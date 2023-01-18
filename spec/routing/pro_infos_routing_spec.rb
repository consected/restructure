require 'rails_helper'

RSpec.describe ProInfosController, type: :routing do
  let(:object_name) { 'pro_infos' }
  let(:object_path) { 'masters/2/pro_infos' }
  let(:parent_params) { { master_id: '2' } }
  describe 'routing' do
    it 'routes to #index' do
      expect(get: "#{object_path}").to route_to("#{object_name}#index", master_id: '2')
    end

    it 'routes to #new' do
      expect_to_be_bad_route(get: "#{object_path}/new")
    end

    it 'routes to #show' do
      expect(get: "#{object_path}/1").to route_to("#{object_name}#show", id: '1', master_id: '2')
    end

    it 'routes to #edit' do
      expect_to_be_bad_route(get: "#{object_path}/1/edit")
    end

    it 'routes to #create' do
      expect_to_be_bad_route(post: "#{object_path}")
    end

    it 'routes to #update' do
      expect_to_be_bad_route(put: "#{object_path}/1")
    end

    it 'routes to #destroy' do
      expect_to_be_bad_route(delete: "#{object_path}/1")
    end
  end
end
