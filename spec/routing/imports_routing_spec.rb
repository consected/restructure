require 'rails_helper'

RSpec.describe Imports::ImportsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/imports/imports').to route_to('imports/imports#index')
    end

    it 'routes to #new' do
      expect(get: '/imports/imports/new').to route_to('imports/imports#new')
    end

    it 'routes to #show' do
      expect(get: '/imports/imports/1').to route_to('imports/imports#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/imports/imports/1/edit').to route_to('imports/imports#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/imports/imports').to route_to('imports/imports#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/imports/imports/1').to route_to('imports/imports#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/imports/imports/1').to route_to('imports/imports#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/imports/imports/1').to route_to('imports/imports#destroy', id: '1')
    end
  end
end
