require "rails_helper"

RSpec.describe ProtocolEventsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/protocol_events").to route_to("protocol_events#index")
    end

    it "routes to #new" do
      expect(:get => "/protocol_events/new").to route_to("protocol_events#new")
    end

    it "routes to #show" do
      expect(:get => "/protocol_events/1").to route_to("protocol_events#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/protocol_events/1/edit").to route_to("protocol_events#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/protocol_events").to route_to("protocol_events#create")
    end

    it "routes to #update" do
      expect(:put => "/protocol_events/1").to route_to("protocol_events#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/protocol_events/1").to route_to("protocol_events#destroy", :id => "1")
    end

  end
end
