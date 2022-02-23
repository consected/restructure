# frozen_string_literal: true

require "#{::Rails.root}/spec/support/activity_log_feature_support/activity_log_setup"
module SpecSetup
  def setup_database
    # puts 'setup database'
    Rails.logger.info 'Setting up database in SpecSetup'

    # Clean up old activity log definitions
    create_admin unless @admin

    als = ActivityLog.active.where(item_type: 'zeus_bulk_message')
    als.each do |al|
      al.update(disabled: true)
    end

    first_al = als.first
    if first_al
      ActivityLogSupport.cleanup_matching_activity_logs(first_al.item_type, first_al.rec_type, first_al.process_name, admin: @admin, excluding_id: first_al.id)
    end

    als = ActivityLog.active.where(name: 'Phone Log')
    als.where('id <> ?', als.first&.id).update_all(disabled: true) if als.count != 1

    first_al = als.first
    if first_al
      ActivityLogSupport.cleanup_matching_activity_logs(first_al.item_type, first_al.rec_type, first_al.process_name, admin: @admin, excluding_id: first_al.id)
      first_al.update!(current_admin: auto_admin, disabled: false)
    end

    expect(ActivityLog.model_names).to include 'player_contact_phone'

    Seeds::ActivityLogPlayerContactPhone.setup
    Seeds::ATrackerUpdatesProtocol.setup

    seed_database

    Master.reset_external_id_matching_fields!

    ActivityLog.enable_active_configurations

    ::ActivityLog::PlayerContactPhone

    # puts 'create data set'
    # create_data_set_outside_tx

    # puts 'create phone log config'
    create_phone_log_config

    # puts 'creating a login user'
    create_user_for_login

    setup_access :addresses
    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    setup_access :trackers
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create
    setup_access :activity_log__player_contact_phone__blank, resource_type: :activity_log_type, access: :create

    ActiveRecord::Base.connection.execute("
                           delete from activity_log_player_contact_phone_history;
                           delete from activity_log_player_contact_phones;
                           delete from player_contact_history;
                           delete from player_contacts;
                           delete from tracker_history where item_type = 'ActivityLog::PlayerContactPhone';
                           delete from trackers where item_type = 'ActivityLog::PlayerContactPhone';")

    # puts "create contacts and logs"
    create_data_set
    create_data_set
    create_data_set
    @test_player_infos = PlayerInfo.all[-20..-1]
    @test_player_infos.each do |p|
      m = p.master
      res = m.player_contacts.phone
      res = create_player_phone p.master, 2 unless res.length > 1
      res.each do |c|
        al = c.activity_log__player_contact_phones
        create_phone_logs c, 2 unless al.length > 1
      end

      raise 'Failed to create player contacts correctly' if p.master.player_contacts.length < 2
      raise 'Failed to create activity logs correctly' if p.master.activity_log__player_contact_phones.length < 2
    end
  end
end
