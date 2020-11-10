# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NfsStore::Dicom::MetadataHandler, type: :model do
  let :test_file do
    Rails.root.join('spec', 'fixtures', 'files', 'dicom', '000000.dcm').to_s
  end

  it 'Extracts metadata from a dicom file' do
    mh = NfsStore::Dicom::MetadataHandler.new file_path: test_file
    res = mh.extract_metadata

    expect(res).to be_a Hash
  end
end
