# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe SecureView::ImagePreviewer, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  def default_role
    'file1'
  end

  before :example do
    @other_users = []
    @other_users << create_user.first
    @other_users << create_user.first
    @other_users << create_user.first

    setup_nfs_store
    setup_container_and_al
    setup_default_filters
  end

  # Helper method to reduce repetition
  def test_file_preview(file_name, file_content, expected_previewable)
    upload_file(file_name, file_content)

    res = NfsStore::Download.find_download_by_path(@container, file_name)
    expect(res).to be_a NfsStore::Manage::StoredFile
    expect(res.retrieval_type).to eq :stored_file
    expect(res.id).to eq @container.stored_files.last.id

    rp = res.retrieval_path
    secure_view_previewer = SecureView::ImagePreviewer.new path: rp.to_s

    return secure_view_previewer if expected_previewable.nil?

    expect(secure_view_previewer.previewable?).to eq expected_previewable
  end

  it 'checks if a file is previewable' do
    # Binary file - not previewable
    test_file_preview('test-path-download.bin', 'binary content', false)

    # PDF file - previewable
    test_file_preview('test-path-download.pdf', '%PDF-1.4 test pdf content', true)

    # PowerPoint file - previewable
    pptx_content = File.read('spec/fixtures/files/secure_view/sample.pptx')
    previewer = test_file_preview('test-path-download.pptx', pptx_content, true)
  end
end
