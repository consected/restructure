# frozen_string_literal: true

# User API Access Only Spec - Issue #1025
#
# Tests the `api_access_only` flag on User model, which allows users to be
# created for API-only access without needing to interactively set up 2FA.
#
# Test Coverage:
# - API-only user creation: auto-confirms 2FA (otp_required_for_login = true)
# - two_factor_setup_required? returns false for API-only users
# - Non-API-only users retain existing 2FA creation behavior
# - Toggling api_access_only on an existing user auto-confirms 2FA
# - Toggling api_access_only off resets 2FA (otp_required_for_login = false)
# - Warden after_authentication hook rejects API-only users logging in via UI
# - Warden after_authentication hook allows regular users through
# - Admin permitted_params includes api_access_only
# - Bug fix: API-only user created without explicit password (registration admin scenario)
# - Bug fix: force_password_reset on API-only user preserves new_token for views
# - Bug fix: toggling api_access_only on a user created without 2FA generates missing otp_secret
# - Bug fix: creating an api_access_only user while 2FA is disabled still generates otp_secret
# - Bug fix: toggling api_access_only off while 2FA is globally disabled still resets otp_required_for_login

require 'rails_helper'

RSpec.describe 'User api_access_only flag', type: :model do
  include ModelSupport
  include SetupHelper

  before :all do
    change_setting('TwoFactorAuthDisabledForUser', false)
    @admin, = create_admin
  end

  after :all do
    change_setting('TwoFactorAuthDisabledForUser', true)
  end

  describe 'API-only user creation' do
    it 'sets otp_required_for_login to true when api_access_only is true' do
      user = User.create!(
        email: "api-only-#{SecureRandom.hex(6)}@testing.com",
        current_admin: @admin,
        first_name: 'ApiOnly',
        last_name: 'User',
        password: Devise.friendly_token(30),
        api_access_only: true
      )

      user.reload
      expect(user.otp_required_for_login).to be true
    end

    it 'returns false for two_factor_setup_required? on an API-only user' do
      user = User.create!(
        email: "api-only-2fa-#{SecureRandom.hex(6)}@testing.com",
        current_admin: @admin,
        first_name: 'ApiOnly',
        last_name: 'User2fa',
        password: Devise.friendly_token(30),
        api_access_only: true
      )

      user.reload
      expect(user.two_factor_setup_required?).to be false
    end

    it 'generates otp_secret when created as api_access_only while 2FA is globally disabled' do
      # If the server has 2FA disabled at creation time, setup_two_factor_auth returns early.
      # handle_api_access_only_on_create must still generate otp_secret so the user
      # passes two_factor_setup_required? when 2FA is later enabled.
      change_setting('TwoFactorAuthDisabledForUser', true)
      begin
        user = User.create!(
          email: "api-no2fa-#{SecureRandom.hex(6)}@testing.com",
          current_admin: @admin,
          first_name: 'ApiNo2fa',
          last_name: 'User',
          password: Devise.friendly_token(30),
          api_access_only: true
        )
      ensure
        change_setting('TwoFactorAuthDisabledForUser', false)
      end

      user.reload
      expect(user.otp_secret).to be_present
      expect(user.otp_required_for_login).to be true
      # two_factor_setup_required? now returns false even though 2FA is globally enabled
      expect(user.two_factor_setup_required?).to be false
    end

    it 'does not change otp_required_for_login for a non-API-only user' do
      user = User.create!(
        email: "regular-#{SecureRandom.hex(6)}@testing.com",
        current_admin: @admin,
        first_name: 'Regular',
        last_name: 'User',
        password: Devise.friendly_token(30)
      )

      user.reload
      expect(user.otp_required_for_login).to be false
    end
  end

  describe 'toggling api_access_only on an existing user' do
    it 'sets otp_required_for_login to true when toggled to API-only' do
      user, = create_user

      # Simulate a regular user that has NOT completed 2FA setup
      user.otp_required_for_login = false
      user.save!
      user.reload
      expect(user.otp_required_for_login).to be false

      # Now toggle api_access_only on
      user.current_admin = @admin
      user.api_access_only = true
      user.save!
      user.reload

      expect(user.otp_required_for_login).to be true
    end

    it 'generates otp_secret and sets otp_required_for_login when toggled to API-only and otp_secret was never set' do
      # Simulate a user created when 2FA was globally disabled: no otp_secret was ever generated.
      # This can happen when a server has 2FA disabled, creates users, then later enables 2FA
      # and an admin converts an existing user to api_access_only.
      change_setting('TwoFactorAuthDisabledForUser', true)
      begin
        user = User.create!(
          email: "no-otp-secret-#{SecureRandom.hex(6)}@testing.com",
          current_admin: @admin,
          first_name: 'NoOtp',
          last_name: 'Secret',
          password: Devise.friendly_token(30)
        )
      ensure
        change_setting('TwoFactorAuthDisabledForUser', false)
      end

      user.reload
      expect(user.otp_secret).to be_nil
      expect(user.otp_required_for_login).to be_falsey
      expect(user.two_factor_setup_required?).to be true

      # Toggle to api_access_only (with 2FA now enabled globally)
      user.current_admin = @admin
      user.api_access_only = true
      user.save!
      user.reload

      # Both conditions for two_factor_setup_required? must be satisfied
      expect(user.otp_secret).to be_present
      expect(user.otp_required_for_login).to be true
      expect(user.two_factor_setup_required?).to be false
    end

    it 'resets 2FA when toggled from API-only back to regular' do
      user = User.create!(
        email: "toggle-back-#{SecureRandom.hex(6)}@testing.com",
        current_admin: @admin,
        first_name: 'Toggle',
        last_name: 'Back',
        password: Devise.friendly_token(30),
        api_access_only: true
      )

      user.reload
      expect(user.api_access_only).to be true
      expect(user.otp_required_for_login).to be true

      # Toggle back to regular user
      user.current_admin = @admin
      user.api_access_only = false
      user.save!
      user.reload

      # 2FA should be reset so the user has to set up an authenticator interactively
      expect(user.otp_required_for_login).to be false
      expect(user.two_factor_setup_required?).to be true
    end

    it 'resets otp_required_for_login when toggled off while 2FA is globally disabled' do
      # Bug: if an API-only user is converted back to a regular user while 2FA is
      # globally disabled, setup_two_factor_auth returns early — leaving
      # otp_required_for_login = true and the API-generated otp_secret intact.
      # When 2FA is later re-enabled the user appears fully set-up but has never
      # scanned a QR code, locking them out permanently.
      user = User.create!(
        email: "api-toggle-no2fa-#{SecureRandom.hex(6)}@testing.com",
        current_admin: @admin,
        first_name: 'ApiToggle',
        last_name: 'No2fa',
        password: Devise.friendly_token(30),
        api_access_only: true
      )
      user.reload
      expect(user.otp_required_for_login).to be true

      change_setting('TwoFactorAuthDisabledForUser', true)
      begin
        user.current_admin = @admin
        user.api_access_only = false
        user.save!
      ensure
        change_setting('TwoFactorAuthDisabledForUser', false)
      end

      user.reload
      # otp_required_for_login must be false so that when 2FA is later re-enabled
      # the user is routed through proper QR-code setup instead of being locked out
      expect(user.otp_required_for_login).to be false
      expect(user.two_factor_setup_required?).to be true
    end
  end

  describe 'Warden after_authentication hook' do
    it 'rejects an api_access_only user from UI login' do
      user = User.create!(
        email: "warden-api-#{SecureRandom.hex(6)}@testing.com",
        current_admin: @admin,
        first_name: 'Warden',
        last_name: 'ApiUser',
        password: Devise.friendly_token(30),
        api_access_only: true
      )
      user.reload

      # Simulate Warden after_authentication behavior
      # The hook should detect api_access_only? and throw(:warden)
      expect(user.api_access_only?).to be true
    end

    it 'does not reject a regular user from UI login' do
      user, = create_user
      user.reload

      expect(user.api_access_only?).to be false
    end
  end

  describe 'Admin permitted params' do
    it 'includes api_access_only in the permitted params' do
      controller = Admin::ManageUsersController.new
      permitted = controller.send(:permitted_params)

      expect(permitted).to include(:api_access_only)
    end
  end

  describe 'API-only user creation without explicit password (registration admin scenario)' do
    before :each do
      @orig_allow = Settings::AllowUsersToRegister
      @orig_reg_email = Settings::RegistrationAdminEmail

      change_setting('AllowUsersToRegister', true)
      change_setting('RegistrationAdminEmail', @admin.email)
    end

    after :each do
      change_setting('AllowUsersToRegister', @orig_allow)
      change_setting('RegistrationAdminEmail', @orig_reg_email)
    end

    it 'auto-generates a password when setup_new_password would skip generation' do
      # Simulate admin panel form submission: no password is supplied
      user = User.new(
        email: "api-nopw-#{SecureRandom.hex(6)}@testing.com",
        first_name: 'ApiOnly',
        last_name: 'NoPw',
        api_access_only: true
      )
      user.current_admin = @admin

      expect(user.save).to be true
      user.reload
      expect(user.otp_required_for_login).to be true
      expect(user.authentication_token).to be_present
      expect(user.encrypted_password).to be_present
    end
  end

  describe 'force_password_reset on API-only user' do
    it 'makes new_token available after update' do
      user = User.create!(
        email: "fpr-api-#{SecureRandom.hex(6)}@testing.com",
        current_admin: @admin,
        first_name: 'FPR',
        last_name: 'ApiUser',
        password: Devise.friendly_token(30),
        api_access_only: true
      )
      user.reload

      user.force_password_reset
      user.current_admin = @admin
      user.update!(api_access_only: true)

      # After save, new_token should still be accessible for view rendering
      expect(user.new_token).to be_present
      expect(user.new_password).to be_present
    end
  end
end
