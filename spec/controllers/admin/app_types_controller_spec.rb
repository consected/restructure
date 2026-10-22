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
# The panel is cached in Rails.cache. Its key extends partial_cache_key with the latest
# updated_at of listed components that key does not cover and whose saves don't clear
# the cache (reports, general selections, item flag names, protocols, role descriptions,
# filestore filters), so edits to them are not served stale.
#
# Test Coverage:
# - GET admin/app_types/components_panel returns HTTP 200
# - The response body contains the expected admin panel components HTML
# - A notice identifies message templates omitted for definitions not generated on this server
# - A renamed report appears in the next panel response (no stale cached panel)
# - An unchanged panel is served from the cache without re-rendering
# - A change to any of the extra key components changes the cache key
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

    it 'shows a note when associated definitions are not generated on this server' do
      app_type = @admin.matching_user&.app_type || Admin::AppType.active.first!
      definitions = app_type.associated_activity_logs.to_a + app_type.associated_dynamic_models.to_a
      definition = definitions.find { |d| d.class.definition_cache.key?(d.id) }
      expect(definition).to be_present

      definition_cache = definition.class.definition_cache
      cached_definition = definition_cache.delete(definition.id)
      skipped = definitions.count { |d| !d.class.definition_cache.key?(d.id) }
      controller.instance_variable_set(:@app_type, app_type)
      allow(controller).to receive(:components_panel_cache_key).and_return("components-panel-spec-#{SecureRandom.hex(8)}")

      get :components_panel

      expect(response.body).to include(
        "Templates used by #{ActionController::Base.helpers.pluralize(skipped, 'definition')} " \
        'not generated on this server are not listed.'
      )
    ensure
      definition_cache[definition.id] = cached_definition if cached_definition
    end

    it 'shows a renamed report on the next request' do
      app_type = @admin.matching_user&.app_type || Admin::AppType.active.first
      old_name = "original panel report #{SecureRandom.hex(4)}"
      report = Report.create!(current_admin: @admin, name: old_name, description: '', sql: 'select 1',
                              search_attrs: '', disabled: false, report_type: 'regular_report',
                              auto: false, searchable: false, item_type: 'panel-spec')
      Admin::UserAccessControl.create!(app_type:, access: :read, resource_type: :report,
                                       resource_name: report.alt_resource_name, current_admin: @admin)

      get :components_panel
      expect(response.body).to include(old_name)

      new_name = "renamed panel report #{SecureRandom.hex(4)}"
      report.update!(name: new_name, current_admin: @admin)

      get :components_panel
      expect(response.body).to include(new_name)
      expect(response.body).not_to include(old_name)
    end

    it 'serves an unchanged panel from the cache without re-rendering it' do
      expect(controller).to receive(:render_to_string).once.and_call_original

      get :components_panel
      first_body = response.body
      get :components_panel

      expect(response.body).to eq(first_body)
    end

    it 'changes the cache key when any extra panel component changes' do
      get :components_panel
      klasses = controller.send(:components_panel_extra_key_classes)
      base = Time.zone.parse('2026-01-01 00:00:00')
      klasses.each { |k| allow(k).to receive(:maximum).with(:updated_at).and_return(base) }
      initial_key = controller.send(:components_panel_cache_key)

      klasses.each do |k|
        allow(k).to receive(:maximum).with(:updated_at).and_return(base + Rational(1, 1_000_000))
        expect(controller.send(:components_panel_cache_key)).not_to eq(initial_key), "#{k.name} change ignored"
        allow(k).to receive(:maximum).with(:updated_at).and_return(base)
      end
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
