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
      expect(zip.entries.first.gp_flags & Zip::Entry::COMPRESSION_LEVEL_SUPERFAST_GPFLAG)
        .to eq(Zip::Entry::COMPRESSION_LEVEL_SUPERFAST_GPFLAG)
    end
  ensure
    zip_file&.close!
  end
end


RSpec.describe NfsStore::Archive::ZipFileGenerator, type: :model do
  let(:temp_directory) { Dir.mktmpdir('nfs_store_zip_target') }

  before { allow(described_class).to receive(:tmpdir).and_return(temp_directory) }
  after { FileUtils.rm_rf(temp_directory) }

  it 'writes to an optional target path' do
    source_path = File.join(temp_directory, 'target-source.txt')
    target_path = File.join(temp_directory, 'prepared', 'download.zip')
    File.write(source_path, 'prepared contents')

    result = described_class.zip_retrieved_items(
      [{ container_id: 1, file_name: 'target-source.txt', retrieval_path: source_path }], target_path:
    )

    expect(result).to eq(target_path)
    expect(Zip::File.open(target_path) { |zip| zip.read('target-source.txt') }).to eq('prepared contents')
  end
end
