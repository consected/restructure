# frozen_string_literal: true

# Tests for config library cache invalidation in dynamic definitions.
#
# When a YAML config library (Admin::ConfigLibrary) is updated, dependent dynamic
# definitions (DynamicModel, ActivityLog, ExternalIdentifier) should detect the
# change through repeatable token-backed refresh status checks.
#
# Two key scenarios exist after PR #1034 (config library versioning):
#
# 1. Definitions with `use_current_version: true` — the `touch` in
#    `refresh_dependencies` is skipped, so the definition's `updated_at` does
#    NOT change. The shared definition token and verified library timestamp enable
#    `refresh_outdated` to take the lightweight path (option parsing only).
#
# 2. Standard versioned definitions — `refresh_dependencies` calls `touch`,
#    bumping the definition's `updated_at`. Cross-server detection works via
#    the existing definition timestamp mechanism, and `refresh_outdated`
#    performs full model regeneration.
#
# These tests cover:
#   AC1: refresh_outdated detects config library changes
#   AC2: definition_refresh_status detects library-only changes repeatably
#   AC3: Only force_option_config_parse is called (not full regeneration) when
#        only a config library changed and touch is skipped (use_current_version)
#   AC4: Only definitions referencing the changed library are refreshed
#   AC5/AC8: The config library timestamp check is lightweight
#   AC6: ApplicationJob calls Application.refresh_dynamic_defs before each job
#   AC7: Existing cache invalidation for direct definition edits still works
#   AC9: Standard versioned definitions trigger full regen via touch
#   AC10: ActivityLog definitions refresh through their extra_log_types attribute

require 'rails_helper'

