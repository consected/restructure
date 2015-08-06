require "rails_helper"

RSpec.describe DefinitionsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/definitions").not_to be_routable
    end

    it "does not route to #new" do
      expect(:get => "/definitions/new").to route_to("definitions#show", id: 'new')      
    end

    it "does not route to #show" do
      expect(:get => "/definitions/protocol_events").to route_to("definitions#show", id: 'protocol_events')
    end

    it "does not route to #edit" do
      expect(:get => "/definitions/1/edit").not_to be_routable
    end

    it "does not route to #create" do
      expect(:post => "/definitions").not_to be_routable
    end

    it "does not route to #update" do
      expect(:put => "/definitions/1").not_to be_routable
    end

    it "does not route to #destroy" do
      expect(:delete => "/definitions/1").not_to be_routable
    end

  end
end
