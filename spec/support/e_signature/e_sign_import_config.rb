# frozen_string_literal: true

module ESignImportConfig
  include MasterSupport

  def db_name
    ActiveRecord::Base.connection.current_database
  end

  def self.import_config
    # Setup the triggers, functions, etc
    config_dir = Rails.root.join('spec', 'fixtures', 'app_configs', 'config_files')
    config_fn = 'test esign_config.json'
    SetupHelper.setup_app_from_import 'test esign', config_dir, config_fn

    als = ActivityLog.active.find_by(table_name: 'activity_log_player_info_e_signs')
    raise 'ActivityLog for player info e-signs not found' if als.nil?
  end

  def setup_config
    seed_database

    create_admin
    create_user

    als = ActivityLog.active.find_by(table_name: 'activity_log_player_info_e_signs')
    expect(als).not_to be nil
    als.implementation_class_defined?(::ActivityLog)
    expect(defined? ActivityLog::PlayerInfoESign).to be_truthy

    new_app_type = Admin::AppType.where(name: 'test esign').first
    new_app_type.update! disabled: false, current_admin: @admin if new_app_type.disabled?

    enable_user_app_access new_app_type, User.batch_user
    Admin::UserRole.find_or_create_by!(role_name: 'nfs_store group 600', user: User.batch_user, app_type: new_app_type) do |ur|
      ur.current_admin = @admin
    end

    cdir = File.join(NfsStore::Manage::Filesystem.nfs_store_directory, 'gid600', "app-type-#{new_app_type.id}", 'containers')
    FileUtils.rm_rf cdir
    FileUtils.mkdir_p cdir

    new_app_type
  end

  def setup_access_as(role, for_user: nil)
    for_user ||= @user

    app_name = 'test esign'
    @app_type = Admin::AppType.active.where(name: app_name).first
    enable_user_app_access app_name, for_user
    for_user.update!(app_type: @app_type)
    # Ensure we have adequate access controls
    add_user_to_role role, for_user:
  end
end
