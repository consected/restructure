# frozen_string_literal: true

# Guards against a security risk in NfsStore file retrieval.
#
# NfsStore::Manage::StoredFile#retrieval_path is expected to point at a regular file physically
# written into the container by the upload pipeline. If the entry at a stored file's location
# is ever replaced with a symlink - however that happens (direct filesystem/NFS access, a
# scripted job, a sync tool, an archive extraction, etc.) - naively following it would serve
# the *link target's* content instead of refusing it. This would bypass the container/role
# -based access control that is supposed to govern what a user can read: once a user is
# permitted to download the stored file record, the OS - not the app - would decide what bytes
# actually come back, unconstrained by the container, app_type, or NFS mount boundaries.
#
# NfsStore::HandlesContainerFile#raise_if_symlink! walks every path component below the
# trusted nfs_store root individually with File.lstat, rather than comparing two resolved
# (realpath) destinations against each other - a realpath-vs-realpath comparison can be
# fooled by a symlink whose target happens to make both sides agree (e.g. a container's
# own directory entry, not just a subdirectory within it, redirected to a different
# container - both "this file's resolved directory" and "this container's resolved root"
# would follow the identical redirect and still match). Only the top-level nfs_store root
# itself is resolved via realpath (it may legitimately be reached via a symlink); every
# component below that - including a container's own directory entry and the leaf file -
# is inspected individually and none of them may be a symlink.
#
# Symlinks are never overwritten and archives are never rejected wholesale for containing
# one - system-generated archives may legitimately contain symlinks a user has no control
# over. Instead, retrieval simply refuses to ever resolve/follow a symlink: an archive
# extracts normally, and NfsStore::Archive::Mounter#extract_archived_files already
# tolerates a single bad entry raising during indexing (existing per-file rescue), so a
# symlink entry is silently never indexed as an ArchivedFile while every other file in the
# same archive remains fully usable. The same read-time guard also covers symlinks that
# appear on already-persisted stored/archived files by any other means.
#
# Specs below, in order:
# 1. A symlink planted directly at a stored file's leaf location, pointing at a "secret"
#    file entirely outside the container.
# 2. A container subdirectory itself replaced with a symlink to an external directory
#    (parent-directory bypass), pointing outside the container.
# 3. A container subdirectory replaced with a symlink pointing at a *different container's*
#    own real directory, rather than an arbitrary host path.
# 4. A container's own directory *entry* (not a subdirectory within it) replaced with a
#    symlink pointing at a different container's own real directory - the case a
#    realpath-vs-realpath comparison would miss (see header note above).
# 5. A crafted .tar.gz archive containing a symlink entry - the archive extracts and
#    indexes successfully, its legitimate file remains downloadable, and the symlink entry
#    is simply never indexed as an ArchivedFile.
# 6. A symlink entry skipped from archive indexing (per spec 5) has no id or download path
#    that could ever reference it - this documents the existing named_like_archive? /
#    index_missing_entry short-circuit, not new behaviour added by this guard.
# 7. An archive that was already mounted/extracted *before* this guard existed (simulated by
#    swapping an already-extracted file for a symlink afterwards) - retrieval must still
#    raise, since the guard is a read-time check, not a one-time extraction-time check.
# 8. A representative internal processing pipeline (NfsStore::Dicom::MetadataHandler) is
#    exercised directly, confirming consumers other than the download controller resolve
#    the same guarded retrieval_path and are protected without any handler-specific code.
# 9. The .zip counterpart to spec 5 - tested independently since Info-ZIP's unzip prints
#    "linking:" (not "inflating:"/"extracting:") for a restored symlink, which
#    extract_archive.sh's own file-count validation does not account for either way.
# 10. A symlink planted directly on disk with no StoredFile record at all must not abort
#    the whole container listing (NfsStore::Browse#list_files_from) - only that one entry
#    is skipped (as an unsaved placeholder), every other file in the container still lists.
# 11. The mandatory negative counterpart to specs 2-4: a legitimate file must still resolve
#    when the *trusted* nfs_store root itself is reached via a symlink (a legitimate
#    ops/deployment scenario, and the default arrangement on macOS dev machines where
#    /var -> /private/var) - only a symlink introduced *below* the root indicates tampering.
require 'rails_helper'
require 'securerandom'
require 'tmpdir'

