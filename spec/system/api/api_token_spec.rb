# frozen_string_literal: true

# These specs make real curl requests against the running test server to verify API token
# authentication and CSRF bypass, both via query params (user_email/user_token) and via the
# native X-User-Email/X-User-Token headers, plus that explicit query params take precedence
# over headers when both are supplied. Also verifies the X-ReStructure-Error response header
# is actually sent on the wire (not just visible via Rack::Test in request specs) when API
# credentials were supplied but rejected, and absent otherwise.
require 'rails_helper'

describe 'API tokens and CSRF', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterSupport

  before(:all) do
    ActionController::Base.allow_forgery_protection = true

    SetupHelper.feature_setup

    change_setting('TwoFactorAuthDisabledForUser', false)
    change_setting('TwoFactorAuthDisabledForAdmin', false)

    # create a user, then disable it
    @d_user, @d_pw = create_user(rand(100_000_000..1_099_999_999))
    expect(@d_user).to be_a User
    expect(@d_user.id).to equal @user.id
    @d_email = @d_user.email
    create_admin
    @d_user.current_admin = @admin
    @d_user.send :setup_two_factor_auth
    @d_user.new_two_factor_auth_code = false
    @d_user.otp_required_for_login = true
    @d_user.disabled = true
    @d_user.save!
    expect(@d_user.active_for_authentication?).to be false

    @user, @good_password = create_user(nil, '', create_master: true)
    expect(@user_authentication_token).to be_present
    @good_email = @user.email
    create_master
  end

  after(:all) do
    ActionController::Base.allow_forgery_protection = false
  end

  def curl_api_get_request(options = nil)
    options ||= {}
    options.reverse_merge! server: server_url,
                           master_id: @master.id,
                           app_type: @user.app_type_id,
                           user_email: @user.email,
                           user_token: @user_authentication_token
    curl = <<~END_STR
      curl -XGET -s \
      "#{options[:server]}/masters/#{options[:master_id]}.json?"\
      "use_app_type=#{options[:app_type]}&"\
      "user_email=#{options[:user_email]}&"\
      "user_token=#{options[:user_token]}"
    END_STR

    `#{curl}`
  end

  def curl_api_post_request(options = nil, form = nil)
    options ||= {}
    form ||= {}
    options.reverse_merge! server: server_url,
                           master_id: @master.id,
                           app_type: @user.app_type_id,
                           user_email: @user.email,
                           user_token: @user_authentication_token

    extras = form.map { |k, v| "-F #{k}=#{v}" }.join(' ')

    curl = <<~END_STR
      curl -XPOST -s \
      "#{options[:server]}/masters/create.json?"\
      "use_app_type=#{options[:app_type]}&"\
      "user_email=#{options[:user_email]}&"\
      "user_token=#{options[:user_token]}" \
      -d '' #{extras}
    END_STR
    `#{curl}`
  end

  # Header-based equivalents of the two curl helpers above (X-User-Email / X-User-Token),
  # per the native simple_token_authentication contract, as an alternative to query params.
  def curl_api_get_request_with_headers(options = nil)
    options ||= {}
    options.reverse_merge! server: server_url,
                           master_id: @master.id,
                           app_type: @user.app_type_id,
                           user_email: @user.email,
                           user_token: @user_authentication_token

    header_args = []
    header_args << %(-H "X-User-Email: #{options[:user_email]}") if options[:user_email]
    header_args << %(-H "X-User-Token: #{options[:user_token]}") if options[:user_token]

    curl = <<~END_STR
      curl -XGET -s #{header_args.join(' ')} \
      "#{options[:server]}/masters/#{options[:master_id]}.json?use_app_type=#{options[:app_type]}"
    END_STR

    `#{curl}`
  end

  def curl_api_post_request_with_headers(options = nil, form = nil)
    options ||= {}
    form ||= {}
    options.reverse_merge! server: server_url,
                           master_id: @master.id,
                           app_type: @user.app_type_id,
                           user_email: @user.email,
                           user_token: @user_authentication_token

    header_args = []
    header_args << %(-H "X-User-Email: #{options[:user_email]}") if options[:user_email]
    header_args << %(-H "X-User-Token: #{options[:user_token]}") if options[:user_token]
    extras = form.map { |k, v| "-F #{k}=#{v}" }.join(' ')

    curl = <<~END_STR
      curl -XPOST -s #{header_args.join(' ')} \
      "#{options[:server]}/masters/create.json?use_app_type=#{options[:app_type]}" \
      -d '' #{extras}
    END_STR
    `#{curl}`
  end

  def server_url
    "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
  end

  # Returns just the response headers (via curl -D -) for a GET request, so specs can assert
  # on the X-ReStructure-Error header without disturbing the existing body-only helpers above.
  def curl_api_get_request_response_headers(options = nil)
    options ||= {}
    options.reverse_merge! server: server_url,
                           master_id: @master.id,
                           app_type: @user.app_type_id,
                           user_email: @user.email,
                           user_token: @user_authentication_token

    header_args = []
    header_args << %(-H "X-User-Email: #{options[:user_email]}") if options[:user_email]
    header_args << %(-H "X-User-Token: #{options[:user_token]}") if options[:user_token]

    curl = <<~END_STR
      curl -XGET -s -D - -o /dev/null #{header_args.join(' ')} \
      "#{options[:server]}/masters/#{options[:master_id]}.json?use_app_type=#{options[:app_type]}"
    END_STR

    `#{curl}`
  end

  it 'makes a curl request without an API token' do
    res = curl_api_get_request user_token: nil
    expect(res).to be_present
    jres = JSON.parse(res)
    expect(jres['error']).to eq 'You need to sign in or sign up before continuing.'
  end

  it 'makes a curl request with bad API token' do
    res = curl_api_get_request user_token: 'badtoken'
    expect(res).to be_present
    jres = JSON.parse(res)
    expect(jres['error']).to eq 'You need to sign in or sign up before continuing.'
  end

  it 'makes a GET curl request with good API token' do
    res = curl_api_get_request
    expect(res).to be_present
    jres = JSON.parse(res)
    expect(jres['master']['id']).to eq @master.id
  end

  it 'makes a POST curl request with API token, avoiding CSRF checks' do
    last_master_id = Master.reorder('').last.id
    res = curl_api_post_request
    expect(res).to be_present

    jres = JSON.parse(res)
    expect(jres['master']['id']).to be > last_master_id
  end

  it 'makes a curl request without an API token in headers' do
    res = curl_api_get_request_with_headers(user_token: nil)
    expect(res).to be_present
    jres = JSON.parse(res)
    expect(jres['error']).to eq 'You need to sign in or sign up before continuing.'
  end

  it 'makes a curl request with bad API token in headers' do
    res = curl_api_get_request_with_headers(user_token: 'badtoken')
    expect(res).to be_present
    jres = JSON.parse(res)
    expect(jres['error']).to eq 'You need to sign in or sign up before continuing.'
  end

  it 'makes a GET curl request with good API token supplied only in headers' do
    res = curl_api_get_request_with_headers
    expect(res).to be_present
    jres = JSON.parse(res)
    expect(jres['master']['id']).to eq @master.id
  end

  it 'makes a POST curl request with API token in headers, avoiding CSRF checks' do
    last_master_id = Master.reorder('').last.id
    res = curl_api_post_request_with_headers
    expect(res).to be_present

    jres = JSON.parse(res)
    expect(jres['master']['id']).to be > last_master_id
  end

  it 'prefers an explicit query param token over a header token when both are supplied' do
    # Bad token in the query param should fail authentication, even with a good token
    # supplied in the header, since explicit URL params always take precedence.
    curl = <<~END_STR
      curl -XGET -s \
      -H "X-User-Email: #{@user.email}" \
      -H "X-User-Token: #{@user_authentication_token}" \
      "#{server_url}/masters/#{@master.id}.json?"\
      "use_app_type=#{@user.app_type_id}&"\
      "user_email=#{@user.email}&"\
      "user_token=badtoken"
    END_STR
    res = `#{curl}`
    expect(res).to be_present
    jres = JSON.parse(res)
    expect(jres['error']).to eq 'You need to sign in or sign up before continuing.'
  end

  it 'sends X-ReStructure-Error header on the wire when a bad token is supplied in headers' do
    headers = curl_api_get_request_response_headers(user_token: 'badtoken')
    expect(headers).to match(/^X-ReStructure-Error: api-token-authentication-failed/i)
  end

  it 'does not send X-ReStructure-Error header on the wire when no credentials are supplied' do
    headers = curl_api_get_request_response_headers(user_email: nil, user_token: nil)
    expect(headers).not_to match(/^X-ReStructure-Error:/i)
  end

  it 'does not send X-ReStructure-Error header on the wire for a successful request' do
    headers = curl_api_get_request_response_headers
    expect(headers).not_to match(/^X-ReStructure-Error:/i)
  end

  after(:all) do
  end
end
