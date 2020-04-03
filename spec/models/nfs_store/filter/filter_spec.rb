# frozen_string_literal: true

require 'rails_helper'

SetupHelper.setup_test_app

RSpec.describe NfsStore::Filter::Filter, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  before :all do
    setup_nfs_store

    res = defined? BhsAssignment
    expect(res).to be_truthy

    @activity_log = @container.parent_item
  end

  before :each do
    @activity_log = @container.parent_item
    @activity_log.extra_log_type = :step_1
  end

  it 'creates filters for a user and role' do
    f = create_filter('^contabc', resource_name: 'nfs_store__manage__containers')
    expect(f).to be_a NfsStore::Filter::Filter

    f = create_filter('^contdef', resource_name: 'nfs_store__manage__containers')
    expect(f).to be_a NfsStore::Filter::Filter

    f = create_filter('^contdef', role_name: 'non user role', resource_name: 'nfs_store__manage__containers')

    fs = NfsStore::Filter::Filter.filters_for @container

    expect(fs.length).to eq 2

    f = create_filter('^contdef', user: @user, resource_name: 'nfs_store__manage__containers')

    fs = NfsStore::Filter::Filter.filters_for @container

    expect(fs.length).to eq 3
  end

  it 'creates filters for a user and role in activity log' do
    expect(@container.parent_item).to eq @activity_log
    @resource_name = @activity_log.resource_name

    f = create_filter('^abc')
    expect(f).to be_a NfsStore::Filter::Filter

    f = create_filter('^def')
    expect(f).to be_a NfsStore::Filter::Filter

    f = create_filter('^def', role_name: 'non user role')

    fs = NfsStore::Filter::Filter.filters_for @activity_log

    expect(fs.length).to eq 2

    f = create_filter('^def', user: @user)

    fs = NfsStore::Filter::Filter.filters_for @activity_log

    expect(fs.length).to eq 3
  end

  it 'applies filters for the current user to container' do
    @resource_name = @activity_log.resource_name

    create_stored_file '.', 'not_abc_ is a test'
    create_stored_file '.', 'abc_ is a test'

    # No filter specified? No results returned
    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    expect(res.length).to eq 0

    f = create_filter('^----nothing')

    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    expect(res.length).to eq 0

    f = create_filter('^/abc')
    f = create_filter('^\/dir\/')
    f = create_filter('^/ghi')
    f = create_filter('^/id\/{{id}} - id file')

    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    res = res.sort { |f, g| f.created_at <=> g.created_at }
    expect(res.length).to eq 1
    expect(res.first.file_name).to eq 'abc_ is a test'

    create_stored_file 'dir1', 'abc_ is a test3'
    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    res = res.sort { |f, g| f.created_at <=> g.created_at }
    expect(res.length).to eq 1

    create_stored_file 'dir', 'abc_ is a test2'
    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    res = res.sort { |f, g| f.created_at <=> g.created_at }
    expect(res.length).to eq 2
    expect(res.first.file_name).to eq 'abc_ is a test'
    expect(res.last.file_name).to eq 'abc_ is a test2'

    create_stored_file 'id', '000100 - id file'
    create_stored_file 'id', "#{@activity_log.id} - id file"
    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    res = res.sort { |f, g| f.created_at <=> g.created_at }
    expect(res.length).to eq 3
    expect(res.last.file_name).to eq "#{@activity_log.id} - id file"
  end

  it 'generates SQL to filter reports' do
    @resource_name = @activity_log.resource_name

    create_filter('^/fabc')
    create_filter('^fdir\/')
    create_filter('^/fghi')
    create_filter('^fid\/{{id}} - id file')

    fs = NfsStore::Filter::Filter.generate_filters_for 'activity_log__player_contact_phone', user: @user

    expect(fs.length).to be > 10
    expect(fs).to include 'fid\/.+ - id file'
  end
end
