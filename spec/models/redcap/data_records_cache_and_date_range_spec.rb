# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Test Summary: Redcap::DataRecords cache and date range
# ======================================================
#
# This spec exercises the REDCap caching and date range filtering features
# added to support GitHub issue #379.
#
# 1. Configurable Cache Times (8 tests)
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
# 2. Export Only Updated Records (11 tests)
#    --------------------------------------
#    validation of export_only_updated_records option:
#      - allows valid values (nil, blank, 'always', 'manual')
#      - rejects invalid values
#
#    calculate_date_range_begin:
#      - returns nil when option not set
#      - returns nil when 'manual' but is_manual_pull is false
#      - returns nil when no records exist
#      - returns max(created_at, updated_at) when 'always' with existing records
#      - calculates for manual pulls when option is 'manual'
#
#    using_date_range_filter:
#      - sets flag to true when dateRangeBegin is used in retrieve()
#
#    skipping cached results:
#      - skips validate and store when results are from cache
#
#    deleted records handling with date range:
#      - skips deleted records validation when using date range filter
#      - does not disable records when using date range filter
#
# Key Components Being Tested:
#   - ApiClient cache configuration flows through from data_options
#   - Cache hit tracking via last_result_from_cache attribute
#   - Option validation for export_only_updated_records
#   - Date range calculation using SQL GREATEST(created_at, updated_at)
#   - Conditional date filtering based on is_manual_pull flag
#   - Cache skip behavior in retrieve_validate_store()
#   - Deleted record handling disabled when using date range filter

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
      end

      it 'rejects invalid values for export_only_updated_records' do
        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'invalid'

        expect(rc).not_to be_valid
        expect(rc.errors[:data_options]).to include("export_only_updated_records must be one of: #{Redcap::ProjectAdmin::ValidExportOnlyUpdatedRecordsValues}")
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

      it 'returns nil when no records exist in the model' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        # Ensure no records exist
        dm.implementation_class.delete_all

        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        date_range = dr.send(:calculate_date_range_begin)

        expect(date_range).to be_nil
      end

      it 'returns max timestamp when records exist and export_only_updated_records is always' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        # First, store some records
        stub_request_records @project[:server_url], @project[:api_key]
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr.retrieve
        dr.summarize_fields
        dr.handle_survey_identifier
        dr.validate
        dr.store

        expect(dm.implementation_class.count).to be > 0

        # Now check the date range is calculated
        dr2 = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        date_range = dr2.send(:calculate_date_range_begin)

        expect(date_range).to be_a Time
        expect(date_range).to be <= Time.current
      end

      it 'calculates date range for manual pulls when export_only_updated_records is manual' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'manual'
        rc.save!

        # Store some records first
        stub_request_records @project[:server_url], @project[:api_key]
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name, is_manual_pull: true)
        dr.retrieve
        dr.summarize_fields
        dr.handle_survey_identifier
        dr.validate
        dr.store

        expect(dm.implementation_class.count).to be > 0

        # Manual pull should calculate date range
        dr2 = Redcap::DataRecords.new(rc, dm.implementation_class.name, is_manual_pull: true)
        date_range = dr2.send(:calculate_date_range_begin)

        expect(date_range).to be_a Time
      end
    end

    describe 'using_date_range_filter' do
      it 'sets using_date_range_filter when date range is used' do
        dm = create_dynamic_model_for_sample_response

        rc = Redcap::ProjectAdmin.active.first
        rc.current_admin = @admin
        rc.data_options.export_only_updated_records = 'always'
        rc.save!

        # Store some records first
        stub_request_records @project[:server_url], @project[:api_key]
        dr = Redcap::DataRecords.new(rc, dm.implementation_class.name)
        dr.retrieve
        dr.summarize_fields
        dr.handle_survey_identifier
        dr.validate
        dr.store

        expect(dm.implementation_class.count).to be > 0

        # Create a new DataRecords instance
        dr2 = Redcap::DataRecords.new(rc, dm.implementation_class.name)

        # Stub request with dateRangeBegin
        stub_request_records_with_date_range @project[:server_url], @project[:api_key]

        dr2.retrieve

        expect(dr2.using_date_range_filter).to be true
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
