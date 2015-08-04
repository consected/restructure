class User < ActiveRecord::Base
  
  include ActionLogging
  include AdminHandler
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :trackable, :timeoutable, :lockable
  belongs_to :admin
  validates_uniqueness_of :email, :case_sensitive => false, :allow_blank => false, :if => :email_changed?
  validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => false, :if => :email_changed?
  before_validation :prevent_email_change, on: :update
  before_validation :ensure_admin_for_disabled_change, on: :update
  validates :admin, presence: true
  
  before_create :generate_password
  
  default_scope -> {order email: :asc}
  
  
  def force_password_reset
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

  # Only allow the administrator to change email address
  def prevent_email_change 
    if email_changed? && self.persisted? && !admin
      errors.add(:email, "change not allowed!")
    end
  end

  def ensure_admin_for_disabled_change
    if disabled_changed? && self.persisted? && !admin
      errors.add(:disabled, "change not allowed!")
    end
  end
  
  def generate_password
    generated_password = Devise.friendly_token.first(12)
    @new_password = generated_password    
    self.password = generated_password
  end
  

end
