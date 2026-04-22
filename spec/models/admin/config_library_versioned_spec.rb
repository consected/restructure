# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/db/table_generators/dynamic_models_table"

# Tests for GitHub Issue #666:
# "Config libraries and dynamic definition versions"
#
# Config library versions should also be applied when using a dynamic definition
# that is versioned. The `_configurations.use_current_version` option config set
# for the dynamic definition referencing the config library should control whether
# the current version or the history dated version of the config library should be used.
#
# Strategy:
# 1. Create a config library with v1 content
# 2. Create a dynamic model definition that references the library
# 3. Create an instance under v1
# 4. Update the config library to v2 content
# 5. Update the dynamic model definition to trigger a new version
# 6. Verify the v1 instance still uses the v1 library content
# 7. Verify a v2 instance uses the v2 library content
# 8. Verify use_current_version overrides this behavior

RSpec.describe 'Config library versioning with dynamic definitions', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport
  include DynamicModelSupport
  include OptionsSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  before :example do
    @user0, = create_user
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_histories
  end

  def create_test_config_library(label_value:)
    @lib_category = "test_ver_cat_#{rand(1_000_000_000)}"
    @lib_name = "test_ver_lib_#{rand(1_000_000_000)}"

    Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: @lib_name,
      category: @lib_category,
      format: 'yaml',
      options: <<~YAML
        _definitions_lib:
          label_from_lib: &label_from_lib #{label_value}
      YAML
    )
  end

  def generate_dm_with_library_ref(_config_library, use_current_version: false)
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
      # ignored
    end

    ucv_config = if use_current_version
                   "_configurations:\n  use_current_version: true\n"
                 else
                   ''
                 end

    options_yaml = <<~YAML
      # @library #{@lib_category} #{@lib_name}
      #{ucv_config}default:
        label: *label_from_lib
        fields:
          - test1
          - test2
    YAML

    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'test created by',
      table_name: 'test_created_by_recs',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      field_list: 'test1 test2',
      category: :test,
      options: options_yaml
    )
    dm.current_admin = @admin
    dm.update_tracker_events

    setup_access :dynamic_model__test_created_by_recs, user: @user
    setup_access :dynamic_model__test_created_by_recs, user: @user0
    dm
  end

  describe 'Admin::ConfigLibrary.content_named_at' do
    it 'returns the current library content when no timestamp is provided' do
      create_test_config_library(label_value: 'v1_label')

      result = Admin::ConfigLibrary.content_named_at(@lib_category, @lib_name, format: :yaml, at: nil)
      expect(result).to include('v1_label')
    end

    it 'returns historical library content at a specific timestamp' do
      lib = create_test_config_library(label_value: 'v1_label')

      sleep 2
      after_v1_time = Time.current

      sleep 2
      lib.current_admin = @admin
      lib.update!(options: <<~YAML)
        _definitions_lib:
          label_from_lib: &label_from_lib v2_label
      YAML

      # Requesting content at the time after v1 but before v2 should return v1 content
      result = Admin::ConfigLibrary.content_named_at(@lib_category, @lib_name, format: :yaml, at: after_v1_time)
      expect(result).to include('v1_label')
      expect(result).not_to include('v2_label')
    end

    it 'returns current content when requested timestamp is after the latest version' do
      lib = create_test_config_library(label_value: 'v1_label')

      sleep 2
      lib.current_admin = @admin
      lib.update!(options: <<~YAML)
        _definitions_lib:
          label_from_lib: &label_from_lib v2_label
      YAML

      sleep 2
      after_v2_time = Time.current

      result = Admin::ConfigLibrary.content_named_at(@lib_category, @lib_name, format: :yaml, at: after_v2_time)
      expect(result).to include('v2_label')
    end
  end

  describe 'versioned dynamic definition uses versioned config library' do
    it 'uses the v1 library content for instances created under v1 definition' do
      # Create library v1 and dynamic model referencing it
      lib = create_test_config_library(label_value: 'v1_label')
      dmdef = generate_dm_with_library_ref(lib)

      # Verify v1 definition has the v1 label
      v1_otc = dmdef.option_type_config_for(:default)
      expect(v1_otc).not_to be_nil
      expect(v1_otc.label).to eq('v1_label')

      sleep 2

      # Create an instance under v1
      instance_v1 = @master.dynamic_model__test_created_by_recs.create!(test1: 'v1_record')

      sleep 2

      # Update the library to v2
      # refresh_dependencies callback should touch the dependent DM definition,
      # creating a new version boundary in history
      lib.current_admin = @admin
      lib.update!(options: <<~YAML)
        _definitions_lib:
          label_from_lib: &label_from_lib v2_label
      YAML

      # Reload and re-parse the definition to simulate what refresh_outdated does
      # on the next web request. This is needed because refresh_dependencies
      # parses a throwaway object, not the cached definition (see issue #1033).
      dmdef.reload
      dmdef.force_option_config_parse

      # The current definition should now use v2 library content
      current_otc = dmdef.option_type_config_for(:default)
      expect(current_otc.label).to eq('v2_label')

      # Reload the v1 instance to clear any memoization
      instance_v1 = DynamicModel::TestCreatedByRec.find(instance_v1.id)

      # The v1 instance's versioned definition should still use v1 library content
      versioned_otc = instance_v1.versioned_definition.option_type_config_for(:default)
      expect(versioned_otc).not_to be_nil
      expect(versioned_otc.label).to eq('v1_label'),
                                     "Expected v1 instance to use v1 library content with label 'v1_label', " \
                                     "but got: #{versioned_otc.label}"
    end

    it 'uses the v2 library content for instances created after v2' do
      # Create library v1 and dynamic model referencing it
      lib = create_test_config_library(label_value: 'v1_label')
      dmdef = generate_dm_with_library_ref(lib)

      sleep 2

      # Update the library to v2
      # refresh_dependencies callback should touch the dependent DM definition
      lib.current_admin = @admin
      lib.update!(options: <<~YAML)
        _definitions_lib:
          label_from_lib: &label_from_lib v2_label
      YAML

      # Reload and re-parse the definition to simulate what refresh_outdated does
      # on the next web request. This is needed because refresh_dependencies
      # parses a throwaway object, not the cached definition (see issue #1033).
      dmdef.reload
      dmdef.force_option_config_parse

      sleep 2

      # Create an instance under v2
      instance_v2 = @master.dynamic_model__test_created_by_recs.create!(test1: 'v2_record')

      # Reload to clear memoization
      instance_v2 = DynamicModel::TestCreatedByRec.find(instance_v2.id)

      # The v2 instance should use v2 library content
      versioned_otc = instance_v2.versioned_definition.option_type_config_for(:default)
      expect(versioned_otc).not_to be_nil
      expect(versioned_otc.label).to eq('v2_label'),
                                     "Expected v2 instance to use v2 library content with label 'v2_label', " \
                                     "but got: #{versioned_otc.label}"
    end
  end

  describe 'use_current_version controls library versioning' do
    it 'uses current library for all instances when use_current_version is true' do
      # Create library v1 and dynamic model with use_current_version: true
      lib = create_test_config_library(label_value: 'v1_label')

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
        # ignored
      end

      options_yaml = <<~YAML
        # @library #{@lib_category} #{@lib_name}
        _configurations:
          use_current_version: true
        default:
          label: *label_from_lib
          fields:
            - test1
            - test2
      YAML

      dmdef = DynamicModel.create!(
        current_admin: @admin,
        name: 'test created by',
        table_name: 'test_created_by_recs',
        primary_key_name: :id,
        foreign_key_name: :master_id,
        field_list: 'test1 test2',
        category: :test,
        options: options_yaml
      )
      dmdef.current_admin = @admin
      dmdef.update_tracker_events

      setup_access :dynamic_model__test_created_by_recs, user: @user
      setup_access :dynamic_model__test_created_by_recs, user: @user0

      sleep 2

      # Create an instance under v1
      instance_v1 = @master.dynamic_model__test_created_by_recs.create!(test1: 'v1_record')

      sleep 2

      # Update the library to v2
      lib.current_admin = @admin
      lib.update!(options: <<~YAML)
        _definitions_lib:
          label_from_lib: &label_from_lib v2_label
      YAML

      sleep 2

      # Force re-parse of current definition
      dmdef.force_option_config_parse

      # Reload the v1 instance to clear memoization
      instance_v1 = DynamicModel::TestCreatedByRec.find(instance_v1.id)

      # With use_current_version: true, the v1 instance should use CURRENT (v2) library
      versioned_def = instance_v1.versioned_definition
      expect(versioned_def).to eq(instance_v1.current_definition),
                               'Expected versioned_definition to return current_definition when use_current_version is true'

      versioned_otc = versioned_def.option_type_config_for(:default)
      expect(versioned_otc).not_to be_nil
      expect(versioned_otc.label).to eq('v2_label'),
                                     'Expected v1 instance to use current (v2) library when use_current_version is true, ' \
                                     "but got: #{versioned_otc.label}"
    end

    it 'does not pass version_at to include_libraries when use_current_version is true' do
      lib = create_test_config_library(label_value: 'v1_label')
      dmdef = generate_dm_with_library_ref(lib, use_current_version: true)

      sleep 2

      # Update the library to v2
      lib.current_admin = @admin
      lib.update!(options: <<~YAML)
        _definitions_lib:
          label_from_lib: &label_from_lib v2_label
      YAML

      sleep 2

      # With use_current_version, the library update should NOT have touched the definition,
      # so no new version boundary exists. Verify versioned() returns nil.
      versioned_def = dmdef.versioned(dmdef.created_at)
      expect(versioned_def).to be_nil,
                               'Expected no version boundary when use_current_version is true (touch should be skipped)'

      # Verify prepare_options_text on the current definition uses latest library (v2)
      config_text = OptionConfigs::ExtraOptions.prepare_options_text(dmdef)
      expect(config_text).to include('v2_label'),
                             'Expected prepare_options_text to use current library content when use_current_version is true, ' \
                             "Got:\n#{config_text}"
      expect(config_text).not_to include('v1_label'),
                                 'Expected versioned library content (v1_label) to NOT be used when use_current_version is true'
    end
  end
end
