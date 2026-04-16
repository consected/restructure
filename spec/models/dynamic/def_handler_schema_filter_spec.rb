# frozen_string_literal: true

require 'rails_helper'

# Tests for GitHub issue #525: Limiting dynamic definition loading during server initialization
#
# When apps are not enabled on a specific server, dynamic definitions with schema_name values
# not in the current database search path should be filtered out during active_model_configurations.
# This prevents attempting to load definitions whose underlying tables are inaccessible,
# avoiding unnecessary "Failed to enable" warnings and slow initialization.
#
# The filtering happens at the active_model_configurations level so definitions with
# inaccessible tables are never passed to define_models or enable_active_configurations.
#
# Key behaviors tested:
# 1. Definitions with explicit schema_name not in search path are filtered out
# 2. Definitions with explicit schema_name in search path are included
# 3. Definitions with nil/blank schema_name whose table exists are included
# 4. Definitions with nil/blank schema_name whose table does NOT exist are filtered out
# 5. ActivityLog definitions with schema_name not in search path are filtered out
RSpec.describe 'Dynamic definition schema filtering - issue #525', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport

  before :all do
    seed_database
    create_admin
    create_user
    @user.app_type ||= Admin::AppType.active.first
    @user.save!
    @app_type = @user.app_type

    @valid_search_paths = Admin::MigrationGenerator.current_search_paths
  end

  describe 'DynamicModel.active_model_configurations schema filtering' do
    before :each do
      DynamicModel.reset_active_model_configurations!
    end

    after :each do
      DynamicModel.reset_active_model_configurations!
    end

    it 'filters out definitions where schema_name is not in current_search_paths' do
      # Simulate a definition created in another environment with a schema
      # not available on the current server (e.g. limited FPHS_POSTGRESQL_SCHEMA).
      # Use update_columns to bypass schema validation, simulating a
      # pre-existing definition in the DB from a different environment.
      invalid_schema = 'non_existent_schema_xyz'
      expect(@valid_search_paths).not_to include(invalid_schema)

      dm = DynamicModel.active.first
      original_schema = dm.schema_name
      dm.update_columns(schema_name: invalid_schema)

      begin
        DynamicModel.reset_active_model_configurations!
        configs = DynamicModel.active_model_configurations(force_update: true)
        config_ids = configs.map(&:id)

        expect(config_ids).not_to include(dm.id),
          "Expected DynamicModel with schema_name '#{invalid_schema}' to be filtered out " \
          "of active_model_configurations, but it was included. " \
          "Current search paths: #{@valid_search_paths.inspect}"
      ensure
        dm.update_columns(schema_name: original_schema)
      end
    end

    it 'includes definitions where schema_name IS in current_search_paths' do
      valid_schema = @valid_search_paths.find(&:present?)
      expect(valid_schema).to be_present

      dm = DynamicModel.active.find { |d| d.schema_name == valid_schema }
      dm ||= DynamicModel.active.first
      expect(dm).to be_present

      DynamicModel.reset_active_model_configurations!
      configs = DynamicModel.active_model_configurations(force_update: true)
      config_ids = configs.map(&:id)

      expect(config_ids).to include(dm.id),
        "Expected DynamicModel with schema_name '#{dm.schema_name}' to be included " \
        "in active_model_configurations since it is in the search path"
    end

    it 'filters out definitions when current_search_paths is limited and does not include their schema' do
      dm = DynamicModel.active.find(&:schema_name)
      skip 'No DynamicModel with schema_name found in test DB' unless dm

      original_schema = dm.schema_name
      limited_paths = @valid_search_paths.reject { |s| s == original_schema }

      allow(Admin::MigrationGenerator).to receive(:current_search_paths).and_return(limited_paths)

      begin
        DynamicModel.reset_active_model_configurations!
        configs = DynamicModel.active_model_configurations(force_update: true)
        config_ids = configs.map(&:id)

        expect(config_ids).not_to include(dm.id),
          "Expected DynamicModel with schema_name '#{original_schema}' to be filtered out " \
          "when search_paths are limited to #{limited_paths.inspect}"
      ensure
        allow(Admin::MigrationGenerator).to receive(:current_search_paths).and_call_original
        DynamicModel.reset_active_model_configurations!
      end
    end
  end

  describe 'nil/blank schema_name filtering by table accessibility' do
    # This tests the core issue #525 scenario: definitions with nil/blank schema_name
    # whose tables are in schemas not accessible on this server should be filtered out
    # of active_model_configurations entirely, so they are never loaded or warned about.

    before :each do
      DynamicModel.reset_active_model_configurations!
      Admin::MigrationGenerator.instance_variable_set(:@tables_and_views, nil)
    end

    after :each do
      DynamicModel.reset_active_model_configurations!
      Admin::MigrationGenerator.instance_variable_set(:@tables_and_views, nil)
    end

    it 'includes nil-schema definitions whose table exists in accessible schemas' do
      dm = DynamicModel.active.first
      expect(dm).to be_present

      # Set schema_name to nil and verify the definition is included
      # (since its table actually exists in the accessible schemas)
      original_schema = dm.schema_name
      dm.update_columns(schema_name: nil)

      begin
        DynamicModel.reset_active_model_configurations!
        configs = DynamicModel.active_model_configurations(force_update: true)
        config_ids = configs.map(&:id)

        expect(config_ids).to include(dm.id),
          "Expected DynamicModel with nil schema_name to be included " \
          "when its table '#{dm.table_name}' exists in accessible schemas"
      ensure
        dm.update_columns(schema_name: original_schema)
      end
    end

    it 'filters out nil-schema definitions whose table does NOT exist in accessible schemas' do
      # Simulate a definition whose table is in a schema inaccessible on this server.
      # The definition has nil schema_name (common for definitions created elsewhere),
      # and its table_name does not appear in the accessible tables_and_views.
      dm = DynamicModel.active.first
      expect(dm).to be_present

      original_schema = dm.schema_name
      original_table_name = dm.table_name

      # Set nil schema and a table name that doesn't exist in any accessible schema
      dm.update_columns(schema_name: nil, table_name: 'nonexistent_table_xyz789')

      begin
        DynamicModel.reset_active_model_configurations!
        Admin::MigrationGenerator.instance_variable_set(:@tables_and_views, nil)
        configs = DynamicModel.active_model_configurations(force_update: true)
        config_ids = configs.map(&:id)

        expect(config_ids).not_to include(dm.id),
          "Expected DynamicModel with nil schema_name and non-existent table " \
          "'nonexistent_table_xyz789' to be filtered out of active_model_configurations. " \
          "Definitions whose tables are not accessible should not be loaded at all."
      ensure
        dm.update_columns(schema_name: original_schema, table_name: original_table_name)
      end
    end

    it 'filters out blank-schema definitions whose table does NOT exist in accessible schemas' do
      dm = DynamicModel.active.first
      expect(dm).to be_present

      original_schema = dm.schema_name
      original_table_name = dm.table_name

      # Set blank (empty string) schema and a non-existent table name
      dm.update_columns(schema_name: '', table_name: 'nonexistent_table_abc123')

      begin
        DynamicModel.reset_active_model_configurations!
        Admin::MigrationGenerator.instance_variable_set(:@tables_and_views, nil)
        configs = DynamicModel.active_model_configurations(force_update: true)
        config_ids = configs.map(&:id)

        expect(config_ids).not_to include(dm.id),
          "Expected DynamicModel with blank schema_name and non-existent table " \
          "'nonexistent_table_abc123' to be filtered out of active_model_configurations."
      ensure
        dm.update_columns(schema_name: original_schema, table_name: original_table_name)
      end
    end
  end

  describe 'ActivityLog.active_model_configurations schema filtering' do
    before :each do
      ActivityLog.reset_active_model_configurations!
    end

    after :each do
      ActivityLog.reset_active_model_configurations!
    end

    it 'filters out definitions when schema_name is not in the search path' do
      al = ActivityLog.active.find(&:schema_name)
      skip 'No ActivityLog with schema_name found in test DB' unless al

      original_schema = al.schema_name
      limited_paths = @valid_search_paths.reject { |s| s == original_schema }
      skip 'Cannot exclude all paths, test not viable' if limited_paths.include?(original_schema)

      allow(Admin::MigrationGenerator).to receive(:current_search_paths).and_return(limited_paths)

      begin
        ActivityLog.reset_active_model_configurations!
        configs = ActivityLog.active_model_configurations(force_update: true)
        config_ids = configs.map(&:id)

        expect(config_ids).not_to include(al.id),
          "Expected ActivityLog with schema_name '#{original_schema}' to be filtered out " \
          "when search_paths do not include it: #{limited_paths.inspect}"
      ensure
        allow(Admin::MigrationGenerator).to receive(:current_search_paths).and_call_original
        ActivityLog.reset_active_model_configurations!
      end
    end
  end

  describe 'enable_active_configurations with schema-filtered definitions' do
    it 'still produces warn-level "Failed to enable" for definitions that pass the filter but fail to load' do
      # When a definition passes the schema filter (schema and table are accessible)
      # but still fails to enable, the warn-level message should remain visible
      # since this indicates a genuine configuration error.
      dm = DynamicModel.active.first
      expect(dm).to be_present

      valid_schema = @valid_search_paths.first

      fake_dm = instance_double(
        dm.class,
        id: dm.id,
        resource_name: 'dynamic_model__broken_in_known_schema_tables',
        'ready_to_generate?': false,
        'table_or_view_ready?': false,
        schema_name: valid_schema,
        table_name: 'broken_in_known_schema_tables',
        'disabled?': false,
        class: DynamicModel
      )

      allow(DynamicModel).to receive(:active_model_configurations).and_return([fake_dm])
      allow(Admin::MigrationGenerator).to receive(:table_or_view_exists?)
        .with(DynamicModel.table_name).and_return(true)

      warn_messages = []
      allow(Rails.logger).to receive(:warn) do |msg|
        warn_messages << msg
        nil
      end

      DynamicModel.enable_active_configurations

      failed_enable_warnings = warn_messages.select { |w| w.to_s.include?('Failed to enable') }
      related_warnings = failed_enable_warnings.select { |w| w.to_s.include?('broken_in_known_schema_tables') }

      expect(related_warnings).not_to be_empty,
        "Expected warn-level 'Failed to enable' messages for a definition with " \
        "schema_name '#{valid_schema}' (in search path) that fails to load. " \
        "This is a genuine error and should remain visible in logs."
    end
  end
end
