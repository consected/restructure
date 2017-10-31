require "rails_helper"

RSpec.describe ExternalIdentifiersController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/external_identifiers").to route_to("external_identifiers#index")
    end

    it "routes to #new" do
      expect(:get => "/external_identifiers/new").to route_to("external_identifiers#new")
    end

    it "routes to #show" do
      expect(:get => "/external_identifiers/1").to route_to("external_identifiers#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/external_identifiers/1/edit").to route_to("external_identifiers#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/external_identifiers").to route_to("external_identifiers#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/external_identifiers/1").to route_to("external_identifiers#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/external_identifiers/1").to route_to("external_identifiers#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/external_identifiers/1").to route_to("external_identifiers#destroy", :id => "1")
    end

  end
end
