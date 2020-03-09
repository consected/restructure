# frozen_string_literal: true

require "#{::Rails.root}/spec/support/seeds"

module SetupHelper
  def self.auto_admin
    admin, = ModelSupport.create_admin
    admin
  end

  def self.db_name
    "fpa_test#{ENV['TEST_ENV_NUMBER']}"
  end

  def self.validate_db_setup
    # Ensure we are set up for this test
    res = File.read("#{ENV['HOME']}/.pgpass").include? db_name
    raise ".pgpass does not contain entry for database #{db_name}" unless res

    q = ActiveRecord::Base.connection.execute "select * from pg_catalog.pg_roles where rolname='fphsetl'"
    res = q.ntuples
    unless res == 1
      raise "Database #{db_name} does not have role fphsetl set up"
    end
  end

  # Setup the byebug service if breakpoints are set in the .byebugrc file
  # if not, just skip it
  def self.setup_byebug
    bbrc = Rails.root.join('.byebugrc')
    init_bb = false
    if File.exist?(bbrc)
      fbb = File.read(bbrc)
      init_bb = !!fbb.index(/^b /)
    end

    if ENV['BYEBUG'] == 'true'
      puts "Running Remote Byebug server.\nTo connect, run:\n   byebug -R localhost:8099"
      require 'byebug/core'
      Byebug.wait_connection = true
      Byebug.start_server('localhost', 8099)
    end
    byebug if init_bb
  end

  def self.reload_configs
    AppControl.define_models
    DynamicModel.enable_active_configurations
    ItemFlag.enable_active_configurations
    ActivityLog.enable_active_configurations
    ExternalIdentifier.enable_active_configurations
    DynamicModel.routes_reload
  end

  def self.feature_setup(_options = {})
    Seeds.setup
    # MasterDataSupport.create_data_set_outside_tx options
  end

  # Setup Activity Log Player Contact Phones
  def self.setup_al_player_contact_phones
    # Ensure that we seed the database, otherwise the PlayerContactPhonesController class does not exist
    RSpec.configure do |c|
      c.before do
        Seeds::GeneralSelections.setup
        Seeds::ActivityLogPlayerContactPhone.setup
      end
    end

    reload_configs

    unless defined? ActivityLog::PlayerContactPhone
      raise 'Activity Log for Player Contact Phones has not been setup correctly.'
    end

    ActivityLog::PlayerContactPhone.definition.update_tracker_events
  end

  # Setup a general Activity Log, with the template of an Activity Log Player Contact Phones, but
  # named uniquely and attached to chosen item_type / rec_type
  def self.setup_al_gen_tests(name, process_name, item_type, rec_type: nil)
    Seeds::GeneralSelections.setup if item_type&.to_s == 'player_contact'

    itn = ActivityLog.item_type_name(item_type, process_name, rec_type)
    tname = 'activity_log_' + itn.pluralize
    cname = 'ActivityLog::' + itn.ns_camelize

    unless ActivityLog.connection.table_exists? tname
      TableGenerators.activity_logs_table(tname, item_type.to_s.pluralize, true,
                                          'data', 'select_call_direction', 'select_who', 'called_when', 'select_result', 'select_next_step', 'follow_up_when', 'notes', 'protocol_id', 'set_related_player_contact_rank')
    end

    res = ActivityLog.find_or_initialize_by(name: name, item_type: item_type, rec_type: rec_type, process_name: process_name, disabled: false, action_when_attribute: 'called_when',
                                            field_list: 'data, select_call_direction, select_who, called_when, select_result, select_next_step, follow_up_when, notes, protocol_id, set_related_player_contact_rank',
                                            blank_log_field_list: 'select_who, called_when, select_next_step, follow_up_when, notes, protocol_id')
    unless res.is_active_model_configuration?
      # If this was a new item, set an admin. Also set disabled nil, since this forces regeneration of the model
      res.update!(current_admin: auto_admin) unless res.admin
      tu = User.template_user
      app_type = Admin::AppType.active.first
      # Ensure there is at least one user access control, otherwise we won't re-enable the process on future loads
      res.other_regenerate_actions
      res.add_user_access_controls force: true, app_type: app_type
      res.update_tracker_events
      reload_configs
    end

    # Check implementation
    test = ActivityLog.active.where(name: name).count == 1

    raise "Failed setup of activity log #{name}" unless test

    res.implementation_class
    cname.constantize

    res
  end

  def self.setup_test_app
    app_name = "bhs_model_#{rand(100_000_000)}"

    sql_files = %w[1-create_bhs_assignments_external_identifier.sql 2-create_activity_log.sql 6-grant_roles_access_to_ml_app.sql create_adders_table.sql]
    sql_source_dir = Rails.root.join('docs', 'config_tests')
    config_dir = Rails.root.join('docs', 'config_tests')
    config_fn = 'bhs_app_type_test_config.json'
    SetupHelper.setup_app_from_import app_name, sql_source_dir, sql_files, config_dir, config_fn

    new_app_type = Admin::AppType.where(name: app_name).active.first
    Admin::UserAccessControl.active.where(app_type_id: new_app_type.id, resource_type: %i[external_id_assignments limited_access]).update_all(disabled: true)

    new_app_type
  end

  # Setup an app from an import configuration (json or yaml)
  #
  # @param [String] name the name of the app to be set
  # @param [String] sql_source_dir location of the SQL files to be run
  # @param [String] sql_files list of SQL files to be run through PSQL
  # @param [String] config_dir location of the configuration file
  # @param [String] config_fn filename of the configuration file (must have file extension .json or .yaml)
  # @return [Array(Admin::AppType, Hash)] returns the results from Admin::AppType.import_config
  #
  def self.setup_app_from_import(name, sql_source_dir, sql_files, config_dir, config_fn)
    admin = auto_admin

    als = ActivityLog.active.where(name: name)
    if als.count != 1
      als.where('id <> ?', als.first&.id).update_all(disabled: true)
    end

    sql_files.each do |fn|
      begin
        sqlfn = Rails.root.join(sql_source_dir, fn)
        puts "Running psql: #{sqlfn}"
        `PGOPTIONS=--search_path=ml_app psql -v ON_ERROR_STOP=ON -d #{db_name} < #{sqlfn}`
      rescue ActiveRecord::StatementInvalid => e
        puts "Exception due to PG error?... #{e}"
      end
    end

    format = config_fn.split('.').last.to_sym

    res = Admin::AppType.import_config File.read(Rails.root.join(config_dir, config_fn)), admin, name: name, format: format

    reload_configs

    res
  end
end