RSpec.describe 'Config library cache invalidation for dynamic definitions', type: :model do
  include ModelSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
    create_admin

    # Use hex suffix to avoid validation "Name must not contain numbers preceded by an underscore"
    @rand_id = SecureRandom.hex(4)
    @library_v1_options = <<~YAML
      _definitions_lib:
        cache_label: &cache_label Original Label
    YAML
    @library_v2_options = <<~YAML
      _definitions_lib:
        cache_label: &cache_label Refreshed Label
    YAML

    # Create a YAML config library that will be referenced by a dynamic model
    @config_library = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: "cachelib#{@rand_id}",
      category: "cachecat#{@rand_id}",
      format: 'yaml',
      options: @library_v1_options
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
      options: <<~YAML
        # @library cachecat#{@rand_id} cachelib#{@rand_id}
        _configurations:
          use_current_version: true
        default:
          label: *cache_label
      YAML
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
    @activity_log = ActivityLog.create!(
      current_admin: @admin,
      name: "activity log cache #{@rand_id}",
      item_type: 'player_contact',
      rec_type: 'email',
      process_name: "cache#{@rand_id}",
      schema_name: 'dynamic_test',
      category: :test,
      action_when_attribute: 'created_at',
      extra_log_types: <<~YAML
        # @library cachecat#{@rand_id} cachelib#{@rand_id}
        _configurations:
          use_current_version: true
        cache_step:
          label: *cache_label
          fields:
            - data
      YAML
    )
    ActivityLog.refresh_outdated
    @activity_log.reload
    @activity_log.force_option_config_parse
  end

  after :all do
    @activity_log&.disable!(@admin)
    change_setting('AllowDynamicMigrations', false)
  end

  # Establish a complete worker baseline before each example; subsequent writes rotate the shared token.
  before do
    [DynamicModel, ActivityLog].each do |definition_class|
      definition_class.instance_variable_set(:@verified_definition_cache_token, nil)
      definition_class.instance_variable_set(:@verified_definition_timestamps, nil)
      definition_class.instance_variable_set(:@verified_config_library_updated_at, nil)
      definition_class.refresh_outdated
    end
  end

  # ---------------------------------------------------------------------------
  # AC2: repeatable definition refresh status checks
  # ---------------------------------------------------------------------------
  describe 'AC2: definition_refresh_status detects config library changes' do
    it 'returns a stable library-only status after a YAML library changes' do
      original_time = Admin::ConfigLibrary.where(id: @config_library.id).pick(:updated_at)
      future_time = original_time + 60.seconds
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(updated_at: future_time)
      Dynamic::DefinitionCacheVersion.rotate!

      expect(DynamicModel.definition_refresh_status).to eq(:library_only_changed)
      expect(DynamicModel.definition_refresh_status).to eq(:library_only_changed)
    ensure
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(updated_at: original_time)
      Dynamic::DefinitionCacheVersion.rotate!
    end

    it 'returns current when config libraries have not changed' do
      expect(DynamicModel.definition_refresh_status).to eq(:current)
    end

    it 'is not affected by non-YAML config library updates' do
      html_original_time = Admin::ConfigLibrary.where(id: @html_config_library.id).pick(:updated_at)
      Admin::ConfigLibrary.where(id: @html_config_library.id).update_all(updated_at: html_original_time + 60.seconds)

      expect(DynamicModel.definition_refresh_status).to eq(:current)
    ensure
      Admin::ConfigLibrary.where(id: @html_config_library.id).update_all(updated_at: html_original_time)
    end
  end

  # ---------------------------------------------------------------------------
  # AC1 & AC3: refresh_outdated handles config library changes with option-only
  # refresh when touch is skipped (use_current_version definitions)
  # ---------------------------------------------------------------------------
  describe 'AC1 & AC3: refresh_outdated lightweight path (config-library-only change)' do
    it 'refreshes both item-type lists after a dependent YAML library changes without clearing the cache' do
      allow(DynamicModel).to receive(:active).and_return(DynamicModel.where(id: @dm.id))
      allow(ActivityLog).to receive(:active).and_return(ActivityLog.none)
      allow(ExternalIdentifier).to receive(:active).and_return(ExternalIdentifier.none)
      token_before = Dynamic::DefinitionCacheVersion.token
      incomplete_class = double(attribute_names: ['select_library_before'], model_name: double(to_s: 'CacheTest'))
      complete_class = double(attribute_names: ['select_library_after'], model_name: double(to_s: 'CacheTest'))
      allow(DynamicModel).to receive(:implementation_classes) do
        Dynamic::DefinitionCacheVersion.token == token_before ? [incomplete_class] : [complete_class]
      end
      Dynamic::DefinitionCache.delete('DynamicModel.item_types')
      Dynamic::DefinitionCache.delete('Classification::GeneralSelection.item_types', Report.item_types_cache_version)
      expect(DynamicModel.item_types.map(&:to_s)).to include(a_string_matching(/select_library_before\z/))
      expect(Classification::GeneralSelection.item_types.map(&:to_s))
        .to include(a_string_matching(/select_library_before\z/))

      expect(Rails.cache).not_to receive(:clear)
      @config_library.reload
      @config_library.current_admin = @admin
      @config_library.update!(options: @library_v2_options)

      expect(Dynamic::DefinitionCacheVersion.token).not_to eq(token_before)
      expect(DynamicModel.item_types.map(&:to_s)).to include(a_string_matching(/select_library_after\z/))
      expect(Classification::GeneralSelection.item_types.map(&:to_s))
        .to include(a_string_matching(/select_library_after\z/))
    ensure
      @config_library.reload
      if @config_library.options != @library_v1_options
        @config_library.current_admin = @admin
        @config_library.update!(options: @library_v1_options)
      end
    end

    it 'rotates dependent cache versions when a live YAML library changes' do
      allow(DynamicModel).to receive(:active).and_return(DynamicModel.where(id: @dm.id))
      allow(ActivityLog).to receive(:active).and_return(ActivityLog.none)
      allow(ExternalIdentifier).to receive(:active).and_return(ExternalIdentifier.none)
      version_before = Dynamic::DefinitionCacheVersion.token

      @config_library.current_admin = @admin
      @config_library.update!(options: @library_v2_options)

      expect(Dynamic::DefinitionCacheVersion.token).not_to eq(version_before)
    end

    it 'refreshes the access control resource names key when a library used by a definition changes' do
      key_before = Admin::UserAccessControl.resource_names_cache_key

      # The before :all instance can carry options changed (then rolled back) by an earlier example
      @config_library.reload
      @config_library.current_admin = @admin
      @config_library.update!(options: @library_v2_options)

      expect(Admin::UserAccessControl.resource_names_cache_key).not_to eq(key_before)
    end

    it 'keeps the access control resource names key when a library used by no definition changes' do
      key_before = Admin::UserAccessControl.resource_names_cache_key

      @other_config_library.reload
      @other_config_library.current_admin = @admin
      @other_config_library.update!(options: "other_config:\n  label: Other Label Changed")

      expect(Admin::UserAccessControl.resource_names_cache_key).to eq(key_before)
    end

    it 'calls force_option_config_parse without full regen when only config library changed' do
      # Capture and bump config library timestamp 60s forward via SQL
      cl_original_time = Admin::ConfigLibrary.where(id: @config_library.id).pick(:updated_at)
      cl_original_options = Admin::ConfigLibrary.where(id: @config_library.id).pick(:options)
      future_time = cl_original_time + 60.seconds
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(
        options: @library_v2_options,
        updated_at: future_time
      )
      Dynamic::DefinitionCacheVersion.rotate!

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

      begin
        DynamicModel.refresh_outdated

        cached_definition = DynamicModel.definition_cache[@dm.id]
        expect(cached_definition.option_type_config_for(:default).label).to eq('Refreshed Label')
      ensure
        Rails.logger = original_logger
        Admin::ConfigLibrary.where(id: @config_library.id).update_all(
          options: cl_original_options,
          updated_at: cl_original_time
        )
        Dynamic::DefinitionCacheVersion.rotate!
        cached_definition = DynamicModel.definition_cache[@dm.id]
        cached_definition.reload
        cached_definition.force_option_config_parse
      end

      # The lightweight path should have been taken
      expect(log_output.string).to include('Refreshing config library dependents')
      expect(log_output.string).not_to include('Refreshing outdated')

      # generate_model should NOT have been called
      expect(generate_called_for).to be_empty
    end
  end

  # ---------------------------------------------------------------------------
  # AC10: ActivityLog uses its own option_configs_attr in the lightweight path
  # ---------------------------------------------------------------------------
  describe 'ActivityLog lightweight path' do
    it 'refreshes the cached definition when extra_log_types references a changed library' do
      cl_original_time = Admin::ConfigLibrary.where(id: @config_library.id).pick(:updated_at)
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(options: @library_v1_options)

      cached_definition = ActivityLog.definition_cache[@activity_log.id]
      cached_definition.reload
      cached_definition.force_option_config_parse
      ActivityLog.definition_cache[@activity_log.id] = cached_definition

      future_time = cl_original_time + 60.seconds
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(
        options: @library_v2_options,
        updated_at: future_time
      )
      Dynamic::DefinitionCacheVersion.rotate!

      begin
        ActivityLog.refresh_outdated

        cached_definition = ActivityLog.definition_cache[@activity_log.id]
        expect(cached_definition.option_type_config_for(:cache_step).label).to eq('Refreshed Label')
      ensure
        Admin::ConfigLibrary.where(id: @config_library.id).update_all(
          options: @library_v1_options,
          updated_at: cl_original_time
        )
        Dynamic::DefinitionCacheVersion.rotate!
        cached_definition = ActivityLog.definition_cache[@activity_log.id]
        cached_definition.reload
        cached_definition.force_option_config_parse
      end
    end
  end

  # ---------------------------------------------------------------------------
  # AC4: Only dependent definitions are refreshed (lightweight path)
  # ---------------------------------------------------------------------------
  describe 'AC4: only dependent definitions are refreshed (lightweight path)' do
    it 'refreshes only definitions with @library references' do
      original_time = Admin::ConfigLibrary.where(id: @config_library.id).pick(:updated_at)
      original_options = Admin::ConfigLibrary.where(id: @config_library.id).pick(:options)
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(
        options: @library_v2_options, updated_at: original_time + 60.seconds
      )
      Dynamic::DefinitionCacheVersion.rotate!

      refreshed_table_names = []
      allow_any_instance_of(DynamicModel).to receive(:force_option_config_parse).and_wrap_original do |original_method, **kwargs|
        refreshed_table_names << original_method.receiver.table_name
        original_method.call(**kwargs)
      end

      DynamicModel.refresh_outdated

      expect(refreshed_table_names).to include(@dm_table_name)
      expect(refreshed_table_names).not_to include(@dm_no_lib_table)
    ensure
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(
        options: original_options, updated_at: original_time
      )
      Dynamic::DefinitionCacheVersion.rotate!
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

      # Simulate a cross-server update: bump the definition's updated_at via SQL
      dm_original_time = DynamicModel.where(id: existing_dm.id).pick(:updated_at)
      future_time = dm_original_time + 1.second
      DynamicModel.where(id: existing_dm.id).update_all(updated_at: future_time)
      Dynamic::DefinitionCacheVersion.rotate!
      DynamicModel.reset_active_model_configurations!

      # A fresh worker check must observe this exact timestamp change before refreshing.
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
      Dynamic::DefinitionCacheVersion.rotate!
      DynamicModel.reset_active_model_configurations!
    end
  end

  # ---------------------------------------------------------------------------
  # AC9: Standard versioned definitions trigger full regen via touch
  # ---------------------------------------------------------------------------
  describe 'AC9: definition timestamp change triggers full regen (not lightweight)' do
    it 'triggers full regeneration when both definition and config library timestamps change' do
      # Get a definition that IS in active_model_configurations (test definitions
      # created in before(:all) are not associated with any app type, so they
      # don't appear in active_model_configurations.
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
      Dynamic::DefinitionCacheVersion.rotate!
      DynamicModel.reset_active_model_configurations!

      # The exact status comparison prioritizes the definition change over the library update.
      expect(DynamicModel.definition_refresh_status).to eq(:definitions_changed)
      log_output = StringIO.new
      test_logger = Logger.new(log_output)
      original_logger = Rails.logger
      Rails.logger = test_logger

      DynamicModel.refresh_outdated

      Rails.logger = original_logger

      # The log should show "Refreshing outdated" (full path)
      expect(log_output.string).to include('Refreshing outdated')
      expect(log_output.string).not_to include('Refreshing config library dependents')

      # Restore timestamps
      DynamicModel.where(id: existing_dm.id).update_all(updated_at: dm_original_time)
      Admin::ConfigLibrary.where(id: @config_library.id).update_all(updated_at: cl_original_time)
      Dynamic::DefinitionCacheVersion.rotate!
      DynamicModel.reset_active_model_configurations!
    end
  end

  # ---------------------------------------------------------------------------
  # AC5 & AC8: unchanged-token status checks are query-free
  # ---------------------------------------------------------------------------
  describe 'AC5 & AC8: verified token fast path' do
    it 'records the latest YAML library timestamp when marking the worker current' do
      latest_cl_time = Admin::ConfigLibrary.where(format: 'yaml').maximum(:updated_at)

      expect(DynamicModel.mark_definition_refresh_current!).to be true
      expect(DynamicModel.instance_variable_get(:@verified_config_library_updated_at)).to eq(latest_cl_time)
    end

    it 'does not query persisted definitions when the token is unchanged' do
      query_count = 0
      counter = lambda { |_name, _start, _finish, _id, payload|
        query_count += 1 unless payload[:name] == 'SCHEMA' || payload[:sql]&.include?('SHOW')
      }

      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
        expect(DynamicModel.definition_refresh_status).to eq(:current)
      end

      expect(query_count).to eq(0)
    end
  end

end
