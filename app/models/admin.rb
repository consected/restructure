class Admin < ActiveRecord::Base

  include ActionLogging

  devise :database_authenticatable, :trackable, :timeoutable, :lockable
  before_validation :prevent_email_change, on: :update
  before_validation :prevent_reenabling_admin, on: :update
  
  def timeout_in
    return 5.minutes if Rails.env.production?
    
    30.minutes
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
  
  def disable!
    self.disabled = true
    self.save
  end

  def active_for_authentication?    
    super && self.disabled != true
  end

  def inactive_message
    !self.disabled  ? super : :account_has_been_disabled    
  end
      
end
