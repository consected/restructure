require "rails_helper"

RSpec.describe TrackerHistoriesController, type: :routing do
  describe "routing" do
  
    it "routes to #index" do
      expect(:get => "/masters/2/tracker_histories").to route_to("tracker_histories#index", master_id: '2')
    end

    it "routes to #index in tracker" do
      expect(:get => "/masters/2/trackers/3/tracker_histories").to route_to("tracker_histories#index", master_id: '2', tracker_id: '3')
    end
    
    it "does not route to #new" do
      expect(:get => "/masters/2/tracker_histories/new").not_to be_routable
    end

    it "does not route to #show" do
      expect(:get => "/masters/2/tracker_histories/1").not_to be_routable
    end

    it "does not route to #edit" do
      expect(:get => "/masters/2/tracker_histories/1/edit").not_to be_routable
    end

    it "does not route to #create" do
      expect(:post => "/masters/2/tracker_histories").not_to be_routable
    end

    it "does not route to #update" do
      expect(:put => "/masters/2/tracker_histories/1").not_to be_routable
    end

    it "does not route to #destroy" do
      expect(:delete => "/masters/2/tracker_histories/1").not_to be_routable
    end
    
    it "does not route to #new in tracker" do
      expect(:get => "/masters/2/trackers/3/tracker_histories/new").not_to be_routable
    end

    it "does not route to #show in tracker" do
      expect(:get => "/masters/2/trackers/3/tracker_histories/1").not_to be_routable
    end

    it "does not route to #edit in tracker" do
      expect(:get => "/masters/2/trackers/3/tracker_histories/1/edit").not_to be_routable
    end

    it "does not route to #create in tracker" do
      expect(:post => "/masters/2/trackers/3/tracker_histories").not_to be_routable
    end

    it "does not route to #update in tracker" do
      expect(:put => "/masters/2/trackers/3/tracker_histories/1").not_to be_routable
    end

    it "does not route to #destroy in tracker" do
      expect(:delete => "/masters/2/trackers/3/tracker_histories/1").not_to be_routable
    end
  end
end

