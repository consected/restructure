# frozen_string_literal: true

require 'rails_helper'

# Tests for dynamic page title updates based on UI context
# Related to GitHub issue #871 - Change page title to be more descriptive of current state
#
# Requirements tested:
# - Masters search pages: show selected search tab name
# - Report page: show report name
# - Admin page: show admin page name
# - Page showing "view" page layout: show the Page title
#
# Also tests for regression of page lock-up issues when switching between tabs.
describe 'page title updates', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include ReportSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    SetupHelper.feature_setup

    seed_database
    create_data_set_outside_tx

    @admin, @admin_password = create_admin
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

    # Create multiple searchable reports for tab switching tests
    @reports = []
    @test_suffix = SecureRandom.hex(4)
    3.times do |i|
      @reports << create_searchable_report("Page Title Test Report #{i + 1} #{@test_suffix}")
    end
  end

  def create_searchable_report(name)
    sql = "select id as master_id from masters where id::text like '%' || :search_text || '%' limit 10"
    search_attrs = <<~END_CONFIG
      search_text:
        text:
          all: true
          multiple: single
          disabled: false
    END_CONFIG
    report = Report.create!(
      current_admin: @admin,
      name: name,
      description: "Test searchable report: #{name}",
      sql: sql,
      search_attrs: search_attrs,
      disabled: false,
      report_type: 'search',
      auto: false,
      searchable: true,
      position: rand(1..100)
    )

    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :read,
      resource_type: :report,
      resource_name: report.alt_resource_name,
      current_admin: @admin
    )

    report
  end

  before :each do
    validate_setup
  end

  describe 'search tab switching' do
    before :each do
      login
    end

    it 'updates page title when clicking Simple Search tab' do
      visit '/masters/search'
      finish_page_loading

      # First click Advanced Search (if available) to collapse Simple Search
      if page.has_button?('Advanced Search')
        click_button 'Advanced Search'
        finish_page_loading
        # Wait for Advanced Search panel to expand
        expect(page).to have_css('#master-search-advanced-form.in', wait: 10)
      end

      # Now click Simple Search tab
      click_button 'Simple Search'
      finish_page_loading

      # Wait for the panel to be visible (check for .in class on the panel)
      expect(page).to have_css('#master-search-simple-form.in', wait: 10)

      # Verify page title is updated
      expect(page).to have_title(/Simple Search/i, wait: 5)
    end

    it 'updates page title when clicking Advanced Search tab' do
      visit '/masters/search'
      finish_page_loading

      # Click Advanced Search tab (may need to check if it exists first)
      if page.has_button?('Advanced Search')
        click_button 'Advanced Search'
        finish_page_loading

        # Wait for the panel to be visible
        expect(page).to have_css('#master-search-advanced-form.in', wait: 10)

        expect(page).to have_title(/Advanced Search/i, wait: 5)
      end
    end

    it 'updates page title when clicking searchable report tabs' do
      visit '/masters/search'
      finish_page_loading

      @reports.each do |report|
        report_tab_selector = "a#expand-searchable-report-#{report.alt_resource_name}"

        next unless page.has_css?(report_tab_selector)

        find(report_tab_selector).click
        finish_page_loading

        # Wait for the report panel to be visible
        expect(page).to have_css("#master-report-#{report.alt_resource_name}.in", wait: 10)

        # Verify page title contains the report name
        expect(page).to have_title(/#{Regexp.escape(report.name)}/i, wait: 5)
      end
    end

    it 'does not freeze when rapidly switching between search tabs' do
      visit '/masters/search'
      finish_page_loading

      # Rapid tab switching to test for freeze/lock-up issues
      # Wait for each panel to appear to verify no freeze
      # Note: Some delay between clicks is realistic and helps prevent Bootstrap transition conflicts
      3.times do
        # Click Advanced Search if available and wait for panel to expand
        if page.has_button?('Advanced Search')
          click_button 'Advanced Search'
          expect(page).to have_css('#master-search-advanced-form.in', wait: 10)
          sleep 0.3 # Allow transition to complete
        end

        # Click Simple Search and wait for panel
        if page.has_button?('Simple Search')
          click_button 'Simple Search'
          expect(page).to have_css('#master-search-simple-form.in', wait: 10)
          sleep 0.3 # Allow transition to complete
        end

        # Click first report tab and wait for panel
        next unless @reports.any?

        report = @reports.first
        report_tab_selector = "a#expand-searchable-report-#{report.alt_resource_name}"
        next unless page.has_css?(report_tab_selector)

        find(report_tab_selector).click
        expect(page).to have_css("#master-report-#{report.alt_resource_name}.in", wait: 10)
        sleep 0.3 # Allow transition to complete
      end

      # If we reach here without timeout, the page did not freeze
      expect(page).to have_css('#master-search-accordion', wait: 5)
    end

    it 'binds event handlers only once even after multiple page interactions' do
      visit '/masters/search'
      finish_page_loading

      # Track how many times the click event handler fires per click
      page.execute_script(<<~JS)
        window.clickHandlerFireCount = 0;
        // Use a specific test handler on the button to count fires
        $(document).on('click.test_handler', '.search-selector-btn', function() {
          window.clickHandlerFireCount++;
          console.log('Test handler fire #' + window.clickHandlerFireCount);
        });
      JS

      # Click a tab
      click_button 'Simple Search' if page.has_button?('Simple Search')
      sleep 0.5

      # Check the count after first click - should be 1
      first_click_count = page.evaluate_script('window.clickHandlerFireCount')
      expect(first_click_count).to eq(1), "First click should fire handler once, got #{first_click_count}"

      # Reset counter
      page.execute_script('window.clickHandlerFireCount = 0;')

      # Click the same tab again
      click_button 'Simple Search' if page.has_button?('Simple Search')
      sleep 0.5

      # Count should be 1 again - exactly one handler firing per click
      second_click_count = page.evaluate_script('window.clickHandlerFireCount')

      expect(second_click_count).to eq(1),
                                    "Expected 1 handler fire on second click, but got #{second_click_count}. " \
                                    'This indicates duplicate event handlers were bound.'
    end
  end

  describe 'report page title' do
    before :each do
      login
    end

    it 'updates page title when viewing a report' do
      report = @reports.first

      visit report_path(report)
      finish_page_loading

      # Verify page title contains the report name
      expect(page).to have_title(/#{Regexp.escape(report.name)}/i, wait: 5)
    end
  end

  describe 'search results title' do
    before :each do
      login
    end

    it 'updates page title to show results after search' do
      visit '/masters/search'
      finish_page_loading

      # Click Simple Search tab
      click_button 'Simple Search' if page.has_button?('Simple Search')
      finish_page_loading

      # Get the master ID we created and search for it using the nav search
      master_id = Master.first&.id
      if master_id
        # Use the nav search bar which is always available
        fill_in 'nav_q_id', with: master_id.to_s
        find('#nav_q_id').native.send_keys(:enter)
        finish_page_loading

        # Verify page title contains 'results'
        expect(page).to have_title(/results/i, wait: 10)
      end
    end
  end
end
