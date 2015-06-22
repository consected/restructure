require "rails_helper"

RSpec.describe GeneralSelectionsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/general_selections").to route_to("general_selections#index")
    end

    it "routes to #new" do
      expect(:get => "/general_selections/new").to route_to("general_selections#new")
    end

    it "routes to #show" do
      expect(:get => "/general_selections/1").to route_to("general_selections#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/general_selections/1/edit").to route_to("general_selections#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/general_selections").to route_to("general_selections#create")
    end

    it "routes to #update" do
      expect(:put => "/general_selections/1").to route_to("general_selections#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/general_selections/1").to route_to("general_selections#destroy", :id => "1")
    end

  end
end
