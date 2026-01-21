# frozen_string_literal: true

# Spec for GitHub Issue #857: External ids panel still not showing content when switching participants
#
# This spec tests the root cause of the issue identified in #857 (follow-up to #653):
# The problem is that when the external IDs tab panel is shown (collapsed → expanded),
# the on_open_click() function is NOT called to auto-click the AJAX links that load
# the external identifier content.
#
# The on_open_click mechanism only triggers when the master container is shown,
# not when individual tab panels within it are shown. When switching between masters,
# the external IDs panel content is not reloaded because:
# 1. The on_open_click links have their auto-clicked classes but no shown.bs.collapse handler
#    is set up to re-trigger them when the panel is re-shown
# 2. When the master container collapses, the nested external IDs panel retains its expanded
#    state but the content is not refreshed on re-expansion
#
# The fix should ensure that:
# 1. When any collapse panel containing .on-open-click is shown, on_open_click() is called
# 2. When any collapse panel is hidden, the auto-clicked classes are reset on its links

require 'rails_helper'

describe 'external ids panel on-open-click mechanism', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterSupport
  include MasterDataSupport
  include FeatureSupport
  include BhsImportConfig

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    BhsImportConfig.import_config
    SetupHelper.feature_setup

    create_admin

    # Ensure the external IDs tab is visible by disabling hide_player_tabs
    app = Admin::AppType.active.where(name: BhsImportConfig.bhs_app_name).first
    add_default_app_config(app, :hide_player_tabs, 'false')

    # Create test data with shared last name for search
    @shared_last_name = "PanelTest#{SecureRandom.hex(4)}"
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

  # Helper to collapse a master record by clicking its header
  def collapse_master_record(master_id:)
    master_container = find("#master-#{master_id}-main-container", visible: :all)
    return unless master_container[:class].include?('in')

    puts_debug "  Collapsing master #{master_id}...", force: true
    expand_master_record(master_id: master_id) # Clicking again toggles collapse
    sleep 1
  end

  # This test demonstrates the bug: when switching between masters,
  # the external IDs panel may appear blank because on_open_click is not called
  it 'loads external id content when switching between masters and clicking external ids tab' do
    # Navigate to search results with multiple master IDs
    master_ids = @masters.map(&:id).join(',')
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{master_ids}"
    dismiss_modal
    finish_page_loading
    sleep 1

    # We'll track which masters show blank panels
    blank_panels_found = []

    # CRITICAL: The bug only manifests when you DON'T start with the first participant.
    # Start with the LAST participant (master 3), then switch to others.
    # Test pattern: Expand master 3 → external ids → expand master 1 → external ids
    # Then go back to master 3 → external ids and check if content loads

    # Assign masters - we'll start with the last one
    master1 = @masters[0]
    master2 = @masters[1]
    master3 = @masters[2]

    # Step 1: Expand the LAST master first (NOT the first!) and its external IDs tab
    puts_debug "Step 1: Expanding master #{master3.id} (the LAST one - critical for bug reproduction)", force: true
    expand_master_record(master_id: master3.id)
    expect(page).to have_css("#master-#{master3.id}-main-container.in", wait: 10)
    finish_form_formatting

    puts_debug 'Step 1: Clicking external ids tab on master 3', force: true
    expand_master_record_tab('external ids')
    finish_page_loading
    sleep 1

    # Capture browser console logs for debugging
    browser_logs = page.driver.browser.logs.get(:browser)
    browser_logs.each do |log|
      puts_debug "  [Browser Console] #{log.level}: #{log.message}", force: true if log.level == 'SEVERE' || log.message.include?('on_open_click') || log.message.include?('ajax')
    end

    # Verify master 3 external IDs are loaded
    ext_panel_3 = find("#external-ids-#{master3.id}", visible: :all)
    within(ext_panel_3) do
      # Wait longer to rule out timing issues
      sleep 5
      bhs_block = all("[id^='bhs-assignments-#{master3.id}']", wait: 10).first
      if bhs_block.nil? || bhs_block.text.strip.empty?
        puts_debug '  Master 3 external IDs panel is BLANK (first load) - even after 5 second wait!', force: true
        take_screenshot('bug_857_first_load_blank', 'Master 3 external IDs blank on first load', force: true)
        save_html_snapshot('/tmp/bug_857_first_load_blank.html')
        blank_panels_found << { master_id: master3.id, step: 'first_load' }
      else
        puts_debug '  ✓ Master 3 external IDs content loaded', force: true
      end
    end

    # Step 2: Now expand master 1 (the first one in the list)
    puts_debug "Step 2: Expanding master #{master1.id} (first in list)", force: true
    expand_master_record(master_id: master1.id)
    expect(page).to have_css("#master-#{master1.id}-main-container.in", wait: 10)
    finish_form_formatting

    puts_debug 'Step 2: Clicking external ids tab on master 1', force: true
    expand_master_record_tab('external ids')
    finish_page_loading
    sleep 1

    # Verify master 1 external IDs are loaded
    ext_panel_1 = find("#external-ids-#{master1.id}", visible: :all)
    within(ext_panel_1) do
      sleep 2
      bhs_block = all("[id^='bhs-assignments-#{master1.id}']", wait: 5).first
      if bhs_block.nil? || bhs_block.text.strip.empty?
        puts_debug '  Master 1 external IDs panel is BLANK', force: true
        blank_panels_found << { master_id: master1.id, step: 'master1_first_load' }
      else
        puts_debug '  ✓ Master 1 external IDs content loaded', force: true
      end
    end

    # Step 3: Go back to master 3 - THIS IS WHERE THE BUG MANIFESTS
    puts_debug 'Step 3: Going back to master 3 (the critical test)', force: true
    expand_master_record(master_id: master3.id)
    expect(page).to have_css("#master-#{master3.id}-main-container.in", wait: 10)
    finish_form_formatting

    puts_debug 'Step 3: Clicking external ids tab on master 3 again', force: true
    expand_master_record_tab('external ids')
    finish_page_loading
    sleep 2 # Give more time for AJAX

    # THIS IS THE CRITICAL CHECK - the panel should have content
    ext_panel_3_revisit = find("#external-ids-#{master3.id}", visible: :all)

    within(ext_panel_3_revisit) do
      sleep 2
      bhs_block = all("[id^='bhs-assignments-#{master3.id}']", wait: 5).first
      panel_text = ext_panel_3_revisit.text.strip

      if bhs_block.nil? || panel_text.empty?
        puts_debug '  !!! BUG REPRODUCED: Master 3 external IDs panel is BLANK after returning!', force: true
        puts_debug "  Panel text: '#{panel_text.truncate(100)}'", force: true
        take_screenshot('bug_857_reproduced', 'External IDs panel blank after switching back', force: true)
        save_html_snapshot('/tmp/bug_857_reproduced.html')
        blank_panels_found << { master_id: master3.id, step: 'return_visit' }
      else
        puts_debug '  ✓ Master 3 external IDs content loaded on return', force: true
      end
    end

    # Step 4: Test with master 2 as well
    puts_debug 'Step 4: Testing second master', force: true
    expand_master_record(master_id: master2.id)
    expect(page).to have_css("#master-#{master2.id}-main-container.in", wait: 10)
    finish_form_formatting

    expand_master_record_tab('external ids')
    finish_page_loading
    sleep 1

    ext_panel_2 = find("#external-ids-#{master2.id}", visible: :all)
    within(ext_panel_2) do
      sleep 2
      bhs_block = all("[id^='bhs-assignments-#{master2.id}']", wait: 5).first
      if bhs_block.nil? || bhs_block.text.strip.empty?
        puts_debug '  Master 2 external IDs panel is BLANK', force: true
        blank_panels_found << { master_id: master2.id, step: 'master2_first_load' }
      else
        puts_debug '  ✓ Master 2 external IDs content loaded', force: true
      end
    end

    # Final check: Go back to master 1
    puts_debug 'Step 5: Going back to master 1', force: true
    expand_master_record(master_id: master1.id)
    expect(page).to have_css("#master-#{master1.id}-main-container.in", wait: 10)
    finish_form_formatting

    expand_master_record_tab('external ids')
    finish_page_loading
    sleep 2

    ext_panel_1_revisit = find("#external-ids-#{master1.id}", visible: :all)
    within(ext_panel_1_revisit) do
      sleep 2
      bhs_block = all("[id^='bhs-assignments-#{master1.id}']", wait: 5).first
      panel_text = ext_panel_1_revisit.text.strip

      if bhs_block.nil? || panel_text.empty?
        puts_debug '  !!! BUG REPRODUCED: Master 1 external IDs panel is BLANK after returning!', force: true
        blank_panels_found << { master_id: master1.id, step: 'return_visit' }
      else
        puts_debug '  ✓ Master 1 external IDs content loaded on return', force: true
      end
    end

    # Report results
    if blank_panels_found.any?
      puts_debug "BUG REPRODUCED: Found #{blank_panels_found.length} blank panel(s):", force: true
      blank_panels_found.each do |b|
        puts_debug "  Master #{b[:master_id]} at step: #{b[:step]}", force: true
      end
      # Fail the test to indicate the bug exists
      expect(blank_panels_found).to be_empty,
                                    "External IDs panel bug: #{blank_panels_found.length} panel(s) were blank. " \
                                    "Steps affected: #{blank_panels_found.map { |b| b[:step] }.join(', ')}"
    else
      puts_debug '✓ All external IDs panels loaded content correctly', force: true
    end
  end

  # This test verifies that the on_open_click mechanism correctly loads
  # external ID content when the panel is expanded
  it 'triggers on_open_click for external ids panel when tab is expanded' do
    # Use 2 masters to test the multi-master scenario
    master1 = @masters.first
    master2 = @masters.second

    # Navigate to search results with 2 masters
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{master1.id},#{master2.id}"
    dismiss_modal
    finish_page_loading
    sleep 1

    # Expand master 1
    expand_master_record(master_id: master1.id)
    expect(page).to have_css("#master-#{master1.id}-main-container.in", wait: 10)
    finish_form_formatting

    # Click the external IDs tab to expand the panel
    puts_debug 'Clicking external ids tab...', force: true
    expand_master_record_tab('external ids')
    finish_page_loading
    sleep 2

    # The panel should now be expanded
    ext_panel = find("#external-ids-#{master1.id}", visible: :all)
    expect(ext_panel[:class].split(' ')).to include('in'), 'External IDs panel should be expanded'

    # The on-open-click links should have been clicked (auto-clicked class added)
    on_open_links = ext_panel.all('.on-open-click a[data-remote="true"]', visible: :all)
    puts_debug "Found #{on_open_links.count} on-open-click AJAX links", force: true

    links_auto_clicked = 0
    on_open_links.each do |link|
      classes = link[:class] || ''
      puts_debug "  Link: #{link[:href]}, classes: #{classes}", force: true
      links_auto_clicked += 1 if classes.include?('auto-clicked')
    end

    # All links should have been auto-clicked
    expect(links_auto_clicked).to eq(on_open_links.count),
                                  "Expected all #{on_open_links.count} links to be auto-clicked, " \
                                  "but only #{links_auto_clicked} were"

    # And the content should have loaded
    bhs_block = ext_panel.all("[id^='bhs-assignments-#{master1.id}']", wait: 5).first
    expect(bhs_block).not_to be_nil, 'BHS assignment block should be present after panel expansion'
    expect(bhs_block.text).not_to be_empty, 'BHS assignment block should have content'

    # Verify the BHS ID is displayed
    expect(ext_panel).to have_content(@bhs_ids.first.to_s, wait: 5),
                         "External IDs panel should display BHS ID #{@bhs_ids.first}"
  end
end
