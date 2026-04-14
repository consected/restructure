# frozen_string_literal: true

# Tests for SaveTriggers::FullTextSearch (issue #74)
#
# Verifies the full_text_search save trigger, which writes tsvector data
# for full-text search indexing when a dynamic model record is saved.
#
# Two modes are supported:
#
# Mode 1 - Separate target table:
#   Reads specified source fields from the item and writes tsvector data
#   to a separate target table via FullTextSearch::TsvectorWriter (upsert).
#
# Mode 2 - Same table column:
#   Reads specified source fields and updates the tsvector column on the
#   item's own table row using a direct SQL UPDATE.
#
# Covers:
# - Registration in ValidSaveTriggers
# - Resolution via trigger_class(:full_text_search)
# - Mode 1: writing tsvector to a separate target table
# - Mode 2: writing tsvector to the same table's column
# - Upsert behaviour (update, not duplicate)
# - Conditional execution with if:
# - Extra content appended to text
# - Error on missing required config (source_fields, target_column)
# - Default ts_config when omitted

require 'rails_helper'

RSpec.describe 'SaveTriggers::FullTextSearch', type: :model do
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
    @source_table_name = 'test_fts_trigger_sources'
    @target_table_name = 'test_fts_trigger_targets'
    @same_table_name = 'test_fts_trigger_sames'

    @conn = ActiveRecord::Base.connection
    @conn.execute("CREATE SCHEMA IF NOT EXISTS #{@schema_name}")

    # ---- Clean up any existing test dynamic models and tables ----

    [@source_table_name, @target_table_name, @same_table_name].each do |tname|
      DynamicModel.active.where(table_name: tname).each { |dm| dm.disable!(@admin) }

      const_name = tname.singularize.camelize.to_sym
      begin
        DynamicModel.send(:remove_const, const_name) if DynamicModel.const_defined?(const_name, false)
      rescue NameError
        # already removed
      end

      history_name = "#{tname.singularize}_history"
      @conn.execute("DROP TABLE IF EXISTS #{@schema_name}.#{history_name} CASCADE")
      @conn.execute("DROP TABLE IF EXISTS #{@schema_name}.#{tname} CASCADE")
    end

    # ---- Source dynamic model (title, body, notes) ----

    @source_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test FTS Trigger Source',
      table_name: @source_table_name,
      schema_name: @schema_name,
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      field_list: 'title body notes'
    )
    @source_dm.update_tracker_events
    setup_access :dynamic_model__test_fts_trigger_sources, resource_type: :table, access: :create

    # ---- Target table for Mode 1 (separate tsvector storage) ----

    @conn.execute(<<~SQL)
      CREATE TABLE #{@schema_name}.#{@target_table_name} (
        id bigserial PRIMARY KEY,
        master_id bigint,
        source_record_id bigint NOT NULL,
        search_vector tsvector,
        created_at timestamp NOT NULL DEFAULT now(),
        updated_at timestamp NOT NULL DEFAULT now(),
        UNIQUE (source_record_id)
      )
    SQL

    @conn.execute(<<~SQL)
      CREATE INDEX idx_fts_trigger_targets_search_vector
      ON #{@schema_name}.#{@target_table_name}
      USING gin (search_vector)
    SQL

    # ---- Same-table dynamic model for Mode 2 (has its own tsvector column) ----

    @same_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test FTS Trigger Same',
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
    setup_access :dynamic_model__test_fts_trigger_sames, resource_type: :table, access: :create
  end

  after :all do
    @source_dm&.disable!(@admin)
    @same_dm&.disable!(@admin)
    @conn&.execute("DROP TABLE IF EXISTS #{@schema_name}.#{@target_table_name} CASCADE")
    change_setting('AllowDynamicMigrations', @original_allow_migrations)
  end

  before :each do
    @master = Master.create!(current_user: @user)
    @master.current_user = @user

    # Clean target table rows between tests
    @conn.execute("DELETE FROM #{@schema_name}.#{@target_table_name}")
  end

  describe 'registration' do
    it 'is listed in ValidSaveTriggers' do
      expect(
        OptionConfigs::ExtraOptionImplementers::SaveTriggers::ValidSaveTriggers
      ).to include(:full_text_search)
    end

    it 'resolves via trigger_class' do
      klass = OptionConfigs::ExtraOptions.trigger_class(:full_text_search)
      expect(klass).to eq(SaveTriggers::FullTextSearch)
    end
  end

  describe 'Mode 1 - separate target table' do
    it 'writes tsvector data to the target table from source fields' do
      source_record = @master.dynamic_model__test_fts_trigger_sources.create!(
        current_user: @user,
        title: 'cardiovascular research',
        body: 'a study on heart disease prevention',
        notes: 'preliminary findings are promising'
      )

      config = {
        fts_1: {
          target_table: "#{@schema_name}.#{@target_table_name}",
          target_column: 'search_vector',
          target_foreign_key_column: 'source_record_id',
          source_fields: %w[title body notes],
          ts_config: 'english'
        }
      }

      trigger = SaveTriggers::FullTextSearch.new(config, source_record)
      trigger.perform

      result = @conn.execute(<<~SQL)
        SELECT search_vector::text, source_record_id
        FROM #{@schema_name}.#{@target_table_name}
        WHERE source_record_id = #{source_record.id}
      SQL

      row = result.first
      expect(row).not_to be_nil
      expect(row['search_vector']).to be_present
      expect(row['source_record_id']).to eq(source_record.id)
    end

    it 'writes data that is queryable with @@ to_tsquery()' do
      source_record = @master.dynamic_model__test_fts_trigger_sources.create!(
        current_user: @user,
        title: 'neuroplasticity experiments',
        body: 'brain adaptation under stress conditions',
        notes: 'control group showed minimal change'
      )

      config = {
        fts_1: {
          target_table: "#{@schema_name}.#{@target_table_name}",
          target_column: 'search_vector',
          target_foreign_key_column: 'source_record_id',
          source_fields: %w[title body],
          ts_config: 'english'
        }
      }

      trigger = SaveTriggers::FullTextSearch.new(config, source_record)
      trigger.perform

      search_result = @conn.execute(<<~SQL)
        SELECT id FROM #{@schema_name}.#{@target_table_name}
        WHERE source_record_id = #{source_record.id}
        AND search_vector @@ to_tsquery('english', 'neuroplasticity & brain')
      SQL

      expect(search_result.count).to eq(1)
    end

    it 'uses the specified ts_config for separate-table writes' do
      source_record = @master.dynamic_model__test_fts_trigger_sources.create!(
        current_user: @user,
        title: 'running studies',
        body: '',
        notes: ''
      )

      config = {
        fts_1: {
          target_table: "#{@schema_name}.#{@target_table_name}",
          target_column: 'search_vector',
          target_foreign_key_column: 'source_record_id',
          source_fields: %w[title],
          ts_config: 'simple'
        }
      }

      trigger = SaveTriggers::FullTextSearch.new(config, source_record)
      trigger.perform

      simple_match = @conn.execute(<<~SQL)
        SELECT id FROM #{@schema_name}.#{@target_table_name}
        WHERE source_record_id = #{source_record.id}
        AND search_vector @@ to_tsquery('simple', 'running')
      SQL
      expect(simple_match.count).to eq(1)

      english_stem_match = @conn.execute(<<~SQL)
        SELECT id FROM #{@schema_name}.#{@target_table_name}
        WHERE source_record_id = #{source_record.id}
        AND search_vector @@ to_tsquery('english', 'run')
      SQL
      expect(english_stem_match.count).to eq(0)
    end
  end

  describe 'Mode 2 - same table column' do
    it 'writes tsvector data to the same record column' do
      same_record = @master.dynamic_model__test_fts_trigger_sames.create!(
        current_user: @user,
        title: 'machine learning overview',
        body: 'neural networks and deep learning algorithms'
      )

      config = {
        fts_1: {
          target_column: 'search_index',
          source_fields: %w[title body],
          ts_config: 'english'
        }
      }

      trigger = SaveTriggers::FullTextSearch.new(config, same_record)
      trigger.perform

      # Re-read the record from the database to verify tsvector was written
      row = @conn.execute(<<~SQL).first
        SELECT search_index::text
        FROM #{@schema_name}.#{@same_table_name}
        WHERE id = #{same_record.id}
      SQL

      expect(row).not_to be_nil
      expect(row['search_index']).to be_present
    end
  end

  describe 'upsert behaviour' do
    it 'updates existing tsvector row rather than duplicating on re-save' do
      source_record = @master.dynamic_model__test_fts_trigger_sources.create!(
        current_user: @user,
        title: 'original title',
        body: 'original body',
        notes: 'original notes'
      )

      config = {
        fts_1: {
          target_table: "#{@schema_name}.#{@target_table_name}",
          target_column: 'search_vector',
          target_foreign_key_column: 'source_record_id',
          source_fields: %w[title body notes],
          ts_config: 'english'
        }
      }

      # First trigger execution
      trigger = SaveTriggers::FullTextSearch.new(config, source_record)
      trigger.perform

      # Simulate update by changing the source record and re-triggering
      source_record.update!(title: 'updated title with new keywords', current_user: @user)
      trigger2 = SaveTriggers::FullTextSearch.new(config, source_record)
      trigger2.perform

      # Should still be exactly one row for this source record
      count_result = @conn.execute(<<~SQL)
        SELECT count(*) AS cnt
        FROM #{@schema_name}.#{@target_table_name}
        WHERE source_record_id = #{source_record.id}
      SQL
      expect(count_result.first['cnt']).to eq(1)

      # And the content should reflect the updated text
      search_result = @conn.execute(<<~SQL)
        SELECT id FROM #{@schema_name}.#{@target_table_name}
        WHERE source_record_id = #{source_record.id}
        AND search_vector @@ to_tsquery('english', 'updated & keywords')
      SQL
      expect(search_result.count).to eq(1)
    end
  end

  describe 'conditional execution' do
    it 'skips trigger when if: condition evaluates false' do
      source_record = @master.dynamic_model__test_fts_trigger_sources.create!(
        current_user: @user,
        title: 'should not be indexed',
        body: 'this should be skipped',
        notes: ''
      )

      config = {
        fts_1: {
          target_table: "#{@schema_name}.#{@target_table_name}",
          target_column: 'search_vector',
          target_foreign_key_column: 'source_record_id',
          source_fields: %w[title body],
          ts_config: 'english',
          if: {
            all: {
              this: {
                notes: 'non_empty_value_that_wont_match'
              }
            }
          }
        }
      }

      trigger = SaveTriggers::FullTextSearch.new(config, source_record)
      trigger.perform

      count_result = @conn.execute(<<~SQL)
        SELECT count(*) AS cnt
        FROM #{@schema_name}.#{@target_table_name}
        WHERE source_record_id = #{source_record.id}
      SQL
      expect(count_result.first['cnt']).to eq(0)
    end
  end

  describe 'extra content' do
    it 'appends extra_content to the indexed text' do
      source_record = @master.dynamic_model__test_fts_trigger_sources.create!(
        current_user: @user,
        title: 'document title',
        body: 'document body text',
        notes: ''
      )

      config = {
        fts_1: {
          target_table: "#{@schema_name}.#{@target_table_name}",
          target_column: 'search_vector',
          target_foreign_key_column: 'source_record_id',
          source_fields: %w[title body],
          extra_content: 'supplementary keywords appended',
          ts_config: 'english'
        }
      }

      trigger = SaveTriggers::FullTextSearch.new(config, source_record)
      trigger.perform

      search_result = @conn.execute(<<~SQL)
        SELECT id FROM #{@schema_name}.#{@target_table_name}
        WHERE source_record_id = #{source_record.id}
        AND search_vector @@ to_tsquery('english', 'supplementary & keywords')
      SQL
      expect(search_result.count).to eq(1)
    end
  end

  describe 'missing required config' do
    it 'raises an error when source_fields is missing' do
      source_record = @master.dynamic_model__test_fts_trigger_sources.create!(
        current_user: @user,
        title: 'test',
        body: 'test',
        notes: ''
      )

      config = {
        fts_1: {
          target_table: "#{@schema_name}.#{@target_table_name}",
          target_column: 'search_vector',
          target_foreign_key_column: 'source_record_id',
          ts_config: 'english'
        }
      }

      trigger = SaveTriggers::FullTextSearch.new(config, source_record)
      expect { trigger.perform }.to raise_error(FphsException, /source_fields/)
    end

    it 'raises an error when target_column is missing' do
      source_record = @master.dynamic_model__test_fts_trigger_sources.create!(
        current_user: @user,
        title: 'test',
        body: 'test',
        notes: ''
      )

      config = {
        fts_1: {
          target_table: "#{@schema_name}.#{@target_table_name}",
          target_foreign_key_column: 'source_record_id',
          source_fields: %w[title body],
          ts_config: 'english'
        }
      }

      trigger = SaveTriggers::FullTextSearch.new(config, source_record)
      expect { trigger.perform }.to raise_error(FphsException, /target_column/)
    end
  end

  describe 'default ts_config' do
    it 'defaults to english when ts_config is omitted' do
      source_record = @master.dynamic_model__test_fts_trigger_sources.create!(
        current_user: @user,
        title: 'default config test',
        body: 'should use english text search configuration',
        notes: ''
      )

      config = {
        fts_1: {
          target_table: "#{@schema_name}.#{@target_table_name}",
          target_column: 'search_vector',
          target_foreign_key_column: 'source_record_id',
          source_fields: %w[title body]
          # ts_config intentionally omitted
        }
      }

      trigger = SaveTriggers::FullTextSearch.new(config, source_record)
      trigger.perform

      search_result = @conn.execute(<<~SQL)
        SELECT id FROM #{@schema_name}.#{@target_table_name}
        WHERE source_record_id = #{source_record.id}
        AND search_vector @@ to_tsquery('english', 'default & english')
      SQL
      expect(search_result.count).to eq(1)
    end
  end
end
