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

    # Ensure the BHS external identifier is formatted how we expect
    resource_name = :bhs_assignments
    bhs = ExternalIdentifier.active.where(name: resource_name).first
    bhs.force_regenerate = true
    bhs.update! external_id_edit_pattern: nil, external_id_view_formatter: nil, current_admin: @admin

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

  # This test demonstrates the bug: when switching between masters,
  # the external IDs panel may appear blank because on_open_click is not called
  it 'loads external id content when switching between masters and clicking external ids tab' do
    # Navigate to search results with multiple master IDs
    master_ids = @masters.map(&:id).join(',')
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{master_ids}"
    dismiss_modal
    finish_page_loading

    # CRITICAL: The bug only manifests when you DON'T start with the first participant.
    # Start with the LAST participant (master 3), then switch to others.
    # Test pattern: Expand master 3 → external ids → expand master 1 → external ids
    # Then go back to master 3 → external ids and check if content loads

    # Assign masters - we'll start with the last one
    master1 = @masters[0]
    master2 = @masters[1]
    master3 = @masters[2]

    # Step 1: Expand the LAST master first (NOT the first!) and its external IDs tab
    expand_master_record(master_id: master3.id)
    expect(page).to have_css("#master-#{master3.id}-main-container.in", wait: 10)
    finish_form_formatting

    expand_master_record_tab('external ids', master_id: master3.id)
    finish_page_loading

    # Verify master 3 external IDs are loaded
    ext_panel_3 = find("#external-ids-#{master3.id}", visible: :all)
    within(ext_panel_3) do
      bhs_block = all("[id^='bhs-assignments-#{master3.id}']", wait: 10).first
      expect(bhs_block).not_to be_nil, 'Master 3 external IDs should load on first expansion'
      expect(bhs_block.text.strip).not_to be_empty, 'Master 3 external IDs should have content'
    end

    # Step 2: Now expand master 1 (the first one in the list)
    expand_master_record(master_id: master1.id)
    expect(page).to have_css("#master-#{master1.id}-main-container.in", wait: 10)
    finish_form_formatting

    expand_master_record_tab('external ids', master_id: master1.id)
    finish_page_loading

    # Verify master 1 external IDs are loaded
    ext_panel_1 = find("#external-ids-#{master1.id}", visible: :all)
    within(ext_panel_1) do
      bhs_block = all("[id^='bhs-assignments-#{master1.id}']", wait: 10).first
      expect(bhs_block).not_to be_nil, 'Master 1 external IDs should load'
      expect(bhs_block.text.strip).not_to be_empty, 'Master 1 external IDs should have content'
    end

    # Step 3: Go back to master 3 - THIS IS WHERE THE BUG MANIFESTS
    expand_master_record(master_id: master3.id)
    expect(page).to have_css("#master-#{master3.id}-main-container.in", wait: 10)
    finish_form_formatting

    expand_master_record_tab('external ids', master_id: master3.id)
    finish_page_loading

    # THIS IS THE CRITICAL CHECK - the panel should have content when returning
    ext_panel_3_revisit = find("#external-ids-#{master3.id}", visible: :all)
    within(ext_panel_3_revisit) do
      bhs_block = all("[id^='bhs-assignments-#{master3.id}']", wait: 10).first
      expect(bhs_block).not_to be_nil, 'Master 3 external IDs should load when returning'
      expect(bhs_block.text.strip).not_to be_empty, 'Master 3 external IDs should have content when returning'
    end

    # Step 4: Test with master 2 as well
    expand_master_record(master_id: master2.id)
    expect(page).to have_css("#master-#{master2.id}-main-container.in", wait: 10)
    finish_form_formatting

    expand_master_record_tab('external ids', master_id: master2.id)
    finish_page_loading

    ext_panel_2 = find("#external-ids-#{master2.id}", visible: :all)
    within(ext_panel_2) do
      bhs_block = all("[id^='bhs-assignments-#{master2.id}']", wait: 10).first
      expect(bhs_block).not_to be_nil, 'Master 2 external IDs should load'
      expect(bhs_block.text.strip).not_to be_empty, 'Master 2 external IDs should have content'
    end

    # Final check: Go back to master 1
    expand_master_record(master_id: master1.id)
    expect(page).to have_css("#master-#{master1.id}-main-container.in", wait: 10)
    finish_form_formatting

    expand_master_record_tab('external ids', master_id: master1.id)
    finish_page_loading

    ext_panel_1_revisit = find("#external-ids-#{master1.id}", visible: :all)
    within(ext_panel_1_revisit) do
      bhs_block = all("[id^='bhs-assignments-#{master1.id}']", wait: 10).first
      expect(bhs_block).not_to be_nil, 'Master 1 external IDs should load when returning'
      expect(bhs_block.text.strip).not_to be_empty, 'Master 1 external IDs should have content when returning'
    end
  end

  # This test verifies that the on_open_click mechanism correctly loads
  # external ID content when the panel is expanded
  it 'triggers on_open_click for external ids panel when tab is expanded' do
    master1 = @masters.first

    # Navigate to search results
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{master1.id}"
    dismiss_modal
    finish_page_loading

    # Expand master 1
    expand_master_record(master_id: master1.id)
    expect(page).to have_css("#master-#{master1.id}-main-container.in", wait: 10)
    finish_form_formatting

    # Click the external IDs tab to expand the panel
    expand_master_record_tab('external ids', master_id: master1.id)
    finish_page_loading

    # The panel should now be expanded - wait for it
    expect(page).to have_css("#external-ids-#{master1.id}.in", wait: 10)
    ext_panel = find("#external-ids-#{master1.id}", visible: :all)

    # The on-open-click links should have been clicked (auto-clicked class added)
    on_open_links = ext_panel.all('.on-open-click a[data-remote="true"]', visible: :all)

    links_auto_clicked = on_open_links.count { |link| (link[:class] || '').include?('auto-clicked') }

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
