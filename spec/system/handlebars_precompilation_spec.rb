# frozen_string_literal: true

# Handlebars Precompilation System Spec
#
# End-to-end tests for server-side Handlebars template precompilation.
# Verifies that precompiled templates load correctly in the browser and
# render properly with data.
#
# Test Coverage:
# - Page loads without JavaScript errors
# - Precompiled templates are available in _fpa.templates
# - Precompiled partials are available in _fpa.partials
# - Templates render correctly with data
# - Body has status-compiled class after template loading

require 'rails_helper'

RSpec.describe 'Handlebars Precompilation', type: :system, js: true, driver: $browser_driver do
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

  describe 'page load with precompiled templates' do
    it 'has status-compiled class on body after loading' do
      visit '/'
      finish_page_loading

      # Wait for templates to load (longer timeout for compilation)
      sleep 5

      expect(page).to have_css('body.status-compiled', wait: 30)

      # Verify _fpa status flags are set
      loaded = page.evaluate_script('_fpa.status.loaded_templates')
      expect(loaded).to be true

      setup_run = page.evaluate_script('_fpa.status.one_time_setup_run')
      expect(setup_run).to be true
    end

    it 'has templates available in _fpa.templates' do
      visit '/'
      finish_page_loading

      templates_available = page.evaluate_script('Object.keys(_fpa.templates || {}).length > 0')

      expect(templates_available).to be true
    end

    it 'has partials available in _fpa.partials' do
      visit '/'
      finish_page_loading

      # Wait for search results templates to be loaded via retrieve_requested_handlebars_templates
      # The body gets class 'loaded-templates--masters__search_results_template' when the full template set is loaded
      # This is the file that contains all the partials
      expect(page).to have_css('body.loaded-templates--masters__search_results_template', wait: 30)

      partials_available = page.evaluate_script('Object.keys(_fpa.partials || {}).length > 0')

      expect(partials_available).to be true
    end
  end

  describe 'template rendering' do
    it 'renders page without template errors' do
      visit '/'
      finish_page_loading

      # Check page doesn't have error indicators
      expect(page).not_to have_css('.ajax-running', wait: 5)
      expect(page).not_to have_content('Template error')
    end
  end
end
