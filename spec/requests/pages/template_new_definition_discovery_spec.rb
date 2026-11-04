# frozen_string_literal: true

# Purpose (issue #1481): a full page-template load must discover newly active dynamic
# definitions and category changes through the database-derived skeleton cache key.
require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe 'Pages template discovery for new dynamic definitions', type: :request do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include CacheKeyMemoizationSupport

  before(:all) do
    @previous_allow_dynamic_migrations = Settings::AllowDynamicMigrations
    @previous_disable_vdef = Settings::DisableVDef
    @previous_perform_caching = Rails.configuration.action_controller.perform_caching
    @previous_cache_store = Rails.cache

    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.configuration.action_controller.perform_caching = true
    change_setting('AllowDynamicMigrations', true)
    change_setting('DisableVDef', false)

    dynamic_model_table_names.each do |table_name|
      next if Admin::MigrationGenerator.table_exists?(table_name)

      TableGenerators.dynamic_models_table(table_name, :create_do, 'test1', 'test2')
    end
  end

  after(:all) do
    Rails.configuration.action_controller.perform_caching = @previous_perform_caching
    Rails.cache = @previous_cache_store
    change_setting('AllowDynamicMigrations', @previous_allow_dynamic_migrations)
    change_setting('DisableVDef', @previous_disable_vdef)
  end

  before do
    @admin, = create_admin
    @user, = create_user
    @master = create_master(@user)
    @created_definitions = []
    @created_page_layouts = []
    sign_in @user

    dynamic_model_table_names.each do |table_name|
      DynamicModel.active.where(table_name:).reload.each do |definition|
        definition.reload
        definition.current_admin = @admin
        definition.disable!(@admin) unless definition.disabled?
      end
    end
  end

  after do
    @created_definitions.each do |definition|
      definition.reload
      definition.current_admin = @admin
      definition.disable!(@admin) unless definition.disabled?
    end

    @created_page_layouts.each do |layout|
      layout.reload
      layout.current_admin = @admin
      layout.disable!(@admin) unless layout.disabled?
    end
  end

  it 'serves the same cached skeleton when no dynamic definition changes' do
    template_version = template_version_for(@user)
    first_skeleton = page_template_text(template_id: template_version)
    skeleton_key = master_skeleton_cache_key

    expect(Rails.cache.read(skeleton_key)).to include('fpa_state_config--player_contact')

    expect_any_instance_of(ActionView::Base).not_to receive(:render)
      .with(partial: 'masters/search_results_template')

    second_skeleton = page_template_text(template_id: template_version, clean_compiled_output: false)

    expect(master_skeleton_cache_key).to eq(skeleton_key)
    expect(second_skeleton).to eq(first_skeleton)
  end

  it 'discovers a new details model and rotates the browser template version' do
    create_category_panel('details')
    existing_definition = create_dynamic_model(table_name: 'issue1481_existing_recs', category: 'details')
    access_control_timestamp = latest_access_control_timestamp

    old_template_version = template_version_for(@user)
    first_skeleton = page_template_text(template_id: old_template_version)
    old_skeleton_key = master_skeleton_cache_key
    old_etag = response.headers['ETag']
    server_cache_version = Application.server_cache_version

    expect_dynamic_model_markup(first_skeleton, existing_definition, category: 'details')

    discovery_definition = create_dynamic_model(
      table_name: 'issue1481_discovery_recs',
      category: 'details',
      preserve_cache: true,
      access_control_updated_at: access_control_timestamp
    )

    expect(Application.server_cache_version).to eq(server_cache_version)
    expect(first_skeleton).not_to match(dynamic_model_state_script_pattern(discovery_definition))
    expect(Rails.cache.read(old_skeleton_key)).to match(dynamic_model_state_script_pattern(existing_definition))
    expect(Rails.cache.read(old_skeleton_key)).not_to match(dynamic_model_state_script_pattern(discovery_definition))

    new_skeleton_key = master_skeleton_cache_key
    new_template_version = template_version_for(@user)
    expect(new_skeleton_key).not_to eq(old_skeleton_key)
    expect(new_template_version).not_to eq(old_template_version)

    new_skeleton = page_template_text(
      template_id: new_template_version,
      clean_compiled_output: false,
      headers: { 'HTTP_IF_NONE_MATCH' => old_etag }
    )

    expect(response).to have_http_status(:ok)
    expect(response.headers['ETag']).not_to eq(old_etag)
    expect_dynamic_model_markup(new_skeleton, existing_definition, category: 'details')
    expect_dynamic_model_markup(new_skeleton, discovery_definition, category: 'details')
    expect(Rails.cache.read(new_skeleton_key)).to match(dynamic_model_state_script_pattern(discovery_definition))
  end

  it 'discovers a new model in a page-layout category without editing the panel' do
    category = "issue1481-panel-#{SecureRandom.hex(4)}"
    layout = create_category_panel(category)
    create_category_panel('details')
    existing_definition = create_dynamic_model(table_name: 'issue1481_existing_recs', category: 'details')
    access_control_timestamp = latest_access_control_timestamp
    layout_updated_at = layout.reload.updated_at

    old_skeleton_key = master_skeleton_cache_key
    first_skeleton = page_template_text(template_id: template_version_for(@user))

    expect_dynamic_model_markup(first_skeleton, existing_definition, category: 'details')

    discovery_definition = create_dynamic_model(
      table_name: 'issue1481_discovery_recs',
      category:,
      preserve_cache: true,
      access_control_updated_at: access_control_timestamp
    )

    new_skeleton_key = master_skeleton_cache_key
    expect(new_skeleton_key).not_to eq(old_skeleton_key)
    expect(layout.reload.updated_at).to eq(layout_updated_at)

    new_skeleton = page_template_text(template_id: template_version_for(@user), clean_compiled_output: false)

    expect(first_skeleton).not_to match(dynamic_model_state_script_pattern(discovery_definition))
    expect_dynamic_model_markup(new_skeleton, existing_definition, category: 'details')
    expect_dynamic_model_markup(new_skeleton, discovery_definition, category:)
    expect(Rails.cache.read(new_skeleton_key)).to match(dynamic_model_state_script_pattern(discovery_definition))
  end

  it 'moves an existing model to its new category in the refreshed skeleton' do
    category = "issue1481-moved-#{SecureRandom.hex(4)}"
    create_category_panel('details')
    create_category_panel(category)
    definition = create_dynamic_model(table_name: 'issue1481_discovery_recs', category: 'details')

    old_skeleton_key = master_skeleton_cache_key
    first_skeleton = page_template_text(template_id: template_version_for(@user))
    expect_dynamic_model_markup(first_skeleton, definition, category: 'details')

    definition.current_admin = @admin
    allow(definition).to receive(:allow_migrations).and_return(false)
    definition.update!(category:)

    new_skeleton_key = master_skeleton_cache_key
    expect(new_skeleton_key).not_to eq(old_skeleton_key)

    new_skeleton = page_template_text(template_id: template_version_for(@user), clean_compiled_output: false)

    expect_dynamic_model_markup(new_skeleton, definition, category:)
    expect(new_skeleton).not_to match(dynamic_model_category_markup_pattern(definition, category: 'details'))
  end

  it 'recomputes a stable key from unchanged database state and a new key after a database change' do
    definition = create_dynamic_model(
      table_name: 'issue1481_discovery_recs', category: 'details', grant_access: false
    )

    first_key = master_skeleton_cache_key
    expect(master_skeleton_cache_key).to eq(first_key)

    definition.update_column(:category, 'issue1481-db-category-change')

    expect(master_skeleton_cache_key).not_to eq(first_key)
  end

  def dynamic_model_table_names
    %w[issue1481_existing_recs issue1481_discovery_recs]
  end

  def grant_dynamic_model_access(definition, table_name, preserve_cache: false, updated_at: nil)
    template_access_control = definition.add_user_access_controls(
      force: true,
      app_type: @user.app_type || Admin::AppType.active.first!
    )
    access_control = setup_access "dynamic_model__#{table_name}".to_sym, user: @user
    if updated_at
      [template_access_control, access_control].compact.each do |access_control_record|
        access_control_record.update_column(:updated_at, updated_at)
      end
    end
    DynamicModel.reset_active_model_configurations!
    access_control
  end

  def latest_access_control_timestamp
    Admin::UserAccessControl.where(app_type_id: [@user.app_type_id, nil]).maximum(:updated_at) || 3.seconds.ago
  end

  def create_dynamic_model(table_name:, category:, grant_access: true, preserve_cache: false,
                           access_control_updated_at: nil)
    if preserve_cache
      allow_any_instance_of(Admin::UserAccessControl)
        .to receive(:clear_rails_cache_on_save?).and_return(false)
    end

    definition = DynamicModel.create!(
      current_admin: @admin,
      name: "Issue1481 #{table_name}",
      table_name:,
      schema_name: 'dynamic_test',
      primary_key_name: 'id',
      foreign_key_name: 'master_id',
      category:,
      field_list: 'test1 test2',
      options: "default:\n  fields:\n    - test1\n    - test2\n"
    )
    definition.current_admin = @admin
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    @created_definitions << definition

    if grant_access
      grant_dynamic_model_access(
        definition,
        table_name,
        preserve_cache:,
        updated_at: access_control_updated_at
      )
    end
    definition
  end

  def create_category_panel(category)
    layout = Admin::PageLayout.create!(
      current_admin: @admin,
      app_type_id: @user.app_type_id,
      layout_name: 'master',
      panel_name: "issue1481-#{category}",
      panel_label: "Issue 1481 #{category}",
      panel_position: 303,
      options: "contains:\n  categories:\n    - #{category}\n"
    )
    @created_page_layouts << layout
    layout
  end

  def master_skeleton_cache_key
    reset_shared_helper_cache_key_memoization
    ApplicationController.helpers.master_templates_skeleton_cache_key(force_user_or_admin: @user)
  end

  def template_version_for(user)
    reset_shared_helper_cache_key_memoization
    Digest::SHA256.hexdigest(
      ApplicationController.helpers.partial_cache_key(:loaded, force_user_or_admin: user)
    )
  end

  def expect_dynamic_model_markup(text, definition, category:)
    plural_item_type_name = definition.full_item_types_name

    expect(text).to include("#{definition.resource_name.hyphenate}-list-template")
    expect(text).to match(dynamic_model_state_script_pattern(definition))
    expect(text).to match(dynamic_model_category_markup_pattern(definition, category:))
    expect(text).to match(/data-sub-list.{0,80}#{Regexp.escape(plural_item_type_name)}/)
  end

  def dynamic_model_state_script_pattern(definition)
    option_type_name = "#{definition.item_type_name}_#{definition.default_option_type_name}"
    /fpa_state_config--#{Regexp.escape(option_type_name)}--v\d+/
  end

  def dynamic_model_category_markup_pattern(definition, category:)
    item_type_class = definition.full_item_types_name.id_hyphenate
    /category-#{Regexp.escape(category)}[\s\S]{0,200}details-item-type-#{Regexp.escape(item_type_class)}/
  end

  def page_template_text(template_id: 'test', clean_compiled_output: true, headers: {})
    HandlebarsPrecompiler.cleanup_compiled_output if clean_compiled_output
    get "/pages/#{template_id}/template", headers: headers
    expect(response).to have_http_status(:ok)

    text = +response.body
    response.body.scan(
      %r{#{Regexp.escape(HandlebarsPrecompiler::URL_RELATIVE_PATH)}gen-([\w-]+)/multi/([\w.-]+\.js)}
    ).uniq.each do |key, filename|
      path = HandlebarsPrecompiler.multi_dir(key).join(filename)
      text << "\n" << File.read(path) if File.exist?(path)
    end
    text
  end
end