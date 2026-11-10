# frozen_string_literal: true

# Verify isolated filesystem setup and lazy app definition lifetimes.
require 'tmpdir'
require 'rails_helper'

RSpec.describe SetupHelper do
  describe 'lazy app definitions' do
    it 'registers only imported app schemas, not shared suite schemas' do
      expect(described_class::LAZY_APP_SCHEMAS).to contain_exactly(
        'play_ipa', 'sample_tracking', 'study_info', 'study_rec'
      )
    end

    it 'does not import apps when suspending an empty schema' do
      expect(described_class).not_to receive(:run_extra_setups)
      expect { described_class.suspend_app_definitions('study_rec') }.not_to raise_error
    end

    context 'with isolated definitions' do
      before do
        allow(described_class).to receive(:refresh_app_definitions)
        @definitions = described_class.app_definition_classes.to_h do |klass|
          allow_any_instance_of(klass).to receive(:generate_model)
          allow_any_instance_of(klass).to receive(:add_master_association)
          attributes = klass.first!.attributes.except('id')
          rows = [
            ['play_ipa', false], ['play_ipa', true], ['study_info', false],
            ['dynamic_test', false], ['ref_data', false]
          ].map do |schema, disabled|
            attributes.merge('schema_name' => schema, 'disabled' => disabled, 'updated_at' => 1.day.ago)
          end
          ids = klass.insert_all!(rows, returning: %w[id]).rows.flatten
          [klass, ids.map { |id| klass.find(id) }]
        end
      end

      it 'suspends all three definition types only in the selected app schema' do
        described_class.suspend_app_definitions('play_ipa')

        @definitions.each_value do |active, inactive, other_app, suite_owned, reference_data|
          expect(active.reload.disabled).to be(true)
          expect(active.updated_at).to be > 1.hour.ago
          expect(inactive.reload.disabled).to be(true)
          expect([other_app, suite_owned, reference_data].map { |record| record.reload.disabled }).to eq([false] * 3)
        end
      end

      it 'persists resumable IDs and preserves pre-disabled versions across repeated suspension' do
        2.times { described_class.suspend_app_definitions('play_ipa') }
        described_class.resume_app_definitions('play_ipa')

        @definitions.each do |klass, (active, inactive, *)|
          expect(active.reload.disabled).to be(false)
          expect(inactive.reload.disabled).to be(true)
          expect(described_class::AppDefinitionTally.where(name: "suspended_app_definition/#{klass.name}/#{active.id}"))
            .not_to exist
        end
      end

      it 'resumes one app without enabling another suspended app' do
        described_class.suspend_app_definitions('play_ipa', 'study_info')
        described_class.resume_app_definitions('study_info')

        @definitions.each_value do |active, inactive, other_app, *|
          expect(active.reload.disabled).to be(true)
          expect(inactive.reload.disabled).to be(true)
          expect(other_app.reload.disabled).to be(false)
        end
      end
    end

    it 'rejects suspension or resume of suite-owned schemas' do
      expect { described_class.suspend_app_definitions('ref_data') }.to raise_error(ArgumentError)
      expect { described_class.resume_app_definitions('dynamic_test') }.to raise_error(ArgumentError)
    end
  end

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
