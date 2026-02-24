# frozen_string_literal: true

# Tests for Issue #905 - Move admin panel alerts (Server Info and Redcap Projects)
# into a collapsed panel at the top of the admin index page.
#
# The alerts panel should:
# - Only appear when there are issues (server info failures or REDCap failures)
# - Show a red alert symbol on the title bar of the collapser
# - Start collapsed (user must click to expand)
# - Show separate category badges (server/redcap) with counts
# - Format the issues more cleanly than the old popover approach
# - Replace the old popover-based alert icons on the Status and REDCap h3 headings

require 'rails_helper'

RSpec.describe 'Admin index page alerts panel - Issue905', js: true, type: :system do
  include MasterSupport
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    create_admin
  end

  before(:each) do
    login_as(@admin, scope: :admin)
  end

  # Mock Admin::ServerInfo to simulate configuration failures
  # @param reasons [Array<String>] list of failure reason messages (empty = healthy)
  def mock_server_info(reasons: [])
    si = Admin::ServerInfo.new(@admin)
    allow(Admin::ServerInfo).to receive(:new).and_return(si)
    allow(si).to receive(:configuration_failed_reason).and_return(reasons)
    allow(si).to receive(:configuration_successful).and_return(reasons.empty?)
    si
  end

  describe 'alerts panel visibility' do
    it 'shows a collapsed alerts panel with category badge when server info has failures' do
      mock_server_info(reasons: ['NFS mountpoint /mnt/fphsfs/gid600 is not mounted'])

      visit '/'
      finish_page_loading

      expect(page).to have_css('#admin-alerts-panel')

      within('#admin-alerts-panel .panel-heading') do
        expect(page).to have_css('.glyphicon-alert')
        expect(page).to have_css('.label-warning', text: 'server: 1')
      end

      # Starts collapsed
      expect(page).not_to have_css('#admin-alerts-collapse.in')
    end

    it 'shows formatted server info issues when the alerts panel is expanded' do
      mock_server_info(reasons: [
                         'NFS mountpoint /mnt/fphsfs/gid600 is not mounted',
                         'NFS directory /mnt/fphsfs/gid601 is not accessible'
                       ])

      visit '/'
      finish_page_loading

      find('#admin-alerts-panel .panel-heading a').click
      sleep 0.5

      expect(page).to have_css('#admin-alerts-collapse.in')

      within('#admin-alerts-collapse') do
        expect(page).to have_content('NFS mountpoint /mnt/fphsfs/gid600 is not mounted')
        expect(page).to have_content('NFS directory /mnt/fphsfs/gid601 is not accessible')
      end
    end

    it 'does not show the alerts panel when there are no issues' do
      mock_server_info(reasons: [])

      visit '/'
      finish_page_loading

      expect(page).not_to have_css('#admin-alerts-panel')
    end

    it 'no longer shows popover-style alerts on the Status heading' do
      mock_server_info(reasons: ['NFS mountpoint /mnt/fphsfs/gid600 is not mounted'])

      visit '/'
      finish_page_loading

      expect(page).to have_css('.admin-index-page')

      within('h3', text: 'Status') do
        expect(page).not_to have_css('.glyphicon-alert[data-toggle="popover"]')
      end
    end
  end
end
