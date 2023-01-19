require 'set'
shared_examples 'a standard user routing' do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: "#{object_path}").to route_to("#{object_name}#index", parent_params)
    end

    it 'routes to #new' do
      expect(get: "#{object_path}/new").to route_to("#{object_name}#new", parent_params)
    end

    it 'routes to #show' do
      expect(get: "#{object_path}/1").to route_to("#{object_name}#show", parent_params.merge(id: '1'))
    end

    it 'routes to #edit' do
      expect(get: "#{object_path}/1/edit").to route_to("#{object_name}#edit", parent_params.merge(id: '1'))
    end

    it 'routes to #create' do
      expect(post: "#{object_path}").to route_to("#{object_name}#create", parent_params)
    end

    it 'routes to #update' do
      expect(put: "#{object_path}/1").to route_to("#{object_name}#update", parent_params.merge(id: '1'))
    end

    it 'routes to #destroy' do
      expect_to_be_bad_route(delete: "#{object_path}/1")
    end
  end
end
