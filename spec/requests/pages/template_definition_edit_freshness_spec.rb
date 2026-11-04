# frozen_string_literal: true

# Regression specs for issues #1525/#1526 and #1481: config-only edits keep the
# cached page-template skeleton stable, while live template_config and index-data
# ETags include current local and referenced definition tokens across requests.
# Inputs baked into the skeleton (option type structure, reference captions, alt width
# classes, dynamic model position) move the skeleton signature; lazily delivered
# configuration does not. Bundle filenames are content addressed, so a permission change
# rotates the skeleton key but not the bundle unless the rendered content changes.
require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe 'Pages template freshness after dynamic definition edits', type: :request do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport

  def dynamic_model_table_name
    'issue1525_template_recs'
  end

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    @prev_disable_vdef = Settings::DisableVDef
    change_setting('AllowDynamicMigrations', true)
    change_setting('DisableVDef', false)
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
    change_setting('DisableVDef', @prev_disable_vdef)
  end

  before do
    @admin, = create_admin
    @user, = create_user
    @master = create_master(@user)
    sign_in @user

    unless Admin::MigrationGenerator.table_exists?(dynamic_model_table_name)
      TableGenerators.dynamic_models_table(dynamic_model_table_name, :create_do, 'test1', 'test2')
    end
  end

  after do
    if @dm&.persisted?
      @dm.reload
      @dm.disable!(@admin) unless @dm.disabled?
    end

    if @lib&.persisted?
      @lib.reload
      @lib.disable!(@admin) unless @lib.disabled?
    end
  end

  def create_dynamic_model(options)
    DynamicModel.active.where(table_name: dynamic_model_table_name).reload.each do |old_definition|
      old_definition.current_admin = @admin
      old_definition.disable!(@admin)
    end

    class_name = dynamic_model_table_name.singularize.ns_camelize
    DynamicModel.send(:remove_const, class_name) if DynamicModel.const_defined?(class_name, false)

    definition = DynamicModel.create!(
      current_admin: @admin,
      name: "Issue1525 template #{SecureRandom.hex(4)}",
      table_name: dynamic_model_table_name,
      schema_name: 'dynamic_test',
      category: :test,
      options:
    )
    definition.current_admin = @admin
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    setup_access :dynamic_model__issue1525_template_recs, user: @user
    DynamicModel.reset_active_model_configurations!
    # The definition only becomes active once access is set up, so its routes must be drawn now
    Rails.application.routes_reloader.reload!
    @dm = definition
  end

  def caption_options(caption)
    <<~YAML
      default:
        fields:
          - test1
          - test2
        caption_before:
          test1: #{caption}
    YAML
  end

  def live_caption_options(caption)
    <<~YAML
      _configurations:
        use_current_version: true

      default:
        fields:
          - test1
          - test2
        caption_before:
          test1: #{caption}
    YAML
  end

  def page_template_text(clean_compiled_output: true)
    HandlebarsPrecompiler.cleanup_compiled_output if clean_compiled_output
    get '/pages/test/template'
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

  def handlebars_bundle_urls(text)
    text.scan(
      %r{#{Regexp.escape(HandlebarsPrecompiler::URL_RELATIVE_PATH)}gen-[\w-]+/multi/[\w.-]+\.js}
    ).uniq
  end

  def skeleton_signature
    Application.refresh_dynamic_defs
    helpers = ApplicationController.helpers
    helpers.instance_variable_set(:@master_templates_skeleton_cache_signatures, nil)
    helpers.instance_variable_set(:@partial_cache_key_access_control_timestamps, nil)
    helpers.master_templates_skeleton_cache_signature(app_type_id: @user.app_type_id)
  end

  def save_definition_options_without_migration(definition, options)
    change_setting('AllowDynamicMigrations', false)
    begin
      definition.reload
      definition.current_admin = @admin
      definition.options = options
      definition.save!
    ensure
      change_setting('AllowDynamicMigrations', true)
    end
  end

  def master_skeleton_cache_key
    helpers = ApplicationController.helpers
    helpers.instance_variable_set(:@master_templates_skeleton_cache_signatures, nil)
    helpers.instance_variable_set(:@partial_cache_key_access_control_timestamps, nil)
    helpers.master_templates_skeleton_cache_key(force_user_or_admin: @user)
  end

  it 'keeps the cached skeleton after an options-only save' do
    previous_caching = Rails.configuration.action_controller.perform_caching
    Rails.configuration.action_controller.perform_caching = true
    skeleton_key = -> { master_skeleton_cache_key }
    definition = create_dynamic_model(live_caption_options('ProbeOne'))
    @master.current_user = @user
    record = @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'unchanged')
    original_skeleton_key = skeleton_key.call
    config_path = "/masters/#{@master.id}/#{definition.base_route_segments}/#{record.id}/template_config"
    page_template_text
    expect(response.body).to include('ProbeOne')
    expect(Rails.cache.read(original_skeleton_key)).to include('ProbeOne')
    original_bundle_urls = handlebars_bundle_urls(response.body)
    get config_path
    expect(response).to have_http_status(:ok)
    old_config_etag = response.headers['ETag']
    expect(response.body).to include('ProbeOne')

    change_setting('AllowDynamicMigrations', false)
    begin
      definition = DynamicModel.active.find(definition.id)
      definition.current_admin = @admin
      definition.options = live_caption_options('ProbeTwo')
      definition.save!
    ensure
      change_setting('AllowDynamicMigrations', true)
    end

    expect(skeleton_key.call).to eq(original_skeleton_key)
    page_template_text(clean_compiled_output: false)
    expect(skeleton_key.call).to eq(original_skeleton_key)
    expect(response.body).to include('ProbeOne')
    expect(response.body).not_to include('ProbeTwo')
    expect(handlebars_bundle_urls(response.body)).to eq(original_bundle_urls)

    get config_path, headers: { 'HTTP_IF_NONE_MATCH' => old_config_etag }
    expect(response).to have_http_status(:ok)
    expect(response.headers['ETag']).not_to eq(old_config_etag)
    expect(response.body).to include('ProbeTwo')
  ensure
    Rails.configuration.action_controller.perform_caching = previous_caching
  end

  it 'changes the cached index key for a record on an older definition version when the live definition changes' do
    previous_caching = Rails.configuration.action_controller.perform_caching
    Rails.configuration.action_controller.perform_caching = true

    definition = create_dynamic_model(caption_options('HistoricalBefore'))
    @master.current_user = @user
    record = @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'unchanged')
    original_token = record.vdef_version
    index_path = "/masters/#{@master.id}/#{definition.base_route_segments}"
    get index_path, params: { cache_result: 'true' }
    expect(response).to have_http_status(:ok)
    original_index_etag = response.headers['ETag']

    # Definition versions are selected by timestamp, so the edit must land after the record was created
    sleep 1.1
    save_definition_options_without_migration(definition, caption_options('HistoricalAfter'))
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    definition.refresh_current_def_version!

    # The record stays on its own definition version, so its own token cannot signal the change
    expect(record.reload.vdef_version).to eq(original_token)

    get index_path, params: { cache_result: 'true' }, headers: { 'HTTP_IF_NONE_MATCH' => original_index_etag }
    expect(response).to have_http_status(:ok)
    expect(response.headers['ETag']).not_to eq(original_index_etag)
  ensure
    Rails.configuration.action_controller.perform_caching = previous_caching
  end

  it 'refreshes live tokens and data ETags when definition versioning is disabled' do
    previous_caching = Rails.configuration.action_controller.perform_caching
    previous_disable_vdef = Settings::DisableVDef
    change_setting('DisableVDef', true)
    Rails.configuration.action_controller.perform_caching = true

    definition = create_dynamic_model(caption_options('DisableVDefBefore'))
    @master.current_user = @user
    record = @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'unchanged')
    original_history_id = definition.all_versions_query(limit: 1).first.fetch('id').to_i
    original_token = record.vdef_version
    expect(record.def_version).to be_nil
    expect(definition.current_def_version).to eq(original_history_id)
    expect(original_token).to eq("v#{original_history_id}")

    index_path = "/masters/#{@master.id}/#{definition.base_route_segments}"
    config_path = "/masters/#{@master.id}/#{definition.base_route_segments}/#{record.id}/template_config"
    get index_path, params: { cache_result: 'true' }
    expect(response).to have_http_status(:ok)
    original_index_etag = response.headers['ETag']
    get config_path
    expect(response).to have_http_status(:ok)
    original_config_etag = response.headers['ETag']

    save_definition_options_without_migration(definition, caption_options('DisableVDefAfter'))
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    definition.refresh_current_def_version!
    updated_history_id = definition.current_def_version
    record.reload
    updated_token = record.vdef_version

    expect(definition.def_version).to be_nil
    expect(updated_history_id).not_to eq(original_history_id)
    expect(updated_token).to eq("v#{updated_history_id}")
    expect(updated_token).not_to eq(original_token)

    get index_path, params: { cache_result: 'true' }, headers: { 'HTTP_IF_NONE_MATCH' => original_index_etag }
    expect(response).to have_http_status(:ok)
    expect(response.headers['ETag']).not_to eq(original_index_etag)
    expect(response.body).to include(updated_token)

    get config_path, headers: { 'HTTP_IF_NONE_MATCH' => original_config_etag }
    expect(response).to have_http_status(:ok)
    expect(response.headers['ETag']).not_to eq(original_config_etag)
    expect(response.body).to include("vdef_version: '#{updated_token}'")
  ensure
    Rails.configuration.action_controller.perform_caching = previous_caching
    change_setting('DisableVDef', previous_disable_vdef)
  end

  it 'tracks active definition identity changes without including option edits' do
    signature_before_add = skeleton_signature
    definition = create_dynamic_model(live_caption_options('SignatureOne'))
    signature_after_add = skeleton_signature
    expect(signature_after_add).not_to eq(signature_before_add)

    change_setting('AllowDynamicMigrations', false)
    begin
      definition.current_admin = @admin
      definition.options = live_caption_options('SignatureTwo')
      definition.save!
      expect(skeleton_signature).to eq(signature_after_add)

      definition.name = "Renamed template #{SecureRandom.hex(3)}"
      definition.save!
    ensure
      change_setting('AllowDynamicMigrations', true)
    end
    signature_after_rename = skeleton_signature
    expect(signature_after_rename).not_to eq(signature_after_add)

    definition.disable!(@admin)
    signature_after_disable = skeleton_signature
    expect(signature_after_disable).not_to eq(signature_after_rename)

    definition.reload.enable!(@admin)
    signature_after_enable = skeleton_signature
    expect(signature_after_enable).not_to eq(signature_after_disable)
  end

  it 'tracks bundled option structure but ignores template state changes' do
    definition = create_dynamic_model(live_caption_options('StructureOne'))
    original_signature = skeleton_signature

    save_definition_options_without_migration(definition, <<~YAML)
      _configurations:
        use_current_version: true

      default:
        fields: [test1]
        label: Changed label
        caption_before:
          test1: StructureTwo
        show_if: {}
        field_options:
          test1:
            disabled: true
    YAML
    expect(skeleton_signature).to eq(original_signature)

    save_definition_options_without_migration(definition, <<~YAML)
      _configurations:
        use_current_version: true

      default:
        fields: [test1, test2]
        caption_before:
          test1: StructureTwo
      secondary:
        fields: [test2]
    YAML
    option_type_signature = skeleton_signature
    expect(option_type_signature).not_to eq(original_signature)

    save_definition_options_without_migration(definition, <<~YAML)
      _configurations:
        use_current_version: true

      default:
        fields: [test1, test2]
        references:
          player_contacts:
            from: this
            add: one_to_this
      secondary:
        fields: [test2]
    YAML
    references_signature = skeleton_signature
    expect(references_signature).not_to eq(option_type_signature)

    save_definition_options_without_migration(definition, <<~YAML)
      _configurations:
        use_current_version: true

      default:
        fields: [test1, test2]
        embed: player_contact
        references:
          player_contacts:
            from: this
            add: one_to_this
      secondary:
        fields: [test2]
    YAML
    expect(skeleton_signature).not_to eq(references_signature)
  end

  it 'tracks dynamic model position, alt_width_classes and reference captions baked into the skeleton' do
    options_with = lambda do |view_options: '', reference_caption: 'RefOne', label: 'Label'|
      <<~YAML
        _configurations:
          use_current_version: true

        default:
          fields: [test1, test2]
          label: #{label}
          #{view_options}
          caption_before:
            test1: TemplateConfigOnly #{label}
            reference_player_contacts: #{reference_caption}
          references:
            player_contacts:
              from: this
              add: one_to_this
      YAML
    end
    definition = create_dynamic_model(options_with.call)
    original_signature = skeleton_signature
    original_key = master_skeleton_cache_key

    # A purely lazily delivered edit (label and non-reference caption) must not move the skeleton
    save_definition_options_without_migration(definition, options_with.call(label: 'Changed label'))
    expect(skeleton_signature).to eq(original_signature)
    expect(master_skeleton_cache_key).to eq(original_key)

    definition.reload.update_columns(position: definition.position.to_i + 7)
    position_signature = skeleton_signature
    expect(position_signature).not_to eq(original_signature)
    expect(master_skeleton_cache_key).not_to eq(original_key)

    save_definition_options_without_migration(
      definition, options_with.call(label: 'Changed label', view_options: "view_options:\n    alt_width_classes: col-md-8")
    )
    alt_width_signature = skeleton_signature
    expect(alt_width_signature).not_to eq(position_signature)

    save_definition_options_without_migration(
      definition,
      options_with.call(label: 'Changed label', reference_caption: 'RefTwo',
                        view_options: "view_options:\n    alt_width_classes: col-md-8")
    )
    expect(skeleton_signature).not_to eq(alt_width_signature)
  end

  it 'tracks dynamic-definition category changes in the skeleton signature' do
    definition = create_dynamic_model(live_caption_options('CategoryOne'))
    original_signature = skeleton_signature

    definition.update_columns(category: 'structural-category-change')

    expect(skeleton_signature).not_to eq(original_signature)
  end

  it 'rotates the skeleton for layout and permission changes, the bundle only when rendered content changes' do
    previous_caching = Rails.configuration.action_controller.perform_caching
    Rails.configuration.action_controller.perform_caching = true
    definition = create_dynamic_model(live_caption_options('BundleOne'))
    layout = Admin::PageLayout.create!(
      current_admin: @admin,
      app_type_id: @user.app_type_id,
      layout_name: 'master',
      panel_name: "bundle-rotation-#{SecureRandom.hex(4)}",
      panel_label: 'Initial bundle panel',
      panel_position: 302,
      options: "contains:\n  resources:\n    - player_contacts\n"
    )
    player_contacts_access = setup_access(:player_contacts, user: @user)
    player_contacts_access.update!(app_type: nil, current_admin: @admin)
    initial_key = master_skeleton_cache_key
    initial_text = page_template_text
    initial_bundle_urls = handlebars_bundle_urls(initial_text)
    expect(initial_bundle_urls).not_to be_empty

    save_definition_options_without_migration(definition, live_caption_options('BundleTwo'))
    expect(master_skeleton_cache_key).to eq(initial_key)
    config_only_text = page_template_text(clean_compiled_output: false)
    expect(handlebars_bundle_urls(config_only_text)).to eq(initial_bundle_urls)

    layout.update!(panel_label: 'Updated bundle panel', current_admin: @admin)
    layout_key = master_skeleton_cache_key
    expect(layout_key).not_to eq(initial_key)
    layout_text = page_template_text(clean_compiled_output: false)
    layout_bundle_urls = handlebars_bundle_urls(layout_text)
    expect(layout_bundle_urls).not_to eq(initial_bundle_urls)

    previous_timestamp =
      Admin::UserAccessControl.where(app_type_id: [@user.app_type_id, nil]).maximum(:updated_at) ||
      Time.current
    permission_updated_at = previous_timestamp + 3.seconds
    player_contacts_access.update!(access: nil, current_admin: @admin)
    player_contacts_access.update_column(:updated_at, permission_updated_at)

    permission_key = master_skeleton_cache_key
    expect(permission_key).not_to eq(layout_key)
    permission_text = page_template_text(clean_compiled_output: false)
    permission_bundle_urls = handlebars_bundle_urls(permission_text)
    # Bundle filenames are content-addressed since Phase 1 (no access-control version), so a
    # permission change rotates the skeleton key but only changes the bundle when it changes
    # the rendered template content, which revoking this access does not.
    expect(permission_bundle_urls).to eq(layout_bundle_urls)
  ensure
    Rails.configuration.action_controller.perform_caching = previous_caching
  end

  it 'reuses a definition structure digest until its live template token changes' do
    definition = create_dynamic_model(caption_options('StructureCache'))
    helper = Object.new.extend(ApplicationHelper)
    token = definition.current_def_version
    allow(definition).to receive(:option_configs).and_call_original
    allow(definition).to receive(:template_version_token) { token }

    first_structure = helper.master_templates_definition_structure(definition)
    expect(helper.master_templates_definition_structure(definition)).to eq(first_structure)
    expect(definition).to have_received(:option_configs).once

    token += 1
    expect(helper.master_templates_definition_structure(definition)).to eq(first_structure)
    expect(definition).to have_received(:template_version_token).exactly(3).times
    expect(definition).to have_received(:option_configs).twice
  end

  it 'tracks activity-log item and record types in the skeleton signature' do
    activity_log = ActivityLog.active.first!
    original_rec_type = activity_log.rec_type
    original_signature = skeleton_signature

    activity_log.update_columns(rec_type: "structural-#{SecureRandom.hex(4)}")

    expect(skeleton_signature).not_to eq(original_signature)
  ensure
    activity_log&.update_columns(rec_type: original_rec_type) if original_rec_type
  end

  it 'keeps a config-library edit out of the skeleton and refreshes template_config' do
    previous_caching = Rails.configuration.action_controller.perform_caching
    Rails.configuration.action_controller.perform_caching = true
    suffix = SecureRandom.hex(4)
    category = "issue1525cat#{suffix}"
    name = "issue1525lib#{suffix}"
    @lib = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name:,
      category:,
      format: 'yaml',
      options: "_definitions_lib:\n  cap: &cap LibOne\n"
    )
    create_dynamic_model(<<~YAML)
      _configurations:
        use_current_version: true

      # @library #{category} #{name}
      default:
        fields: [test1, test2]
        caption_before:
          test1: *cap
    YAML

    definition = @dm
    @master.current_user = @user
    record = @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'unchanged')
    skeleton_key = master_skeleton_cache_key
    original_skeleton_text = page_template_text
    expect(response.body).to include('LibOne')
    original_bundle_urls = handlebars_bundle_urls(response.body)
    index_path = "/masters/#{@master.id}/#{definition.base_route_segments}"
    get index_path, params: { cache_result: 'true' }
    expect(response).to have_http_status(:ok)
    original_index_etag = response.headers['ETag']
    original_token = record.vdef_version
    history_id = definition.current_def_version
    library_updated_at = @lib.updated_at
    config_path = "/masters/#{@master.id}/#{definition.base_route_segments}/#{record.id}/template_config"
    allow(Dynamic::TemplateVersionTokens).to receive(:live_config_library_tokens).and_call_original
    get config_path
    expect(response).to have_http_status(:ok)
    expect(Dynamic::TemplateVersionTokens).to have_received(:live_config_library_tokens).once
    old_config_etag = response.headers['ETag']
    expect(response.body).to include('LibOne')

    @lib.current_admin = @admin
    @lib.options = "_definitions_lib:\n  cap: &cap LibTwo\n"
    @lib.save!
    @lib.update_columns(updated_at: library_updated_at + 1.second)
    definition.refresh_current_def_version!

    expect(master_skeleton_cache_key).to eq(skeleton_key)
    expect(definition.current_def_version).to eq(history_id)
    expect(definition.template_version_token).to be >= 1_000_000_000_000
    expect(definition.template_version_token).not_to eq(history_id)
    updated_skeleton_text = page_template_text(clean_compiled_output: false)
    expect(response.body).to include('LibOne')
    expect(response.body).not_to include('LibTwo')
    expect(handlebars_bundle_urls(updated_skeleton_text)).to eq(original_bundle_urls)
    expect(original_skeleton_text).to include('LibOne')

    get index_path, params: { cache_result: 'true' }, headers: { 'HTTP_IF_NONE_MATCH' => original_index_etag }
    expect(response).to have_http_status(:ok)
    expect(response.headers['ETag']).not_to eq(original_index_etag)
    updated_token = "v#{definition.template_version_token}"
    expect(record.vdef_version).to eq(updated_token)
    expect(record.vdef_version).not_to eq(original_token)

    get config_path, headers: { 'HTTP_IF_NONE_MATCH' => old_config_etag }
    expect(response).to have_http_status(:ok)
    expect(response.headers['ETag']).not_to eq(old_config_etag)
    expect(response.body).to include('LibTwo')
  ensure
    Rails.configuration.action_controller.perform_caching = previous_caching
  end

  it 'refreshes definitions before rendering a cross-process options update' do
    definition = create_dynamic_model(caption_options('WorkerOne'))
    expect(page_template_text).to include('WorkerOne')

    cached_updated_at = definition.reload.updated_at
    definition.update_columns(options: caption_options('WorkerTwo'), updated_at: cached_updated_at + 3.seconds)

    text = page_template_text
    expect(text).to include('WorkerTwo')
    expect(text).not_to include('WorkerOne')
  end

  it 'refreshes a live definition token before serializing a show response' do
    definition = create_dynamic_model(live_caption_options('ShowBefore'))
    @master.current_user = @user
    record = @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'show')
    path = "/masters/#{@master.id}/#{definition.base_route_segments}/#{record.id}"
    stale_definition = record.current_definition
    old_token = stale_definition.current_def_version

    worker_definition = DynamicModel.find(definition.id)
    worker_definition.current_admin = @admin
    worker_definition.options = live_caption_options('ShowAfter')
    change_setting('AllowDynamicMigrations', false)
    begin
      worker_definition.save!
    ensure
      change_setting('AllowDynamicMigrations', true)
    end

    DynamicModel.definition_cache[definition.id] = stale_definition
    expect(stale_definition.current_def_version).to eq(old_token)
    new_token = worker_definition.current_def_version
    expect(new_token).not_to eq(old_token)
    expect(record.current_definition).to equal(stale_definition)
    expect(stale_definition).to receive(:refresh_current_def_version!).once.and_call_original

    get path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("\"vdef_version\":\"v#{new_token}\"")
  end

  it 'revalidates cached data after another worker changes only the live definition' do
    definition = create_dynamic_model(live_caption_options('WorkerOne'))
    @master.current_user = @user
    record = @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'unchanged')
    expect(record.def_version).to be_nil
    path = "/masters/#{@master.id}/#{definition.base_route_segments}"
    expect(Rails.application.routes.recognize_path(path, method: :get)[:action]).to eq('index')

    get path, params: { cache_result: 'true' }
    expect(response).to have_http_status(:ok)
    old_token = "v#{definition.current_def_version}"
    old_etag = response.headers['ETag']
    expect(response.body).to include("\"vdef_version\":\"#{old_token}\"")
    expect(old_etag).to be_present

    stale_definition = DynamicModel.definition_cache.fetch(definition.id)
    expect(stale_definition.current_def_version).to eq(definition.current_def_version)
    stale_updated_at = stale_definition.updated_at
    worker_definition = DynamicModel.find(definition.id)
    worker_definition.current_admin = @admin
    worker_definition.options = live_caption_options('WorkerTwo')
    change_setting('AllowDynamicMigrations', false)
    begin
      worker_definition.save!
      worker_definition.update_columns(updated_at: stale_updated_at + 3.seconds)
    ensure
      change_setting('AllowDynamicMigrations', true)
    end

    expect(stale_definition.current_def_version).to eq(old_token.delete_prefix('v').to_i)
    expect(record.reload.updated_at).to be_present

    get path, params: { cache_result: 'true' }, headers: { 'HTTP_IF_NONE_MATCH' => old_etag }
    expect(response).to have_http_status(:ok)
    expect(response.headers['ETag']).not_to eq(old_etag)
    expect(response.body).to include("\"vdef_version\":\"v#{worker_definition.current_def_version}\"")
  end

  it 'returns 304 for unchanged index data and refreshes after a live definition edit' do
    definition = create_dynamic_model(live_caption_options('WorkerOne'))
    @master.current_user = @user
    record = @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'unchanged')
    path = "/masters/#{@master.id}/#{definition.base_route_segments}"
    record_updated_at = record.reload.updated_at

    get path, params: { cache_result: 'true' }
    expect(response).to have_http_status(:ok)
    original_etag = response.headers['ETag']
    expect(original_etag).to be_present

    get path, params: { cache_result: 'true' }, headers: { 'HTTP_IF_NONE_MATCH' => original_etag }
    expect(response).to have_http_status(:not_modified)

    unrelated_master = create_master(@user)
    unrelated_master.current_user = @user
    unrelated_master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'outside-index')
    get path, params: { cache_result: 'true' }, headers: { 'HTTP_IF_NONE_MATCH' => original_etag }
    expect(response).to have_http_status(:not_modified)

    stale_definition = DynamicModel.definition_cache.fetch(definition.id)
    stale_updated_at = stale_definition.updated_at
    worker_definition = DynamicModel.find(definition.id)
    worker_definition.current_admin = @admin
    worker_definition.options = live_caption_options('WorkerTwo')
    change_setting('AllowDynamicMigrations', false)
    begin
      worker_definition.save!
      worker_definition.update_columns(updated_at: stale_updated_at + 3.seconds)
    ensure
      change_setting('AllowDynamicMigrations', true)
    end

    expect(record.reload.updated_at).to eq(record_updated_at)
    get path, params: { cache_result: 'true' }, headers: { 'HTTP_IF_NONE_MATCH' => original_etag }
    expect(response).to have_http_status(:ok)
    expect(response.headers['ETag']).not_to eq(original_etag)
  end

  it 'caches template_config by its live resource token, not unrelated definition updates' do
    definition = create_dynamic_model(live_caption_options('ConfigOne'))
    @master.current_user = @user
    record = @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'unchanged')
    expect(record.def_version).to be_nil
    path = "/masters/#{@master.id}/#{definition.base_route_segments}/#{record.id}/template_config"

    get path
    expect(response).to have_http_status(:ok)
    original_etag = response.headers['ETag']
    expect(original_etag).to be_present

    Admin::MessageTemplate.create!(
      name: "unrelated-template-config-#{SecureRandom.hex(4)}",
      category: 'guest_reference',
      message_type: :dialog,
      template_type: :content,
      template: 'unrelated',
      current_admin: @admin
    )
    get path, headers: { 'HTTP_IF_NONE_MATCH' => original_etag }
    expect(response).to have_http_status(:not_modified)

    worker_definition = DynamicModel.find(definition.id)
    worker_definition.current_admin = @admin
    worker_definition.options = live_caption_options('ConfigTwo')
    stale_updated_at = definition.updated_at
    change_setting('AllowDynamicMigrations', false)
    begin
      worker_definition.save!
      worker_definition.update_columns(updated_at: stale_updated_at + 3.seconds)
    ensure
      change_setting('AllowDynamicMigrations', true)
    end

    get path, headers: { 'HTTP_IF_NONE_MATCH' => original_etag }
    expect(response).to have_http_status(:ok)
    expect(response.headers['ETag']).not_to eq(original_etag)
    expect(response.body).to include('ConfigTwo')
  end

  it 'emits the live state of a referenced dynamic model in the referencing record template_config' do
    create_dynamic_model(live_caption_options('RootCaption'))
    ref_table = 'issue1525_ref_recs'
    TableGenerators.dynamic_models_table(ref_table, :create_do, 'test1', 'test2') unless
      Admin::MigrationGenerator.table_exists?(ref_table)
    DynamicModel.send(:remove_const, ref_table.singularize.ns_camelize) if
      DynamicModel.const_defined?(ref_table.singularize.ns_camelize, false)
    ref_definition = DynamicModel.create!(
      current_admin: @admin, name: "Issue1525 ref #{SecureRandom.hex(4)}", table_name: ref_table,
      schema_name: 'dynamic_test', category: :test, options: live_caption_options('RefCaption')
    )
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    setup_access :dynamic_model__issue1525_ref_recs, user: @user
    save_definition_options_without_migration(@dm, <<~YAML)
      _configurations:
        use_current_version: true

      default:
        fields:
          - test1
          - test2
        caption_before:
          test1: RootCaption
        references:
          dynamic_model__issue1525_ref_recs:
            from: this
            add: many
    YAML
    DynamicModel.reset_active_model_configurations!
    Application.refresh_dynamic_defs
    @master.current_user = @user
    root = @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'root')
    referenced = @master.dynamic_model__issue1525_ref_recs.create!(current_user: @user, test1: 'referenced')
    ModelReference.create_with(root, referenced, force_create: true)
    expect(root.reload.model_references.map(&:to_record_id)).to include(referenced.id)

    get "/masters/#{@master.id}/#{@dm.base_route_segments}/#{root.id}/template_config"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('RootCaption')
    expect(response.body).to include('RefCaption')
  ensure
    ref_definition&.reload&.disable!(@admin) unless ref_definition&.disabled?
  end

  it 'revalidates index data when only a referenced definition changes' do
    create_dynamic_model(live_caption_options('RootCaption'))
    ref_table = 'issue1525_ref_recs'
    TableGenerators.dynamic_models_table(ref_table, :create_do, 'test1', 'test2') unless
      Admin::MigrationGenerator.table_exists?(ref_table)
    DynamicModel.send(:remove_const, ref_table.singularize.ns_camelize) if
      DynamicModel.const_defined?(ref_table.singularize.ns_camelize, false)
    ref_definition = DynamicModel.create!(
      current_admin: @admin, name: "Issue1525 ref #{SecureRandom.hex(4)}", table_name: ref_table,
      schema_name: 'dynamic_test', category: :test, options: live_caption_options('RefCaption')
    )
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    setup_access :dynamic_model__issue1525_ref_recs, user: @user
    save_definition_options_without_migration(@dm, <<~YAML)
      _configurations:
        use_current_version: true

      default:
        fields:
          - test1
          - test2
        caption_before:
          test1: RootCaption
        references:
          dynamic_model__issue1525_ref_recs:
            from: this
            add: many
    YAML
    DynamicModel.reset_active_model_configurations!
    Application.refresh_dynamic_defs
    @master.current_user = @user
    root = @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'root')
    referenced = @master.dynamic_model__issue1525_ref_recs.create!(current_user: @user, test1: 'referenced')
    ModelReference.create_with(root, referenced, force_create: true)
    model_references = root.reload.model_references
    expect(model_references).not_to be_empty
    model_reference = model_references.find { |reference| reference.to_record_id == referenced.id }
    expect(model_reference).to be_present
    model_reference.current_user = @user
    referenced_record = model_reference.to_record
    expect(referenced_record).to respond_to(:vdef_version)
    original_referenced_vdef_version = referenced_record.vdef_version
    expect(original_referenced_vdef_version).to be_present
    original_root_vdef_version = root.vdef_version
    root_updated_at = root.updated_at
    referenced_updated_at = referenced_record.updated_at
    path = "/masters/#{@master.id}/#{@dm.base_route_segments}"

    get path, params: { cache_result: 'true' }
    expect(response).to have_http_status(:ok)
    original_etag = response.headers['ETag']
    expect(original_etag).to be_present
    expect(response.body).to include('model_references')

    save_definition_options_without_migration(ref_definition, live_caption_options('RefAfter'))
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    ref_definition.refresh_current_def_version!
    root.reload
    referenced_record.reload
    updated_referenced_vdef_version = referenced_record.vdef_version
    expect(root.vdef_version).to eq(original_root_vdef_version)
    expect(root.updated_at).to eq(root_updated_at)
    expect(referenced_record.updated_at).to eq(referenced_updated_at)
    expect(updated_referenced_vdef_version).not_to eq(original_referenced_vdef_version)

    get path, params: { cache_result: 'true' }, headers: { 'HTTP_IF_NONE_MATCH' => original_etag }
    expect(response).to have_http_status(:ok)
    expect(response.headers['ETag']).not_to eq(original_etag)
  ensure
    ref_definition&.reload&.disable!(@admin) unless ref_definition&.disabled?
  end

  it 'collects template-config cache dependencies from one representative per definition version' do
    create_dynamic_model(live_caption_options('Representative'))
    @master.current_user = @user
    definition_class = DynamicModel.const_get(dynamic_model_table_name.singularize.ns_camelize)
    records = [
      @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'first'),
      @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'second')
    ]
    controller = DynamicModel::DynamicModelsController.new
    controller.instance_variable_set(:@instance_list, records)

    cache_records = controller.send(:template_config_records)

    expect(cache_records.count { |record| record.instance_of?(definition_class) }).to eq(1)
  end

  it 'refreshes live tokens without walking model references for every record' do
    create_dynamic_model(live_caption_options('BoundedRefresh'))
    @master.current_user = @user
    records = [
      @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'first'),
      @master.dynamic_model__issue1525_template_recs.create!(current_user: @user, test1: 'second')
    ]
    controller = DynamicModel::DynamicModelsController.new
    expect(records.first).to receive(:model_references).once.and_return([])
    expect(records.second).not_to receive(:model_references)

    controller.send(:refresh_live_template_version_tokens, records)
  end

  it 'does not refresh dynamic definitions when revalidating a matching template etag' do
    token = begin
      get '/masters/search'
      expect(response).to have_http_status(:ok)
      match = response.body.match(/_fpa\.state\.template_version\s*=\s*'([a-f0-9]{64})'/)
      expect(match).to be_present
      match[1]
    end

    get "/pages/#{token}/template"
    expect(response).to have_http_status(:ok)
    etag = response.headers['ETag']
    expect(etag).to be_present

    expect(Application).not_to receive(:refresh_dynamic_defs)
    get "/pages/#{token}/template", headers: { 'HTTP_IF_NONE_MATCH' => etag }
    expect(response).to have_http_status(:not_modified)
  end
end
