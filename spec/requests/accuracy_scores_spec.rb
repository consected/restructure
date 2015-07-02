require 'rails_helper'

RSpec.describe "AccuracyScores", type: :request do
  describe "GET /accuracy_scores" do
    it "works! (now write some real specs)" do
      get accuracy_scores_path
      expect(response).to have_http_status(200)
    end
  end
end
