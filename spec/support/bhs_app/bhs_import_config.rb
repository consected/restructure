module BhsImportConfig

  include MasterSupport

  def import_config

    seed_database

    # Ensure we are set up for this test
    res = File.read("#{ENV['HOME']}/.pgpass").include? 'fpa_test'
    expect(res).to be true

    q = ActiveRecord::Base.connection.execute "select * from pg_catalog.pg_roles where rolname='fphsetl'"
    res = q.ntuples
    expect(res).to eq 1

    # Setup the triggers, functions, etc
    files = %w(DROP-bhs_tables.sql 1-create_bhs_assignments_external_identifier.sql 2-create_activity_log.sql 3-add_notification_triggers.sql 4-add_testmybrain_trigger.sql 5-create_sync_subject_data_aws_db.sql 6-grant_roles_access_to_ml_app.sql)

    ExternalIdentifier.where(name: 'bhs_assignments').update_all(disabled: true)
    i = ExternalIdentifier.where(name: 'bhs_assignments').order(id: :desc).first
    i.update! disabled: false, min_id: 0, external_id_edit_pattern: nil, current_admin: @admin if i

    ActivityLog.where(table_name: 'activity_log_bhs_assignments').update_all(disabled: true)
    i = ActivityLog.where(table_name: 'activity_log_bhs_assignments').order(id: :desc).first
    i.update! disabled: false, current_admin: @admin if i

    files.each do |fn|

      begin
        sqlfn = Rails.root.join('db', 'app_specific', 'bhs', 'aws-db', fn)
        puts "Running psql: #{sqlfn}"
        `PGOPTIONS=--search_path=ml_app psql -d fpa_test < #{sqlfn}`
      rescue ActiveRecord::StatementInvalid => e
        puts "Exception due to PG error?... #{e}"
      end
    end


    create_admin
    create_user

    eis = ExternalIdentifier.where(name: 'bhs_assignments')
    if eis.length > 0 && eis.active.length == 0
      eis.order(id: :desc).first.update current_admin: @admin, disabled: false
    end

    Admin::AppType.import_config File.read(Rails.root.join('db', 'app_configs', 'bhs_config.json')), @admin

    # Make sure the activity log configuration is available

    ExternalIdentifier.where(name: 'bhs_assignments').update_all(disabled: true)
    i = ExternalIdentifier.where(name: 'bhs_assignments').order(id: :desc).first
    i.update! disabled: false, min_id: 0, external_id_edit_pattern: nil, current_admin: @admin if i

    ActivityLog.where(table_name: 'activity_log_bhs_assignments').update_all(disabled: true)
    i = ActivityLog.where(table_name: 'activity_log_bhs_assignments').order(id: :desc).first
    i.update! disabled: false, current_admin: @admin if i
    ::ActivityLog.define_models
    ::ExternalIdentifier.define_models

    # Admin::UserAccessControl.active.update_all(disabled: true)

    new_app_type = Admin::AppType.where(name: 'bhs').first
    new_app_type.update!(disabled: false, current_admin: @admin)
    new_app_type
  end


  def setup_access_as role

    app_name = BhsUi::AppShortName
    @app_type = Admin::AppType.active.where(name: app_name).first
    enable_user_app_access app_name, @user
    @user.update!(app_type: @app_type)
    # Ensure we have adequate access controls

    # setup_access :player_infos
    # setup_access :player_contacts
    # setup_access :activity_log__bhs_assignments
    #
    # # default settings for activities
    # setup_access :activity_log__bhs_assignment__contact_initiator, resource_type: :activity_log_type, access: :read
    # setup_access :activity_log__bhs_assignment__respond_to_pi, resource_type: :activity_log_type, access: :read
    # setup_access :activity_log__bhs_assignment__primary, resource_type: :activity_log_type, access: :read
    # setup_access :activity_log__bhs_assignment__blank_log, resource_type: :activity_log_type, access: :read
    # setup_access :create_master, resource_type: :general, access: nil
    # setup_access 'BHS Subjects Pending Sync', resource_type: :report, access: nil
    # setup_access 'Contact from PI', resource_type: :report, access: nil
    # remove_user_from_role :pi
    # remove_user_from_role :ra
    add_default_app_config @app_type, :hide_player_tabs, 'true'
    # add_default_app_config @app_type, 'menu create master record label', "Create Subject Record"


    if role == :pi
      add_user_to_role :pi
      add_user_config :hide_player_tabs, 'true'

      setup_access :activity_log__bhs_assignment__blank_log, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__bhs_assignment__contact_initiator, resource_type: :activity_log_type, access: :create, user: @user
    elsif role == :ra
      add_user_to_role :ra
      add_user_config :hide_player_tabs, 'false'
      setup_access :player_contacts
      setup_access :create_master, resource_type: :general, access: :read, user: @user
      setup_access 'BHS Subjects Pending Sync', resource_type: :report, access: :read, user: @user
      setup_access 'Contact from PI', resource_type: :report, access: :read, user: @user
      setup_access :activity_log__bhs_assignment__respond_to_pi, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__bhs_assignment__primary, resource_type: :activity_log_type, access: :create, user: @user
    end

  end

end
