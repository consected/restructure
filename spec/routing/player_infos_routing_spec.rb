require "rails_helper"

RSpec.describe PlayerInfosController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/player_infos").to route_to("player_infos#index")
    end

    it "routes to #new" do
      expect(:get => "/player_infos/new").to route_to("player_infos#new")
    end

    it "routes to #show" do
      expect(:get => "/player_infos/1").to route_to("player_infos#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/player_infos/1/edit").to route_to("player_infos#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/player_infos").to route_to("player_infos#create")
    end

    it "routes to #update" do
      expect(:put => "/player_infos/1").to route_to("player_infos#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/player_infos/1").to route_to("player_infos#destroy", :id => "1")
    end

  end
end
