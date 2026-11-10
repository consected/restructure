# frozen_string_literal: true

# Tests for GitHub issue #1383: "Allow REDCap pulls to continue when an
# individual record's save trigger raises."
#
# Verifies that the `continue_on_record_error` data option on
# Redcap::ProjectAdmin controls whether a per-record exception in
# Redcap::DataRecords#store aborts the entire pull (default, fail-fast) or
# is caught, recorded in `errors`, and allows remaining records to be
# processed (opt-in resilient mode).
#
# Covers:
#   - Default behaviour (option absent/disabled): single record failure aborts store
#   - Option enabled: failure recorded in errors (with the failing record's id),
#     other records still created
#   - before_save and after_commit trigger failures with option enabled, for both
#     newly created records and updates to existing records
#   - Capping of recorded errors when many records fail, to bound job request size
#   - Validation of the continue_on_record_error option's accepted values

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::DataRecords, type: :model do
  include MasterSupport
  include ModelSupport
  include Redcap::RedcapSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
  end

  describe 'continue_on_record_error option' do
    before :all do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first
    end

    before :example do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      change_setting('RedcapJobUserEmail', @admin.email)
      setup_file_store
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first
      reset_mocks
    end

    # Helper: set up a DataRecords instance with records retrieved and ready to store.
    # Returns [data_records_instance, project_admin, dynamic_model_class]
    def prepare_data_records_for_store
      dm = create_dynamic_model_for_sample_response

      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin

      stub_request_records @project[:server_url], @project[:api_key]
      dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
      dr.retrieve
      dr.summarize_fields
      dr.handle_survey_identifier
      dr.validate

      [dr, rc, dm.implementation_class]
    end

    # Helper: pull a second, changed version of the same records so create_or_update
    # takes the update path (existing_record found) rather than the create path.
    # Mirrors the setup used in data_records_spec.rb's "does updates on records that
    # have changed" example.
    # @return [Redcap::DataRecords]
    def prepare_updated_data_records_for_store(rc_admin, model_class)
      WebMock.reset!
      rc_admin.api_client.send :clear_cache, rc_admin.api_client.send(:cache_key, :records)
      rc_admin.api_client.send :clear_cache, rc_admin.api_client.send(:cache_key, :records, rc_admin.records_request_options)
      stub_request_records @project[:server_url], @project[:api_key], 'updated_records'
      Rails.cache.clear

      dr2 = Redcap::DataRecords.new(rc_admin, model_class.name)
      dr2.retrieve
      dr2.summarize_fields
      dr2.handle_survey_identifier
      dr2.validate
      dr2
    end

    it 'validates continue_on_record_error accepts only true, false, or blank' do
      _dr, rc, = prepare_data_records_for_store

      # Reload a fresh instance for each check: repeatedly validating the same
      # instance would trigger #update_options' before_validation callback to
      # rebuild data_options from the config_text written by a prior #valid?
      # call, silently discarding the value being tested here.
      [true, false, nil, ''].each do |valid_value|
        fresh_rc = Redcap::ProjectAdmin.find(rc.id)
        fresh_rc.current_admin = @admin
        fresh_rc.data_options.continue_on_record_error = valid_value
        expect(fresh_rc).to be_valid
      end

      fresh_rc = Redcap::ProjectAdmin.find(rc.id)
      fresh_rc.current_admin = @admin
      fresh_rc.data_options.continue_on_record_error = 'false'
      expect(fresh_rc).not_to be_valid
      expect(fresh_rc.errors[:data_options]).to include(a_string_matching(/continue_on_record_error/))
    end

    context 'when continue_on_record_error is disabled (default)' do
      it 'defaults to disabled' do
        _dr, rc, = prepare_data_records_for_store

        expect(rc.data_options.continue_on_record_error).to be_falsey
      end

      it 'treats a blank string the same as disabled, not as a truthy enabled value' do
        _dr, rc, model_class = prepare_data_records_for_store

        rc.current_admin = @admin
        rc.data_options.continue_on_record_error = ''
        rc.save!

        dr2 = Redcap::DataRecords.new(rc, model_class.name)
        expect(dr2.continue_on_record_error).to eq(false)
      end

      it 'aborts the entire store run when a single record raises' do
        dr, _rc, _model_class = prepare_data_records_for_store

        call_count = 0
        allow(dr).to receive(:create_or_update).and_wrap_original do |method, *args|
          call_count += 1
          raise StandardError, 'save trigger exploded' if call_count == 2

          method.call(*args)
        end

        expect { dr.store }.to raise_error(StandardError, 'save trigger exploded')
      end
    end

    context 'when continue_on_record_error is enabled' do
      before :example do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.continue_on_record_error = true
        rc.save!
      end

      it 'records the error, with the failing record id, and continues processing remaining records' do
        dr, _rc, _model_class = prepare_data_records_for_store

        total_records = dr.records.length
        expect(total_records).to be >= 3
        expected_failing_id = dr.send(:record_identifiers, dr.records[1])

        call_count = 0
        allow(dr).to receive(:create_or_update).and_wrap_original do |method, *args|
          call_count += 1
          raise StandardError, 'save trigger exploded' if call_count == 2

          method.call(*args)
        end

        expect { dr.store }.not_to raise_error

        # The failing record should be recorded in errors, identified by its record id
        expect(dr.errors).not_to be_empty
        trigger_error = dr.errors.find { |e| e[:action] == :create_or_update }
        expect(trigger_error).to be_present
        expect(trigger_error[:id]).to eq(expected_failing_id)
        expect(trigger_error[:errors][:store]).to include('save trigger exploded')

        # Other records should still have been created
        expect(dr.created_ids.length).to eq(total_records - 1)
      end

      it 'caps the number of recorded errors when many records fail' do
        stub_const('Redcap::DataRecords::MaxRecordErrorsRecorded', 1)
        dr, _rc, _model_class = prepare_data_records_for_store
        total_records = dr.records.length

        allow(dr).to receive(:create_or_update).and_raise(StandardError, 'save trigger exploded')

        expect { dr.store }.not_to raise_error

        record_errors = dr.errors.select { |e| e[:action] == :create_or_update }
        expect(record_errors.length).to eq(1)

        overflow_error = dr.errors.find { |e| e[:id].nil? }
        expect(overflow_error).to be_present
        expect(overflow_error[:errors][:store]).to eq("#{total_records - 1} additional record errors were suppressed")
      end

      it 'does not let unrelated pre-existing error entries consume the recorded-error cap' do
        stub_const('Redcap::DataRecords::MaxRecordErrorsRecorded', 1)
        dr, _rc, _model_class = prepare_data_records_for_store
        total_records = dr.records.length

        # An unrelated pre-existing error entry (e.g. a validation failure from #create_or_update)
        # should not count against the cap on record_store_error entries.
        dr.errors << { id: { record_id: 'unrelated' }, errors: { base: 'unrelated validation failure' },
                       action: :create }

        allow(dr).to receive(:create_or_update).and_raise(StandardError, 'save trigger exploded')

        expect { dr.store }.not_to raise_error

        record_errors = dr.errors.select { |e| e[:action] == :create_or_update }
        expect(record_errors.length).to eq(1)

        overflow_error = dr.errors.find { |e| e[:id].nil? }
        expect(overflow_error[:errors][:store]).to eq("#{total_records - 1} additional record errors were suppressed")
      end

      it 'safe_record_identifiers never raises, even if record_identifiers and record_id_field both raise' do
        dr, _rc, _model_class = prepare_data_records_for_store

        allow(dr).to receive(:record_identifiers).and_raise(StandardError, 'bad data dictionary')
        allow(dr).to receive(:record_id_field).and_raise(StandardError, 'data dictionary unavailable')

        result = nil
        expect { result = dr.send(:safe_record_identifiers, { some: 'record' }) }.not_to raise_error
        expect(result).to eq(unidentified_record: true)
      end

      it 'records the error when a before_save trigger raises while creating a record' do
        dr, _rc, model_class = prepare_data_records_for_store

        total_records = dr.records.length

        # Simulate a before_save trigger raising on the first save attempt
        save_count = 0
        allow_any_instance_of(model_class).to receive(:handle_before_save_triggers).and_wrap_original do |method, *args|
          save_count += 1
          raise StandardError, 'before_save trigger failed' if save_count == 1

          method.call(*args)
        end

        expect { dr.store }.not_to raise_error

        expect(dr.errors).not_to be_empty
        trigger_error = dr.errors.find { |e| e[:errors][:store].to_s.include?('before_save trigger failed') }
        expect(trigger_error).to be_present

        # The record that raised should not be persisted
        expect(dr.created_ids.length).to eq(total_records - 1)
      end

      it 'records the error when an after_commit trigger raises while creating a record' do
        dr, _rc, model_class = prepare_data_records_for_store

        total_records = dr.records.length

        # Simulate an after_commit trigger raising after the record is already committed
        commit_count = 0
        allow_any_instance_of(model_class).to receive(:handle_save_triggers).and_wrap_original do |method, *args|
          commit_count += 1
          raise StandardError, 'after_commit trigger failed' if commit_count == 1

          method.call(*args)
        end

        expect { dr.store }.not_to raise_error

        expect(dr.errors).not_to be_empty
        trigger_error = dr.errors.find { |e| e[:errors][:store].to_s.include?('after_commit trigger failed') }
        expect(trigger_error).to be_present

        # The record that raised in after_commit should already be persisted
        # so total created should include it
        expect(dr.created_ids.length).to eq(total_records)
      end

      it 'records the error and excludes the record when a before_save trigger raises while updating a record' do
        dr, rc, model_class = prepare_data_records_for_store
        expect { dr.store }.not_to raise_error
        expect(dr.errors).to be_empty

        dr2 = prepare_updated_data_records_for_store(rc, model_class)

        # Of the 5 records in the 'updated_records' fixture, only 2 actually differ
        # from what was stored by the first pull (the rest are unchanged and are
        # skipped before any save is attempted).
        expected_updates = 2
        record_id_field = dr2.send(:record_id_field)
        failing_id = nil

        # Simulate a before_save trigger raising on the first update attempt.
        save_count = 0
        allow_any_instance_of(model_class).to receive(:handle_before_save_triggers).and_wrap_original do |method, *args|
          save_count += 1
          if save_count == 1
            failing_id = { record_id_field => method.receiver[record_id_field] }
            raise StandardError, 'before_save update trigger failed'
          end

          method.call(*args)
        end

        expect { dr2.store }.not_to raise_error
        expect(failing_id).to be_present

        expect(dr2.errors).not_to be_empty
        trigger_error = dr2.errors.find { |e| e[:errors][:store].to_s.include?('before_save update trigger failed') }
        expect(trigger_error).to be_present
        expect(trigger_error[:id]).to eq(failing_id)

        # The rolled-back update must not be counted, nor have files captured for it
        expect(dr2.updated_ids).not_to include(failing_id)
        expect(dr2.updated_ids.length).to eq(expected_updates - 1)
      end

      it 'records the error and still counts the record when an after_commit trigger raises while updating a record' do
        dr, rc, model_class = prepare_data_records_for_store
        expect { dr.store }.not_to raise_error
        expect(dr.errors).to be_empty

        dr2 = prepare_updated_data_records_for_store(rc, model_class)

        # Of the 5 records in the 'updated_records' fixture, only 2 actually differ
        # from what was stored by the first pull (the rest are unchanged and are
        # skipped before any save is attempted).
        expected_updates = 2
        record_id_field = dr2.send(:record_id_field)
        failing_id = nil

        # Simulate an after_commit trigger raising after the update is already committed.
        commit_count = 0
        allow_any_instance_of(model_class).to receive(:handle_save_triggers).and_wrap_original do |method, *args|
          commit_count += 1
          if commit_count == 1
            failing_id = { record_id_field => method.receiver[record_id_field] }
            raise StandardError, 'after_commit update trigger failed'
          end

          method.call(*args)
        end

        expect { dr2.store }.not_to raise_error
        expect(failing_id).to be_present

        expect(dr2.errors).not_to be_empty
        trigger_error = dr2.errors.find { |e| e[:errors][:store].to_s.include?('after_commit update trigger failed') }
        expect(trigger_error).to be_present
        expect(trigger_error[:id]).to eq(failing_id)

        # The update already committed, so it should still be counted
        expect(dr2.updated_ids).to include(failing_id)
        expect(dr2.updated_ids.length).to eq(expected_updates)
      end

      it 'continues processing when disabling a deleted record raises, with handle_deleted_records "disable"' do
        dm = create_dynamic_model_for_sample_response(disable: true)

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.handle_deleted_records = 'disable'
        rc.data_options.continue_on_record_error = true
        rc.save!

        stub_request_records @project[:server_url], @project[:api_key]
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr.retrieve
        dr.summarize_fields
        dr.handle_survey_identifier
        dr.validate
        dr.store
        expect(dr.errors).to be_empty

        WebMock.reset!
        rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)
        rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)
        stub_request_records @project[:server_url], @project[:api_key], 'missing_record'
        Rails.cache.clear

        dr2 = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr2.retrieve
        dr2.summarize_fields
        dr2.handle_survey_identifier
        dr2.validate

        # The first create_or_update call belongs to #disable_deleted_records (disabling
        # record 4, which is missing from this pull's retrieved records).
        call_count = 0
        allow(dr2).to receive(:create_or_update).and_wrap_original do |method, *args|
          call_count += 1
          raise StandardError, 'disable trigger failed' if call_count == 1

          method.call(*args)
        end

        expect { dr2.store }.not_to raise_error

        trigger_error = dr2.errors.find { |e| e[:errors][:store].to_s.include?('disable trigger failed') }
        expect(trigger_error).to be_present
        expect(dr2.disabled_ids).to be_empty

        # Processing continued into the main loop and created the new retrieved record
        expect(dr2.created_ids.map { |r| r[:record_id] }).to eq(%w[222224])
      end
    end
  end
end
