# frozen_string_literal: true

# Tests for client-side idle timeout on the 2FA setup (QR code) page.
#
# This covers the setup flow shown at /users/show_otp when a user has passed
# password login but has not yet completed 2FA enrollment.
#
# Expected behavior:
# - setup page exposes timeout/sign-in/sign-out metadata to JS
# - idle timeout signs out the in-progress session and returns to sign-in
# - submitting a valid OTP before timeout completes setup normally

require 'rails_helper'

describe '2FA setup page idle timeout', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  SHORT_TIMEOUT_SECS = 3

  before(:all) do
    change_setting('AllowUsersToRegister', false)
    Rails.application.reload_routes!
    Rails.application.routes_reloader.reload!

    SetupHelper.feature_setup

    # Create the user while 2FA is disabled to simulate a user upgrading to 2FA.
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)

    @user, @good_password = create_user
    @good_email = @user.email
  end

  after(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
  end

  def reach_2fa_setup_page
    change_setting('TwoFactorAuthDisabledForUser', false)

    Capybara.reset_sessions!
    visit '/users/sign_in'
    expect(page).to have_css('#new_user', wait: 10)

    within '#new_user' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: @good_password
      click_button 'Log in'
    end

    expect(page).to have_css('body.show_otp', wait: 10)
    expect(page).to have_css('#form-validate-otp', wait: 10)
  end

  it 'exposes timeout and auth paths on the 2FA setup form' do
    change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

    reach_2fa_setup_page

    setup_form = find('#form-validate-otp', visible: :all)
    expect(setup_form['data-otp-setup-idle-timeout'].to_i).to eq(SHORT_TIMEOUT_SECS)
    expect(setup_form['data-sign-in-path']).to eq('/users/sign_in')
    expect(setup_form['data-sign-out-path']).to eq('/users/sign_out')
  end

  it 'signs out and returns to sign-in page after setup idle timeout' do
    change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

    reach_2fa_setup_page

    within '#form-validate-otp' do
      fill_in 'Enter Two-Factor Authentication Code', with: '123'
    end

    sleep SHORT_TIMEOUT_SECS + 2

    expect(current_path).to eq('/users/sign_in')
    expect(page).to have_css('#new_user', wait: 10)
  end

  it 'does not time out when valid setup OTP is submitted before timeout' do
    change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

    reach_2fa_setup_page

    @user.reload
    expect(@user.otp_secret).to be_present
    expect(@user.otp_required_for_login).to be(false)

    within '#form-validate-otp' do
      fill_in 'Enter Two-Factor Authentication Code', with: @user.current_otp
      click_button 'Submit Code'
    end

    expect(page).not_to have_content('Two-Factor Authentication Setup')
    @user.reload
    expect(@user.otp_required_for_login).to be(true)
  end
end
