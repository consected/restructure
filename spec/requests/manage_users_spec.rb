require 'rails_helper'

RSpec.describe "ManageUsers", type: :request do
  describe "GET /manage_users" do
    it "works! (now write some real specs)" do
      get manage_users_path
      expect(response).to have_http_status(200)
    end
  end
end
