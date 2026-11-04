# frozen_string_literal: true

# Purpose: the shared database metadata caches (column comments, foreign keys, data dictionary
# contents) must be dropped only once a migration has completed, and the column comments cache
# can be force-refreshed so comments written back to the database by a migration are never stale.
require 'rails_helper'

RSpec.describe Admin::MigrationGenerator, type: :model do
  let(:cache_keys) do
    version = Application.version
    ["db_column_comments-#{version}", "db_foreign_keys-#{version}",
     "db_data_dic-metadata_cache_tests-#{version}", "db_data_dic-prev_metadata_cache_tests-#{version}"]
  end
  let(:generator) do
    described_class.new('metadata_cache_test', table_name: 'metadata_cache_tests',
                                               prev_table_name: 'prev_metadata_cache_tests',
                                               allow_migrations: true)
  end

  before do
    cache_keys.each { |key| Rails.cache.write(key, [{ 'cached' => true }]) }
    allow(Admin::AppTypeImport).to receive(:prevent_migrations?).and_return(false)
    allow(described_class).to receive(:migrate).and_return(true)
  end

  after { cache_keys.each { |key| Rails.cache.delete(key) } }

  describe '#run_migration' do
    it 'drops the cached metadata for the old and new table after the migration completes' do
      calls = []
      allow(described_class).to receive(:migrate) do
        calls << :migrate
        expect(cache_keys.map { |key| Rails.cache.read(key) }).to all(be_present)
      end
      allow(described_class).to receive(:invalidate_definition_metadata_cache!).and_wrap_original do |original, **args|
        calls << :invalidate
        original.call(**args)
      end

      generator.run_migration

      expect(calls).to eq(%i[migrate invalidate])
      expect(cache_keys.map { |key| Rails.cache.read(key) }).to all(be_nil)
    end

    it 'leaves the cached metadata alone when the migration fails' do
      allow(described_class).to receive(:migrate).and_raise(FphsException, 'migration failure')

      expect { generator.run_migration }.to raise_error(FphsException, /migration failure/)

      expect(cache_keys.map { |key| Rails.cache.read(key) }).to all(be_present)
    end

    it 'leaves the cached metadata alone when migrations are not allowed' do
      generator.allow_migrations = false

      generator.run_migration

      expect(cache_keys.map { |key| Rails.cache.read(key) }).to all(be_present)
    end
  end

  describe '.data_dic' do
    let(:basename) { 'metadata_cache_dd' }
    let(:key) { "db_data_dic-#{basename}-#{Application.version}" }

    before do
      allow(described_class).to receive(:tables_and_views)
        .and_return([{ 'table_name' => "#{basename}_datadic", 'schema_name' => 'ref_data' }])
      allow(described_class.connection).to receive(:execute).and_return([{ 'variable_name' => 'a' }])
    end

    after { Rails.cache.delete(key) }

    it 'caches the result with an expiry so row changes are eventually picked up' do
      expect(Rails.cache).to receive(:fetch)
        .with(key, expires_in: described_class::DataDicCacheTTL).and_call_original

      expect(described_class.data_dic(basename)).to eq([{ 'variable_name' => 'a' }])
    end

    it 'is cleared when the invalidated table name is the _datadic table' do
      Rails.cache.write(key, [{ 'cached' => true }])

      described_class.invalidate_definition_metadata_cache!(table_names: ["#{basename}_datadic"])

      expect(Rails.cache.read(key)).to be_nil
    end
  end

  describe '.column_comments' do
    it 'returns the cached result by default' do
      expect(described_class.column_comments).to eq([{ 'cached' => true }])
    end

    it 're-runs the catalog query and replaces the cached result when forced' do
      result = described_class.column_comments(force: true)

      expect(result).not_to eq([{ 'cached' => true }])
      expect(Rails.cache.read("db_column_comments-#{Application.version}")).to eq(result)
    end
  end
end
