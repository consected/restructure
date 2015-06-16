require 'rails_helper'

RSpec.describe "Protocols", type: :request do
  describe "GET /protocols" do
    it "works! (now write some real specs)" do
      get protocols_path
      expect(response).to have_http_status(200)
    end
  end
end
