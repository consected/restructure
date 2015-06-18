require "rails_helper"

RSpec.describe ItemFlagNamesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/item_flag_names").to route_to("item_flag_names#index")
    end

    it "routes to #new" do
      expect(:get => "/item_flag_names/new").to route_to("item_flag_names#new")
    end

    it "routes to #show" do
      expect(:get => "/item_flag_names/1").to route_to("item_flag_names#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/item_flag_names/1/edit").to route_to("item_flag_names#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/item_flag_names").to route_to("item_flag_names#create")
    end

    it "routes to #update" do
      expect(:put => "/item_flag_names/1").to route_to("item_flag_names#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/item_flag_names/1").to route_to("item_flag_names#destroy", :id => "1")
    end

  end
end
