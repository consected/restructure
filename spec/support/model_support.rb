require "#{::Rails.root}/spec/support/seed_support"
module ModelSupport

  UserPrefix = 'g-ttuser-'
  UserDomain = 'testing.com'

  def seed_database
    Rails.logger.info "NOT Starting seed setup"
    # SeedSupport.setup
  end

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


    admin, _ = create_admin
    user = User.create! email: good_email, current_admin: admin
    @user = user

    app_type = Admin::AppType.active.first

    unless opt[:no_app_type_setup]
      Admin::UserAccessControl.create! user: user, app_type: app_type, access: :read, resource_type: :general, resource_name: :app_type, current_admin: admin
    end

    # Set a default app_type to use to allow non-interactive tests to continue
    user.app_type = app_type
    user.save!

    # Save a new password, as required to handle temp passwords
    user  = User.find(user.id)
    user.current_admin = admin
    good_password = user.generate_password
    user.save!

    if opt[:create_master]
      Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :create_master, current_admin: @admin, user: @user
    end

    [user, good_password]
  end

  def create_admin  r=nil

    a = Admin.order(id: :desc).first
    unless r
      r = 1
      r = a.id + 1 if a
    end
    good_admin_email = "e-testadmin-tester#{r}@testing.com"

    admin = Admin.create! email: good_admin_email

    # Save a new password, as required to handle temp passwords
    admin = Admin.find(admin.id)
    good_admin_password = admin.generate_password
    admin.save!

    @admin = admin
    [admin, good_admin_password]
  end

  def create_user_role role_name, user: nil, app_type: nil
    user ||= @user
    app_type ||= user.app_type
    Admin::UserRole.create! current_admin: @admin, app_type: app_type, role_name: role_name, user: user
  end

  def create_app_type name: nil, label: nil
    Admin::AppType.create! current_admin: @admin, name: name, label: label
  end

  def let_user_create_player_infos in_app_type: nil
    res = @user.has_access_to? :access, :table, :player_infos
    if res && res.user_id == @user.id
      res.disabled = true
      res.current_admin = @admin
      res.save!
    # else
    end

    in_app_type ||= @user.app_type
    Admin::UserAccessControl.create! current_admin: @admin, app_type: in_app_type, user: @user, access: :create, resource_type: :table, resource_name: :player_infos

  end

  def add_app_config app_type, name, value, user: nil, role_name: nil
    @admin ||= create_admin

    cond = {name: name}
    cond[:role_name] = role_name if role_name
    cond[:user] = user if user

    ac = app_type.app_configurations.active.where(cond).first
    if ac
      cond[:current_admin] = @admin
      ac.update! cond
    else
      cond = cond.merge(current_admin: @admin, app_type: app_type, value: value)
      Admin::AppConfiguration.create! cond
    end

  end

end
