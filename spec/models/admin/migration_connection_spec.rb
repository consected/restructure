# frozen_string_literal: true

# Verify inline migration tracking and migration worker cleanup after failures and timeouts.
require 'rails_helper'

RSpec.describe Admin::MigrationConnection, type: :model do
  describe '.migrate' do
    it 'runs inline when the current connection is pinned' do
      connection_pool = ActiveRecord::Base.connection_pool
      expect(connection_pool.with_connection(&:pinned)).to be(true)

      calling_thread = Thread.current
      expect(described_class).to receive(:call_migration_context).with('test_migrations') do
        expect(Thread.current).to eq(calling_thread)
      end

      expect(described_class.migrate('test_migrations')).to be(true)
    end

    it 'records pending files from a migration run on the pinned connection' do
      migration_directory = Dir.mktmpdir('inline_migration')
      migration_seconds = SecureRandom.random_number(86_400)
      migration_version = format('20000101%02d%02d%02d', migration_seconds / 3600,
                                 migration_seconds / 60 % 60, migration_seconds % 60)
      migration_suffix = SecureRandom.hex(6)
      migration_class = "InlineProbe#{migration_suffix.camelize}"
      migration_file = File.join(migration_directory, "#{migration_version}_inline_probe_#{migration_suffix}.rb")
      expanded_migration_file = File.expand_path(migration_file)
      table_name = "dynamic_test.inline_probe_#{migration_suffix}"

      File.write migration_file, <<~RUBY
        class #{migration_class} < ActiveRecord::Migration[8.1]
          def change
            create_table '#{table_name}' do |t|
              t.string :value
            end
          end
        end
      RUBY

      expect(ActiveRecord::Base.connection_pool.with_connection(&:pinned)).to be(true)
      described_class.migrate(migration_directory)

      expect(described_class.inline_migration_files).to include(expanded_migration_file)
      expect(ActiveRecord::Base.connection.data_source_exists?(table_name)).to be(true)
      expect(described_class.take_inline_migration_files!).to eq([expanded_migration_file])
      expect(described_class.inline_migration_files).to be_empty
    ensure
      described_class.take_inline_migration_files!
      described_class.reset_inline_migration_flag!
      FileUtils.remove_entry(migration_directory) if migration_directory && File.exist?(migration_directory)
    end

    it 'records only migrations completed before an inline migration failure' do
      migration_directory = Dir.mktmpdir('inline_migration_failure')
      migration_suffix = SecureRandom.hex(6)
      first_version = format('20000101%06d', SecureRandom.random_number(86_400))
      second_version = format('20000102%06d', SecureRandom.random_number(86_400))
      first_class = "InlineSuccess#{migration_suffix.camelize}"
      second_class = "InlineFailure#{migration_suffix.camelize}"
      table_name = "dynamic_test.inline_probe_#{migration_suffix}"
      first_file = File.join(migration_directory, "#{first_version}_inline_success_#{migration_suffix}.rb")
      second_file = File.join(migration_directory, "#{second_version}_inline_failure_#{migration_suffix}.rb")
      expanded_first_file = File.expand_path(first_file)
      failed_file = Rails.root.join(described_class.db_migration_failed_dirname, File.basename(second_file))

      File.write first_file, <<~RUBY
        class #{first_class} < ActiveRecord::Migration[8.1]
          def change
            create_table '#{table_name}' do |t|
              t.string :value
            end
          end
        end
      RUBY
      File.write second_file, <<~RUBY
        class #{second_class} < ActiveRecord::Migration[8.1]
          def change
            raise 'inline migration failure'
          end
        end
      RUBY

      expect(ActiveRecord::Base.connection_pool.with_connection(&:pinned)).to be(true)
      expect do
        described_class.migrate(migration_directory, do_migration: second_file)
      end.to raise_error(FphsException, /inline migration failure/)

      expect(described_class.inline_migration_files).to eq([expanded_first_file])
      expect(ActiveRecord::Base.connection.data_source_exists?(table_name)).to be(true)
    ensure
      described_class.take_inline_migration_files!
      described_class.reset_inline_migration_flag!
      FileUtils.rm_f failed_file if failed_file
      FileUtils.remove_entry(migration_directory) if migration_directory && File.exist?(migration_directory)
    end

    it 'stops the worker and raises a wrapped timeout when the connection is not pinned' do
      connection_pool = ActiveRecord::Base.connection_pool
      allow(connection_pool).to receive(:with_connection).and_yield(double(pinned: false))
      allow(described_class).to receive(:call_migration_context) { sleep 0.2 }
      stub_const('Settings::MigrationTimeoutSec', 0.01)

      worker_threads = []
      allow(Thread).to receive(:new).and_wrap_original do |new_thread, *args, &block|
        thread = new_thread.call(*args, &block)
        worker_threads << thread
        thread
      end

      expect { described_class.migrate('test_migrations') }
        .to raise_error(FphsException, /Migration did not complete within 0\.01 seconds/)
      expect(worker_threads).to all(satisfy { |thread| !thread.alive? })
    ensure
      worker_threads&.each do |thread|
        thread.kill
        thread.join
      end
    end

    it 'wraps migration errors once and moves the failed migration file' do
      migration_directory = Dir.mktmpdir
      migration_file = File.join(migration_directory, "migration_failure_#{SecureRandom.hex}.rb")
      failed_file = Rails.root.join(described_class.db_migration_failed_dirname, File.basename(migration_file))
      File.write(migration_file, '# migration fixture')

      connection_pool = ActiveRecord::Base.connection_pool
      allow(connection_pool).to receive(:with_connection).and_yield(double(pinned: false))
      allow(described_class).to receive(:call_migration_context).and_raise(StandardError, 'migration exploded')
      expect(described_class).to receive(:move_failed_migration_file).once.and_call_original

      expect do
        described_class.migrate('test_migrations', do_migration: migration_file.to_s)
      end.to raise_error(FphsException) { |error|
        expect(error.message).to include('migration exploded')
        expect(error.message.scan('Failed migration').length).to eq(1)
      }

      expect(File).not_to exist(migration_file)
      expect(File).to exist(failed_file)
    ensure
      FileUtils.rm_f(failed_file) if failed_file
      FileUtils.remove_entry(migration_directory) if migration_directory && File.exist?(migration_directory)
    end

    it 'wraps syntax errors once and moves the failed migration file' do
      migration_directory = Dir.mktmpdir
      migration_file = File.join(migration_directory, "migration_syntax_failure_#{SecureRandom.hex}.rb")
      failed_file = Rails.root.join(described_class.db_migration_failed_dirname, File.basename(migration_file))
      File.write(migration_file, '# migration fixture')

      connection_pool = ActiveRecord::Base.connection_pool
      allow(connection_pool).to receive(:with_connection).and_yield(double(pinned: false))
      allow(described_class).to receive(:call_migration_context).and_raise(SyntaxError, 'migration syntax exploded')
      expect(described_class).to receive(:move_failed_migration_file).once.and_call_original

      expect do
        described_class.migrate('test_migrations', do_migration: migration_file)
      end.to raise_error(FphsException) { |error|
        expect(error.message).to include('migration syntax exploded')
        expect(error.message.scan('Failed migration').length).to eq(1)
      }

      expect(File).not_to exist(migration_file)
      expect(File).to exist(failed_file)
    ensure
      FileUtils.rm_f(failed_file) if failed_file
      FileUtils.remove_entry(migration_directory) if migration_directory && File.exist?(migration_directory)
    end
  end
end
