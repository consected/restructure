# frozen_string_literal: true

require 'rails_helper'

# This spec tests that failed API authentication attempts are logged to the Rails logger
# at warn severity, with appropriate context including request path, HTTP method, and
# failure reason. This helps detect bad credentials, integration mistakes, and probing.

describe 'API authentication failure logging', type: :request do
  include ModelSupport
  include MasterSupport

  before(:all) do
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', false)

    @user, @good_password = create_user(nil, '', create_master: true)
    @user_authentication_token = @user.authentication_token
    expect(@user_authentication_token).to be_present
    @good_email = @user.email
    @good_app_type = @user.app_type_id
  end

  after(:all) do
    # Cleanup
  end

  describe 'failed API authentication attempts' do
    it 'logs a warn message when API request has a bad user_token' do
      # Arrange: Stub Rails.logger to capture warn calls
      allow(Rails.logger).to receive(:warn).and_call_original

      # Act: Make an API request with a bad token
      get '/masters.json',
          params: {
            use_app_type: @good_app_type,
            user_email: @good_email,
            user_token: 'invalid_token_xyz'
          }

      # Assert: Response should be unauthenticated
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to eq 'You need to sign in or sign up before continuing.'

      # Assert: Verify that a warn message was logged
      expect(Rails.logger).to have_received(:warn).with(
        a_string_matching(/API.*authentication.*fail|failed.*API.*auth|invalid.*token|bad.*token/i)
      )
    end

    it 'logs a warn message when API request has a bad user email' do
      # Arrange
      allow(Rails.logger).to receive(:warn).and_call_original

      # Act: Make an API request with a bad email
      get '/masters.json',
          params: {
            use_app_type: @good_app_type,
            user_email: 'nonexistent@example.com',
            user_token: @user_authentication_token
          }

      # Assert: Response should be unauthenticated
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to eq 'You need to sign in or sign up before continuing.'

      # Assert: Verify that a warn message was logged
      expect(Rails.logger).to have_received(:warn).with(
        a_string_matching(/API.*authentication.*fail|failed.*API.*auth|unknown.*user|invalid.*user/i)
      )
    end

    it 'logs a warn message when API request has no user_token' do
      # Arrange
      allow(Rails.logger).to receive(:warn).and_call_original

      # Act: Make an API request with no token
      get '/masters.json',
          params: {
            use_app_type: @good_app_type,
            user_email: @good_email
          }

      # Assert: Response should be unauthenticated
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to eq 'You need to sign in or sign up before continuing.'

      # Assert: Verify that a warn message was logged
      expect(Rails.logger).to have_received(:warn).with(
        a_string_matching(/API.*authentication.*fail|missing.*token|no.*token|unauthenticated/i)
      )
    end

    it 'does not log sensitive tokens in the warn message' do
      # Arrange: Verify filtered params configuration
      expect(Rails.application.config.filter_parameters).to include(:user_token)

      allow(Rails.logger).to receive(:warn).and_call_original

      # Act: Make an API request with a bad token
      bad_token = 'super_secret_bad_token_12345'
      get '/masters.json',
          params: {
            use_app_type: @good_app_type,
            user_email: @good_email,
            user_token: bad_token
          }

      # Assert: Verify that the warn message does not contain the actual token
      expect(Rails.logger).to have_received(:warn) do |message|
        expect(message).not_to include(bad_token)
        expect(message).not_to include('super_secret')
      end
    end

    it 'logs request context in the warn message' do
      # Arrange
      allow(Rails.logger).to receive(:warn).and_call_original

      # Act: Make an API request with a bad token
      get '/masters.json',
          params: {
            use_app_type: @good_app_type,
            user_email: @good_email,
            user_token: 'badtoken'
          }

      # Assert: Verify that context is logged (path, method, email, app_type)
      expect(Rails.logger).to have_received(:warn).with(
        a_string_matching(/masters|GET|#{Regexp.escape(@good_email)}|use_app_type|#{@good_app_type}/)
      )
    end

    it 'does not log warn when API request succeeds with good token' do
      # Arrange
      allow(Rails.logger).to receive(:warn).and_call_original

      # Create a master record for the user so we can query it
      master = create_master(@user)

      # Act: Make an authenticated API request with good token to get a specific master
      get "/masters/#{master.id}.json",
          params: {
            use_app_type: @good_app_type,
            user_email: @good_email,
            user_token: @user_authentication_token
          }

      # Assert: Response should be successful (200 or redirect that succeeds)
      expect([200, 301, 302]).to include(response.status)

      # Assert: Verify that NO warn message related to auth failure was logged
      # (normal request logs are okay, we're just checking for failure-specific warns)
      expect(Rails.logger).not_to have_received(:warn).with(
        a_string_matching(/API.*authentication.*fail|failed.*API.*auth/i)
      )
    end
  end
end
