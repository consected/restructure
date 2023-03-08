require 'rails_helper'

RSpec.describe TrackerHistoriesController, type: :routing do
  describe 'direct routing' do
    it 'routes to #index' do
      expect(get: '/masters/3/tracker_histories').to route_to('tracker_histories#index', { master_id: '3' })
    end

    it 'does not route to #new' do
      expect_to_be_bad_route(get: '/masters/3/tracker_histories/new')
    end

    it 'does not route to #show' do
      expect_to_be_bad_route(get: '/masters/3/tracker_histories/1')
    end

    it 'does not route to #edit' do
      expect_to_be_bad_route(get: '/masters/3/tracker_histories/1/edit')
    end

    it 'does not route to #create' do
      expect_to_be_bad_route(post: '/masters/3/tracker_histories')
    end

    it 'does not route to #update' do
      expect_to_be_bad_route(put: '/masters/3/tracker_histories/1')
    end

    it 'does not route to #destroy' do
      expect_to_be_bad_route(delete: '/masters/3/tracker_histories/1')
    end
  end

  describe 'nested routing' do
    it 'routes to #index' do
      expect(get: '/masters/3/trackers/2/tracker_histories').to route_to('tracker_histories#index', { master_id: '3', tracker_id: '2' })
    end

    it 'does not route to #new' do
      expect_to_be_bad_route(get: '/masters/3/trackers/2/tracker_histories/new')
    end

    it 'does not route to #show' do
      expect_to_be_bad_route(get: '/masters/3/trackers/2/tracker_histories/1')
    end

    it 'does not route to #edit' do
      expect_to_be_bad_route(get: '/masters/3/trackers/2/tracker_histories/1/edit')
    end

    it 'does not route to #create' do
      expect_to_be_bad_route(post: '/masters/3/trackers/2/tracker_histories')
    end

    it 'does not route to #update' do
      expect_to_be_bad_route(put: '/masters/3/trackers/2/tracker_histories/1')
    end

    it 'does not route to #destroy' do
      expect_to_be_bad_route(delete: '/masters/3/trackers/2/tracker_histories/1')
    end
  end
end
