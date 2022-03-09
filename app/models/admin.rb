# frozen_string_literal: true

class Admin < ActiveRecord::Base
  @admin_optional = true

  include AdminHandler
  include RegistrationHandler
  include StandardAuthentication

  # A configuration allows two factor authentication to be disabled for the app server
  if two_factor_auth_disabled
    devise :database_authenticatable, :trackable, :timeoutable, :lockable, :validatable
  else
    devise :trackable, :timeoutable, :lockable, :validatable, :two_factor_authenticatable,
           otp_secret_encryption_key: otp_enc_key
  end

  before_validation :prevent_email_change, on: :update
  before_validation :prevent_reenabling_admin, on: :update
  before_validation :prevent_not_in_setup_script_or_allowed, on: :create

  validate :only_allow_disable
  after_save :unlock_account, on: :update

  def enabled?
    !disabled
  end

  def timeout_in
    Settings::AdminTimeout
  end

  # Standard Devise callback to allow accounts to be disabled
  def active_for_authentication?
    super && !disabled
  end

  # Standard Devise callback to tell user that an account has been disabled
  def inactive_message
    !disabled ? super : :account_has_been_disabled
  end

  # Get the user that corresponds to this admin
  # @return [User | nil]
  def matching_user
    User.active.where(email: email).first
  end

  # Get the current app type for the user that corresponds to this admin
  # @return [Admin::AppType | nil]
  def matching_user_app_type
    @matching_user_app_type || matching_user&.app_type
  end

  #
  # Get an admin that matches the current user's email, if one exists
  # @param [User] user
  # @return [Admin]
  def self.for_user(user)
    active.where(email: user.email).first
  end

  # Set the matching user's app type forcefully, to override the current value
  # This facilitates app type importing and automatic migrations
  attr_writer :matching_user_app_type

  # Simple way to ensure that this is not being run from inside Passenger
  def in_setup_script
    ENV['FPHS_ADMIN_SETUP'] == 'yes'
  end

  def to_s
    email
  end

  def authentication_token=(_); end

  def authentication_token; end

  # method provided by devise database_authenticable module.
  def send_password_change_notification
    # do not notify the admins for now
  end

  protected

  def unlock_account
    if access_locked? && saved_change_to_encrypted_password?
      self.locked_at = nil
      self.failed_attempts = nil
    end
  end

  def prevent_email_change
    errors.add(:email, 'change not allowed!') if id == current_admin&.id && email_changed? && persisted?
  end

  def prevent_reenabling_admin
    if disabled_changed? && persisted? && disabled != true && disabled_was == true && !in_setup_script
      errors.add(:disabled, 'change not allowed!')
    end
  end

  def prevent_not_in_setup_script_or_allowed
    errors.add(:admin, 'can only create admins in console') unless in_setup_script || Settings::AllowAdminsToManageAdmins
  end

  def only_allow_disable
    return if in_setup_script
    return unless !disabled && disabled_changed? && !disabled_was != true

    errors.add(:admin, 'can not re-enable administrators')
  end
end
