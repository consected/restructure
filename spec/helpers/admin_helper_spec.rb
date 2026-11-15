# frozen_string_literal: true

require 'rails_helper'

# Admin::AdminHelper Spec - show_admin_heading async components (issue #1171)
#
# The admin components list was rendered synchronously inside a Rails.cache.fetch
# block on every admin page, causing significant page-load delays whenever the
# cache expired (e.g. after any admin record save or a new login).
#
# The fix introduces lazy (async) loading: the _app_components_dropdown partial
# should render an empty #components-menu div with a data-lazy-url attribute
# pointing to the new GET admin/app_types/components_panel endpoint. The browser
# then fetches the content via AJAX when the collapse panel is first expanded.
#
# Test Coverage:
# - The components dropdown rendered by show_admin_heading includes a data-lazy-url
#   attribute on the components-menu button or container element, pointing to the
#   components_panel admin path.
# - The #components-menu div is empty on initial render (no inline component HTML),
#   confirming that the expensive synchronous render has been removed.

RSpec.describe AdminHelper, type: :helper do
  include ModelSupport

  before :all do
    create_admin
  end

  describe '#show_admin_heading async components dropdown (issue #1171)' do
    before do
      # Provide the admin context required by show_admin_heading and partials.
      # Use define_singleton_method for methods that exist only on the controller
      # (not on ActionView::Base), since verify_partial_doubles is enabled.
      helper.define_singleton_method(:current_admin) { @admin }
      helper.define_singleton_method(:current_user) { nil }
      helper.define_singleton_method(:title) { 'Test Page' }
      helper.define_singleton_method(:sub_title) { '' }
      helper.define_singleton_method(:help_section) { 'main' }
      helper.define_singleton_method(:help_subsection) { 'README.md' }

      # Stub partial_cache_key (ApplicationHelper method — exists on helper)
      # to avoid DB queries in the test.
      allow(helper).to receive(:partial_cache_key).and_return('test-components-cache-key')

      # Stub unrelated partials to keep the test focused
      allow(helper).to receive(:render).and_call_original
      allow(helper).to receive(:render).with(partial: 'admin_handler/status_bar').and_return('')

      # Stub the inner components partial to return recognisable HTML so the
      # "empty #components-menu" assertion can detect its presence and fail
      # correctly in the red phase. After the fix, this partial is never
      # rendered inline and the assertion will pass.
      allow(helper).to receive(:render)
        .with(partial: 'admin/app_types/components')
        .and_return('<div class="app-type-component">SomeComponent</div>')
    end

    it 'renders the components dropdown with a data-lazy-url attribute' do
      result = helper.show_admin_heading('Test Title')

      expect(result).to include('data-lazy-url')
    end

    it 'data-lazy-url points to the components_panel admin path' do
      result = helper.show_admin_heading('Test Title')

      expect(result).to match(%r{data-lazy-url=["'][^"']*components_panel[^"']*["']})
        .or match(%r{data-lazy-url=["'][^"']*/admin/app_types/components_panel[^"']*["']})
    end

    it 'renders #components-menu div without inline component content' do
      result = helper.show_admin_heading('Test Title')

      # The components-menu container must be present
      expect(result).to include('id="components-menu"')

      # The synchronous render of admin/app_types/components must NOT appear
      # inline. After the fix the div should be empty; currently it contains
      # the stubbed component HTML, so this assertion fails in the red phase.
      expect(result).not_to include('app-type-component')
    end
  end
end