RSpec.describe 'NfsStore stored file symlink handling', type: :model do
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

  it 'does not follow a symlink planted at a stored file location' do
    upload_file('report.txt', 'legitimate container content')
    stored_file = @container.stored_files.last
    expect(stored_file.file_name).to eq 'report.txt'

    retrieval_path = stored_file.retrieval_path
    expect(File.read(retrieval_path)).to eq 'legitimate container content'

    # Stand-in for a file outside the container / NFS store tree entirely - e.g. another
    # user's home directory, or any other file the app server process can read.
    secret_path = Rails.root.join('tmp', "secret-#{SecureRandom.hex}.txt").to_s
    File.write(secret_path, 'unauthorized secret content')

    begin
      # Replace the stored file's on-disk entry with a symlink to the external secret file.
      # This does not go through any app upload code - it represents the underlying
      # filesystem entry being tampered with by some other means.
      File.delete(retrieval_path)
      File.symlink(secret_path, retrieval_path)
      expect(File.lstat(retrieval_path)).to be_symlink

      download = NfsStore::Download.new(container: @container, activity_log: @activity_log)

      expect do
        download.retrieve_file_from(stored_file.id, :stored_file, for_action: :download)
      end.to raise_error(FsException::SymlinkBlocked, /symbolic link/)
    ensure
      File.delete(secret_path) if File.exist?(secret_path)
    end
  end

  it 'does not follow a symlinked parent directory leading to a stored file' do
    upload_file('placeholder.txt', 'irrelevant')
    container_root = File.dirname(@container.stored_files.last.retrieval_path)

    # A directory entirely outside the container, standing in for anywhere else on the
    # host filesystem the app server process can read.
    evil_target_dir = Dir.mktmpdir
    File.write(File.join(evil_target_dir, 'leak.txt'), 'unauthorized secret content')
    linked_subdir = File.join(container_root, 'linked_subdir')

    begin
      # Replace what should be a real container subdirectory with a symlink to the
      # external directory. `File.lstat` on the final path alone would not catch this,
      # since it only inspects the leaf and still follows symlinked parent directories.
      File.symlink(evil_target_dir, linked_subdir)
      stored_file = create_stored_file('linked_subdir', 'leak.txt')

      download = NfsStore::Download.new(container: @container, activity_log: @activity_log)

      expect do
        download.retrieve_file_from(stored_file.id, :stored_file, for_action: :download)
      end.to raise_error(FsException::SymlinkBlocked, /symbolic link/)
    ensure
      File.delete(linked_subdir) if File.exist?(linked_subdir) || File.symlink?(linked_subdir)
      FileUtils.rm_rf(evil_target_dir)
    end
  end

  it 'does not follow a symlink that hops from one container into a different one' do
    container_a = @container
    activity_log_a = @activity_log
    upload_file('placeholder.txt', 'irrelevant')
    container_a_root = File.dirname(container_a.stored_files.last.retrieval_path)

    # A second, distinct container - standing in for another tenant's container, which in
    # production may live behind a *different* per-role bindfs mount (e.g. gid600 vs
    # gid601). Anchoring containment on the whole filestore root alone would not catch a
    # symlink pointing here, since this container is still nested under that same root.
    setup_access('activity_log__player_contact_phone__step_2', resource_type: :activity_log_type)
    setup_default_filters(activity: :step_2)
    setup_container_and_al(activity: :step_2)
    upload_file('secret.txt', 'unauthorized secret content')
    container_b_root = File.dirname(@container.stored_files.last.retrieval_path)

    # Confirm this genuinely exercises a same-mount, different-container escape (both
    # containers belong to the same user/app_type, so both resolve via the same gidNNN
    # bindfs mount) - the boundary being tested is the container, not the mount.
    expect(container_a_root[%r{/gid\d+/}]).to eq(container_b_root[%r{/gid\d+/}])

    linked_subdir = File.join(container_a_root, 'linked_subdir')

    begin
      # Replace what should be a real container_a subdirectory with a symlink pointing
      # straight at container_b's own real directory - not an arbitrary host path.
      File.symlink(container_b_root, linked_subdir)
      stored_file = create_stored_file('linked_subdir', 'secret.txt', container: container_a)

      download = NfsStore::Download.new(container: container_a, activity_log: activity_log_a)

      expect do
        download.retrieve_file_from(stored_file.id, :stored_file, for_action: :download)
      end.to raise_error(FsException::SymlinkBlocked, /symbolic link/)
    ensure
      File.delete(linked_subdir) if File.exist?(linked_subdir) || File.symlink?(linked_subdir)
    end
  end

  it 'does not follow a symlink that replaces a container directory entry itself, not just a subdirectory within it' do
    container_a = @container
    activity_log_a = @activity_log
    upload_file('placeholder.txt', 'irrelevant')
    container_a_path = File.dirname(container_a.stored_files.last.retrieval_path)

    # A second, distinct container, standing in for another tenant's container.
    setup_access('activity_log__player_contact_phone__step_2', resource_type: :activity_log_type)
    setup_default_filters(activity: :step_2)
    setup_container_and_al(activity: :step_2)
    upload_file('secret.txt', 'unauthorized secret content')
    container_b_path = File.dirname(@container.stored_files.last.retrieval_path)

    begin
      # Replace container_a's OWN directory entry entirely (not merely a subdirectory
      # within it) with a symlink straight to container_b's real directory. A containment
      # check that only compares two realpaths (rather than inspecting each literal path
      # component with lstat) would be fooled here: both "this file's resolved directory"
      # and "this container's resolved root" would follow the identical redirect and
      # still agree with each other.
      FileUtils.rm_rf(container_a_path)
      File.symlink(container_b_path, container_a_path)

      stored_file = create_stored_file(nil, 'secret.txt', container: container_a)

      download = NfsStore::Download.new(container: container_a, activity_log: activity_log_a)

      expect do
        download.retrieve_file_from(stored_file.id, :stored_file, for_action: :download)
      end.to raise_error(FsException::SymlinkBlocked, /symbolic link/)
    ensure
      File.delete(container_a_path) if File.symlink?(container_a_path)
    end
  end

  it 'extracts a .tar.gz archive containing a symlink entry, but never indexes the symlink itself' do
    secret_path = Rails.root.join('tmp', "secret-#{SecureRandom.hex}.txt").to_s
    File.write(secret_path, 'unauthorized secret content')

    archive_source_dir = Dir.mktmpdir
    archive_dir = Dir.mktmpdir
    archive_path = File.join(archive_dir, 'payload.tar.gz')

    begin
      File.write(File.join(archive_source_dir, 'notes.txt'), 'legitimate archive content')
      # Craft a symlink entry pointing outside the extraction directory - exactly what tar
      # preserves transparently by default when an archive is built with real symlinks.
      # System-generated archives may legitimately contain symlinks a user has no control
      # over, so the whole archive is not rejected - only the symlink entry itself is
      # never surfaced as a retrievable ArchivedFile (see NfsStore::Archive::Mounter
      # #extract_archived_files, which already tolerates a single bad entry raising during
      # indexing and simply skips it, leaving every other extracted file usable).
      File.symlink(secret_path, File.join(archive_source_dir, 'linked-secret.txt'))

      Dir.chdir(archive_source_dir) do
        # List entries explicitly (rather than '.') so tar doesn't add a "./" directory
        # entry that would trip up extract_archive.sh's own file-count validation.
        expect(Kernel.system('tar', '-czf', archive_path, 'notes.txt', 'linked-secret.txt')).to be_truthy
      end

      # Archive mounting and indexing are triggered synchronously as part of upload
      # processing in the test env - the upload itself must not raise.
      upload_file('payload.tar.gz', File.read(archive_path))

      notes = @container.archived_files.find_by(file_name: 'notes.txt')
      expect(notes).not_to be_nil
      expect(File.read(notes.retrieval_path)).to eq 'legitimate archive content'

      expect(@container.archived_files.find_by(file_name: 'linked-secret.txt')).to be_nil
    ensure
      FileUtils.rm_rf(archive_source_dir)
      FileUtils.rm_rf(archive_dir)
      File.delete(secret_path) if File.exist?(secret_path)
    end
  end

  it 'never exposes a retrievable reference to a symlink entry skipped from archive indexing' do
    secret_path = Rails.root.join('tmp', "secret-#{SecureRandom.hex}.txt").to_s
    File.write(secret_path, 'unauthorized secret content')

    archive_source_dir = Dir.mktmpdir
    archive_dir = Dir.mktmpdir
    archive_path = File.join(archive_dir, 'payload.tar.gz')

    begin
      File.write(File.join(archive_source_dir, 'notes.txt'), 'legitimate archive content')
      File.symlink(secret_path, File.join(archive_source_dir, 'linked-secret.txt'))

      Dir.chdir(archive_source_dir) do
        expect(Kernel.system('tar', '-czf', archive_path, 'notes.txt', 'linked-secret.txt')).to be_truthy
      end

      upload_file('payload.tar.gz', File.read(archive_path))
      expect(@container.archived_files.find_by(file_name: 'linked-secret.txt')).to be_nil

      # The symlink remains physically present on disk inside the mounted-archive
      # directory (it was never overwritten or deleted), so it still surfaces in a raw
      # filesystem scan of the container...
      expect(@container.list_fs_files).to include(a_string_ending_with('linked-secret.txt'))

      # ...but NfsStore::Manage::StoredFile#named_like_archive? (matched via the
      # `.__mounted-archive__` path segment) makes Browse.list_files_from's "index
      # missing filesystem entries" step return a transient, *unsaved* placeholder for
      # anything found inside a mounted-archive directory, rather than persisting it -
      # that logic exists to avoid double-indexing archive contents as StoredFiles, but
      # it also means our skipped symlink is never given a database record at all.
      listed = NfsStore::Browse.list_files_from(@container, activity_log: @activity_log)
      listed_symlink = listed.find { |f| f.file_name == 'linked-secret.txt' }
      expect(listed_symlink).not_to be_nil
      expect(listed_symlink).not_to be_persisted
      expect(listed_symlink.id).to be_nil

      # With no persisted StoredFile or ArchivedFile record, there is no valid id or
      # container-relative download path that could ever reference this entry - both of
      # NfsStore::Download's lookup mechanisms come up empty. The path here mirrors the
      # real archive_mount_name/archive_file convention: the archive's own file_name
      # ('payload.tar.gz'), not the on-disk '.__mounted-archive__'-suffixed directory name.
      expect(NfsStore::Download.find_download_by_path(@container, 'payload.tar.gz/linked-secret.txt')).to be_nil
    ensure
      FileUtils.rm_rf(archive_source_dir)
      FileUtils.rm_rf(archive_dir)
      File.delete(secret_path) if File.exist?(secret_path)
    end
  end

  it 'does not follow a symlink already resting in a previously-mounted archive directory' do
    archive_source_dir = Dir.mktmpdir
    archive_dir = Dir.mktmpdir
    archive_path = File.join(archive_dir, 'benign.tar.gz')

    begin
      File.write(File.join(archive_source_dir, 'inside.txt'), 'legitimate archived content')

      Dir.chdir(archive_source_dir) do
        expect(Kernel.system('tar', '-czf', archive_path, 'inside.txt')).to be_truthy
      end

      # A normal archive with no symlinks mounts and indexes successfully via the existing
      # upload pipeline, giving us a real ArchivedFile backed by a real extracted file.
      upload_file('benign.tar.gz', File.read(archive_path))
      archived_file = @container.archived_files.find_by(file_name: 'inside.txt')
      expect(archived_file).not_to be_nil

      extracted_path = archived_file.retrieval_path
      expect(File.read(extracted_path)).to eq 'legitimate archived content'

      secret_path = Rails.root.join('tmp', "secret-#{SecureRandom.hex}.txt").to_s
      File.write(secret_path, 'unauthorized secret content')

      begin
        # Simulate an archive that was mounted/extracted before this guard existed, and
        # already has a symlink sitting on disk in its extracted directory - the guard
        # must catch this at read time, not only at extraction time.
        File.delete(extracted_path)
        File.symlink(secret_path, extracted_path)

        download = NfsStore::Download.new(container: @container, activity_log: @activity_log)

        expect do
          download.retrieve_file_from(archived_file.id, :archived_file, for_action: :download)
        end.to raise_error(FsException::SymlinkBlocked, /symbolic link/)
      ensure
        File.delete(secret_path) if File.exist?(secret_path)
      end
    ensure
      FileUtils.rm_rf(archive_source_dir)
      FileUtils.rm_rf(archive_dir)
    end
  end

  it 'protects a representative internal processing pipeline (DICOM metadata handler) too' do
    upload_file('scan.dcm', 'legitimate container content')
    stored_file = @container.stored_files.last
    retrieval_path = stored_file.retrieval_path

    secret_path = Rails.root.join('tmp', "secret-#{SecureRandom.hex}.txt").to_s
    File.write(secret_path, 'unauthorized secret content')

    begin
      File.delete(retrieval_path)
      File.symlink(secret_path, retrieval_path)

      # Other pipeline steps (DeidentifyHandler, NfsStore::Process::FullTextSearchJob,
      # NfsStore::Scripted::ScriptHandler) resolve the file to process via the same
      # guarded ContainerFile#retrieval_path, so the guard protects them too without any
      # handler-specific changes - MetadataHandler is exercised directly here as one
      # representative case (not all of them): it resolves retrieval_path before entering
      # its own internal `rescue StandardError`, so the symlink rejection is not swallowed.
      expect do
        NfsStore::Dicom::MetadataHandler.extract_metadata_from(stored_file)
      end.to raise_error(FsException::SymlinkBlocked, /symbolic link/)
    ensure
      File.delete(secret_path) if File.exist?(secret_path)
    end
  end

  it 'extracts a .zip archive containing a symlink entry, but never indexes the symlink itself' do
    secret_path = Rails.root.join('tmp', "secret-#{SecureRandom.hex}.txt").to_s
    File.write(secret_path, 'unauthorized secret content')

    archive_source_dir = Dir.mktmpdir
    archive_dir = Dir.mktmpdir
    archive_path = File.join(archive_dir, 'payload.zip')

    begin
      File.write(File.join(archive_source_dir, 'notes.txt'), 'legitimate archive content')
      File.symlink(secret_path, File.join(archive_source_dir, 'linked-secret.txt'))

      Dir.chdir(archive_source_dir) do
        # `-y` stores symlinks as symlinks (rather than following them) - the same
        # technique zip archives use to preserve real symlinks. This matters separately
        # from the .tar.gz case: Info-ZIP's `unzip` prints "linking:" (not
        # "inflating:"/"extracting:") for a restored symlink, and `find -type f` also
        # excludes symlinks, so extract_archive.sh's own count-based validation does not
        # reject this archive either way - the symlink entry is simply never indexed.
        expect(Kernel.system('zip', '-y', archive_path, 'notes.txt', 'linked-secret.txt')).to be_truthy
      end

      upload_file('payload.zip', File.read(archive_path))

      notes = @container.archived_files.find_by(file_name: 'notes.txt')
      expect(notes).not_to be_nil
      expect(File.read(notes.retrieval_path)).to eq 'legitimate archive content'

      expect(@container.archived_files.find_by(file_name: 'linked-secret.txt')).to be_nil
    ensure
      FileUtils.rm_rf(archive_source_dir)
      FileUtils.rm_rf(archive_dir)
      File.delete(secret_path) if File.exist?(secret_path)
    end
  end

  it 'does not abort the whole container listing when a symlink has no database record of its own' do
    upload_file('legit.txt', 'legitimate container content')
    container_root = File.dirname(@container.stored_files.last.retrieval_path)

    # Stand-in for a symlink planted directly on disk by some means other than the app's
    # own upload code, so it never went through NfsStore::Archive::Mounter's per-entry
    # extraction handling and has no StoredFile record at all -
    # NfsStore::Manage::StoredFile.index_missing_entry (invoked by NfsStore::Browse
    # #list_files_from for any filesystem entry without a DB record) resolves it via the
    # same guarded retrieval_path, and previously had no rescue around that call.
    secret_path = Rails.root.join('tmp', "secret-#{SecureRandom.hex}.txt").to_s
    File.write(secret_path, 'unauthorized secret content')
    planted_link = File.join(container_root, 'planted-link.txt')

    begin
      File.symlink(secret_path, planted_link)

      listed = nil
      expect do
        listed = NfsStore::Browse.list_files_from(@container, activity_log: @activity_log)
      end.not_to raise_error

      expect(listed.map(&:file_name)).to include('legit.txt')

      planted = listed.find { |f| f.file_name == 'planted-link.txt' }
      expect(planted).not_to be_nil
      expect(planted).not_to be_persisted
      expect(planted.title).to match(/symbolic link/)
    ensure
      File.delete(planted_link) if File.exist?(planted_link) || File.symlink?(planted_link)
      File.delete(secret_path) if File.exist?(secret_path)
    end
  end

  it 'still resolves a legitimate file when the nfs_store root itself is reached via a symlink' do
    upload_file('placeholder.txt', 'legitimate container content')
    stored_file = @container.stored_files.last
    expect(File.read(stored_file.retrieval_path)).to eq 'legitimate container content'

    # Stand-in for a legitimate ops-level indirection (e.g. an NFS mount cutover, or macOS
    # dev machines where /var is itself a symlink to /private/var) - the root being reached
    # via a symlink must NOT be confused with an attacker planting a symlink *below* it.
    real_root = NfsStore::Manage::Filesystem.nfs_store_directory
    symlinked_root = "#{real_root}-symlinked-#{SecureRandom.hex(4)}"

    begin
      File.symlink(real_root, symlinked_root)
      NfsStore::Manage::Filesystem.nfs_store_directory = symlinked_root

      expect(File.read(stored_file.retrieval_path)).to eq 'legitimate container content'
    ensure
      NfsStore::Manage::Filesystem.nfs_store_directory = real_root
      File.delete(symlinked_root) if File.symlink?(symlinked_root)
    end
  end
end
