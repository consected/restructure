class Admin < ActiveRecord::Base
  
  include StandardAuthentication

  devise :database_authenticatable, :trackable, :timeoutable, :lockable, :validatable

  before_validation :prevent_email_change, on: :update
  before_validation :prevent_reenabling_admin, on: :update
  before_validation :prevent_not_in_setup_script, on: :create


  def enabled?
    !self.disabled
  end

  def timeout_in
    return Settings::AdminTimeout
  end

  # Standard Devise callback to allow accounts to be disabled
  def active_for_authentication?
    super && !self.disabled
  end

  # Standard Devise callback to tell user that an account has been disabled
  def inactive_message
    !self.disabled  ? super : :account_has_been_disabled
  end

  # Simple way to ensure that this is not being run from inside Passenger
  def in_setup_script
    ENV['FPHS_ADMIN_SETUP']=='yes'
  end

  def to_s
    email
  end

  protected

    def prevent_email_change
      if email_changed? && self.persisted?
        errors.add(:email, "change not allowed!")
      end
    end

    def prevent_reenabling_admin
      if disabled_changed? && self.persisted? && self.disabled != true && !in_setup_script
        errors.add(:disabled, "change not allowed!")
      end

    end

    def prevent_not_in_setup_script
      errors.add(:admin, "can only create admins in console") unless in_setup_script
    end

end
