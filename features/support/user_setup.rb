module UserSetup

  include MasterDataSupport
  include ModelSupport
  include ActivityLogSetup
  include PhoneLogSupport

  def setup_database
    puts 'setup database'
    seed_database
    puts 'create data set'
    create_data_set

    puts 'create phone log config'
    create_phone_log_config


    puts'create players'
    PlayerInfo.all.each do |p|
      p.master.player_contacts.phone.each do |pc|
        pc.class.connection.execute("delete from player_contact_history where player_contact_id = #{pc.id.to_i};
                                     delete from activity_log_player_contact_phones where player_contact_id = #{pc.id.to_i};
                                     delete from player_contacts where id = #{pc.id.to_i};")
        
      end
      res = create_player_phone p.master, 2
      res.each do |c|
        create_phone_logs c, 2
      end

      raise "Failed to create player contacts correctly" if p.master.player_contacts.length < 2
      raise "Failed to create activity logs correctly" if p.master.activity_log_player_contact_phones.length < 2

    end
  end



  def user_login
    @user, @good_password  = create_user
    @good_email  = @user.email
    login
  end

  def user_logout
    logout
  end

  def user_logged_in?
    res = all('.nav a[data-do-action="show-user-options"]')
    return res.length > 0
  end
end

World(UserSetup)
