# frozen_string_literal: true

bhs_app_name = "bhs_#{$STARTED_AT}"

module BhsImportConfig
  include MasterSupport

  def app_name
    @app_name ||= BhsImportConfig.bhs_app_name
  end

  def self.bhs_app_name
    @bhs_app_name
  end

  def self.import_config
    ExternalIdentifier.define_models
    config_dir = Rails.root.join('spec', 'fixtures', 'app_configs', 'config_files')
    config_fn = 'bhs_config.json'
    app, = SetupHelper.setup_app_from_import bhs_app_name, config_dir, config_fn
    # app = SetupHelper.setup_test_app
    @bhs_app_name = app.name
    app
  end

  def setup_access_as(role)
    # app_name = BhsUi::AppShortName
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
    setup_access :trackers, resource_type: :table, access: :create, user: @user

    if role == :pi
      add_user_to_role :pi
      add_user_config :hide_player_tabs, 'true'
      setup_access :activity_log__bhs_assignments, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__bhs_assignment__blank_log, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__bhs_assignment__contact_initiator, resource_type: :activity_log_type, access: :create, user: @user
    elsif role == :ra
      add_user_to_role :ra
      add_user_config :hide_player_tabs, 'false'
      setup_access :player_contacts
      setup_access :create_master, resource_type: :general, access: :read, user: @user
      setup_access :bhs_assignments, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__bhs_assignments, resource_type: :table, access: :create, user: @user
      setup_access 'BHS Subjects Pending Sync', resource_type: :report, access: :read, user: @user
      setup_access 'Contact from PI', resource_type: :report, access: :read, user: @user
      setup_access :activity_log__bhs_assignment__respond_to_pi, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__bhs_assignment__primary, resource_type: :activity_log_type, access: :create, user: @user
    end
  end
end
