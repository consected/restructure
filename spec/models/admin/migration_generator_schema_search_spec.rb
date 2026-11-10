# frozen_string_literal: true

# Regression coverage for blank schema names in generated schema-migration files.
# This guards against creating invalid CREATE SCHEMA migrations when no schema name
# is available for an app or test environment.
require 'rails_helper'

RSpec.describe 'Admin::MigrationGenerator schema search path handling', type: :model do
  include ModelSupport

  # Test database schema_search_path is: ml_app,ipa_ops,testmybrain,persnet,bulk_msg,ref_data,test,redcap_test,dynamic_test
  # We'll use test, redcap_test, and dynamic_test for testing purposes as they appear in different positions

  before :all do
    create_admin
    @created_tables = []
    @test_table_name = 'schema_search_test_table'
  end

  after :all do
    # Clean up all test tables
    @created_tables.each do |table_info|
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table_info[:schema]}.#{table_info[:table]} CASCADE")
    rescue StandardError => e
      Rails.logger.warn "Failed to drop test table #{table_info[:schema]}.#{table_info[:table]}: #{e}"
    end

    # Reset the memoized tables and views
    Admin::MigrationGenerator.tables_and_views_reset!
  end

  before :each do
    create_admin unless @admin
    # Reset the memoized tables and views before each test
    Admin::MigrationGenerator.tables_and_views_reset!
  end

  describe 'table_schema_hash with duplicate table names in multiple schemas' do
    context 'when table exists in multiple schemas' do
      before :all do
        # Create the same table in three different schemas
        # These schemas are ordered in the test database search path as: test, redcap_test, dynamic_test

        %w[test redcap_test dynamic_test].each do |schema|
          table_full_name = "#{schema}.#{@test_table_name}"

          # Drop if exists
          ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table_full_name} CASCADE")

          # Create table
          ActiveRecord::Base.connection.execute <<~SQL
            CREATE TABLE #{table_full_name} (
              id bigserial PRIMARY KEY,
              name varchar,
              created_at timestamp NOT NULL DEFAULT NOW(),
              updated_at timestamp NOT NULL DEFAULT NOW()
            )
          SQL

          @created_tables << { schema: schema, table: @test_table_name }
        end

        # Reset cache to pick up new tables
        Admin::MigrationGenerator.tables_and_views_reset!
      end

      it 'returns the first schema in the search path when table exists in multiple schemas' do
        hash = Admin::MigrationGenerator.table_schema_hash

        # The table should be associated with 'test' schema since it appears first in the search path
        expect(hash[@test_table_name]).to eq('test')
      end

      it 'table_or_view_exists_in_schema? correctly identifies the table in each schema' do
        # Verify the table exists in all three schemas
        expect(Admin::MigrationGenerator.table_or_view_exists_in_schema?(@test_table_name, 'test')).to be_truthy
        expect(Admin::MigrationGenerator.table_or_view_exists_in_schema?(@test_table_name, 'redcap_test')).to be_truthy
        expect(Admin::MigrationGenerator.table_or_view_exists_in_schema?(@test_table_name, 'dynamic_test')).to be_truthy
      end

      it 'respects search path order even when schemas are alphabetically different' do
        # The search path for test is: ml_app,ipa_ops,testmybrain,persnet,bulk_msg,ref_data,test,redcap_test,dynamic_test
        # Alphabetically: dynamic_test < redcap_test < test
        # But search path order is: test < redcap_test < dynamic_test
        # So the hash should return 'test' (earliest in search path), not 'dynamic_test' (earliest alphabetically)

        hash = Admin::MigrationGenerator.table_schema_hash
        expect(hash[@test_table_name]).to eq('test')
        expect(hash[@test_table_name]).not_to eq('dynamic_test')
        expect(hash[@test_table_name]).not_to eq('redcap_test')
      end
    end

    context 'when table exists only in later search path schema' do
      before :all do
        @late_schema_table = 'late_schema_test_table'
        # Create table only in dynamic_test schema (last in our test trio)
        table_full_name = "dynamic_test.#{@late_schema_table}"

        ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table_full_name} CASCADE")

        ActiveRecord::Base.connection.execute <<~SQL
          CREATE TABLE #{table_full_name} (
            id bigserial PRIMARY KEY,
            data varchar,
            created_at timestamp NOT NULL DEFAULT NOW(),
            updated_at timestamp NOT NULL DEFAULT NOW()
          )
        SQL

        @created_tables << { schema: 'dynamic_test', table: @late_schema_table }
        Admin::MigrationGenerator.tables_and_views_reset!
      end

      it 'returns the only schema where the table exists' do
        hash = Admin::MigrationGenerator.table_schema_hash
        expect(hash[@late_schema_table]).to eq('dynamic_test')
      end
    end

    context 'when table exists in first and last schema but not middle' do
      before :all do
        @gap_table = 'gap_test_table'
        # Create table in test and dynamic_test, but NOT in redcap_test

        %w[test dynamic_test].each do |schema|
          table_full_name = "#{schema}.#{@gap_table}"

          ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table_full_name} CASCADE")

          ActiveRecord::Base.connection.execute <<~SQL
            CREATE TABLE #{table_full_name} (
              id bigserial PRIMARY KEY,
              value varchar,
              created_at timestamp NOT NULL DEFAULT NOW(),
              updated_at timestamp NOT NULL DEFAULT NOW()
            )
          SQL

          @created_tables << { schema: schema, table: @gap_table }
        end

        Admin::MigrationGenerator.tables_and_views_reset!
      end

      it 'returns the first schema in search path where table exists' do
        hash = Admin::MigrationGenerator.table_schema_hash
        # Should return 'test' since it's earlier in the search path than 'dynamic_test'
        expect(hash[@gap_table]).to eq('test')
      end
    end
  end

  describe 'schema generation' do
    it 'skips migration creation when the schema name is blank' do
      migration_generator = Admin::MigrationGenerator.new('')
      allow(Rails.logger).to receive(:warn)

      expect(migration_generator).not_to receive(:write_db_migration)

      expect { migration_generator.add_schema }.not_to raise_error
      expect(Rails.logger).to have_received(:warn).with(/schema.*blank/i)
    end
  end

  describe 'dynamic model schema_name_in_db with duplicate tables' do
    before :all do
      create_admin
      @dm_test_table = 'dm_schema_test_table'

      # Create the same table in multiple schemas
      %w[test redcap_test dynamic_test].each do |schema|
        table_full_name = "#{schema}.#{@dm_test_table}"

        ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table_full_name} CASCADE")

        ActiveRecord::Base.connection.execute <<~SQL
          CREATE TABLE #{table_full_name} (
            id bigserial PRIMARY KEY,
            master_id bigint,
            test_field varchar,
            created_at timestamp NOT NULL DEFAULT NOW(),
            updated_at timestamp NOT NULL DEFAULT NOW()
          )
        SQL

        @created_tables << { schema: schema, table: @dm_test_table }
      end

      Admin::MigrationGenerator.tables_and_views_reset!
    end

    it 'dynamic model schema_name_in_db returns first schema in search path' do
      # Create a dynamic model pointing to the test schema
      dm = DynamicModel.create!(
        current_admin: @admin,
        name: 'test schema search',
        table_name: @dm_test_table,
        schema_name: 'test',
        category: :test
      )

      expect(dm.persisted?).to be_truthy

      # schema_name_in_db should return 'test' since it's first in the search path
      expect(dm.schema_name_in_db).to eq('test')

      # Clean up
      dm.current_admin = @admin
      dm.disable!
    end

    it 'dynamic model shows warning when schema_name does not match schema_name_in_db' do
      # Create a dynamic model with schema_name pointing to dynamic_test
      # but the actual table used will be from 'test' schema (first in search path)
      dm = DynamicModel.create!(
        current_admin: @admin,
        name: 'test schema mismatch',
        table_name: @dm_test_table,
        schema_name: 'dynamic_test',
        category: :test
      )

      expect(dm.persisted?).to be_truthy

      # schema_name is what we set
      expect(dm.schema_name).to eq('dynamic_test')

      # schema_name_in_db should return 'test' (first in search path)
      expect(dm.schema_name_in_db).to eq('test')

      # They should not match, indicating a warning condition
      expect(dm.schema_name).not_to eq(dm.schema_name_in_db)

      # Clean up
      dm.current_admin = @admin
      dm.disable!
    end

    it 'dynamic model with correct schema_name matches schema_name_in_db' do
      # Create a dynamic model with schema_name correctly set to 'test'
      dm = DynamicModel.create!(
        current_admin: @admin,
        name: 'test schema correct',
        table_name: @dm_test_table,
        schema_name: 'test',
        category: :test
      )

      expect(dm.persisted?).to be_truthy

      # Both should match
      expect(dm.schema_name).to eq('test')
      expect(dm.schema_name_in_db).to eq('test')
      expect(dm.schema_name).to eq(dm.schema_name_in_db)

      # Clean up
      dm.current_admin = @admin
      dm.disable!
    end
  end
end
