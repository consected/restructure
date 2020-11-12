require 'set'
shared_examples 'a standard admin routing' do

  describe "routing" do

    let(:target_path) {
      if object_path.include? '/admin/'
        return object_path.split('/').select{|n| !n.blank?}.join('/')
      else
        return object_name
      end
    }

    it "routes to #index" do
      expect(:get => "#{object_path}").to route_to("#{target_path}#index", parent_params)
    end

    it "routes to #new" do
      expect(:get => "#{object_path}/new").to route_to("#{target_path}#new", parent_params)
    end

    it "routes to #show" do
      expect(:get => "#{object_path}/1").not_to be_routable #route_to("#{object_path}#show", parent_params.merge(:id => "1"))
    end

    it "routes to #edit" do
      expect(:get => "#{object_path}/1/edit").to route_to("#{target_path}#edit", parent_params.merge(:id => "1"))
    end

    it "routes to #create" do
      expect(:post => "#{object_path}").to route_to("#{target_path}#create", parent_params)
    end

    it "routes to #update" do
      expect(:put => "#{object_path}/1").to route_to("#{target_path}#update", parent_params.merge(:id => "1"))
    end

    it "routes to #destroy" do
      expect(:delete => "#{object_path}/1").not_to be_routable
    end

  end
end
