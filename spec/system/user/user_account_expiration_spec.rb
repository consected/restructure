# frozen_string_literal: true

# Tests for User account expiration via expire_datetime - Issue #330
#
# This spec verifies the Warden after_set_user hook that checks expire_datetime
# on each request. When a user's expire_datetime has passed, they are logged out
# and shown the "account has expired" message.
#
# Test Coverage:
# - User can login normally when expire_datetime is nil (no expiration set)
# - User can login normally when expire_datetime is in the future
# - User cannot login when expire_datetime is in the past (sees expiration message)
# - Active session is terminated when expire_datetime passes mid-session
# - User can login again after expire_datetime is cleared (set back to nil)
#
# The Warden hook is defined in config/initializers/warden_expire_hook.rb.
# The account_expired? method is defined in app/models/concerns/standard_authentication.rb.
# The flash message is defined in config/locales/devise.en.yml.

require 'rails_helper'

describe 'user account expiration via expire_datetime', js: true, driver: $browser_driver do
  include ModelSupport
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('AllowUsersToRegister', false)
    Rails.application.reload_routes!
    Rails.application.routes_reloader.reload!

    SetupHelper.feature_setup

    @user, @good_password = create_user
    @good_email = @user.email

    # Ensure clean state
    User.where(id: @user.id).update_all(expire_datetime: nil)
  end

  after(:each) do
    # Reset expire_datetime after each test to avoid leaking state
    User.where(id: @user.id).update_all(expire_datetime: nil)
  end

  it 'allows login when expire_datetime is nil' do
    User.where(id: @user.id).update_all(expire_datetime: nil)

    login
    finish_page_loading

    expect(user_logged_in?).to be(true),
                               'User should be logged in when expire_datetime is nil'
  end

  it 'allows login when expire_datetime is in the future' do
    User.where(id: @user.id).update_all(expire_datetime: 1.week.from_now)

    login
    finish_page_loading

    expect(user_logged_in?).to be(true),
                               'User should be logged in when expire_datetime is in the future'
  end

  it 'prevents login when expire_datetime is in the past' do
    User.where(id: @user.id).update_all(expire_datetime: 1.hour.ago)

    visit '/users/sign_in'
    fill_in 'user_email', with: @good_email
    fill_in 'user_password', with: @good_password
    click_button 'Log in'

    expect(page).to have_css('#new_user', wait: 10),
                    'Expected to remain on the login page when account is expired'
    expect(page).to have_content('Your account has expired'),
                    'Expected the account expired flash message'
  end

  it 'terminates an active session when expire_datetime passes' do
    # Ensure no expiration so we can log in
    User.where(id: @user.id).update_all(expire_datetime: nil)

    login
    finish_page_loading

    expect(user_logged_in?).to be(true),
                               'User should be logged in before expiration is set'

    # Set expire_datetime to a few seconds from now
    User.where(id: @user.id).update_all(expire_datetime: 3.seconds.from_now)

    # Wait for the expiration to pass
    sleep 5

    # Navigate to a protected page — the Warden hook should detect expiration
    visit '/masters/search'

    expect(page).to have_css('#new_user', wait: 10),
                    'Expected redirect to login page after expire_datetime passed'
    expect(current_path).to eq('/users/sign_in')
    expect(page).to have_content('Your account has expired'),
                    'Expected the account expired flash message after mid-session expiration'
  end

  it 'allows login again after expire_datetime is cleared' do
    # First, set the account as expired
    User.where(id: @user.id).update_all(expire_datetime: 1.hour.ago)

    visit '/users/sign_in'
    fill_in 'user_email', with: @good_email
    fill_in 'user_password', with: @good_password
    click_button 'Log in'

    expect(page).to have_css('#new_user', wait: 10),
                    'Expected login to be blocked while account is expired'

    # Clear the expiration
    User.where(id: @user.id).update_all(expire_datetime: nil)

    # Now login should succeed
    login
    finish_page_loading

    expect(user_logged_in?).to be(true),
                               'User should be able to login after expire_datetime is cleared'
  end
end
