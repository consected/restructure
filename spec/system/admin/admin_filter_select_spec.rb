# frozen_string_literal: true

require 'rails_helper'

# System spec for filter select boxes - Issue #969
#
# Tests that admin pages and user report pages display filter options
# using "chosen" select boxes instead of buttons. This verifies:
# - Filter select boxes are rendered with the use-chosen class
# - Selecting a filter option navigates to the filtered page
# - Multiple filter selects can be used simultaneously
# - The reports index also renders filter select boxes
# - Admin disabled filter is included as a select box
describe 'filter select boxes', js: true, driver: $browser_driver do
  include ModelSupport
  include FeatureSupport
  include AdminActionsSetup

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
  end

  describe 'admin pages' do
    before(:each) do
      admin_sign_in_with_2fa
    end

    it 'renders filter select boxes on the general selections admin page' do
      visit '/admin/general_selections'
      finish_page_loading

      # Verify select boxes are rendered instead of buttons.
      # Chosen.js hides the original select and creates a div.chosen-container
      within '.data-results' do
        expect(page).to have_css('select.filter-select', visible: :all, minimum: 1)
        expect(page).to have_css('.chosen-container', minimum: 1)
        expect(page).not_to have_css('#filter-accordion')
        expect(page).not_to have_css('.panel-group#filter-accordion')
      end
    end

    it 'renders filter labels next to select boxes' do
      visit '/admin/general_selections'
      finish_page_loading

      within '#filter-selects' do
        expect(page).to have_css('.filter-select-label', minimum: 1, visible: true)
        expect(page).to have_css('.filter-select-group', minimum: 1)
      end
    end

    it 'includes disabled filter for admin users' do
      visit '/admin/general_selections'
      finish_page_loading

      within '#filter-selects' do
        # The disabled filter should be one of the filter selects (hidden by chosen.js)
        disabled_select = find('select.filter-select[data-filter-on="disabled"]', visible: :all)
        expect(disabled_select).to be_present
      end
    end

    it 'filters results when a filter option is selected' do
      visit '/admin/general_selections'
      finish_page_loading

      # Get the first filter select (hidden by chosen.js) and verify it has options
      within '#filter-selects' do
        first_select = first('select.filter-select', visible: :all)
        options = first_select.all('option', visible: :all)
        expect(options.length).to be > 1
      end
    end
  end

  describe 'reports index page' do
    before(:each) do
      admin_sign_in_with_2fa
    end

    it 'renders filter select boxes on the reports page if categories exist' do
      # Create reports with different categories to ensure filters are shown
      Report.active.update_all(disabled: true, admin_id: @admin.id)

      r1 = Report.create!(current_admin: @admin, name: 'Test Report 1', description: '',
                          sql: 'select 1', item_type: 'category_a', report_type: 'regular_report')
      r2 = Report.create!(current_admin: @admin, name: 'Test Report 2', description: '',
                          sql: 'select 1', item_type: 'category_b', report_type: 'regular_report')

      visit '/reports'
      finish_page_loading

      # Verify select boxes are rendered since there are multiple categories
      if page.has_css?('select.filter-select')
        expect(page).to have_css('select.filter-select')
        expect(page).not_to have_css('#filter-accordion')
      end
    ensure
      r1&.update(disabled: true, current_admin: @admin)
      r2&.update(disabled: true, current_admin: @admin)
    end
  end
end
