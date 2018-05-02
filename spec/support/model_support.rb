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
    good_password = user.password
    @user = user

    app_type = Admin::AppType.active.first

    unless opt[:no_app_type_setup]
      Admin::UserAccessControl.create! user: user, app_type: app_type, access: :read, resource_type: :general, resource_name: :app_type, current_admin: admin
    end

    # Set a default app_type to use to allow non-interactive tests to continue
    user.app_type = app_type
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
    good_admin_password = admin.password
    @admin = admin
    [admin, good_admin_password]
  end
end
