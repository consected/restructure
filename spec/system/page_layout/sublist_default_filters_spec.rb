# frozen_string_literal: true

# Spec for GitHub Issue #584: Phone contacts rank filter buttons - need an app config for which to show as active
#
# This spec tests the page layout view_options configuration for:
#
# Requirement 1: active_sublist_values
#   - Array config [10,5] → only buttons matching those values have 'active' class
#   - String 'all' → all filter buttons have 'active' class
#   - Empty array [] → no filter buttons have 'active' class
#   - Missing key → falls back to current default (first button active)
#
# Requirement 2: sort_sublists
#   - 'desc' config → order button has data-order-val="desc"
#   - 'asc' config → order button has data-order-val="asc"
#   - Missing key → falls back to current default
#
# The view_options settings are configured in Admin::PageLayout for master panel layouts.
# Example configuration:
#   view_options:
#     active_sublist_values:
#       player_contacts: [10,5]
#       addresses: all
#       dynamic_model__other_contacts: []
#     sort_sublists:
#       player_contacts: desc
#       addresses: asc

require 'rails_helper'

describe 'sublist default filter configuration', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    SetupHelper.feature_setup

    @admin, @admin_password = create_admin

    # Use create_data_set_outside_tx to properly create test data visible to browser
    create_data_set_outside_tx

    # Create test user with access to master
    @user, @good_password = create_user
    @good_email = @user.email
    @app_type = @user.app_type
    expect(@user.two_factor_setup_required?).to be_falsey
    setup_access :player_infos, user: @user
    setup_access :addresses, user: @user
    setup_access :player_contacts, user: @user

    # Use the master created by create_data_set_outside_tx
    @master = create_master(@user)
    @master_id = @master.id

    @master.player_infos.create!(
      first_name: 'Sublist',
      last_name: 'FilterTest',
      birth_date: '1990-01-01',
      rank: 10,
      source: 'nflpa'
    )

    # Create test contacts with specific ranks
    @master.player_contacts.create!(
      data: '(555)111-1111',
      rec_type: 'phone',
      rank: 10 # Primary
    )

    @master.player_contacts.create!(
      data: '(555)222-2222',
      rec_type: 'phone',
      rank: 5 # Secondary
    )
    @master.player_contacts.create!(
      data: '(555)333-3333',
      rec_type: 'phone',
      rank: -1 # Bad contact
    )

    # Create or update the page layout with active_sublist_values configuration
    # First check for an existing panel (including disabled ones), then create if needed
    @panel_layout = Admin::PageLayout.where(
      layout_name: 'master',
      panel_name: 'details'
    ).where('app_type_id = ? OR app_type_id IS NULL', @app_type.id).first

    if @panel_layout
      @original_options = @panel_layout.options
      @original_disabled = @panel_layout.disabled
      @panel_layout.update!(
        disabled: false,
        current_admin: @admin,
        options: <<~YAML
          contains:
            categories:
              - details
          view_options:
            initial_show: true
            active_sublist_values:
              player_contacts: [10, 5]
        YAML
      )
    else
      @panel_layout = Admin::PageLayout.create!(
        layout_name: 'master',
        panel_name: 'details',
        panel_label: 'Details',
        panel_position: 0,
        app_type: @app_type,
        current_admin: @admin,
        options: <<~YAML
          contains:
            categories:
              - details
          view_options:
            initial_show: true
            active_sublist_values:
              player_contacts: [10, 5]
        YAML
      )
    end

    add_app_config(@app_type, 'open panels', 'details', user: @user)
  end

  after(:all) do
    # Restore original options if we modified an existing layout
    if @panel_layout && @original_options
      @panel_layout.update!(
        current_admin: @admin,
        options: @original_options,
        disabled: @original_disabled
      )
    elsif @panel_layout && !@original_options
      @panel_layout.update!(current_admin: @admin, disabled: true)
    end
  end

  before :each do
    login
  end

  it 'activates only filter buttons matching the configured array values - fixes #584' do
    # Navigate to the master record
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    finish_page_loading

    # Wait for search results to load (the master-result heading)
    expect(page).to have_css("#master-#{@master.id}", wait: 10)
    dismiss_modal

    # Wait for master content to be fully rendered - look for player_contacts with an ID
    # The ID indicates Handlebars has rendered the template with actual data
    unless page.has_css?("[id^='player_contacts-#{@master.id}']", wait: 15)
      # The Handlebars templates haven't been rendered yet
      # Try clicking the master expander to trigger content load
      master_link = find("#master-#{@master.id} a.master-expander", wait: 5)
      scroll_into_view(master_link)
      master_link.click
      finish_page_loading
      sleep 3 # Allow time for AJAX and Handlebars rendering
    end

    # Debug if player_contacts still not found
    unless page.has_css?("[id^='player_contacts-#{@master.id}']", wait: 10)
      # Check for JavaScript errors
      puts '=== Checking for JS errors ==='
      begin
        logs = page.driver.browser.logs.get(:browser)
        logs.each { |log| puts "Browser log: #{log.level} - #{log.message}" }
      rescue StandardError => e
        puts "Could not get browser logs: #{e.message}"
      end

      debug_process_status
      save_html_snapshot('/tmp/sublist_expanded.html')
      raise 'Could not find player_contacts. Check /tmp/sublist_expanded.html'
    end

    expect(page).not_to have_css('.alert-danger')

    # Find the player_contacts sublist filter buttons
    within '[data-sub-list="player_contacts"] .sublist-filter-selectors' do
      # Buttons for rank 10 and 5 should be active (in our configuration)
      filter_10 = find('button.filter-switch[data-filter-val="10"]')
      filter_5 = find('button.filter-switch[data-filter-val="5"]')
      filter_other = find('button.filter-switch[data-filter-val="-1"]')

      expect(filter_10[:class]).to include('active'),
                                   'Expected filter button for rank 10 to be active based on active_sublist_values config'
      expect(filter_5[:class]).to include('active'),
                                  'Expected filter button for rank 5 to be active based on active_sublist_values config'
      expect(filter_other[:class]).not_to include('active'),
                                          'Expected filter button for rank -1 to NOT be active (not in active_sublist_values config)'
    end
  end

  it 'activates all filter buttons when configured with "all" value' do
    # Update config to use 'all'
    @panel_layout.update!(
      current_admin: @admin,
      options: <<~YAML
        contains:
          categories:
            - details
        view_options:
          initial_show: true
          active_sublist_values:
            player_contacts: all
      YAML
    )

    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    finish_page_loading
    expect(page).to have_css("#master-#{@master.id}", wait: 10)
    dismiss_modal

    unless page.has_css?("[id^='player_contacts-#{@master.id}']", wait: 15)
      master_link = find("#master-#{@master.id} a.master-expander", wait: 5)
      scroll_into_view(master_link)
      master_link.click
      finish_page_loading
      sleep 3
    end

    within '[data-sub-list="player_contacts"] .sublist-filter-selectors' do
      # All buttons should be active when 'all' is configured
      all('button.filter-switch').each do |button|
        expect(button[:class]).to include('active'),
                                  "Expected all filter buttons to be active when active_sublist_values is 'all'"
      end
    end
  end

  it 'activates no filter buttons when configured with empty array' do
    # Update config to use empty array
    @panel_layout.update!(
      current_admin: @admin,
      options: <<~YAML
        contains:
          categories:
            - details
        view_options:
          initial_show: true
          active_sublist_values:
            player_contacts: []
      YAML
    )

    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    finish_page_loading
    expect(page).to have_css("#master-#{@master.id}", wait: 10)
    dismiss_modal

    unless page.has_css?("[id^='player_contacts-#{@master.id}']", wait: 15)
      master_link = find("#master-#{@master.id} a.master-expander", wait: 5)
      scroll_into_view(master_link)
      master_link.click
      finish_page_loading
      sleep 3
    end

    within '[data-sub-list="player_contacts"] .sublist-filter-selectors' do
      # No buttons should be active when empty array is configured
      all('button.filter-switch').each do |button|
        expect(button[:class]).not_to include('active'),
                                      'Expected no filter buttons to be active when active_sublist_values is empty array'
      end
    end
  end

  it 'falls back to first button active when key is missing from config' do
    # Update config without player_contacts key
    @panel_layout.update!(
      current_admin: @admin,
      options: <<~YAML
        contains:
          categories:
            - details
        view_options:
          initial_show: true
          active_sublist_values:
            addresses: all
      YAML
    )

    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    finish_page_loading
    expect(page).to have_css("#master-#{@master.id}", wait: 10)
    dismiss_modal

    unless page.has_css?("[id^='player_contacts-#{@master.id}']", wait: 15)
      master_link = find("#master-#{@master.id} a.master-expander", wait: 5)
      scroll_into_view(master_link)
      master_link.click
      finish_page_loading
      sleep 3
    end

    within '[data-sub-list="player_contacts"] .sublist-filter-selectors' do
      buttons = all('button.filter-switch')
      # First button should be active (default behavior when no config)
      expect(buttons.first[:class]).to include('active'),
                                       'Expected first filter button to be active as fallback when key missing'
      # Other buttons should not be active
      buttons[1..].each do |button|
        expect(button[:class]).not_to include('active'),
                                      'Expected non-first buttons to be inactive as fallback when key missing'
      end
    end
  end

  it 'sets sort order based on sort_sublists configuration' do
    # Update config to include sort order
    @panel_layout.update!(
      current_admin: @admin,
      options: <<~YAML
        contains:
          categories:
            - details
        view_options:
          initial_show: true
          sort_sublists:
            player_contacts: desc
      YAML
    )

    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    finish_page_loading
    expect(page).to have_css("#master-#{@master.id}", wait: 10)
    dismiss_modal

    unless page.has_css?("[id^='player_contacts-#{@master.id}']", wait: 15)
      master_link = find("#master-#{@master.id} a.master-expander", wait: 5)
      scroll_into_view(master_link)
      master_link.click
      finish_page_loading
      sleep 3
    end

    within '[data-sub-list="player_contacts"] .sublist-order-selector' do
      order_button = find('button.order-switch')
      expect(order_button['data-order-val']).to eq('desc'),
                                                'Expected order button to have data-order-val="desc" based on sort_sublists config'
    end
  end
end
