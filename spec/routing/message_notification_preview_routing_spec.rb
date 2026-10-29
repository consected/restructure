# frozen_string_literal: true

# Purpose: Ensure the message-notification preview exposes only the nested GET show route.

require 'rails_helper'

RSpec.describe 'Message notification preview routing', type: :routing do
  it 'routes the nested GET show action' do
    expect(get: '/masters/3/message_notifications/7').to route_to(
      'messaging/message_notifications#show', master_id: '3', id: '7'
    )
  end

  it 'does not expose a collection index route' do
    expect_to_be_bad_route(get: '/masters/3/message_notifications')
  end

  it 'does not expose create, update, or destroy routes' do
    expect_to_be_bad_route(post: '/masters/3/message_notifications')
    expect_to_be_bad_route(patch: '/masters/3/message_notifications/7')
    expect_to_be_bad_route(put: '/masters/3/message_notifications/7')
    expect_to_be_bad_route(delete: '/masters/3/message_notifications/7')
  end
end
