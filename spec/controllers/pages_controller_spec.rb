# frozen_string_literal: true

# PagesController Spec
#
# Tests for the PagesController actions:
# - Admin page: renders the admin index page
# - User page: redirects to search page
# - Template action (issue #1004 - AC10):
#   - Returns 304 Not Modified when ETag matches (If-None-Match header)
#   - Returns 200 with content on cache miss
#   - Sets appropriate Cache-Control headers for browser caching

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
  #
  # The template action should:
  # - Return 200 with rendered content on first request (cache miss)
  # - Set Cache-Control max-age and Expires headers for long-lived browser caching
  # - Return 304 Not Modified when the client sends a matching If-None-Match ETag
  # - Return 200 with fresh content when the ETag does not match
  describe '#template (ETag/304 caching - issue #1004)' do
    include MasterSupport
    before_each_login_user

    let(:template_version) { Digest::SHA256.hexdigest('test-version') }

    it 'returns 200 on cache miss' do
      get :template, params: { id: template_version }

      expect(response).to have_http_status(:ok)
    end

    it 'sets Cache-Control header with max-age for browser caching' do
      get :template, params: { id: template_version }

      expect(response.headers['Cache-Control']).to include('max-age=')
    end

    it 'sets Expires header for far-future caching' do
      get :template, params: { id: template_version }

      expect(response.headers['Expires']).to be_present
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
end
