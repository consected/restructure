# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Test Summary: Redcap::DataRecords cache and date range
# ======================================================
#
# This spec exercises the REDCap caching and date range filtering features
# added to support GitHub issue #379.
#
# 1. Configurable Cache Times (10 tests)
#    ---------------------------------
#    metadata_export_cache_time:
#      - uses default cache time (60s) when nil
#      - uses custom cache time when set (e.g., 120s)
#      - disables caching when set to 0
#
#    record_export_cache_time:
#      - uses default cache time (60s) when nil
#      - uses custom cache time when set (e.g., 300s)
#      - disables caching when set to 0
#
#    last_result_from_cache tracking:
#      - tracks when results come from cache vs API
#      - always fetches from API when caching is disabled
#
#    server_time_zone conversion:
#      - converts date_range_begin to server time zone when set
#      - does not convert when server_time_zone is not set
#
# 2. Export Only Updated Records (17 tests)
#    --------------------------------------
#    validation of export_only_updated_records option:
#      - allows valid values (nil, blank, 'always', 'manual', 'scheduled')
#      - rejects invalid values
#
#    validation of server_time_zone option:
#      - allows valid time zone identifiers
#      - rejects invalid time zone identifiers
#
#    calculate_date_range_begin:
#      - returns nil when option not set
#      - returns nil when 'manual' but is_manual_pull is false
#      - returns nil when 'scheduled' but is_manual_pull is true
#      - returns nil when no successful store records ClientRequest exists
#      - returns ClientRequest timestamp when 'always' with existing successful store
#      - calculates for manual pulls when option is 'manual'
#      - calculates for scheduled pulls when option is 'scheduled'
#
#    using_date_range_filter:
#      - sets flag to true when dateRangeBegin is used in retrieve()
#      - stores date_range_begin when date range filter is used
#      - does not store date_range_begin when retrieve_all is true
#
#    skipping cached results:
#      - skips validate and store when results are from cache
#      - records error in job request when exception occurs
#
#    deleted records handling with date range:
#      - skips deleted records validation when using date range filter
#      - does not disable records when using date range filter
#
# 3. Ignore Cache and Retrieve All Parameters (8 tests)
#    --------------------------------------------------
#    ignore_cache parameter:
#      - forces API request when ignore_cache is true (bypasses cache)
#      - uses cache normally when ignore_cache is false
#
#    retrieve_all parameter:
#      - retrieves all records when retrieve_all is true (ignores date range)
#      - uses date range when retrieve_all is false
#
#    ProjectAdmin helper methods:
#      - export_only_updated_records_for_manual? returns true for 'manual'
#      - export_only_updated_records_for_manual? returns true for 'always'
#      - export_only_updated_records_for_manual? returns false for 'scheduled'
#      - export_only_updated_records_for_manual? returns false when not set
#      - date_range_begin_for_manual_pull returns timestamp when successful store exists
#      - date_range_begin_for_manual_pull returns nil when option not set
#
# Key Components Being Tested:
#   - ApiClient cache configuration flows through from data_options
#   - Cache hit tracking via last_result_from_cache attribute
#   - Option validation for export_only_updated_records
#   - Date range calculation using ClientRequest.created_at from last successful store
#   - Conditional date filtering based on is_manual_pull flag
#   - Cache skip behavior in retrieve_validate_store()
#   - Deleted record handling disabled when using date range filter
#   - ignore_cache parameter bypasses cache
#   - retrieve_all parameter ignores date range settings

