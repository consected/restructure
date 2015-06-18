require 'rails_helper'

RSpec.describe "ItemFlagNames", type: :request do
  describe "GET /item_flag_names" do
    it "works! (now write some real specs)" do
      get item_flag_names_path
      expect(response).to have_http_status(200)
    end
  end
end
