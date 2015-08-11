module StandardAuthentication
  extend ActiveSupport::Concern    

  included do
    before_validation :generate_password, on: :create    
    validates_uniqueness_of :email, :case_sensitive => false, :allow_blank => false, :if => :email_changed?
    validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => false, :if => :email_changed?

  end
  
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

  protected  

    # Generate a random password for a new user
    # Return the plain text password in the new_password attribute
    def generate_password
      generated_password = Devise.friendly_token.first(12)
      @new_password = generated_password    
      self.password = generated_password
    end

end
