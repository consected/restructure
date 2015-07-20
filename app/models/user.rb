class User < ActiveRecord::Base
  
  include ActionLogging
 
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :trackable, :timeoutable, :lockable
  validates_uniqueness_of :email, :case_sensitive => false, :allow_blank => true, :if => :email_changed?
  validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => true, :if => :email_changed?
  before_validation :prevent_email_change, on: :update
 
  before_create :generate_password
  
  
  
  def force_password_reset
    generate_password
  end
  
  def new_password
    @new_password
  end
  
  def timeout_in  
    30.minutes
  end
protected

  def prevent_email_change 
    if email_changed? && self.persisted?
      errors.add(:email, "change not allowed!")
    end
  end
  
  def generate_password
    generated_password = Devise.friendly_token.first(12)
    @new_password = generated_password    
    self.password = generated_password
  end
  
  
end
