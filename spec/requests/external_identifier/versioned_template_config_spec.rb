# frozen_string_literal: true

# Request specs for issue #1238 — extending the definition-versioning fix to
# external identifiers.
#
# Background: the master record search-results page emits, at page load, the
# Handlebars template-config <script> blocks for every active definition (see
# app/views/common_templates/_search_results_template.html.erb). For dynamic
# models and activity logs the global page template iterates the definition's
# version history (`all_versions`) so that records created under an older
# definition version can still resolve their `.v<def_version>` template-config
# key. The external identifier global template
# (app/views/external_identifiers/_search_results_template.html.erb) previously
# emitted only the current version, so an external identifier record created
# before a definition version bump could not resolve its older version key and
# its show-mode form would silently fail to render.
#
# These tests assert that the page template (pages#template) emits a per-version
# template-config block for an external identifier's older definition version,
# including the field labels captured at that version, in addition to the current
# version. Without the fix only the current version's block is present.
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

  EiNameVersionedTplCfg = 'test_show1238_eids'
  EiAttrVersionedTplCfg = 'test_show1238_id'
  EiExtraFieldVersionedTplCfg = 'note'

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
    it 'emits a per-version template-config block for an older definition version on the page template' do
      bump_external_identifier('EiFieldLabelV2')

      ei = ExternalIdentifier.active.find_by(name: EiNameVersionedTplCfg)
      current_version = ei.all_versions.first&.def_version
      older_version = ei.all_versions
                        .map(&:def_version)
                        .compact
                        .uniq
                        .reject { |v| v == current_version }
                        .first

      expect(older_version)
        .to be_present, 'expected the external identifier to have an older definition version in its history'

      name_with_option_type = "#{ei.item_type_name}_#{ei.default_options.name}".underscore

      get template_page_path(1)

      expect(response).to have_http_status(:ok)

      # The fix: the older version's block must also be emitted, carrying the
      # `note` field label captured at that version. Without the fix only the
      # current version's block (and thus only the current label) is present.
      expect(response.body)
        .to include("fpa_state_config--#{name_with_option_type}--v#{older_version}")
      # EiFieldLabelV2 is the current version's `note` label; EiFieldLabelV1
      # belongs to the older version and is only present when the older version's
      # block is emitted.
      expect(response.body).to include('EiFieldLabelV1')
      expect(response.body).to include('EiFieldLabelV2')
    end
  end
end
