require "rails_helper"

RSpec.describe CollegesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/colleges").to route_to("colleges#index")
    end

    it "routes to #new" do
      expect(:get => "/colleges/new").to route_to("colleges#new")
    end

    it "routes to #show" do
      expect(:get => "/colleges/1").to route_to("colleges#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/colleges/1/edit").to route_to("colleges#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/colleges").to route_to("colleges#create")
    end

    it "routes to #update" do
      expect(:put => "/colleges/1").to route_to("colleges#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/colleges/1").to route_to("colleges#destroy", :id => "1")
    end

  end
end
