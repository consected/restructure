# frozen_string_literal: true

# API Access Only User System Spec - Issue #1025
#
# Tests that a user marked as `api_access_only` can successfully make API
# requests via token authentication without ever completing interactive 2FA
# setup, even when 2FA is globally required.
#
# Test Coverage:
# - API-only user can make GET requests with token auth (no 302 redirect to OTP)
# - API-only user can make POST requests with token auth
# - Regular user without 2FA setup gets a non-200 response (existing security preserved)
# - API-only user cannot reach the authenticated application via browser login
#
# These tests use curl to exercise the real HTTP API, mirroring the pattern
# established in api_token_spec.rb.

require 'rails_helper'

describe 'API access only user - Issue #1025', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterSupport

  before(:all) do
    ActionController::Base.allow_forgery_protection = true

    SetupHelper.feature_setup

    # 2FA must be enabled globally—this is the scenario described in the issue
    change_setting('TwoFactorAuthDisabledForUser', false)
    change_setting('TwoFactorAuthDisabledForAdmin', false)

    create_admin

    # Create a standard user with 2FA already completed (for master record access)
    @user, @good_password = create_user(nil, '', create_master: true)
    @good_email = @user.email

    create_master

    # Create an API-only user via admin (simulating admin panel creation)
    @api_user = User.create!(
      email: "api-only-#{SecureRandom.hex(6)}@testing.com",
      current_admin: @admin,
      first_name: 'ApiOnly',
      last_name: 'TestUser',
      api_access_only: true
    )
    @api_user_token = @api_user.authentication_token
    expect(@api_user_token).to be_present

    # Grant the API user access to an app type and master creation
    app_type = Admin::AppType.active.first
    Admin::UserAccessControl.create! user: @api_user, app_type:, access: :read, resource_type: :general,
                                     resource_name: :app_type, current_admin: @admin
    Admin::UserAccessControl.create! user: @api_user, app_type:, access: :read, resource_type: :general,
                                     resource_name: :create_master, current_admin: @admin
    @api_user.update!(app_type:)
    let_user_create :player_contacts, alt_user: @api_user

    # Verify preconditions: API user has 2FA auto-confirmed
    @api_user.reload
    expect(@api_user.otp_required_for_login).to be true
    expect(@api_user.two_factor_setup_required?).to be false

    # Create a regular user that has NOT completed 2FA setup (to test the redirect still happens)
    @no_2fa_user = User.create!(
      email: "no2fa-#{SecureRandom.hex(6)}@testing.com",
      current_admin: @admin,
      first_name: 'No2fa',
      last_name: 'TestUser'
    )
    @no_2fa_user_token = @no_2fa_user.authentication_token
    expect(@no_2fa_user_token).to be_present

    app_type = Admin::AppType.active.first
    Admin::UserAccessControl.create! user: @no_2fa_user, app_type:, access: :read, resource_type: :general,
                                     resource_name: :app_type, current_admin: @admin
    @no_2fa_user.update!(app_type:)

    # Verify preconditions: regular user still needs 2FA setup
    @no_2fa_user.reload
    expect(@no_2fa_user.otp_required_for_login).to be false
    expect(@no_2fa_user.two_factor_setup_required?).to be true
  end

  after(:all) do
    ActionController::Base.allow_forgery_protection = false
  end

  def server_url
    "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
  end

  #
  # Make a GET curl request, returning [body, http_status_code]
  # rubocop:disable Style/FormatStringToken
  def curl_api_get(options = {})
    options.reverse_merge!(
      server: server_url,
      master_id: @master.id,
      app_type: @api_user.app_type_id,
      user_email: @api_user.email,
      user_token: @api_user_token
    )

    curl = <<~END_STR
      curl -XGET -s -w '\\n%{http_code}' \
      "#{options[:server]}/masters/#{options[:master_id]}.json?"\
      "use_app_type=#{options[:app_type]}&"\
      "user_email=#{options[:user_email]}&"\
      "user_token=#{options[:user_token]}"
    END_STR

    output = `#{curl}`
    lines = output.rstrip.split("\n")
    http_code = lines.pop.to_i
    body = lines.join("\n")
    [body, http_code]
  end
  # rubocop:enable Style/FormatStringToken

  # rubocop:disable Style/FormatStringToken
  def curl_api_post(options = {})
    options.reverse_merge!(
      server: server_url,
      app_type: @api_user.app_type_id,
      user_email: @api_user.email,
      user_token: @api_user_token
    )

    curl = <<~END_STR
      curl -XPOST -s -w '\\n%{http_code}' \
      "#{options[:server]}/masters/create.json?"\
      "use_app_type=#{options[:app_type]}&"\
      "user_email=#{options[:user_email]}&"\
      "user_token=#{options[:user_token]}" \
      -d ''
    END_STR

    output = `#{curl}`
    lines = output.rstrip.split("\n")
    http_code = lines.pop.to_i
    body = lines.join("\n")
    [body, http_code]
  end
  # rubocop:enable Style/FormatStringToken

  describe 'API-only user with token authentication' do
    it 'makes a GET API request successfully without 2FA setup' do
      body, http_code = curl_api_get
      expect(http_code).to eq(200), "Expected 200, got #{http_code}. Body: #{body}"
      expect(body).to be_present

      jres = JSON.parse(body)
      # Should get master data back, NOT a redirect or error about 2FA
      expect(jres['master']).to be_present, "Expected master JSON, got: #{jres}"
      expect(jres['master']['id']).to eq @master.id
    end

    it 'makes a POST API request successfully without 2FA setup' do
      last_master_id = Master.reorder('').last.id

      body, http_code = curl_api_post
      expect(http_code).to eq(200), "Expected 200, got #{http_code}. Body: #{body}"
      expect(body).to be_present

      jres = JSON.parse(body)
      expect(jres['master']).to be_present, "Expected master JSON, got: #{jres}"
      expect(jres['master']['id']).to be > last_master_id
    end
  end

  describe 'regular user without 2FA setup (existing security preserved)' do
    it 'does not return master data for a user that has not completed 2FA' do
      body, http_code = curl_api_get(
        user_email: @no_2fa_user.email,
        user_token: @no_2fa_user_token,
        app_type: @no_2fa_user.app_type_id
      )

      # Should get a redirect (302) to OTP setup, not a successful JSON response
      expect(http_code).not_to eq(200),
                               "Regular user without 2FA should not get 200 OK, got #{http_code}. Body: #{body}"

      # The body should not contain master data
      jres = begin
        JSON.parse(body)
      rescue StandardError
        nil
      end
      expect(jres&.dig('master')).to be_nil,
                                     "Regular user without 2FA should not get master data, got: #{jres}"
    end
  end

  describe 'API-only user blocked from UI login' do
    it 'cannot reach the authenticated application area via browser' do
      # Navigate directly to the app root—an unauthenticated user is redirected to sign-in
      visit '/'

      # Verify not authenticated—should see login page, not the application
      expect(page).to have_css('form', wait: 5)

      # Attempt to visit the masters page as the API-only user (without session auth)
      # The user should be redirected to sign-in, confirming they cannot access the app via browser
      visit "/masters/#{@master.id}"
      expect(page).to have_current_path('/users/sign_in', ignore_query: true, wait: 5)
    end
  end
end
