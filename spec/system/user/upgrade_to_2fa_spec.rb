# frozen_string_literal: true

# Tests the upgrade path from a server running without 2FA to requiring 2FA.
#
# This spec simulates the scenario where:
# 1. A server has been running with FPHS_2FA_AUTH_DISABLED=true (no 2FA for users or admins)
# 2. Users and admins have been logging in with just email and password
# 3. The server administrator changes the configuration to require 2FA
# 4. On next login, users and admins are prompted to set up 2FA before they can access the app
# 5. After setting up 2FA, subsequent logins require both password and 2FA code
#
# This aligns with the admin documentation in docs/admin_reference/users/upgrade_to_2fa.md
# and the user documentation in docs/guest_reference/main/upgrade_to_2fa.md

require 'rails_helper'

describe 'upgrade server from no 2FA to requiring 2FA', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  context 'user upgrade to 2FA' do
    before(:all) do
      change_setting('AllowUsersToRegister', false)
      Rails.application.reload_routes!
      Rails.application.routes_reloader.reload!

      SetupHelper.feature_setup

      # Start with 2FA disabled, simulating a server that has been running without 2FA
      change_setting('TwoFactorAuthDisabledForUser', true)
      change_setting('TwoFactorAuthDisabledForAdmin', true)

      @user, @good_password = create_user
      @good_email = @user.email
    end

    it 'allows login without 2FA when 2FA is disabled' do
      expect(User.two_factor_auth_disabled).to be true

      visit '/users/sign_in'
      within '#new_user' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      expect(page).to have_css '.flash .alert', text: "×\nSigned in successfully."
    end

    it 'requires 2FA setup and then 2FA login after enabling 2FA on the server' do
      # Step 1: Enable 2FA (simulating server config change)
      change_setting('TwoFactorAuthDisabledForUser', false)
      expect(User.two_factor_auth_disabled).to be false

      # The user was created with 2FA disabled, so they have no OTP secret
      # and otp_required_for_login is false
      @user.reload
      expect(@user.two_factor_setup_required?).to be true

      # Step 2: User logs in with password only
      visit '/users/sign_in'
      within '#new_user' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      # After password verification, user is redirected to the 2FA setup page
      expect(page).to have_content 'Two-Factor Authentication Setup'
      expect(page).to have_css 'img[src^="data:image/png;base64"]'
      expect(page).to have_css '#form-validate-otp'

      # Step 3: User sets up 2FA by entering the code from their authenticator app
      @user.reload
      expect(@user.otp_secret).to be_present
      expect(@user.otp_required_for_login).to be false

      within '#form-validate-otp' do
        fill_in 'Enter Two-Factor Authentication Code', with: @user.current_otp
        click_button 'Submit Code'
      end

      # After successful 2FA setup, user is redirected to the home page
      expect(page).not_to have_content 'Two-Factor Authentication Setup'
      @user.reload
      expect(@user.otp_required_for_login).to be true

      # Step 4: Log out and log back in - now requires 2FA code
      # Wait for TOTP code to cycle so the consumed code is no longer current
      used_otp = @user.current_otp
      sleep 1 until @user.current_otp != used_otp

      Capybara.reset_sessions!

      visit '/users/sign_in'
      within '#new_user' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      # 2FA code prompt should appear on subsequent login
      expect(page).to have_selector('.login-2fa-block', visible: true)

      within '#new_user' do
        fill_in 'Two-Factor Authentication Code', with: @user.current_otp
        click_button 'Log in'
      end

      expect(page).to have_css '.flash .alert', text: "×\nSigned in successfully."
    end

    after(:all) do
      change_setting('TwoFactorAuthDisabledForUser', true)
      change_setting('TwoFactorAuthDisabledForAdmin', true)
    end
  end

  context 'admin upgrade to 2FA' do
    before(:all) do
      SetupHelper.feature_setup

      ENV['FPHS_ADMIN_SETUP'] = 'yes'

      # Start with 2FA disabled
      change_setting('TwoFactorAuthDisabledForUser', true)
      change_setting('TwoFactorAuthDisabledForAdmin', true)

      # Create an admin without 2FA (simulating existing admin on server with 2FA disabled)
      @good_email = "test-2fa-upgrade-#{rand(1_000_000_000)}admin@testing.com"
      @admin = Admin.create! email: @good_email
      @admin = Admin.find(@admin.id)
      @good_password = @admin.generate_password
      # Do not set up OTP - admin was created when 2FA was disabled
      @admin.otp_required_for_login = false
      @admin.new_two_factor_auth_code = false
      @admin.save!
    end

    it 'allows admin login without 2FA when 2FA is disabled' do
      expect(Admin.two_factor_auth_disabled).to be true

      url = "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
      visit url

      within '#new_admin' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      expect(page).to have_css '.flash .alert', text: 'Signed in successfully.'
    end

    it 'requires 2FA setup and then 2FA login after enabling 2FA on the server for admin' do
      # Step 1: Enable 2FA for admins (simulating server config change)
      change_setting('TwoFactorAuthDisabledForAdmin', false)
      expect(Admin.two_factor_auth_disabled).to be false

      # Admin has no OTP secret set up
      @admin.reload
      expect(@admin.two_factor_setup_required?).to be true

      # Step 2: Admin logs in with password
      url = "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
      visit url

      within '#new_admin' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      # After password verification, admin is redirected to the 2FA setup page
      expect(page).to have_content 'Two-Factor Authentication Setup'
      expect(page).to have_css 'img[src^="data:image/png;base64"]'
      expect(page).to have_css '#form-validate-otp'

      # Step 3: Admin sets up 2FA
      @admin.reload
      expect(@admin.otp_secret).to be_present
      expect(@admin.otp_required_for_login).to be false

      within '#form-validate-otp' do
        fill_in 'Enter Two-Factor Authentication Code', with: @admin.current_otp
        click_button 'Submit Code'
      end

      # After successful 2FA setup, admin is redirected away from setup page
      expect(page).not_to have_content 'Two-Factor Authentication Setup'
      @admin.reload
      expect(@admin.otp_required_for_login).to be true

      # Step 4: Log out and log back in - now requires 2FA code
      # Wait for TOTP code to cycle so the consumed code is no longer current
      used_otp = @admin.current_otp
      sleep 1 until @admin.current_otp != used_otp

      Capybara.reset_sessions!

      visit url

      within '#new_admin' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      # 2FA code prompt should appear on subsequent login
      expect(page).to have_selector('.login-2fa-block', visible: true)

      within '#new_admin' do
        fill_in 'Two-Factor Authentication Code', with: @admin.current_otp
        click_button 'Log in'
      end

      finish_page_loading
      if has_css?('.flash .alert', text: 'Signed in successfully.', wait: 2)
        expect(page).to have_css('.flash .alert', text: 'Signed in successfully.')
      else
        expect(current_path).not_to eq '/admins/sign_in'
      end
    end

    after(:all) do
      change_setting('TwoFactorAuthDisabledForUser', true)
      change_setting('TwoFactorAuthDisabledForAdmin', true)
    end
  end
end
