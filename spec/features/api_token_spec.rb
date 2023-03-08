# frozen_string_literal: true

require 'rails_helper'

describe 'API tokens and CSRF', js: true, driver: :app_firefox_driver do
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

  def server_url
    "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
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

  after(:all) do
  end
end
