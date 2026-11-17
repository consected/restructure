# frozen_string_literal: true

# Verify generated migrations use an isolated test root and retain the shared root elsewhere.
require 'rails_helper'

RSpec.describe Admin::MigrationGenerator, type: :model do
  describe '.app_migrations_root' do
    it 'includes both test environment suffixes in test' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('test'))
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('TEST_ENV_NUMBER').and_return('3')
      allow(ENV).to receive(:[]).with('TEST_ENV_SET').and_return('_workers')

      expect(described_class.app_migrations_root).to eq('tmp/app_migrations_test3_workers')
    end

    it 'returns the shared root outside test' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('production'))

      expect(described_class.app_migrations_root).to eq('db/app_migrations')
    end
  end

  describe '#db_migration_dirname' do
    it 'places schema migrations under the configured root' do
      migration_generator = described_class.new('dynamic_test')

      expect(migration_generator.db_migration_dirname)
        .to eq("#{described_class.app_migrations_root}/dynamic_test")
    end
  end
end