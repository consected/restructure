# frozen_string_literal: true

# Spec for GitHub Issue #219: Allow a page layout master panel to specify the master tab to open by default
#
# Tests the page layout view_options.initial_show configuration and its interaction
# with the "open panels" app configuration.
#
# Two independent mechanisms control tab auto-expansion:
#   1. initial_show (static, ERB-time): set in page layout view_options, adds 'on-open-click'
#      class directly to the tab <li> during server-side template rendering
#   2. open_panels (dynamic, Handlebars runtime): set via app configuration, evaluated per
#      master record with substitution support, adds 'on-open-click' via Handlebars helper
#
# Precedence rules:
#   - If initial_show is nil (not set), open_panels determines whether to auto-expand
#   - If initial_show is explicitly true, the tab always auto-expands (regardless of open_panels)
#   - If initial_show is explicitly false, the ERB class is NOT added, but open_panels can
#     still cause the tab to auto-expand via the Handlebars runtime evaluation

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
      ac = @app_type.app_configurations.active.where(name: 'open panels').first
      ac&.update!(current_admin: @admin, disabled: true)
    else
      add_app_config(@app_type, 'open panels', value, user: @user)
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
    # Restore original layouts
    @original_layouts&.each do |id, attrs|
      pl = Admin::PageLayout.find_by(id: id)
      pl&.update!(current_admin: @admin, options: attrs[:options], disabled: attrs[:disabled])
    end

    # Remove test layouts and their history records
    [@details_panel, @trackers_panel].compact.each do |pl|
      ActiveRecord::Base.connection.execute(
        "DELETE FROM page_layout_history WHERE page_layout_id = #{pl.id}"
      )
      pl.destroy
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

    it 'initial_show: true wins even when open_panels does not list the panel' do
      update_layout(@details_panel, details_layout_yaml(initial_show: true))
      update_layout(@trackers_panel, trackers_layout_yaml)
      set_open_panels('trackers')

      navigate_to_master
      # details auto-expands via initial_show, trackers via open_panels
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
