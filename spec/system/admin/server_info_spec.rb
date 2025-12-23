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
end
