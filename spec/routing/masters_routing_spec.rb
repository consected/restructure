require "rails_helper"

RSpec.describe MastersController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/masters").to route_to("masters#index")
    end

    it "routes to #search" do
      expect(:get => "/masters/search").to route_to("masters#search")
    end



    it "routes to #show" do
      expect(:get => "/masters/1").to route_to("masters#show", :id => "1")
    end

    it "routes to #new" do
      expect(:get => "/masters/new").to route_to("masters#new")
    end

    it "routes to #create" do
      expect(:post => "/masters/create").to route_to("masters#create")
    end

  end
end
