require 'rails_helper'

RSpec.describe "ManualInvestigations", type: :request do
  describe "GET /manual_investigations" do
    it "works! (now write some real specs)" do
      get manual_investigations_path
      expect(response).to have_http_status(200)
    end
  end
end
