require "rails_helper"

RSpec.describe ManualInvestigationsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/manual_investigations").to route_to("manual_investigations#index")
    end

    it "routes to #new" do
      expect(:get => "/manual_investigations/new").to route_to("manual_investigations#new")
    end

    it "routes to #show" do
      expect(:get => "/manual_investigations/1").to route_to("manual_investigations#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/manual_investigations/1/edit").to route_to("manual_investigations#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/manual_investigations").to route_to("manual_investigations#create")
    end

    it "routes to #update" do
      expect(:put => "/manual_investigations/1").to route_to("manual_investigations#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/manual_investigations/1").to route_to("manual_investigations#destroy", :id => "1")
    end

  end
end
