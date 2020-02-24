module ESignImportConfig

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
    files = %w(create_al_table.sql create_ipa_inex_checklist_table.sql)

    files.each do |fn|

      begin
        sqlfn = Rails.root.join('db', 'app_specific', 'test_esign', fn)
        puts "Running psql: #{sqlfn}"
        `PGOPTIONS=--search_path=ml_app psql -d fpa_test < #{sqlfn}`
      rescue ActiveRecord::StatementInvalid => e
        puts "Exception due to PG error?... #{e}"
      end
    end


    create_admin
    create_user

    # apps = Admin::AppType.active.where(name: 'test esign')
    # if apps.active.count == 1
    #   als = ActivityLog.active.where(table_name: 'activity_log_player_info_e_signs')
    #   als.first.implementation_class_defined?(::ActivityLog)
    # else
    #   als = ActivityLog.active.where( table_name: 'activity_log_player_info_e_signs')
    #   als.each do |al|
    #     al.update  current_admin: @admin, disabled: true
    #   end
    #
    #   apps.each do |a|
    #     a.update current_admin: @admin, disabled: true
    #   end
    #
    # end


    Admin::AppType.import_config File.read(Rails.root.join('db', 'app_configs', 'test esign_config.json')), @admin

    als = ActivityLog.active.where(table_name: 'activity_log_player_info_e_signs')
    als.active.first.implementation_class_defined?(::ActivityLog)
    expect(defined? ActivityLog::PlayerInfoESign).to be_truthy

    new_app_type = Admin::AppType.where(name: 'test esign').first
    new_app_type.update! disabled: false, current_admin: @admin if new_app_type.disabled?

    cdir = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, 'gid600', "app-type-#{new_app_type.id}", "containers")
    FileUtils.rm_rf cdir
    FileUtils.mkdir_p cdir

    new_app_type
  end


  def setup_access_as role, for_user: nil

    for_user ||= @user

    app_name = 'test esign'
    @app_type = Admin::AppType.active.where(name: app_name).first
    enable_user_app_access app_name, for_user
    for_user.update!(app_type: @app_type)
    # Ensure we have adequate access controls
    add_user_to_role role, for_user: for_user

  end

end
