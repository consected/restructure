# frozen_string_literal: true

# Render-layer regression guard for GitHub Issue #665:
# "New fields appear in dynamic model instances that were created in a previous
# definition version"
#
# PR #1031 added a model-layer guard (spec/models/dynamic/versioned_field_list_spec.rb)
# but explicitly did NOT cover the rendering/template layer where the user-reported
# symptom actually appears. This request spec closes that gap: it exercises the
# per-record `template_config` endpoint (the path the browser uses to fetch the
# Handlebars template-config for a record), and asserts that a record created under
# an older definition version receives the OLD field list (`item_list`) — i.e. a
# field added to the definition later does not leak into the older record's
# rendered field set — while a record created under the current version does
# include the new field.
#
# This is the render-layer counterpart to PR #1031's
# `TemplateOptionMapping.dynamic_model_mapping[:item_list]` model-layer assertion,
# and is the mechanism through which the issue #1238 fix (emitting per-version
# template_config) keeps versioned records rendering correctly.
#
# Note: the emitted template_config also includes `field_types`, derived from all
# physical table columns, so the new column name appears there for every version.
# The assertions below therefore target the `item_list` value specifically, which
# is what the browser uses to decide which fields to show.

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe 'DynamicModel versioned field list rendering', type: :request do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport

  DmTableVersionedRender = 'test_created_by_recs'
  DmNewFieldVersionedRender = 'text_array'
  DmV1FieldsVersionedRender = 'test1 test2'
  DmV2FieldsVersionedRender = 'test1 test2 text_array'

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)
    # Definition-at-record-creation versioning must be active for an older record
    # to resolve to its historical definition version. In the test environment
    # DisableVDef already defaults to false, but set it explicitly so the
    # versioned behavior is self-documenting and cannot be accidentally disabled.
    @prev_disable_vdef = Settings::DisableVDef
    change_setting('DisableVDef', false)
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
    change_setting('DisableVDef', @prev_disable_vdef)
  end

  before(:each) do
    @admin = create_admin.first
    @user = create_user.first
    @master = create_master(@user)
    @master.current_user = @user

    @dm = setup_dynamic_model
    setup_access :dynamic_model__test_created_by_recs, user: @user
  end

  # Create the dynamic model with an explicit, restricted v1 field_list
  # ("test1 test2") on a table that physically also has the later-added
  # "text_array" column. This mirrors PR #1031's setup and lets us add the new
  # field to the definition (v2) without an ALTER TABLE.
  def setup_dynamic_model
    unless Admin::MigrationGenerator.table_exists?(DmTableVersionedRender)
      TableGenerators.dynamic_models_table(DmTableVersionedRender, :create_do,
                                           'test1', 'test2', 'created_by_user_id',
                                           'use_def_version_time', 'text_array')
    end

    DynamicModel.active.where(table_name: DmTableVersionedRender).each { |dm| dm.disable!(@admin) }

    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'test created by',
      table_name: DmTableVersionedRender,
      primary_key_name: :id,
      foreign_key_name: :master_id,
      field_list: DmV1FieldsVersionedRender,
      category: :test
    )
    dm.update_tracker_events
    dm.send :reset_all_versions
    DynamicModel.define_models
    DynamicModel.routes_reload
    Application.refresh_dynamic_defs
    dm
  end

  # Bump the dynamic model definition to v2, adding the new field. Migrations are
  # disabled during the save because the column already exists; we only need a new
  # version-history entry.
  def bump_dynamic_model
    sleep 2
    change_setting('AllowDynamicMigrations', nil)
    @dm.current_admin = @admin
    @dm.update!(field_list: DmV2FieldsVersionedRender)
    change_setting('AllowDynamicMigrations', true)
    DynamicModel.define_models
    DynamicModel.routes_reload
    Application.refresh_dynamic_defs
    @dm
  end

  def create_dm_record
    @master.dynamic_model__test_created_by_recs.create!(current_user: @user, test1: 'a value')
  end

  def template_config_path(rec)
    "/masters/#{@master.id}/#{rec.class.definition.base_route_segments}/#{rec.id}/template_config"
  end

  # Extract the emitted `item_list: '...'` value from the template_config response
  # so assertions target the field list specifically (not field_types, which lists
  # all physical columns).
  def emitted_item_list(body)
    body[/item_list:\s*'([^']*)'/, 1]
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

  describe 'per-record template_config field list' do
    it 'serves the older version field list for a record created before a field was added' do
      # Record created under v1 (fields: test1, test2)
      v1_record = create_dm_record

      # Add a new field to the definition (v2)
      bump_dynamic_model

      # Record created under v2 (fields: test1, test2, text_array)
      v2_record = create_dm_record

      # Confirm the records genuinely resolve to different definition versions
      v1_record = DynamicModel::TestCreatedByRec.find(v1_record.id)
      v1_record.current_user = @user
      expect(v1_record.versioned_definition.field_list_array).not_to include(DmNewFieldVersionedRender)

      # The v1 record's template_config must expose only the old fields
      get template_config_path(v1_record)
      expect(response).to have_http_status(:ok)
      v1_item_list = emitted_item_list(response.body)
      expect(v1_item_list).to be_present
      expect(v1_item_list).to include('test1')
      expect(v1_item_list).to include('test2')
      expect(v1_item_list).not_to include(DmNewFieldVersionedRender),
                                  "Expected v1 record item_list to exclude '#{DmNewFieldVersionedRender}', " \
                                  "but got: #{v1_item_list}"

      # The v2 record's template_config must include the new field
      get template_config_path(v2_record)
      expect(response).to have_http_status(:ok)
      v2_item_list = emitted_item_list(response.body)
      expect(v2_item_list).to include(DmNewFieldVersionedRender),
                              "Expected v2 record item_list to include '#{DmNewFieldVersionedRender}', " \
                              "but got: #{v2_item_list}"
    end
  end
end
