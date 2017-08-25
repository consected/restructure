module UserSetup

  include MasterDataSupport
  include ModelSupport

  def setup_database
    seed_database
    create_data_set

    PlayerInfo.all.each do |p|
      create_player_phone p.master
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
