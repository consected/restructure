# frozen_string_literal: true

# Tests for Issue #1171 - Admin panel components list async lazy loading.
#
# Previously the components panel was rendered synchronously inside a
# Rails.cache.fetch block on every admin page, causing significant delays
# whenever the cache expired (after any admin record save, or after a new
# admin login that changes current_sign_in_at).
#
# The fix loads the panel lazily:
# - On admin action pages (via the dropdown): content is fetched via AJAX
#   when the collapse button is first clicked.
# - On the admin index page (/): content is fetched via AJAX on DOM ready
#   into .admin-components-lazy-panel.
#
# Test Coverage:
# - The #components-menu div is initially empty on an admin action page
# - Clicking the components dropdown button triggers an AJAX load
# - After expansion, the components list is visible in the dropdown
# - On the admin index page, the components panel loads without a click
# - The components panel is accessible at GET /admin/app_types/components_panel

require 'rails_helper'

RSpec.describe 'Admin components panel async loading - Issue1171', js: true, type: :system do
  include MasterSupport
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    create_admin
  end

  before(:each) do
    login_as(@admin, scope: :admin)
  end

  describe 'components dropdown on admin action pages' do
    before(:each) do
      # Visit any admin action page that renders show_admin_heading
      visit '/admin/activity_logs'
      finish_page_loading
    end

    it 'renders the components-menu button on the page' do
      expect(page).to have_css('#components-menu-button')
    end

    it 'renders #components-menu initially empty (no synchronous component HTML)' do
      # The fix: components-menu starts without inline component content.
      # Before the fix, the full components list was rendered synchronously here.
      # #components-menu is a Bootstrap collapse (hidden by default) – access with visible: false
      expect(page).not_to have_css('#components-menu .admin-panel-components', visible: false)
    end

    it 'has a data-lazy-url attribute on #components-menu pointing to the panel endpoint' do
      # #components-menu is hidden by default (Bootstrap collapse, no .in class)
      menu = find('#components-menu', visible: false)
      expect(menu['data-lazy-url']).to include('/admin/app_types/components_panel')
    end

    it 'loads the components list via AJAX when the dropdown is expanded' do
      btn = find('#components-menu-button')
      scroll_into_view(btn)
      sleep 0.5
      btn.click
      # Wait for Bootstrap to open the collapse (.in class), then for AJAX content
      expect(page).to have_css('#components-menu.in', wait: 5)
      expect(page).to have_css('#components-menu .admin-panel-components', wait: 15)
    end

    it 'shows component links inside the dropdown after expansion' do
      btn = find('#components-menu-button')
      scroll_into_view(btn)
      sleep 0.5
      btn.click
      expect(page).to have_css('#components-menu.in', wait: 5)
      expect(page).to have_css('#components-menu .admin-panel-components', wait: 15)

      within('#components-menu .admin-panel-components') do
        # At least one component link should be present after loading
        expect(page).to have_css('a', minimum: 1)
      end
    end
  end

  describe 'components panel on admin index page' do
    before(:each) do
      visit '/'
      finish_page_loading
    end

    it 'renders the lazy panel placeholder on the index page' do
      expect(page).to have_css('.admin-components-lazy-panel')
    end

    it 'loads the components list into the lazy panel on DOM ready' do
      # The panel is loaded automatically (no click required) on the index page
      expect(page).to have_css('.admin-components-lazy-panel .admin-panel-components', wait: 15)
    end
  end

  describe 'components_panel endpoint' do
    before(:each) do
      # Visit a regular admin page first to ensure the session is fully established
      visit '/admin/activity_logs'
      finish_page_loading
    end

    it 'returns the components panel HTML when visited directly' do
      visit '/admin/app_types/components_panel'
      expect(page).to have_css('.admin-panel-components', wait: 10)
    end
  end
end
