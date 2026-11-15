# frozen_string_literal: true

# Tests for client-side idle timeout on the 2FA OTP entry step of the login page.
#
# Issue #1075 - Add client-side timeout to 2FA OTP entry page.
#
# When a user completes step 1 (email + password) and the OTP entry block is revealed,
# a countdown timer begins. If the user does not submit a valid OTP before the timer
# expires, the form silently resets back to step 1 - clearing both the password and OTP
# fields and hiding the 2FA block again.
#
# Key behaviors tested:
# - The timeout timer starts after step 1 completes and the 2FA block is shown
# - After the timeout expires the form returns to step 1 (login-user-password-block visible)
# - After the timeout expires the password field is cleared
# - After the timeout expires the OTP field is cleared
# - After the timeout the user can re-enter credentials normally
# - The timeout duration respects the Settings::TwoFactorAuthIdleTimeout value
# - A successful OTP submission before the timeout completes login normally
# - The timeout only applies while waiting for OTP entry (not after successful login)
#
# The test overrides Settings::TwoFactorAuthIdleTimeout to 3 seconds for fast execution.
# The feature is implemented in app/assets/javascripts/app/_fpa_loaded_login.js.

require 'rails_helper'

describe '2FA OTP idle timeout on login page - issue #1075', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  SHORT_TIMEOUT_SECS = 3

  before(:all) do
    change_setting('AllowUsersToRegister', false)
    Rails.application.reload_routes!
    Rails.application.routes_reloader.reload!

    SetupHelper.feature_setup

    # Enable 2FA so the OTP step appears
    change_setting('TwoFactorAuthDisabledForUser', false)

    @user, @good_password = create_user
    @good_email = @user.email

    # Ensure user has 2FA fully configured
    @user.reload
    @user.setup_two_factor_auth if @user.otp_secret.blank?
    @user.otp_required_for_login = true
    @user.save!
    @user.reload
  end

  after(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
  end

  # ---------------------------------------------------------------------------
  # Helper: navigate to login page, fill in credentials, submit step 1 and wait
  # for the 2FA OTP block to become visible. Does NOT submit the OTP.
  # ---------------------------------------------------------------------------
  def reach_otp_step
    Capybara.reset_sessions!
    visit '/users/sign_in'
    expect(page).to have_css('#new_user')

    within '#new_user' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: @good_password
      click_button 'Log in'
    end

    expect(page).to have_selector('.login-2fa-block', visible: true, wait: 10),
                    'Expected OTP entry block to appear after step 1'
  end

  # ---------------------------------------------------------------------------
  # Group 1 – Basic Timeout Behaviour
  # ---------------------------------------------------------------------------

  context 'basic timeout behaviour' do
    it 'exposes the 2FA idle timeout value from Settings to the client-side JS' do
      # The JS should read Settings::TwoFactorAuthIdleTimeout and store it so
      # the timer knows when to fire.
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_otp_step

      # After the feature is implemented, the timeout value should be available on
      # the login JS state object (analogous to how UserTimeout is exposed).
      timeout_value = page.evaluate_script('_fpa.loaded.login_state && _fpa.loaded.login_state.otp_idle_timeout')

      expect(timeout_value).to eq(SHORT_TIMEOUT_SECS),
                                "Expected client-side otp_idle_timeout to equal " \
                                "Settings::TwoFactorAuthIdleTimeout (#{SHORT_TIMEOUT_SECS}), " \
                                "got #{timeout_value.inspect}"
    end

    it 'resets the form to step 1 after the idle timeout expires' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_otp_step

      # Verify we are on step 2 (OTP block visible, password block hidden)
      expect(page).to have_selector('.login-2fa-block', visible: true)
      expect(page).not_to have_selector('.login-user-password-block', visible: true)

      # Wait for the timeout to expire (add a small buffer)
      sleep SHORT_TIMEOUT_SECS + 2

      # After timeout: password/email block should be visible again (step 1)
      expect(page).to have_selector('.login-user-password-block', visible: true, wait: 5),
                      'Expected login-user-password-block to be visible again after idle timeout'
    end

    it 'hides the 2FA OTP block after the idle timeout expires' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_otp_step

      sleep SHORT_TIMEOUT_SECS + 2

      expect(page).not_to have_selector('.login-2fa-block', visible: true, wait: 5),
                          'Expected login-2fa-block to be hidden after idle timeout reset'
    end

    it 'clears the password field after the idle timeout expires' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_otp_step

      sleep SHORT_TIMEOUT_SECS + 2

      # The password field should be blank after reset
      password_value = find('#user_password', visible: :all).value
      expect(password_value).to be_blank,
                                'Expected password field to be cleared after idle timeout reset'
    end

    it 'clears the OTP field after the idle timeout expires' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_otp_step

      # Type a partial OTP to simulate a user who started but did not finish
      within '#new_user' do
        fill_in 'Two-Factor Authentication Code', with: '123'
      end

      sleep SHORT_TIMEOUT_SECS + 2

      otp_value = find('#user_otp_attempt', visible: :all).value
      expect(otp_value).to be_blank,
                           'Expected OTP field to be cleared after idle timeout reset'
    end

    it 'allows the user to re-enter credentials normally after a timeout reset' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_otp_step

      sleep SHORT_TIMEOUT_SECS + 2

      # Form should be back at step 1 - user can type credentials again
      expect(page).to have_selector('.login-user-password-block', visible: true, wait: 5)

      # Wait for a fresh OTP code
      used_otp = @user.current_otp
      sleep 1 until @user.current_otp != used_otp

      within '#new_user' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      expect(page).to have_selector('.login-2fa-block', visible: true, wait: 10),
                      'Expected OTP block to appear again after re-submitting credentials'

      @user.reload
      within '#new_user' do
        fill_in 'Two-Factor Authentication Code', with: @user.current_otp
        click_button 'Log in'
      end

      expect(page).to have_css('.flash .alert', text: "×\nSigned in successfully.", wait: 10),
                      'Expected successful login after re-entering credentials post-timeout'
    end
  end

  # ---------------------------------------------------------------------------
  # Group 2 – Configurable Timeout via Settings
  # ---------------------------------------------------------------------------

  context 'configurable timeout via Settings::TwoFactorAuthIdleTimeout' do
    it 'has a default value of 300 seconds in DefaultSettings' do
      expect(DefaultSettings::TwoFactorAuthIdleTimeout).to eq(300),
                                                           'Expected default TwoFactorAuthIdleTimeout to be 300 seconds'
    end

    it 'uses the configured timeout duration when overridden' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      expect(Settings::TwoFactorAuthIdleTimeout).to eq(SHORT_TIMEOUT_SECS),
                                                    "Expected TwoFactorAuthIdleTimeout to be #{SHORT_TIMEOUT_SECS}"
    end

    it 'resets the form within the configured short timeout window' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_otp_step

      start_time = Time.now
      sleep SHORT_TIMEOUT_SECS + 2

      # The form should have reset shortly after the configured timeout
      expect(page).to have_selector('.login-user-password-block', visible: true, wait: 3),
                      "Expected form to reset within #{SHORT_TIMEOUT_SECS + 2}s of OTP block appearing"

      elapsed = Time.now - start_time
      expect(elapsed).to be < (SHORT_TIMEOUT_SECS + 5),
                         "Reset took too long: #{elapsed.round(1)}s (timeout=#{SHORT_TIMEOUT_SECS}s)"
    end
  end

  # ---------------------------------------------------------------------------
  # Group 3 – No Timeout When OTP is Submitted Before Timer Expires
  # ---------------------------------------------------------------------------

  context 'no timeout when OTP is submitted before timer expires' do
    it 'does not reset the form when a valid OTP is submitted before the timeout' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_otp_step

      # Submit OTP immediately - before the timer fires
      @user.reload
      within '#new_user' do
        fill_in 'Two-Factor Authentication Code', with: @user.current_otp
        click_button 'Log in'
      end

      # Should navigate away (login success) not reset to step 1
      expect(page).to have_css('.flash .alert', text: "×\nSigned in successfully.", wait: 10),
                      'Expected successful login when OTP submitted before timeout'

      expect(page).not_to have_css('#new_user', wait: 2),
                          'Expected login form to be gone after successful login'
    end

    it 'completes the login session normally without any form reset after successful OTP' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_otp_step

      @user.reload
      within '#new_user' do
        fill_in 'Two-Factor Authentication Code', with: @user.current_otp
        click_button 'Log in'
      end

      expect(page).to have_css('.flash .alert', text: "×\nSigned in successfully.", wait: 10)
      finish_page_loading

      # User should be properly logged in
      expect(user_logged_in?).to be(true),
                                 'User should be logged in after successful OTP submission'
    end
  end

  # ---------------------------------------------------------------------------
  # Group 4 – Settings Integration
  # ---------------------------------------------------------------------------

  context 'Settings integration' do
    it 'Settings::TwoFactorAuthIdleTimeout is defined in app_settings.rb' do
      # This constant must exist and be accessible - it will fail until added
      expect { Settings::TwoFactorAuthIdleTimeout }.not_to raise_error
    end

    it 'Settings::TwoFactorAuthIdleTimeout is included in AppSettingsVars for admin visibility' do
      expect(Settings::AppSettingsVars).to include('TwoFactorAuthIdleTimeout'),
                                           'TwoFactorAuthIdleTimeout should appear in AppSettingsVars so admins can see it'
    end

    it 'the timeout setting can be changed by an admin and takes effect immediately' do
      first_timeout = 3
      second_timeout = 5

      change_setting('TwoFactorAuthIdleTimeout', first_timeout)
      expect(Settings::TwoFactorAuthIdleTimeout).to eq(first_timeout)

      change_setting('TwoFactorAuthIdleTimeout', second_timeout)
      expect(Settings::TwoFactorAuthIdleTimeout).to eq(second_timeout)
    end
  end

  # ---------------------------------------------------------------------------
  # Group 4 – Admin Login OTP Timeout
  # The admin login page has a separate #new_admin form at /admins/sign_in but
  # uses the same JS and the same shared #mfa-step1 timeout block.
  # ---------------------------------------------------------------------------

  context 'admin login OTP timeout' do
    before(:all) do
      change_setting('TwoFactorAuthDisabledForAdmin', false)

      ENV['FPHS_ADMIN_SETUP'] = 'yes'
      @admin_email = "test-2fa-timeout-#{rand(1_000_000_000)}admin@testing.com"
      @admin = Admin.create! email: @admin_email
      @admin = Admin.find(@admin.id)
      @admin_password = @admin.generate_password
      @admin.otp_secret = Admin.generate_otp_secret
      @admin.otp_required_for_login = true
      @admin.new_two_factor_auth_code = false
      @admin.save!
    end

    after(:all) do
      change_setting('TwoFactorAuthDisabledForAdmin', true)
    end

    def reach_admin_otp_step
      Capybara.reset_sessions!
      visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
      expect(page).to have_css('#new_admin', wait: 10)

      within '#new_admin' do
        fill_in 'Email', with: @admin_email
        fill_in 'Password', with: @admin_password
        click_button 'Log in'
      end

      expect(page).to have_selector('.login-2fa-block', visible: true, wait: 10),
                      'Expected OTP entry block to appear for admin after step 1'
    end

    it 'resets the admin form to step 1 after the idle timeout expires' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_admin_otp_step

      expect(page).to have_selector('.login-2fa-block', visible: true)
      expect(page).not_to have_selector('.login-user-password-block', visible: true)

      sleep SHORT_TIMEOUT_SECS + 2

      expect(page).to have_selector('.login-user-password-block', visible: true, wait: 5),
                      'Expected login-user-password-block to be visible again after admin idle timeout'
    end

    it 'clears the admin OTP field after the idle timeout expires' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_admin_otp_step

      within '#new_admin' do
        fill_in 'Two-Factor Authentication Code', with: '123'
      end

      sleep SHORT_TIMEOUT_SECS + 2

      otp_value = find('#admin_otp_attempt', visible: :all).value
      expect(otp_value).to be_blank,
                           'Expected admin OTP field to be cleared after idle timeout reset'
    end

    it 'does not reset the admin form when OTP is submitted before the timeout' do
      change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

      reach_admin_otp_step

      @admin.reload
      within '#new_admin' do
        fill_in 'Two-Factor Authentication Code', with: @admin.current_otp
        click_button 'Log in'
      end

      expect(page).to have_css('.flash .alert', text: "×\nSigned in successfully.", wait: 10),
                      'Expected successful admin login when OTP submitted before timeout'
    end
  end
end
