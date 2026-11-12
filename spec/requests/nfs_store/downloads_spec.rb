# frozen_string_literal: true

# Regression coverage for large filestore selections: one JSON parameter must
# bypass Rack's query-parameter count limit while preserving legacy submissions.
require 'rails_helper'

RSpec.describe 'NfsStore downloads selected items (issue #1551)', type: :request do
  include ModelSupport

  before do
    @user, = create_user
    sign_in @user
    allow_any_instance_of(NfsStore::DownloadsController).to receive(:nfs_store_browse_path).and_return('/')
    allow_any_instance_of(NfsStore::Download).to receive(:save!).and_return(true)
  end

  def stub_empty_multi_download(expected_items: nil)
    allow_any_instance_of(NfsStore::Download).to receive(:retrieve_files_from) do |_download, items|
      expect(items).to eq(expected_items) if expected_items
      []
    end
  end

  it "hits Rack's parameter-count limit when thousands of legacy array parameters are posted" do
    encoded_items = Array.new(4_100) do |index|
      value = { id: index + 1, retrieval_type: 'stored_file', container_id: 1 }.to_json
      "nfs_store_download%5Bselected_items%5D%5B%5D=#{CGI.escape(value)}"
    end.join('&')

    headers = { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' }
    post '/nfs_store/downloads/multi', params: encoded_items, headers: headers

    expect(response).to have_http_status(:bad_request)
    expect(response.body).to include('total number of query parameters')
  end

  it 'accepts thousands of selections as a single JSON parameter and normalizes them for download' do
    count = 4_100
    selected_items = Array.new(count) do |index|
      {
        id: index + 1,
        retrieval_type: 'stored_file',
        container_id: 1,
        activity_log_type: 'activity_log__file_test',
        activity_log_id: 2
      }
    end
    expected_first_item = {
      id: 1,
      container_id: 1,
      retrieval_type: :stored_file,
      activity_log_type: 'activity_log__file_test',
      activity_log_id: 2
    }
    expect_any_instance_of(NfsStore::Download).to receive(:retrieve_files_from) do |_download, items|
      expect(items.length).to eq(count)
      expect(items.first).to eq(expected_first_item)
      []
    end

    post '/nfs_store/downloads/multi', params: {
      nfs_store_download: { container_id: 'multi', selected_items_json: selected_items.to_json }
    }

    expect(response).to have_http_status(:found)
  end

  it 'continues to accept the legacy array of JSON strings' do
    expected_items = [
      { id: 12, container_id: 1, retrieval_type: :stored_file, activity_log_type: nil, activity_log_id: 0 }
    ]
    stub_empty_multi_download(expected_items:)

    post '/nfs_store/downloads/multi', params: {
      nfs_store_download: {
        container_id: 'multi',
        selected_items: [{ id: 12, retrieval_type: 'stored_file', container_id: 1 }.to_json]
      }
    }

    expect(response).to have_http_status(:found)
  end

  it 'returns a bad request for malformed or non-object JSON entries instead of a server error' do
    ['{not json', '{"id":12}', '[null]'].each do |selected_items_json|
      post '/nfs_store/downloads/multi', params: {
        nfs_store_download: { container_id: 'multi', selected_items_json: }
      }

      expect(response).to have_http_status(:bad_request)
    end
  end
end

# Purpose: issue #1553 - a single file selected for download is sent as the original file (named by its
# own file_name) rather than a zip, while multiple selected files continue to be zipped. Symlink blocking
# must still apply to the single file path.
RSpec.describe 'NfsStore downloads of a single selected file (issue #1553)', type: :request do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  before :example do
    setup_nfs_store
    setup_container_and_al
    setup_default_filters
    sign_in @user
    allow_any_instance_of(NfsStore::DownloadsController).to receive(:nfs_store_browse_path).and_return('/')
  end

  def selected_item_hash(file_name)
    stored_file = @container.stored_files.find_by(file_name:)
    { id: stored_file.id, retrieval_type: 'stored_file', container_id: @container.id,
      activity_log_type: @activity_log.class.name.ns_underscore, activity_log_id: @activity_log.id }
  end

  def post_multi(*file_names)
    post '/nfs_store/downloads/multi', params: {
      nfs_store_download: { container_id: 'multi', selected_items_json: file_names.map { |name| selected_item_hash(name) }.to_json }
    }
  end

  def zip_entry_names(body)
    names = []
    Zip::InputStream.open(StringIO.new(body)) do |zis|
      while (entry = zis.get_next_entry)
        names << File.basename(entry.name)
      end
    end
    names
  end

  it 'sends a single selected file directly with its own file name, not as a zip' do
    upload_file 'single-direct.txt', 'direct file content'

    post_multi 'single-direct.txt'

    expect(response).to have_http_status(:ok)
    expect(response.headers['Content-Type']).not_to include('zip')
    expect(response.headers['Content-Disposition']).to include('single-direct.txt')
    expect(response.body).to eq 'direct file content'
  end

  it 'sends a single selected file directly when using the download action' do
    upload_file 'single-action.txt', 'action file content'
    stored_file = @container.stored_files.find_by(file_name: 'single-action.txt')

    post '/nfs_store/downloads', params: {
      commit: 'Download',
      nfs_store_download: {
        container_id: @container.id,
        activity_log_type: @activity_log.class.name.ns_underscore,
        activity_log_id: @activity_log.id,
        selected_items_json: [{ id: stored_file.id, retrieval_type: 'stored_file', container_id: @container.id }].to_json
      }
    }

    expect(response).to have_http_status(:ok)
    expect(response.headers['Content-Type']).not_to include('zip')
    expect(response.headers['Content-Disposition']).to include('single-action.txt')
    expect(response.body).to eq 'action file content'
  end

  it 'continues to zip multiple selected files with their original file names' do
    upload_file 'multi-one.txt', 'content one'
    upload_file 'multi-two.txt', 'content two'

    post_multi 'multi-one.txt', 'multi-two.txt'

    expect(response).to have_http_status(:ok)
    expect(response.headers['Content-Type']).to include('zip')
    expect(response.headers['Content-Disposition']).to include("#{@container.name} - 2 files.zip")
    expect(zip_entry_names(response.body)).to contain_exactly('multi-one.txt', 'multi-two.txt')
  end

  it 'blocks a single selected file that has been replaced by a symbolic link' do
    upload_file 'linked-direct.txt', 'legitimate content'
    retrieval_path = @container.stored_files.find_by(file_name: 'linked-direct.txt').retrieval_path
    secret_path = Rails.root.join('tmp', "secret-#{SecureRandom.hex}.txt").to_s
    File.write(secret_path, 'unauthorized secret content')

    begin
      File.delete(retrieval_path)
      File.symlink(secret_path, retrieval_path)

      post_multi 'linked-direct.txt'

      expect(response.body).to eq NfsStore::DownloadsController::SymlinkBlockedMessage
      expect(response.body).not_to include('unauthorized secret content')
    ensure
      FileUtils.rm_f secret_path
    end
  end
end
