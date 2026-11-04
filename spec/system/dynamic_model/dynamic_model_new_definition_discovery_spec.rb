# frozen_string_literal: true

# Purpose (issue #1481): a newly defined Details model appears on the next full page load.
require 'rails_helper'
require './db/table_generators/dynamic_models_table'

describe 'dynamic model discovery on full page reload', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include CacheKeyMemoizationSupport

  ExistingTable = 'issue1481_system_existing_recs'
  DiscoveryTable = 'issue1481_system_discovery_recs'

  def set_up_feature
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)

    create_admin

    masters = Master.no_temporary_masters
    if masters.count.zero? || masters.first&.id.to_i < 1
      create_data_set_outside_tx
      @master = masters.first
      @master_id = @master.id
    else
      @master = masters.first
      @master_id = @master.id
    end

    expect(@master_id).to be > 0

    @user, @good_password = create_user(create_master: true)
    @app_type = @user.app_type
    expect(@app_type).not_to be_nil
    expect(@user.two_factor_auth_disabled).to be_truthy
  end

  def create_discovery_model(table_name)
    DynamicModel.create!(
      current_admin: @admin,
      name: "Issue1481 #{table_name}",
      table_name:,
      schema_name: 'dynamic_test',
      primary_key_name: 'id',
      foreign_key_name: 'master_id',
      category: 'details',
      field_list: 'test1 test2',
      options: "default:\n  fields:\n    - test1\n    - test2\n"
    )
  end

  def grant_model_access(definition, table_name, updated_at: nil)
    template_access = definition.add_user_access_controls(force: true, app_type: @app_type)
    user_access = setup_access "dynamic_model__#{table_name}".to_sym, user: @user, app_type: @app_type

    [template_access, user_access].compact.each do |access_control|
      access_control.update_column(:updated_at, updated_at) if updated_at
    end
  end

  def master_skeleton_cache_key
    reset_shared_helper_cache_key_memoization
    ApplicationController.helpers.master_templates_skeleton_cache_key(force_user_or_admin: @user)
  end

  before(:all) do
    @previous_allow_dynamic_migrations = Settings::AllowDynamicMigrations
    @previous_user_two_factor_disabled = Settings::TwoFactorAuthDisabledForUser
    @previous_perform_caching = Rails.configuration.action_controller.perform_caching
    @created_definitions = []

    change_setting('AllowDynamicMigrations', true)
    Rails.configuration.action_controller.perform_caching = true
    set_up_feature

    DynamicModel.active.where(table_name: ExistingTable).reload.each { |definition| definition.reload.disable!(@admin) }
    @baseline_model = create_discovery_model(ExistingTable)
    @created_definitions << @baseline_model
    grant_model_access(@baseline_model, ExistingTable)

    unless Admin::MigrationGenerator.table_exists?(DiscoveryTable)
      TableGenerators.dynamic_models_table(DiscoveryTable, :create_do, 'test1', 'test2')
    end

    DynamicModel.reset_active_model_configurations!
    SetupHelper.reload_configs
    Rails.application.routes_reloader.reload!
  end

  after(:all) do
    Array(@created_definitions).each do |definition|
      next unless DynamicModel.exists?(definition.id)

      definition.reload
      definition.disable!(@admin) unless definition.disabled?
    end

    if @created_definitions.present?
      DynamicModel.define_models
      Application.refresh_dynamic_defs
      DynamicModel.reset_active_model_configurations!
      SetupHelper.reload_configs
      Rails.application.routes_reloader.reload!
    end

    change_setting('AllowDynamicMigrations', @previous_allow_dynamic_migrations)
    change_setting('TwoFactorAuthDisabledForUser', @previous_user_two_factor_disabled)
    Rails.configuration.action_controller.perform_caching = @previous_perform_caching
  end

  before(:each) do
    validate_setup
    login
  end

  it 'shows a newly defined Details model after reloading the master search page' do
    page_url = "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master_id}"
    baseline_panel = '.details-item-type-dynamic-model--issue1481-system-existing-recs'
    discovery_panel = '.details-item-type-dynamic-model--issue1481-system-discovery-recs'

    visit page_url
    dismiss_modal
    expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
    finish_page_loading
    finish_form_formatting

    expect(page).to have_css("#details-#{@master_id}")
    expect(page).to have_css(baseline_panel)
    expect(page).to have_css("#{baseline_panel} .new-button-container a.btn")
    expect(page).not_to have_css(discovery_panel)

    original_skeleton_key = master_skeleton_cache_key
    original_skeleton = Rails.cache.read(original_skeleton_key)
    expect(original_skeleton).to be_present
    server_cache_version = Application.server_cache_version
    access_control_timestamp = Admin::UserAccessControl
                              .where(app_type_id: [@app_type.id, nil])
                              .maximum(:updated_at) || 3.seconds.ago

    allow_any_instance_of(Admin::UserAccessControl)
      .to receive(:clear_rails_cache_on_save?).and_return(false)

    discovery_model = create_discovery_model(DiscoveryTable)
    @created_definitions << discovery_model
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    grant_model_access(discovery_model, DiscoveryTable, updated_at: access_control_timestamp)
    DynamicModel.reset_active_model_configurations!
    SetupHelper.reload_configs
    Rails.application.routes_reloader.reload!

    expect(Application.server_cache_version).to eq(server_cache_version)
    expect(master_skeleton_cache_key).not_to eq(original_skeleton_key)
    expect(Rails.cache.read(original_skeleton_key)).to eq(original_skeleton)

    visit page_url
    dismiss_modal
    expand_master_record_and_tab(master_id: @master_id, tab_name: 'details')
    finish_page_loading
    finish_form_formatting

    expect(page).to have_css(baseline_panel)
    expect(page).to have_css("#{baseline_panel} .new-button-container a.btn")
    expect(page).to have_css(discovery_panel)
    expect(page).to have_css("#{discovery_panel} .new-button-container a.btn")
  end
end