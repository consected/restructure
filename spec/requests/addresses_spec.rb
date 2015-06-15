require 'rails_helper'

RSpec.describe "Addresses", type: :request do
  describe "GET /addresses" do
    it "works! (now write some real specs)" do
      get addresses_path
      expect(response).to have_http_status(200)
    end
  end
end
