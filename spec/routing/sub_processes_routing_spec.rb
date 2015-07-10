require "rails_helper"

RSpec.describe SubProcessesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/sub_processes").to route_to("sub_processes#index")
    end

    it "routes to #new" do
      expect(:get => "/sub_processes/new").to route_to("sub_processes#new")
    end

    it "routes to #show" do
      expect(:get => "/sub_processes/1").to route_to("sub_processes#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/sub_processes/1/edit").to route_to("sub_processes#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/sub_processes").to route_to("sub_processes#create")
    end

    it "routes to #update" do
      expect(:put => "/sub_processes/1").to route_to("sub_processes#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/sub_processes/1").to route_to("sub_processes#destroy", :id => "1")
    end

  end
end