RSpec.describe 'Redcap::DataRecords cache and date range', type: :model do
  include MasterSupport
  include ModelSupport
  include Redcap::RedcapSupport

  describe 'configurable cache times' do
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

    describe 'metadata_export_cache_time' do
      it 'uses default cache time when metadata_export_cache_time is nil' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin

        expect(rc.data_options.metadata_export_cache_time).to be_nil
        expect(rc.api_client.metadata_export_cache_time).to eq 60.seconds
      end

      it 'uses custom cache time when metadata_export_cache_time is set' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.metadata_export_cache_time = 120
        rc.save!

        expect(rc.api_client.metadata_export_cache_time).to eq 120.seconds
      end

      it 'disables caching when metadata_export_cache_time is 0' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.metadata_export_cache_time = 0
        rc.save!

        expect(rc.api_client.metadata_export_cache_time).to be_nil
      end
    end

    describe 'record_export_cache_time' do
      it 'uses default cache time when record_export_cache_time is nil' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin

        expect(rc.data_options.record_export_cache_time).to be_nil
        expect(rc.api_client.record_export_cache_time).to eq 60.seconds
      end

      it 'uses custom cache time when record_export_cache_time is set' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.record_export_cache_time = 300
        rc.save!

        expect(rc.api_client.record_export_cache_time).to eq 300.seconds
      end

      it 'disables caching when record_export_cache_time is 0' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.record_export_cache_time = 0
        rc.save!

        expect(rc.api_client.record_export_cache_time).to be_nil
      end
    end

    describe 'last_result_from_cache tracking' do
      it 'tracks when results come from cache vs API' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin

        # Clear the cache first
        rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

        # First request should be from API
        res1 = rc.api_client.records
        expect(res1).to be_a Array
        expect(rc.api_client.last_result_from_cache).to be false

        # Second request should be from cache (within cache window)
        res2 = rc.api_client.records
        expect(res2).to be_a Array
        expect(rc.api_client.last_result_from_cache).to be true
      end

      it 'always fetches from API when caching is disabled' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.record_export_cache_time = 0
        rc.save!

        # Clear any existing cache
        rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

        # First request from API
        res1 = rc.api_client.records
        expect(res1).to be_a Array
        expect(rc.api_client.last_result_from_cache).to be false

        # Second request should also be from API (caching disabled)
        res2 = rc.api_client.records
        expect(res2).to be_a Array
        expect(rc.api_client.last_result_from_cache).to be false
      end
    end

    describe 'server_time_zone conversion' do
      it 'converts date_range_begin to server time zone when set' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.server_time_zone = 'America/New_York'
        rc.save!

        # Create a UTC time
        utc_time = Time.utc(2026, 1, 15, 17, 0, 0) # 5 PM UTC

        # This should convert to 12 PM EST (noon)
        # The request should have the converted time in the dateRangeBegin
        expect(rc.api_client).to receive(:request).with(
          :records,
          hash_including(
            request_options: hash_including(dateRangeBegin: '2026-01-15 12:00:00'),
            cache_expires_in: anything
          )
        ).and_return([])

        rc.api_client.records(date_range_begin: utc_time)
      end

      it 'does not convert when server_time_zone is not set' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.server_time_zone = nil
        rc.save!

        # Create a UTC time
        utc_time = Time.utc(2026, 1, 15, 17, 0, 0) # 5 PM UTC

        # Without time zone conversion, the time should be used as-is
        expect(rc.api_client).to receive(:request).with(
          :records,
          hash_including(
            request_options: hash_including(dateRangeBegin: '2026-01-15 17:00:00'),
            cache_expires_in: anything
          )
        ).and_return([])

        rc.api_client.records(date_range_begin: utc_time)
      end
    end
  end

  describe 'export_only_updated_records' do
    before :all do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first
      setup_file_fields
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

    describe 'validation of export_only_updated_records option' do
      it 'allows valid values for export_only_updated_records' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin

        # nil is valid
        rc.data_options.export_only_updated_records = nil
        expect(rc).to be_valid

        # blank is valid
        rc.data_options.export_only_updated_records = ''
        expect(rc).to be_valid

        # 'always' is valid
        rc.data_options.export_only_updated_records = 'always'
        expect(rc).to be_valid

        # 'manual' is valid
        rc.data_options.export_only_updated_records = 'manual'
        expect(rc).to be_valid

        # 'scheduled' is valid
        rc.data_options.export_only_updated_records = 'scheduled'
        expect(rc).to be_valid
      end

      it 'rejects invalid values for export_only_updated_records' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'invalid'

        expect(rc).not_to be_valid
        expect(rc.errors[:data_options]).to include("export_only_updated_records must be one of: #{Redcap::ProjectAdmin::ValidExportOnlyUpdatedRecordsValues}")
      end
    end

    describe 'validation of server_time_zone option' do
      it 'allows valid time zone identifiers' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin

        # nil is valid
        rc.data_options.server_time_zone = nil
        expect(rc).to be_valid

        # blank is valid
        rc.data_options.server_time_zone = ''
        expect(rc).to be_valid

        # America/New_York is valid
        rc.data_options.server_time_zone = 'America/New_York'
        expect(rc).to be_valid

        # UTC is valid
        rc.data_options.server_time_zone = 'UTC'
        expect(rc).to be_valid

        # Europe/London is valid
        rc.data_options.server_time_zone = 'Europe/London'
        expect(rc).to be_valid
      end

      it 'rejects invalid time zone identifiers' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.server_time_zone = 'Invalid/TimeZone'

        expect(rc).not_to be_valid
        expect(rc.errors[:data_options]).to include("server_time_zone 'Invalid/TimeZone' is not a valid time zone identifier")
      end
    end

    describe 'calculate_date_range_begin' do
      it 'returns nil when export_only_updated_records is not set' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin

        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        date_range = dr.send(:calculate_date_range_begin)

        expect(date_range).to be_nil
      end

      it 'returns nil when export_only_updated_records is manual but is_manual_pull is false' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'manual'
        rc.save!

        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name, is_manual_pull: false)
        date_range = dr.send(:calculate_date_range_begin)

        expect(date_range).to be_nil
      end

      it 'returns nil when export_only_updated_records is scheduled and is_manual_pull is true' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'scheduled'
        rc.save!

        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name, is_manual_pull: true)
        date_range = dr.send(:calculate_date_range_begin)

        expect(date_range).to be_nil
      end

      it 'returns nil when no successful store records ClientRequest exists' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        # Ensure no successful store records ClientRequest exists
        Redcap::ClientRequest.where(redcap_project_admin_id: rc.id, action: 'store records').delete_all

        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        date_range = dr.send(:calculate_date_range_begin)

        expect(date_range).to be_nil
      end

      it 'returns ClientRequest timestamp when successful store records exists and export_only_updated_records is always' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        # Create a successful ClientRequest for 'store records'
        store_time = 5.minutes.ago
        Redcap::ClientRequest.create!(
          current_admin: @admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          result: { errors: [] },
          created_at: store_time
        )

        # Now check the date range is calculated
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        date_range = dr.send(:calculate_date_range_begin)

        expect(date_range).to be_a Time
        expect(date_range.to_i).to eq store_time.to_i
      end

      it 'calculates date range for manual pulls when export_only_updated_records is manual' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'manual'
        rc.save!

        # Create a successful ClientRequest for 'store records'
        store_time = 5.minutes.ago
        Redcap::ClientRequest.create!(
          current_admin: @admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          result: { errors: [] },
          created_at: store_time
        )

        # Manual pull should calculate date range
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name, is_manual_pull: true)
        date_range = dr.send(:calculate_date_range_begin)

        expect(date_range).to be_a Time
        expect(date_range.to_i).to eq store_time.to_i
      end

      it 'calculates date range for scheduled pulls when export_only_updated_records is scheduled' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'scheduled'
        rc.save!

        # Create a successful ClientRequest for 'store records'
        store_time = 5.minutes.ago
        Redcap::ClientRequest.create!(
          current_admin: @admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          result: { errors: [] },
          created_at: store_time
        )

        # Scheduled pull should calculate date range
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name, is_manual_pull: false)
        date_range = dr.send(:calculate_date_range_begin)

        expect(date_range).to be_a Time
        expect(date_range.to_i).to eq store_time.to_i
      end
    end

    describe 'using_date_range_filter' do
      it 'sets using_date_range_filter when date range is used' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        # Create a successful ClientRequest for 'store records'
        Redcap::ClientRequest.create!(
          current_admin: @admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          result: { errors: [] },
          created_at: 5.minutes.ago
        )

        # Stub request with dateRangeBegin
        stub_request_records_with_date_range @project[:server_url], @project[:api_key]

        # Create DataRecords instance and retrieve
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr.retrieve

        expect(dr.using_date_range_filter).to be true
      end

      it 'stores date_range_begin when date range filter is used' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        # Create a successful ClientRequest for 'store records'
        store_time = 5.minutes.ago
        Redcap::ClientRequest.create!(
          current_admin: @admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          result: { errors: [] },
          created_at: store_time
        )

        # Stub request with dateRangeBegin
        stub_request_records_with_date_range @project[:server_url], @project[:api_key]

        # Create DataRecords instance and retrieve
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr.retrieve

        expect(dr.using_date_range_filter).to be true
        expect(dr.date_range_begin).to be_a Time
        expect(dr.date_range_begin.to_i).to eq store_time.to_i
      end

      it 'does not store date_range_begin when retrieve_all is true' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        # Create a successful ClientRequest for 'store records'
        Redcap::ClientRequest.create!(
          current_admin: @admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          result: { errors: [] },
          created_at: 5.minutes.ago
        )

        stub_request_records @project[:server_url], @project[:api_key]

        # Create DataRecords instance with retrieve_all: true
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr.retrieve(retrieve_all: true)

        expect(dr.using_date_range_filter).to be false
        expect(dr.date_range_begin).to be_nil
      end
    end

    describe 'skipping cached results' do
      it 'skips validate and store when results are from cache' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin

        stub_request_records @project[:server_url], @project[:api_key]

        # First retrieval - from API
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr.retrieve_validate_store

        expect(dr.retrieved_from_cache).to be false
        expect(dr.created_ids.length).to be > 0

        # Second retrieval - from cache
        dr2 = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr2.retrieve_validate_store

        expect(dr2.retrieved_from_cache).to be true
        expect(dr2.storage_stage).to eq 'skipped (from cache)'
        expect(dr2.created_ids.length).to eq 0
        expect(dr2.updated_ids.length).to eq 0
      end

      it 'records error in job request when exception occurs' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin

        stub_request_records @project[:server_url], @project[:api_key]

        # Create DataRecords instance and make it fail during store
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)

        # Stub the store method to raise an exception
        allow(dr).to receive(:store).and_raise(StandardError, 'Test error during store')

        expect { dr.retrieve_validate_store }.to raise_error(StandardError, 'Test error during store')

        # Verify the error was recorded
        expect(dr.errors).to be_an Array
        expect(dr.errors.length).to eq 1
        expect(dr.errors.first[:error]).to eq 'Test error during store'
        expect(dr.errors.first[:backtrace]).to be_present
        # storage_stage preserves where failure occurred with "(failed)" appended
        expect(dr.storage_stage).to eq 'validate (failed)'

        # Verify the job request was updated with the error
        job_request = Redcap::ClientRequest.where(
          redcap_project_admin: rc,
          action: 'store records'
        ).order(created_at: :desc).first

        expect(job_request).to be_present
        expect(job_request.result['errors']).to be_an Array
        expect(job_request.result['errors'].length).to eq 1
        expect(job_request.result['errors'].first['error']).to eq 'Test error during store'

        # This job request should NOT be picked up by last_successful_store_records_at
        expect(rc.last_successful_store_records_at).to be_nil
      end
    end

    describe 'deleted records handling with date range' do
      it 'skips deleted records validation when using date range filter' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        # Store records first
        stub_request_records @project[:server_url], @project[:api_key]
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr.retrieve
        dr.summarize_fields
        dr.handle_survey_identifier
        dr.validate
        dr.store

        original_count = dm.implementation_class.count
        expect(original_count).to be > 0

        # Create a successful ClientRequest for 'store records' to enable date range calculation
        Redcap::ClientRequest.create!(
          current_admin: @admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          result: { errors: [] },
          created_at: 5.minutes.ago
        )

        # Clear cache to force new request
        rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

        # Now retrieve with a date range (returning fewer records using 'updated_records' fixture)
        stub_request_records_with_date_range @project[:server_url], @project[:api_key]

        dr2 = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr2.retrieve

        # With date range filter, validation should not fail even if fewer records returned
        expect { dr2.validate }.not_to raise_error
        expect(dr2.using_date_range_filter).to be true
      end

      it 'does not disable records when using date range filter' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.data_options.handle_deleted_records = 'disable'
        rc.save!

        # Store records first
        stub_request_records @project[:server_url], @project[:api_key]
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr.retrieve
        dr.summarize_fields
        dr.handle_survey_identifier
        dr.validate
        dr.store

        original_count = dm.implementation_class.count
        expect(original_count).to be > 0

        # Create a successful ClientRequest for 'store records' to enable date range calculation
        Redcap::ClientRequest.create!(
          current_admin: @admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          result: { errors: [] },
          created_at: 5.minutes.ago
        )

        # Clear cache
        rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

        # Retrieve with date range (returning subset using 'updated_records' fixture)
        stub_request_records_with_date_range @project[:server_url], @project[:api_key]

        dr2 = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr2.retrieve
        dr2.summarize_fields
        dr2.handle_survey_identifier
        dr2.validate
        dr2.store

        # No records should have been disabled since we're using date range filter
        expect(dr2.disabled_ids.length).to eq 0
        expect(dm.implementation_class.where(disabled: true).count).to eq 0
      end
    end
  end

  describe 'ignore_cache and retrieve_all parameters' do
    before :all do
      @bad_admin, = create_admin
      @bad_admin.update! disabled: true
      create_admin
      @projects = setup_redcap_project_admin_configs
      @project = @projects.first
      setup_file_fields
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

    describe 'ignore_cache parameter' do
      it 'forces API request when ignore_cache is true' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin

        # Clear the cache first
        rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

        # First request should be from API
        res1 = rc.api_client.records
        expect(rc.api_client.last_result_from_cache).to be false

        # Second request should be from cache
        res2 = rc.api_client.records
        expect(rc.api_client.last_result_from_cache).to be true

        # Third request with ignore_cache should be from API
        res3 = rc.api_client.records(ignore_cache: true)
        expect(rc.api_client.last_result_from_cache).to be false
      end

      it 'uses cache normally when ignore_cache is false' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin

        # Clear the cache first
        rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

        # First request from API
        res1 = rc.api_client.records(ignore_cache: false)
        expect(rc.api_client.last_result_from_cache).to be false

        # Second request from cache (ignore_cache: false is default behavior)
        res2 = rc.api_client.records(ignore_cache: false)
        expect(rc.api_client.last_result_from_cache).to be true
      end
    end

    describe 'retrieve_all parameter' do
      it 'retrieves all records when retrieve_all is true' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        # Create a successful ClientRequest for 'store records'
        Redcap::ClientRequest.create!(
          current_admin: @admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          result: { errors: [] },
          created_at: 5.minutes.ago
        )

        stub_request_records @project[:server_url], @project[:api_key]

        # Create DataRecords instance with retrieve_all: true
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name, is_manual_pull: true)

        # With retrieve_all: true, date range should not be used
        dr.retrieve(retrieve_all: true)
        expect(dr.using_date_range_filter).to be false
      end

      it 'uses date range when retrieve_all is false' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        # Create a successful ClientRequest for 'store records'
        Redcap::ClientRequest.create!(
          current_admin: @admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          result: { errors: [] },
          created_at: 5.minutes.ago
        )

        # Stub request with dateRangeBegin
        stub_request_records_with_date_range @project[:server_url], @project[:api_key]

        # Create DataRecords instance with retrieve_all: false (default)
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name, is_manual_pull: true)
        dr.retrieve(retrieve_all: false)

        # With retrieve_all: false, date range should be used
        expect(dr.using_date_range_filter).to be true
      end
    end

    describe 'ProjectAdmin helper methods' do
      it 'export_only_updated_records_for_manual? returns true when set to manual' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'manual'
        rc.save!

        expect(rc.export_only_updated_records_for_manual?).to be true
      end

      it 'export_only_updated_records_for_manual? returns true when set to always' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        expect(rc.export_only_updated_records_for_manual?).to be true
      end

      it 'export_only_updated_records_for_manual? returns false when set to scheduled' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'scheduled'
        rc.save!

        expect(rc.export_only_updated_records_for_manual?).to be false
      end

      it 'export_only_updated_records_for_manual? returns false when not set' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = nil
        rc.save!

        expect(rc.export_only_updated_records_for_manual?).to be false
      end

      it 'date_range_begin_for_manual_pull returns timestamp when successful store records exists' do
        # This test verifies that when there is a successful store records ClientRequest,
        # the date_range_begin_for_manual_pull returns the ClientRequest created_at timestamp.
        rc = @project_admin
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'manual'
        rc.save!

        # Create a successful ClientRequest for 'store records'
        store_time = 5.minutes.ago
        Redcap::ClientRequest.create!(
          current_admin: @admin,
          action: 'store records',
          server_url: rc.server_url,
          name: rc.name,
          redcap_project_admin: rc,
          result: { errors: [] },
          created_at: store_time
        )

        # Now check the date range from ProjectAdmin
        date_range = rc.date_range_begin_for_manual_pull

        expect(date_range).to be_a Time
        expect(date_range.to_i).to eq store_time.to_i
      end

      it 'date_range_begin_for_manual_pull returns nil when option not set' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = nil
        rc.save!

        expect(rc.date_range_begin_for_manual_pull).to be_nil
      end
    end
  end

  # Helper method to stub requests with dateRangeBegin
  # Uses the 'updated_records' fixture which returns a subset of updated records
  def stub_request_records_with_date_range(server_url, api_key)
    # Stub the request that includes dateRangeBegin
    stub_request(:post, server_url)
      .with(
        body: hash_including({
                               'token' => api_key,
                               'content' => 'record',
                               'format' => 'json'
                             })
      )
      .to_return(status: 200, body: data_sample_response('updated_records'), headers: {})
  end
end
