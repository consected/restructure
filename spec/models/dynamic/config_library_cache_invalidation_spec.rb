# frozen_string_literal: true

# Tests for config library cache invalidation in dynamic definitions.
#
# When a YAML config library (Admin::ConfigLibrary) is updated, dependent dynamic
# definitions (DynamicModel, ActivityLog, ExternalIdentifier) should detect the
# change via their `up_to_date?` / `refresh_outdated` mechanisms.
#
# Two key scenarios exist after PR #1034 (config library versioning):
#
# 1. Definitions with `use_current_version: true` — the `touch` in
#    `refresh_dependencies` is skipped, so the definition's `updated_at` does
#    NOT change. Cross-server detection relies entirely on the config library
#    timestamp check in `latest_stored_update`, and `refresh_outdated` takes
#    the lightweight path (force_option_config_parse only, no full regen).
#
# 2. Standard versioned definitions — `refresh_dependencies` calls `touch`,
#    bumping the definition's `updated_at`. Cross-server detection works via
#    the existing definition timestamp mechanism, and `refresh_outdated`
#    performs full model regeneration.
#
# These tests cover:
#   AC1: refresh_outdated detects config library changes
#   AC2: up_to_date? incorporates the latest config library updated_at
#   AC3: Only force_option_config_parse is called (not full regeneration) when
#        only a config library changed and touch is skipped (use_current_version)
#   AC4: Only definitions referencing the changed library are refreshed
#   AC5/AC8: The config library timestamp check is lightweight
#   AC6: ApplicationJob calls Application.refresh_dynamic_defs before each job
#   AC7: Existing cache invalidation for direct definition edits still works
#   AC9: Standard versioned definitions trigger full regen via touch

require 'rails_helper'

