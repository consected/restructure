module NfsStoreSupport


  def setup_nfs_store
    seed_database
    ::ActivityLog.define_models

    create_admin
    create_user


    @app_type = @user.app_type
    create_user_role DefaultRole, user: @user, app_type: @app_type
    create_user_role 'nfs_store group 600', user: @user, app_type: @app_type


    test_dir = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, "#{NfsStore::Manage::Group::NfsMountNamePrefix}600", "app-type-#{@app_type.id}", 'containers')
    FileUtils.rm_rf test_dir
    FileUtils.mkdir_p test_dir

    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    create_item(data: rand(10000000000000000), rank: 10)

    aldef = ActivityLog.where(name: 'AL Filter Test').update_all(name: "AL Filter OLD #{rand(10000000)}")

    aldef = ActivityLog.new(
      name: "AL Filter Test",
      item_type: 'player_contact',
      rec_type: 'phone',
      action_when_attribute: "created_at"
    )


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

end
