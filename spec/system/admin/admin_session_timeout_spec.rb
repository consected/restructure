# frozen_string_literal: true

# Tests for issue #1345: "Admin session being invalidated during use".
#
# Root cause: ApplicationController#authenticate_user_or_admin! used
# `!current_user && !current_admin`, which short-circuits in Ruby - if current_user
# is truthy, current_admin is never evaluated. Devise's Timeoutable hook only
# refreshes a scope's last_request_at when that scope's user is actually fetched
# via Warden for the current request. Since admins are typically also signed in
# as a matching user, requests going through this shared authentication gate
# never refreshed the *admin* scope's inactivity timer, only the user scope's.
# This was especially significant for XHR requests (such as the "Continue
# working" keep-alive link, GET /pages/version.json via data-remote="true"),
# since ApplicationController#check_temp_passwords and #setup_navs - the only
# other places that touch current_admin - both return early for request.xhr?.
#
# Unlike spec/system/user/user_session_timeout_spec.rb (which only needs one
# Devise scope), these tests sign in as an admin AND its matching user in the
# same browser session, matching the real-world scenario described in the issue.
#
# Tests cover:
# - The admin scope survives past AdminTimeout when only shared/XHR keep-alive
#   requests occur (proving the fix), while the matching user stays logged in.
# - The admin scope still times out on genuine inactivity (negative control,
#   confirming AdminTimeout is actually enforced and our probe detects it).

require 'rails_helper'

describe 'admin session timeout via shared authentication gate', js: true, driver: $browser_driver do
  include ModelSupport
  include FeatureSupport
  include AdminActionsSetup

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('AllowUsersToRegister', false)
    Rails.application.reload_routes!
    Rails.application.routes_reloader.reload!

    SetupHelper.feature_setup
  end

  before(:each) do
    make_an_admin
    create_admin_matching_user
    # admin_sign_in_with_2fa self-heals @good_password to the admin's password if it
    # doesn't match, so capture the matching user's real password before that happens.
    @user_password = @good_password
  end

  after(:each) do
    change_setting('AdminTimeout', 30.minutes)
    change_setting('UserTimeout', 30.minutes)
  end

  # Sign in as the matching user too, joining the already-signed-in admin session.
  #
  # Can't reuse the shared `login` helper here: its `user_logged_in?` guard checks for a
  # generic `.nav a[data-do-action="show-user-options"]` element, which the admin's OWN
  # session already renders (admin panel reuses the same nav component) - so `login` would
  # silently skip submitting the user's credentials entirely, never actually establishing
  # `current_user` alongside `current_admin`. Submit the sign-in form directly instead, and
  # verify success via the :user scope actually appearing in the session store (unambiguous,
  # unlike UI checks that both scopes can satisfy).
  def sign_in_matching_user_too
    @good_password = @user_password
    @user.update!(otp_required_for_login: false) if @user.otp_required_for_login

    visit '/users/sign_in'
    finish_page_loading
    within '#new_user' do
      fill_in 'Email', with: @user.email
      fill_in 'Password', with: @good_password
      click_button 'Log in'
    end
    finish_page_loading

    row = ActiveRecord::SessionStore::Session.order(:id).last
    expect(row&.data && row.data['warden.user.user.session']).to be_present,
                                                                  'matching user sign-in should establish the :user warden scope'
  end


  # Fires the same XHR keep-alive request as the "Continue working" link
  # (GET /pages/version.json, data-remote="true") and returns its HTTP status.
  def keep_alive_ping
    page.execute_script(<<~JS)
      window.__keepAliveStatus = 'pending';
      window.__keepAliveBody = null;
      fetch('/pages/version.json', { headers: { 'X-Requested-With': 'XMLHttpRequest' }, credentials: 'same-origin' })
        .then(function(r) { window.__keepAliveStatus = r.status; return r.text(); })
        .then(function(t) { window.__keepAliveBody = t; })
        .catch(function(e) { window.__keepAliveStatus = 'error'; window.__keepAliveBody = e.toString(); });
    JS

    status = nil
    Timeout.timeout(10) do
      loop do
        status = page.evaluate_script('window.__keepAliveStatus')
        break unless status == 'pending'

        sleep 0.2
      end
    end
    status
  end

  # PagesController#index (the root path) renders the admin panel when current_admin
  # is present, or redirects to masters search when only current_user remains.
  def admin_area_reachable?
    visit '/'
    finish_page_loading
    current_path == '/'
  end

  it 'keeps the admin session alive across AdminTimeout when only shared XHR keep-alive requests occur' do
    admin_timeout = 60
    change_setting('AdminTimeout', admin_timeout.seconds)
    change_setting('UserTimeout', 10.minutes)

    admin_sign_in_with_2fa
    sign_in_matching_user_too

    start = Time.now
    expect(admin_area_reachable?).to be(true), 'admin should be reachable immediately after sign-in'

    # Fire the same XHR keep-alive request the "Continue working" link uses, repeatedly,
    # spanning well past admin_timeout - this only proves the fix if the admin scope's
    # inactivity timer is genuinely being refreshed by these background requests.
    3.times do
      sleep (admin_timeout * 0.7).round
      expect(keep_alive_ping).to eq(200), "keep-alive ping should succeed #{(Time.now - start).round}s since sign-in"
    end

    expect(admin_area_reachable?).to be(true),
                                     "admin session should survive #{(Time.now - start).round}s because keep-alive " \
                                     'requests refreshed its inactivity timer'
  end

  it 'still times out the admin session on genuine inactivity' do
    admin_timeout = 60
    change_setting('AdminTimeout', admin_timeout.seconds)
    change_setting('UserTimeout', 10.minutes)

    admin_sign_in_with_2fa
    sign_in_matching_user_too

    expect(admin_area_reachable?).to be(true)

    sleep admin_timeout + 20

    expect(admin_area_reachable?).to be(false),
                                     'admin session should time out after genuine inactivity beyond AdminTimeout'
  end
end
