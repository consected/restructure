class Admin < ActiveRecord::Base

  include ActionLogging

  devise :database_authenticatable, :trackable, :timeoutable, :lockable, :validatable
  
  before_validation :prevent_email_change, on: :update
  before_validation :prevent_reenabling_admin, on: :update
  before_validation :generate_password  
  
  
  def force_password_reset
    unlock_access!
    generate_password
  end
  
  def timeout_in
    return Settings::AdminTimeout
  end

  def new_password
    @new_password
  end
  
  def disable!
    self.disabled = true
    self.save
  end

  def active_for_authentication?
    super && !self.disabled
  end
  
  def inactive_message
    !self.disabled  ? super : :account_has_been_disabled    
  end

protected  

  # Generate a random password for a new administrator
  # Return the plain text password in the new_password attribute
  def generate_password
    generated_password = Devise.friendly_token.first(12)
    @new_password = generated_password    
    self.password = generated_password
  end

  
  def prevent_email_change 
    if email_changed? && self.persisted?
      errors.add(:email, "change not allowed!")
    end
  end
  
  def prevent_reenabling_admin
    if disabled_changed? && self.persisted? && self.disabled != true
      errors.add(:disabled, "change not allowed!")
    end
    
  end
  
end
