require 'rails_helper'

RSpec.describe NfsStore::Filter::Filter, type: :model do

  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport


  DefaultRole = 'file1'

  before :all do
    setup_nfs_store

  end

  def create_filter filter, role_name: DefaultRole, user: nil, resource_name: nil

    resource_name ||= @resource_name
    role_name = nil if user

    f = NfsStore::Filter::Filter.create!(
      current_admin: @admin,
      app_type: @app_type,
      role_name: role_name,
      user: user,
      resource_name: resource_name,
      filter: filter
    )
  end

  def create_stored_file  file_path, file_name, container: nil, activity_log: nil

    activity_log ||= @activity_log

    container ||= activity_log&.container || @container

    NfsStore::Manage::StoredFile.create!(
        container: container,
        file_name: file_name,
        path: file_path,
        content_type: 'application/dicom',
        file_hash: 'dummy',
        file_size: 0,
        prevent_processing: true
    )
  end


  it "creates filters for a user and role" do

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

  it "creates filters for a user and role in activity log" do

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

  it "applies filters for the current user to container" do

    create_stored_file '.', 'not_abc_ is a test'
    create_stored_file '.', 'abc_ is a test'

    # No filter specified? No results returned
    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    expect(res.length).to eq 0

    f = create_filter('^----nothing')

    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    expect(res.length).to eq 0

    f = create_filter('^/abc')
    f = create_filter('^dir\/')
    f = create_filter('^/ghi')


    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    expect(res.length).to eq 1
    expect(res.first.file_name).to eq 'abc_ is a test'

    create_stored_file 'dir1', 'abc_ is a test3'
    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    expect(res.length).to eq 1

    create_stored_file 'dir', 'abc_ is a test2'
    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    expect(res.length).to eq 2
    expect(res.first.file_name).to eq 'abc_ is a test'
    expect(res.last.file_name).to eq 'abc_ is a test2'




  end

end
