# frozen_string_literal: true

# PagesController Spec
#
# Tests for the PagesController actions:
# - Admin page: renders the admin index page
# - User page: redirects to search page
# - Template action (issue #1004 - AC10, issue #63):
#   - Returns 304 Not Modified when ETag matches (If-None-Match header)
#   - Returns 200 with content on cache miss
#   - Sets Cache-Control with private, max-age, and immutable directives
#   - Sets Expires header computed from max-age
# - Template version-token validation (issue #1287):
#   - Matching token (params[:id] == helpers.template_version): immutable caching + ETag 304 flow
#   - Stale/mismatched token: prevent_cache headers (no-store), no immutable, still returns 200

require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe 'admin page' do
    include MasterSupport

    before_each_login_admin

    it 'shows the admin menu page' do
      get :index, params: {}
      expect(response).to have_http_status :success
      expect(response).to render_template 'pages/index'
    end
  end

  describe 'user page' do
    include MasterSupport

    before_each_login_user

    it 'redirects to search page' do
      get :index, params: {}
      expect(response).to redirect_to '/masters/search'
    end
  end

  # AC10: ETag / 304 behavior for the template action (issue #1004)
  # Issue #63: Add Cache-Control: private and immutable directives
  #
  # The template action should:
  # - Return 200 with rendered content on first request (cache miss)
  # - Set Cache-Control with private, max-age, and immutable for browser caching
  # - Return 304 Not Modified when the client sends a matching If-None-Match ETag
  # - Return 200 with fresh content when the ETag does not match
  describe '#template (ETag/304 caching - issue #1004, #63)' do
    include MasterSupport

    before_each_login_user

    let(:template_version) { controller.helpers.template_version }

    it 'returns 200 on cache miss' do
      get :template, params: { id: template_version }

      expect(response).to have_http_status(:ok)
    end

    it 'sets Cache-Control header with private, max-age, and immutable for browser caching' do
      get :template, params: { id: template_version }

      cache_control = response.headers['Cache-Control']
      expect(cache_control).to include('private')
      expect(cache_control).to include('max-age=')
      expect(cache_control).to include('immutable')
    end

    it 'sets Expires header computed from max-age' do
      get :template, params: { id: template_version }

      expires = Time.httpdate(response.headers['Expires'])
      expect(expires).to be > Time.now
    end

    it 'includes an ETag in the response' do
      get :template, params: { id: template_version }

      expect(response.headers['ETag']).to be_present
    end

    it 'returns 304 Not Modified when If-None-Match matches the ETag' do
      # First request to get the ETag
      get :template, params: { id: template_version }
      etag = response.headers['ETag']

      expect(etag).to be_present

      # Second request with matching ETag
      request.env['HTTP_IF_NONE_MATCH'] = etag
      get :template, params: { id: template_version }

      expect(response).to have_http_status(:not_modified)
    end

    it 'returns 200 when If-None-Match does not match (stale ETag)' do
      request.env['HTTP_IF_NONE_MATCH'] = '"stale-etag-value"'
      get :template, params: { id: template_version }

      expect(response).to have_http_status(:ok)
    end
  end

  # Issue #1287: version-token validation to prevent wrong-app-type browser cache poisoning.
  #
  # The template action embeds a content-addressed token (helpers.template_version) in the page URL.
  # If the token in params[:id] matches the current server-side digest, the response is safe to
  # cache immutably. If it does NOT match (race condition: app_type changed between page render
  # and deferred AJAX fetch), the response must NOT be cached immutably to prevent poisoning.
  describe '#template version-token validation (issue #1287)' do
    include MasterSupport

    before_each_login_user

    let(:real_token) { controller.helpers.template_version }
    let(:stale_token) { Digest::SHA256.hexdigest('stale-bogus-token') }

    context 'when params[:id] matches the current template_version (normal path)' do
      it 'sets Cache-Control with immutable and max-age=604800' do
        get :template, params: { id: real_token }

        cache_control = response.headers['Cache-Control']
        expect(cache_control).to include('immutable')
        expect(cache_control).to include('max-age=604800')
      end

      it 'returns 304 Not Modified when ETag matches' do
        get :template, params: { id: real_token }
        etag = response.headers['ETag']
        expect(etag).to be_present

        request.env['HTTP_IF_NONE_MATCH'] = etag
        get :template, params: { id: real_token }

        expect(response).to have_http_status(:not_modified)
      end
    end

    context 'when params[:id] does NOT match the current template_version (stale token)' do
      it 'does NOT set Cache-Control immutable' do
        get :template, params: { id: stale_token }

        cache_control = response.headers['Cache-Control']
        expect(cache_control).not_to include('immutable')
      end

      it 'sets Cache-Control to no-store (prevent_cache)' do
        get :template, params: { id: stale_token }

        cache_control = response.headers['Cache-Control']
        expect(cache_control).to include('no-store')
      end

      it 'still returns 200 (does not 404 or reject)' do
        get :template, params: { id: stale_token }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
