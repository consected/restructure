# frozen_string_literal: true

require 'rails_helper'

# Acceptance test for GitHub Issue #1180: Page layout resource rendering should support
# dynamic models and external identifiers in contains.resources panels.
#
# Prior to the fix, `contains.resources` in a master panel page layout only correctly rendered
# activity logs. Dynamic model and external identifier resources would produce incorrect
# `data-template` attribute values (using the full resource name rather than the stripped
# hyphenated name from the Resources::Models registry), causing Handlebars templates not to
# be found and the panel content not to render.
#
# This spec verifies correct DOM output for each resource type after the master record is
# expanded, specifically:
#   AC-002: Dynamic model resource - tab link has correct data-template using the DM's
#           hyphenated_name (stripped of namespace), content div has dynamic-model-generic-block
#   AC-003: External identifier resource - tab link has correct data-template, content div
#           has external-id-generic-block
#   AC-005: Panel tab is absent when the current user has no access to the panel's resources
#
# Implementation changes verified:
#   - app/helpers/page_layouts_helper.rb (resource_render_info)
#   - app/views/masters/_search_results_master_tabs_resources.html.erb
#   - app/views/masters/_search_results_resources_panel.html.erb

describe 'page layout resource type rendering', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport

  def set_up_feature
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    change_setting('AllowDynamicMigrations', true)
    SetupHelper.feature_setup

    @admin, @admin_password = create_admin

    ms = Master.no_temporary_masters
    if ms.count == 0 || ms.first.nil? || ms.first.id < 1
      create_data_set_outside_tx
    end

    @master = Master.no_temporary_masters.first
    @master_id = @master.id
    expect(@master_id).to be > 0

    @user, @good_password = create_user(create_master: true)
    @good_email = @user.email
    @app_type = @user.app_type
    expect(@app_type).not_to be nil
    expect(@user.two_factor_setup_required?).to be_falsey
  end

  # Create (or re-create) the test DynamicModel used in resource panels
  def setup_dm_resource
    DynamicModel.active.where(table_name: 'test_rr_dms').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestRrDm) if defined?(DynamicModel::TestRrDm)

    @dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test RR DM',
      schema_name: 'dynamic_test',
      table_name: 'test_rr_dms',
      category: :details,
      field_list: 'description',
      primary_key_name: 'id',
      foreign_key_name: 'master_id'
    )

    setup_access :dynamic_model__test_rr_dms, user: @user

    # Create a record on the master so the AJAX-loaded list has visible content to assert against
    @dm_record_text = "rr-dm-record-#{SecureRandom.hex(4)}"
    @dm.implementation_class.create!(
      master: @master,
      description: @dm_record_text,
      current_user: @user
    )
  end

  # Create (or re-create) the test ExternalIdentifier used in resource panels
  def setup_ei_resource
    unless Admin::MigrationGenerator.table_exists? 'test_rr_ext_ids'
      sql = <<~SQL
        CREATE TABLE IF NOT EXISTS ml_app.test_rr_ext_ids (
          id SERIAL PRIMARY KEY,
          master_id INTEGER REFERENCES ml_app.masters(id),
          test_rr_ext_id BIGINT NOT NULL,
          created_at TIMESTAMP,
          updated_at TIMESTAMP,
          user_id INTEGER REFERENCES ml_app.users(id)
        )
      SQL
      ActiveRecord::Base.connection.execute(sql)
    end

    ExternalIdentifier.active.where(name: 'test_rr_ext_ids').reload.each do |ei|
      ei.update!(disabled: true, current_admin: @admin)
    end

    @ei = ExternalIdentifier.create!(
      current_admin: @admin,
      name: 'test_rr_ext_ids',
      label: 'Test RR Ext ID',
      external_id_attribute: 'test_rr_ext_id',
      min_id: 1,
      max_id: 999_999_999
    )

    setup_access :test_rr_ext_ids, resource_type: :table, user: @user

    # Create a record on the master so the AJAX-loaded list has visible content to assert against.
    # The external identifier numeric value is rendered in the list panel.
    @ei_record_value = rand(100_000..999_999)
    @ei.implementation_class.create!(
      master: @master,
      test_rr_ext_id: @ei_record_value,
      current_user: @user
    )
  end

  # Create a master panel page layout with contains.resources listing the given resource names.
  # initial_show: true makes the panel auto-expand on master open and fires the AJAX list load via
  # the `on-open-click` mechanism, so we can assert against actually rendered content.
  def create_resource_panel(resources:, initial_show: true)
    disable_active_panel_layout('test-rr-resources-panel')
    resource_list = resources.map { |r| "    - #{r}" }.join("\n")
    options_yaml = <<~YAML
      contains:
        resources:
      #{resource_list}
    YAML
    if initial_show
      options_yaml += "view_options:\n  initial_show: true\n"
    end
    Admin::PageLayout.create!(
      current_admin: @admin,
      app_type_id: @app_type.id,
      layout_name: 'master',
      panel_name: 'test-rr-resources-panel',
      panel_label: 'RR Resources',
      panel_position: 200,
      options: options_yaml
    )
  end

  # Navigate to the master record search result and expand it so tabs are rendered
  def expand_test_master
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
    dismiss_modal
    finish_page_loading
    expect(page).to have_css("#master-#{@master_id}")
    expect(page).not_to have_css('.alert')
    expand_master_record(master_id: @master_id)
    finish_page_loading
  end

  # -------------------------------------------------------------------
  # AC-002: Dynamic model resource in contains.resources panel
  # -------------------------------------------------------------------

  describe 'dynamic model resource (AC-002)' do
    before(:all) do
      set_up_feature
      setup_dm_resource
      create_resource_panel(resources: ['dynamic_model__test_rr_dms'])
      Rails.application.routes_reloader.reload!
    end

    after(:all) do
      disable_active_panel_layout('test-rr-resources-panel', reload_routes: true)
    end

    before(:each) do
      validate_setup
      login
    end

    it 'renders a single tab keyed by the panel_name that toggles the outer panel container' do
      expand_test_master

      # The unified contract: one tab per page-layout panel, keyed by panel_name
      # (consistent with contains.categories behaviour).
      tab = find("a[data-panel-tab='test-rr-resources-panel']", wait: 15)
      expect(tab['data-target']).to eq("#test-rr-resources-panel-#{@master_id}")

      # Only one tab is rendered, even though the panel can contain one or more resources.
      expect(page).to have_css("a[data-panel-tab='test-rr-resources-panel']", count: 1)
    end

    it 'renders the inner resource block with dynamic-model-generic-block class and correct data-template' do
      expand_test_master

      expected_template = 'dynamic-model--test-rr-dms-list-template'

      # The inner resource block lives inside the outer panel container and is the
      # element that self-loads its list content via the _fpa.js sub-item loader.
      content_div = find("[data-sub-item='dynamic_model__test_rr_dms']", visible: :all, wait: 15)
      expect(content_div[:class]).to include('dynamic-model-generic-block')
      expect(content_div['data-template']).to eq(expected_template)
    end

    it 'loads the actual dynamic model records into the panel when the master is expanded' do
      # With initial_show: true on the page-layout panel, opening the master record fires
      # the on-open-click auto-click on the single resources tab, which expands the outer
      # panel container; the inner block then loads its list via the sub-item loader.
      expand_test_master

      # Wait for Bootstrap collapse to fully open the outer resources panel
      expect(page).to have_css("#test-rr-resources-panel-#{@master_id}.collapse.in", wait: 15)

      # The dynamic model record's description field value must be rendered into the
      # AJAX-loaded list panel for the user to see it.
      content_div = find("[data-sub-item='dynamic_model__test_rr_dms']")
      expect(content_div).to have_text(@dm_record_text, wait: 15)
    end
  end

  # -------------------------------------------------------------------
  # AC-003: External identifier resource in contains.resources panel
  # -------------------------------------------------------------------

  describe 'external identifier resource (AC-003)' do
    before(:all) do
      set_up_feature
      setup_ei_resource
      create_resource_panel(resources: ['test_rr_ext_ids'])
      Rails.application.routes_reloader.reload!
    end

    after(:all) do
      disable_active_panel_layout('test-rr-resources-panel', reload_routes: true)
    end

    before(:each) do
      validate_setup
      login
    end

    it 'renders a single tab keyed by the panel_name for the EI panel' do
      expand_test_master

      tab = find("a[data-panel-tab='test-rr-resources-panel']", wait: 15)
      expect(tab['data-target']).to eq("#test-rr-resources-panel-#{@master_id}")
      expect(page).to have_css("a[data-panel-tab='test-rr-resources-panel']", count: 1)
    end

    it 'renders the inner resource block with external-id-generic-block class and correct data-template' do
      expand_test_master

      expected_template = 'test-rr-ext-ids-list-template'

      content_div = find("[data-sub-item='test_rr_ext_ids']", visible: :all, wait: 15)
      expect(content_div[:class]).to include('external-id-generic-block')
      expect(content_div['data-template']).to eq(expected_template)
    end

    it 'loads the actual external identifier records into the panel when the master is expanded' do
      expand_test_master

      expect(page).to have_css("#test-rr-resources-panel-#{@master_id}.collapse.in", wait: 15)

      content_div = find("[data-sub-item='test_rr_ext_ids']")
      expect(content_div).to have_text(@ei_record_value.to_s, wait: 15)
    end
  end

  # -------------------------------------------------------------------
  # Multiple resources in the same master panel
  #
  # Verifies that a single contains.resources panel listing both a dynamic
  # model and an external identifier renders tabs and content panels for
  # both resources, and that the AJAX-loaded list content for each resource
  # type is rendered into its respective panel when the master is expanded.
  # -------------------------------------------------------------------

  describe 'multiple resources in the same master panel' do
    before(:all) do
      set_up_feature
      setup_dm_resource
      setup_ei_resource
      create_resource_panel(resources: ['dynamic_model__test_rr_dms', 'test_rr_ext_ids'])
      Rails.application.routes_reloader.reload!
    end

    after(:all) do
      disable_active_panel_layout('test-rr-resources-panel', reload_routes: true)
    end

    before(:each) do
      validate_setup
      login
    end

    it 'renders a single tab and both resource blocks inside the one outer panel container' do
      expand_test_master

      # Exactly ONE tab is rendered for the panel, regardless of how many
      # resources it contains (mirrors the contains.categories behaviour).
      expect(page).to have_css("a[data-panel-tab='test-rr-resources-panel']", count: 1)
      tab = find("a[data-panel-tab='test-rr-resources-panel']", wait: 15)
      expect(tab['data-target']).to eq("#test-rr-resources-panel-#{@master_id}")

      # Both resource inner blocks live inside the single outer panel container.
      outer = find("#test-rr-resources-panel-#{@master_id}", visible: :all, wait: 15)
      dm_content = outer.find("[data-sub-item='dynamic_model__test_rr_dms']", visible: :all)
      ei_content = outer.find("[data-sub-item='test_rr_ext_ids']", visible: :all)

      expect(dm_content[:class]).to include('dynamic-model-generic-block')
      expect(dm_content['data-template']).to eq('dynamic-model--test-rr-dms-list-template')
      expect(ei_content[:class]).to include('external-id-generic-block')
      expect(ei_content['data-template']).to eq('test-rr-ext-ids-list-template')
    end

    it 'loads the actual records for both resources into their respective inner blocks' do
      expand_test_master

      # The outer panel container opens, then each inner block self-loads.
      expect(page).to have_css("#test-rr-resources-panel-#{@master_id}.collapse.in", wait: 15)

      dm_content = find("[data-sub-item='dynamic_model__test_rr_dms']")
      ei_content = find("[data-sub-item='test_rr_ext_ids']")

      expect(dm_content).to have_text(@dm_record_text, wait: 15)
      expect(ei_content).to have_text(@ei_record_value.to_s, wait: 15)
    end
  end

  # -------------------------------------------------------------------
  # AC-005: Panel tab is absent for a user with no resource access
  # -------------------------------------------------------------------

  describe 'access control - no panel tab for inaccessible resources (AC-005)' do
    before(:all) do
      set_up_feature
      setup_dm_resource
      create_resource_panel(resources: ['dynamic_model__test_rr_dms'])

      # Second user with no access to the DM resource
      @no_access_user, @no_access_password = create_user(create_master: false)
      @no_access_email = @no_access_user.email

      Rails.application.routes_reloader.reload!
    end

    after(:all) do
      disable_active_panel_layout('test-rr-resources-panel', reload_routes: true)
    end

    before(:each) do
      validate_setup
    end

    it 'does not render the panel tab when the user has no access to the resource' do
      # Log in as the user without access
      @user = @no_access_user
      @good_email = @no_access_email
      @good_password = @no_access_password
      login

      expand_test_master

      expect(page).not_to have_css("a[data-panel-tab='test-rr-resources-panel']")
    end
  end
end
