require 'rails_helper'

RSpec.describe "Masters", type: :request do
  describe "GET /masters" do
    it "works! (now write some real specs)" do
      get masters_path
      expect(response).to have_http_status(200)
    end
  end
end
