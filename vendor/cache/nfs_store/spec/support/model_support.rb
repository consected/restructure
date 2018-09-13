module ModelSupport

  UserPrefix = 'g-ttuser-'
  UserDomain = 'testing.com'

  def gen_username r
    "#{UserPrefix}#{r}@#{UserDomain}"
  end

  def pick_one_from objs
    objs[rand objs.length]
  end

  def create_user r=nil, extra='', opt={}

    unless r
      r = Time.new.to_f.to_s
    end
    good_email = gen_username("#{r}-#{extra}-")


    # admin, _ = create_admin
    user = User.create! email: good_email#, current_admin: admin
    good_password = user.password
    @user = user

    app_type = Admin::AppType.active.first

    unless opt[:no_app_type_setup]
      Admin::UserAccessControl.create! user: user, app_type: app_type, access: :read, resource_type: :general, resource_name: :app_type#, current_admin: admin
    end

    # Set a default app_type to use to allow non-interactive tests to continue
    user.app_type = app_type
    user.save!


    if opt[:create_master]
      Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :create_master, user: @user#, current_admin: @admin
    end

    [user, good_password]
  end


  def create_user_role role_name, user: nil, app_type: nil
    user ||= @user
    app_type ||= user.app_type
    Admin::UserRole.create! app_type: app_type, role_name: role_name, user: user#, current_admin: @admin
  end

  def create_app_type name: name, label: label
    Admin::AppType.create! name: name, label: label #, current_admin: @admin
  end

end
