# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Regression guard for GitHub Issue #665:
# "New fields appear in dynamic model instances that were created in a previous definition version"
#
# These specs lock in the CURRENT, CORRECT behavior at the model layer:
# when a dynamic model definition is versioned (an explicit field_list is set and later changed),
# records associated with the older version expose only the fields that existed at that time.
# Specifically, when a new field is added to a DM definition, it must NOT appear in:
#   - the versioned definition's field_list_array
#   - the versioned option_type_config fields
#   - the edit_form_field_list of instances pinned to the prior version
#   - the TemplateOptionMapping item_list for the prior version
#
# Strategy: The test table test_created_by_recs has columns: test1, test2, created_by_user_id,
# use_def_version_time, text_array. We create the DM with an explicit field_list of just
# "test1 test2" (v1), then later update it to "test1 test2 text_array" (v2) - simulating
# a new field being added to the definition. This avoids ALTER TABLE and migration issues.
#
# Note: the originally reported scenario in #665 may manifest at a different layer
# (e.g. blank field_list auto-detected from table columns, or in the rendering/template layer).
# These tests do not reproduce that scenario; they exist to prevent regressions in the
# model-layer behavior that is currently working as intended.

RSpec.describe 'Versioned field list for dynamic model instances', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport
  include DynamicModelSupport
  include OptionsSupport

  # The "new" field is text_array, which already exists in the table but won't be in the initial field_list
  let(:v1_fields_str) { 'test1 test2' }
  let(:v2_fields_str) { 'test1 test2 text_array' }
  let(:new_field) { 'text_array' }

  before :all do
    change_setting('AllowDynamicMigrations', true)
    # These specs only have meaning when definition-at-record-creation versioning
    # is active. In the test environment DisableVDef already defaults to false
    # (Rails.env.development? is false), but set it explicitly so the versioned
    # behavior is not silently dependent on the environment default and cannot be
    # accidentally disabled (e.g. via FPHS_DISABLE_VDEF). With versioning disabled,
    # `versioned`/`versioned_definition` resolve to the current definition and the
    # "old fields only" assertions below would no longer be exercised.
    @prev_disable_vdef = Settings::DisableVDef
    change_setting('DisableVDef', false)
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
    change_setting('DisableVDef', @prev_disable_vdef)
  end

  before :example do
    @user0, = create_user
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_histories
  end

  # Creates a DM with an explicit restricted field_list (only test1, test2)
  # instead of letting it pick up all columns from the table
  def generate_dm_with_restricted_fields
    unless Admin::MigrationGenerator.table_exists? 'test_created_by_recs'
      TableGenerators.dynamic_models_table('test_created_by_recs', :create_do,
                                           'test1', 'test2', 'created_by_user_id',
                                           'use_def_version_time', 'text_array')
    end

    @master = Master.create! current_user: @user
    @master.current_user = @user

    DynamicModel.active.where(table_name: 'test_created_by_recs').reload.each { |dm| dm.disable!(@admin) }
    begin
      DynamicModel.send(:remove_const, :TestCreatedByRec) if DynamicModel.const_defined?(:TestCreatedByRec, false)
    rescue NameError
      # Constant may have been removed by another parallel test
    end

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test created by',
                              table_name: 'test_created_by_recs',
                              primary_key_name: :id,
                              foreign_key_name: :master_id,
                              field_list: v1_fields_str,
                              category: :test
    dm.current_admin = @admin
    dm.update_tracker_events

    setup_access :dynamic_model__test_created_by_recs, user: @user
    setup_access :dynamic_model__test_created_by_recs, user: @user0
    dm.send :reset_all_versions
    dm
  end

  it 'returns only old fields from versioned definition field_list_array when a new field is added' do
    # Create DM v1 with restricted field_list (test1, test2 only)
    dmdef = generate_dm_with_restricted_fields

    v1_field_list = dmdef.field_list_array.dup
    expect(v1_field_list).to eq %w[test1 test2]
    expect(v1_field_list).not_to include(new_field)

    sleep 2

    # Disable migrations since the column already exists - we only need a version history entry
    change_setting('AllowDynamicMigrations', nil)

    # Update the DM definition to include the new field - this creates v2 in history
    dmdef.current_admin = @admin
    dmdef.update!(field_list: v2_fields_str)

    change_setting('AllowDynamicMigrations', true)

    # Current definition should now include the new field
    dmdef.reload
    expect(dmdef.field_list_array).to include(new_field)

    # The versioned definition (v1 from history) should NOT include the new field
    v1_version = dmdef.all_versions.last # oldest version in history
    expect(v1_version).not_to be_nil
    expect(v1_version.field_list_array).to include('test1')
    expect(v1_version.field_list_array).to include('test2')
    expect(v1_version.field_list_array).not_to include(new_field),
                                               "Expected v1 versioned definition field_list_array NOT to include '#{new_field}', " \
                                               "but got: #{v1_version.field_list_array}"
  end

  it 'returns only old fields from versioned option_type_config when a new field is added' do
    # Create DM v1 with restricted field_list
    dmdef = generate_dm_with_restricted_fields

    v1_otc_fields = dmdef.option_type_config_for(:default)&.fields&.dup
    expect(v1_otc_fields).to be_present
    expect(v1_otc_fields).not_to include(new_field)

    # Create an instance under v1
    sleep 2
    instance_v1 = @master.dynamic_model__test_created_by_recs.create!(test1: 'v1_record')

    sleep 2

    # Disable migrations since the column already exists
    change_setting('AllowDynamicMigrations', nil)

    # Update field_list to v2 (adding text_array)
    dmdef.current_admin = @admin
    dmdef.update!(field_list: v2_fields_str)

    change_setting('AllowDynamicMigrations', true)

    # Force re-parse of current definition options
    dmdef.force_option_config_parse

    # Current definition should have the new field in option_type_config
    current_otc = dmdef.option_type_config_for(:default)
    expect(current_otc.fields).to include(new_field)

    # Reload the v1 instance to clear any memoization
    instance_v1 = DynamicModel::TestCreatedByRec.find(instance_v1.id)

    # The v1 instance's versioned definition's option_type_config should NOT include the new field
    versioned_otc = instance_v1.versioned_definition.option_type_config_for(:default)
    expect(versioned_otc).not_to be_nil
    expect(versioned_otc.fields).not_to include(new_field),
                                        "Expected versioned option_type_config fields for a v1 instance NOT to include '#{new_field}', " \
                                        "but got: #{versioned_otc.fields}"
  end

  it 'returns only old fields from edit_form_field_list for instances created under a previous version' do
    # Create DM v1 with restricted field_list
    dmdef = generate_dm_with_restricted_fields

    # Create an instance under v1
    sleep 2
    instance_v1 = @master.dynamic_model__test_created_by_recs.create!(test1: 'v1_record')
    instance_v1.current_user = @user

    v1_edit_fields = instance_v1.edit_form_field_list.dup
    expect(v1_edit_fields).not_to include(new_field.to_sym)
    expect(v1_edit_fields).not_to include(new_field)

    sleep 2

    # Disable migrations since the column already exists
    change_setting('AllowDynamicMigrations', nil)

    # Update field_list to v2 (adding text_array)
    dmdef.current_admin = @admin
    dmdef.update!(field_list: v2_fields_str)

    change_setting('AllowDynamicMigrations', true)

    # Create an instance under v2
    sleep 2
    instance_v2 = @master.dynamic_model__test_created_by_recs.create!(test1: 'v2_record')
    instance_v2.current_user = @user

    # v2 instance should include the new field in edit_form_field_list
    v2_edit_fields = instance_v2.edit_form_field_list
    expect(v2_edit_fields.map(&:to_s)).to include(new_field),
                                          "Expected v2 instance edit_form_field_list to include '#{new_field}', but got: #{v2_edit_fields}"

    # Reload the v1 instance to clear memoization
    instance_v1 = DynamicModel::TestCreatedByRec.find(instance_v1.id)
    instance_v1.current_user = @user

    # v1 instance should NOT include the new field in edit_form_field_list
    v1_edit_fields_after = instance_v1.edit_form_field_list
    expect(v1_edit_fields_after.map(&:to_s)).not_to include(new_field),
                                                    "Expected v1 instance edit_form_field_list NOT to include '#{new_field}', " \
                                                    "but got: #{v1_edit_fields_after}"
  end

  it 'returns only old fields from TemplateOptionMapping.dynamic_model_mapping for versioned definitions' do
    # Create DM v1 with restricted field_list
    dmdef = generate_dm_with_restricted_fields

    # Create an instance under v1
    sleep 2
    instance_v1 = @master.dynamic_model__test_created_by_recs.create!(test1: 'v1_record')

    sleep 2

    # Disable migrations since the column already exists
    change_setting('AllowDynamicMigrations', nil)

    # Update field_list to v2 (adding text_array)
    dmdef.current_admin = @admin
    dmdef.update!(field_list: v2_fields_str)

    change_setting('AllowDynamicMigrations', true)

    dmdef.force_option_config_parse

    # Reload the v1 instance and get its versioned definition
    instance_v1 = DynamicModel::TestCreatedByRec.find(instance_v1.id)
    versioned_def = instance_v1.versioned_definition

    # Get the option_type_config from the versioned definition
    versioned_otc = versioned_def.option_type_config_for(:default)
    expect(versioned_otc).not_to be_nil

    # Call dynamic_model_mapping with the versioned definition as def_record
    mapping = OptionConfigs::TemplateOptionMapping.dynamic_model_mapping(versioned_def, versioned_otc, @user)

    # The item_list in the mapping should only include old fields, NOT the new field
    expect(mapping[:item_list]).not_to include(new_field),
                                       "Expected TemplateOptionMapping item_list for versioned definition NOT to include '#{new_field}', " \
                                       "but got: #{mapping[:item_list]}"

    # Verify the current definition DOES include the new field
    current_otc = dmdef.option_type_config_for(:default)
    current_mapping = OptionConfigs::TemplateOptionMapping.dynamic_model_mapping(dmdef, current_otc, @user)
    expect(current_mapping[:item_list]).to include(new_field),
                                           "Expected current TemplateOptionMapping item_list to include '#{new_field}'"
  end
end
