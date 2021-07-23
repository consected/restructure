# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NfsStore::Archive::Mounter, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport
  include DicomSupport

  def default_role
    'file1'
  end

  def do_dicom_test_uploads; end

  before :each do
    seed_database && ::ActivityLog.define_models

    @other_users = []
    @other_users << create_user.first
    @other_users << create_user.first
    @other_users << create_user.first

    setup_nfs_store
    @activity_log = @container.parent_item

    upload_test_dicom_files

    f = 'dicoms.zip'
    zip_content = File.read(dicom_file_path(f))
    @zip_file = upload_file(f, zip_content)

    expect(@uploaded_files.length).to be > 2
  end

  it 'uploads a file that is not an archive format and ignores it' do
    sf = @uploaded_files.first.stored_file
    expect(NfsStore::Archive::Mounter.has_archive_extension?(sf)).to be false
    expect(NfsStore::Archive::Mounter.mount(sf)).to eq :not_archive
  end

  it 'uploads a file that is archive format and extracts it' do
    sf = @zip_file.stored_file
    mounter = NfsStore::Archive::Mounter.new
    mounter.stored_file = sf

    expect(mounter.temp_mounted_path).to end_with '/.tmp-dicoms.zip.__mounted-archive__'
    expect(NfsStore::Archive::Mounter.has_archive_extension?(sf)).to be true
    expect(mounter.mount).to be_truthy
    expect(mounter.archive_file_count).to eq 11
  end

  it 'indicates a failure if the incorrect number of files are extracted' do
    tmpzipdir = Dir.mktmpdir
    f = 'dicoms.zip'
    archive_path = dicom_file_path(f)

    # Start by successfully extracting the file using the bash script
    cmd = ['app-scripts/extract_archive.sh', archive_path, tmpzipdir]
    res = Kernel.system(*cmd)
    expect(res).to be_truthy

    FileUtils.rm_f File.join(tmpzipdir, '000005.dcm')

    cmd = ['app-scripts/extract_archive.sh', archive_path, tmpzipdir]
    res = Kernel.system(*cmd)
    expect(res).to be_falsey

    # Now remove all files but leave the directory
    10.times do |i|
      FileUtils.rm_f File.join(tmpzipdir, "00000#{i}.dcm")
    end
    FileUtils.rm_f File.join(tmpzipdir, '000010.dcm')

    cmd = ['app-scripts/extract_archive.sh', archive_path, tmpzipdir]
    res = Kernel.system(*cmd)
    expect(res).to be_truthy
  end

  it 'handles split zip files' do
    tmpzipdir = Dir.mktmpdir
    f = 'split.zip'
    archive_path = dicom_file_path(f)

    # Start by successfully extracting the file using the bash script
    cmd = ['app-scripts/extract_archive.sh', archive_path, tmpzipdir]
    res = Kernel.system(*cmd)
    expect(res).to be_truthy
  end

  it 'indicates a failure if a zip is broken' do
    # Start by testing a file that has a changed byte
    tmpzipdir = Dir.mktmpdir
    f = 'broken.zip'
    archive_path = dicom_file_path(f)

    cmd = ['app-scripts/extract_archive.sh', archive_path, tmpzipdir]
    res = Kernel.system(*cmd)
    expect(res).to be_falsey

    # If a split zip file is missing a part, fail
    tmpzipdir = Dir.mktmpdir
    f = 'broken-split.zip'
    archive_path = dicom_file_path(f)

    # Start by successfully extracting the file using the bash script
    cmd = ['app-scripts/extract_archive.sh', archive_path, tmpzipdir]
    res = Kernel.system(*cmd)
    expect(res).to be_falsey

    
  end


  it 'uploads a file that is archive format but does nothing if it is marked with status "in process"' do
    sf = @zip_file.stored_file
    mounter = NfsStore::Archive::Mounter.new
    mounter.stored_file = sf
    mounter.extract_in_progress!
    expect(mounter.extract_in_progress?).to be true
    expect(NfsStore::Archive::Mounter.has_archive_extension?(sf)).to be true
    expect(mounter.mount).to be_nil
    expect(mounter.extract_in_progress?).to be true
  end

  it 'processes an archive marked with status "in process", because it is outside the timeout period' do
    sf = @zip_file.stored_file
    mounter = NfsStore::Archive::Mounter.new
    mounter.stored_file = sf
    # Simulate a broken extract
    mounter.extract_in_progress!
    expect(mounter.extract_in_progress?).to be true
    Dir.glob('*', base: mounter.mounted_path).each do |f|
      FileUtils.rm_f(File.join(mounter.mounted_path, f))
    end
    expect(mounter.archive_file_count).to eq 0
    expect(NfsStore::Archive::Mounter::ProcessingRetryTime).to eq 34.minutes
    FileUtils.touch mounter.processing_archive_flag_path, mtime: Time.now - NfsStore::Archive::Mounter::ProcessingRetryTime - 10.seconds
    expect(mounter.extract_in_progress?).to be false
    expect(NfsStore::Archive::Mounter.has_archive_extension?(sf)).to be true
    expect(mounter.mount).to be_truthy
    expect(mounter.archive_file_count).to eq 11
    expect(mounter.extract_in_progress?).to be false
  end
end
