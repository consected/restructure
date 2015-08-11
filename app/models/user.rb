class User < ActiveRecord::Base
  
  include ActionLogging
  include AdminHandler
  
  devise :database_authenticatable, :trackable, :timeoutable, :lockable, :validatable
  
  belongs_to :admin
  
  before_validation :generate_password, on: :create    
  validates_uniqueness_of :email, :case_sensitive => false, :allow_blank => false, :if => :email_changed?
  validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => false, :if => :email_changed?
  
  default_scope -> {order email: :asc}
  
  
  def force_password_reset
    unlock_access!
    generate_password
  end
  
  def new_password
    @new_password
  end
  
  def disable!
    self.disabled = true
    self.save
  end

  
  def timeout_in  
    Settings::UserTimeout
  end

  
  def active_for_authentication?
    super && !self.disabled
  end
  
  def inactive_message
    !self.disabled  ? super : :account_has_been_disabled    
  end
    
protected

  # Generate a random password for a new user
  # Return the plain text password in the new_password attribute
  def generate_password
    generated_password = Devise.friendly_token.first(12)
    @new_password = generated_password    
    self.password = generated_password
  end
  
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

end
