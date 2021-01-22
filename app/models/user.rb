# frozen_string_literal: true

# A Devise user (there are scopes for user and admin in Devise).
# The core functionality for authentication (password, MFA and token), and associations
# with authorization models are handled through this model.
class User < ActiveRecord::Base
  include AdminHandler
  include StandardAuthentication

  acts_as_token_authenticatable

  # A configuration allows two factor authentication to be disabled for the app server
  if two_factor_auth_disabled
    devise :database_authenticatable, :trackable, :timeoutable, :lockable, :validatable
  else
    devise :trackable, :timeoutable, :lockable, :validatable, :two_factor_authenticatable,
           otp_secret_encryption_key: otp_enc_key
  end

  belongs_to :admin
  has_one :contact_info, class_name: 'Users::ContactInfo', foreign_key: :user_id

  has_many :user_access_controls, autosave: true, class_name: 'Admin::UserAccessControl'
  belongs_to :app_type, class_name: 'Admin::AppType', optional: true
  # Enforce use of app_type when getting user_roles, to prevent leakage of same named user roles across apps
  has_many :user_roles,
           ->(user) { user_app_type(user) },
           autosave: true, class_name: 'Admin::UserRole'

  default_scope -> { order email: :asc }
  scope :not_template, -> { where('email NOT LIKE ?', Settings::TemplateUserEmailPattern) }
  before_save :set_app_type
  before_save :set_access_levels

  #
  # The template user is assigned to newly created roles to ensure they are exported
  # in an app type export, even if there are no other matching users on the target server
  def self.template_user
    where(email: Settings::TemplateUserEmail).first
  end

  #
  # The batch_user is the User instance for the user specified in Settings::AdminEmail
  def self.batch_user
    # Use the admin email as the user - this assumes that the equivalent user has been set up for automated use
    where(email: Settings::AdminEmail).first
  end

  #
  # Make the batch user usable by ensuring it has the desired app type set as the current app
  # @param [Admin::AppType | Integer] with_app - the app type (or id) to use the batch user with
  # @return [User] - the batch user instance
  def self.use_batch_user(with_app)
    bu = batch_user
    return unless bu

    bu.update(app_type: with_app)
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
  # Placeholder for user preference object, which is current hard coded,
  # but will become an editable model in the future
  # @return [UserPreference]
  def user_preference
    UserPreference.new
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

  #
  # Simple authorizations that say what type of general actions a user can perform in this app type.
  # In previous versions, this was managed by the UserAuthorization class. Since
  # we now have App Types and user access controls, this has been combined.
  # The can? method defaults to resource_type :general for this reason, although
  # can be used for checking access on other resource types if desired
  # example: user.can? :create_master
  # @param [Symbol] auth - the resource name to check against
  # @param [Symbol] resource_type - defaults to :general - one of Admin::UserAccessControl.resource_types
  def can?(auth, resource_type = :general)
    has_access_to? :access, resource_type, auth
  end

  #
  # Preferred mechanism for checking access controls for a user
  # Memoizes the result in param @has_access_to, which gets cleared
  # if a user access control is added or updated while this instance is present.
  # Note: with_options usage is vague and should be avoided
  # @param [Symbol] perform - the action to be performed such as :access or :create
  # @param [Symbol] resource_type - one of Admin::UserAccessControl.resource_types
  # @param [Symbol] named - the resource name to check against
  # @param [unknown] with_options - do not use
  # @param [Admin::AppType | Integer] alt_app_type_id - by default check against user's current app type,
  #                                   otherwise use this alternative
  # @param [True | nil] force_reset - force reset of memoization to reevaluate
  # @return [Admin::UserAccessControl | nil]
  def has_access_to?(perform, resource_type, named, with_options = nil, alt_app_type_id: nil, force_reset: nil)
    @has_access_to ||= {}

    clear_has_access_to! if user_access_controls_updated?
    clear_role_names! if user_roles_updated?

    key = "#{perform}-#{resource_type}-#{named}-#{with_options}-#{alt_app_type_id || app_type_id}"
    return @has_access_to[key] if @has_access_to.key?(key) && !force_reset

    @has_access_to[key] =
      Admin::UserAccessControl.access_for? self,
                                           perform,
                                           resource_type,
                                           named,
                                           with_options,
                                           alt_app_type_id: alt_app_type_id
  end

  #
  # Is there a later user access control record (updated at or created at) than
  # the one we last saw within this instance. Handles automatic memo clearing to
  # support changes to user access controls in spec tests
  def user_access_controls_updated?
    if @latest_user_access_control != Admin::UserAccessControl.latest_update
      @latest_user_access_control = Admin::UserAccessControl.latest_update
    else
      false
    end
  end

  def clear_has_access_to!
    @latest_user_access_control = Admin::UserAccessControl.latest_update
    @has_access_to = {}
  end

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

  #
  # The full list of active role names for the current app_type
  # @return [Array{String}]
  def role_names
    clear_role_names! if @latest_user_role != Admin::UserRole.latest_update

    @role_names ||= user_roles.active.pluck(:role_name)
  end

  #
  # Is there a later user role record (updated at or created at) than
  # the one we last saw within this instance. Handles automatic memo clearing to
  # support changes to user roles in spec tests
  def user_roles_updated?
    @latest_user_role != Admin::UserRole.latest_update
  end

  def clear_role_names!
    @latest_user_role = Admin::UserRole.latest_update
    @role_names = nil
    # Updated roles also lead to has_access_to evaluations requiring refresh
    clear_has_access_to!
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

  # Ensure that access controls are appropriately created and disabled
  # Disable access controls when a user is disabled.
  # Do not re-enable automatically, since this could provide undesired access being granted
  def set_access_levels
    user_access_controls.each(&:disable!) if persisted? && disabled
  end

  # Ensure that the app type being set for the user is valid and accessible to him
  def set_app_type
    self.app_type_id = nil if app_type_id && !app_type_valid?
  end
end
