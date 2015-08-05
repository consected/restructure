class User < ActiveRecord::Base
  
  include ActionLogging
  include AdminHandler
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :trackable, :timeoutable, :lockable, :validatable
  belongs_to :admin
  validates_uniqueness_of :email, :case_sensitive => false, :allow_blank => false, :if => :email_changed?
  validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => false, :if => :email_changed?
  before_validation :generate_password, on: :create    
  
  
  
  default_scope -> {order email: :asc}
  
  
  def force_password_reset
    unlock_access!
    generate_password
  end
  
  def new_password
    @new_password
  end
  
  def timeout_in  
    30.minutes
  end

  
  def active_for_authentication?
    super && !self.disabled
  end
  
  def inactive_message
    !self.disabled  ? super : :account_has_been_disabled    
  end
    
protected

  
  def generate_password
    generated_password = Devise.friendly_token.first(12)
    @new_password = generated_password    
    self.password = generated_password
  end
  
  # Override blanket functionality to limit it to check for changed email and disabled flag change
  def ensure_admin_set
    if !admin && !self.persisted?
      errors.add(:admin, "account must be used to create user")
    end
    
    if email_changed? && self.persisted? && !admin
      errors.add(:email, "change not allowed!")
    end
    if disabled_changed? && self.persisted? && !admin
      errors.add(:disabled, "change not allowed!")
    end
  end

end
