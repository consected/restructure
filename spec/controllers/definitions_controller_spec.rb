# frozen_string_literal: true

# Purpose: verify definition responses are cached against definition and user data versions.

require 'rails_helper'

describe DefinitionsController, type: :controller do
  include MasterSupport
  include ControllerMacros

  describe 'when not authenticated' do
    it 'should require user login' do
      get :show, params:  { id: 'protocol_events' }, xhr: true
      expect(response).to have_http_status(302)
      expect(response).to redirect_to '/users/sign_in'
    end
  end

  describe 'when authenticated' do
    before_each_login_user
    before(:each) do
      @definitions_controller = DefinitionsController.new
    end

    after(:each) do
      User.reset_latest_update
    end

    it 'should get latest protocol_events' do
      get :show, params:  { id: 'protocol_events' }, xhr: true

      expect(response).to have_http_status(:success)
      j = response.parsed_body
      expect(j).to be_a Array
      expect(j.length).to eq Classification::ProtocolEvent.enabled.length
    end

    it 'refreshes a definition response when the shared definition token changes' do
      id = "protocol_events-cache-token-#{SecureRandom.hex(4)}"
      allow(controller).to receive(:get_def).and_return([{ version: 'before' }], [{ version: 'after' }])

      get :show, params: { id: }, xhr: true
      expect(response.parsed_body).to eq([{ 'version' => 'before' }])

      Dynamic::DefinitionCacheVersion.rotate!
      get :show, params: { id: }, xhr: true

      expect(response.parsed_body).to eq([{ 'version' => 'after' }])
    end

    it 'refreshes the users definition response when a user is added' do
      id = "users-cache-token-#{SecureRandom.hex(4)}"
      get :show, params: { id: }, xhr: true
      expect(response.parsed_body).to include(hash_including('id' => @user.id, 'name' => @user.email))

      new_email = "cache-token-#{SecureRandom.hex(4)}@example.com"
      new_user = User.create!(
        current_admin: Admin.active.first!,
        email: new_email,
        first_name: 'Cache',
        last_name: 'Version',
        password: Devise.friendly_token(30)
      )

      get :show, params: { id: }, xhr: true

      expect(response.parsed_body).to include(hash_including('id' => new_user.id, 'name' => new_email))
    end

    it 'should not get an unexpected item' do
      get :show, params:  { id: 'new' }, xhr: true
      expect(response).to have_http_status(404)
    end
  end

  describe 'show that Brakeman security warning is not an issue' do
    before_each_login_user
    it 'attempts to force use of an invalid definition type' do
      get :show, params:  { id: 'addresses' }, xhr: true
      expect(response).to have_http_status(404)
      get :show, params:  { id: '&something' }, xhr: true
      expect(response).to have_http_status(404)
      get :show, params:  { id: '123654' }, xhr: true
      expect(response).to have_http_status(404)
    end
  end
end
