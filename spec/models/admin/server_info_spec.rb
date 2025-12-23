# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ServerInfo, type: :model do
  include MasterSupport

  before :example do
    create_admin
  end

  it 'requires an active admin user' do
    expect { Admin::ServerInfo.new(@admin) }.not_to raise_error

    expect do
      Admin::ServerInfo.new(nil)
    end.to raise_error(FphsException, 'Initialization with admin blank is not valid')
  end

  it 'gets a list of server settings' do
    si = Admin::ServerInfo.new(@admin)

    as = si.app_settings
    expect(as).to be_a Hash
    expect(as).not_to be_empty

    expect(as['DefaultMigrationSchema']).to eq 'ml_app'
  end

  it 'gets a list of database settings' do
    si = Admin::ServerInfo.new(@admin)

    as = si.db_settings
    expect(as).to be_a Hash
    expect(as).not_to be_empty

    expect(as[:connection][:adapter]).to eq 'postgresql'
  end

  it 'gets the database server version' do
    si = Admin::ServerInfo.new(@admin)

    version = si.db_version
    expect(version).to be_a String
    expect(version).to include('PostgreSQL')
  end

  it 'gets memcached connection stats' do
    si = Admin::ServerInfo.new(@admin)

    stats = si.memcached_stats
    expect(stats).to be_a Hash
    expect(stats[:status]).to be_present

    # Should return either 'connected', 'not configured', or 'connection failed'
    expect(stats[:status]).to match(/connected|not configured|connection failed/)

    # If connected, should have servers
    if stats[:status] == 'connected'
      expect(stats[:servers]).to be_present
    # If not configured, should have details
    elsif stats[:status] == 'not configured'
      expect(stats[:details]).to be_present
    # If connection failed, should have error message
    elsif stats[:status] == 'connection failed'
      expect(stats[:error]).to be_present
    end
  end

  it 'handles database connection errors gracefully' do
    si = Admin::ServerInfo.new(@admin)

    # Mock connection error
    allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, 'Connection failed')

    version = si.db_version
    expect(version).to include('not available')
    expect(version).to include('Connection failed')
  end

  it 'handles memcached connection errors gracefully' do
    si = Admin::ServerInfo.new(@admin)

    # Mock a MemCacheStore instance
    mock_cache = instance_double(ActiveSupport::Cache::MemCacheStore)
    allow(Rails).to receive(:cache).and_return(mock_cache)
    allow(mock_cache).to receive(:is_a?).with(ActiveSupport::Cache::MemCacheStore).and_return(true)
    allow(mock_cache).to receive(:stats).and_raise(StandardError, 'Memcached unavailable')

    stats = si.memcached_stats
    expect(stats[:status]).to eq('connection failed')
    expect(stats[:error]).to include('Memcached unavailable')
  end
end
