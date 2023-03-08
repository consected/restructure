# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NfsStore::Dicom::MetadataHandler, type: :model do
  let :test_file do
    Rails.root.join('spec', 'fixtures', 'files', 'dicom', '000000.dcm').to_s
  end

  let :test_jog_file do
    Rails.root.join('spec', 'fixtures', 'files', 'dicom', 'lossyjpeg.dcm').to_s
  end

  def check_file
    # Check the original file
    orig_dcm = DICOM::DObject.read(test_file)
    orig_dcm = orig_dcm.to_hash

    expect(orig_dcm["Patient's Name"]).not_to be_blank
    expect(orig_dcm['Patient ID']).not_to be_blank
    expect(orig_dcm['Study Date']).not_to be_blank
  end

  it 'Removes metadata from a dicom file using a default set of anonymization tags' do
    check_file

    # Setup and run the anonymization handler
    dh = NfsStore::Dicom::DeidentifyHandler.new file_path: test_file
    tmpfile = dh.send :anonymize

    expect(tmpfile).to be_a String
    dcm = DICOM::DObject.read(tmpfile)
    dcm = dcm.to_hash

    # The original Transfer Syntax UID should still be set
    expect(dcm['Transfer Syntax UID']).to eq DICOM::EXPLICIT_LITTLE_ENDIAN
    expect(dcm["Patient's Name"]).to eq 'Patient'
    expect(dcm['Patient ID']).to eq 'ID'
    expect(dcm['Study Date']).to eq '20000101'
  end

  it 'Removes metadata from a dicom file using a specified set of anonymization tags' do
    check_file

    # Setup and run the anonymization handler
    set_tags = {
      '0010,0010': 'Anon',
      '0008,0020': '20200101'
    }

    delete_tags = ['0010,0020']

    dh = NfsStore::Dicom::DeidentifyHandler.new file_path: test_file
    tmpfile = dh.anonymize_with(set_tags: set_tags, delete_tags: delete_tags)

    expect(tmpfile).to be_a String
    dcm = DICOM::DObject.read(tmpfile)
    dcm = dcm.to_hash

    # The original Transfer Syntax UID should still be set
    expect(dcm['Transfer Syntax UID']).to eq DICOM::EXPLICIT_LITTLE_ENDIAN
    expect(dcm["Patient's Name"]).to eq 'Anon'
    expect(dcm['Patient ID']).to be_nil
    expect(dcm['Study Date']).to eq '20200101'
  end

  it 'retains the Transfer Syntax UID from the original image' do
    check_file

    # Setup and run the anonymization handler
    set_tags = {
      '0010,0010': 'Anon',
      '0008,0020': '20200101'
    }

    delete_tags = ['0010,0020']

    dh = NfsStore::Dicom::DeidentifyHandler.new file_path: test_jog_file
    tmpfile = dh.anonymize_with(set_tags: set_tags, delete_tags: delete_tags)

    expect(tmpfile).to be_a String
    dcm = DICOM::DObject.read(tmpfile)
    dcm = dcm.to_hash

    # The original Transfer Syntax UID should still be set
    expect(dcm['Transfer Syntax UID']).to eq DICOM::TXS_JPEG_BASELINE
    expect(dcm["Patient's Name"]).to eq 'Anon'
    expect(dcm['Patient ID']).to be_nil
    expect(dcm['Study Date']).to eq '20200101'
  end
end
