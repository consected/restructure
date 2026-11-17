# frozen_string_literal: true

# Guards against a write-side counterpart of the read-side symlink risk covered by
# container_file_symlink_spec.rb.
#
# Moving/renaming a stored or archived file that itself happens to be a symlink is safe:
# `mv` relocates the symlink entry itself rather than following it, and any later read
# still hits NfsStore::HandlesContainerFile#raise_if_symlink!. The risk covered here is
# different - a symlinked *directory* planted somewhere inside the container (e.g. left
# behind, untouched, by an archive containing a symlinked directory entry - see
# container_file_symlink_spec.rb's archive specs for why symlink entries are never
# rejected/overwritten) can be targeted as the destination of moving a *different,
# legitimate* file, via a plain user-supplied relative path string
# (NfsStore::Manage::Filesystem.clean_path only rejects absolute paths and '..'
# traversal, it has no knowledge of what is actually on disk). Without a containment
# check on the write destination, `FileUtils.mkdir_p`/`Kernel.system('mv', ...)` would
# follow that symlinked directory transparently, landing the moved file's real bytes
# outside the container.
#
# NfsStore::Manage::Filesystem.raise_if_symlink_in_path! (the same per-component
# File.lstat walk used to guard reads) is applied to write destinations in
# NfsStore::Manage::Filesystem#test_dir (:write, :mkdir) and #move_file_to_final_location
# to close this gap.
require 'rails_helper'
require 'securerandom'
require 'tmpdir'

