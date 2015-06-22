require 'rails_helper'

RSpec.describe "GeneralSelections", type: :request do
  describe "GET /general_selections" do
    it "works! (now write some real specs)" do
      get general_selections_path
      expect(response).to have_http_status(200)
    end
  end
end
