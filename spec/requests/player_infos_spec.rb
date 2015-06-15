require 'rails_helper'

RSpec.describe "PlayerInfos", type: :request do
  describe "GET /player_infos" do
    it "works! (now write some real specs)" do
      get player_infos_path
      expect(response).to have_http_status(200)
    end
  end
end
