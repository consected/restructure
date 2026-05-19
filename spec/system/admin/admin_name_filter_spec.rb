# frozen_string_literal: true

# Admin Name Filter System Spec - Issue #1159
#
# Tests that the Reports admin panel automatically includes a name filter
# dropdown (using chosen.js) when the primary model has a 'name' column,
# without the controller needing to explicitly define it.
#
# Verifies:
# - A name filter select is rendered with data-filter-on="name"
# - The filter is wrapped in a chosen-container (typeahead UI)
# - Selecting a name value navigates to the filtered index
# - Only records matching the selected name are shown after filtering

require 'rails_helper'

describe 'admin name filter - Issue #1159', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin

    @report_alpha = Report.create!(
      current_admin: @admin,
      name: "Alpha Name Filter Test #{SecureRandom.hex(4)}",
      description: 'First report for name filter test',
      sql: 'select 1',
      search_attrs: '',
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false
    )

    @report_beta = Report.create!(
      current_admin: @admin,
      name: "Beta Name Filter Test #{SecureRandom.hex(4)}",
      description: 'Second report for name filter test',
      sql: 'select 1',
      search_attrs: '',
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false
    )
  end

  after(:all) do
    @report_alpha&.update(disabled: true, current_admin: @admin) if @report_alpha&.persisted?
    @report_beta&.update(disabled: true, current_admin: @admin) if @report_beta&.persisted?
  end

  before(:each) do
    admin_sign_in_with_2fa
  end

  it 'renders a name filter select on the reports admin page' do
    visit '/admin/reports'
    finish_page_loading

    within '#filter-selects' do
      name_select = find('select.filter-select[data-filter-on="name"]', visible: :all)
      expect(name_select).to be_present

      # chosen.js wraps the hidden select in a div.chosen-container
      expect(page).to have_css('.chosen-container', minimum: 1)
    end
  end

  it 'shows a label for the name filter' do
    visit '/admin/reports'
    finish_page_loading

    within '#filter-selects' do
      expect(page).to have_css('.filter-select-label', text: /name/i, visible: true)
    end
  end

  it 'populates the name filter options with existing report names' do
    visit '/admin/reports'
    finish_page_loading

    name_select = find('select.filter-select[data-filter-on="name"]', visible: :all)
    option_values = name_select.all('option', visible: :all).map(&:value)

    expect(option_values).to include(@report_alpha.name)
    expect(option_values).to include(@report_beta.name)
  end

  it 'filters the report list when a name is selected' do
    visit '/admin/reports'
    finish_page_loading

    # Open the chosen dropdown for the name filter.
    # Chosen.js inserts the div.chosen-container immediately after the hidden select,
    # both within the same span.filter-select-group. Navigate via the visible label.
    name_label = find('.filter-select-label', exact_text: 'Name:', visible: true)
    name_filter_group = name_label.find(:xpath, '..')
    name_filter_group.find('.chosen-container').click

    results_selector = 'body > .chosen-container.chosen-with-drop .chosen-results li.active-result'
    expect(page).to have_css(results_selector, wait: 5)

    results = all(results_selector)
    target = results.find { |r| r.text == @report_alpha.name }
    unless target
      raise "Could not find '#{@report_alpha.name}' in name filter dropdown. " \
            "Available: #{results.map(&:text).inspect}"
    end

    target.click
    finish_page_loading

    # After filtering, only the matching report should appear
    within '.data-results' do
      expect(page).to have_css("#admin-item-#{@report_alpha.id}", wait: 10)
      expect(page).not_to have_css("#admin-item-#{@report_beta.id}")
    end
  end
end
