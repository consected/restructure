require "rails_helper"

RSpec.describe AddressesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/addresses").to route_to("addresses#index")
    end

    it "routes to #new" do
      expect(:get => "/addresses/new").to route_to("addresses#new")
    end

    it "routes to #show" do
      expect(:get => "/addresses/1").to route_to("addresses#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/addresses/1/edit").to route_to("addresses#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/addresses").to route_to("addresses#create")
    end

    it "routes to #update" do
      expect(:put => "/addresses/1").to route_to("addresses#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/addresses/1").to route_to("addresses#destroy", :id => "1")
    end

  end
end
