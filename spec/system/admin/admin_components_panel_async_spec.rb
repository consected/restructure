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

  # Issue #1323: The admin components panel cache key does not vary by app type
  # when the controller calls partial_cache_key with force_user_or_admin: current_admin.
  # Because the method only computes apptype/userrole/uac when u.is_a?(User), the key
  # stays constant when u is an Admin - so switching the admin's effective app type
  # (via matching_user) serves stale cached content from the previous app type.
  describe 'components panel cache busts on app type switch (Issue #1323)' do
    it 'shows updated components after the admin matching_user switches app type' do
      app_types = Admin::AppType.active.order(:id).limit(2).to_a
      skip 'Need at least 2 active app types for this test' unless app_types.size >= 2

      app_type_a = app_types.first
      app_type_b = app_types.second

      # Create a matching user for the admin on app_type_a
      unless @admin.matching_user
        user = User.create!(
          email: @admin.email,
          current_admin: @admin,
          first_name: 'AdminMatch',
          last_name: 'User',
          password: Devise.friendly_token(30)
        )
        user = User.find(user.id)
        user.current_admin = @admin
        user.otp_required_for_login = false
        user.new_two_factor_auth_code = false
        user.confirmed_at = Time.now
        user.save!
      end

      matching_user = @admin.matching_user
      expect(matching_user).to be_present

      # Grant access to both app types
      [app_type_a, app_type_b].each do |at|
        next if matching_user.has_access_to?(:access, :general, :app_type, alt_app_type_id: at.id)

        Admin::UserAccessControl.create!(
          user: matching_user, app_type: at, access: :read,
          resource_type: :general, resource_name: :app_type, current_admin: @admin
        )
      end

      # Set matching user to app_type_a
      matching_user.current_admin = @admin
      matching_user.update!(app_type: app_type_a)
      expect(matching_user.reload.app_type_id).to eq(app_type_a.id)

      # Clear any prior cache entries for this key
      Rails.cache.clear

      # Visit components panel - content is rendered for app_type_a and cached
      visit '/admin/app_types/components_panel'
      expect(page).to have_css('.admin-panel-components', wait: 10)
      first_visit_content = find('#admin-panel-components').text

      # Switch matching user to app_type_b
      matching_user.current_admin = @admin
      matching_user.update!(app_type: app_type_b)
      expect(matching_user.reload.app_type_id).to eq(app_type_b.id)

      # Visit components panel again - should show content for app_type_b
      visit '/admin/app_types/components_panel'
      expect(page).to have_css('.admin-panel-components', wait: 10)
      second_visit_content = find('#admin-panel-components').text

      # The bug: cache key doesn't include app_type when u is Admin, so stale
      # content from app_type_a is served even after switching to app_type_b.
      # This assertion fails with the bug (content is identical) and passes
      # once the cache key properly varies by the admin's effective app type.
      expect(second_visit_content).not_to eq(first_visit_content),
                                          'Expected components panel content to differ after switching from ' \
                                          "'#{app_type_a.name}' to '#{app_type_b.name}', but got identical content. " \
                                          'This indicates the cache key is not varying by app type (Issue #1323).'
    end
  end
end