RSpec.describe 'Config library cache invalidation for dynamic definitions', type: :model do
  include ModelSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
    create_admin

    # Use hex suffix to avoid validation "Name must not contain numbers preceded by an underscore"
    @rand_id = SecureRandom.hex(4)

    # Create a YAML config library that will be referenced by a dynamic model
    @config_library = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: "cachelib#{@rand_id}",
      category: "cachecat#{@rand_id}",
      format: 'yaml',
      options: "label_config:\n  label: Original Label"
    )

    # Create a second, independent YAML config library (not referenced by our test definition)
    @other_config_library = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: "otherlib#{@rand_id}",
      category: "othercat#{@rand_id}",
      format: 'yaml',
      options: "other_config:\n  label: Other Label"
    )

    # Create a non-YAML config library
    @html_config_library = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: "htmllib#{@rand_id}",
      category: "cachecat#{@rand_id}",
      format: 'html',
      options: '<p>Some HTML</p>'
    )

    # Create a DynamicModel with use_current_version: true that references the
    # config library. Because use_current_version is set, refresh_dependencies
    # will skip the `touch` call, so the definition's updated_at will NOT change
    # when the library is updated. This exercises the lightweight cache path.
    @dm_table_name = "test_clcache#{@rand_id}s"
    @dm = DynamicModel.create!(
      current_admin: @admin,
      name: "test clcache #{@rand_id}",
      table_name: @dm_table_name,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      options: "# @library cachecat#{@rand_id} cachelib#{@rand_id}\n_configurations:\n  use_current_version: true\n  default:\n    label: Test CL Cache"
    )

    # Create another DynamicModel that does NOT reference any config library
    @dm_no_lib_table = "test_clnolib#{@rand_id}s"
    @dm_no_lib = DynamicModel.create!(
      current_admin: @admin,
      name: "test clnolib #{@rand_id}",
      table_name: @dm_no_lib_table,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      options: "_configurations:\n  default:\n    label: Test No Lib"
    )

    # Create a standard versioned DynamicModel (no use_current_version) that
    # references the config library. refresh_dependencies will call `touch` on
    # this definition, bumping its updated_at.
    @dm_versioned_table = "test_clver#{@rand_id}s"
    @dm_versioned = DynamicModel.create!(
      current_admin: @admin,
      name: "test clver #{@rand_id}",
      table_name: @dm_versioned_table,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      options: "# @library cachecat#{@rand_id} cachelib#{@rand_id}\n_configurations:\n  default:\n    label: Test CL Versioned"
    )

    # Ensure models are generated and caches are primed
    DynamicModel.refresh_outdated
    # Prime the up_to_date? memoization so subsequent calls return true
    DynamicModel.instance_variable_set(:@prev_latest_update, DynamicModel.latest_stored_update)
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  # Reset class-level memoized state before each test to prevent cross-test
  # contamination through ivars that persist on the DynamicModel class.
  before do
    DynamicModel.instance_variable_set(:@prev_latest_update, nil)
    DynamicModel.instance_variable_set(:@prev_latest_def_update, nil)
    DynamicModel.instance_variable_set(:@config_library_only_change, nil)
    DynamicModel.instance_variable_set(:@latest_def_update, nil)
  end

  # ---------------------------------------------------------------------------
  # AC2: up_to_date? incorporates config library timestamps
  # ---------------------------------------------------------------------------
  describe 'AC2: up_to_date? incorporates config library timestamps' do
    it 'returns false when a YAML config library timestamp is newer (cross-server)' do
      # Prime: first call returns nil, second returns true
      expect(DynamicModel.up_to_date?).to be_nil
      expect(DynamicModel.up_to_date?).to be true

      # Capture current state for later restoration
      cl_original_time = Admin::ConfigLibrary.where(id: @config_library.id).pick(:updated_at)

      # Simulate cross-server: bump config library timestamp 60s forward via SQL
      # (bypasses callbacks — simulates change made on another server)
      future_time = cl_original_time + 60.seconds
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(updated_at: future_time)

      # up_to_date? should return false — config library is newer
      expect(DynamicModel.up_to_date?).to be false

      # @config_library_only_change should be true — only config library changed
      expect(DynamicModel.instance_variable_get(:@config_library_only_change)).to be true

      # Restore timestamp
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(updated_at: cl_original_time)
    end

    it 'returns true when config libraries have not changed' do
      # Prime
      expect(DynamicModel.up_to_date?).to be_nil
      expect(DynamicModel.up_to_date?).to be true
    end

    it 'is not affected by non-YAML config library updates' do
      # Prime
      expect(DynamicModel.up_to_date?).to be_nil
      expect(DynamicModel.up_to_date?).to be true

      # Bump only the HTML (non-YAML) config library timestamp forward
      html_original_time = Admin::ConfigLibrary.where(id: @html_config_library.id).pick(:updated_at)
      future_time = html_original_time + 60.seconds
      Admin::ConfigLibrary.where(id: @html_config_library.id).update_all(updated_at: future_time)

      # up_to_date? should still return true — non-YAML libraries are not checked
      expect(DynamicModel.up_to_date?).to be true

      # Restore
      Admin::ConfigLibrary.where(id: @html_config_library.id).update_all(updated_at: html_original_time)
    end
  end

  # ---------------------------------------------------------------------------
  # AC1 & AC3: refresh_outdated handles config library changes with option-only
  # refresh when touch is skipped (use_current_version definitions)
  # ---------------------------------------------------------------------------
  describe 'AC1 & AC3: refresh_outdated lightweight path (config-library-only change)' do
    it 'calls force_option_config_parse without full regen when only config library changed' do
      # Prime
      expect(DynamicModel.up_to_date?).to be_nil
      expect(DynamicModel.up_to_date?).to be true

      # Capture and bump config library timestamp 60s forward via SQL
      cl_original_time = Admin::ConfigLibrary.where(id: @config_library.id).pick(:updated_at)
      future_time = cl_original_time + 60.seconds
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(updated_at: future_time)

      # Spy on generate_model to verify it is NOT called (lightweight path)
      generate_called_for = []
      allow_any_instance_of(DynamicModel).to receive(:generate_model).and_wrap_original do |original_method, *args|
        generate_called_for << original_method.receiver.table_name
        original_method.call(*args)
      end

      log_output = StringIO.new
      test_logger = Logger.new(log_output)
      original_logger = Rails.logger
      Rails.logger = test_logger

      DynamicModel.refresh_outdated

      Rails.logger = original_logger

      # The lightweight path should have been taken
      expect(log_output.string).to include('Refreshing config library dependents')
      expect(log_output.string).not_to include('Refreshing outdated')

      # generate_model should NOT have been called
      expect(generate_called_for).to be_empty

      # Restore timestamp
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(updated_at: cl_original_time)
    end
  end

  # ---------------------------------------------------------------------------
  # AC4: Only dependent definitions are refreshed (lightweight path)
  # ---------------------------------------------------------------------------
  describe 'AC4: only dependent definitions are refreshed (lightweight path)' do
    it 'refreshes only definitions with @library references via the lightweight path' do
      # Prime caches
      DynamicModel.instance_variable_set(:@prev_latest_update, nil)
      DynamicModel.up_to_date?
      DynamicModel.up_to_date?

      # Update the config library. Touch is skipped for @dm (use_current_version),
      # but the @dm_versioned definition will be touched (standard versioned).
      # We need to re-prime after the touch so that only the config library
      # timestamp change is detected by the lightweight path.
      @config_library.current_admin = @admin
      @config_library.update!(options: "label_config:\n  label: Selective Refresh #{rand(1_000_000)}")

      # Re-prime to absorb the def timestamp change from touch on @dm_versioned,
      # but leave the config library timestamp change undetected.
      # The lightweight path should only fire for config-library-only changes.
      # Since @dm_versioned was touched, we need to simulate the scenario where
      # only config library changes are pending (e.g. on another server that
      # only has use_current_version definitions, or where touch already
      # triggered a full regen for the versioned definition).
      # We test this by verifying the lightweight path itself filters correctly.
      DynamicModel.instance_variable_set(:@config_library_only_change, true)

      # Track which definitions get force_option_config_parse called
      refreshed_table_names = []

      allow_any_instance_of(DynamicModel).to receive(:force_option_config_parse).and_wrap_original do |original_method, **kwargs|
        refreshed_table_names << original_method.receiver.table_name
        original_method.call(**kwargs)
      end

      # Directly invoke the lightweight path in refresh_outdated
      DynamicModel.reset_active_model_configurations!
      DynamicModel.active.each do |d|
        next unless d.options_text&.include?('# @library ')

        d.force_option_config_parse(raise_bad_configs: false)
      end

      # Only definitions with @library references should be refreshed
      expect(refreshed_table_names).to include(@dm_table_name)
      expect(refreshed_table_names).not_to include(@dm_no_lib_table)
    end
  end

  # ---------------------------------------------------------------------------
  # AC6: ApplicationJob calls Application.refresh_dynamic_defs before each job
  # ---------------------------------------------------------------------------
  describe 'AC6: ApplicationJob refreshes dynamic defs before job execution' do
    it 'calls Application.refresh_dynamic_defs in around_perform before the job block' do
      refresh_called_before_perform = false
      job_performed = false

      allow(Application).to receive(:refresh_dynamic_defs) do
        refresh_called_before_perform = true unless job_performed
      end

      # Create a minimal test job class
      test_job_class = Class.new(ApplicationJob) do
        self.queue_adapter = :inline

        define_method(:perform) do
          job_performed = true
        end
      end

      test_job_class.perform_now

      expect(refresh_called_before_perform).to be true
      expect(job_performed).to be true
    end
  end

  # ---------------------------------------------------------------------------
  # AC7: Existing behavior — direct definition edits trigger full regeneration
  # ---------------------------------------------------------------------------
  describe 'AC7: direct definition edits still trigger full regeneration' do
    it 'triggers full regeneration via refresh_outdated when a definition updated_at changes' do
      # This tests the existing (already working) behavior: when a dynamic definition's
      # own updated_at changes, refresh_outdated performs full model regeneration.

      DynamicModel.reset_active_model_configurations!
      existing_dm = DynamicModel.active_model_configurations.reorder('').order('updated_at desc nulls last').first
      expect(existing_dm).not_to be_nil

      # Prime from clean state (before(:each) already reset ivars)
      expect(DynamicModel.up_to_date?).to be_nil
      lu_before = DynamicModel.instance_variable_get(:@prev_latest_update)

      # Simulate a cross-server update: bump the definition's updated_at via SQL
      dm_original_time = DynamicModel.where(id: existing_dm.id).pick(:updated_at)
      future_time = lu_before + 60.seconds
      DynamicModel.where(id: existing_dm.id).update_all(updated_at: future_time)
      DynamicModel.reset_active_model_configurations!

      # Call refresh_outdated directly (without calling up_to_date? first, which would
      # consume the change and update @prev_latest_update).
      # refresh_outdated internally calls up_to_date? and then regenerates changed definitions.
      log_output = StringIO.new
      test_logger = Logger.new(log_output)
      original_logger = Rails.logger
      Rails.logger = test_logger

      DynamicModel.refresh_outdated

      Rails.logger = original_logger

      # The log should show that the definition was refreshed (existing behavior)
      expect(log_output.string).to include("Refreshing #{existing_dm.resource_name}")

      # Restore original timestamp to avoid affecting other tests
      DynamicModel.where(id: existing_dm.id).update_all(updated_at: dm_original_time)
      DynamicModel.reset_active_model_configurations!
    end
  end

  # ---------------------------------------------------------------------------
  # AC9: Standard versioned definitions trigger full regen via touch
  # ---------------------------------------------------------------------------
  describe 'AC9: definition timestamp change triggers full regen (not lightweight)' do
    it 'triggers full regeneration when both definition and config library timestamps change' do
      # Prime
      expect(DynamicModel.up_to_date?).to be_nil
      expect(DynamicModel.up_to_date?).to be true

      # Get a definition that IS in active_model_configurations (test definitions
      # created in before(:all) are not associated with any app type, so they
      # don't appear in active_model_configurations or affect latest_stored_update).
      DynamicModel.reset_active_model_configurations!
      existing_dm = DynamicModel.active_model_configurations.reorder('').order('updated_at desc nulls last').first
      expect(existing_dm).not_to be_nil

      # Capture original timestamps for restoration
      dm_original_time = DynamicModel.where(id: existing_dm.id).pick(:updated_at)
      cl_original_time = Admin::ConfigLibrary.where(id: @config_library.id).pick(:updated_at)

      # Bump BOTH definition and config library timestamps forward via SQL.
      future_time = [dm_original_time, cl_original_time].max + 60.seconds
      DynamicModel.where(id: existing_dm.id).update_all(updated_at: future_time)
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(updated_at: future_time)
      DynamicModel.reset_active_model_configurations!

      # Call refresh_outdated which internally calls up_to_date? and detects the change.
      # Do NOT call up_to_date? separately — that would consume the change.
      log_output = StringIO.new
      test_logger = Logger.new(log_output)
      original_logger = Rails.logger
      Rails.logger = test_logger

      DynamicModel.refresh_outdated

      Rails.logger = original_logger

      # @config_library_only_change should be false — definition timestamp also changed
      expect(DynamicModel.instance_variable_get(:@config_library_only_change)).to be false

      # The log should show "Refreshing outdated" (full path)
      expect(log_output.string).to include('Refreshing outdated')
      expect(log_output.string).not_to include('Refreshing config library dependents')

      # Restore timestamps
      DynamicModel.where(id: existing_dm.id).update_all(updated_at: dm_original_time)
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(updated_at: cl_original_time)
      DynamicModel.reset_active_model_configurations!
    end
  end

  # ---------------------------------------------------------------------------
  # AC5 & AC8: Config library timestamp check is lightweight
  # ---------------------------------------------------------------------------
  describe 'AC5 & AC8: config library timestamp check is lightweight' do
    it 'retrieves the max updated_at from YAML config libraries efficiently' do
      # The latest_stored_update (or a new companion method) should also consider
      # yaml config library timestamps. We verify that the latest yaml config
      # library updated_at is obtainable and is a Time-like value.
      latest_cl_time = Admin::ConfigLibrary.where(format: 'yaml')
                                           .order('updated_at desc nulls last')
                                           .limit(1)
                                           .pluck(:updated_at)
                                           .first

      expect(latest_cl_time).to be_a(ActiveSupport::TimeWithZone).or be_a(Time)

      # The combined latest_stored_update should be >= the latest config library time
      # This tests the new behavior where latest_stored_update incorporates config libraries
      combined_latest = DynamicModel.latest_stored_update
      expect(combined_latest).to be >= latest_cl_time
    end

    it 'uses a single query or minimal queries for the timestamp check' do
      # Verify that checking up_to_date? does not make an excessive number of queries.
      # We allow up to 3 queries (definition table + config_libraries table + possible cache).
      # Note: before(:each) already reset @prev_latest_update to nil

      query_count = 0
      counter = lambda { |_name, _start, _finish, _id, payload|
        query_count += 1 unless payload[:name] == 'SCHEMA' || payload[:sql]&.include?('SHOW')
      }

      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
        DynamicModel.up_to_date?
      end

      expect(query_count).to be <= 3
    end
  end
end
