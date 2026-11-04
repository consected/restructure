# frozen_string_literal: true

# Request specs for issue #1238 — external identifier definition versioning and
# the page template.
#
# Background: ExternalIdentifier records use their definition's latest history
# row as the live `def_version`. They still never reference a historical
# definition version, so the global page template
# (app/views/external_identifiers/_search_results_template.html.erb) must emit
# ONLY the current-version config block for each EI definition — emitting
# historical blocks is unnecessary and incurs a performance cost (YAML parse for
# every history row of every EI definition on every page load).
#
# Previous behaviour (PR #1242) emitted historical EI version blocks via an
# `all_versions` loop. That loop has been removed because:
#   1. EI records never reference historical versions (they use the live version).
#   2. The EI `template_config` endpoint must provide current state for live
#      records because the page skeleton is cached independently of definition edits.
#   3. Emitting historical blocks causes a performance regression proportional to
#      the number of historical EI definition saves.
#
# These tests assert:
#   - The global page template emits the CURRENT version config block for an EI
#     definition (confirming it is rendered).
#   - It does NOT emit any historical version blocks for that EI definition.
#
# To exercise genuine field-label versioning (rather than only the id attribute,
# whose display caption is also influenced by the definition `label`), the
# external identifier is given an additional descriptive data field (`note`) via
# `extra_fields`, and it is that field's label that is changed between versions.

require 'rails_helper'
require './db/table_generators/external_identifiers_table'

