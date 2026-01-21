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
    master_ids = @masters.map(&:id).join(',')
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{master_ids}"
    dismiss_modal
    finish_page_loading

    all_panels = all('.master-panel', visible: :all)
    expect(all_panels.count).to be >= 2

    # Test each master's external ids panel
    @masters.each do |master|
      expand_master_record(master_id: master.id)
      expect(page).to have_css("#master-#{master.id}-main-container.in.loaded-master-main", wait: 10)
      finish_form_formatting

      expand_master_record_tab('external ids')
      finish_page_loading

      ext_ids_panel = find("#external-ids-#{master.id}")
      within(ext_ids_panel) do
        expect(page).to have_css('.external-identifier, [data-model-data-type="external_identifier"], .external-ids-panel', wait: 5)
        bhs_block = find("[id^='bhs-assignments-#{master.id}']")
        expect(bhs_block.text).not_to be_empty
      end
    end

    # Rapid switching test
    5.times do
      @masters.each do |master|
        expand_master_record(master_id: master.id)
        expect(page).to have_css("#master-#{master.id}-main-container.in", wait: 5)

        expand_master_record_tab('external ids')
        finish_page_loading

        ext_ids_panel = find("#external-ids-#{master.id}.in, #external-ids-#{master.id}.collapse.in", visible: :all)
        bhs_block = ext_ids_panel.find("[id^='bhs-assignments-#{master.id}']", visible: :all)
        expect(bhs_block.text.strip).not_to be_empty
      end
    end
  end
end
