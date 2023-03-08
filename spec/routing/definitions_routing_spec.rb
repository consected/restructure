require 'rails_helper'

RSpec.describe DefinitionsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect_to_be_bad_route(get: '/definitions')
    end

    it 'does not route to #new' do
      expect(get: '/definitions/new').to route_to('definitions#show', id: 'new')
    end

    it 'does not route to #show' do
      expect(get: '/definitions/protocol_events').to route_to('definitions#show', id: 'protocol_events')
    end

    it 'does not route to #edit' do
      expect_to_be_bad_route(get: '/definitions/1/edit')
    end

    it 'does not route to #create' do
      expect(post: '/definitions').to route_to('definitions#create')
    end

    it 'does not route to #update' do
      expect_to_be_bad_route(put: '/definitions/1')
    end

    it 'does not route to #destroy' do
      expect_to_be_bad_route(delete: '/definitions/1')
    end
  end
end
