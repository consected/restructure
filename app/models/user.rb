class User < ActiveRecord::Base
  
  include ActionLogging
 
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :trackable, :timeoutable, :lockable
  validates_uniqueness_of :email, :case_sensitive => false, :allow_blank => true, :if => :email_changed?
  validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => true, :if => :email_changed?
 
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

  def generate_password
    generated_password = Devise.friendly_token.first(12)
    @new_password = generated_password    
    self.password = generated_password
  end
  
  
end
