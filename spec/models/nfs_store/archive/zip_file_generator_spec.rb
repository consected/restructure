# frozen_string_literal: true

# Tests RubyZip 3 compatibility for NFS Store retrieved-file archives.

require 'rails_helper'

RSpec.describe NfsStore::Archive::ZipFileGenerator, type: :model do
  let(:temp_directory) { Dir.mktmpdir('nfs_store_zip_file_generator') }

  before do
    allow(described_class).to receive(:tmpdir).and_return(temp_directory)
  end

  after do
    FileUtils.rm_rf(temp_directory)
  end

  it 'creates a zip archive containing retrieved files at their archive paths' do
    source_path = File.join(temp_directory, 'source.txt')
    File.write(source_path, 'retrieved file contents')

    zip_file = described_class.zip_retrieved_items(
      [
        {
          container_id: 1,
          parent_name: 'parent',
          container_name: 'container',
          container_path: 'files',
          file_name: 'source.txt',
          retrieval_path: source_path
        }
      ]
    )

    Zip::File.open(zip_file.path) do |zip|
      expect(zip.entries.map(&:name)).to eq ['parent/container/files/source.txt']
      expect(zip.read('parent/container/files/source.txt')).to eq 'retrieved file contents'
    end
  ensure
    zip_file&.close!
  end
end
