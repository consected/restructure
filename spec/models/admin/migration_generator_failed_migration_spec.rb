# frozen_string_literal: true

# Regression coverage for issue #1505: missing generated migration files must not mask migration errors.
require 'rails_helper'

RSpec.describe Admin::MigrationGenerator, type: :model do
  describe '#run_migration' do
    it 'preserves the migration exception when the migration file is missing' do
      migration_generator = described_class.new('migration_failure_test', allow_migrations: true)
      missing_migration = Rails.root.join('tmp', "missing_migration_#{SecureRandom.hex}.rb")
      migration_generator.instance_variable_set(:@do_migration, missing_migration.to_s)

      migration_context = double
      allow(Admin::AppTypeImport).to receive(:prevent_migrations?).and_return(false)
      allow(described_class).to receive(:migration_context).and_return(migration_context)
      allow(migration_context).to receive(:migrate).and_raise(StandardError, 'original migration failure')

      expect { migration_generator.run_migration }
        .to raise_error(FphsException, /original migration failure/)
    end

    it 'preserves the migration exception when moving the failed migration file raises' do
      migration_generator = described_class.new('migration_failure_test', allow_migrations: true)
      migration_file = Rails.root.join('tmp', "migration_to_fail_#{SecureRandom.hex}.rb")
      migration_generator.instance_variable_set(:@do_migration, migration_file.to_s)

      migration_context = double
      allow(Admin::AppTypeImport).to receive(:prevent_migrations?).and_return(false)
      allow(described_class).to receive(:migration_context).and_return(migration_context)
      allow(migration_context).to receive(:migrate).and_raise(StandardError, 'original migration failure')
      allow(File).to receive(:exist?).with(migration_file.to_s).and_return(true)
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:mv)
        .with(migration_file.to_s, migration_generator.db_migration_failed_dirname)
        .and_raise(Errno::EACCES, 'permission denied')

      expect { migration_generator.run_migration }
        .to raise_error(FphsException, /original migration failure/)
    end
  end
end
