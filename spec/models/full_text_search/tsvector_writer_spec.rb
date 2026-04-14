# frozen_string_literal: true

require 'rails_helper'

# Tests for FullTextSearch::TsvectorWriter (issue #74).
# Verifies the shared utility module that writes tsvector data to database tables:
# - write_tsvector inserts tsvector data using parameterized SQL (Mode 1: separate target table)
# - write_tsvector performs upsert (update if FK row already exists)
# - update_tsvector updates a tsvector column on the record's own table (Mode 2: same table)
# - build_text_content concatenates field values with nil-safe handling
# - build_text_content supports extra_content parameter for file text
# - Table and column names are properly quoted to prevent SQL injection
RSpec.describe 'FullTextSearch::TsvectorWriter', type: :model do
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
    @source_table_name = 'test_fts_sources'
    @target_table_name = 'test_fts_targets'
    @same_table_name = 'test_fts_same_tables'
    @full_target_table = "#{@schema_name}.#{@target_table_name}"
    @full_source_table = "#{@schema_name}.#{@source_table_name}"
    @full_same_table = "#{@schema_name}.#{@same_table_name}"

    @conn = ActiveRecord::Base.connection

    # Create the schema if it doesn't exist
    @conn.execute("CREATE SCHEMA IF NOT EXISTS #{@schema_name}")

    # Clean up any existing test tables
    [@source_table_name, @same_table_name].each do |tname|
      DynamicModel.active.where(table_name: tname).each { |dm| dm.disable!(@admin) }

      const_name = tname.singularize.camelize.to_sym
      begin
        DynamicModel.send(:remove_const, const_name) if DynamicModel.const_defined?(const_name, false)
      rescue NameError
        # Constant may have been removed by another parallel test
      end

      history_name = "#{tname.singularize}_history"
      @conn.execute("DROP TABLE IF EXISTS #{@schema_name}.#{history_name} CASCADE")
      @conn.execute("DROP TABLE IF EXISTS #{@schema_name}.#{tname} CASCADE")
    end
    @conn.execute("DROP TABLE IF EXISTS #{@full_target_table} CASCADE")

    # Create a source dynamic model with fields to index
    @source_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test FTS Source',
      table_name: @source_table_name,
      schema_name: @schema_name,
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      field_list: 'title description notes',
      options: <<~YAML
        _db_columns:
          title:
            type: string
          description:
            type: string
          notes:
            type: string
      YAML
    )

    @source_dm.update_tracker_events
    setup_access :dynamic_model__test_fts_sources, resource_type: :table, access: :create

    # Create a target table for tsvector storage with raw SQL
    # This simulates the FTS target table that TsvectorWriter writes to
    @conn.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{@full_target_table} (
        id bigserial PRIMARY KEY,
        master_id bigint,
        source_id bigint NOT NULL,
        search_content tsvector,
        created_at timestamp NOT NULL DEFAULT now(),
        updated_at timestamp NOT NULL DEFAULT now(),
        UNIQUE (source_id)
      )
    SQL

    # Create a GIN index on the tsvector column
    @conn.execute(<<~SQL)
      CREATE INDEX IF NOT EXISTS idx_test_fts_target_search_content
      ON #{@full_target_table}
      USING gin (search_content)
    SQL

    # ---- Same-table dynamic model for Mode 2 (has its own tsvector column) ----
    @same_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test FTS Same Table',
      table_name: @same_table_name,
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
      YAML
    )
    @same_dm.update_tracker_events
    setup_access :dynamic_model__test_fts_same_tables, resource_type: :table, access: :create
  end

  after :all do
    @source_dm&.disable!(@admin)
    @same_dm&.disable!(@admin)
    @conn&.execute("DROP TABLE IF EXISTS #{@full_target_table} CASCADE")
    change_setting('AllowDynamicMigrations', @original_allow_migrations)
  end

  before :each do
    @master = Master.create! current_user: @user
    @master.current_user = @user

    # Clean target table rows between tests
    @conn.execute("DELETE FROM #{@full_target_table}")
  end

  describe '.write_tsvector' do
    it 'writes a tsvector value to the target table' do
      source_record = @master.dynamic_model__test_fts_sources.create!(
        current_user: @user,
        title: 'test document',
        description: 'a sample description',
        notes: 'some notes here'
      )

      FullTextSearch::TsvectorWriter.write_tsvector(
        target_table: @full_target_table,
        target_field: 'search_content',
        text_content: 'test document a sample description some notes here',
        fk_column: 'source_id',
        fk_value: source_record.id,
        master_id: @master.id
      )

      result = @conn.execute(<<~SQL)
        SELECT search_content::text, master_id, source_id
        FROM #{@full_target_table}
        WHERE source_id = #{source_record.id}
      SQL

      row = result.first
      expect(row).not_to be_nil
      expect(row['search_content']).to be_present
      expect(row['master_id']).to eq(@master.id)
      expect(row['source_id']).to eq(source_record.id)
    end

    it 'performs upsert - updates existing row when FK matches' do
      source_record = @master.dynamic_model__test_fts_sources.create!(
        current_user: @user,
        title: 'original title',
        description: 'original description',
        notes: 'original notes'
      )

      # First write
      FullTextSearch::TsvectorWriter.write_tsvector(
        target_table: @full_target_table,
        target_field: 'search_content',
        text_content: 'original title original description original notes',
        fk_column: 'source_id',
        fk_value: source_record.id,
        master_id: @master.id
      )

      # Second write with updated content - should update, not insert
      FullTextSearch::TsvectorWriter.write_tsvector(
        target_table: @full_target_table,
        target_field: 'search_content',
        text_content: 'updated title with new keywords and findings',
        fk_column: 'source_id',
        fk_value: source_record.id,
        master_id: @master.id
      )

      # Should only have one row
      count_result = @conn.execute(<<~SQL)
        SELECT count(*) AS cnt FROM #{@full_target_table} WHERE source_id = #{source_record.id}
      SQL
      expect(count_result.first['cnt']).to eq(1)

      # Content should be the updated version
      search_result = @conn.execute(<<~SQL)
        SELECT id FROM #{@full_target_table}
        WHERE source_id = #{source_record.id}
        AND search_content @@ to_tsquery('english', 'updated & keywords')
      SQL
      expect(search_result.count).to eq(1)
    end

    it 'writes data that is queryable with full text search' do
      source_record = @master.dynamic_model__test_fts_sources.create!(
        current_user: @user,
        title: 'cardiovascular research',
        description: 'a study on heart disease prevention',
        notes: 'preliminary findings are promising'
      )

      FullTextSearch::TsvectorWriter.write_tsvector(
        target_table: @full_target_table,
        target_field: 'search_content',
        text_content: 'cardiovascular research a study on heart disease prevention preliminary findings are promising',
        fk_column: 'source_id',
        fk_value: source_record.id,
        master_id: @master.id
      )

      # Should match relevant query
      matching = @conn.execute(<<~SQL)
        SELECT source_id FROM #{@full_target_table}
        WHERE search_content @@ to_tsquery('english', 'cardiovascular & research')
      SQL
      expect(matching.map { |r| r['source_id'] }).to include(source_record.id)

      # Should not match unrelated query
      non_matching = @conn.execute(<<~SQL)
        SELECT source_id FROM #{@full_target_table}
        WHERE search_content @@ to_tsquery('english', 'banana & smoothie')
      SQL
      expect(non_matching.map { |r| r['source_id'] }).not_to include(source_record.id)
    end

    it 'uses the specified ts_config for separate-table writes' do
      source_record = @master.dynamic_model__test_fts_sources.create!(
        current_user: @user,
        title: 'running quickly',
        description: '',
        notes: ''
      )

      FullTextSearch::TsvectorWriter.write_tsvector(
        target_table: @full_target_table,
        target_field: 'search_content',
        text_content: 'running quickly',
        fk_column: 'source_id',
        fk_value: source_record.id,
        master_id: @master.id,
        ts_config: 'simple'
      )

      simple_match = @conn.execute(<<~SQL)
        SELECT id FROM #{@full_target_table}
        WHERE source_id = #{source_record.id}
        AND search_content @@ to_tsquery('simple', 'running')
      SQL
      expect(simple_match.count).to eq(1)

      english_stem_match = @conn.execute(<<~SQL)
        SELECT id FROM #{@full_target_table}
        WHERE source_id = #{source_record.id}
        AND search_content @@ to_tsquery('english', 'run')
      SQL
      expect(english_stem_match.count).to eq(0)
    end
  end

  describe '.build_text_content' do
    it 'concatenates field values from an item' do
      source_record = @master.dynamic_model__test_fts_sources.create!(
        current_user: @user,
        title: 'my title',
        description: 'my description',
        notes: 'my notes'
      )

      text = FullTextSearch::TsvectorWriter.build_text_content(
        item: source_record,
        with_fields: %i[title description notes]
      )

      expect(text).to include('my title')
      expect(text).to include('my description')
      expect(text).to include('my notes')
    end

    it 'skips nil and blank field values' do
      source_record = @master.dynamic_model__test_fts_sources.create!(
        current_user: @user,
        title: 'only title set',
        description: '',
        notes: nil
      )

      text = FullTextSearch::TsvectorWriter.build_text_content(
        item: source_record,
        with_fields: %i[title description notes]
      )

      expect(text).to include('only title set')
      # Should not contain empty separators or garbage from nil/blank values
      expect(text).not_to match(/\s{2,}/)
    end

    it 'appends extra_content when provided' do
      source_record = @master.dynamic_model__test_fts_sources.create!(
        current_user: @user,
        title: 'document title',
        description: 'document description',
        notes: ''
      )

      text = FullTextSearch::TsvectorWriter.build_text_content(
        item: source_record,
        with_fields: %i[title description],
        extra_content: 'extracted file text content from a PDF attachment'
      )

      expect(text).to include('document title')
      expect(text).to include('document description')
      expect(text).to include('extracted file text content from a PDF attachment')
    end

    it 'handles extra_content when all fields are blank' do
      source_record = @master.dynamic_model__test_fts_sources.create!(
        current_user: @user,
        title: '',
        description: nil,
        notes: nil
      )

      text = FullTextSearch::TsvectorWriter.build_text_content(
        item: source_record,
        with_fields: %i[title description notes],
        extra_content: 'only file content available'
      )

      expect(text).to include('only file content available')
      expect(text.strip).not_to be_empty
    end
  end

  describe '.update_tsvector' do
    it 'updates a tsvector column on the record own table' do
      record = @master.dynamic_model__test_fts_same_tables.create!(
        current_user: @user,
        title: 'neuroscience developments',
        body: 'recent advances in brain imaging technology'
      )

      FullTextSearch::TsvectorWriter.update_tsvector(
        table_name: @full_same_table,
        target_field: 'search_index',
        text_content: 'neuroscience developments recent advances in brain imaging technology',
        record_id: record.id
      )

      result = @conn.execute(<<~SQL)
        SELECT search_index::text
        FROM #{@full_same_table}
        WHERE id = #{record.id}
      SQL

      row = result.first
      expect(row).not_to be_nil
      expect(row['search_index']).to be_present
    end

    it 'data is queryable with full text search' do
      record = @master.dynamic_model__test_fts_same_tables.create!(
        current_user: @user,
        title: 'cardiovascular research',
        body: 'a study on heart disease prevention'
      )

      FullTextSearch::TsvectorWriter.update_tsvector(
        table_name: @full_same_table,
        target_field: 'search_index',
        text_content: 'cardiovascular research a study on heart disease prevention',
        record_id: record.id
      )

      matching = @conn.execute(<<~SQL)
        SELECT id FROM #{@full_same_table}
        WHERE search_index @@ to_tsquery('english', 'cardiovascular & research')
      SQL
      expect(matching.map { |r| r['id'] }).to include(record.id)

      non_matching = @conn.execute(<<~SQL)
        SELECT id FROM #{@full_same_table}
        WHERE search_index @@ to_tsquery('english', 'banana & smoothie')
      SQL
      expect(non_matching.map { |r| r['id'] }).not_to include(record.id)
    end

    it 'uses the specified ts_config' do
      record = @master.dynamic_model__test_fts_same_tables.create!(
        current_user: @user,
        title: 'running jumping',
        body: 'the dogs are running and jumping'
      )

      FullTextSearch::TsvectorWriter.update_tsvector(
        table_name: @full_same_table,
        target_field: 'search_index',
        text_content: 'running jumping the dogs are running and jumping',
        record_id: record.id,
        ts_config: 'simple'
      )

      # With 'simple' config, words are not stemmed — exact match on 'running' should work
      matching = @conn.execute(<<~SQL)
        SELECT id FROM #{@full_same_table}
        WHERE search_index @@ to_tsquery('simple', 'running')
      SQL
      expect(matching.map { |r| r['id'] }).to include(record.id)
    end

    it 'rejects invalid table_name' do
      expect do
        FullTextSearch::TsvectorWriter.update_tsvector(
          table_name: 'dynamic_test.test_fts_same_table; DROP TABLE users; --',
          target_field: 'search_index',
          text_content: 'test content',
          record_id: 1
        )
      end.to raise_error(ArgumentError)
    end

    it 'rejects invalid target_field' do
      expect do
        FullTextSearch::TsvectorWriter.update_tsvector(
          table_name: @full_same_table,
          target_field: 'search_index; DROP TABLE users; --',
          text_content: 'test content',
          record_id: 1
        )
      end.to raise_error(ArgumentError)
    end
  end

  describe 'SQL injection prevention' do
    it 'safely handles table and column names' do
      # Attempting to use a malicious table name should raise an ArgumentError
      # (not NameError from missing constant — the module must exist to validate input)
      expect do
        FullTextSearch::TsvectorWriter.write_tsvector(
          target_table: "#{@schema_name}.test_fts_targets; DROP TABLE users; --",
          target_field: 'search_content',
          text_content: 'test content',
          fk_column: 'source_id',
          fk_value: 1
        )
      end.to raise_error(ArgumentError)
    end

    it 'safely handles malicious text content without SQL injection' do
      source_record = @master.dynamic_model__test_fts_sources.create!(
        current_user: @user,
        title: 'safe title',
        description: 'safe description',
        notes: ''
      )

      # Malicious text content should be parameterized and safe
      expect do
        FullTextSearch::TsvectorWriter.write_tsvector(
          target_table: @full_target_table,
          target_field: 'search_content',
          text_content: "'; DROP TABLE users; --",
          fk_column: 'source_id',
          fk_value: source_record.id,
          master_id: @master.id
        )
      end.not_to raise_error

      # Verify the target table still exists and data was written
      result = @conn.execute("SELECT count(*) AS cnt FROM #{@full_target_table}")
      expect(result.first['cnt']).to be >= 1
    end
  end
end
