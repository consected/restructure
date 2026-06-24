# frozen_string_literal: true

# Request specs for issue #1238 — external identifier definition versioning and
# the page template.
#
# Background: ExternalIdentifier records always return `def_version = nil`
# (hard-coded in `Dynamic::ExternalIdImplementer#def_version`). This means EI
# records NEVER reference a historical definition version; they always resolve
# against the current version. Therefore the global page template
# (app/views/external_identifiers/_search_results_template.html.erb) must emit
# ONLY the current-version config block for each EI definition — emitting
# historical blocks is unnecessary and incurs a performance cost (YAML parse for
# every history row of every EI definition on every page load).
#
# Previous behaviour (PR #1242) emitted historical EI version blocks via an
# `all_versions` loop. That loop has been removed because:
#   1. EI records never reference historical versions (def_version is always nil).
#   2. The EI `template_config` controller action returns an empty response, so
#      no on-demand fallback exists — but one is not needed for the same reason.
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

    setup_access EiNameVersionedTplCfg.to_sym, user: @user
  end

  # Create the external identifier table, with an additional `note` data column
  # beyond the id attribute, so the definition can expose a genuine descriptive
  # field whose label can be versioned.
  def create_external_identifier_table
    unless Admin::MigrationGenerator.table_exists?(EiNameVersionedTplCfg)
      TableGenerators.external_identifiers_table(EiNameVersionedTplCfg, true, EiAttrVersionedTplCfg)
    end

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
      ExternalIdentifier.all_versions_memo = {}
      HandlebarsPrecompiler.cleanup_public_dir

      get template_page_path(1)

      expect(response).to have_http_status(:ok)

      # The CURRENT version config block must be present (the EI is rendered).
      expect(response.body)
        .to include("fpa_state_config--#{name_with_option_type}--v"),
            "expected the current-version config block for #{name_with_option_type} to be present"

      # No HISTORICAL version config block must be present. EI records always
      # return def_version = nil, so historical configs are never referenced.
      # Emitting them is a pure performance cost with no functional benefit.
      expect(response.body)
        .not_to match(/fpa_state_config--#{Regexp.escape(name_with_option_type)}--v\d+/),
                'expected NO historical version config block for the EI definition in the global page template'

      # The CURRENT field label must appear (the definition is rendered).
      expect(response.body).to include('EiFieldLabelV2')

      # The OLD field label must NOT appear — old blocks are not emitted.
      expect(response.body).not_to include('EiFieldLabelV1')
    end
  end
end
