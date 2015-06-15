require "rails_helper"

RSpec.describe MastersController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/masters").to route_to("masters#index")
    end


    it "routes to #show" do
      expect(:get => "/masters/1").to route_to("masters#show", :id => "1")
    end



  end
end
