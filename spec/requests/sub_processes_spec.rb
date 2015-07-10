require 'rails_helper'

RSpec.describe "SubProcesses", type: :request do
  describe "GET /sub_processes" do
    it "works! (now write some real specs)" do
      get sub_processes_path
      expect(response).to have_http_status(200)
    end
  end
end
