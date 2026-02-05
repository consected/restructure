# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Server Info', js: true, type: :system do
  include MasterSupport
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    create_admin
  end

  before(:each) do
    login_as(@admin, scope: :admin)
  end

  it 'displays server information including database version and memcached stats' do
    visit '/admin/server_info'
    finish_page_loading

    # Check that the page loaded successfully
    expect(page).to have_content('Server Information')

    # Check Database Settings section exists
    expect(page).to have_content('Database Settings')
    expect(page).to have_css('.si-app-settings')

    # Check Database Server Version is displayed
    expect(page).to have_content('Database Server Version')
    expect(page).to have_css('.si-db-version')

    # Verify database version contains PostgreSQL version info
    db_version_text = find('.si-db-version').text
    expect(db_version_text).to include('PostgreSQL')

    # Check Memcached Connection section exists
    expect(page).to have_content('Memcached Connection')
    expect(page).to have_css('.si-memcached-stats')

    # Check memcached status is displayed
    expect(page).to have_css('.si-memcached-status')
    memcached_status = find('.si-memcached-status').text

    # Status should be one of the expected values
    expect(memcached_status).to match(/connected|not configured|connection failed/)

    # Additional checks based on status
    if memcached_status == 'connected'
      # If connected, should show server stats
      expect(page).to have_css('.si-memcached-stats tr', minimum: 2)
    elsif memcached_status == 'not configured'
      # If not configured, should show details
      expect(page).to have_content('Cache store is not Dalli')
    elsif memcached_status == 'connection failed'
      # If connection failed, should show error
      expect(page).to have_css('.si-memcached-error')
    end
  end

  it 'displays other server information sections' do
    visit '/admin/server_info'
    finish_page_loading

    # Check other sections exist
    expect(page).to have_content('App Settings')
    expect(page).to have_content('NfsStore Settings')
    expect(page).to have_content('Disk Usage')
    expect(page).to have_content('Processes')
  end

  it 'handles database version retrieval errors gracefully' do
    # Mock the server info to return an error for db_version
    si = Admin::ServerInfo.new(@admin)
    allow(Admin::ServerInfo).to receive(:new).and_return(si)
    allow(si).to receive(:db_version).and_return('not available: Connection error')

    visit '/admin/server_info'
    finish_page_loading

    expect(page).to have_content('Database Server Version')
    expect(page).to have_content('not available')
  end

  it 'handles memcached connection errors gracefully' do
    # Mock the server info to return a connection error for memcached
    si = Admin::ServerInfo.new(@admin)
    allow(Admin::ServerInfo).to receive(:new).and_return(si)
    allow(si).to receive(:memcached_stats).and_return({ status: 'connection failed', error: 'Timeout' })

    visit '/admin/server_info'
    finish_page_loading

    expect(page).to have_content('Memcached Connection')
    expect(page).to have_content('connection failed')
    expect(page).to have_content('Timeout')
  end

  # Tests for issue #896 - NFS mountpoint info display
  describe 'NFS mountpoint information display' do
    it 'displays source filesystem status separately - Issue896' do
      visit '/admin/server_info'
      finish_page_loading

      expect(page).to have_content('NfsStore Settings')
      expect(page).to have_content('NFS Source Filesystem')

      # Should show source filesystem information in its own section
      within('.nfs-source-filesystem-info') do
        expect(page).to have_content('Mount Path:')
        expect(page).to have_content('Source Filesystem:')
        expect(page).to have_content('Mount Status:')
      end
    end

    it 'displays detailed mountpoint information for each NFS group - Issue896' do
      visit '/admin/server_info'
      finish_page_loading

      expect(page).to have_content('NFS Group Directory Status')

      # Should display information for each group_id in range
      group_id_range = NfsStore::Manage::Filesystem.group_id_range
      group_id_range.each do |gid|
        # Should show the group id
        expect(page).to have_content("gid#{gid}")
      end

      # Should show mount and directory status columns
      within('.nfs-mountpoint-info') do
        expect(page).to have_css('.nfs-mount-status')
        expect(page).to have_css('.nfs-dir-status')
      end
    end

    it 'shows mounted status for healthy mountpoints - Issue896' do
      visit '/admin/server_info'
      finish_page_loading

      within('.nfs-mountpoint-info') do
        # Should show 'mounted' status for working mountpoints
        expect(page).to have_content('mounted')
      end
    end

    it 'shows failed status for broken mountpoints - Issue896' do
      # Mock a failed mountpoint
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)

      mount_info = [
        {
          group_id: 600,
          mount_path: '/mnt/fphsfs/gid600',
          mountpoint_status: :failed,
          directory_status: :failed
        }
      ]
      allow(si).to receive(:nfs_store_mount_dirs).and_return(mount_info)

      visit '/admin/server_info'
      finish_page_loading

      within('.nfs-mountpoint-info') do
        # Should show 'failed' status
        expect(page).to have_content('failed')
        expect(page).to have_content('gid600')
      end
    end

    it 'displays source filesystem path from mount command - Issue896' do
      visit '/admin/server_info'
      finish_page_loading

      # Should show the filesystem source in the dedicated section
      within('.nfs-source-filesystem-info') do
        # Should show source filesystem field
        expect(page).to have_content('Source Filesystem:')
        # The actual filesystem path should be present (not just the label)
        # Look for content that looks like a path
        expect(page.text).to match(%r{/[\w\-/]+|not configured|not found})
      end
    end

    it 'shows both mountpoint and directory status separately - Issue896' do
      visit '/admin/server_info'
      finish_page_loading

      within('.nfs-mountpoint-info') do
        # Should show both checks
        expect(page).to have_content(/mountpoint|mount status/i)
        expect(page).to have_content(/directory|dir status/i)
      end
    end
  end

  describe 'Admin status indicators for NFS mountpoint failures' do
    it 'shows alert icon when mountpoints are failed - Issue896' do
      # Mock a failed mountpoint in configuration
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)

      # Mock configuration failures including mountpoint issue
      allow(si).to receive(:configuration_failed_reason).and_return(['NFS mountpoint gid600 is not mounted'])
      allow(si).to receive(:configuration_successful).and_return(false)

      visit '/admin/server_info'
      finish_page_loading

      # Should show error icon in status indicators
      within('.si-general-status') do
        expect(page).to have_css('.glyphicon-alert')
      end
    end

    it 'displays mountpoint failure details in status popover - Issue896' do
      # Mock a failed mountpoint
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)
      allow(si).to receive(:configuration_failed_reason).and_return(['NFS mountpoint gid600 is not mounted'])
      allow(si).to receive(:configuration_successful).and_return(false)

      visit '/admin/server_info'
      finish_page_loading

      # Click on the alert icon to show popover
      within('.si-general-status') do
        find('.glyphicon-alert').click
      end

      # Popover should show the mountpoint failure
      expect(page).to have_content('NFS mountpoint')
      expect(page).to have_content('gid600')
    end

    it 'includes link to NfsStore Settings section in status popover - Issue896' do
      # Mock a failed mountpoint
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)
      allow(si).to receive(:configuration_failed_reason).and_return(['NFS mountpoint gid600 is not mounted. See NfsStore Settings for details.'])
      allow(si).to receive(:configuration_successful).and_return(false)

      visit '/admin/server_info'
      finish_page_loading

      # Click on the alert icon
      within('.si-general-status') do
        find('.glyphicon-alert').click
      end

      # Should mention NfsStore Settings
      expect(page).to have_content('NfsStore Settings')
    end

    it 'does not show alert when all mountpoints are healthy - Issue896' do
      # Ensure all mountpoints are healthy
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)
      allow(si).to receive(:configuration_failed_reason).and_return([])
      allow(si).to receive(:configuration_successful).and_return(true)

      visit '/admin/server_info'
      finish_page_loading

      # Should not show error icon
      within('.si-general-status') do
        expect(page).not_to have_css('.glyphicon-alert')
      end
    end
  end

  describe 'Main admin page status indicators' do
    it 'shows NFS mountpoint failures on main admin page - Issue896' do
      # Mock a failed mountpoint
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)
      allow(si).to receive(:configuration_failed_reason).and_return(['NFS mountpoint /mnt/fphsfs/gid600 (gid600) is not mounted. See NfsStore Settings for details.'])
      allow(si).to receive(:configuration_successful).and_return(false)

      visit '/admin'
      finish_page_loading

      # Main admin page should show the status indicator in the Status section
      within('h3', text: /^Status/) do
        expect(page).to have_css('.glyphicon-alert')
      end
    end

    it 'displays mountpoint error details in popover on main admin page - Issue896' do
      # Mock a failed mountpoint
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)
      allow(si).to receive(:configuration_failed_reason).and_return([
        'NFS mountpoint /mnt/fphsfs/gid600 (gid600) is not mounted. See NfsStore Settings for details.',
        'NFS directory /mnt/fphsfs/gid601 (gid601) is not accessible. See NfsStore Settings for details.'
      ])
      allow(si).to receive(:configuration_successful).and_return(false)

      visit '/admin'
      finish_page_loading

      # Click the alert icon to show popover
      within('h3', text: /^Status/) do
        find('.glyphicon-alert').click
      end

      # Popover should show both mountpoint failures
      expect(page).to have_content('NFS mountpoint')
      expect(page).to have_content('gid600')
      expect(page).to have_content('gid601')
      expect(page).to have_content('NfsStore Settings')
    end

    it 'does not show alert on main admin page when all mountpoints are healthy - Issue896' do
      # Ensure all mountpoints are healthy
      si = Admin::ServerInfo.new(@admin)
      allow(Admin::ServerInfo).to receive(:new).and_return(si)
      
      # Mock healthy mountpoints
      original_pathname_new = Pathname.method(:new)
      allow(Pathname).to receive(:new) do |path|
        pn = original_pathname_new.call(path)
        if path.include?('/gid')
          allow(pn).to receive(:mountpoint?).and_return(true)
        end
        pn
      end
      
      allow(si).to receive(:configuration_failed_reason).and_return([])
      allow(si).to receive(:configuration_successful).and_return(true)

      visit '/admin'
      finish_page_loading

      # Should not show error icon in Status section
      within('h3', text: /^Status/) do
        expect(page).not_to have_css('.glyphicon-alert')
      end
    end
  end
end
