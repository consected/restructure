# frozen_string_literal: true

# Tests for GitHub issue #607: Redcap longitudinal records break ability to use a foreign key
# onto masters / external ids.
#
# When a longitudinal Redcap project is configured with `associate_master_through_external_identifer`,
# subsequent arms/events only record the `record_id`, not the study id field. The system should:
# 1. Automatically add a `longitudinal_study_id` integer field to the dynamic model
# 2. Populate `longitudinal_study_id` during record capture by looking up the study id
#    from the first record matching the same record_id
# 3. Set the `foreign_key_name` to 'longitudinal_study_id' for master record association
# 4. Set `_configurations.foreign_key_through_external_id` to the external id resource name
#
# Two fixture sets are tested:
#
# Simple fixture (longitudinal_records.json):
# - record_id 31, event_1_arm_1: study_id "123" → longitudinal_study_id = 123
# - record_id 31, event_2_arm_1: study_id "" → looks up from record_id 31 → longitudinal_study_id = 123
# - record_id 32, all events: study_id "" → no source value → longitudinal_study_id = nil
#
# Real data fixture (longitudinal_records_long.json):
# - 66 records, 35 unique record_ids (3-37), 7 event names across 3 arms
# - study_id populated only on participant_id_arm_* events
# - e.g. record_id=34: participant_id_arm_1 has study_id=207585036,
#   screening_bp_home_arm_1 should inherit 207585036 via record_id lookup

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::DataRecords, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)

    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
    @metadata_project = @projects.find { |p| p[:name] == 'longitudinal' }
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
    reset_mocks
  end

  context 'with simple longitudinal fixture' do
    before :all do
      setup_longitudinal_fields('dynamic_test.test_longitudinal_fkey_recs')

      rc = @project_admin_metadata
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]

      rc.data_options.associate_master_through_external_identifer = 'scantrons study_id'
      rc.save!

      rc.reload
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]
      expect(rc.data_options.associate_master_through_external_identifer).to eq 'scantrons study_id'
      expect(rc.is_longitudinal?).to be true

      rc.update_dynamic_model
      @dm_fkey = rc.dynamic_storage.dynamic_model
      @project_admin_fkey = rc
    end

    it 'adds longitudinal_study_id field to the dynamic model when longitudinal project has fkey configured' do
      setup_longitudinal_fields('dynamic_test.test_longitudinal_fkey_recs')
      rc = @project_admin_fkey
      rc.reload
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]

      expect(rc.is_longitudinal?).to be true
      expect(rc.data_options.associate_master_through_external_identifer).to eq 'scantrons study_id'

      dm_class = @dm_fkey.implementation_class
      expect(dm_class.attribute_names).to include('longitudinal_study_id')
    end

    it 'configures foreign_key_name as longitudinal_study_id for the dynamic model' do
      setup_longitudinal_fields('dynamic_test.test_longitudinal_fkey_recs')
      rc = @project_admin_fkey
      rc.reload
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]

      dm = @dm_fkey
      dm.reload
      expect(dm.foreign_key_name).to eq 'longitudinal_study_id'
      expect(dm.configurations[:foreign_key_through_external_id]).to eq 'scantrons'
    end

    it 'populates longitudinal_study_id during record capture based on record_id lookup' do
      setup_longitudinal_fields('dynamic_test.test_longitudinal_fkey_recs')
      rc = @project_admin_fkey
      rc.reload
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]

      dm_class = @dm_fkey.implementation_class

      dr = Redcap::DataRecords.new(rc, dm_class.name)
      dr.retrieve
      dr.summarize_fields
      expect { dr.validate }.not_to raise_error

      dr.store
      expect(dr.errors).to be_empty

      # record_id 31 event_1_arm_1 has study_id "123" - should set longitudinal_study_id = 123
      rec_31_e1 = dm_class.find_by(record_id: '31', redcap_event_name: 'event_1_arm_1')
      expect(rec_31_e1.longitudinal_study_id).to eq 123

      # record_id 31 event_2_arm_1 has study_id "" - should look up from record_id 31 → 123
      rec_31_e2 = dm_class.find_by(record_id: '31', redcap_event_name: 'event_2_arm_1')
      expect(rec_31_e2.longitudinal_study_id).to eq 123

      # record_id 32 events have no study_id anywhere - longitudinal_study_id should be nil
      rec_32_e1 = dm_class.find_by(record_id: '32', redcap_event_name: 'event_1_arm_2')
      expect(rec_32_e1.longitudinal_study_id).to be_nil

      rec_32_e2 = dm_class.find_by(record_id: '32', redcap_event_name: 'event_2_arm_2')
      expect(rec_32_e2.longitudinal_study_id).to be_nil

      rec_32_e3 = dm_class.find_by(record_id: '32', redcap_event_name: 'event_3_arm_2')
      expect(rec_32_e3.longitudinal_study_id).to be_nil
    end
  end

  context 'with real longitudinal data' do
    before :all do
      setup_longitudinal_long_fields('dynamic_test.test_longitudinal_long_fkey_recs')

      rc = @project_admin_long_metadata
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]

      rc.data_options.associate_master_through_external_identifer = 'scantrons study_id'
      rc.save!

      rc.reload
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]
      expect(rc.data_options.associate_master_through_external_identifer).to eq 'scantrons study_id'
      expect(rc.is_longitudinal?).to be true

      rc.update_dynamic_model
      @dm_long_fkey = rc.dynamic_storage.dynamic_model
      @project_admin_long_fkey = rc
    end

    it 'adds longitudinal_study_id field to the dynamic model' do
      setup_longitudinal_long_fields('dynamic_test.test_longitudinal_long_fkey_recs')
      rc = @project_admin_long_fkey
      rc.reload
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]

      expect(rc.is_longitudinal?).to be true
      expect(rc.data_options.associate_master_through_external_identifer).to eq 'scantrons study_id'

      dm_class = @dm_long_fkey.implementation_class
      expect(dm_class.attribute_names).to include('longitudinal_study_id')
    end

    it 'stores all 66 records from the fixture' do
      setup_longitudinal_long_fields('dynamic_test.test_longitudinal_long_fkey_recs')
      rc = @project_admin_long_fkey
      rc.reload
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]

      dm_class = @dm_long_fkey.implementation_class

      dr = Redcap::DataRecords.new(rc, dm_class.name)
      dr.retrieve
      dr.summarize_fields
      expect { dr.validate }.not_to raise_error

      dr.store
      expect(dr.errors).to be_empty
      expect(dm_class.count).to eq 66
    end

    it 'populates longitudinal_study_id for records with study_id in participant_id events' do
      setup_longitudinal_long_fields('dynamic_test.test_longitudinal_long_fkey_recs')
      rc = @project_admin_long_fkey
      rc.reload
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]

      dm_class = @dm_long_fkey.implementation_class

      dr = Redcap::DataRecords.new(rc, dm_class.name)
      dr.retrieve
      dr.summarize_fields
      expect { dr.validate }.not_to raise_error
      dr.store
      expect(dr.errors).to be_empty

      # record_id=34: participant_id_arm_1 has study_id=207585036
      rec_34_pid = dm_class.find_by(record_id: '34', redcap_event_name: 'participant_id_arm_1')
      expect(rec_34_pid.longitudinal_study_id).to eq 207_585_036

      # record_id=37: participant_id_arm_1 has study_id=415734484
      rec_37_pid = dm_class.find_by(record_id: '37', redcap_event_name: 'participant_id_arm_1')
      expect(rec_37_pid.longitudinal_study_id).to eq 415_734_484

      # record_id=32: participant_id_arm_2 has study_id=458465543
      rec_32_pid = dm_class.find_by(record_id: '32', redcap_event_name: 'participant_id_arm_2')
      expect(rec_32_pid.longitudinal_study_id).to eq 458_465_543
    end

    it 'propagates longitudinal_study_id to non-participant events via record_id lookup' do
      setup_longitudinal_long_fields('dynamic_test.test_longitudinal_long_fkey_recs')
      rc = @project_admin_long_fkey
      rc.reload
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]

      dm_class = @dm_long_fkey.implementation_class

      dr = Redcap::DataRecords.new(rc, dm_class.name)
      dr.retrieve
      dr.summarize_fields
      expect { dr.validate }.not_to raise_error
      dr.store
      expect(dr.errors).to be_empty

      # record_id=34: screening_bp_home_arm_1 has null study_id, should get 207585036 from record_id lookup
      rec_34_scr = dm_class.find_by(record_id: '34', redcap_event_name: 'screening_bp_home_arm_1')
      expect(rec_34_scr.longitudinal_study_id).to eq 207_585_036

      # record_id=37: screening_bp_home_arm_1 has null study_id, should get 415734484 from record_id lookup
      rec_37_scr = dm_class.find_by(record_id: '37', redcap_event_name: 'screening_bp_home_arm_1')
      expect(rec_37_scr.longitudinal_study_id).to eq 415_734_484

      # record_id=32: 6month_bp_home_mea_arm_2 has null study_id, should get 458465543 from record_id lookup
      rec_32_6m = dm_class.find_by(record_id: '32', redcap_event_name: '6month_bp_home_mea_arm_2')
      expect(rec_32_6m.longitudinal_study_id).to eq 458_465_543

      # record_id=27: 6month_home_bp_mea_arm_3 has null study_id, should get value from record_id lookup
      rec_27_6m = dm_class.find_by(record_id: '27', redcap_event_name: '6month_home_bp_mea_arm_3')
      expect(rec_27_6m.longitudinal_study_id).not_to be_nil
    end

    it 'ensures all records sharing a record_id get a consistent longitudinal_study_id' do
      setup_longitudinal_long_fields('dynamic_test.test_longitudinal_long_fkey_recs')
      rc = @project_admin_long_fkey
      rc.reload
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]

      dm_class = @dm_long_fkey.implementation_class

      dr = Redcap::DataRecords.new(rc, dm_class.name)
      dr.retrieve
      dr.summarize_fields
      expect { dr.validate }.not_to raise_error
      dr.store
      expect(dr.errors).to be_empty

      # record_id=34 has two records - both should have the same longitudinal_study_id
      recs_34 = dm_class.where(record_id: '34').to_a
      expect(recs_34.length).to eq 2
      study_ids_34 = recs_34.map(&:longitudinal_study_id).uniq
      expect(study_ids_34).to eq [207_585_036]

      # record_id=3 has two records - both should have the same longitudinal_study_id
      recs_3 = dm_class.where(record_id: '3').to_a
      expect(recs_3.length).to eq 2
      study_ids_3 = recs_3.map(&:longitudinal_study_id).uniq
      expect(study_ids_3).to eq [727_347_772]
    end

    it 'handles record_id=27 which has study_id in multiple arms' do
      setup_longitudinal_long_fields('dynamic_test.test_longitudinal_long_fkey_recs')
      rc = @project_admin_long_fkey
      rc.reload
      rc.current_admin = @admin
      rc.api_key = @metadata_project[:api_key]

      dm_class = @dm_long_fkey.implementation_class

      dr = Redcap::DataRecords.new(rc, dm_class.name)
      dr.retrieve
      dr.summarize_fields
      expect { dr.validate }.not_to raise_error
      dr.store
      expect(dr.errors).to be_empty

      # record_id=27 has study_id in both arm_1 (404153478) and arm_3 (727347772)
      # Each participant_id event has its own study_id, so they get their own value directly
      rec_27_arm1 = dm_class.find_by(record_id: '27', redcap_event_name: 'participant_id_arm_1')
      expect(rec_27_arm1.longitudinal_study_id).to eq 404_153_478

      rec_27_arm3 = dm_class.find_by(record_id: '27', redcap_event_name: 'participant_id_arm_3')
      expect(rec_27_arm3.longitudinal_study_id).to eq 727_347_772

      # The 6month event has no study_id - it gets one from record_id lookup
      rec_27_6m = dm_class.find_by(record_id: '27', redcap_event_name: '6month_home_bp_mea_arm_3')
      expect(rec_27_6m.longitudinal_study_id).not_to be_nil
    end
  end
end
