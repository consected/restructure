# frozen_string_literal: true

# These request specs verify that CSRF failures return the forbidden status while valid tokens
# remain accepted, that API user_token authentication (as a param or as an X-User-Token header)
# correctly bypasses CSRF protection, and that failed API authentication attempts get a
# distinguishing X-ReStructure-Error response header (via ApiAwareFailureApp).
require 'rails_helper'

describe 'csrf protection' do
  include MasterSupport
  include ModelSupport

  def login_user(user = nil)
    user ||= @user || create_user.first
    user.confirmed_at ||= Time.now
    user.current_admin ||= @admin
    user.save
    get '/users/sign_in'
    expect(response.status).to eq 200
    sign_in user
    get '/masters/search'
    expect(response.status).to eq 200

    expect(controller.current_user).to eq user
    let_user_create_master user
    get '/masters/new'
    expect(response.status).to eq 200

    @token = retrieve_authenticity_token
  end

  def retrieve_authenticity_token
    form_authenticity_token || header_authenticity_token ||
      raise('authenticity_token not found in body')
  end

  def put_with_token(path, params, token = nil)
    put path, params: params.merge('authenticity_token' => token || retrieve_authenticity_token), xhr: true
  end

  def post_with_token(path, params, token = nil)
    post path, params: params.merge(authenticity_token: token || retrieve_authenticity_token), xhr: true
  end

  def form_authenticity_token
    regex = /name="authenticity_token" value="(?<token>.+?)"/
    parts = response.body.match(regex)
    parts['token'] if parts
  end

  def header_authenticity_token
    regex = /meta name="csrf-token" content="(?<token>.+?)"/
    parts = response.body.match(regex)
    parts['token'] if parts
  end

  describe 'login and CSRF protection covers actions' do
    before :example do
      ActionController::Base.allow_forgery_protection = true
      @user = create_user(nil, '', create_master: true).first

      @master = create_master
      @token = login_user
    end

    after :example do
      ActionController::Base.allow_forgery_protection = false
    end

    it 'logs in to add a master record' do
      last_master = Master.reorder('').last.id
      expect(controller.current_user.can?(:create_master)).to be_truthy
      expect(@token).not_to be_nil
      expect(@token).to eq retrieve_authenticity_token

      expect(post_with_token('/masters/create', {}, @token)).to be_in [200, 302]
      expect(Master.reorder('').last.id).to be > last_master
    end

    it 'logs in, but fails to add a master record due to missing CSRF token' do
      expect(post_with_token('/masters/create', {}, '')).to eq(403)
      expect(response.headers['X-ReStructure-Error']).to eq('invalid-authenticity-token')
    end

    it 'logs in, but fails to add a master record due to bad CSRF token' do
      expect(post_with_token('/masters/create', {}, "#{retrieve_authenticity_token}1")).to eq(403)
    end

    it 'logs in, and successfully creates a master record' do
      expect(post_with_token('/masters/create', {}, retrieve_authenticity_token)).to eq(302)
    end
  end

  describe 'login and CSRF protection covers MFA lookup requests' do
    before :example do
      ActionController::Base.allow_forgery_protection = true
      @user = create_user(nil, '', create_master: true).first
    end

    after :example do
      ActionController::Base.allow_forgery_protection = false
    end

    it 'attempts to get MFA requirement, but fails due to missing CSRF token' do
      get '/users/sign_in'
      expect(post_with_token('/mfa/step1.json', { resource_type: 'user', user: { email: 'abc', password: 'def' } }, '')).to eq(403)
    end

    it 'attempts to get MFA requirement, and gets a valid response' do
      get '/users/sign_in'
      expect(post_with_token('/mfa/step1.json', { resource_type: 'user', user: { email: 'abc', password: 'def' } }, header_authenticity_token)).to eq(200)
    end

    it 'attempts to get MFA requirement, but fails due to bad CSRF token' do
      get '/users/sign_in'
      expect(post_with_token('/mfa/step1.json', { resource_type: 'user', user: { email: 'abc', password: 'def' } }, "#{retrieve_authenticity_token}1")).to eq(403)
    end
  end

  describe 'API user_token CSRF bypass' do
    before :example do
      ActionController::Base.allow_forgery_protection = true
      @user, = create_user(nil, '', create_master: true)
    end

    after :example do
      ActionController::Base.allow_forgery_protection = false
    end

    it 'bypasses CSRF when user_token is supplied as a query/body param' do
      last_master_id = Master.reorder('').last.id
      post '/masters/create.json',
           params: { master: {}, use_app_type: @user.app_type_id, user_email: @user.email,
                     user_token: @user.authentication_token }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['master']['id']).to be > last_master_id
    end

    it 'bypasses CSRF when user_token is supplied via the X-User-Token header' do
      last_master_id = Master.reorder('').last.id
      post '/masters/create.json',
           params: { master: {}, use_app_type: @user.app_type_id },
           headers: { 'X-User-Email' => @user.email, 'X-User-Token' => @user.authentication_token }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['master']['id']).to be > last_master_id
    end

    it 'prefers an explicit query param token over a header token when both are supplied' do
      # A bad param token must still fail authentication, even with a good header token present,
      # since explicit URL/body params always take precedence over headers.
      post '/masters/create.json',
           params: { master: {}, use_app_type: @user.app_type_id, user_email: @user.email,
                     user_token: 'badtoken' },
           headers: { 'X-User-Email' => @user.email, 'X-User-Token' => @user.authentication_token }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'still fails CSRF when no user_token is supplied anywhere' do
      post '/masters/create.json', params: { master: {}, use_app_type: @user.app_type_id }
      expect(response.status).to eq(403)
    end
  end

  describe 'API authentication failure header' do
    before :example do
      @user, = create_user
    end

    it 'adds X-ReStructure-Error when a bad user_token param was supplied' do
      get '/masters.json', params: { use_app_type: @user.app_type_id, user_email: @user.email, user_token: 'badtoken' }
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['X-ReStructure-Error']).to eq('api-token-authentication-failed')
    end

    it 'adds X-ReStructure-Error when a bad user_token header was supplied' do
      get '/masters.json',
          params: { use_app_type: @user.app_type_id },
          headers: { 'X-User-Email' => @user.email, 'X-User-Token' => 'badtoken' }
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['X-ReStructure-Error']).to eq('api-token-authentication-failed')
    end

    it 'does not add X-ReStructure-Error for an ordinary unauthenticated browser request' do
      get '/masters.json', params: { use_app_type: @user.app_type_id }
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['X-ReStructure-Error']).to be_nil
    end
  end
end
