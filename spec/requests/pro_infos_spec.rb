require 'rails_helper'

RSpec.describe "ProInfos", type: :request do
  describe "GET /pro_infos" do
    it "works! (now write some real specs)" do
      get pro_infos_path
      expect(response).to have_http_status(200)
    end
  end
end
