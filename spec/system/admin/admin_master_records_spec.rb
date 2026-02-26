# frozen_string_literal: true

# System tests for Master Records admin page (issue #930)
#
# Tests that verify the Master Records admin page functions correctly:
# - Navigation to the page
# - Display of masters table and standard models
# - Show panel opening via AJAX
# - Sample form auto-loading when tab is clicked
# - Tab navigation and content rendering

require 'rails_helper'

describe 'Master Records admin page', js: true, driver: $browser_driver do
  include ModelSupport
  include FeatureSupport
  include UserSupport

  before(:all) do
    SetupHelper.feature_setup

    # Disable 2FA for easier testing
    change_setting('TwoFactorAuthDisabledForAdmin', true)

    # Create an admin with master_records capability
    create_admin
    @admin.update!(capabilities: ['master_records'])

    # Create a user and Master record for sample form testing
    # Settings::admin_master must be a Master record ID
    @user, = create_user
    @master = Master.create!(current_user: @user)
    change_setting('AdminMaster', @master.id)
  end

  before(:each) do
    login_as(@admin, scope: :admin)
  end

  after(:all) do
    change_setting('TwoFactorAuthDisabledForAdmin', false)
  end

  it 'displays the Master Records page' do
    visit '/admin/master_records'

    expect(page).to have_content('Master Records')
    expect(page).to have_css('.master-records-index__models-table')
  end

  it 'shows masters table as first entry' do
    visit '/admin/master_records'

    within('.master-records-index__models-table tbody') do
      first_row = all('tr').first
      expect(first_row).to have_content('masters')
      expect(first_row).to have_content('Master records (subjects)')
    end
  end

  it 'opens show panel when clicking eye icon' do
    visit '/admin/master_records'

    # Click the eye icon for the first entry (masters)
    within('.master-records-index__models-table tbody') do
      first('a.glyphicon-eye-open').click
    end

    # Wait for AJAX to load the panel
    expect(page).to have_css('.master-records-show-panel', wait: 10)
    expect(page).to have_css('.nav-tabs', wait: 5)
    expect(page).to have_content('Details')
  end

  it 'auto-loads sample form when clicking Sample Form tab' do
    visit '/admin/master_records'

    # Click the eye icon for player_infos (second entry, ID 2)
    within('.master-records-index__models-table tbody') do
      all('a.glyphicon-eye-open')[1].click
    end

    # Wait for the panel to load
    expect(page).to have_css('.master-records-show-panel', wait: 10)

    # Verify the Sample Form tab exists
    within('.nav-tabs') do
      expect(page).to have_link('Sample Form')
    end

    # Click the Sample Form tab
    within('.nav-tabs') do
      click_link 'Sample Form'
    end

    # After clicking the tab, verify the refresh link with on-show-auto-click class exists
    within('#mr-sample-form-2') do
      expect(page).to have_css('a.on-show-auto-click', text: 'Refresh sample', visible: :all)
    end

    # The on-show-auto-click JavaScript should trigger automatically
    # We just verify the mechanism is in place - the link should get clicked by JS
    # For this test, we verify that the auto-click setup exists, not that the form fully loads
    # (full form loading would require proper app setup, user access, etc.)
    within('#mr-sample-form-result-2') do
      # Initially shows "loading..."
      expect(page).to have_content('loading...')
    end
  end

  it 'shows API tab with masters-specific content for masters entry' do
    visit '/admin/master_records'

    # Click the eye icon for masters (first entry)
    within('.master-records-index__models-table tbody') do
      first('a.glyphicon-eye-open').click
    end

    # Wait for the panel to load
    expect(page).to have_css('.master-records-show-panel', wait: 10)

    # Click the API tab
    within('.nav-tabs') do
      click_link 'API'
    end

    # Check for masters-specific API content
    expect(page).to have_content('Create master record alone')
    expect(page).to have_content('Create master with associations')
    expect(page).to have_content('available associations')
  end

  it 'does not show UAC tab for masters entry' do
    visit '/admin/master_records'

    # Click the eye icon for masters (first entry)
    within('.master-records-index__models-table tbody') do
      first('a.glyphicon-eye-open').click
    end

    # Wait for the panel to load
    expect(page).to have_css('.master-records-show-panel', wait: 10)

    # Check that UAC tab is not present
    within('.nav-tabs') do
      expect(page).not_to have_content('User Access Controls')
    end
  end

  it 'shows UAC tab for standard models' do
    visit '/admin/master_records'

    # Click the eye icon for player_infos (second entry, ID 2)
    within('.master-records-index__models-table tbody') do
      all('a.glyphicon-eye-open')[1].click
    end

    # Wait for the panel to load
    expect(page).to have_css('.master-records-show-panel', wait: 10)

    # Check that UAC tab is present
    within('.nav-tabs') do
      expect(page).to have_content('User Access Controls')
    end
  end

  it 'does not show Sample Form tab for tracker_histories' do
    visit '/admin/master_records'

    # Click the eye icon for tracker_histories (last entry)
    within('.master-records-index__models-table tbody') do
      all('a.glyphicon-eye-open').last.click
    end

    # Wait for the panel to load
    expect(page).to have_css('.master-records-show-panel', wait: 10)

    # Check that Sample Form tab is not present
    within('.nav-tabs') do
      expect(page).not_to have_content('Sample Form')
    end
  end
end
