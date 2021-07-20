# frozen_string_literal: true

module NfsStoreSupport
  AlFilterTestName = 'AL Filter Test 2'
  SetupHelper.setup_al_gen_tests AlFilterTestName, nil, 'player_contact', rec_type: 'phone'

  def default_role
    'file1'
  end

  def setup_nfs_store(clean_files: true)
    create_admin
    create_user

    @trash_master = create_master
    @trash_pc = create_item(data: rand(10_000_000_000_000_000), rank: 0)

    @app_type = @user.app_type
    expect(@user.has_access_to?(:access, :general, :app_type, alt_app_type_id: @app_type.id)).to be_truthy
    create_user_role default_role, user: @user, app_type: @app_type
    create_user_role 'nfs_store group 600', user: @user, app_type: @app_type

    enable_user_app_access(@app_type, User.batch_user)
    User.use_batch_user @app_type
    expect(User.batch_user.has_access_to?(:access, :general, :app_type, alt_app_type_id: @app_type.id)).to be_truthy
    batch_user = User.use_batch_user @app_type.id

    begin
      create_user_role default_role, user: batch_user, app_type: @app_type
    rescue StandardError
      nil
    end

    begin
      create_user_role 'nfs_store group 600', user: batch_user, app_type: @app_type
    rescue StandardError
      nil
    end

    if clean_files
      test_dir = File.join(
        NfsStore::Manage::Filesystem.nfs_store_directory,
        "#{NfsStore::Manage::Group::NfsMountNamePrefix}600",
        "app-type-#{@app_type.id}",
        'containers'
      )
      FileUtils.rm_rf test_dir
      FileUtils.mkdir_p test_dir
    end

    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    create_item(data: rand(10_000_000_000_000_000), rank: 10)

    @al_name = AlFilterTestName
    @al_item_type = 'player_contact'

    aldefs = ActivityLog.active.where(name: @al_name)
    @aldef = aldefs.first

    if aldefs.count >= 1
      # Cleanup duplicate defs

      aldefs.each do |a|
        a.disable!(@admin) unless a.id == @aldef.id
      end
    end

    unless @aldef
      @aldef = ActivityLog.where(name: @al_name).first
      @aldef.update(disabled: false, current_admin: @admin)
      @aldef = ActivityLog.active.where(name: @al_name).first
      puts 'About to fail' unless @aldef
    end
    expect(@aldef).not_to be nil

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    @layout = Admin::MessageTemplate.create! name: 'test email layout upload', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}.</p>'
    @content = Admin::MessageTemplate.create! name: 'test email content upload', message_type: :email, template_type: :content, template: t, current_admin: @admin

    @aldef.extra_log_types = <<ENDDEF
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

      nfs_store:
        pipeline:
          - mount_archive:
          - index_files:
          - dicom_metadata:

    step_2:
      label: Step 2
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

ENDDEF

    @aldef.current_admin = @admin
    @aldef.save!
    @aldef.option_configs(force: true)
    ActivityLog::PlayerContactPhone.definition.option_configs(force: true)

    finalize_al_setup user: @user
    finalize_al_setup user: batch_user, skip_al_setup: true
  end

  def finalize_al_setup(activity: nil, user: nil, skip_al_setup: nil)
    user ||= @user
    activity ||= :step_1
    @resource_name = ActivityLog::PlayerContactPhone.definition.option_type_config_for(activity).resource_name

    setup_access 'activity_log__player_contact_phones', user: user
    setup_access @resource_name, resource_type: :activity_log_type, user: user
    setup_access "activity_log__player_contact_phone__#{activity}".to_sym, resource_type: :activity_log_type, user: user

    setup_access 'nfs_store__manage__containers', user: user
    setup_access 'nfs_store__manage__stored_files', user: user
    setup_access 'nfs_store__manage__archived_files', user: user
    setup_access :download_files, resource_type: :general, access: :read, user: user

    return if @user.id == User.batch_user.id || skip_al_setup

    basedir = NfsStore::Manage::Filesystem.temp_directory
    FileUtils.mkdir_p File.join(basedir, 'gid600', "app-type-#{@app_type.id}", 'containers')
    @player_contact.master.current_user = user

    # Make sure the tests will run cleanly
    mrs = ModelReference.all
    mrs.update_all from_record_master_id: @trash_master.id, from_record_id: nil

    setup_container_and_al activity: activity
  end

  def setup_container_and_al(activity: nil)
    activity ||= :step_1

    names = ActivityLog::PlayerContactPhone.definition.option_configs.map(&:name)
    expect(names).to include activity

    @activity_log = ActivityLog::PlayerContactPhone.new(
      select_call_direction: 'from player',
      select_who: 'user',
      extra_log_type: activity,
      player_contact: @player_contact,
      master: @player_contact.master
    )

    @activity_log.save!
    expect(@activity_log.resource_name).to eq "activity_log__player_contact_phone__#{activity}"

    @container = @activity_log.model_references.first.to_record
    expect(@container).not_to be nil
    # end

    @container.parent_item = @activity_log
    @activity_log.current_user = @user
    @container.current_user = @user

    expect(@activity_log).to be_a ActivityLog::PlayerContactPhone
    expect(@activity_log.resource_name).to eq "activity_log__player_contact_phone__#{activity}"
    expect(@activity_log.extra_log_type_config.nfs_store).to be_a Hash

    @container
  end

  def setup_default_filters(activity: nil)
    activity ||= :step_1
    create_filter('.*', role_name: nil)
    create_filter('.*', resource_name: 'nfs_store__manage__containers', role_name: nil)
    create_filter('.*', resource_name: 'activity_log__player_contact_phones', role_name: nil)
    create_filter('.*', resource_name: "activity_log__player_contact_phone__#{activity}", role_name: nil)
  end

  def upload_file(filename = 'test-name.txt', content = nil)
    content ||= SecureRandom.hex
    upload_set = SecureRandom.hex
    md5tot = Digest::MD5.hexdigest(content)
    ioupload = StringIO.new(content)

    u = NfsStore::Upload.new container: @container, user: @container.master.current_user, file_name: filename, file_hash: md5tot, upload_set: upload_set, content_type: MIME::Types.type_for(filename)&.first
    u.upload = ioupload

    u.consume_chunk upload: ioupload, headers: {}, chunk_hash: md5tot
    u.save!
    u
  end

  def create_filter(filter, role_name: default_role, user: nil, resource_name: nil)
    resource_name ||= @resource_name
    role_name = nil if user

    NfsStore::Filter::Filter.create!(
      current_admin: @admin,
      app_type: @app_type,
      role_name: role_name,
      user: user,
      resource_name: resource_name,
      filter: filter
    )
  end

  def clear_filters
    NfsStore::Filter::Filter.active.where(app_type: @app_type).update_all(disabled: true)
  end

  def create_stored_file(file_path, file_name, container: nil, activity_log: nil)
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
