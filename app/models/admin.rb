class Admin < ActiveRecord::Base

  include ActionLogging

  devise :database_authenticatable, :trackable, :timeoutable, :lockable
  before_update :prevent_email_change
  
  
  def timeout_in
    return 5.minutes if Rails.env.production?
    
    30.minutes
  end

  def prevent_email_change 
    if email_changed? && self.persisted?
      errors.add(:email, "change not allowed!")
    end
  end

  def active_for_authentication?    
    super and self.disabled != true
  end
  
end
