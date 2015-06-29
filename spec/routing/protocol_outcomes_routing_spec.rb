require "rails_helper"

RSpec.describe ProtocolOutcomesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/protocol_outcomes").to route_to("protocol_outcomes#index")
    end

    it "routes to #new" do
      expect(:get => "/protocol_outcomes/new").to route_to("protocol_outcomes#new")
    end

    it "routes to #show" do
      expect(:get => "/protocol_outcomes/1").to route_to("protocol_outcomes#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/protocol_outcomes/1/edit").to route_to("protocol_outcomes#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/protocol_outcomes").to route_to("protocol_outcomes#create")
    end

    it "routes to #update" do
      expect(:put => "/protocol_outcomes/1").to route_to("protocol_outcomes#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/protocol_outcomes/1").to route_to("protocol_outcomes#destroy", :id => "1")
    end

  end
end
