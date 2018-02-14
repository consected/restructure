require "rails_helper"

RSpec.describe PagesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/pages").to route_to("pages#index")
    end

    it "does not route to #show" do
      expect(:get => "/pages/1").to route_to("pages#show")
    end

    it "does not route to #new" do
      expect(:get => "/pages/new").to route_to("pages#show")
    end

    it "does not route to #edit" do
      expect(:get => "/pages/1/edit").not_to be_routable
    end

    it "does not route to #create" do
      expect(:post => "/pages").not_to be_routable
    end

    it "does not route to #update" do
      expect(:put => "/pages/1").not_to be_routable
    end

    it "does not route to #destroy" do
      expect(:delete => "/pages/1").not_to be_routable
    end

  end
end
