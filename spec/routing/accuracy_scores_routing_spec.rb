require "rails_helper"

RSpec.describe AccuracyScoresController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/accuracy_scores").to route_to("accuracy_scores#index")
    end

    it "routes to #new" do
      expect(:get => "/accuracy_scores/new").to route_to("accuracy_scores#new")
    end

    it "routes to #show" do
      expect(:get => "/accuracy_scores/1").to route_to("accuracy_scores#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/accuracy_scores/1/edit").to route_to("accuracy_scores#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/accuracy_scores").to route_to("accuracy_scores#create")
    end

    it "routes to #update" do
      expect(:put => "/accuracy_scores/1").to route_to("accuracy_scores#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/accuracy_scores/1").to route_to("accuracy_scores#destroy", :id => "1")
    end

  end
end
