# frozen_string_literal: true

require "#{::Rails.root}/spec/support/seed_support"
require "#{::Rails.root}/spec/support/user_support"

module ModelSupport
  include ::UserSupport

  UserPrefix = 'g-ttuser-'
  UserDomain = 'testing.com'

  def seed_database
    Rails.logger.info 'NOT Starting seed setup'
    SeedSupport.setup
  end

  def db_name
    "fpa_test#{ENV['TEST_ENV_NUMBER']}"
  end

  def gen_username(r)
    "#{UserPrefix}#{r}@#{UserDomain}"
  end

  def pick_one_from(objs)
    objs[rand objs.length]
  end

  def create_user(r = nil, extra = '', opt = {})
    r ||= Time.new.to_f.to_s
    good_email = gen_username("#{r}-#{extra}-")

    admin, = create_admin
    user = User.create! email: good_email, current_admin: admin, first_name: "fn#{r}", last_name: "ln#{r}"

    # Save a new password, as required to handle temp passwords
    user = User.find(user.id)
    user.current_admin = admin
    good_password = user.generate_password
    user.otp_required_for_login = true
    user.new_two_factor_auth_code = false
    user.save!

    # # Can't reload, as that doesn't clear non-db attributes
    user = User.find(user.id)

    app_type = Admin::AppType.active.first
    raise 'No active app type!' unless app_type

    unless opt[:no_app_type_setup]
      Admin::UserAccessControl.create! user: user, app_type: app_type, access: :read, resource_type: :general, resource_name: :app_type, current_admin: admin
    end

    # Set a default app_type to use to allow non-interactive tests to continue
    user.app_type = app_type
    user.save!

    if opt[:create_master]
      Admin::UserAccessControl.create! app_type_id: app_type.id, access: :read, resource_type: :general, resource_name: :create_master, current_admin: @admin, user: user
    end
    @user = user
    let_user_create :player_contacts

    [user, good_password]
  end

  def self.create_admin(r = nil)
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
    admin.otp_secret = Admin.generate_otp_secret
    admin.otp_required_for_login = true
    admin.new_two_factor_auth_code = false
    admin.save!

    # # Can't reload, as that doesn't clear non-db attributes
    admin = Admin.find(admin.id)
    [admin, good_admin_password]
  end

  def create_admin(r = nil)
    admin, good_admin_password = ModelSupport.create_admin(r)
    @admin = admin
    [admin, good_admin_password]
  end

  def create_user_role(role_name, user: nil, app_type: nil)
    user ||= @user
    app_type ||= user.app_type
    Admin::UserRole.create! current_admin: @admin, app_type: app_type, role_name: role_name, user: user
  end

  def create_app_type(name: nil, label: nil)
    Admin::AppType.create! current_admin: @admin, name: name, label: label
  end

  def let_user_create_player_infos(in_app_type: nil)
    let_user_create :player_infos, in_app_type: in_app_type
  end

  def let_user_create_player_contacts(in_app_type: nil)
    let_user_create :player_contacts, in_app_type: in_app_type
  end

  def let_user_create(resource_name, in_app_type: nil)
    res = @user.has_access_to? :access, :table, resource_name
    if res && res.user_id == @user.id
      res.disabled = true
      res.current_admin = @admin
      res.save!
      # else
    end

    in_app_type ||= @user.app_type
    if in_app_type
      Admin::UserAccessControl.create! current_admin: @admin, app_type: in_app_type, user: @user, access: :create, resource_type: :table, resource_name: resource_name
    end
  end

  def add_app_config(app_type, name, value, user: nil, role_name: nil)
    @admin ||= create_admin

    cond = { name: name }
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

  # Force a database seed at config time, to avoid issues later
  SeedSupport.setup
end