RSpec.describe 'ExternalIdentifier versioned template config', type: :request do
  include ModelSupport
  include MasterSupport
  include ExternalIdentifierSupport

  it 'does not install the embedded-item before-action on unrelated EI actions' do
    callbacks = ExternalIdentifier::ExternalIdentifierController._process_action_callbacks.select do |callback|
      callback.filter == :handle_embedded_item
    end

    expect(callbacks).to be_empty
  end

  # rubocop:disable Lint/ConstantDefinitionInBlock
  EiNameVersionedTplCfg = 'test_show1238_eids'
  EiAttrVersionedTplCfg = 'test_show1238_id'
  EiExtraFieldVersionedTplCfg = 'note'
  # rubocop:enable Lint/ConstantDefinitionInBlock

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    # The underlying table (with its extra `note` column) is created directly
    # below, so auto migrations are not needed and are kept off to avoid a
    # table-comment migration competing for a lock during definition saves.
    change_setting('AllowDynamicMigrations', false)
    @prev_disable_vdef = Settings::DisableVDef
    # Ensure definition versioning is active so older versions are genuinely
    # distinct from the current version.
    change_setting('DisableVDef', false)

    create_external_identifier_table
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
    change_setting('DisableVDef', @prev_disable_vdef)
  end

  before(:each) do
    @admin = create_admin.first
    @user = create_user.first
    @master = create_master(@user)

    setup_external_identifier('EiFieldLabelV1')

    setup_access EiNameVersionedTplCfg.to_sym, user: @user, app_type: @user.app_type
    @external_identifier.send(:remove_implementation_class)
    @external_identifier.send(:remove_implementation_controller_class)
    ExternalIdentifier.reset_active_model_configurations!
    ExternalIdentifier.clear_all_versions_memo
    ExternalIdentifier.definition_cache.clear
    ExternalIdentifier.define_models
    @external_identifier.add_master_association
    Application.refresh_dynamic_defs
    Rails.application.routes_reloader.reload!
  end

  # Create the external identifier table, with an additional `note` data column
  # beyond the id attribute, so the definition can expose a genuine descriptive
  # field whose label can be versioned.
  def create_external_identifier_table
    TableGenerators.external_identifiers_table(EiNameVersionedTplCfg, true, EiAttrVersionedTplCfg, skip_if_exists: true)

    columns = Admin::MigrationGenerator.table_column_names(EiNameVersionedTplCfg)
    return if columns.include?(EiExtraFieldVersionedTplCfg)

    ActiveRecord::Base.connection.execute(
      "ALTER TABLE #{EiNameVersionedTplCfg} ADD COLUMN #{EiExtraFieldVersionedTplCfg} character varying"
    )
  end

  # Create (or re-enable) the external identifier definition exposing the `note`
  # field, with a distinctive label for it so we can detect which definition
  # version a given template-config block came from.
  def setup_external_identifier(field_label)
    ExternalIdentifier.active.where(name: EiNameVersionedTplCfg).each { |e| e.disable!(@admin) }

    @external_identifier = ExternalIdentifier.create!(
      name: EiNameVersionedTplCfg,
      label: 'Show 1238 EID',
      external_id_attribute: EiAttrVersionedTplCfg,
      extra_fields: EiExtraFieldVersionedTplCfg,
      min_id: 1,
      max_id: 99_999_999,
      disabled: false,
      current_admin: @admin,
      options: ei_options(field_label)
    )

    ExternalIdentifier.define_models
    Application.refresh_dynamic_defs
    @external_identifier
  end

  # Bump the external identifier definition to a new version, changing only the
  # `note` field label, recording a new entry in the definition's version
  # history. Version history is recorded independently of migrations.
  def bump_external_identifier(field_label)
    sleep 2
    ei = ExternalIdentifier.active.find_by(name: EiNameVersionedTplCfg)
    ei.current_admin = @admin
    ei.options = ei_options(field_label)
    ei.save!
    ExternalIdentifier.define_models
    Application.refresh_dynamic_defs
    ei
  end

  def ei_options(field_label)
    <<~OPTS
      default:
        labels:
          #{EiExtraFieldVersionedTplCfg}: "#{field_label}"
    OPTS
  end

  def template_config_path(record)
    "/masters/#{@master.id}/#{@external_identifier.base_route_segments}/#{record.id}/template_config"
  end

  def login_user(user = nil)
    user ||= @user
    sign_out :user
    user.confirmed_at ||= Time.now
    user.current_admin ||= @admin
    user.save
    get '/users/sign_in'
    expect(response.status).to eq 200
    sign_in user
  end

  before(:each) do
    login_user
  end

  describe 'older definition version field labels' do
    it 'keeps a historical-time record on the current external identifier definition' do
      @master.current_user = @user
      record = @master.public_send(@external_identifier.base_route_segments).create!(
        EiAttrVersionedTplCfg => 12_345,
        note: 'created before the definition update',
        no_track: true,
        current_user: @user
      )
      record.update_column(:created_at, 1.minute.ago)

      bump_external_identifier('EiFieldLabelV2')
      current_definition = ExternalIdentifier.active.find_by!(name: EiNameVersionedTplCfg)

      expect(record.reload.created_at).to be < current_definition.all_versions_query(limit: 1).first.fetch('updated_at')
      expect(record.def_version).to be_nil
      expect(record.versioned_definition).to eq(current_definition)
      expect(record.versioned_definition.options_text).to include('EiFieldLabelV2')
    end

    it 'does NOT emit historical version config blocks — EI records always use the current version' do
      bump_external_identifier('EiFieldLabelV2')

      ei = ExternalIdentifier.active.find_by(name: EiNameVersionedTplCfg)
      older_version = ei.all_versions
                        .map(&:def_version)
                        .compact
                        .uniq
                        .reject { |v| v == ei.all_versions.first&.def_version }
                        .first

      expect(older_version)
        .to be_present, 'expected the external identifier to have an older definition version in its history'

      name_with_option_type = "#{ei.item_type_name}_#{ei.default_options.name}".underscore

      # Reset memoization so the freshly bumped definition is re-fetched.
      ExternalIdentifier.reset_active_model_configurations!
      ExternalIdentifier.clear_all_versions_memo
      HandlebarsPrecompiler.cleanup_compiled_output

      get template_page_path(1)

      expect(response).to have_http_status(:ok)

      # The CURRENT version config block must use the latest history ID.
      expect(response.body)
        .to include("fpa_state_config--#{name_with_option_type}--v#{ei.current_def_version}"),
            "expected the current-version config block for #{name_with_option_type} to be present"

      # The live version is emitted; older versions are not loaded globally.
      expect(response.body)
        .not_to include("fpa_state_config--#{name_with_option_type}--v#{older_version}"),
                'expected NO historical version config block for the EI definition in the global page template'

      # The CURRENT field label must appear (the definition is rendered).
      expect(response.body).to include('EiFieldLabelV2')

      # The OLD field label must NOT appear — old blocks are not emitted.
      expect(response.body).not_to include('EiFieldLabelV1')
    end
  end

  describe 'global page template' do
    # The live EI templates are only delivered by the page skeleton. The template_config
    # endpoint returns state alone, so the skeleton must include the Handlebars templates.
    it 'emits the Handlebars result templates for the live definition' do
      ei = ExternalIdentifier.active.find_by(name: EiNameVersionedTplCfg)
      name_with_option_type = "#{ei.item_type_name}_#{ei.default_options.name}".underscore
      HandlebarsPrecompiler.cleanup_compiled_output

      get template_page_path(1)

      expect(response).to have_http_status(:ok)
      text = +response.body
      response.body.scan(
        %r{#{Regexp.escape(HandlebarsPrecompiler::URL_RELATIVE_PATH)}gen-([\w-]+)/multi/([\w.-]+\.js)}
      ).uniq.each do |key, filename|
        path = HandlebarsPrecompiler.multi_dir(key).join(filename)
        text << "\n" << File.read(path) if File.exist?(path)
      end

      expect(text).to include("fpa_state_config--#{name_with_option_type}--v#{ei.current_def_version}")
      expect(text).not_to include("fpa_state_config--#{name_with_option_type}--v#{ei.current_def_version}--form")
      expect(text).to include("#{name_with_option_type.hyphenate}-result-template")
    end
  end

  describe 'live template_config endpoint' do
    it 'returns a resource-scoped validator for the live definition' do
      @master.current_user = @user
      record = @master.public_send(@external_identifier.base_route_segments).create!(
        EiAttrVersionedTplCfg => 12_345,
        note: 'current note',
        no_track: true,
        current_user: @user
      )
      record.current_user = @user
      path = template_config_path(record)

      get path
      expect(response).to have_http_status(:ok)
      original_etag = response.headers['ETag']
      expect(original_etag).to be_present

      get path, headers: { 'HTTP_IF_NONE_MATCH' => original_etag }
      expect(response).to have_http_status(:not_modified)

      bump_external_identifier('EiFieldLabelV2')
      get path, headers: { 'HTTP_IF_NONE_MATCH' => original_etag }
      expect(response).to have_http_status(:ok)
      expect(response.headers['ETag']).not_to eq(original_etag)
      expect(response.body).to include('EiFieldLabelV2')
    ensure
      @external_identifier&.send(:remove_implementation_class)
      @external_identifier&.send(:remove_implementation_controller_class)
      ExternalIdentifier.reset_active_model_configurations!
      ExternalIdentifier.clear_all_versions_memo
      ExternalIdentifier.definition_cache.clear
    end

    it 'returns the live version state and v0 alias without bundle templates' do
      @master.current_user = @user
      association = @external_identifier.base_route_segments
      record = @master.public_send(association).create!(
        EiAttrVersionedTplCfg => 12_345,
        note: 'current note',
        no_track: true,
        current_user: @user
      )
      record.current_user = @user
      token = "v#{@external_identifier.current_def_version}"
      state_name = "#{@external_identifier.item_type_name}_default".underscore

      expect(ExternalIdentifier.active_model_configurations.pluck(:name)).to include(EiNameVersionedTplCfg)

      path = template_config_path(record)
      route = Rails.application.routes.recognize_path(path, method: :get)
      expect(route).to include(action: 'template_config'), "expected #{path} to route to template_config, got #{route.inspect}"
      get path

      expect(response).to have_http_status(:ok), "route=#{route.inspect}; response=#{response.body}"
      expect(response.body).to include("fpa_state_config--#{state_name}--#{token}")
      expect(response.body).to include('EiFieldLabelV1')
      expect(response.body).not_to include('EiFieldLabelV2')
      expect(response.body)
        .to include("set_v0(_fpa.state.template_config.#{state_name}, " \
                    "_fpa.state.template_config.#{state_name}.#{token});")
      expect(response.body).not_to include('_fpa.retrieve_requested_handlebars_templates')
      expect(response.body).not_to include('references_results')
    end
  end
end
