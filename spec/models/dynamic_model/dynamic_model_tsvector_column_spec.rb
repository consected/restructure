# frozen_string_literal: true

require 'rails_helper'

# Tests for tsvector column and GIN index support in dynamic model definitions (issue #74).
# Verifies that specifying `type: tsvector` and `index: gin` in _db_columns configuration
# causes the dynamic migration system to:
# - Create a tsvector column in the database (not string)
# - Create a GIN index on that column (not B-tree)
# - Allow storing tsvector data via SQL
# - Allow querying tsvector data with full text search operators
RSpec.describe 'Dynamic Model Tsvector Column and GIN Index', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include DynamicModelSupport

  before :all do
    create_admin
    create_user

    @original_allow_migrations = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)

    @schema_name = 'dynamic_test'
    @table_name = 'test_tsvector_fields'
    @full_table_name = "#{@schema_name}.#{@table_name}"

    # Clean up any existing test tables and model
    DynamicModel.active.where(table_name: @table_name).each { |dm| dm.disable!(@admin) }
    begin
      DynamicModel.send(:remove_const, :TestTsvectorField) if DynamicModel.const_defined?(:TestTsvectorField, false)
    rescue NameError
      # Constant may have been removed by another parallel test
    end

    # Drop existing tables if they exist
    @conn = ActiveRecord::Base.connection
    history_table = "#{@table_name.singularize}_history"
    @conn.execute("DROP TABLE IF EXISTS #{@schema_name}.#{history_table} CASCADE")
    @conn.execute("DROP TABLE IF EXISTS #{@full_table_name} CASCADE")

    # Create the dynamic model definition with tsvector column and GIN index
    @dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Tsvector Fields',
      table_name: @table_name,
      schema_name: @schema_name,
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      field_list: 'title body search_index',
      options: <<~YAML
        _db_columns:
          title:
            type: string
          body:
            type: string
          search_index:
            type: tsvector
            index: gin
      YAML
    )

    @dm.update_tracker_events
    setup_access :dynamic_model__test_tsvector_fields
  end

  after :all do
    @dm&.disable!(@admin)
    change_setting('AllowDynamicMigrations', @original_allow_migrations)
  end

  before :each do
    @master = Master.create! current_user: @user
    @master.current_user = @user
  end

  describe 'tsvector column creation' do
    it 'creates a tsvector column in the database' do
      @conn.schema_cache.clear!
      columns = @conn.columns(@full_table_name)

      search_col = columns.find { |c| c.name == 'search_index' }
      expect(search_col).not_to be_nil
      expect(search_col.sql_type).to eq('tsvector')
    end

    it 'creates string columns for non-tsvector fields' do
      @conn.schema_cache.clear!
      columns = @conn.columns(@full_table_name)

      title_col = columns.find { |c| c.name == 'title' }
      body_col = columns.find { |c| c.name == 'body' }

      expect(title_col).not_to be_nil
      expect(body_col).not_to be_nil
      expect(title_col.type).to eq(:string)
      expect(body_col.type).to eq(:string)
    end
  end

  describe 'GIN index creation' do
    it 'creates a GIN index on the tsvector column' do
      @conn.schema_cache.clear!
      indexes = @conn.indexes(@full_table_name)

      gin_index = indexes.find { |idx| idx.columns.include?('search_index') }
      expect(gin_index).not_to be_nil
      expect(gin_index.using).to eq(:gin)
    end

    it 'does not create GIN indexes on regular string columns' do
      @conn.schema_cache.clear!
      indexes = @conn.indexes(@full_table_name)

      title_index = indexes.find { |idx| idx.columns.include?('title') }
      body_index = indexes.find { |idx| idx.columns.include?('body') }

      # String columns without index config should have no index
      expect(title_index).to be_nil
      expect(body_index).to be_nil
    end
  end

  describe 'tsvector data storage' do
    it 'can store tsvector data via raw SQL' do
      # Insert a record first to get a master association
      record = @master.dynamic_model__test_tsvector_fields.create!(
        current_user: @user,
        title: 'test document',
        body: 'this is the body text'
      )

      # Write tsvector data directly via SQL
      @conn.execute(<<~SQL)
        UPDATE #{@full_table_name}
        SET search_index = to_tsvector('english', 'test document this is the body text')
        WHERE id = #{record.id}
      SQL

      # Verify the tsvector data was stored
      result = @conn.execute(<<~SQL)
        SELECT search_index::text FROM #{@full_table_name} WHERE id = #{record.id}
      SQL

      tsvector_value = result.first['search_index']
      expect(tsvector_value).to be_present
    end
  end

  describe 'tsvector querying' do
    it 'can query tsvector data with full text search operators' do
      record = @master.dynamic_model__test_tsvector_fields.create!(
        current_user: @user,
        title: 'important report',
        body: 'this contains critical findings about research'
      )

      @conn.execute(<<~SQL)
        UPDATE #{@full_table_name}
        SET search_index = to_tsvector('english', 'important report this contains critical findings about research')
        WHERE id = #{record.id}
      SQL

      # Query using tsquery - should find the record
      matching = @conn.execute(<<~SQL)
        SELECT id FROM #{@full_table_name}
        WHERE search_index @@ to_tsquery('english', 'critical & findings')
      SQL

      expect(matching.map { |r| r['id'] }).to include(record.id)

      # Query using tsquery - should NOT find with unrelated terms
      non_matching = @conn.execute(<<~SQL)
        SELECT id FROM #{@full_table_name}
        WHERE search_index @@ to_tsquery('english', 'banana & smoothie')
      SQL

      expect(non_matching.map { |r| r['id'] }).not_to include(record.id)
    end
  end

  describe 'db_columns configuration parsing' do
    it 'includes tsvector type in parsed db_columns' do
      @dm.option_configs(force: true)
      db_cols = @dm.db_columns

      # YAML parses unquoted values as strings
      expect(db_cols[:search_index][:type].to_s).to eq('tsvector')
    end

    it 'includes gin index in parsed db_columns' do
      @dm.option_configs(force: true)
      db_cols = @dm.db_columns

      # YAML parses unquoted values as strings
      expect(db_cols[:search_index][:index].to_s).to eq('gin')
    end
  end
end
