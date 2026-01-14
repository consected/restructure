# frozen_string_literal: true

require 'rails_helper'

# Tests for master search with searchable report tabs
# Related to GitHub issue #834 - Master results get requested twice
describe 'master search with reports', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include ReportSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    SetupHelper.feature_setup

    seed_database
    create_data_set_outside_tx

    @admin, = create_admin
    @user, @good_password = create_user
    @good_email = @user.email

    # Grant view_reports access
    Admin::UserAccessControl.create!(
      app_type_id: @user.app_type_id,
      access: :read,
      resource_type: :general,
      resource_name: :view_reports,
      current_admin: @admin,
      user: @user
    )

    # Create searchable reports for master search
    create_searchable_report
    create_searchable_report_with_auto_run
  end

  def create_searchable_report
    sql = "select id as master_id from masters where id::text like '%' || :search_text || '%' limit 10"
    search_attrs = <<~END_CONFIG
      search_text:
        text:
          all: true
          multiple: single
          disabled: false
    END_CONFIG
    @searchable_report = Report.create!(
      current_admin: @admin,
      name: "Searchable Report #{SecureRandom.hex(4)}",
      description: 'Test searchable report for master search',
      sql: sql,
      search_attrs: search_attrs,
      disabled: false,
      report_type: 'search',
      auto: false,
      searchable: true,
      position: 1
    )

    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :read,
      resource_type: :report,
      resource_name: @searchable_report.alt_resource_name,
      current_admin: @admin
    )
  end

  def create_searchable_report_with_auto_run
    sql = 'select id as master_id from masters limit 5'
    @auto_run_report = Report.create!(
      current_admin: @admin,
      name: "Auto Run Report #{SecureRandom.hex(4)}",
      description: 'Test auto-run searchable report for master search',
      sql: sql,
      search_attrs: '',
      disabled: false,
      report_type: 'search',
      auto: true,
      searchable: true,
      position: 2
    )

    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :read,
      resource_type: :report,
      resource_name: @auto_run_report.alt_resource_name,
      current_admin: @admin
    )
  end

  before :each do
    validate_setup
    login
  end

  # Test for GitHub issue #834 - Master results get requested twice
  # When clicking a custom report tab, the search should only be submitted once
  it 'submits search only once when clicking a searchable report tab' do
    # Verify we have masters in the database
    master_count = Master.count
    puts "Masters in database: #{master_count}"
    expect(master_count).to be > 0, 'Need at least one master record for this test'

    visit '/masters/search'
    finish_page_loading

    # Verify the searchable report tab exists
    report_tab_selector = "a#expand-searchable-report-#{@auto_run_report.alt_resource_name}"
    expect(page).to have_css(report_tab_selector)

    # Set up JavaScript to track search submissions by monitoring form submits
    page.execute_script(<<~JS)
      window.searchSubmitCount = 0;
      window.searchSubmitTimes = [];
      $(document).on('submit', 'form.search_report', function(e) {
        window.searchSubmitCount++;
        window.searchSubmitTimes.push(new Date().toISOString());
        console.log('Form submit #' + window.searchSubmitCount + ' at ' + window.searchSubmitTimes[window.searchSubmitTimes.length - 1]);
      });
    JS

    # Click the auto-run searchable report tab
    find(report_tab_selector).click

    # Wait for the panel to expand
    expect(page).to have_css("#master-report-#{@auto_run_report.alt_resource_name}.in", wait: 10)

    # Wait for the form to load via AJAX
    expect(page).to have_css("#master-report-#{@auto_run_report.alt_resource_name} form.search_report", wait: 10)

    finish_page_loading

    # Wait for search results to appear - check for the count within searchable report panel
    # or check for any master-expander appearing (indicating results)
    using_wait_time(15) do
      expect(page).to have_css('.search_count_reports .search_count', text: /\d+/)
    end

    # Give some additional time for any duplicate requests to be made
    sleep 2

    # Verify only ONE search request was made
    search_count = page.evaluate_script('window.searchSubmitCount')
    submit_times = page.evaluate_script('window.searchSubmitTimes')
    expect(search_count).to eq(1), "Expected 1 search submit, but got #{search_count}. Submit times: #{submit_times}"
  end

  # Test for GitHub issue #834 - Enter key in form field causes double submit
  # When pressing Enter in a search criteria field, the search should only be submitted once
  it 'submits search only once when pressing Enter in a search field' do
    visit '/masters/search'
    finish_page_loading

    # Click the non-auto-run searchable report tab (so we can type in a field)
    click_link @searchable_report.name
    expect(page).to have_css("#master-report-#{@searchable_report.alt_resource_name}.in", wait: 5)

    # Wait for the form to load via AJAX
    expect(page).to have_css("#master-report-#{@searchable_report.alt_resource_name} form.search_report", wait: 10)
    finish_page_loading

    # Set up JavaScript to track search submissions
    page.execute_script(<<~JS)
      window.searchSubmitCount = 0;
      window.searchSubmitTimes = [];
      $(document).on('submit', 'form.search_report', function(e) {
        window.searchSubmitCount++;
        window.searchSubmitTimes.push(new Date().toISOString());
        console.log('Form submit #' + window.searchSubmitCount + ' at ' + window.searchSubmitTimes[window.searchSubmitTimes.length - 1]);
      });
    JS

    # First search: type in the text field and press Enter
    within ".searchable-report[data-report-id='#{@searchable_report.id}']" do
      search_field = find('input[name="search_attrs[search_text]"]', wait: 5)
      search_field.send_keys('1', :enter)
    end

    # Wait for search results to appear
    expect(page).to have_css('.search_count_reports .search_count', text: /\d+/, wait: 15)

    # Give some time for any duplicate requests to be made
    sleep 2

    # Verify only ONE search request was made
    search_count = page.evaluate_script('window.searchSubmitCount')
    submit_times = page.evaluate_script('window.searchSubmitTimes')
    expect(search_count).to eq(1), "Expected 1 search submit when pressing Enter, but got #{search_count}. Submit times: #{submit_times}"

    # Reset counter for second search
    page.execute_script('window.searchSubmitCount = 0; window.searchSubmitTimes = [];')

    # Second search: change criteria and press Enter again to verify multiple searches work
    within ".searchable-report[data-report-id='#{@searchable_report.id}']" do
      search_field = find('input[name="search_attrs[search_text]"]', wait: 5)
      search_field.fill_in with: '2'
      search_field.send_keys(:enter)
    end

    # Wait for new search results
    expect(page).to have_css('.search_count_reports .search_count', text: /\d+/, wait: 15)
    sleep 2

    # Verify second search also only submitted once
    search_count = page.evaluate_script('window.searchSubmitCount')
    submit_times = page.evaluate_script('window.searchSubmitTimes')
    expect(search_count).to eq(1), "Expected 1 search submit for second Enter press, but got #{search_count}. Submit times: #{submit_times}"
  end

  it 'displays results correctly when clicking searchable report tab' do
    visit '/masters/search'
    finish_page_loading

    # Click the searchable report tab
    click_link @searchable_report.name
    expect(page).to have_css("#master-report-#{@searchable_report.alt_resource_name}.in", wait: 5)
    finish_page_loading

    # First search with criteria '1'
    within ".searchable-report[data-report-id='#{@searchable_report.id}']" do
      fill_in 'search_attrs[search_text]', with: '1'
      click_button 'search'
    end

    # Wait for search results
    expect(page).to have_css('.search_count_reports .search_count', text: /\d+/, wait: 10)
    first_count = find('.search_count_reports .search_count').text

    # Second search with different criteria '2'
    within ".searchable-report[data-report-id='#{@searchable_report.id}']" do
      fill_in 'search_attrs[search_text]', with: '2'
      click_button 'search'
    end

    # Wait for new results
    expect(page).to have_css('.search_count_reports .search_count', text: /\d+/, wait: 10)

    # Third search with different criteria '3' to ensure multiple searches work
    within ".searchable-report[data-report-id='#{@searchable_report.id}']" do
      fill_in 'search_attrs[search_text]', with: '3'
      click_button 'search'
    end

    # Wait for final results - verifies multiple searches in same session work
    expect(page).to have_css('.search_count_reports .search_count', text: /\d+/, wait: 10)
  end

  it 'auto-runs search when clicking auto-run report tab' do
    visit '/masters/search'
    finish_page_loading

    # Click the auto-run report tab
    click_link @auto_run_report.name
    expect(page).to have_css("#master-report-#{@auto_run_report.alt_resource_name}.in", wait: 5)

    # Auto-run should trigger search automatically - check for results count
    expect(page).to have_css('.search_count_reports .search_count', text: /\d+/, wait: 10)
  end

  it 'switches between report tabs without double requests' do
    visit '/masters/search'
    finish_page_loading

    # Set up JavaScript to track all search submissions
    page.execute_script(<<~JS)
      window.searchSubmitCount = 0;
      window.searchSubmitTimes = [];
      $(document).on('submit', 'form.search_report', function(e) {
        window.searchSubmitCount++;
        window.searchSubmitTimes.push(new Date().toISOString());
        console.log('Form submit #' + window.searchSubmitCount + ' at ' + window.searchSubmitTimes[window.searchSubmitTimes.length - 1]);
      });
    JS

    # Click first searchable report tab
    click_link @searchable_report.name
    expect(page).to have_css("#master-report-#{@searchable_report.alt_resource_name}.in", wait: 5)
    finish_page_loading

    # First search with criteria '1'
    within ".searchable-report[data-report-id='#{@searchable_report.id}']" do
      fill_in 'search_attrs[search_text]', with: '1'
      click_button 'search'
    end
    expect(page).to have_css('.search_count_reports .search_count', text: /\d+/, wait: 10)

    # Reset counter and do second search with different criteria
    page.execute_script('window.searchSubmitCount = 0; window.searchSubmitTimes = [];')

    within ".searchable-report[data-report-id='#{@searchable_report.id}']" do
      fill_in 'search_attrs[search_text]', with: '2'
      click_button 'search'
    end
    expect(page).to have_css('.search_count_reports .search_count', text: /\d+/, wait: 10)
    sleep 1

    # Verify only one search for the second criteria
    search_count = page.evaluate_script('window.searchSubmitCount')
    expect(search_count).to eq(1), "Expected 1 search for second criteria, but got #{search_count}"

    # Reset counter before switching tabs
    page.execute_script('window.searchSubmitCount = 0; window.searchSubmitTimes = [];')

    # Now switch to auto-run report tab
    click_link @auto_run_report.name
    expect(page).to have_css("#master-report-#{@auto_run_report.alt_resource_name}.in", wait: 5)
    finish_page_loading

    # Wait for auto-run search to complete
    expect(page).to have_css('.search_count_reports .search_count', text: /\d+/, wait: 10)

    # Give time for any duplicate requests
    sleep 2

    # Verify only ONE search request for the second report
    search_count = page.evaluate_script('window.searchSubmitCount')
    expect(search_count).to eq(1), "Expected 1 search request when switching tabs, but got #{search_count}"
  end

  it 'clears results when switching between tabs' do
    visit '/masters/search'
    finish_page_loading

    # Click auto-run report tab and wait for results
    click_link @auto_run_report.name
    expect(page).to have_css("#master-report-#{@auto_run_report.alt_resource_name}.in", wait: 5)
    expect(page).to have_css('.search_count_reports .search_count', text: /\d+/, wait: 10)

    # Switch to Simple Search tab
    click_button 'Simple Search'
    expect(page).to have_css('#master-search-simple-form.in', wait: 5)

    # Results count should be cleared (0 or empty)
    # Wait for the collapse animation and clearing
    sleep 1
    count_el = find('.search_count_reports', visible: :all)
    expect(count_el.text).to match(/^(0|)$/), 'Results count should be cleared to 0 or empty'
  end

  it 'works correctly when switching from Simple Search to report tab' do
    visit '/masters/search'
    finish_page_loading

    # Start at Simple Search tab (default)
    expect(page).to have_css('#master-search-simple-form.in')

    # Now switch to a searchable auto-run report
    click_link @auto_run_report.name
    expect(page).to have_css("#master-report-#{@auto_run_report.alt_resource_name}.in", wait: 10)

    # Wait for form to load via AJAX
    expect(page).to have_css("#master-report-#{@auto_run_report.alt_resource_name} form.search_report", wait: 10)
    finish_page_loading

    # Auto-run should complete - check for results count appearing
    using_wait_time(15) do
      expect(page).to have_css('.search_count_reports .search_count', text: /\d+/)
    end
  end
end
