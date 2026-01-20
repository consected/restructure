# frozen_string_literal: true

# Spec for GitHub Issue #653: External ids panel intermittently not showing any content
#
# This spec tests the scenario where:
# 1. Multiple participants with the same last name exist
# 2. Each participant has at least one external identifier
# 3. User performs a search returning multiple participants
# 4. User clicks between different participants' master headers
# 5. User clicks the "external id" tab on each participant
#
# The bug: Sometimes clicking another participant's master header and then its
# "external id" tab leads to a blank panel appearing without any external identifier blocks.

require 'rails_helper'

describe 'external ids panel switching between participants', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include BhsImportConfig

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    BhsImportConfig.import_config
    SetupHelper.feature_setup

    create_admin

    # Create test data with shared last name
    @shared_last_name = "TestSurname#{SecureRandom.hex(4)}"
    @masters = []
    @bhs_ids = []

    create_data_set_outside_tx

    gs = Classification::GeneralSelection.all
    gs.each do |g|
      g.current_admin = @admin
      g.create_with = true
      g.edit_always = true
      g.save
    end

    @user, @good_password = create_user
    @good_email = @user.email
    resource_name = :bhs_assignments
    setup_access resource_name, resource_type: :table, access: :create, user: @user
    setup_access :player_infos, resource_type: :table, access: :create, user: @user

    # Create 3 masters with the same last name, each with external identifiers
    3.times do |i|
      master = Master.create!(current_user: @user)
      first_name = "FirstName#{i}"
      master.current_user = @user
      master.player_infos.create!(
        first_name: first_name,
        last_name: @shared_last_name,
        birth_date: Date.new(1980 + i, 1, 1),
        current_user: @user
      )

      # Create BHS external identifier for each master
      bhs_id = rand(100_000_000..999_999_999)
      master.bhs_assignments.create!(bhs_id: bhs_id, current_user: @user)
      @bhs_ids << bhs_id
      @masters << master
    end

    ActivityLog.define_models
    validate_setup
    validate_bhs_setup
  end

  before :each do
    ActivityLog.define_models
    validate_setup
    validate_bhs_setup
    login
  end

  it 'shows external ids panel content when switching between multiple participants' do
    # Debug: Show what masters we're searching for
    puts_debug "Masters created: #{@masters.map(&:id).join(', ')}", force: true
    @masters.each do |m|
      pi = m.player_infos.first
      puts_debug "  Master #{m.id}: #{pi&.first_name} #{pi&.last_name}", force: true
    end

    # Navigate to search results with multiple master IDs
    # Using nav_q_id with comma-separated IDs to get multiple results
    master_ids = @masters.map(&:id).join(',')
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{master_ids}"
    dismiss_modal
    finish_page_loading
    sleep 2

    # Debug: Check what we got
    puts_debug "Current URL: #{current_url}", force: true
    puts_alerts

    # Check if master panels exist but are hidden
    all_panels = all('.master-panel', visible: :all)
    visible_panels = all('.master-panel', visible: true, wait: 2)
    puts_debug "All master panels (including hidden): #{all_panels.count}", force: true
    puts_debug "Visible master panels: #{visible_panels.count}", force: true

    if visible_panels.empty? && all_panels.any?
      puts_debug 'Master panels exist but are hidden. Saving HTML for analysis...', force: true
      save_html_snapshot('/tmp/hidden_master_panels.html')
      take_screenshot('hidden_master_panels', 'Master panels hidden', force: true)
      all_panels.each do |p|
        puts_debug "  Panel ID: #{p[:id]}, class: #{p[:class]}", force: true
      end
    end

    debug_process_status if visible_panels.empty?

    # Verify we have multiple master results - use visible: :all to get past hidden panels
    expect(all_panels.count).to be >= 2, "Expected at least 2 master panels, but found #{all_panels.count}"
    master_panels = all_panels
    puts_debug "Found #{master_panels.count} master panels", force: true

    # Test each master's external ids panel
    @masters.each_with_index do |master, index|
      puts_debug "Testing master #{index + 1} (ID: #{master.id})", force: true

      # Expand the master record using helper
      expand_master_record(master_id: master.id)

      # Wait for master container to load
      expect(page).to have_css("#master-#{master.id}-main-container.in.loaded-master-main", wait: 10)
      finish_form_formatting

      # Expand the external ids tab using helper
      puts_debug "  Clicking external ids tab for master #{master.id}", force: true
      expand_master_record_tab('external ids')

      finish_page_loading
      sleep 1

      # Verify the external ids panel is shown and has content
      ext_ids_panel = all("#external-ids-#{master.id}").first
      unless ext_ids_panel
        puts_debug "  WARNING: External ids panel #external-ids-#{master.id} not found!", force: true
        debug_state("no_ext_panel_master_#{master.id}", 'External ids panel not found after click')
        take_screenshot("external_ids_blank_#{master.id}", 'External IDs panel blank', force: true)
        save_html_snapshot("/tmp/external_ids_blank_#{master.id}.html")
        expect(ext_ids_panel).not_to be_nil, "External ids panel should exist for master #{master.id}"
        next
      end

      puts_debug "  Found external ids panel: #external-ids-#{master.id}", force: true

      # Check if the panel has content (external id blocks)
      within(ext_ids_panel) do
        # Wait for AJAX content to load - external ids are loaded via data-remote links
        sleep 2
        finish_page_loading

        # Look for BHS assignment block content
        ext_id_content = all('.external-identifier, [data-model-data-type="external_identifier"], .external-ids-panel', wait: 5)

        if ext_id_content.empty?
          puts_debug "  WARNING: No external id content found in panel for master #{master.id}!", force: true
          puts_debug "  Panel HTML preview: #{ext_ids_panel.text.truncate(200)}", force: true
          debug_state("empty_ext_panel_master_#{master.id}", 'External ids panel is empty')
          take_screenshot("external_ids_empty_#{master.id}", 'External IDs panel empty', force: true)
          save_html_snapshot("/tmp/external_ids_empty_#{master.id}.html")
        else
          puts_debug "  ✓ Found #{ext_id_content.count} external id content elements", force: true
        end

        # Check for the specific BHS assignment
        bhs_block = all("[id^='bhs-assignments-#{master.id}']", wait: 3).first
        if bhs_block
          puts_debug '  ✓ Found BHS assignment block', force: true
          expect(bhs_block.text).not_to be_empty, "BHS block should have content for master #{master.id}"
        else
          puts_debug "  WARNING: BHS assignment block not found for master #{master.id}", force: true
          panel_children = all('*', visible: true).map { |e| "#{e.tag_name}##{e[:id]}.#{e[:class]}" }.first(10)
          puts_debug "  Panel children (first 10): #{panel_children.join(', ')}", force: true
          debug_state("no_bhs_block_master_#{master.id}", 'BHS block not found in external ids panel')
        end
      end

      # Log before switching to next
      puts_debug "  Collapsing master #{master.id} before switching to next", force: true if index < @masters.length - 1
    end

    # Now do rapid switching between masters to trigger the intermittent bug
    puts_debug 'Testing rapid switching between masters...', force: true
    bug_reproduced = false
    bug_details = []

    5.times do |iteration|
      @masters.each_with_index do |master, index|
        puts_debug "  Rapid switch iteration #{iteration + 1}, master #{index + 1}", force: true

        # Expand master using helper
        expand_master_record(master_id: master.id)

        # Wait for container to be visible
        expect(page).to have_css("#master-#{master.id}-main-container.in", wait: 5)

        # Expand external ids tab using helper
        expand_master_record_tab('external ids')
        sleep 0.5

        # Wait for external ids panel to expand
        sleep 1

        # Check for the bug - panel is open but empty
        ext_ids_panel = all("#external-ids-#{master.id}.in, #external-ids-#{master.id}.collapse.in", visible: :all).first

        if ext_ids_panel
          # Panel exists - check if it has content (BHS assignment block)
          bhs_block = all("[id^='bhs-assignments-#{master.id}']", visible: :all).first
          panel_text = ext_ids_panel.text.strip

          if bhs_block.nil? || panel_text.empty?
            puts_debug "  !!! BUG REPRODUCED: Empty external ids panel for master #{master.id} during rapid switch!", force: true
            puts_debug "    Panel text: '#{panel_text.truncate(100)}'", force: true
            puts_debug "    BHS block present: #{!bhs_block.nil?}", force: true
            take_screenshot("bug_reproduced_#{iteration}_#{master.id}", 'Bug reproduced - empty panel during rapid switch', force: true)
            save_html_snapshot("/tmp/bug_reproduced_#{iteration}_#{master.id}.html")
            bug_reproduced = true
            bug_details << { iteration:, master_id: master.id, panel_text: panel_text.truncate(100) }
          else
            puts_debug '    ✓ Panel has content', force: true
          end
        else
          puts_debug "  Panel not found or not expanded for master #{master.id}", force: true
        end
      end
    end

    puts_debug 'External ids panel switching test completed', force: true

    # Report results
    if bug_reproduced
      puts_debug "BUG WAS REPRODUCED #{bug_details.length} time(s):", force: true
      bug_details.each do |d|
        puts_debug "  Iteration #{d[:iteration]}, Master #{d[:master_id]}: '#{d[:panel_text]}'", force: true
      end
      # Fail the test to indicate the bug is confirmed
      expect(bug_reproduced).to be(false),
                                "External IDs panel bug reproduced: Panel was empty #{bug_details.length} time(s) during rapid switching. See screenshots and HTML snapshots in /tmp/"
    else
      puts_debug 'Bug was NOT reproduced in this run', force: true
    end
  end
end
