# frozen_string_literal: true

# Spec for GitHub Issue #219: Allow a page layout master panel to specify the master tab to open by default
# Related to GitHub Issue #1153: Auto open panels is opening everything
#
# Tests the page layout view_options.initial_show configuration and its interaction
# with the "open panels" app configuration.
#
# Two mechanisms control tab auto-expansion:
#   1. initial_show (static, ERB-time): set in page layout view_options, adds 'on-open-click'
#      class directly to the tab <li> during server-side template rendering
#   2. open_panels (dynamic, Handlebars runtime): set via app configuration, evaluated per
#      master record with substitution support, adds 'on-open-click' via Handlebars helper
#
# Precedence rules:
#   - open_panels only controls panels where initial_show is nil (not explicitly set).
#   - If a panel has initial_show: true, it will always auto-expand regardless of open_panels.
#     To allow open_panels to control which panels open, panels must NOT have initial_show: true.
#   - If initial_show is explicitly false, the panel never opens via the static ERB path.
#     However, open_panels can still cause expansion via the Handlebars runtime evaluation.
#
# Issue #1153 root cause: the Viva app page layouts had initial_show: true on all panels,
# preventing open_panels from controlling which panels opened. The resolution was to correct
# the page layout configuration — the template code was correct all along.

require 'rails_helper'

