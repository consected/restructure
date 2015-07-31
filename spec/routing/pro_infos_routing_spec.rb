require "rails_helper"

RSpec.describe ProInfosController, type: :routing do
  let(:object_name) { 'pro_infos' }
  let(:object_path) { 'masters/2/pro_infos'}
  let(:parent_params) { { master_id: '2'} }
  describe "routing" do

    it "routes to #index" do
      expect(:get => "#{object_path}").to route_to("#{object_name}#index", :master_id => "2")
    end

    it "routes to #new" do
      expect(:get => "#{object_path}/new").not_to be_routable
    end

    it "routes to #show" do
      expect(:get => "#{object_path}/1").to route_to("#{object_name}#show", :id => "1", :master_id => "2")
    end

    it "routes to #edit" do
      expect(:get => "#{object_path}/1/edit").not_to be_routable
    end

    it "routes to #create" do
      expect(:post => "#{object_path}").not_to be_routable
    end

    it "routes to #update" do
      expect(:put => "#{object_path}/1").not_to be_routable
    end

    it "routes to #destroy" do
      expect(:delete => "#{object_path}/1").not_to be_routable
    end

  end
end
