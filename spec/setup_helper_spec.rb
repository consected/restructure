# frozen_string_literal: true

# Verify that test-only filestore state is reset with the test database setup.
require 'rails_helper'

RSpec.describe SetupHelper do
  describe '.setup_nfs_directories' do
    it 'removes stale filestore directories and recreates the ref-data path' do
      root = NfsStore::Manage::Filesystem.nfs_store_directory
      stale_path = File.join(root, 'gid601', 'stale-app', 'containers')
      FileUtils.mkdir_p stale_path

      described_class.setup_nfs_directories

      expect(File).not_to exist(stale_path)
      expect(Dir).to exist(File.join(root, 'gid601', 'app-type-4', 'containers'))
    end
  end
end
