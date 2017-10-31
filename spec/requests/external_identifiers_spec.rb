require 'rails_helper'

RSpec.describe "ExternalIdentifiers", type: :request do
  describe "GET /external_identifiers" do
    it "works! (now write some real specs)" do
      get external_identifiers_path
      expect(response).to have_http_status(200)
    end
  end
end
