# frozen_string_literal: true

# System spec for GitHub Issue #1194: Activity Log filter activities (perspectives)
#
# Tests the activity log panel perspectives feature from a UI/browser perspective:
# - Perspective buttons appear alongside the activity log content block when configured
#   via Admin::PageLayout view_options.perspectives
# - The "All" button is active by default when no default perspective is configured
# - The panel-level view_options.default_perspective marks that named button active on
#   initial render
# - Admin::AppConfiguration 'default activity log perspective' (user-scoped) marks
#   the configured perspective button active on initial render
# - Clicking a perspective button toggles active class and triggers AJAX refresh
# - The refreshed block shows only records matching the perspective's where: filter
# - Clicking "All" restores the full unfiltered list
# - When no perspectives are configured, the perspective button bar is absent
#
# Issue: https://github.com/consected/restructure/issues/1194
# PR:    https://github.com/consected/restructure/pull/1197

require 'rails_helper'

describe 'activity log panel perspectives', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include ActivityLogSupport
  include FeatureSupport

  PERSP_PANEL_NAME = 'al-perspectives-test-panel'
  PERSP_RESOURCE   = 'activity_log__player_contact_emails'
  PERSP_SLUG       = 'who_is_agent'
  PERSP_LABEL      = 'Is Agent'

  def base_panel_options_yaml(perspectives: true, default_perspective: nil)
    persp_yaml = if perspectives
                   <<~PERSP
                     perspectives:
                       #{PERSP_RESOURCE}:
                         - name: #{PERSP_SLUG}
                           label: #{PERSP_LABEL}
                           where:
                             select_who: agent
                   PERSP
                 else
                   ''
                 end

    default_yaml = default_perspective ? "    default_perspective: #{default_perspective}\n" : ''

    persp_indented = persp_yaml.present? ? persp_yaml.lines.map { |l| "    #{l}" }.join : ''

    <<~YAML
        contains:
          resources:
            - #{PERSP_RESOURCE}
        view_options:
          initial_show: true
      #{persp_indented}#{default_yaml}
    YAML
  end

  def update_panel_options(options_yaml)
    @panel_layout.orig_config_text = nil
    @panel_layout.update!(current_admin: @admin, options: options_yaml)
    Rails.cache.delete('server_cache_version')
    Admin::AppConfiguration.clear_memo!
  end

  def navigate_and_expand
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    dismiss_modal
    finish_page_loading
    expect(page).to have_css("#master-#{@master.id}", wait: 15)
    expand_master_record(master_id: @master.id)
    finish_page_loading
    # In LEGACY mode (single-resource panel) the block id is resource-keyed,
    # not panel_name-keyed. Wait for the resource block to expand.
    resource_block_id = PERSP_RESOURCE.hyphenate
    expect(page).to have_css("##{resource_block_id}-#{@master.id}.collapse.in", wait: 20)
    finish_page_loading
  end

  def perspectives_bar
    find(".activity-log-perspectives[data-resource='#{PERSP_RESOURCE}']", wait: 15)
  end

  def al_content_block
    find("[data-sub-item='#{PERSP_RESOURCE}'] .activity-log-list", wait: 15)
  end

  def click_perspective_btn(data_perspective)
    btn = find(".activity-log-perspectives__btn[data-perspective='#{data_perspective}']", wait: 15)
    scroll_into_view(btn)
    sleep 0.3
    btn.click
    finish_page_loading
    sleep 0.5 # Allow time for JavaScript active-class toggle
  end

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    change_setting('AllowDynamicMigrations', true)
    SetupHelper.feature_setup

    @admin, @admin_password = create_admin
    create_data_set_outside_tx

    @user, @good_password = create_user
    @good_email = @user.email
    @app_type = @user.app_type

    # generate_test_activity_log creates AL definition and sets @master
    @al_def = generate_test_activity_log

    setup_access :player_contacts, user: @user

    @player_contact = @master.player_contacts.create!(
      data: 'perspectives@example.com',
      rec_type: 'email',
      rank: 10,
      current_user: @user
    )

    @al_subject = @player_contact.activity_log__player_contact_emails.new(
      select_who: 'subject',
      extra_log_type: 'primary'
    )
    @al_subject.master = @master
    @al_subject.current_user = @user
    @al_subject.save!

    @al_agent = @player_contact.activity_log__player_contact_emails.new(
      select_who: 'agent',
      extra_log_type: 'primary'
    )
    @al_agent.master = @master
    @al_agent.current_user = @user
    @al_agent.save!

    disable_active_panel_layout(PERSP_PANEL_NAME)

    @panel_layout = Admin::PageLayout.create!(
      current_admin: @admin,
      app_type: @app_type,
      layout_name: 'master',
      panel_name: PERSP_PANEL_NAME,
      panel_label: 'Al Perspectives Test Panel',
      panel_position: 200,
      options: base_panel_options_yaml
    )

    ActivityLog.define_models
    Rails.application.routes_reloader.reload!
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', false)
    disable_active_panel_layout(PERSP_PANEL_NAME)
    Admin::AppConfiguration.active
                           .where(app_type: @app_type, name: 'default activity log perspective')
                           .each { |ac| ac.update!(current_admin: @admin, disabled: true) }
    Admin::AppConfiguration.clear_memo!
    # Disable the email activity log created for this spec so it doesn't contaminate
    # subsequent specs that check supports_activity_log for player_contact items
    @al_def&.update!(disabled: true, current_admin: @admin)
  end

  before(:each) do
    update_panel_options(base_panel_options_yaml)
    Admin::AppConfiguration.clear_memo!
    login
  end

  # ---------------------------------------------------------------------------
  # Perspectives buttons rendering
  # ---------------------------------------------------------------------------

  it 'renders the perspectives button bar when perspectives are configured' do
    navigate_and_expand

    expect(page).to have_css(".activity-log-perspectives[data-resource='#{PERSP_RESOURCE}']", wait: 15)
    within perspectives_bar do
      expect(page).to have_css(".activity-log-perspectives__btn[data-perspective='']")
      expect(page).to have_css(".activity-log-perspectives__btn[data-perspective='#{PERSP_SLUG}']")
      expect(page).to have_text('All')
      expect(page).to have_text(PERSP_LABEL)
    end
  end

  # ---------------------------------------------------------------------------
  # Default active state — no default configured
  # ---------------------------------------------------------------------------

  it 'marks the "All" button active by default when no default perspective is configured' do
    navigate_and_expand

    within perspectives_bar do
      all_btn   = find(".activity-log-perspectives__btn[data-perspective='']")
      named_btn = find(".activity-log-perspectives__btn[data-perspective='#{PERSP_SLUG}']")

      expect(all_btn[:class]).to include('active'),
                                 '"All" button should be active when no default is configured'
      expect(named_btn[:class]).not_to include('active')
    end
  end

  # ---------------------------------------------------------------------------
  # Default active state — panel-level default_perspective
  # ---------------------------------------------------------------------------

  it 'marks the configured default_perspective button active on initial render' do
    update_panel_options(base_panel_options_yaml(default_perspective: PERSP_SLUG))

    navigate_and_expand

    within perspectives_bar do
      named_btn = find(".activity-log-perspectives__btn[data-perspective='#{PERSP_SLUG}']")
      all_btn   = find(".activity-log-perspectives__btn[data-perspective='']")

      expect(named_btn[:class]).to include('active'),
                                   'Named perspective should be active when default_perspective is set'
      expect(all_btn[:class]).not_to include('active')
    end
  end

  # ---------------------------------------------------------------------------
  # Default active state — Admin::AppConfiguration user default
  # ---------------------------------------------------------------------------

  it 'marks the app-config default perspective button active for the configured user' do
    add_app_config(
      @app_type,
      'default activity log perspective',
      "#{PERSP_RESOURCE}: #{PERSP_SLUG}",
      user: @user
    )
    Admin::AppConfiguration.clear_memo!

    navigate_and_expand

    within perspectives_bar do
      named_btn = find(".activity-log-perspectives__btn[data-perspective='#{PERSP_SLUG}']")
      expect(named_btn[:class]).to include('active'),
                                   'App-config default should be reflected as active button'
    end
  ensure
    Admin::AppConfiguration.active
                           .where(app_type: @app_type, name: 'default activity log perspective')
                           .each { |ac| ac.update!(current_admin: @admin, disabled: true) }
    Admin::AppConfiguration.clear_memo!
  end

  # ---------------------------------------------------------------------------
  # Button click toggles active class
  # ---------------------------------------------------------------------------

  it 'toggles active class when a perspective button is clicked and restores it on "All"' do
    navigate_and_expand

    # Verify buttons exist
    bar = perspectives_bar
    expect(bar).to have_css(".activity-log-perspectives__btn[data-perspective='']")
    expect(bar).to have_css(".activity-log-perspectives__btn[data-perspective='#{PERSP_SLUG}']")

    # Click the named perspective button
    click_perspective_btn(PERSP_SLUG)
    sleep 1 # Allow JavaScript and AJAX to complete

    # Verify the named button is now active
    all_btn = find(".activity-log-perspectives__btn[data-perspective='']")
    named_btn = find(".activity-log-perspectives__btn[data-perspective='#{PERSP_SLUG}']")

    # Check class attributes with retry via Capybara
    expect(page).to have_css(".activity-log-perspectives__btn[data-perspective='#{PERSP_SLUG}'].active", wait: 10)
    expect(all_btn[:class]).not_to include('active')

    # Click All button to reset
    click_perspective_btn('')
    sleep 1

    # Verify All is active again
    expect(page).to have_css(".activity-log-perspectives__btn[data-perspective=''].active", wait: 10)
    named_btn = find(".activity-log-perspectives__btn[data-perspective='#{PERSP_SLUG}']")
    expect(named_btn[:class]).not_to include('active')
  end

  # ---------------------------------------------------------------------------
  # AJAX content filtering
  # ---------------------------------------------------------------------------

  it 'loads only matching records when a perspective is applied, and restores all on "All"' do
    navigate_and_expand

    # Both records should be visible in the initial unfiltered list
    block = al_content_block
    expect(block).to have_css("ul[data-item-id='#{@al_agent.id}']", wait: 20)
    expect(block).to have_css("ul[data-item-id='#{@al_subject.id}']", wait: 20)

    click_perspective_btn(PERSP_SLUG)

    block = al_content_block
    expect(block).to have_css("ul[data-item-id='#{@al_agent.id}']", wait: 20)
    expect(block).not_to have_css("ul[data-item-id='#{@al_subject.id}']")

    click_perspective_btn('')

    block = al_content_block
    expect(block).to have_css("ul[data-item-id='#{@al_agent.id}']", wait: 20)
    expect(block).to have_css("ul[data-item-id='#{@al_subject.id}']", wait: 20)
  end

  # ---------------------------------------------------------------------------
  # No perspectives configured — bar absent
  # ---------------------------------------------------------------------------

  it 'does not render the perspective button bar when no perspectives are configured' do
    update_panel_options(base_panel_options_yaml(perspectives: false))

    navigate_and_expand

    expect(page).not_to have_css(".activity-log-perspectives[data-resource='#{PERSP_RESOURCE}']")
  end
end
