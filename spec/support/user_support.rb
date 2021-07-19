# frozen_string_literal: true

module UserSupport
  UserPrefix = 'g-ttuser-'
  UserDomain = 'testing.com'

  def create_user(part = nil, extra = '', opt = {})
    start_time = Time.now

    part ||= Time.new.to_f.to_s
    good_email = opt[:email] || gen_username("#{part}-#{extra}-")

    admin, = @admin || create_admin
    user = User.create! email: good_email, current_admin: admin, first_name: "fn#{part}", last_name: "ln#{part}"

    # Save a new password, as required to handle temp passwords
    user = User.find(user.id)
    user.current_admin = admin
    good_password = user.generate_password
    user.otp_required_for_login = true
    user.new_two_factor_auth_code = false
    user.save!
    @user_authentication_token = user.authentication_token

    # # Can't reload, as that doesn't clear non-db attributes
    user = User.find(user.id)

    app_type = opt[:app_type] || @user&.app_type || Admin::AppType.active.first
    raise 'No active app type!' unless app_type

    unless opt[:no_app_type_setup]
      Admin::UserAccessControl.create! user: user, app_type: app_type, access: :read, resource_type: :general,
                                       resource_name: :app_type, current_admin: admin
    end

    # Set a default app_type to use to allow non-interactive tests to continue
    if user.app_type != app_type
      user.app_type = app_type
      user.save!
    end

    if opt[:create_master]
      Admin::UserAccessControl.create! app_type: app_type, access: :read, resource_type: :general,
                                       resource_name: :create_master, current_admin: @admin, user: user
    end
    @user = user
    let_user_create :player_contacts

    delay = Time.now - start_time
    puts "create_user took #{delay} seconds" if delay > 2.seconds

    [user, good_password]
  end

  def self.create_admin(part = nil)
    a = Admin.order(id: :desc).first
    unless part
      part = 1
      part = a.id + 1 if a
    end
    good_admin_email = "e-testadmin-tester#{part}@testing.com"

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

  def create_admin(part = nil)
    admin, good_admin_password = UserSupport.create_admin(part)
    @admin = admin
    [admin, good_admin_password]
  end

  def create_user_role(role_name, user: nil, app_type: nil)
    user ||= @user
    app_type ||= user.app_type
    Admin::UserRole.create! current_admin: @admin, app_type: app_type, role_name: role_name, user: user
  end

  def gen_username(part)
    "#{UserPrefix}#{part}@#{UserDomain}"
  end

  def enable_user_app_access(app_name, user = nil)
    @user.app_type = Admin::AppType.where(name: app_name).first
    setup_access :app_type, resource_type: :general, access: :read, user: user
  end

  def setup_access(resource_name = nil, resource_type: :table, access: :create, user: nil)
    return if @path_prefix == '/admin'

    resource_name ||= objects_symbol

    app_type = @user.app_type

    uac = Admin::UserAccessControl.where(app_type: app_type, resource_type: resource_type, resource_name: resource_name)
    uac = uac.where(user: user) if user

    uac.active.update_all(disabled: true) if uac.active.length > 1
    uac = uac.active.first || uac.first
    if uac
      uac.access = access
      uac.disabled = false
      uac.current_admin = auto_admin
      uac.save!
    else
      uac = Admin::UserAccessControl.create! app_type: app_type, access: access, resource_type: resource_type,
                                             resource_name: resource_name, user: user, current_admin: auto_admin
    end

    if user && access && resource_name != :app_type
      check_access = (access == :see_presence ? access : :access)
      res = user.has_access_to?(check_access, resource_type, resource_name)
      expect(res).to be_truthy,
                     "Newly created User Access Control not working as expected: #{check_access}, #{resource_type}, #{resource_name}"
    end

    uac
  rescue StandardError
    Rails.logger.debug "Failed to create access for #{resource_name}"
  end

  def add_user_to_role(role_name, for_user: nil)
    for_user ||= @user
    Admin::UserRole.add_to_role for_user, for_user.app_type, role_name, @admin
  end

  def remove_user_from_role(role_name, for_user: nil)
    for_user ||= @user
    Admin::UserRole.remove_from_role for_user, for_user.app_type, role_name, @admin
  end

  def add_user_config(config_name, config_value, for_user: nil)
    for_user ||= @user
    Admin::AppConfiguration.add_user_config for_user, for_user.app_type, config_name, config_value, @admin
  end

  def remove_user_config(config_name, for_user: nil)
    for_user ||= @user
    Admin::AppConfiguration.remove_user_config for_user, for_user.app_type, config_name, @admin
  end

  def let_user_create_player_infos(in_app_type: nil)
    let_user_create :player_infos, in_app_type: in_app_type
  end

  def let_user_create_player_contacts(in_app_type: nil)
    let_user_create :player_contacts, in_app_type: in_app_type
  end

  def let_user_create(resource_name, in_app_type: nil, alt_user: nil)
    user = alt_user || @user
    res = user.has_access_to? :access, :table, resource_name
    if res && res.user_id == user.id
      res.disabled = true
      res.current_admin = @admin
      res.save!
    end

    in_app_type ||= user.app_type
    return unless in_app_type

    Admin::UserAccessControl.create! current_admin: @admin, app_type: in_app_type, user: user, access: :create,
                                     resource_type: :table, resource_name: resource_name

    # expect(user.has_access_to?(:create, :table, resource_name)).to be_truthy
  end
end
