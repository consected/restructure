require "#{::Rails.root}/spec/support/activity_log_feature_support/activity_log_setup"
module SpecSetup

  def setup_database
    puts 'setup database'
    seed_database

    if ActivityLog.connection.table_exists? "activity_log_player_contact_phones"
      sql = TableGenerators.activity_logs_table('activity_log_player_contact_phones', 'player_contacts', :drop_do)
    end

    TableGenerators.activity_logs_table('activity_log_player_contact_phones', 'player_contacts', true, 'select_result', 'select_next_step', 'follow_up_when', 'protocol_id', 'select_call_direction', 'select_who', 'called_when', 'notes', 'data', 'set_related_player_contact_rank')


    ActivityLog.enable_active_configurations

    ::ActivityLog::PlayerContactPhone

    puts 'create data set'
    create_data_set

    puts 'create phone log config'
    create_phone_log_config

    puts 'creating a login user'
    create_user_for_login


    setup_access :player_contacts

    # Ensure the table can be accessed
    uacs = Admin::UserAccessControl.where app_type: @user.app_type, resource_type: :table, resource_name: :activity_log__player_contact_phones
    uac = uacs.first
    if uac
      uac.access = :create
      uac.disabled = false
      uac.current_admin = @admin
      uac.save!
    else
      uac = Admin::UserAccessControl.create! app_type: @user.app_type, access: :create, resource_type: :table, resource_name: :activity_log__player_contact_phones, current_admin: @admin
    end

    # Ensure the steps can be accessed
    [:primary, :blank_log].each do |s|
      rn = (ActivityLog.enabled.first.extra_log_type_configs.select{|a| a.name == s}.first).resource_name
      uacs = Admin::UserAccessControl.where app_type: @user.app_type, resource_type: :activity_log_type, resource_name: rn
      uac = uacs.first
      if uac
        # uac.access = :create
        # uac.disabled = false
        # uac.current_admin = @admin
        # uac.save!
      else
        uac = Admin::UserAccessControl.create! app_type: @user.app_type, access: :create, resource_type: :activity_log_type, resource_name: rn, current_admin: @admin
      end
    end



    puts "cleanup player contacts"

    ActiveRecord::Base.connection.execute("delete from player_contact_history;
                           -- delete from activity_log_player_contact_phone_history;
                           delete from activity_log_player_contact_phones;
                           delete from player_contacts;
                           delete from tracker_history where item_type = 'ActivityLog::PlayerContactPhone';
                           delete from trackers where item_type = 'ActivityLog::PlayerContactPhone';")


    puts "create contacts and logs"
    @test_player_infos = PlayerInfo.all[-20..-1]
    @test_player_infos.each do |p|
      m = p.master
      # pr = Classification::Protocol.active.where(name: 'Study').first
      # sp = pr.sub_processes.active.where(name: 'Alerts').first
      # pe = sp.protocol_events.active.where(name: 'Level 1').first
      #
      # m.current_user = @user
      # m.trackers.create!(protocol: pr, sub_process: sp, protocol_event: pe, event_date: DateTime.now)

      res = m.player_contacts.phone
      unless res.length > 1
        res = create_player_phone p.master, 2
      end
      res.each do |c|
        al = c.activity_log__player_contact_phones
        unless al.length > 1
          create_phone_logs c, 2
        end
      end

      raise "Failed to create player contacts correctly" if p.master.player_contacts.length < 2
      raise "Failed to create activity logs correctly" if p.master.activity_log__player_contact_phones.length < 2

    end
  end

  def user_logs_in
  #Given "the user has logged in" do
    login unless user_logged_in?
    expect(user_logged_in?).to be true
  end


  def create_user_for_login
    @user, @good_password  = create_user
    @good_email  = @user.email
  end

  def user_logout
    logout
  end

  def user_logged_in?
    res = all('.nav a[data-do-action="show-user-options"]')
    return res.length > 0
  end
end
