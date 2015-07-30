require 'set'
shared_examples 'a standard user routing' do
  
  describe "routing" do

    it "routes to #index" do
      expect(:get => "#{object_path}").to route_to("#{object_name}#index", :master_id => "2")
    end

    it "routes to #new" do
      expect(:get => "#{object_path}/new").to route_to("#{object_name}#new", :master_id => "2")
    end

    it "routes to #show" do
      expect(:get => "#{object_path}/1").to route_to("#{object_name}#show", :id => "1", :master_id => "2")
    end

    it "routes to #edit" do
      expect(:get => "#{object_path}/1/edit").to route_to("#{object_name}#edit", :id => "1", :master_id => "2")
    end

    it "routes to #create" do
      expect(:post => "#{object_path}").to route_to("#{object_name}#create", :master_id => "2")
    end

    it "routes to #update" do
      expect(:put => "#{object_path}/1").to route_to("#{object_name}#update", :id => "1", :master_id => "2")
    end

    it "routes to #destroy" do
      expect(:delete => "#{object_path}/1").to route_to("#{object_name}#destroy", :id => "1", :master_id => "2")
    end

  end
end