# frozen_string_literal: true

# Tests for Devise session timeout behavior.
#
# This spec verifies that user sessions correctly expire after the configured
# inactivity timeout period (Settings::UserTimeout).
#
# Run with a short timeout using:
#   app-scripts/test_session_timeout_rspec.sh spec/system/user/user_session_timeout_spec.rb
#
# The test_session_timeout_rspec.sh script sets USER_TIMEOUT_MINS=1 so sessions
# expire after 1 minute of inactivity, making timeout behavior testable.
#
# Key regression: CSP violation reports (sent automatically by the browser) were
# resetting the server-side last_request_at via the Warden after_set_user hook.
# The fix ensures CspReportsController prepends devise.skip_trackable so these
# automatic browser requests don't reset the inactivity timer.
#
# Tests cover:
# - Client-side JS timeout value matches server Settings
# - Server-side Devise timedout? logic
# - Session expiry after inactivity with redirect to login
# - Timeout warning alarm before session expires
# - Session refresh via "Continue working" keeps session alive

require 'rails_helper'

describe 'user session timeout', js: true, driver: $browser_driver do
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
  end

  it 'reports the correct timeout value to the client-side JS' do
    login
    finish_page_loading

    timeout_value = page.evaluate_script('_fpa.status.session && _fpa.status.session.timeout')
    expected_timeout = Settings::UserTimeout.to_i

    expect(timeout_value).to eq(expected_timeout),
                              "Expected client-side timeout to be #{expected_timeout}s " \
                              "(Settings::UserTimeout), got #{timeout_value}s"
  end

  it 'confirms Devise server-side timedout? matches the Settings value' do
    user = User.find(@user.id)
    expected = Settings::UserTimeout

    expect(user.timeout_in).to eq(expected),
                                "User#timeout_in should equal Settings::UserTimeout. " \
                                "Got #{user.timeout_in.inspect}, expected #{expected.inspect}"

    # A time just before the timeout should NOT be timed out
    barely_within = (expected.to_i - 1).seconds.ago
    expect(user.timedout?(barely_within)).to be(false),
                                             "User should NOT be timed out #{expected.to_i - 1}s ago"

    # A time just after the timeout SHOULD be timed out
    just_past = (expected.to_i + 1).seconds.ago
    expect(user.timedout?(just_past)).to be(true),
                                         "User SHOULD be timed out #{expected.to_i + 1}s ago"
  end

  it 'times out the session after inactivity and redirects to login' do
    change_setting('UserTimeout', 1.minute) # Set timeout to 1 minute for testing
    login
    finish_page_loading

    # Disable the client-side JS timer so we can test server-side timeout independently.
    # The JS timer would also redirect but we want to confirm the server enforces it.
    page.execute_script(<<~JS)
      _fpa.status.session.is_counting = false;
      _fpa.status.session.has_ticked = true;
    JS

    # Wait for the server-side timeout to expire
    server_timeout = Settings::UserTimeout.to_i
    wait_time = server_timeout + 15

    sleep wait_time

    # Now try to access a protected page — server should detect expired session
    visit '/masters/search'

    # After timeout, user should be redirected to login page
    expect(page).to have_css('#new_user', wait: 10),
                    "Expected login form after #{wait_time}s inactivity " \
                    "(timeout=#{server_timeout}s). Current URL: #{current_url}"
    expect(current_path).to eq('/users/sign_in')
  end

  it 'shows a timeout warning alarm before session expires' do
    change_setting('UserTimeout', 1.minute) # Set timeout to 1 minute for testing
    login
    finish_page_loading

    alarm_time = page.evaluate_script('_fpa.status.session.alarm_time')
    default_timeout = page.evaluate_script('_fpa.status.session.default_timeout')

    # Wait until alarm should trigger
    alarm_wait = (default_timeout - alarm_time).ceil + 2
    sleep alarm_wait

    expect(page).to have_css('.flash .alert-warning', wait: 5),
                    'Expected timeout warning flash message to appear'
    expect(find('.flash .alert-warning').text).to include('session will time out')
  end

  it 'keeps the session alive when the user clicks Continue Working' do
    change_setting('UserTimeout', 1.minute) # Set timeout to 1 minute for testing
    login
    finish_page_loading

    alarm_time = page.evaluate_script('_fpa.status.session.alarm_time')
    default_timeout = page.evaluate_script('_fpa.status.session.default_timeout')
    alarm_wait = (default_timeout - alarm_time).ceil + 2

    sleep alarm_wait

    # Alarm should be showing
    expect(page).to have_css('.flash .alert-warning', wait: 5),
                    'Expected timeout warning to appear'

    # Click "Continue working" to refresh the session
    within '.flash .alert-warning' do
      click_link 'Continue working'
    end

    sleep 2

    # Session should still be active
    expect(user_logged_in?).to be(true),
                               'User should still be logged in after clicking Continue Working'

    # Wait past half the timeout to verify session was extended
    half_timeout = (Settings::UserTimeout.to_i / 2).ceil
    sleep half_timeout

    expect(user_logged_in?).to be(true),
                               'User should still be logged in after session refresh'
  end

  after(:all) do
    # Clean up
      change_setting('UserTimeout', 30.minutes) # Set timeout back to 30 minutes
  end
end
