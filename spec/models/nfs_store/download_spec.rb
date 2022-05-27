# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

RSpec.describe NfsStore::Download, type: :model do
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

  it 'finds a download using a path rather than an id' do
    file_name = 'test-path-download.txt'
    upload_file file_name, 'text content'

    expect(@container.stored_files.last.file_name).to eq file_name

    download_path = file_name
    res = NfsStore::Download.find_download_by_path(download_path)
    expect(res).to be_a NfsStore::Manage::StoredFile
    expect(res.retrieval_type).to eq :stored_file
    expect(res.id).to eq @container.stored_files.last.id
  end
end
