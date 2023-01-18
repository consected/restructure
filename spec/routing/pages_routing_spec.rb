require 'rails_helper'

RSpec.describe PagesController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/pages').to route_to('pages#index')
    end

    it 'does not route to #show' do
      expect(get: '/pages/1').to route_to('pages#show', id: '1')
    end

    it 'does not route to #new' do
      expect(get: '/pages/new').to route_to('pages#show', id: 'new')
    end

    it 'does not route to #edit' do
      expect_to_be_bad_route(get: '/pages/1/edit')
    end

    it 'does not route to #create' do
      expect_to_be_bad_route(post: '/pages')
    end

    it 'does not route to #update' do
      expect_to_be_bad_route(put: '/pages/1')
    end

    it 'does not route to #destroy' do
      expect_to_be_bad_route(delete: '/pages/1')
    end
  end
end
