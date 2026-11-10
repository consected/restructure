# frozen_string_literal: true

# Memcached Clear Template Recovery System Spec - fixes #987
#
# Verifies that clearing memcached and cleaning compiled handlebars template files
# does not break UI template retrieval for logged-in users.
#
# The bug: when memcached is cleared (e.g., from a configuration change) and
# compiled template files are cleaned up (e.g., on server restart),
# server_cache_version must be invalidated. Without invalidation, the same
# template_version is generated, causing browsers to serve stale cached
# template HTML that references deleted multi files, returning 404.
#
# Test Coverage:
# - Page loads normally with templates compiled
# - After simulated cleanup + cache invalidation, page still loads correctly
# - server_cache_version changes after cleanup_compiled_output + cache invalidation
# - Without cache invalidation, server_cache_version remains stale (proves bug)

require 'rails_helper'

RSpec.describe 'Template recovery after memcached clear', type: :system, js: true, driver: $browser_driver do
  include ModelSupport
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    @user, = create_user
    change_setting('TwoFactorAuthDisabledForUser', true)
  end

  before do
    login_as(@user, scope: :user)
  end

  describe 'compiled template cleanup without server_cache_version invalidation' do
    it 'leaves stale server_cache_version that would cause 404 on multi files' do
      visit '/'
      finish_page_loading
      expect(page).to have_css('body.status-compiled', wait: 30)

      # Record the current server_cache_version
      scv_before = Application.server_cache_version

      # Simulate what happens on server restart: compiled files are deleted
      HandlebarsPrecompiler.cleanup_compiled_output

      # Without the fix, server_cache_version remains unchanged
      # This means template_version stays the same, and browsers serve cached
      # template HTML referencing deleted multi files
      scv_after_no_fix = Application.server_cache_version
      expect(scv_after_no_fix).to eq(scv_before),
                                  'Bug: server_cache_version should remain stale without cache invalidation'

      # Verify that compiled multi files were actually deleted
      multi_files = Dir.glob(HandlebarsPrecompiler.multi_dir.join('*.js'))
      expect(multi_files).to be_empty,
                             'cleanup_compiled_output should have deleted all multi files'

      # Now apply the fix: invalidate server_cache_version
      Rails.cache.delete('server_cache_version')

      # After invalidation, a new server_cache_version is generated
      scv_after_fix = Application.server_cache_version
      expect(scv_after_fix).not_to eq(scv_before),
                                   'Fix: server_cache_version must change after cache invalidation'
    end
  end

  describe 'page recovery after cleanup with cache invalidation' do
    it 'reloads templates successfully after cleanup_compiled_output and cache invalidation' do
      # Step 1: Load page normally - templates compile and UI works
      visit '/'
      finish_page_loading
      expect(page).to have_css('body.status-compiled', wait: 30)

      templates_before = page.evaluate_script('Object.keys(_fpa.templates || {}).length')
      expect(templates_before).to be > 0

      # Step 2: Simulate server restart scenario
      # Cleanup compiled files (what happens on Rails startup)
      HandlebarsPrecompiler.cleanup_compiled_output
      HandlebarsPrecompiler.cleanup_tmp_dir
      # Invalidate server_cache_version (the fix from issue #987)
      Rails.cache.delete('server_cache_version')

      # Step 3: Reload - templates should recompile and work
      visit '/'
      finish_page_loading
      expect(page).to have_css('body.status-compiled', wait: 30)

      templates_after = page.evaluate_script('Object.keys(_fpa.templates || {}).length')
      expect(templates_after).to be > 0
    end

    it 'loads search results templates after cleanup and cache invalidation' do
      visit '/'
      finish_page_loading

      # Wait for the full template set to load
      expect(page).to have_css('body.loaded-templates--masters__search_results_template', wait: 30)

      # Simulate cleanup + fix
      HandlebarsPrecompiler.cleanup_compiled_output
      HandlebarsPrecompiler.cleanup_tmp_dir
      Rails.cache.delete('server_cache_version')

      # Reload and verify search results templates loaded
      visit '/'
      finish_page_loading
      expect(page).to have_css('body.loaded-templates--masters__search_results_template', wait: 30)

      partials_count = page.evaluate_script('Object.keys(_fpa.partials || {}).length')
      expect(partials_count).to be > 0
    end
  end
end
