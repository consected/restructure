# frozen_string_literal: true

# A Devise user (there are scopes for user and admin in Devise).
# The core functionality for authentication (password, MFA and token), and associations
# with authorization models are handled through this model.
class User < ActiveRecord::Base
  include AdminHandler
  include RegistrationHandler
  include StandardAuthentication
  include UserAccessHandler
  include UserRoleHandler

  acts_as_token_authenticatable

  supported_modules = %i[trackable timeoutable lockable validatable]
  supported_modules += %i[registerable confirmable recoverable] if Settings::AllowUsersToRegister
  if two_factor_auth_disabled
    supported_modules << :database_authenticatable
  else
    supported_modules += [:two_factor_authenticatable, { otp_secret_encryption_key: otp_enc_key }]
  end

  devise(*supported_modules)

  belongs_to :admin
  has_one :contact_info, class_name: 'Users::ContactInfo', foreign_key: :user_id
  has_one :user_preference, autosave: true, inverse_of: :user

  belongs_to :app_type, class_name: 'Admin::AppType', optional: true

  attr_accessor :terms_of_use
  attr_accessor :client_localized

  default_scope -> { order email: :asc }
  scope :not_template, -> { where('email NOT LIKE ?', Settings::TemplateUserEmailPatternForSQL) }

  before_validation :set_current_user_on_user_preferences
  before_create :build_user_preference_on_create
  before_save :set_app_type

  validates :first_name,
            presence: {
              if: -> { required_for_self_registration? }
            },
            length: {
              maximum: 50,
              allow_nil: true
            }

  validates :last_name,
            presence: {
              if: -> { required_for_self_registration? }
            },
            length: {
              maximum: 50,
              allow_nil: true
            }

  # country_code and terms_of_use are enforced if user self registration is enabled
  validates :country_code,
            presence: {
              if: -> { required_for_self_registration? },
              message: 'must be selected'
            },
            length: {
              is: 2,
              allow_blank: true,
              message: ApplicationHelper::DoNotDisplayErrorMessage
            }

  validates :terms_of_use,
            acceptance: {
              if: -> { required_for_self_registration? }
            }

  # The validations error is not shown to the user since the terms_of_use acceptance error is sufficient.
  # See notes app/views/devise/shared/_error_messages.html.erb
  validates :terms_of_use_accepted,
            presence: {
              if: -> { required_for_self_registration? },
              message: ApplicationHelper::DoNotDisplayErrorMessage
            }

  validate :prevent_disable_template_user

  #
  # The template user is assigned to newly created roles to ensure they are exported
  # in an app type export, even if there are no other matching users on the target server
  def self.template_user
    res = find_by(email: Settings::TemplateUserEmail)

    Rails.logger.error "template_user #{Settings::TemplateUserEmail} does not exist" unless res
    res
  end

  # Get the admin that corresponds to this user
  # @return [Admin | nil]
  def matching_admin
    Admin.active.where(email: email).first
  end

  #
  # The batch_user is the User instance for the user specified in Settings::BatchUserEmail
  def self.batch_user
    e = Settings::BatchUserEmail
    # Use the admin email as the user - this assumes that the equivalent user has been set up for automated use
    find_by(email: e)
  end

  #
  # Make the batch user usable by ensuring it has the desired app type set as the current app
  # @param [Admin::AppType | Integer] with_app - the app type (or id) to use the batch user with
  # @return [User] - the batch user instance
  def self.use_batch_user(with_app)
    bu = batch_user
    return unless bu

    raise FphsException, 'use_batch_user must specify an app' unless with_app

    with_app = with_app.id if with_app.is_a? Admin::AppType
    bu.update(app_type_id: with_app)
    bu
  end

  #
  # Return a list of Hash results for active users
  # each record being {id: id, value: id, name: email}
  # Used by the DefinitionsController
  def self.active_id_name_list(_filter = nil)
    active.map { |u| { id: u.id, value: u.id, name: u.email } }
  end

  #
  # Return a list of array [user email, id] pairs
  # where the user email has the string "[disabled]" appended
  # if the user record is disabled
  # Used by editable reports
  def self.all_name_value_enable_flagged(type_filter = nil)
    if type_filter && type_filter[:disabled] == false
      res = active
      type_filter.delete :disabled
    else
      res = all
    end

    res.map { |u| ["#{u.email} #{u.disabled ? '[disabled]' : ''}", u.id] }
  end

  #
  # The remaining timeout time for a user session, based on the
  # app configuration, or the default for the server
  # @return [Integer] number of minutes remaining
  def timeout_in
    return @timeout_in if @timeout_in

    ust = Admin::AppConfiguration.value_for(:user_session_timeout)
    @timeout_in = if ust.blank?
                    Settings::UserTimeout
                  else
                    ust.to_i.minutes
                  end
  end

  # Standard Devise callback to allow accounts to be disabled
  def active_for_authentication?
    super && !disabled
  end

  # Standard Devise callback to tell user that an account has been disabled
  def inactive_message
    !disabled ? super : :account_has_been_disabled
  end

  # By default, the user is redirected to the login page after registration.
  # Uncomment if the path needs to change.
  # def after_sign_up_path_for(resource)
  #   super
  # end
  #
  # Simply return the email for the user if a string is requested
  # @return [String]
  def to_s
    email
  end

  #
  # Validate the user's current app type, ensuring that access controls grant access to it
  # @return [Boolean]
  def app_type_valid?
    app_type_id.in? accessible_app_type_ids
  end

  # App Types (ids) this user can access.
  # This is *cached*, so is preferable to use in most cases
  # @return [Array{Integer}]
  def accessible_app_type_ids
    Admin::AppType.all_ids_available_to(self)
  end

  #
  # App Types this user can access
  # @return [Array{Admin::AppType}]
  def accessible_app_types
    Admin::AppType.all_available_to(self)
  end

  # Send user confirmation email if self registering
  # method provided by devise confirmable module; Override so job notifications can be executed
  def send_on_create_confirmation_instructions
    return unless required_for_self_registration?

    generate_confirmation_token! unless @raw_confirmation_token
    Users::Confirmations.notify self
  end

  # method provided by devise recoverable module; Override so job notifications can be executed
  def send_reset_password_instructions
    return if a_template_or_batch_user? || !allow_users_to_register?

    if do_not_email
      raise FphsGeneralError,
            "User profile set to 'no email' - contact an administrator to reset the password"
    end

    token = set_reset_password_token
    options = { reset_password_hash: token }
    Users::PasswordRecovery.notify self, options
    token
  end

  def resend_confirmation_instructions
    return if a_template_or_batch_user? || !allow_users_to_register?

    generate_confirmation_token! unless @raw_confirmation_token
    Users::Confirmations.notify self
  end

  # method provided by devise database_authenticable module; Override so job notifications can be executed
  def send_password_change_notification
    return if a_template_or_batch_user? || !allow_users_to_register? || do_not_email

    Users::PasswordChanged.notify self
  end

  protected

  # Override included functionality that ensures an administrator has been set
  # Limit it to check for an administrator when email or disabled flag change
  # This is required since user tracking and password updates are allowed in
  # standard operation, but the user can not reset a disabled flag or their email address
  def ensure_admin_set
    if !admin_set? && !persisted?
      errors.add(:admin, 'account must be used to create user')
      return false
    end

    if email_changed? && persisted? && !admin_set?
      errors.add(:email, 'change not allowed!')
      return false
    end

    if disabled_changed? && persisted? && !admin_set?
      errors.add(:disabled, 'change not allowed! (no admin set?)')
      return false
    end

    true
  end

  # Ensure that the app type being set for the user is valid and accessible to him
  def set_app_type
    self.app_type_id = nil if app_type_id && !app_type_valid?
  end

  def password_required?
    return false if a_template_or_batch_user?

    super
  end

  private

  def set_current_user_on_user_preferences
    user_preference&.current_user = self
  end

  def build_user_preference_on_create
    build_user_preference({ current_user: self }) unless a_template_or_batch_user?
  end

  def prevent_disable_template_user
    return unless email == Settings::TemplateUserEmail && disabled && disabled_changed?

    raise FphsException, "Do not attempt to disable the template user: #{email}"
  end
end
