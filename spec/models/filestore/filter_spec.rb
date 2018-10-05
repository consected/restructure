require 'rails_helper'

RSpec.describe NfsStore::Filter::Filter, type: :model do

  include PlayerContactSupport
  include ModelSupport

  DefaultRole = 'file1'

  before :all do
    seed_database
    ::ActivityLog.define_models

    create_admin
    create_user

    @app_type = @user.app_type
    create_user_role DefaultRole, user: @user, app_type: @app_type
    create_user_role 'nfs_store group 600', user: @user, app_type: @app_type
    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    create_item(data: rand(10000000000000000), rank: 10)

    aldef = ActivityLog.where(name: 'AL Filter Test').first
    unless aldef
      aldef = ActivityLog.new(
        name: "AL Filter Test",
        item_type: 'player_contact',
        rec_type: 'phone',
        action_when_attribute: "created_at"
      )
    end

    aldef.extra_log_types =<<EOF
    step_1:
      label: Step 1
      fields:
        - select_call_direction
        - select_who

      save_trigger:
        on_create:
          create_filestore_container:
            name:
              - session files
              - select_scanner
            label: Session Files
            create_with_role: nfs_store group 600

      references:
        nfs_store__manage__container:
          label: Files
          from: this
          add: one_to_this
          view_as:
            edit: hide
            show: filestore
            new: not_embedded

EOF

    aldef.current_admin = @admin
    aldef.save!

    @resource_name = ActivityLog::PlayerContactPhone.extra_log_type_config_for(:step_1).resource_name


    setup_access 'activity_log__player_contact_phones'
    setup_access @resource_name, resource_type: :activity_log_type
    setup_access 'nfs_store__manage__containers'
    setup_access 'nfs_store__manage__stored_files'
    setup_access 'nfs_store__manage__archived_files'

    basedir = '/var/tmp/nfs_store_tmp'
    FileUtils.mkdir_p File.join(basedir, 'gid600', "app-type-#{@app_type.id}", "containers")

    @player_contact.master.current_user = @user
    al = @player_contact.activity_log__player_contact_phones.build(select_call_direction: 'from player', select_who: 'user', extra_log_type: :step_1)
    al.save!
    @activity_log = al
    @container = NfsStore::Manage::Container.last
    @container.master.current_user ||= @user


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

    container ||= @container

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

    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    expect(res.length).to eq 2

    f = create_filter('^----nothing')

    res = NfsStore::Filter::Filter.evaluate_container_files @activity_log
    expect(res.length).to eq 0

    f = create_filter('^\/abc')
    f = create_filter('^dir\/')
    f = create_filter('^\/ghi')


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