describe 'page layout initial_show tab auto-expand', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  def navigate_to_master
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    finish_page_loading
    expect(page).to have_css("#master-#{@master.id}", wait: 15)
    dismiss_modal
  end

  # Wait for a tab panel to be expanded (Bootstrap collapse adds 'in' class)
  def wait_for_panel_expanded(panel_name, timeout: 15)
    tab_link = find("[data-panel-tab='#{panel_name}']", wait: timeout)
    target = tab_link['data-target']
    expect(page).to have_css("#{target}.in", wait: timeout)
  end

  # Confirm a panel is NOT expanded after allowing time for any auto-click to fire
  def expect_panel_collapsed(panel_name, wait_seconds: 5)
    tab_link = find("[data-panel-tab='#{panel_name}']", wait: 5)
    target = tab_link['data-target']
    sleep wait_seconds
    expect(page).not_to have_css("#{target}.in", wait: 0),
                        "Expected panel '#{panel_name}' to be collapsed but it was expanded"
  end

  # Update a page layout's options.
  # Clears orig_config_text to force OptionsHandler to re-parse the new YAML,
  # since the same Ruby object is reused across test examples and the ||= guard
  # in setup_options would otherwise skip re-parsing when the raw YAML matches
  # the initial create! value.
  def update_layout(layout, options_yaml)
    layout.orig_config_text = nil
    layout.update!(current_admin: @admin, options: options_yaml)
  end

  def set_open_panels(value)
    if value.nil?
      @app_type.app_configurations.active.where(name: 'open panels').each do |ac|
        ac.update!(current_admin: @admin, disabled: true)
      end
    else
      Admin::AppConfiguration.add_user_config(@user, @app_type, :open_panels, value, @admin)
    end
  end

  # Layout YAML helpers to reduce repetition across examples
  def details_layout_yaml(initial_show: nil)
    yaml = "contains:\n  categories:\n    - details\n"
    yaml += "view_options:\n  initial_show: #{initial_show}\n" unless initial_show.nil?
    yaml
  end

  def trackers_layout_yaml(initial_show: nil)
    yaml = "contains:\n  categories:\n    - trackers\n"
    yaml += "view_options:\n  initial_show: #{initial_show}\n" unless initial_show.nil?
    yaml
  end

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    SetupHelper.feature_setup

    @admin, @admin_password = create_admin
    create_data_set_outside_tx

    @user, @good_password = create_user
    @good_email = @user.email
    @app_type = @user.app_type

    setup_access :player_infos, user: @user
    setup_access :addresses, user: @user
    setup_access :player_contacts, user: @user
    setup_access :trackers, resource_type: :table, access: :read, user: @user

    @master = create_master(@user)

    @master.player_infos.create!(
      first_name: 'InitialShow',
      last_name: 'TabTest',
      birth_date: '1990-01-01',
      rank: 10,
      source: 'nflpa'
    )

    @master.player_contacts.create!(
      data: '(555)999-8888',
      rec_type: 'phone',
      rank: 10
    )

    # Store and disable existing master layouts to start clean
    @original_layouts = {}
    Admin::PageLayout.where(layout_name: 'master')
                     .where('app_type_id = ? OR app_type_id IS NULL', @app_type.id)
                     .each do |pl|
      @original_layouts[pl.id] = { options: pl.options, disabled: pl.disabled }
      pl.update!(current_admin: @admin, disabled: true)
    end

    # Create two master panel layouts for testing
    @details_panel = Admin::PageLayout.create!(
      layout_name: 'master',
      panel_name: 'details',
      panel_label: 'Details',
      panel_position: 0,
      app_type: @app_type,
      current_admin: @admin,
      options: details_layout_yaml
    )

    @trackers_panel = Admin::PageLayout.create!(
      layout_name: 'master',
      panel_name: 'trackers',
      panel_label: 'Trackers',
      panel_position: 1,
      app_type: @app_type,
      current_admin: @admin,
      options: trackers_layout_yaml
    )

    # Store original open_panels config
    @original_open_panels_config = @app_type.app_configurations.active.where(name: 'open panels').first
    @original_open_panels_value = @original_open_panels_config&.value
    @original_open_panels_disabled = @original_open_panels_config&.disabled
  end

  after(:all) do
    # Remove test layouts FIRST to avoid panel_name uniqueness conflicts when restoring originals
    [@details_panel, @trackers_panel].compact.each do |pl|
      ActiveRecord::Base.connection.execute(
        "DELETE FROM page_layout_history WHERE page_layout_id = #{pl.id}"
      )
      pl.destroy
    end

    # Restore original layouts (no panel_name conflicts now)
    @original_layouts&.each do |id, attrs|
      pl = Admin::PageLayout.find_by(id: id)
      pl&.update!(current_admin: @admin, options: attrs[:options], disabled: attrs[:disabled])
    end

    # Restore original open_panels config
    if @original_open_panels_config
      @original_open_panels_config.update!(
        current_admin: @admin,
        value: @original_open_panels_value,
        disabled: @original_open_panels_disabled
      )
    else
      ac = @app_type.app_configurations.active.where(name: 'open panels').first
      ac&.update!(current_admin: @admin, disabled: true)
    end
  end

  before(:each) do
    # Clear the AppConfiguration memoization cache before each test.
    # DatabaseCleaner truncates records between tests, so any user-specific config
    # created by a previous test is gone from the DB. Without clearing the memo,
    # value_for still returns the stale cached value from the prior test even though
    # the record no longer exists, causing incorrect open_panels behavior.
    Admin::AppConfiguration.clear_memo!
    # Clear precompiled Handlebars templates so each test gets a fresh compilation
    # reflecting the current layout and config state (avoids stale cache from prior tests)
    HandlebarsPrecompiler.cleanup_tmp_dir
    HandlebarsPrecompiler.cleanup_public_dir
    Rails.cache.delete('server_cache_version')
    login
  end

  context 'initial_show on a category panel' do
    it 'auto-expands the details panel when initial_show is true - resolves #219' do
      update_layout(@details_panel, details_layout_yaml(initial_show: true))
      update_layout(@trackers_panel, trackers_layout_yaml)
      set_open_panels(nil)

      navigate_to_master
      wait_for_panel_expanded('details')
      expect_panel_collapsed('trackers')
    end

    it 'does not auto-expand the details panel when initial_show is not set' do
      update_layout(@details_panel, details_layout_yaml)
      update_layout(@trackers_panel, trackers_layout_yaml)
      set_open_panels(nil)

      navigate_to_master
      expect_panel_collapsed('details')
      expect_panel_collapsed('trackers')
    end
  end

  context 'initial_show interaction with open_panels app configuration' do
    it 'auto-expands a panel via open_panels when initial_show is not set' do
      update_layout(@details_panel, details_layout_yaml)
      update_layout(@trackers_panel, trackers_layout_yaml)
      set_open_panels('details')

      navigate_to_master
      wait_for_panel_expanded('details')
      expect_panel_collapsed('trackers')
    end

    it 'initial_show: true opens a panel even when not listed in open_panels - #1153 was a config bug' do
      # initial_show: true is not overridden by open_panels. A panel with initial_show: true
      # will always auto-expand regardless of what open_panels specifies.
      # The root cause of #1153 was that all Viva page layout panels had initial_show: true,
      # which must be removed for open_panels to control which panel opens.
      update_layout(@details_panel, details_layout_yaml(initial_show: true))
      update_layout(@trackers_panel, trackers_layout_yaml)
      set_open_panels('trackers')

      navigate_to_master
      # details opens because initial_show: true is not suppressed by open_panels
      wait_for_panel_expanded('details')
      # trackers also opens because it is listed in open_panels (initial_show: nil allows the override)
      wait_for_panel_expanded('trackers')
    end

    it 'initial_show: true on all panels opens all panels regardless of open_panels - #1153' do
      # When every panel has initial_show: true, open_panels has no effect — all panels open.
      # This is the exact scenario reported in #1153.
      # Resolution: remove initial_show: true from panels that should be controlled by open_panels.
      update_layout(@details_panel, details_layout_yaml(initial_show: true))
      update_layout(@trackers_panel, trackers_layout_yaml(initial_show: true))
      set_open_panels('details')

      navigate_to_master
      # Both open because initial_show: true is not overridden by open_panels
      wait_for_panel_expanded('details')
      wait_for_panel_expanded('trackers')
    end

    it 'open_panels still expands a panel even when initial_show is false' do
      update_layout(@details_panel, details_layout_yaml(initial_show: false))
      update_layout(@trackers_panel, trackers_layout_yaml)
      set_open_panels('details')

      navigate_to_master
      # details expands because open_panels evaluation is independent of initial_show
      wait_for_panel_expanded('details')
      expect_panel_collapsed('trackers')
    end
  end

  context 'multiple panels with initial_show' do
    it 'auto-expands both panels when both have initial_show: true' do
      update_layout(@details_panel, details_layout_yaml(initial_show: true))
      update_layout(@trackers_panel, trackers_layout_yaml(initial_show: true))
      set_open_panels(nil)

      navigate_to_master
      wait_for_panel_expanded('details')
      wait_for_panel_expanded('trackers')
    end
  end
end
