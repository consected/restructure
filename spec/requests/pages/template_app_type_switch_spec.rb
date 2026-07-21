# frozen_string_literal: true

# Request spec for the concrete app-type-switch race described in issue #1287.
#
# This is the end-to-end regression that the controller spec cannot provide:
# it captures the real token V_A that was embedded in the HTML of an actual
# page response, then switches the persisted user to app type B WITHOUT
# rendering a new page, and finally fetches /pages/V_A/template — exactly the
# sequence that caused browser cache-poisoning before the fix.
#
# Why this spec is necessary (and why the controller spec is not sufficient):
#   - spec/controllers/pages_controller_spec.rb proves the local conditional
#     branches (synthetic tokens, no real HTTP stack).
#   - spec/system/user/template_version_cache_poisoning_spec.rb proves the
#     browser-level headers via fetch() but uses logout/login to make the token
#     stale (a different staleness trigger).
#   - This spec reproduces the ORIGINAL bug sequence: the token encodes
#     app_type_A.id; after the DB row is switched to app_type_B the token is
#     stale because template_version now encodes B.  Without the fix the server
#     would still return immutable with B's content under A's URL.
#
# Why a request spec (not a system spec) for this scenario:
#   Capybara's Selenium driver uses a separate Puma process whose DB connections
#   are independent of the test connection, causing a cross-process deadlock or
#   30 s script timeout when the server tries to render the template partial for
#   a newly-created, unconfigured app type.  In a request spec the controller
#   action and test setup share the same in-process connection, so no deadlock
#   occurs and the render completes quickly.
#
# Examples:
#   - Token V_A + user still on app-type A → Cache-Control includes immutable
#   - Token V_A + user switched to app-type B → Cache-Control includes no-store,
#     excludes immutable

require 'rails_helper'

RSpec.describe 'PagesController#template app-type-switch race (issue #1287)', type: :request do
  include ModelSupport

  before(:each) do
    @admin, = create_admin
    @user, = create_user
    @app_type_a = @user.app_type

    sign_out :user
    @user.confirmed_at ||= Time.now
    @user.current_admin ||= @admin
    @user.save

    get '/users/sign_in'
    expect(response.status).to eq 200
    sign_in @user
  end

  # Extract the template_version token embedded by _setup_app.html.erb:
  #   _fpa.state.template_version = '<%= template_version %>';
  # This is the same token the browser reads and later uses as the URL token
  # in its deferred AJAX GET /pages/:id/template request.
  def embedded_template_version
    get '/masters/search'
    expect(response.status).to eq 200
    match = response.body.match(/_fpa\.state\.template_version\s*=\s*'([a-f0-9]{64})'/)
    expect(match).to be_present, 'expected _fpa.state.template_version to be embedded in the page HTML'
    match[1]
  end

  describe 'positive path (no switch)' do
    it 'returns Cache-Control with immutable and max-age=604800 for the current token' do
      token_a = embedded_template_version

      get "/pages/#{token_a}/template"

      expect(response).to have_http_status(:ok)
      expect(response.headers['Cache-Control']).to include('immutable'),
        "Matching token must receive immutable cache headers; got: #{response.headers['Cache-Control']}"
      expect(response.headers['Cache-Control']).to include('max-age=604800'),
        "Matching token must receive max-age=604800; got: #{response.headers['Cache-Control']}"
    end
  end

  describe 'race path (app-type switch without re-render)' do
    it 'returns no-store and omits immutable for token V_A after the user is switched to app-type B' do
      # Step 1: capture V_A — the token embedded in the page while the user is on A.
      # template_version = SHA256(partial_cache_key(:loaded)) includes app_type_a.id,
      # current_sign_in_at, userrole, uac, item_updates, and server_cache_version.
      token_a = embedded_template_version
      expect(token_a).to be_present

      # Step 2: simulate an app-type switch in another tab (or AppTypeChange).
      # The DB record is updated directly, but no new page is rendered — the
      # already-loaded page in tab-A still holds V_A.
      app_type_b = create_app_type(name: "cpt_b_#{SecureRandom.hex(4)}", label: 'CPT B')
      enable_user_app_access app_type_b, @user
      @user.reload.update_column(:app_type_id, app_type_b.id)

      # Step 3: the deferred fetch fires with V_A.  The server now reloads the
      # user (app_type_b.id), recomputes template_version → V_B ≠ V_A, and must
      # call prevent_cache instead of set_browser_cache(:immutable).
      get "/pages/#{token_a}/template"

      expect(response).to have_http_status(:ok)
      cache_control = response.headers['Cache-Control']

      expect(cache_control).to include('no-store'),
        "Stale V_A token after app-type switch must get no-store — " \
        "without the fix the server would return app-type-B content as immutable " \
        "under the V_A URL, poisoning the browser cache for 7 days. " \
        "Got: #{cache_control}"

      expect(cache_control).not_to include('immutable'),
        "Stale V_A token must NOT be marked immutable after app-type switch. " \
        "Got: #{cache_control}"
    end
  end
end
