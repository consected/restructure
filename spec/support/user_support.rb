# frozen_string_literal: true

module UserSupport
  UserPrefix = 'g-ttuser-'
  UserDomain = 'testing.com'

  def create_user(part = nil, extra = '', opt = {})
    start_time = Time.now
    if part.is_a? Hash
      opt = part
      part = nil
    end
    part ||= SecureRandom.hex(10)
    good_email = opt[:email] || gen_username("#{part}-#{extra}-")
    admin, = @admin || create_admin

    attr = {
      email: good_email, current_admin: admin, first_name: "fn#{part}", last_name: "ln#{part}",
      password: Devise.friendly_token(30)
    }

    good_password = attr[:password] if opt[:with_password]

    user = User.create! attr

    # Save a new password, as required to handle temp passwords
    unless opt[:no_password_change]
      user = User.find(user.id)
      user.current_admin = admin
      good_password = user.generate_password
      if Settings::TwoFactorAuthDisabledForUser
        user.otp_required_for_login = false
        user.new_two_factor_auth_code = false
      else
        user.otp_required_for_login = true
        user.new_two_factor_auth_code = false
      end
      user.save!
    end

    if Settings::TwoFactorAuthDisabledForUser
      user.otp_required_for_login = false
      user.new_two_factor_auth_code = false
    else
      user.otp_required_for_login = true
      user.new_two_factor_auth_code = false
    end

    # Set confirmed for system tests
    user.confirmed_at ||= Time.now if respond_to?(:page) && !opt[:not_confirmed]

    user.save!
    expect(user.two_factor_setup_required?).to be_falsey

    @user_authentication_token = user.authentication_token

    # # Can't reload, as that doesn't clear non-db attributes
    user = User.find(user.id)

    app_type = opt[:app_type] || @user&.app_type || Admin::AppType.active.first
    raise 'No active app type!' unless app_type

    unless opt[:no_app_type_setup]
      Admin::UserAccessControl.create! user:, app_type:, access: :read, resource_type: :general,
                                       resource_name: :app_type, current_admin: admin
    end

    # Set a default app_type to use to allow non-interactive tests to continue
    if user.app_type != app_type
      user.app_type = app_type
      user.save!
    end

    if opt[:create_master]
      Admin::UserAccessControl.create! app_type:, access: :read, resource_type: :general,
                                       resource_name: :create_master, current_admin: @admin, user:
    end
    @user = user
    @good_email = user.email
    @good_password = good_password
    let_user_create :player_contacts

    delay = Time.now - start_time
    puts "create_user took #{delay} seconds" if delay > 2.seconds

    [user, good_password]
  end

  def grant_user_app_access(user, app_type = nil)
    app_type = app_type || user&.app_type || Admin::AppType.active.first
    raise 'No app type set' unless app_type

    Admin::UserAccessControl.create app_type:, access: :read, resource_type: :general,
                                    resource_name: :app_type, current_admin: @admin, user:
  end

  def self.create_admin(part = nil, with_matching_user: false)
    a = Admin.order(id: :desc).first

    part ||= SecureRandom.hex(10)
    good_admin_email = "e-testadmin-tester#{part}@testing.com"

    admin = Admin.find_or_initialize_by(email: good_admin_email)
    admin.disabled = false
    admin.save! if admin.new_record? || admin.changed?
    # Save a new password, as required to handle temp passwords
    admin = Admin.find(admin.id)
    good_admin_password = admin.generate_password

    # Only set up 2FA if it's not disabled
    unless Admin.two_factor_auth_disabled
      admin.otp_secret = Admin.generate_otp_secret
      admin.otp_required_for_login = true
      admin.new_two_factor_auth_code = false
    end

    admin.save!

    # # Can't reload, as that doesn't clear non-db attributes
    admin = Admin.find(admin.id)

    if with_matching_user

      attr = {
        email: admin.email, current_admin: admin, first_name: admin.first_name, last_name: admin.last_name
      }

      good_password = attr[:password] = Devise.friendly_token(30)

      user = User.create! attr
      raise 'Not a user' unless user.is_a?(User)
      raise "User email #{user.email} does not match admin email #{admin.email}" unless user.email == admin.email
    end

    [admin, good_admin_password]
  end

  def create_admin(part = nil, with_matching_user: false)
    admin, good_admin_password = UserSupport.create_admin(part)
    @admin = admin

    if with_matching_user
      user, good_user_password = create_user(nil, nil, email: admin.email)
      expect(user).to be_a User
      expect(user.email).to eq admin.email
    end

    [admin, good_admin_password]
  end

  def create_user_role(role_name, user: nil, app_type: nil)
    user ||= @user
    app_type ||= user.app_type
    Admin::UserRole.create! current_admin: @admin, app_type:, role_name:, user:
  end

  def gen_username(part)
    "#{UserPrefix}#{part}@#{UserDomain}"
  end

  #
  # Enable access to an app type for a user (or default @user)
  # @param [String | Integer | Admin::AppType] app_type - name, id or AppType
  # @param [User] user - optional user or default will be @user
  # @return [Admin::UserAccessControl]
  def enable_user_app_access(app_type, user = nil)
    user ||= @user

    case app_type
    when String
      app_type = Admin::AppType.where(name: app_type).first
    when Integer
      app_type = Admin::AppType.find(app_type)
    end

    res = user.has_access_to?(:access, :general, :app_type, alt_app_type_id: app_type.id)
    return res if res

    res = setup_access(:app_type, resource_type: :general, access: :read, user:, app_type:)
    expect(user.has_access_to?(:access, :general, :app_type, alt_app_type_id: app_type.id))
    res
  end

  def setup_access(resource_name = nil, resource_type: :table, access: :create, user: nil, app_type: nil)
    return if @path_prefix == '/admin'

    resource_name ||= objects_symbol

    unless resource_name
      Rails.logger.warn "No resource name for #{resource_type} - #{self.class}"
      Rails.logger.warn ExceptionExtensions.short_string_backtrace(caller)

      return
    end

    app_type ||= @user.app_type

    uac = Admin::UserAccessControl.where(app_type:, resource_type:, resource_name:, role_name: [nil, ''])
    uac = if user
            uac.where(user:)
          else
            uac.where(user_id: nil)
          end

    uac.active.update_all(disabled: true) if uac.active.length > 1
    uac = uac.active.first || uac.first
    if uac
      disabled = uac.user&.disabled # The UAC must be disabled if the user is disabled
      uac.access = access
      uac.disabled = disabled
      uac.current_admin = auto_admin
      uac.updated_at = DateTime.now
      uac.save!
    else
      disabled = user&.disabled # The UAC must be disabled if the user is disabled
      uac = Admin::UserAccessControl.create! app_type:, access:, resource_type:,
                                             resource_name:, user:, current_admin: auto_admin,
                                             disabled: disabled
    end

    if user && access && resource_name != :app_type
      check_access = (access == :see_presence ? access : :access)
      res = user.has_access_to?(check_access, resource_type, resource_name)
      expect(res).to be_truthy,
                     "Newly created User Access Control not working as expected: #{check_access}, #{resource_type}, #{resource_name}"
    end

    uac
  rescue StandardError => e
    puts "Failed to create access for #{resource_name}: #{e}"
    puts "resource_name needs to be one of:\n#{Admin::UserAccessControl.resource_names_for(resource_type.to_sym)}"
    puts "#{e}\n#{e.short_string_backtrace}"
    Rails.logger.info "Failed to create access for #{resource_name}"
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
    let_user_create :player_infos, in_app_type:
  end

  def let_user_create_player_contacts(in_app_type: nil)
    let_user_create :player_contacts, in_app_type:
  end

  def let_user_create(resource_name, in_app_type: nil, alt_user: nil)
    user = alt_user || @user
    res = user.has_access_to? :access, :table, resource_name
    if res && res.user_id == user.id
      # Find it, as the object is not actually a database record
      res = Admin::UserAccessControl.find(res.id)
      res.disabled = true
      res.current_admin = @admin
      res.save!
    end

    in_app_type ||= user.app_type
    return unless in_app_type

    Admin::UserAccessControl.create! current_admin: @admin, app_type: in_app_type, user:, access: :create,
                                     resource_type: :table, resource_name:

    # expect(user.has_access_to?(:create, :table, resource_name)).to be_truthy
  end

  def revoke_user_create(resource_name, in_app_type: nil, alt_user: nil)
    user = alt_user || @user
    in_app_type ||= user.app_type
    res = user.has_access_to? :access, :table, resource_name, alt_app_type_id: in_app_type
    res = Admin::UserAccessControl.find(res.id)
    return unless res && res.user_id == user.id

    res.disabled = true
    res.current_admin = @admin
    res.save!
  end

  def validate_setup
    user = User.active.find_by(email: @good_email&.downcase)
    expect(user).to be_a User
    expect(user.id).to equal @user.id
    validate_scantron_setup
    validate_update_protocol_setup
  end

  def validate_update_protocol_setup
    expect(Classification::ProtocolEvent.active.reload.find_by(name: 'created player info')).not_to be nil
    expect(Classification::ProtocolEvent.active.reload.find_by(name: 'updated player info')).not_to be nil
    expect(Classification::ProtocolEvent.active.reload.find_by(name: 'created player contact')).not_to be nil
    expect(Classification::ProtocolEvent.active.reload.find_by(name: 'updated player contact')).not_to be nil
  end

  def validate_scantron_setup
    return if defined? Scantron

    puts 'Scantron was not defined!'
    Rails.logger.warn 'Scantron was not defined!'
    seed_database
    return if defined? Scantron

    m = Resources::Models.find_by(resource_name: 'scantrons')
    r = ExternalIdentifier.active.where(name: 'scantron').count
    Rails.logger.warn m
    Rails.logger.warn r
    raise FphsException, "Scantron is still not defined, even after seeding: \n#{m}\n#{r}"
  end
end
