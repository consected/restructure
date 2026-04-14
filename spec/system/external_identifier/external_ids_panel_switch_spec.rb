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
    # Navigate to search results with multiple master IDs
    master_ids = @masters.map(&:id).join(',')
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{master_ids}"
    dismiss_modal
    finish_page_loading

    # Verify we have multiple master results
    all_panels = all('.master-panel', visible: :all)
    expect(all_panels.count).to be >= 2, "Expected at least 2 master panels, but found #{all_panels.count}"

    # Test each master's external ids panel
    @masters.each do |master|
      # Expand the master record using helper
      expand_master_record(master_id: master.id)

      # Wait for master container to load
      expect(page).to have_css("#master-#{master.id}-main-container.in.loaded-master-main", wait: 10)
      finish_form_formatting

      # Expand the external ids tab using helper
      expand_master_record_tab('external ids', master_id: master.id)
      finish_page_loading

      # Verify the external ids panel is shown and has content
      ext_ids_panel = find("#external-ids-#{master.id}")
      within(ext_ids_panel) do
        # Look for BHS assignment block content
        bhs_block = all("[id^='bhs-assignments-#{master.id}']", wait: 10).first
        expect(bhs_block).not_to be_nil, "BHS assignment should exist for master #{master.id}"
        expect(bhs_block.text).not_to be_empty, "BHS block should have content for master #{master.id}"
      end
    end

    # Now do rapid switching between masters
    3.times do
      @masters.each do |master|
        # Expand master using helper
        expand_master_record(master_id: master.id)

        # Wait for container to be visible
        expect(page).to have_css("#master-#{master.id}-main-container.in", wait: 10)

        # Expand external ids tab using helper
        expand_master_record_tab('external ids', master_id: master.id)
        finish_page_loading

        # Verify panel has content
        ext_ids_panel = find("#external-ids-#{master.id}", visible: :all)
        bhs_block = ext_ids_panel.all("[id^='bhs-assignments-#{master.id}']", wait: 10).first
        expect(bhs_block).not_to be_nil, "External IDs should load for master #{master.id} during rapid switching"
        expect(bhs_block.text.strip).not_to be_empty, "External IDs should have content for master #{master.id}"
      end
    end
  end
end
