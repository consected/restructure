module NfsStoreSupport

  DefaultRole = 'file1'


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

    if ActivityLog::PlayerContactPhone
      ActivityLog.send(:remove_const, "PlayerContactPhone")
    end

    aldef = ActivityLog.new(
      name: "AL Filter Test",
      item_type: 'player_contact',
      rec_type: 'phone',
      action_when_attribute: "created_at"
    )

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    @layout = Admin::MessageTemplate.create! name: 'test email layout upload', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}.</p>'
    @content = Admin::MessageTemplate.create! name: 'test email content upload', message_type: :email, template_type: :content, template: t, current_admin: @admin

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

        on_upload:
          notify:
            type: email
            role: upload notify role
            layout_template: test email layout upload
            content_template: test email content upload
            subject: Send test

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
    setup_access :download_files, resource_type: :general, access: :read

    basedir = '/var/tmp/nfs_store_tmp'
    FileUtils.mkdir_p File.join(basedir, 'gid600', "app-type-#{@app_type.id}", "containers")

    @player_contact.master.current_user = @user
    al = @player_contact.activity_log__player_contact_phones.build(select_call_direction: 'from player', select_who: 'user', extra_log_type: :step_1)
    al.save!
    @activity_log = al
    @container = NfsStore::Manage::Container.last
    @container.parent_item ||= @activity_log

    expect(@container).not_to be nil

    @container.master.current_user ||= @user
    @container.save!

  end

  def upload_file filename='test-name.txt', content=nil

    content ||= SecureRandom.hex
    md5tot = Digest::MD5.hexdigest(content)
    ioupload = StringIO.new(content)

    u = NfsStore::Upload.new container: @container, user: @container.master.current_user, file_name: filename, file_hash: md5tot, content_type: MIME::Types.type_for(filename)&.first
    u.upload = ioupload

    u.consume_chunk upload: ioupload, headers: {}, chunk_hash: md5tot
    u.save!
    u
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


end
