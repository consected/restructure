# frozen_string_literal: true

# Tests for Issue #911: Improved error handling in NfsStore::Archive::Mounter flag file operations.
#
# When flag file operations (touch, rm_f, read, write, exist?, mtime) fail due to
# filesystem errors (e.g. permission denied, I/O errors), the original low-level
# exceptions (Errno::EACCES, etc.) should be rescued and re-raised as
# FsException::Action with descriptive messages that include:
# - the method name
# - the flag file path
# - the original error details
# - a hint about likely causes (filesystem mount issues or role/access problems)
#
# These tests use a stubbed stored_file to avoid requiring actual NFS filesystem setup.

require 'rails_helper'

RSpec.describe NfsStore::Archive::Mounter, 'flag file error handling - Issue911', type: :model do
  let(:fake_archive_path) { '/nfs_store/gid600/containers/test_archive.zip' }
  let(:fake_file_name) { 'test_archive.zip' }

  let(:stored_file) do
    instance_double(
      'NfsStore::Manage::StoredFile',
      retrieval_path: fake_archive_path,
      file_name: fake_file_name
    )
  end

  let(:mounter) do
    m = described_class.new
    m.stored_file = stored_file
    m
  end

  let(:processing_archive_flag) { "#{fake_archive_path}#{described_class::ProcessingArchiveSuffix}" }
  let(:failed_archive_flag) { "#{fake_archive_path}#{described_class::FailedArchiveSuffix}" }
  let(:processing_index_flag) { "#{fake_archive_path}#{described_class::ProcessingIndexSuffix}" }

  shared_examples 'raises FsException::Action with context' do |method_name|
    it "includes the method name '#{method_name}' in the error message" do
      expect { subject }.to raise_error(FsException::Action, /#{Regexp.escape(method_name)} failed/)
    end

    it 'includes the flag file path in the error message' do
      expect { subject }.to raise_error(FsException::Action, /flag file '.*'/)
    end

    it 'includes the original error class and message' do
      expect { subject }.to raise_error(FsException::Action, /Errno::EACCES - Permission denied/)
    end

    it 'includes a hint about likely causes' do
      expect { subject }.to raise_error(
        FsException::Action,
        %r{filesystem mount/connection issue.*does not have access to the container's files}
      )
    end
  end

  describe '#indicator_timed_out?' do
    context 'when File.exist? raises a permission error' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(fake_archive_path).and_raise(Errno::EACCES, fake_archive_path)
      end

      subject { mounter.indicator_timed_out? }

      include_examples 'raises FsException::Action with context', 'indicator_timed_out?'
    end

    context 'when File.mtime raises a permission error' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(fake_archive_path).and_return(true)
        allow(mounter).to receive(:failed_indicator?).and_return(false)
        allow(File).to receive(:mtime).with(fake_archive_path).and_raise(Errno::EACCES, fake_archive_path)
      end

      subject { mounter.indicator_timed_out? }

      include_examples 'raises FsException::Action with context', 'indicator_timed_out?'
    end

    context 'when FileUtils.rm_f raises a permission error during cleanup' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(fake_archive_path).and_return(true)
        allow(mounter).to receive(:failed_indicator?).and_return(false)
        # Simulate a timed-out indicator
        allow(File).to receive(:mtime).with(fake_archive_path)
                                      .and_return(Time.now - described_class::ProcessingRetryTime - 10)
        allow(FileUtils).to receive(:rm_f).with(fake_archive_path).and_raise(Errno::EACCES, fake_archive_path)
      end

      subject { mounter.indicator_timed_out?(clear: true) }

      include_examples 'raises FsException::Action with context', 'indicator_timed_out?'
    end

    context 'when File.exist? raises an IOError' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(fake_archive_path).and_raise(IOError, 'closed stream')
      end

      subject { mounter.indicator_timed_out? }

      it 'raises FsException::Action for IOError' do
        expect { subject }.to raise_error(FsException::Action, /indicator_timed_out\?.*IOError/)
      end
    end
  end

  describe '#extract_in_progress?' do
    context 'when File.exist? raises a permission error' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(processing_archive_flag).and_raise(Errno::EACCES, processing_archive_flag)
      end

      subject { mounter.extract_in_progress? }

      include_examples 'raises FsException::Action with context', 'extract_in_progress?'
    end

    context 'when File.mtime raises a permission error' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(processing_archive_flag).and_return(true)
        allow(File).to receive(:mtime).with(processing_archive_flag)
                                      .and_raise(Errno::EACCES, processing_archive_flag)
      end

      subject { mounter.extract_in_progress? }

      include_examples 'raises FsException::Action with context', 'extract_in_progress?'
    end
  end

  describe '#extract_in_progress!' do
    context 'when FileUtils.touch raises a permission error' do
      before do
        allow(FileUtils).to receive(:touch).with(processing_archive_flag)
                                           .and_raise(Errno::EACCES, processing_archive_flag)
      end

      subject { mounter.extract_in_progress! }

      include_examples 'raises FsException::Action with context', 'extract_in_progress!'

      it 'reports the processing archive flag path' do
        expect { subject }.to raise_error(FsException::Action, /#{Regexp.escape(processing_archive_flag)}/)
      end
    end

    context 'when FileUtils.touch raises EIO' do
      before do
        allow(FileUtils).to receive(:touch).with(processing_archive_flag)
                                           .and_raise(Errno::EIO, 'Input/output error')
      end

      subject { mounter.extract_in_progress! }

      it 'raises FsException::Action for EIO' do
        expect { subject }.to raise_error(FsException::Action, /extract_in_progress!.*Errno::EIO/)
      end
    end
  end

  describe '#extract_failed!' do
    let(:original_exception) { StandardError.new('original extraction error') }

    context 'when File.write raises a permission error' do
      before do
        # extract_completed! is called first — let it succeed
        allow(FileUtils).to receive(:rm_f).with(processing_archive_flag)
        allow(File).to receive(:write).with(failed_archive_flag, original_exception.message)
                                      .and_raise(Errno::EACCES, failed_archive_flag)
      end

      subject { mounter.extract_failed!(original_exception) }

      include_examples 'raises FsException::Action with context', 'extract_failed!'

      it 'reports the failed archive flag path' do
        expect { subject }.to raise_error(FsException::Action, /#{Regexp.escape(failed_archive_flag)}/)
      end
    end

    context 'when extract_completed! raises (via its own rescue)' do
      before do
        allow(FileUtils).to receive(:rm_f).with(processing_archive_flag)
                                          .and_raise(Errno::EACCES, processing_archive_flag)
      end

      subject { mounter.extract_failed!(original_exception) }

      it 'raises FsException::Action from extract_completed!' do
        expect { subject }.to raise_error(FsException::Action, /extract_completed!/)
      end
    end
  end

  describe '#extract_failure_reason' do
    context 'when File.exist? raises a permission error' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(fake_archive_path).and_raise(Errno::EACCES, fake_archive_path)
      end

      subject { mounter.extract_failure_reason }

      include_examples 'raises FsException::Action with context', 'extract_failure_reason'
    end

    context 'when File.read raises a permission error' do
      let(:failed_path) { "#{fake_archive_path}#{described_class::FailedArchiveSuffix}" }
      let(:failed_stored_file) do
        instance_double(
          'NfsStore::Manage::StoredFile',
          retrieval_path: failed_path,
          file_name: "#{fake_file_name}#{described_class::FailedArchiveSuffix}"
        )
      end

      before do
        mounter.stored_file = failed_stored_file
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(failed_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(failed_path).and_raise(Errno::EACCES, failed_path)
      end

      subject { mounter.extract_failure_reason }

      include_examples 'raises FsException::Action with context', 'extract_failure_reason'
    end
  end

  describe '#extract_completed!' do
    context 'when FileUtils.rm_f raises a permission error' do
      before do
        allow(FileUtils).to receive(:rm_f).with(processing_archive_flag)
                                          .and_raise(Errno::EACCES, processing_archive_flag)
      end

      subject { mounter.extract_completed! }

      include_examples 'raises FsException::Action with context', 'extract_completed!'
    end
  end

  describe '#index_in_progress?' do
    context 'when File.exist? raises a permission error' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(processing_index_flag).and_raise(Errno::EACCES, processing_index_flag)
      end

      subject { mounter.index_in_progress? }

      include_examples 'raises FsException::Action with context', 'index_in_progress?'
    end

    context 'when File.mtime raises a permission error' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(processing_index_flag).and_return(true)
        allow(File).to receive(:mtime).with(processing_index_flag)
                                      .and_raise(Errno::EACCES, processing_index_flag)
      end

      subject { mounter.index_in_progress? }

      include_examples 'raises FsException::Action with context', 'index_in_progress?'
    end
  end

  describe '#index_in_progress!' do
    context 'when FileUtils.touch raises a permission error' do
      before do
        allow(FileUtils).to receive(:touch).with(processing_index_flag)
                                           .and_raise(Errno::EACCES, processing_index_flag)
      end

      subject { mounter.index_in_progress! }

      include_examples 'raises FsException::Action with context', 'index_in_progress!'

      it 'reports the processing index flag path' do
        expect { subject }.to raise_error(FsException::Action, /#{Regexp.escape(processing_index_flag)}/)
      end
    end
  end

  describe '#index_completed!' do
    context 'when FileUtils.rm_f raises a permission error' do
      before do
        allow(FileUtils).to receive(:rm_f).with(processing_index_flag)
                                          .and_raise(Errno::EACCES, processing_index_flag)
      end

      subject { mounter.index_completed! }

      include_examples 'raises FsException::Action with context', 'index_completed!'
    end
  end

  describe '.mount_all' do
    let(:stored_file_for_mount_all) do
      instance_double(
        'NfsStore::Manage::StoredFile',
        retrieval_path: fake_archive_path,
        file_name: fake_file_name,
        id: 42
      )
    end

    context 'when File.ctime raises a filesystem error' do
      before do
        allow(described_class).to receive(:has_archive_extension?).with(stored_file_for_mount_all).and_return(true)
        allow(File).to receive(:ctime).with(fake_archive_path).and_raise(Errno::EACCES, fake_archive_path)
        # After the ctime rescue returns nil, td will be nil, so it won't skip.
        # archive_extracted? must be false to continue.
        mounter_instance = instance_double(described_class)
        allow(described_class).to receive(:new).and_return(mounter_instance)
        allow(mounter_instance).to receive(:stored_file=)
        allow(mounter_instance).to receive(:archive_extracted?).and_return(false)
        allow(mounter_instance).to receive(:extract_completed!)
          .and_raise(Errno::EACCES, processing_archive_flag)
      end

      it 'raises FsException::Action with context about the stored file' do
        relation = double('ActiveRecord::Relation', all: [stored_file_for_mount_all])
        expect do
          described_class.mount_all(relation)
        end.to raise_error(FsException::Action, /mount_all.*test_archive\.zip.*id: 42/)
      end

      it 'includes the original error details in the message' do
        relation = double('ActiveRecord::Relation', all: [stored_file_for_mount_all])
        expect do
          described_class.mount_all(relation)
        end.to raise_error(FsException::Action, /Errno::EACCES/)
      end
    end
  end
end
