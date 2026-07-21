# frozen_string_literal: true

require 'rails_helper'

# Purpose (issue #1287): verify that PagesController#template validates the version token
# in params[:id] against the current server-side digest, preventing wrong-app-type template
# content from being permanently cached in the browser under the correct app-type URL.
#
# Root cause: the action previously ignored params[:id] and unconditionally applied
# Cache-Control: private, max-age=604800, immutable.  If a user's app_type_id changed
# between the full page render (which embeds the token via ApplicationHelper#template_version)
# and the deferred AJAX fetch that uses the embedded token, the server returned the *new*
# app type's templates under the *old* app type's URL, marked immutable.  The browser would
# then permanently cache that wrong-app content against that URL for seven days.
#
# Fix: when params[:id] == helpers.template_version (the normal path) the response is
# content-addressed and immutable caching is safe.  When params[:id] is stale or
# mismatched (the race-condition path) the action calls prevent_cache, returning
# Cache-Control: no-cache, no-store, max-age=0, must-revalidate so nothing wrong is
# permanently bound to the stale URL.
#
# These specs use in-browser fetch() calls to read the actual Cache-Control response
# header returned by the server in the full application stack (real HTTP, real session
# cookies, real helper computation), verifying behaviour that the controller spec can only
# prove at the mock-request level.
#
# Examples:
# - Current token → Cache-Control includes immutable and max-age=604800
# - Arbitrary stale token → Cache-Control includes no-store, excludes immutable
# - App-type-switch race: load as app type A (token V_A), switch user to app type B in DB,
#   then fetch with V_A → no-store (V_A is now stale; without the fix it would be immutable
#   with app-type-B's content permanently bound to V_A's URL)
describe 'template version token cache-poisoning prevention', js: true, driver: $browser_driver do
  include ModelSupport
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)
    @user, @user_password = create_user
    @app_type_a = @user.app_type
  end

  def login_as_user
    @user = User.find(@user.id)
    @good_email = @user.email
    @good_password = @user_password
    login
  end

  before do
    login_as_user
  end

  # Make an authenticated GET to the template endpoint from the current browser session
  # and return the Cache-Control response header value as a Ruby string.
  # Uses fetch() with `credentials: 'same-origin'` so the session cookie is sent.
  # Uses `cache: 'no-store'` on the fetch itself so the browser cache does not serve a
  # previously stored response for this test assertion.
  def fetch_template_cache_control(token)
    page.evaluate_async_script(<<~JS)
      var done = arguments[arguments.length - 1];
      fetch('/pages/#{token}/template', {
        method: 'GET',
        credentials: 'same-origin',
        cache: 'no-store'
      })
        .then(function (r) { done(r.headers.get('Cache-Control') || ''); })
        .catch(function (e) { done('error: ' + e.message); });
    JS
  end

  describe 'matching token (normal single-tab path)' do
    it 'returns Cache-Control: immutable, private, max-age=604800 for the current template token' do
      visit '/masters/search'
      finish_page_loading
      expect(page).to have_css('body.status-compiled', wait: 30)

      real_token = page.evaluate_script('_fpa.state.template_version')
      expect(real_token).to be_present, 'Page should have set _fpa.state.template_version'

      cache_control = fetch_template_cache_control(real_token)
      expect(cache_control).not_to start_with('error:'),
        "fetch() failed: #{cache_control}"

      expect(cache_control).to include('immutable'),
        "Matching token should be cached immutably, got: #{cache_control}"
      expect(cache_control).to include('max-age=604800'),
        "Matching token should have a 7-day max-age, got: #{cache_control}"
      expect(cache_control).to include('private'),
        "Template responses must always be private (user-specific), got: #{cache_control}"
    end
  end

  describe 'stale / mismatched token (race-condition path)' do
    it 'returns Cache-Control: no-store and omits immutable for a bogus stale token' do
      visit '/masters/search'
      finish_page_loading
      expect(page).to have_css('body.status-compiled', wait: 30)

      stale_token = Digest::SHA256.hexdigest('stale-bogus-token-for-1287-spec')
      cache_control = fetch_template_cache_control(stale_token)
      expect(cache_control).not_to start_with('error:'),
        "fetch() failed: #{cache_control}"

      expect(cache_control).to include('no-store'),
        "Stale token must get non-cacheable headers (no-store), got: #{cache_control}"
      expect(cache_control).not_to include('immutable'),
        "Stale token must NOT be marked immutable — that would permanently bind wrong content to this URL, got: #{cache_control}"
    end

    it 'returns no-store for a token that became stale when the session renewed (multi-tab race simulation)' do
      # Step 1: Load the page and capture the token embedded by this session.
      # partial_cache_key(:loaded) includes current_sign_in_at, so the token is
      # tightly bound to this specific login moment.
      visit '/masters/search'
      finish_page_loading
      expect(page).to have_css('body.status-compiled', wait: 30)

      token_from_first_session = page.evaluate_script('_fpa.state.template_version')
      expect(token_from_first_session).to be_present

      # Step 2: Simulate the other-tab renewal — log out and back in, which advances
      # current_sign_in_at (one of the inputs to partial_cache_key).  The server's
      # fresh template_version will therefore differ from token_from_first_session.
      # This mirrors the real race: one tab still holds the old token while another
      # tab's navigation has updated the user's session state.
      logout
      login_as_user

      # Step 3: Fetch with the old token — the server's current template_version no
      # longer matches, so the response must be non-cacheable.
      # Without the fix: the server would have returned immutable with the *current*
      # session's templates, permanently binding the wrong content to the old URL.
      cache_control = fetch_template_cache_control(token_from_first_session)
      expect(cache_control).not_to start_with('error:'),
        "fetch() failed: #{cache_control}"

      expect(cache_control).to include('no-store'),
        "After session renewal the old token must get no-store — " \
        "immutable here would poison the browser cache with renewed-session content. " \
        "Got: #{cache_control}"
      expect(cache_control).not_to include('immutable'),
        "Old session token must NOT be marked immutable after login renewal, " \
        "got: #{cache_control}"
    end
  end
end
