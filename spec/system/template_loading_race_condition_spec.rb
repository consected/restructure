# frozen_string_literal: true

# Template Loading Race Condition System Spec
#
# Verifies that the splash guard ("loading...") does not disappear until all
# Handlebars templates are fully loaded and available for use.
#
# The bug: compile_templates() is called (adding status-compiled to body, removing
# the splash guard) before retrieve_requested_handlebars_templates AJAX completes.
# This creates a window where the user can interact with the page (e.g. click search)
# but templates aren't available, causing:
#   "Cannot read properties of undefined (reading 'attr')" in _fpa.js render_template
#
# Root cause: load_template_version.done() sets loaded_templates=true after 1ms,
# which triggers one_time_setup() -> compile_templates() -> status-compiled.
# But the multi file AJAX from retrieve_requested_handlebars_templates hasn't
# completed yet, so Handlebars.templates is still empty.
#
# Test Coverage:
# - Templates must be loaded before compile_templates first runs
# - Search works immediately after splash guard disappears without JS errors

require 'rails_helper'

RSpec.describe 'Template loading race condition', type: :system, js: true, driver: $browser_driver do
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

  describe 'splash guard and template loading synchronization' do
    it 'has templates loaded before compile_templates adds status-compiled' do
      # Use Chrome DevTools Protocol to inject JavaScript that runs BEFORE any
      # page scripts on the next document load. A MutationObserver captures the
      # template state at the exact moment status-compiled is added to the body,
      # which is when the splash guard is removed and the user can interact.
      cdp_result = page.driver.browser.execute_cdp(
        'Page.addScriptToEvaluateOnNewDocument',
        source: <<~JS
          window._testCompileState = { caught: false, template_count: -1 };
          document.addEventListener('DOMContentLoaded', function() {
            var observer = new MutationObserver(function(mutations) {
              if (document.body.classList.contains('status-compiled') && !window._testCompileState.caught) {
                window._testCompileState.caught = true;
                window._testCompileState.template_count = Object.keys(Handlebars.templates || {}).length;
              }
            });
            observer.observe(document.body, { attributes: true, attributeFilter: ['class'] });
          });
        JS
      )
      cdp_script_id = cdp_result['identifier']

      begin
        visit '/masters/search'

        # Wait for full page load including search results template multi file
        expect(page).to have_css('body.status-compiled', wait: 30)
        expect(page).to have_css('body.loaded-templates--masters__search_results_template', wait: 30)

        state = page.evaluate_script('window._testCompileState')

        expect(state).not_to be_nil, 'CDP script should have set window._testCompileState'
        expect(state['caught']).to be(true),
          'MutationObserver should have captured status-compiled being set'

        # Get the total template count after full page load for comparison
        total_templates = page.evaluate_script('Object.keys(Handlebars.templates || {}).length')

        # At the moment status-compiled was set (splash guard removed), ALL templates
        # should already be loaded.
        # Before the fix: only layout templates loaded (search results multi file still pending).
        # After the fix: all templates loaded because status-compiled is deferred until ready.
        expect(state['template_count']).to eq(total_templates),
          "Only #{state['template_count']} of #{total_templates} templates were loaded " \
          'when status-compiled was set (splash guard removed). ' \
          'All multi file templates must be loaded before the splash guard is removed.'
      ensure
        page.driver.browser.execute_cdp(
          'Page.removeScriptToEvaluateOnNewDocument',
          identifier: cdp_script_id
        )
      end
    end

    it 'does not produce JS errors when searching immediately after splash guard disappears' do
      visit '/masters/search'

      # Set up error handler to catch uncaught JS exceptions from the race condition
      page.execute_script(<<~JS)
        window._testJsErrors = [];
        window.addEventListener('error', function(event) {
          window._testJsErrors.push({
            message: event.message,
            source: event.filename,
            line: event.lineno,
            col: event.colno
          });
        });
      JS

      # Wait ONLY for the splash guard to disappear (status-compiled class added)
      expect(page).to have_css('body.status-compiled', wait: 30)

      # Immediately attempt a search - reproducing the user's reported scenario.
      # Without the fix, templates may not be loaded yet, causing render_template
      # to crash when it tries to call .attr('id') on undefined html.
      within '#simple_search_master' do
        fill_in 'Last name', with: 'test'
        click_button 'search'
      end

      # Allow time for the search AJAX to complete or fail
      sleep 3

      # Check for uncaught JS errors caused by templates not being loaded
      js_errors = page.evaluate_script('window._testJsErrors || []')
      template_errors = js_errors.select do |e|
        e['message']&.include?('Cannot read properties') ||
          e['message']&.include?('is not a function')
      end

      expect(template_errors).to be_empty,
        'JS errors occurred when searching immediately after splash guard disappeared: ' \
        "#{template_errors.map { |e| "#{e['message']} at line #{e['line']}" }.join('; ')}"

      # The search results block should be present (even if showing "No Results")
      expect(page).to have_css('#master_results_block', wait: 10)
    end
  end
end
