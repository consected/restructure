require "rails_helper"

RSpec.describe ProInfosController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/pro_infos").to route_to("pro_infos#index")
    end

    it "routes to #new" do
      expect(:get => "/pro_infos/new").to route_to("pro_infos#new")
    end

    it "routes to #show" do
      expect(:get => "/pro_infos/1").to route_to("pro_infos#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/pro_infos/1/edit").to route_to("pro_infos#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/pro_infos").to route_to("pro_infos#create")
    end

    it "routes to #update" do
      expect(:put => "/pro_infos/1").to route_to("pro_infos#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/pro_infos/1").to route_to("pro_infos#destroy", :id => "1")
    end

  end
end
