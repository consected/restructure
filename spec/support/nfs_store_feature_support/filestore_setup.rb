# frozen_string_literal: true

# Setup support for NFS Store filestore UI system specs
# Provides methods to configure activity logs with filestore capabilities,
# create test data, and set up proper user access controls.
module FilestoreSetup
  include ModelSupport

  ActivityLogName = 'Filestore UI Test'

  # Setup the activity log definition with filestore configuration
  # This creates an activity log type that includes a filestore container
  # with full user file action capabilities (upload, rename, send to trash)
  def setup_filestore_activity_log
    create_admin unless @admin

    # Set up the filestore directory
    @app_type = @user.app_type
    test_dir = File.join(
      NfsStore::Manage::Filesystem.nfs_store_directory,
      "#{NfsStore::Manage::Group::NfsMountNamePrefix}600",
      "app-type-#{@app_type.id}",
      'containers'
    )
    FileUtils.rm_rf test_dir
    FileUtils.mkdir_p test_dir

    # Create or find the activity log definition
    @aldef = ActivityLog.active.where(name: ActivityLogName).first
    if @aldef
      ActivityLogSupport.cleanup_matching_activity_logs(
        @aldef.item_type, @aldef.rec_type, @aldef.process_name,
        admin: @admin, excluding_id: @aldef.id
      )
    else
      @aldef = ActivityLog.where(name: ActivityLogName).first
      if @aldef
        ActivityLogSupport.cleanup_matching_activity_logs(
          @aldef.item_type, @aldef.rec_type, @aldef.process_name,
          admin: @admin, excluding_id: @aldef.id
        )
        @aldef.update(disabled: false, current_admin: @admin)
      else
        SetupHelper.setup_al_gen_tests ActivityLogName, nil, 'player_contact', rec_type: 'phone'
        @aldef = ActivityLog.active.where(name: ActivityLogName).first
      end
    end

    raise 'Failed to set up filestore activity log definition' unless @aldef

    # Configure the activity log with filestore and supporting documents
    @aldef.extra_log_types = filestore_extra_log_types_config
    @aldef.current_admin = @admin
    @aldef.save!
    @aldef.option_configs(force: true)

    ActivityLog.define_models
    ActivityLog::PlayerContactPhone.definition.option_configs(force: true)

    @aldef
  end

  # Configuration for the extra log types including supporting documents
  def filestore_extra_log_types_config
    <<~ENDDEF
      phone_log:
        label: Phone Log
        fields:
          - select_call_direction
          - select_who
          - notes

      supporting_documents:
        label: Supporting Documents
        fields:
          - notes

        save_trigger:
          on_create:
            create_filestore_container:
              name:
                - supporting files
              label: Supporting Files
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

        nfs_store:
          pipeline:
            - mount_archive:
            - index_files:

    ENDDEF
  end

  # Set up user access for filestore operations
  def setup_filestore_user_access(user: nil)
    user ||= @user
    app_type = user.app_type

    # Basic access
    setup_access :player_contacts, user: user
    setup_access :player_infos, user: user

    # Activity log access
    setup_access :activity_log__player_contact_phones, user: user
    setup_access :activity_log__player_contact_phone__phone_log, resource_type: :activity_log_type, user: user
    setup_access :activity_log__player_contact_phone__supporting_documents, resource_type: :activity_log_type, user: user

    # Filestore access
    setup_access :nfs_store__manage__containers, user: user
    setup_access :nfs_store__manage__stored_files, user: user
    setup_access :nfs_store__manage__archived_files, user: user
    setup_access :download_files, resource_type: :general, access: :read, user: user
    setup_access :send_files_to_trash, resource_type: :general, access: :read, user: user
    setup_access :move_files, resource_type: :general, access: :read, user: user

    # Role for filestore group
    create_user_role 'nfs_store group 600', user: user, app_type: app_type
  end

  # Set up the filestore filters to allow all files
  def setup_filestore_filters
    resource_name = 'activity_log__player_contact_phone__supporting_documents'

    # Clear existing filters
    NfsStore::Filter::Filter.active.where(app_type: @app_type, resource_name: resource_name).update_all(disabled: true)

    # Create a filter that allows all files
    NfsStore::Filter::Filter.create!(
      current_admin: @admin,
      app_type: @app_type,
      role_name: nil,
      user: nil,
      resource_name: resource_name,
      filter: '.*'
    )
  end

  # Create a test master record with phone contact
  def create_filestore_test_data
    @master = create_master
    @player_contact = create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @player_contact.master.current_user = @user

    @master
  end

  # Create a file for testing
  def create_test_file_content(filename = 'test-document.txt')
    content = "Test file content for filestore testing - #{SecureRandom.hex}"
    { filename: filename, content: content }
  end
end
