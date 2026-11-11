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
