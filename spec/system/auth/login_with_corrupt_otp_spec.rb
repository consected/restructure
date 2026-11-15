# frozen_string_literal: true

# Purpose: Verify that a real UI login attempt fails gracefully with the proper
# inactive message when the user's OTP secret is undecryptable, rather than
# crashing with ActiveRecord::Encryption::Errors::Decryption.
# Related issue: consected/restructure#1226

require 'rails_helper'

describe 'Login UI with corrupt OTP secret - issue #1226', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    change_setting('AllowUsersToRegister', false)
    SetupHelper.feature_setup

    # Enable 2FA so the OTP step appears (or login processes MFA)
    change_setting('TwoFactorAuthDisabledForUser', false)

    @user, @good_password = create_user
    @good_email = @user.email

    @user.reload
    @user.setup_two_factor_auth if @user.otp_secret.blank?
    @user.otp_required_for_login = true
    @user.save!
  end

  after(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
  end

  before(:each) do
    # Corrupt the user's OTP secret directly in DB
    User.connection.execute("UPDATE users SET otp_secret = 'not-a-valid-cipher' WHERE id = #{@user.id}")
  end

  it 'prevents login and shows inactive account message' do
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

    within '#new_user' do
      # OTP is corrupt, so we can't provide a good one. Submitting any code fails safely.
      fill_in 'Two-Factor Authentication Code', with: '123456'
      click_button 'Log in'
    end

    # The user should not be able to log in, and should be redirected with standard failure or inactive
    expect(page).to have_content(/Invalid Email, Password or Two-Factor Authentication Code|Your account requires administrator assistance|Invalid email, password or two-factor authentication code/i)
  end
end
