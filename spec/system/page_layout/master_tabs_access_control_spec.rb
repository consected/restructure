# frozen_string_literal: true

# Spec for GitHub Issue #673: Master tabs (and drop downs) should be hidden if a user doesn't have access to them
#
# This spec tests that:
# 1. Navigation links in master tabs dropdown are filtered based on user access
# 2. The entire dropdown disappears if user has no access to any links
# 3. Users with partial access see only their accessible links
# 4. Report links are verified to work when clicked (navigating to the report page)
#
# Note: Only report resources (resource_type: report) are supported in navigation tab dropdowns.
# Table resources (activity logs, external identifiers, etc.) are not supported in nav dropdowns
# as they require the panel partial rendering which is incompatible with the dropdown context.

require 'rails_helper'

describe 'master tabs access control filtering', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    SetupHelper.feature_setup

    @admin, @admin_password = create_admin

    @app_type = Admin::AppType.where(name: 'zeus').first

    # Create 4 unique reports for this test (reports don't have default access)
    @reports = []
    @report_prefix = "test_nav_#{SecureRandom.hex(4)}"
    4.times do |i|
      report = Report.create!(
        name: "#{@report_prefix}_report_#{i + 1}",
        description: "Nav Test Report #{i + 1}",
        item_type: :player_info,
        report_type: 'regular',
        sql: 'select 1 as id',
        current_admin: @admin,
        disabled: false
      )
      @reports << report
    end

    # Build the links YAML for nav panel (only reports - table resources not supported in nav dropdowns)
    nav_options = <<~YAML
      nav:
        label: test nav links
        links:
          - label: Nav Test Report 1
            resource_type: report
            resource_name: #{@reports[0].name}
            url: /reports/#{@reports[0].name}
          - label: Nav Test Report 2
            resource_type: report
            resource_name: #{@reports[1].name}
            url: /reports/#{@reports[1].name}
          - label: Nav Test Report 3
            resource_type: report
            resource_name: #{@reports[2].name}
            url: /reports/#{@reports[2].name}
          - label: Nav Test Report 4
            resource_type: report
            resource_name: #{@reports[3].name}
            url: /reports/#{@reports[3].name}
    YAML

    # Find or create the master-tabs nav panel
    @nav_panel = Admin::PageLayout.where(layout_name: 'nav', panel_name: 'master-tabs', app_type: @app_type).first
    if @nav_panel
      # Store original options for later restoration
      @original_options = @nav_panel.options
      @original_disabled = @nav_panel.disabled
      @nav_panel.update!(
        disabled: false,
        current_admin: @admin,
        options: nav_options.strip
      )
    else
      @nav_panel = Admin::PageLayout.create!(
        layout_name: 'nav',
        panel_name: 'master-tabs',
        panel_label: 'test nav links',
        panel_position: 0,
        app_type: @app_type,
        current_admin: @admin,
        options: nav_options.strip
      )
    end

    # Create a dummy master panel so that the custom tabs layout is used (otherwise default tabs are shown which don't support custom nav)
    @dummy_master_panel = Admin::PageLayout.where(
        layout_name: 'master',
        panel_name: 'dummy_details',
        app_type: @app_type
      ).first
    
    unless @dummy_master_panel
      @dummy_master_panel = Admin::PageLayout.create!(
        layout_name: 'master',
        panel_name: 'dummy_details',
        panel_label: 'Details',
        panel_position: 10,
        app_type: @app_type,
        current_admin: @admin,
        options: <<~YAML
          contains:
            categories:
              - details
        YAML
      )
    end

    # Create three users with different access levels
    @user1, @password1 = create_user
    @user2, @password2 = create_user
    @user3, @password3 = create_user

    # User1: Full access to all 4 reports
    @reports.each do |report|
      setup_access(report.name, resource_type: :report, access: :read, user: @user1)
    end

    # User2: Access to only first 2 reports
    @reports.take(2).each do |report|
      setup_access(report.name, resource_type: :report, access: :read, user: @user2)
    end

    # User3: No access to any reports (should not see dropdown at all)

    # Give user1 create permissions for setup
    [:player_infos, :player_contacts].each do |res|
      setup_access(res, resource_type: :table, access: :create, user: @user1)
    end

    # Create a master record for testing
    @master = Master.create!(current_user: @user1)
    @player_info = @master.player_infos.create!(
      first_name: 'Test',
      last_name: 'NavAccess',
      current_user: @user1
    )

    # Give all users basic access to view master records and player contacts
    [@user1, @user2, @user3].each do |user|
      setup_access(:player_infos, resource_type: :table, access: :read, user: user)
      setup_access(:player_contacts, resource_type: :table, access: :read, user: user)
    end
  end

  after(:all) do
    # Restore original nav panel state
    if @original_options
      @nav_panel&.update(options: @original_options, disabled: @original_disabled, current_admin: @admin)
    else
      @nav_panel&.update(disabled: true, current_admin: @admin)
    end
    if @dummy_master_panel
      ActiveRecord::Base.connection.execute("DELETE FROM page_layout_history WHERE page_layout_id = #{@dummy_master_panel.id}")
      @dummy_master_panel.destroy
    end
    @reports&.each { |r| r.update!(disabled: true, current_admin: @admin) }
  end

  # Helper to open the nav dropdown and ensure all items are visible
  def open_nav_dropdown_with_full_height
    find('#extra-master-tab-drop').click
    sleep 0.3

    # Remove any height restrictions on dropdown and force all items visible
    page.execute_script(<<~JS)
      var dropdown = document.querySelector('.extra-master-tab-dropdown-menu');
      if (dropdown) {
        dropdown.style.maxHeight = 'none';
        dropdown.style.overflow = 'visible';
        dropdown.style.display = 'block';
        dropdown.style.position = 'relative';
        // Also ensure all list items are visible
        dropdown.querySelectorAll('li').forEach(function(li) {
          li.style.display = 'block';
          li.style.visibility = 'visible';
          li.style.opacity = '1';
        });
      }
    JS
    sleep 0.2

    find('.extra-master-tab-dropdown-menu')
  end

  describe 'user1 with full report access' do
    it 'sees all 4 report links in dropdown and can click them' do
      login_as(@user1, scope: :user)
      visit "/masters/#{@master.id}"
      finish_page_loading

      # Wait for master results to load
      expect(page).to have_css('.master-result', wait: 15)

      # Expand master record
      expand_master_record(master_id: @master.id)
      finish_page_loading

      # Check that nav dropdown exists
      expect(page).to have_css('#extra-master-tab-drop', wait: 10)
      expect(page).to have_content('test nav links')

      # Click dropdown to see all links
      dropdown = open_nav_dropdown_with_full_height

      # Verify all 4 report links are present
      all_links = dropdown.all('li.extra-master-tab', visible: :all)
      link_labels = all_links.map do |li|
        li.find('a', visible: :all).text
      rescue StandardError
        nil
      end.compact

      # All 4 report links should be present
      expect(all_links.count).to eq(4), "Expected 4 nav links but found #{all_links.count}: #{link_labels.inspect}"
      expect(link_labels).to include('Nav Test Report 1')
      expect(link_labels).to include('Nav Test Report 2')
      expect(link_labels).to include('Nav Test Report 3')
      expect(link_labels).to include('Nav Test Report 4')

      # Click Report 1 link and verify it works
      within(dropdown) do
        click_link 'Nav Test Report 1'
      end
      finish_page_loading
      expect(page).to have_current_path("/reports/#{@reports[0].name}")

      # Go back and test another report link
      visit "/masters/#{@master.id}"
      finish_page_loading
      expect(page).to have_css('.master-result', wait: 15)
      expand_master_record(master_id: @master.id)
      finish_page_loading

      dropdown = open_nav_dropdown_with_full_height
      within(dropdown) do
        click_link 'Nav Test Report 4'
      end
      finish_page_loading
      expect(page).to have_current_path("/reports/#{@reports[3].name}")
    end
  end

  describe 'user2 with partial report access' do
    it 'sees only 2 accessible report links' do
      login_as(@user2, scope: :user)
      visit "/masters/#{@master.id}"
      finish_page_loading

      # Wait for master results to load
      expect(page).to have_css('.master-result', wait: 15)

      # Expand master record
      expand_master_record(master_id: @master.id)
      finish_page_loading

      # Check that nav dropdown exists
      expect(page).to have_css('#extra-master-tab-drop', wait: 10)
      expect(page).to have_content('test nav links')

      # Click dropdown to see links
      dropdown = open_nav_dropdown_with_full_height

      # Verify link count and content
      all_links = dropdown.all('li.extra-master-tab', visible: :all)
      link_labels = all_links.map do |li|
        li.find('a', visible: :all).text
      rescue StandardError
        nil
      end.compact

      # User2 has access to first 2 reports only
      expect(all_links.count).to eq(2), "Expected 2 nav links but found #{all_links.count}: #{link_labels.inspect}"
      expect(link_labels).to include('Nav Test Report 1')
      expect(link_labels).to include('Nav Test Report 2')
      # Reports 3 and 4 should NOT be present - no access
      expect(link_labels).not_to include('Nav Test Report 3')
      expect(link_labels).not_to include('Nav Test Report 4')

      # Click the first report link to verify it works
      within(dropdown) do
        click_link 'Nav Test Report 1'
      end
      finish_page_loading
      expect(page).to have_current_path("/reports/#{@reports[0].name}")
    end
  end

  describe 'user3 with no report access' do
    it 'does not see the nav dropdown (no accessible links)' do
      login_as(@user3, scope: :user)
      visit "/masters/#{@master.id}"
      finish_page_loading

      # Wait for master results to load
      expect(page).to have_css('.master-result', wait: 15)

      # Expand master record
      expand_master_record(master_id: @master.id)
      finish_page_loading

      # Nav dropdown should NOT exist because user has no access to any reports
      expect(page).not_to have_css('#extra-master-tab-drop', wait: 5)
      expect(page).not_to have_content('test nav links')
    end
  end
end
