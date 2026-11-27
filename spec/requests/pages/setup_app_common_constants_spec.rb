# frozen_string_literal: true

# Request specs for the non-sensitive common constants embedded in the application setup script.
# They ensure only the deliberate browser-safe subset is exposed to client-side substitutions.

require 'rails_helper'

RSpec.describe 'Application setup common constants', type: :request do
  include ModelSupport

  before do
    @admin, = create_admin
    @user, = create_user
    sign_out :user
    @user.confirmed_at ||= Time.current
    @user.current_admin ||= @admin
    @user.save!

    get '/users/sign_in'
    expect(response).to have_http_status(:ok)
    sign_in @user
  end

  it 'does not expose common constants on the signed-out sign-in page' do
    sign_out :user
    get '/users/sign_in'

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('_fpa.state.common_constants')
    expect(response.body).not_to include(Settings::AdminEmail)
  end

  it 'embeds the allowlisted common constants and excludes sensitive settings' do
    get '/masters/search'

    expect(response).to have_http_status(:ok)
    serialized_constants = response.body.match(/_fpa\.state\.common_constants\s*=\s*(\{.*?\});/m)&.captures&.first
    expect(serialized_constants).to be_present, 'expected common constants in _setup_app.html.erb output'

    constants = JSON.parse(serialized_constants)
    expected_constants = %w[
      base_url environment_name admin_email default_logo user_session_timeout allow_users_to_register
    ]
    expect(constants.keys).to match_array(expected_constants)
    expect(constants).not_to have_key('invitation_code')
    expect(constants.keys.grep(/password|invitation|secret|token/i)).to be_empty
    expect(constants['base_url']).to eq(Settings::BaseUrl)
    expect(constants['environment_name']).to eq(Settings::EnvironmentName)
    expect(constants['admin_email']).to eq(Settings::AdminEmail)
    expect(constants['default_logo']).to eq(Settings::DefaultLogo)
    expect(constants['user_session_timeout']).to eq(Settings::UserTimeout.to_i / 60)
  end
end
