# frozen_string_literal: true

require 'rails_helper'

# Tests for NfsStore::Process::FullTextSearchJob (issue #74).
# Verifies the NFS Store pipeline job that extracts text from uploaded files
# and writes tsvector data to a target table for full-text searching:
# - Reads pipeline configuration for :full_text_search from extra_log_types
# - Extracts text from supported files (text, PDF, office) via FullTextSearch::TextExtractor
# - Writes extracted text to a target table's tsvector column via FullTextSearch::TsvectorWriter
# - Applies file_filters using the scripted pipeline pattern (regex filters)
# - Skips unsupported file types (e.g. DICOM files)
# - Handles multiple files independently, creating one tsvector row per file
RSpec.describe 'NfsStore::Process::FullTextSearchJob', type: :model do
  include PlayerContactSupport
  include ModelSupport
  include MasterSupport
  include NfsStoreSupport
  include DynamicModelSupport

  def default_role
    'file1'
  end

  before :all do
    create_admin
    create_user

    @original_allow_migrations = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)

    @schema_name = 'dynamic_test'
    @target_table_name = 'test_fts_job_targets'
    @full_target_table = "#{@schema_name}.#{@target_table_name}"

    @conn = ActiveRecord::Base.connection
    @conn.execute("CREATE SCHEMA IF NOT EXISTS #{@schema_name}")

    # Drop existing target table if it exists
    @conn.execute("DROP TABLE IF EXISTS #{@full_target_table} CASCADE")

    # Create the target table for tsvector storage
    # This simulates the FTS target table that the pipeline job writes to
    @conn.execute(<<~SQL)
      CREATE TABLE #{@full_target_table} (
        id bigserial PRIMARY KEY,
        master_id bigint,
        stored_file_id bigint NOT NULL,
        search_vector tsvector,
        created_at timestamp NOT NULL DEFAULT now(),
        updated_at timestamp NOT NULL DEFAULT now(),
        UNIQUE (stored_file_id)
      )
    SQL

    # Create a GIN index on the tsvector column
    @conn.execute(<<~SQL)
      CREATE INDEX idx_test_fts_job_targets_search_vector
      ON #{@full_target_table}
      USING gin (search_vector)
    SQL
  end

  after :all do
    @conn&.execute("DROP TABLE IF EXISTS #{@full_target_table} CASCADE")
    change_setting('AllowDynamicMigrations', @original_allow_migrations)
  end

  before :each do
    seed_database && ActivityLog.define_models
    setup_nfs_store
    setup_fts_pipeline
    setup_container_and_al activity: :fts_test
    setup_default_filters activity: :fts_test

    # Clean target table rows between tests
    @conn.execute("DELETE FROM #{@full_target_table}")
  end

  # Configure the activity log definition with a full_text_search pipeline step
  def setup_fts_pipeline(file_filters: ['.*'], ts_config: 'english')
    @al_name = NfsStoreSupport::AlFilterTestName

    @aldef = ActivityLog.active.where(name: @al_name).first
    unless @aldef
      @aldef = ActivityLog.where(name: @al_name).first
      @aldef.update(disabled: false, current_admin: @admin)
      @aldef = ActivityLog.active.where(name: @al_name).first
    end
    expect(@aldef).not_to be nil

    @aldef.extra_log_types = <<~ENDDEF
      fts_test:
        label: FTS Test
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          on_create:
            create_filestore_container:
              name:
                - session files
                - select_scanner
              label: Session Files
              create_with_role: nfs_store group 600

        references:
          nfs_store__manage__container:
            label: Files
            from: this
            add: one_to_this
            view_as:
              edit: hide
              show: filestore
              new: not_embedded

        nfs_store:
          pipeline:
            - mount_archive:
            - index_files:
            - full_text_search:
                target_table: #{@full_target_table}
                target_column: search_vector
                target_foreign_key_column: stored_file_id
                ts_config: #{ts_config}
                file_filters:
                  - #{file_filters.join("\n                  - ")}
    ENDDEF

    @aldef.current_admin = @admin
    @aldef.save!
    @aldef.option_configs(force: true)
    ActivityLog::PlayerContactPhone.definition.option_configs(force: true)

    finalize_al_setup activity: :fts_test
  end

  describe 'pipeline config reading' do
    it 'reads the full_text_search config from the pipeline' do
      text_content = 'This is searchable text content for full text search testing'
      ul = upload_file('test-document.txt', text_content)
      sf = ul.stored_file

      ph = NfsStore::Process::ProcessHandler.new(sf)
      config = ph.pipeline_job_config(:full_text_search)

      expect(config).not_to be_nil
      expect(config[:target_table]).to eq @full_target_table
      expect(config[:target_column]).to eq 'search_vector'
      expect(config[:target_foreign_key_column]).to eq 'stored_file_id'
      expect(config[:ts_config]).to eq 'english'
      expect(config[:file_filters]).to eq(['.*'])
    end
  end

  describe 'file_filters' do
    it 'indexes a supported file when it matches file_filters' do
      setup_fts_pipeline(file_filters: ['.*\\.txt$'])

      ul = upload_file('filter-match.txt', 'text content to include')
      sf = ul.stored_file

      job = NfsStore::Process::FullTextSearchJob.new
      curr_app = sf.current_user.app_type_id
      job.perform(sf, curr_app)

      result = @conn.execute(
        "SELECT count(*) AS cnt FROM #{@full_target_table} WHERE stored_file_id = #{sf.id}"
      )
      expect(result.first['cnt']).to eq 1
    end

    it 'skips a supported file when it does not match file_filters' do
      setup_fts_pipeline(file_filters: ['.*\\.txt$'])

      ul = upload_file('filter-miss.csv', 'text content that should be skipped by filters')
      sf = ul.stored_file

      job = NfsStore::Process::FullTextSearchJob.new
      curr_app = sf.current_user.app_type_id
      job.perform(sf, curr_app)

      result = @conn.execute(
        "SELECT count(*) AS cnt FROM #{@full_target_table} WHERE stored_file_id = #{sf.id}"
      )
      expect(result.first['cnt']).to eq 0
    end
  end

  describe 'basic text extraction and indexing' do
    it 'extracts text from a text file and writes tsvector to the target table' do
      text_content = 'This is searchable text content for full text search testing'
      ul = upload_file('test-document.txt', text_content)
      sf = ul.stored_file

      job = NfsStore::Process::FullTextSearchJob.new
      curr_app = sf.current_user.app_type_id
      job.perform(sf, curr_app)

      # Verify a row was written to the target table
      result = @conn.execute(
        "SELECT stored_file_id, search_vector FROM #{@full_target_table} WHERE stored_file_id = #{sf.id}"
      )
      expect(result.count).to eq 1

      row = result.first
      expect(row['stored_file_id']).to eq sf.id
      expect(row['search_vector']).not_to be_nil
      expect(row['search_vector']).not_to be_empty
    end

    it 'uses the configured ts_config when writing to the target table' do
      setup_fts_pipeline(ts_config: 'simple')

      ul = upload_file('config-simple.txt', 'running data')
      sf = ul.stored_file

      job = NfsStore::Process::FullTextSearchJob.new
      curr_app = sf.current_user.app_type_id
      job.perform(sf, curr_app)

      simple_match = @conn.execute(<<~SQL)
        SELECT id FROM #{@full_target_table}
        WHERE stored_file_id = #{sf.id}
        AND search_vector @@ to_tsquery('simple', 'running')
      SQL
      expect(simple_match.count).to eq(1)

      english_stem_match = @conn.execute(<<~SQL)
        SELECT id FROM #{@full_target_table}
        WHERE stored_file_id = #{sf.id}
        AND search_vector @@ to_tsquery('english', 'run')
      SQL
      expect(english_stem_match.count).to eq(0)
    end
  end

  describe 'skipping unsupported files' do
    it 'does not write tsvector data for unsupported file types' do
      # Upload a DICOM file (unsupported for text extraction)
      ul = upload_file('test-image.dcm', 'binary dicom data')
      sf = ul.stored_file

      job = NfsStore::Process::FullTextSearchJob.new
      curr_app = sf.current_user.app_type_id
      job.perform(sf, curr_app)

      # Verify no row was written to the target table
      result = @conn.execute(
        "SELECT count(*) AS cnt FROM #{@full_target_table} WHERE stored_file_id = #{sf.id}"
      )
      expect(result.first['cnt']).to eq 0
    end
  end

  describe 'multiple files' do
    it 'creates a separate tsvector entry for each uploaded text file' do
      stored_file_ids = []

      3.times do |i|
        content = "Document number #{i} with unique searchable content about topic #{i}"
        ul = upload_file("test-doc-#{i}.txt", content)
        sf = ul.stored_file
        stored_file_ids << sf.id

        job = NfsStore::Process::FullTextSearchJob.new
        curr_app = sf.current_user.app_type_id
        job.perform(sf, curr_app)
      end

      # Verify each file has its own tsvector row
      result = @conn.execute(
        "SELECT count(*) AS cnt FROM #{@full_target_table}"
      )
      expect(result.first['cnt']).to eq 3

      # Verify each stored_file_id has a row
      stored_file_ids.each do |sf_id|
        row = @conn.execute(
          "SELECT search_vector FROM #{@full_target_table} WHERE stored_file_id = #{sf_id}"
        ).first
        expect(row).not_to be_nil
        expect(row['search_vector']).not_to be_nil
      end
    end
  end
end
