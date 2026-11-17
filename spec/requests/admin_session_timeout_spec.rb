# frozen_string_literal: true

require 'rails_helper'

# Regression tests for #1345: "Admin session being invalidated during use".
#
# Root cause: ApplicationController#authenticate_user_or_admin! used
# `!current_user && !current_admin`, which short-circuits in Ruby: if
# current_user is truthy, current_admin is never evaluated. Devise's
# Timeoutable hook (Warden::Manager.after_set_user) only refreshes a scope's
# last_request_at when that scope's user is actually fetched via Warden for
# the current request. Since admins are typically also signed in as a
# matching user, requests going through this shared authentication gate never
# refreshed the *admin* scope's inactivity timer, only the user scope's.
#
# This is especially significant for XHR requests (such as the "Continue
# working" keep-alive link, which hits GET /pages/version.json via
# data-remote="true"), because ApplicationController#check_temp_passwords
# - the only other place in the shared before_action chain that touches
# current_admin - returns early for request.xhr? without evaluating either
# helper. So for XHR requests, authenticate_user_or_admin! was the *only*
# code path that could refresh the admin scope's timer, and the short-circuit
# bug meant it never did so whenever a matching current_user was present.
#
# The fix evaluates both current_user and current_admin unconditionally.
describe 'admin session timeout via shared authentication gate', type: :request do
  include UserSupport

  before do
    @admin, = create_admin(with_matching_user: true)
    @user = User.find_by(email: @admin.email)
    expect(@user).to be_a(User)
  end

  it 'calls current_admin (not just current_user) when authenticating a shared XHR request, so the admin scope inactivity timer is refreshed' do
    sign_in @admin
    sign_in @user

    # For an XHR request, check_temp_passwords and setup_navs both return early without
    # touching current_admin, so authenticate_user_or_admin! is the only remaining code path
    # in the before_action chain that can invoke current_admin and let Devise's Timeoutable
    # hook refresh the admin scope's last_request_at. This mirrors the "Continue working"
    # keep-alive request (GET /pages/version.json, data-remote="true").
    expect_any_instance_of(PagesController).to receive(:current_admin).at_least(:once).and_call_original

    get '/pages/version.json', xhr: true
    expect(response).to have_http_status(:success)
  end
end
