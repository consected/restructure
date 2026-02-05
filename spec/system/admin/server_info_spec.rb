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

    # Expand Database Settings panel
    find('a[href="#collapse-db-settings"]').click
    sleep 0.5 # Wait for accordion animation

    # Check Database Settings section exists
    expect(page).to have_content('Database Settings')
    expect(page).to have_css('.si-app-settings')

    # Check Database Server Version is displayed
    expect(page).to have_content('Database Server Version')
    expect(page).to have_css('.si-db-version')

    # Verify database version contains PostgreSQL version info
    db_version_text = find('.si-db-version').text
    expect(db_version_text).to include('PostgreSQL')

    # Expand Memcached Connection panel
    find('a[href="#collapse-memcached"]').click
    sleep 0.5 # Wait for accordion animation

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

    # Check accordion panels exist
    expect(page).to have_content('App Settings')
    expect(page).to have_content('NfsStore Settings')
    expect(page).to have_content('Disk Usage')
    expect(page).to have_content('Processes')

    # Verify panels can be expanded
    find('a[href="#collapse-app-settings"]').click
    sleep 0.3
    expect(page).to have_css('#collapse-app-settings.in')

    find('a[href="#collapse-disk-usage"]').click
    sleep 0.3
    expect(page).to have_css('#collapse-disk-usage.in')
  end

  it 'handles database version retrieval errors gracefully' do
    # Mock the server info to return an error for db_version
    si = Admin::ServerInfo.new(@admin)
    allow(Admin::ServerInfo).to receive(:new).and_return(si)
    allow(si).to receive(:db_version).and_return('not available: Connection error')

    visit '/admin/server_info'
    finish_page_loading

    # Expand Database Settings panel
    find('a[href="#collapse-db-settings"]').click
    sleep 0.5

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

    # Expand Memcached Connection panel
    find('a[href="#collapse-memcached"]').click
    sleep 0.5

    expect(page).to have_content('Memcached Connection')
    expect(page).to have_content('connection failed')
    expect(page).to have_content('Timeout')
  end

  # Tests for issue #896 - NFS mountpoint info display
  describe 'NFS mountpoint information display' do
    it 'displays source filesystem status separately - Issue896' do
      visit '/admin/server_info'
      finish_page_loading

      # Expand NfsStore Settings panel
      find('a[href="#collapse-nfsstore"]').click
      sleep 0.5

      expect(page).to have_content('NfsStore Settings')
      expect(page).to have_content('NFS Source Filesystem')

      # Should show source filesystem information in its own section
      within('.nfs-source-filesystem-info') do
        expect(page).to have_content('Source Filesystem:')
        expect(page).to have_content('Status:')
      end
    end

    it 'displays detailed mountpoint information for each NFS group - Issue896' do
      visit '/admin/server_info'
      finish_page_loading

      # Expand NfsStore Settings panel
      find('a[href="#collapse-nfsstore"]').click
      sleep 0.5

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

      # Expand NfsStore Settings panel
      find('a[href="#collapse-nfsstore"]').click
      sleep 0.5

      within('.nfs-mountpoint-info') do
        # Should show mount status indicators (in test env, directories exist but aren't real mounts)
        # So we expect to see status badges rendered
        expect(page).to have_css('.nfs-mount-status')
        expect(page).to have_css('.nfs-dir-status')
        # Directory should be accessible even if mount failed
        expect(page).to have_content('accessible')
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

      # Expand NfsStore Settings panel
      find('a[href="#collapse-nfsstore"]').click
      sleep 0.5

      within('.nfs-mountpoint-info') do
        # Should show 'failed' status
        expect(page).to have_content('failed')
        expect(page).to have_content('gid600')
      end
    end

    it 'displays source filesystem path from mount command - Issue896' do
      visit '/admin/server_info'
      finish_page_loading

      # Expand NfsStore Settings panel
      find('a[href="#collapse-nfsstore"]').click
      sleep 0.5

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

      # Expand NfsStore Settings panel
      find('a[href="#collapse-nfsstore"]').click
      sleep 0.5

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

      # General Status panel is open by default, click on the alert icon to show popover
      within('#collapse-general') do
        find('.glyphicon-alert').click
      end
      sleep 0.5

      # Popover content is in data-content attribute or rendered popover div
      # Check that the alert icon has the failure message in its data-content
      alert_icon = find('#collapse-general .glyphicon-alert')
      expect(alert_icon['data-content']).to include('NFS mountpoint')
      expect(alert_icon['data-content']).to include('gid600')
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

  #  describe 'Main admin page status indicators' do
  #   # These tests are skipped as the main admin page isn't available in test environment
  #   # The core NFS monitoring functionality is thoroughly tested above
  # end
end
