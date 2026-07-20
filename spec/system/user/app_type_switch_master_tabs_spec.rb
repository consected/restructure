# frozen_string_literal: true

require 'rails_helper'

# Purpose (follow-up to issues #1279 / #1270): reproduce through the UI the "missing master
# panel tabs" defect reported in production after release 9.46.3, and verify the fix.
#
# Root cause: Admin::UserAccessControl.viewable_tables cached its result in Rails.cache
# WITHOUT the user's current app_type_id in the cache key. When a user switched app type
# within a single session (current_sign_in_at unchanged, no access control rows modified),
# the previous app type's cached viewable tables were returned. The master panel tab
# filtering (app/views/masters/_search_results_master_tabs.html.erb) then dropped panels
# whose resources were not viewable in the PREVIOUS app type, so tabs were missing from
# the master record details. The incomplete render was baked into the compiled Handlebars
# template files, making the problem persist.
#
# Before PR #1271 (issue #1270), every User save (sign-in tracking, app type switches)
# cleared the whole Rails cache, which hid the under-scoped cache key. Rolling production
# back to 9.46.2 therefore made the symptom disappear without fixing the actual defect.
#
# These system specs exercise the full stack (viewable_tables caching, template
# generation, Handlebars compilation and client-side rendering) in single examples that:
# - switch a user between two app types and verify the correct tabs are shown in each
# - switch between two users with different access and verify per-user tabs are correct
describe 'master panel tabs across app type and user switches', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport

  PanelA = 'test-ats-panel-a'
  PanelB = 'test-ats-panel-b'
  PanelC = 'test-ats-panel-c'

  def set_up_feature
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    change_setting('AllowDynamicMigrations', true)
    SetupHelper.feature_setup

    @admin, @admin_password = create_admin

    ms = Master.no_temporary_masters
    create_data_set_outside_tx if ms.count == 0 || ms.first.nil? || ms.first.id < 1

    @master = Master.no_temporary_masters.first
    @master_id = @master.id
    expect(@master_id).to be > 0

    # User 1 on app type A, later granted access to app type B too
    @user1, @user1_password = create_user(create_master: true)
    @app_type_a = @user1.app_type
    expect(@app_type_a).not_to be nil

    @app_type_b = create_app_type(name: "ats_test_b_#{SecureRandom.hex(3)}", label: 'ATS Test B')
    enable_user_app_access @app_type_b, @user1

    # User 2 on app type A only, with different table access from user 1
    @user2, @user2_password = create_user
    expect(@user2.app_type_id).to eq @app_type_a.id
  end

  # Create (or re-create) a test DynamicModel used in the resource panels
  def setup_dm_resource(table_name, label)
    class_name = table_name.singularize.camelize.to_sym
    DynamicModel.active.where(table_name:).reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, class_name) if DynamicModel.const_defined?(class_name, false)

    DynamicModel.create!(
      current_admin: @admin,
      name: label,
      schema_name: 'dynamic_test',
      table_name:,
      category: :details,
      field_list: 'description',
      primary_key_name: 'id',
      foreign_key_name: 'master_id'
    )
  end

  # Create a master panel page layout containing the given resources for an app type
  def create_resource_panel(app_type:, panel_name:, panel_label:, resources:)
    disable_active_panel_layout(panel_name, app_type:)
    resource_list = resources.map { |r| "    - #{r}" }.join("\n")
    options_yaml = <<~YAML
      contains:
        resources:
      #{resource_list}
    YAML
    Admin::PageLayout.create!(
      current_admin: @admin,
      app_type_id: app_type.id,
      layout_name: 'master',
      panel_name:,
      panel_label:,
      panel_position: 200,
      options: options_yaml
    )
  end

  def login_as(user, password)
    @user = User.find(user.id)
    @good_email = @user.email
    @good_password = password
    login
  end

  # Switch the current user's app type through the navbar app selector,
  # exactly as a real user would
  def switch_app_type(app_type)
    finish_page_loading
    expect(page).to have_css('#use_app_type_select')
    find('#use_app_type_select').find("option[value='#{app_type.id}']").select_option
    # The selector change navigates to /pages/home?use_app_type=<name> and reloads the app
    expect(page).to have_css("#use_app_type_select[data-app-type-id='#{app_type.id}']", wait: 30)
    finish_page_loading
  end

  # Navigate to the master record search result and expand it so tabs are rendered
  def expand_test_master
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
    dismiss_modal
    finish_page_loading
    expect(page).to have_css("#master-#{@master_id}")
    expand_master_record(master_id: @master_id)
    finish_page_loading
  end

  before(:all) do
    set_up_feature

    # App type A panels:
    # - PanelA contains a dynamic model viewable only by user 1
    # - PanelC contains a dynamic model viewable only by user 2
    @dm_a = setup_dm_resource('test_ats_a_recs', 'Test ATS A Rec')
    @dm_c = setup_dm_resource('test_ats_c_recs', 'Test ATS C Rec')
    # App type B panel:
    # - PanelB contains a dynamic model viewable by user 1 in app type B only
    @dm_b = setup_dm_resource('test_ats_b_recs', 'Test ATS B Rec')

    create_resource_panel app_type: @app_type_a, panel_name: PanelA, panel_label: 'ATS Panel A',
                          resources: ['dynamic_model__test_ats_a_recs']
    create_resource_panel app_type: @app_type_a, panel_name: PanelC, panel_label: 'ATS Panel C',
                          resources: ['dynamic_model__test_ats_c_recs']
    create_resource_panel app_type: @app_type_b, panel_name: PanelB, panel_label: 'ATS Panel B',
                          resources: ['dynamic_model__test_ats_b_recs']

    # User 1 access: DM A in app type A; DM B in app type B (created directly since
    # setup_access validates has_access_to? against the user's current app type)
    setup_access :dynamic_model__test_ats_a_recs, user: @user1, app_type: @app_type_a
    Admin::UserAccessControl.create! app_type: @app_type_b, resource_type: :table,
                                     resource_name: 'dynamic_model__test_ats_b_recs',
                                     access: :create, user: @user1, current_admin: @admin

    # User 2 access: DM C in app type A only
    setup_access :dynamic_model__test_ats_c_recs, user: @user2, app_type: @app_type_a

    Rails.application.routes_reloader.reload!
  end

  after(:all) do
    disable_active_panel_layout(PanelA, app_type: @app_type_a)
    disable_active_panel_layout(PanelC, app_type: @app_type_a)
    disable_active_panel_layout(PanelB, app_type: @app_type_b, reload_routes: true)
  end

  it 'shows the correct master panel tabs when a user switches app types within a session' do
    login_as @user1, @user1_password

    # App type A: PanelA tab shown; PanelB is for app type B; PanelC is not accessible to user 1
    expand_test_master
    expect(page).to have_css("a[data-panel-tab='#{PanelA}']", wait: 15)
    expect(page).not_to have_css("a[data-panel-tab='#{PanelB}']")
    expect(page).not_to have_css("a[data-panel-tab='#{PanelC}']")

    # Switch to app type B within the same session.
    # Previously the stale cached viewable tables of app type A filtered out PanelB's
    # resources, so the PanelB tab was missing from the master record details.
    switch_app_type @app_type_b
    expand_test_master
    expect(page).to have_css("a[data-panel-tab='#{PanelB}']", wait: 15)
    expect(page).not_to have_css("a[data-panel-tab='#{PanelA}']")

    # Switch back to app type A and check the original tabs are restored
    switch_app_type @app_type_a
    expand_test_master
    expect(page).to have_css("a[data-panel-tab='#{PanelA}']", wait: 15)
    expect(page).not_to have_css("a[data-panel-tab='#{PanelB}']")
  end

  it 'shows the correct master panel tabs for each user when switching users within a session' do
    # User 1 sees PanelA but not PanelC
    login_as @user1, @user1_password
    expand_test_master
    expect(page).to have_css("a[data-panel-tab='#{PanelA}']", wait: 15)
    expect(page).not_to have_css("a[data-panel-tab='#{PanelC}']")
    logout

    # User 2 sees PanelC but not PanelA - templates must not leak between users
    login_as @user2, @user2_password
    expand_test_master
    expect(page).to have_css("a[data-panel-tab='#{PanelC}']", wait: 15)
    expect(page).not_to have_css("a[data-panel-tab='#{PanelA}']")
  end
end
