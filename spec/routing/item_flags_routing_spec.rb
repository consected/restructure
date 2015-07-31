require "rails_helper"

RSpec.describe ItemFlagsController, type: :routing do
  describe "player info flags" do
    let(:object_name) { 'item_flags' }
    let(:object_path) { 'masters/3/player_infos/2/item_flags'}
    let(:parent_params) { {master_id: '3', item_id: '2', item_controller: 'player_infos'} }
    
    
    it "routes to #index" do
      expect(:get => "#{object_path}").to route_to("#{object_name}#index", parent_params)
    end

    it "routes to #new" do
      expect(:get => "#{object_path}/new").to route_to("#{object_name}#new", parent_params)
    end

    it "routes to #show" do
      expect(:get => "#{object_path}/1").to route_to("#{object_name}#show", parent_params.merge(:id => "1") )
    end

    it "routes to #edit" do
      expect(:get => "#{object_path}/1/edit").not_to be_routable
    end

    it "routes to #create" do
      expect(:post => "#{object_path}/4").to route_to("#{object_name}#create", parent_params.merge(:id=>'4'))
    end

    it "routes to #update" do
      expect(:put => "#{object_path}/1").not_to be_routable
    end

    it "routes to #destroy" do
      expect(:delete => "#{object_path}/1").not_to be_routable
    end
  end
end
