# frozen_string_literal: true

# Verify NFS setup and rolled-back migration cleanup without modifying shared test directories.
require 'tmpdir'
require 'rails_helper'

RSpec.describe SetupHelper do
  def with_isolated_filestore
    filesystem = NfsStore::Manage::Filesystem
    original_nfs_store_directory = filesystem.nfs_store_directory
    original_temp_directory = filesystem.temp_directory
    nfs_store_directory = Dir.mktmpdir('setup_helper_nfs_store')
    temp_directory = Dir.mktmpdir('setup_helper_nfs_tmp')
    filesystem.nfs_store_directory = nfs_store_directory
    filesystem.temp_directory = temp_directory
    yield nfs_store_directory
  ensure
    filesystem.nfs_store_directory = original_nfs_store_directory
    filesystem.temp_directory = original_temp_directory
    FileUtils.rm_rf nfs_store_directory if nfs_store_directory
    FileUtils.rm_rf temp_directory if temp_directory
  end

  describe '.move_rolled_back_migration_files' do
    it 'moves an existing migration and overwrites a same-named file' do
      Dir.mktmpdir('setup_helper_rolled_back') do |rolled_back_dir|
        Dir.mktmpdir('setup_helper_migrations') do |migration_dir|
          allow(described_class).to receive(:rolled_back_migrations_dirname).and_return(rolled_back_dir)
          migration_file = File.join(migration_dir, 'migration.rb')
          rolled_back_file = File.join(rolled_back_dir, 'migration.rb')
          File.write migration_file, 'new migration'
          File.write rolled_back_file, 'old migration'

          described_class.move_rolled_back_migration_files([migration_file])

          expect(File).not_to exist(migration_file)
          expect(File.read(rolled_back_file)).to eq('new migration')
        end
      end
    end

    it 'skips a missing migration file without raising' do
      Dir.mktmpdir('setup_helper_rolled_back') do |rolled_back_dir|
        allow(described_class).to receive(:rolled_back_migrations_dirname).and_return(rolled_back_dir)

        expect do
          described_class.move_rolled_back_migration_files([File.join(rolled_back_dir, 'missing.rb')])
        end.not_to raise_error
      end
    end
  end

  describe '.clean_rolled_back_migrations_dir' do
    it 'removes migration files while preserving other files' do
      Dir.mktmpdir('setup_helper_rolled_back') do |rolled_back_dir|
        allow(described_class).to receive(:rolled_back_migrations_dirname).and_return(rolled_back_dir)
        migration_file = File.join(rolled_back_dir, 'migration.rb')
        other_file = File.join(rolled_back_dir, 'notes.txt')
        File.write migration_file, 'migration'
        File.write other_file, 'notes'

        described_class.clean_rolled_back_migrations_dir

        expect(File).not_to exist(migration_file)
        expect(File).to exist(other_file)
      end
    end
  end

  describe '.setup_nfs_directories' do
    it 'removes stale filestore content under the root' do
      with_isolated_filestore do |root|
        stale_path = File.join(root, 'stale-app', 'containers')
        FileUtils.mkdir_p stale_path

        described_class.setup_nfs_directories

        expect(File).not_to exist(stale_path)
      end
    end

    it 'recreates every group directory' do
      with_isolated_filestore do |root|
        described_class.setup_nfs_directories

        NfsStore::Manage::Filesystem.group_id_range.each do |group_id|
          group_directory = File.join(root, "#{NfsStore::Manage::Group::NfsMountNamePrefix}#{group_id}")
          expect(Dir).to exist(group_directory)
        end
      end
    end

    it 'creates the ref-data containers directory for the active app type' do
      with_isolated_filestore do |root|
        described_class.setup_nfs_directories
        app_type = Admin::AppType.active.find_by(name: 'ref-data')
        containers_directory = File.join(root, 'gid601', "app-type-#{app_type.id}", 'containers')

        expect(Dir).to exist(containers_directory)
      end
    end
  end

  describe '.setup_ref_data_app_nfs' do
    it 'recreates the ref-data containers directory when it is missing' do
      with_isolated_filestore do |root|
        app_type = Admin::AppType.active.find_by(name: 'ref-data')
        containers_directory = File.join(root, 'gid601', "app-type-#{app_type.id}", 'containers')
        FileUtils.mkdir_p containers_directory
        FileUtils.rm_rf containers_directory

        described_class.setup_ref_data_app_nfs

        expect(Dir).to exist(containers_directory)
      end
    end
  end
end
