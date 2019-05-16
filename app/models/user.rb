class User < ActiveRecord::Base

  include AdminHandler
  include StandardAuthentication

  acts_as_token_authenticatable

  devise :trackable, :timeoutable, :lockable, :validatable, :two_factor_authenticatable,
         :otp_secret_encryption_key => otp_enc_key

  belongs_to :admin
  has_one :contact_info, class_name: 'Users::ContactInfo', foreign_key: :user_id

  has_many :user_access_controls, autosave: true, class_name: "Admin::UserAccessControl"
  belongs_to :app_type, class_name: "Admin::AppType"
  # Enforce use of app_type when getting user_roles, to prevent leakage of same named user roles across apps
  has_many :user_roles, ->(user) { user_app_type(user)}, autosave: true, class_name: "Admin::UserRole"
  # has_many :user_roles, autosave: true, class_name: "Admin::UserRole"

  default_scope -> {order email: :asc}

  before_save :set_app_type
  before_save :set_access_levels


  def self.active_id_name_list filter=nil
    active.map {|u| {id: u.id, value: u.id, name: u.email} }
  end

  def self.all_name_value_enable_flagged type_filter=nil

    if type_filter && type_filter[:disabled] == false
      res = active
      type_filter.delete :disabled
    else
      res = all
    end

    res.map{|u| ["#{u.email} #{u.disabled ? '[disabled]' : ''}", u.id]  }
  end

  def user_preference
    UserPreference.new
  end

  def timeout_in
    ust = Admin::AppConfiguration.value_for(:user_session_timeout)
    if ust.blank?
       Settings::UserTimeout
    else
      ust.to_i.minutes
    end
  end

  # Standard Devise callback to allow accounts to be disabled
  def active_for_authentication?
    super && !self.disabled
  end

  # Standard Devise callback to tell user that an account has been disabled
  def inactive_message
    !self.disabled  ? super : :account_has_been_disabled
  end

  # Simple authorizations that say what type of general actions a user can perform in this app type.
  # In previous versions, this was managed by the UserAuthorization class. Since
  # we now have App Types and user access controls, this has been combined.
  # The can? method defaults to resource_type :general for this reason, although
  # can be used for checking access on other resource types if desired
  # example: user.can? :create_master
  def can? auth, resource_type=:general
    self.has_access_to? :access, resource_type, auth
  end

  # Preferred mechanism for checking access controls for a user
  # Note: with_options usage is vague and should be avoided
  def has_access_to? perform, resource_type, named, with_options=nil, alt_app_type_id: nil
    Admin::UserAccessControl.access_for? self, perform, resource_type, named, with_options, alt_app_type_id: alt_app_type_id
  end

  def to_s
    email
  end

  # Validate the user's current app type, ensuring that access controls grant access to it
  # @return [Boolean]
  def app_type_valid?
    app_type.in? Admin::AppType.all_available_to(self)
  end


  protected

    # Override included functionality that ensures an administrator has been set
    # Limit it to check for an administrator when email or disabled flag change
    # This is required since user tracking and password updates are allowed in
    # standard operation, but the user can not reset a disabled flag or their email address
    def ensure_admin_set

      if !admin_set? && !self.persisted?
        errors.add(:admin, "account must be used to create user")
        return false
      end

      if email_changed? && self.persisted? && !admin_set?
        errors.add(:email, "change not allowed!")
        return false
      end

      if disabled_changed? && self.persisted? && !admin_set?
        errors.add(:disabled, "change not allowed! (no admin set?)")
        return false
      end

      true
    end


    # Ensure that access controls are appropriately created and disabled
    def set_access_levels

      # Disable access controls when a user is disabled.
      # Do not re-enable automatically, since this could provide undesired access being granted
      if persisted? && self.disabled
        self.user_access_controls.each {|uac| uac.disable! }
      end
    end

    # Ensure that the app type being set for the user is valid and accessible to him
    def set_app_type
      if app_type_id
        unless app_type_valid?
          self.app_type_id = nil
        end
      end
    end

end
