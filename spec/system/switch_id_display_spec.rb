# frozen_string_literal: true

require 'rails_helper'

# Tests for GitHub issue #312 - switch_id_on_click does not work correctly
# for multiple external ids or when not showing the master_id
#
# Test Coverage:
# - Single ID display (master_id only, scantron_id only): no switch button shown
# - Two IDs (master_id + msid): switch button toggles between them
# - Multiple IDs (master_id, msid, scantron_id, sage_id): rotates through all IDs
# - External IDs only (no master_id): rotates correctly without master_id
# - Mixed ID availability: shows actual values or "(none)" with appropriate titles
# - Crosswalk field labels: configured via AppConfiguration for proper display names
#   (e.g., "MSID" instead of "Msid", "Scantron ID" instead of "Scantron")
#
# Key functionality tested:
# - Switch button title updates to show next ID label
# - ID spans have correct visibility (only current ID visible)
# - data-id-label attributes set correctly for JavaScript switch logic
# - Title attributes show proper labels (e.g., "No MSID" for missing values)
describe 'switch ID display in search results', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    SetupHelper.feature_setup

    seed_database
    create_data_set_outside_tx

    @admin, = create_admin
    @user, @good_password = create_user
    @good_email = @user.email

    # Ensure external identifiers are active
    setup_external_identifiers

    # Create masters with different ID combinations
    create_masters_with_varying_ids
  end

  def setup_external_identifiers
    # Ensure scantrons and sage_assignments are active
    ExternalIdentifier.where(name: 'scantrons').update_all(disabled: false)
    ExternalIdentifier.where(name: 'sage_assignments').update_all(disabled: false)

    # Ensure user has access to external identifiers (read and create)
    setup_access :scantrons, resource_type: :table, access: :create
    setup_access :sage_assignments, resource_type: :table, access: :create

    # Configure crosswalk field labels
    crosswalk_labels = "msid: MSID\npro_id: Pro Football ID"
    add_app_config(@user.app_type, 'crosswalk field labels', crosswalk_labels)
    Admin::AppConfiguration.clear_memo!
    Master.reset_crosswalk_field_labels!
    Master.reset_external_id_matching_fields!
  end

  def create_masters_with_varying_ids
    # Generate unique IDs for this test run (within valid ranges)
    # Scantron: 1-999999, Sage: 1000000000-9999999999
    @msid_base = rand(1_000_000..9_000_000)
    @scantron_base = rand(100_000..900_000)
    @sage_base = rand(1_000_000_000..9_000_000_000)

    # Master with all IDs: msid, scantron_id, sage_id
    @master_all_ids = create_master(@user, { msid: @msid_base, pro_id: rand(1_000_000_000) })
    scantron = Scantron.new(scantron_id: @scantron_base)
    scantron.master = @master_all_ids
    scantron.save!
    sage = SageAssignment.new(sage_id: @sage_base)
    sage.master = @master_all_ids
    sage.save!

    # Master with only msid
    @master_msid_only = create_master(@user, { msid: @msid_base + 1, pro_id: rand(1_000_000_000) })

    # Master with only scantron_id (no msid)
    @master_scantron_only = create_master(@user, { msid: nil, pro_id: rand(1_000_000_000) })
    scantron2 = Scantron.new(scantron_id: @scantron_base + 2)
    scantron2.master = @master_scantron_only
    scantron2.save!

    # Master with only sage_id (no msid)
    @master_sage_only = create_master(@user, { msid: nil, pro_id: rand(1_000_000_000) })
    sage2 = SageAssignment.new(sage_id: @sage_base + 3)
    sage2.master = @master_sage_only
    sage2.save!

    # Master with no IDs (only master_id)
    @master_no_ext_ids = create_master(@user, { msid: nil, pro_id: rand(1_000_000_000) })
  end

  before(:each) do
    validate_setup
    login
  end

  after(:each) do
    # Reset the app configuration to default
    reset_id_display_config
  end

  def set_id_display_config(id_list)
    add_app_config(@user.app_type, 'show ids in master result', id_list)
  end

  def reset_id_display_config
    # Reset to default master_id only
    add_app_config(@user.app_type, 'show ids in master result', 'master_id')
  end

  def search_for_master(master)
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{master.id}"
    finish_page_loading

    # Wait for search results to load
    expect(page).to have_css('#master_results_block .master-result', wait: 10)
  end

  describe 'with single ID (master_id only)' do
    before(:each) do
      set_id_display_config('master_id')
    end

    it 'displays master_id without switch button' do
      search_for_master(@master_all_ids)

      # Should show master_id
      within '#master_results_block .master-result' do
        expect(page).to have_css('.alt-id-item.master_id', text: @master_all_ids.id.to_s)
        # Should not show switch button when only one ID
        expect(page).not_to have_css('a.switch_id')
      end
    end
  end

  describe 'with single ID (scantron_id only)' do
    before(:each) do
      set_id_display_config('scantron_id')
    end

    it 'displays scantron_id without switch button' do
      search_for_master(@master_all_ids)

      # Should show scantron_id
      within '#master_results_block .master-result' do
        expect(page).to have_css('.alt-id-item.scantron_id', text: @master_all_ids.scantron_id.to_s)
        # Should not show switch button when only one ID
        expect(page).not_to have_css('a.switch_id')
      end
    end
  end

  describe 'with master_id and msid' do
    before(:each) do
      set_id_display_config('master_id,msid')
    end

    it 'displays master_id first and can switch to msid' do
      search_for_master(@master_all_ids)

      within '#master_results_block .master-result' do
        # First ID (master_id) should be visible
        master_id_span = find('.alt-id-item.master_id', visible: true)
        expect(master_id_span).to have_content(@master_all_ids.id.to_s)
        expect(master_id_span).to have_css('[title="Master"]')

        # Second ID (msid) should be hidden initially
        msid_span = find('.alt-id-item.msid', visible: :all)
        expect(msid_span).not_to be_visible

        # Click switch button
        switch_button = find('a.switch_id')
        expect(switch_button['title']).to eq('switch to MSID')
        switch_button.click

        # Now msid should be visible and master_id hidden
        expect(master_id_span).not_to be_visible
        expect(msid_span).to be_visible
        expect(msid_span).to have_content(@master_all_ids.msid.to_s)
        expect(msid_span).to have_css('[title="MSID"]')

        # Switch button title should now point to next ID (master_id)
        expect(switch_button['title']).to eq('switch to Master')
      end
    end

    it 'shows (none) for missing msid with correct title' do
      search_for_master(@master_no_ext_ids)

      within '#master_results_block .master-result' do
        # Click switch to show msid
        find('a.switch_id').click

        # Should show (none) with "No MSID" title
        msid_span = find('.alt-id-item.msid', visible: true)
        none_indicator = msid_span.find('[title="No MSID"]')
        expect(none_indicator).to have_content('(none)')
      end
    end
  end

  describe 'with multiple external IDs (msid, scantron_id, sage_id)' do
    before(:each) do
      set_id_display_config('master_id,msid,scantron_id,sage_id')
    end

    it 'rotates through all four IDs when switch button is clicked' do
      search_for_master(@master_all_ids)

      within '#master_results_block .master-result' do
        switch_button = find('a.switch_id')

        # Initially master_id should be visible
        expect(page).to have_css('.alt-id-item.master_id', visible: true)

        # First click: switch to msid
        switch_button.click
        expect(page).to have_no_css('.alt-id-item.master_id', visible: true)
        expect(page).to have_css('.alt-id-item.msid', visible: true)
        expect(switch_button['title']).to eq('switch to Scantron ID')

        # Second click: switch to scantron_id
        switch_button.click
        expect(page).to have_no_css('.alt-id-item.msid', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id', visible: true)
        expect(switch_button['title']).to eq('switch to Sage ID')

        # Third click: switch to sage_id
        switch_button.click
        expect(page).to have_no_css('.alt-id-item.scantron_id', visible: true)
        expect(page).to have_css('.alt-id-item.sage_id', visible: true)
        expect(switch_button['title']).to eq('switch to Master')

        # Fourth click: back to master_id
        switch_button.click
        expect(page).to have_no_css('.alt-id-item.sage_id', visible: true)
        expect(page).to have_css('.alt-id-item.master_id', visible: true)
        expect(switch_button['title']).to eq('switch to MSID')
      end
    end

    it 'displays actual values and (none) appropriately for mixed IDs' do
      # Master with only some IDs set
      search_for_master(@master_msid_only)

      within '#master_results_block .master-result' do
        switch_button = find('a.switch_id')

        # master_id should show actual value
        expect(find('.alt-id-item.master_id', visible: true)).to have_content(@master_msid_only.id.to_s)

        # Switch to msid - should show actual value
        switch_button.click
        expect(page).to have_css('.alt-id-item.msid', visible: true)
        expect(page).to have_css('.alt-id-item.msid [title="MSID"]', visible: true)
        expect(page).to have_css('.alt-id-item.msid', text: @master_msid_only.msid.to_s, visible: true)

        # Switch to scantron_id - should show (none)
        switch_button.click
        expect(page).to have_css('.alt-id-item.scantron_id', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id [title="No Scantron ID"]', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id', text: '(none)', visible: true)

        # Switch to sage_id - should show (none)
        switch_button.click
        expect(page).to have_css('.alt-id-item.sage_id', visible: true)
        expect(page).to have_css('.alt-id-item.sage_id [title="No Sage ID"]', visible: true)
        expect(page).to have_css('.alt-id-item.sage_id', text: '(none)', visible: true)
      end
    end
  end

  describe 'without master_id (external IDs only)' do
    before(:each) do
      set_id_display_config('msid,scantron_id')
    end

    it 'rotates through external IDs without master_id' do
      search_for_master(@master_all_ids)

      within '#master_results_block .master-result' do
        switch_button = find('a.switch_id')

        # First should be msid
        expect(page).to have_css('.alt-id-item.msid', visible: true)
        expect(switch_button['title']).to eq('switch to Scantron ID')

        # Click to switch to scantron_id
        switch_button.click
        expect(page).to have_no_css('.alt-id-item.msid', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id', visible: true)
        expect(switch_button['title']).to eq('switch to MSID')

        # Click again to return to msid
        switch_button.click
        expect(page).to have_no_css('.alt-id-item.scantron_id', visible: true)
        expect(page).to have_css('.alt-id-item.msid', visible: true)
      end
    end

    it 'shows (none) for both when no external IDs assigned' do
      search_for_master(@master_no_ext_ids)

      within '#master_results_block .master-result' do
        switch_button = find('a.switch_id')

        # First (msid) should show (none)
        expect(page).to have_css('.alt-id-item.msid', visible: true)
        expect(page).to have_css('.alt-id-item.msid [title="No MSID"]', visible: true)
        expect(page).to have_css('.alt-id-item.msid', text: '(none)', visible: true)

        # Switch to scantron_id - should also show (none)
        switch_button.click
        expect(page).to have_no_css('.alt-id-item.msid', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id [title="No Scantron ID"]', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id', text: '(none)', visible: true)
      end
    end
  end

  describe 'with sage_id and scantron_id (no master_id or msid)' do
    before(:each) do
      set_id_display_config('sage_id,scantron_id')
    end

    it 'displays sage_id first and switches correctly' do
      search_for_master(@master_all_ids)

      within '#master_results_block .master-result' do
        switch_button = find('a.switch_id')

        # First should be sage_id
        expect(page).to have_css('.alt-id-item.sage_id', visible: true)
        expect(page).to have_css('.alt-id-item.sage_id', text: @sage_base.to_s, visible: true)

        # Switch to scantron_id
        switch_button.click
        expect(page).to have_no_css('.alt-id-item.sage_id', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id', text: @scantron_base.to_s, visible: true)
      end
    end

    it 'handles master with only one of the two IDs' do
      # Master with only sage_id
      search_for_master(@master_sage_only)

      within '#master_results_block .master-result' do
        switch_button = find('a.switch_id')

        # First should be sage_id with value
        expect(page).to have_css('.alt-id-item.sage_id', text: (@sage_base + 3).to_s, visible: true)

        # Switch to scantron_id - should show (none)
        switch_button.click
        expect(page).to have_no_css('.alt-id-item.sage_id', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id [title="No Scantron ID"]', visible: true)
        expect(page).to have_css('.alt-id-item.scantron_id', text: '(none)', visible: true)
      end
    end
  end
end
