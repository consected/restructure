# frozen_string_literal: true

# Ensures generated migration timestamps remain unique and increasing without waiting between writes.
require 'rails_helper'

RSpec.describe Admin::MigrationGenerator, type: :model do
  describe '#write_db_migration' do
    let(:generator) { described_class.new('timestamp_test', allow_migrations: true) }

    before do
      described_class.instance_variable_set(:@last_migration_timestamp, nil)
      allow(generator).to receive(:db_migration_dirname).and_return('virtual/migrations')
      allow(Dir).to receive(:exist?).with('virtual/migrations').and_return(true)
      allow(Dir).to receive(:glob).with(anything, base: 'virtual/migrations').and_return([])
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
    end

    it 'returns unique increasing timestamps without sleeping' do
      expect(generator).not_to receive(:sleep)

      first_path = generator.write_db_migration('migration', 'first_table', 'abcdef')
      second_path = generator.write_db_migration('migration', 'second_table', 'abcdef')
      timestamps = [first_path, second_path].map { |path| File.basename(path).first(14) }

      expect(timestamps).to all(match(/\A\d{14}\z/))
      expect(timestamps[1]).to be > timestamps[0]
    end

    it 'uses the system-local clock consistently when Rails Time.zone differs' do
      local_now = Time.local(2026, 11, 6, 12, 34, 56)
      zone_name = local_now.utc_offset.zero? ? 'Eastern Time (US & Canada)' : 'UTC'
      allow(Time).to receive(:now).and_return(local_now)

      Time.use_zone(zone_name) do
        first_timestamp = described_class.next_migration_timestamp('virtual/migrations')
        second_timestamp = described_class.next_migration_timestamp('virtual/migrations')

        expect(first_timestamp).to eq(local_now.strftime('%Y%m%d%H%M%S'))
        expect(second_timestamp).to eq((local_now + 1).strftime('%Y%m%d%H%M%S'))
      end
    end

    it 'skips timestamps already present in the target directory' do
      seen_patterns = []
      allow(Dir).to receive(:glob) do |pattern, base:|
        expect(base).to eq('virtual/migrations')
        seen_patterns << pattern
        seen_patterns.length == 1 ? ['existing migration'] : []
      end

      path = generator.write_db_migration('migration', 'existing_table', 'abcdef')

      expect(seen_patterns.length).to eq(2)
      expect(File.basename(path).first(14)).to eq(seen_patterns.last.delete_suffix('*'))
    end
  end
end
