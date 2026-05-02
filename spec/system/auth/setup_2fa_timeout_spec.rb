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

    visit '/users/show_otp'
    expect(current_path).to eq('/users/sign_in')
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

# Admin 2FA setup page idle timeout
describe '2FA setup page idle timeout - admin', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  SHORT_TIMEOUT_SECS = 3

  before(:all) do
    change_setting('AllowUsersToRegister', false)
    Rails.application.reload_routes!
    Rails.application.routes_reloader.reload!

    SetupHelper.feature_setup

    # Create admin while 2FA is disabled to simulate upgrade-to-2FA scenario
    change_setting('TwoFactorAuthDisabledForAdmin', true)

    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    @admin_email = "test-setup-2fa-timeout-#{rand(1_000_000_000)}admin@testing.com"
    @admin = Admin.create! email: @admin_email
    @admin = Admin.find(@admin.id)
    @admin_password = @admin.generate_password
    @admin.otp_required_for_login = false
    @admin.new_two_factor_auth_code = false
    @admin.save!
  end

  after(:all) do
    change_setting('TwoFactorAuthDisabledForAdmin', true)
  end

  def reach_admin_2fa_setup_page
    change_setting('TwoFactorAuthDisabledForAdmin', false)

    Capybara.reset_sessions!
    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    expect(page).to have_css('#new_admin', wait: 10)

    within '#new_admin' do
      fill_in 'Email', with: @admin_email
      fill_in 'Password', with: @admin_password
      click_button 'Log in'
    end

    expect(page).to have_css('body.show_otp', wait: 10)
    expect(page).to have_css('#form-validate-otp', wait: 10)
  end

  it 'exposes admin sign-in and sign-out paths on the 2FA setup form' do
    change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

    reach_admin_2fa_setup_page

    setup_form = find('#form-validate-otp', visible: :all)
    expect(setup_form['data-otp-setup-idle-timeout'].to_i).to eq(SHORT_TIMEOUT_SECS)
    expect(setup_form['data-sign-in-path']).to eq('/admins/sign_in'),
                                               "Expected sign-in path to be /admins/sign_in, got #{setup_form['data-sign-in-path'].inspect}"
    expect(setup_form['data-sign-out-path']).to eq('/admins/sign_out'),
                                                "Expected sign-out path to be /admins/sign_out, got #{setup_form['data-sign-out-path'].inspect}"
  end

  it 'signs out and returns to admin sign-in page after setup idle timeout' do
    change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

    reach_admin_2fa_setup_page

    sleep SHORT_TIMEOUT_SECS + 2

    # After timeout the admin is signed out and redirected to /admins/sign_in.
    # However /admins/sign_in requires ?secure_entry=<token> for unauthenticated access
    # (see config/initializers/reopen_devise.rb), so the server further redirects to
    # /users/sign_in. This is expected security behaviour.
    expect(['/admins/sign_in', '/users/sign_in']).to include(current_path),
                                                     "Expected to be redirected to a sign-in page after admin 2FA setup timeout, got #{current_path.inspect}"

    # Verify the admin setup page is no longer accessible without re-authenticating
    visit '/admins/show_otp'
    expect(current_path).not_to eq('/admins/show_otp'),
                                  'Expected /admins/show_otp to redirect away after session timeout'
  end

  it 'does not time out when valid setup OTP is submitted before timeout for admin' do
    change_setting('TwoFactorAuthIdleTimeout', SHORT_TIMEOUT_SECS)

    reach_admin_2fa_setup_page

    @admin.reload
    expect(@admin.otp_secret).to be_present
    expect(@admin.otp_required_for_login).to be(false)

    within '#form-validate-otp' do
      fill_in 'Enter Two-Factor Authentication Code', with: @admin.current_otp
      click_button 'Submit Code'
    end

    expect(page).not_to have_content('Two-Factor Authentication Setup')
    @admin.reload
    expect(@admin.otp_required_for_login).to be(true)
  end
end