RSpec.describe 'NfsStore stored file symlink write protection', type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  def default_role
    'file1'
  end

  before :each do
    setup_nfs_store
    setup_container_and_al
    setup_default_filters
  end

  it 'does not follow a symlinked directory as an intermediate destination when moving a legitimate file' do
    upload_file('movable.txt', 'legitimate content to move')
    stored_file = @container.stored_files.last
    container_root = File.dirname(stored_file.retrieval_path)

    # Stand-in for anywhere else on the host filesystem the app server process can write
    # to - e.g. what an archive-embedded symlinked directory entry would point at.
    evil_target_dir = Dir.mktmpdir
    linked_subdir = File.join(container_root, 'evil_link')

    begin
      File.symlink(evil_target_dir, linked_subdir)

      expect do
        stored_file.move_to('evil_link')
      end.to raise_error(FsException::SymlinkBlocked, /symbolic link/)

      # The aborted move must not have redirected the file's real bytes outside the
      # container.
      expect(Dir.children(evil_target_dir)).to be_empty

      # ...and the original file must be untouched.
      stored_file.reload
      stored_file.current_user = @container.master.current_user
      expect(stored_file.path).to be_nil
      expect(File.read(stored_file.retrieval_path)).to eq 'legitimate content to move'
    ensure
      File.delete(linked_subdir) if File.exist?(linked_subdir) || File.symlink?(linked_subdir)
      FileUtils.rm_rf(evil_target_dir)
    end
  end

  it 'fails open (returns nil rather than raising) when a path component cannot be stat-ed due to a permission error' do
    # A multi-role user whose first mounted role can't search a directory (e.g. differing
    # bindfs `o=` permissions per role) must still fall through to the next role, the same
    # way it did before this guard existed - test_dir/move_from's "try each role" loops
    # already rescue Errno::EACCES themselves; the guard must not turn that into an
    # unrescued FsException::Action, or every operation for that role would hard-fail
    # instead of gracefully trying the next one.
    upload_file('movable2.txt', 'legitimate content')
    path = @container.stored_files.last.retrieval_path

    allow(File).to receive(:lstat).and_raise(Errno::EACCES, 'denied')

    expect(NfsStore::Manage::Filesystem.raise_if_symlink_in_path!(path)).to be_nil
  end

  it 'does not block an otherwise-valid write when only the guard itself hits a permission error' do
    # If the guard's own verification can't complete (EACCES) but the real underlying
    # operation would otherwise succeed, it must not spuriously block it - test_dir's
    # :write result (an Array from FileUtils.rm, not literal `true`) still comes back,
    # rather than the guard forcing a `false`/raise of its own.
    upload_file('movable2b.txt', 'legitimate content')

    allow(File).to receive(:lstat).and_raise(Errno::EACCES, 'denied')

    expect(NfsStore::Manage::Filesystem.test_dir('nfs_store group 600', @container, :write)).to be_truthy
  end

  it 'falls through to a second role when the first role mount is genuinely inaccessible' do
    # Real bindfs mounts present the SAME underlying container files under different
    # roles/simulated permissions - in this test env (no real bindfs) the two mounts are
    # genuinely separate directories, so the second role's copy has to be created
    # explicitly to prove a real fallback, not just a guard that fails open.
    second_role = 'nfs_store group 601'
    create_user_role second_role, user: @user, app_type: @app_type
    second_role_dir = NfsStore::Manage::Filesystem.nfs_store_path(second_role, @container, strip_final_slash: true)
    FileUtils.mkdir_p(second_role_dir)

    # Force a deterministic role order so the failing role is genuinely tried first,
    # rather than depending on DB query order.
    allow(@container).to receive(:current_user_role_names).and_return(['nfs_store group 600', second_role])

    original_lstat = File.method(:lstat)
    allow(File).to receive(:lstat) do |*args|
      raise Errno::EACCES, args.first if args.first.to_s.include?('gid600')

      original_lstat.call(*args)
    end

    original_touch = FileUtils.method(:touch)
    allow(FileUtils).to receive(:touch) do |*args|
      raise Errno::EACCES, args.first if args.first.to_s.include?('gid600')

      original_touch.call(*args)
    end

    expect(NfsStore::Manage::Filesystem.test_dir('nfs_store group 600', @container, :write)).to be false
    expect(NfsStore::Manage::Filesystem.test_dir(second_role, @container, :write)).to be_truthy
  ensure
    FileUtils.rm_rf(second_role_dir) if second_role_dir
  end

  it 'does not follow a symlink planted at a mounter flag file path' do
    secret_path = Rails.root.join('tmp', "secret-#{SecureRandom.hex}.txt").to_s
    File.write(secret_path, 'unauthorized secret content')

    upload_file('report.txt', 'legitimate container content')
    stored_file = @container.stored_files.last
    mounter = NfsStore::Archive::Mounter.new(stored_file:)
    flag_path = mounter.processing_archive_flag_path

    begin
      # Stand-in for the flag file's sibling name being swapped for a symlink, by some
      # means other than the app's own flag-writing code - the archive file itself
      # (already guarded via retrieval_path) is untouched; only this exact suffixed name
      # has never been individually checked before.
      File.symlink(secret_path, flag_path)

      expect { mounter.extract_in_progress! }.to raise_error(FsException::SymlinkBlocked, /symbolic link/)
      expect(File.read(secret_path)).to eq 'unauthorized secret content'
    ensure
      File.delete(flag_path) if File.exist?(flag_path) || File.symlink?(flag_path)
      File.delete(secret_path) if File.exist?(secret_path)
    end
  end

  it 'does not follow a symlink planted at a processing flag path, without blocking other files in the same batch' do
    secret_path = Rails.root.join('tmp', "secret-#{SecureRandom.hex}.txt").to_s
    File.write(secret_path, 'unauthorized secret content')

    upload_file('one.txt', 'legitimate content one')
    upload_file('two.txt', 'legitimate content two')
    sf_one = @container.stored_files.find_by!(file_name: 'one.txt')
    sf_two = @container.stored_files.find_by!(file_name: 'two.txt')

    handler = NfsStore::Process::ProcessHandler.new([sf_one, sf_two])
    flag_path_one = handler.processing_flag_file_path(sf_one)
    flag_path_two = handler.processing_flag_file_path(sf_two)

    begin
      File.symlink(secret_path, flag_path_one)

      handler.set_processing_flags

      # The tampered file's flag was skipped rather than following the symlink...
      expect(File.lstat(flag_path_one)).to be_symlink
      expect(File.read(secret_path)).to eq 'unauthorized secret content'
      # ...but the other file in the same batch was still flagged normally.
      expect(File.exist?(flag_path_two)).to be true
    ensure
      File.delete(flag_path_one) if File.exist?(flag_path_one) || File.symlink?(flag_path_one)
      File.delete(flag_path_two) if File.exist?(flag_path_two) || File.symlink?(flag_path_two)
      File.delete(secret_path) if File.exist?(secret_path)
    end
  end
end
