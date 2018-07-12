require 'rails_helper'

RSpec.describe "FileStorageResources", type: :request do
  describe "GET /file_storage_resources" do
    it "works! (now write some real specs)" do
      get file_storage_resources_path
      expect(response).to have_http_status(200)
    end
  end
end
