class User < ActiveRecord::Base

  include AdminHandler
  include StandardAuthentication

  devise :database_authenticatable, :trackable, :timeoutable, :lockable, :validatable

  belongs_to :admin
  has_many :user_authorizations
  has_many :user_access_controls, autosave: true

  default_scope -> {order email: :asc}

  before_create :set_access_levels

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

  def timeout_in
    ust = AppConfiguration.value_for(:user_session_timeout)
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

  def can? auth
    UserAuthorization.user_can? self, auth
  end

  def has_access_to? perform, resource_type, named, with_options=nil
    UserAccessControl.access_for? self.id, perform, resource_type, named, with_options
  end

  def to_s
    email
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
        errors.add(:disabled, "change not allowed!")
        return false
      end

      true
    end


    # Ensure that access controls are appropriately created and disabled
    def set_access_levels
      if persisted? && self.disabled
        user.access_controls.each {|uac| uac.disable! }
      elsif !persisted?
        UserAccessControl.create_all_for self, current_admin
      end
    end

end
