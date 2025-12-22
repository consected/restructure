# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NfsStore::Dicom::MetadataHandler, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport
  include DicomSupport

  let :test_file do
    Rails.root.join('spec', 'fixtures', 'files', 'dicom', '000000.dcm').to_s
  end

  it 'Extracts metadata from a dicom file' do
    mh = NfsStore::Dicom::MetadataHandler.new file_path: test_file
    res = mh.extract_metadata

    expect(res).to be_a Hash
    expect(res).to have_key('File Meta Information Group Length')
  end

  it 'Raises an error if no file path is given' do
    setup_nfs_store
    upload_test_dicom_files
    expect(@uploaded_files.length).to be > 0
    sf = @uploaded_files.first.stored_file
    expect(File.exist?(sf.retrieval_path)).to be true

    # A new user won't have any of the retrieval roles, allowing the test to trigger the error
    new_user, = create_user
    sf.current_user = new_user
    # Ensure the container gets the new user's roles
    sf.container.current_user = new_user
    sf.container.instance_variable_set(:@current_user_role_names, nil)

    res = NfsStore::Dicom::MetadataHandler.extract_metadata_from sf
    expect(sf.file_metadata).to be_a Hash
    msg = "No file path for Dicom to extract metadata from. User: #{new_user.email} User roles: []"
    expected_res = {
      'fphs_exception' => {
        'status' => 'failed',
        'info' => 'failed to extract DICOM metadata.',
        'exception' => msg
      }
    }
    expect(sf.file_metadata).to eq(expected_res)
  end
end
