require 'rails_helper'

RSpec.describe "Imports", type: :request do
  describe "GET /imports" do
    it "works! (now write some real specs)" do
      get imports_path
      expect(response).to have_http_status(200)
    end
  end
end
