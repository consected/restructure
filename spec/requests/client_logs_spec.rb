# frozen_string_literal: true

# These request specs verify that ClientLogsController's CSRF bypass correctly recognizes
# API user_token authentication supplied via the X-User-Token header, not just as a param
# (mirrors the same gap fixed in UserBaseController::MixedStrategy).
require 'rails_helper'

describe 'client logs CSRF protection' do
  include ModelSupport

  before :example do
    ActionController::Base.allow_forgery_protection = true
    @user, = create_user
  end

  after :example do
    ActionController::Base.allow_forgery_protection = false
  end

  it 'bypasses CSRF when user_token is supplied as a param' do
    post '/client_logs.json',
         params: { msg: 'test', user_email: @user.email, user_token: @user.authentication_token }
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq('OK')
  end

  it 'bypasses CSRF when user_token is supplied via the X-User-Token header' do
    post '/client_logs.json',
         params: { msg: 'test' },
         headers: { 'X-User-Email' => @user.email, 'X-User-Token' => @user.authentication_token }
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq('OK')
  end

  it 'prefers an explicit query param token over a header token when both are supplied' do
    # A bad param token must still fail authentication, even with a good header token present.
    post '/client_logs.json',
         params: { msg: 'test', user_email: @user.email, user_token: 'badtoken' },
         headers: { 'X-User-Email' => @user.email, 'X-User-Token' => @user.authentication_token }
    expect(response).to have_http_status(:unauthorized)
  end

  it 'still fails authentication when no user_token is supplied anywhere' do
    # NOTE: this controller's two separate protect_from_forgery calls share a single
    # class-level forgery_protection_strategy, so the :null_session strategy (registered
    # last) is always used for CSRF failures here; the request is instead rejected by
    # authenticate_user! with 401, not a 403 CSRF error. This is pre-existing behaviour,
    # unrelated to the header-vs-param detection fixed above.
    post '/client_logs.json', params: { msg: 'test' }
    expect(response.status).to eq(401)
  end
end
