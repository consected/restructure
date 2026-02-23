# frozen_string_literal: true

# Tests for Issue #905 - Move admin panel alerts (Server Info and Redcap Projects)
# into a collapsed panel at the top of the admin index page.
#
# The alerts panel should:
# - Only appear when there are issues (server info failures or REDCap failures)
# - Show a red alert symbol on the title bar of the collapser
# - Start collapsed (user must click to expand)
# - Format the issues more cleanly than the old popover approach
# - Replace the old popover-based alert icons on the Status and REDCap h3 headings

require 'rails_helper'

RSpec.describe 'Admin index page alerts panel - Issue905', js: true, type: :system do
  include MasterSupport
  include FeatureSupport
  include ModelSupport
  include Redcap::RedcapSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    create_admin
    SetupHelper.feature_setup
  end

  before(:each) do
    login_as(@admin, scope: :admin)
  end

  describe 'alerts panel visibility' do
    it 'shows a collapsed alerts panel with red alert icon when server info has failures - Issue905' do
      # Mock server info to report configuration failures
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)
      allow(si).to receive(:configuration_successful).and_return(false)
      allow(si).to receive(:configuration_failed_reason).and_return(
        ['NFS mountpoint /mnt/fphsfs/gid600 is not mounted']
      )

      visit '/'
      finish_page_loading

      # The alerts panel should be present
      expect(page).to have_css('#admin-alerts-panel')

      # It should have a red alert icon in the title bar
      within('#admin-alerts-panel .panel-heading') do
        expect(page).to have_css('.glyphicon-alert')
      end

      # It should start collapsed (panel body not visible)
      expect(page).not_to have_css('#admin-alerts-collapse.in')
    end

    it 'shows formatted server info issues when the alerts panel is expanded - Issue905' do
      # Mock server info configuration failures
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)
      allow(si).to receive(:configuration_successful).and_return(false)
      allow(si).to receive(:configuration_failed_reason).and_return(
        [
          'NFS mountpoint /mnt/fphsfs/gid600 is not mounted',
          'NFS directory /mnt/fphsfs/gid601 is not accessible'
        ]
      )

      visit '/'
      finish_page_loading

      # Expand the alerts panel
      find('#admin-alerts-panel .panel-heading a').click
      sleep 0.5

      # The panel body should now be visible
      expect(page).to have_css('#admin-alerts-collapse.in')

      # Each issue should be listed cleanly (not as popover content)
      within('#admin-alerts-collapse') do
        expect(page).to have_content('NFS mountpoint /mnt/fphsfs/gid600 is not mounted')
        expect(page).to have_content('NFS directory /mnt/fphsfs/gid601 is not accessible')
      end
    end

    it 'does not show the alerts panel when there are no issues - Issue905' do
      # Mock server info to be healthy
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)
      allow(si).to receive(:configuration_successful).and_return(true)
      allow(si).to receive(:configuration_failed_reason).and_return([])

      visit '/'
      finish_page_loading

      # The alerts panel should NOT be present when there are no issues
      expect(page).not_to have_css('#admin-alerts-panel')
    end

    it 'no longer shows popover-style alerts on the Status heading - Issue905' do
      # Mock server info with failures (old behavior would put popover on h3)
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)
      allow(si).to receive(:configuration_successful).and_return(false)
      allow(si).to receive(:configuration_failed_reason).and_return(
        ['NFS mountpoint /mnt/fphsfs/gid600 is not mounted']
      )

      visit '/'
      finish_page_loading

      # Verify the admin index page loaded
      expect(page).to have_css('.admin-index-page')

      # The old popover-based alert icon should NOT appear next to the Status heading
      within('h3', text: 'Status') do
        expect(page).not_to have_css('.glyphicon-alert[data-toggle="popover"]')
      end
    end
  end
end
