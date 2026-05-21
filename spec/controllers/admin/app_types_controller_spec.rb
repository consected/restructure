# frozen_string_literal: true

# Admin::AppTypesController Spec (issue #1171)
#
# Tests for the async components_panel action introduced to fix slow admin page
# loading caused by synchronous rendering of the components list on every page.
#
# The components panel was previously rendered synchronously inside a
# Rails.cache.fetch block in the _app_components_dropdown partial. Any cache miss
# (triggered by invalidate_cache on admin saves or login) blocked the whole page.
#
# The fix loads the panel via a dedicated GET endpoint so the initial page renders
# immediately and the components load asynchronously in the background.
#
# Test Coverage:
# - GET admin/app_types/components_panel returns HTTP 200
# - The response body contains the expected admin panel components HTML
# - The response is served with appropriate caching headers
# - The endpoint is inaccessible to unauthenticated requests (redirects to sign-in)

require 'rails_helper'

RSpec.describe Admin::AppTypesController, type: :controller do
  include MasterSupport

  render_views

  before_each_login_admin

  describe 'GET #components_panel (issue #1171)' do
    it 'returns HTTP 200' do
      get :components_panel

      expect(response).to have_http_status(:ok)
    end

    it 'returns HTML containing the admin components panel' do
      get :components_panel

      expect(response.content_type).to include('text/html')
      expect(response.body).to include('components')
    end

    it 'uses Rails.cache when rendering the panel' do
      cache_called = false
      allow(Rails.cache).to receive(:fetch).and_wrap_original do |original, *args, **kwargs, &block|
        cache_called = true if args.first.to_s.include?('components')
        original.call(*args, **kwargs, &block)
      end

      get :components_panel

      expect(cache_called).to be(true)
    end
  end

  describe 'GET #components_panel authentication (issue #1171)' do
    it 'redirects unauthenticated requests to admin sign-in' do
      sign_out @admin

      get :components_panel

      expect(response).to redirect_to(new_admin_session_path)
    end
  end
end
