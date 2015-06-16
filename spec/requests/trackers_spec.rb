require 'rails_helper'

RSpec.describe "Trackers", type: :request do
  describe "GET /trackers" do
    it "works! (now write some real specs)" do
      get trackers_path
      expect(response).to have_http_status(200)
    end
  end
end
