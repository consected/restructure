# frozen_string_literal: true

require 'bcrypt'

module StandardAuthentication
  extend ActiveSupport::Concern

  # Number of days to extend a user's password expiration by for short term re-enabling of accounts
  ExtendExpirationDays = 5

  included do
    before_validation :setup_new_password, on: :create
    validates_uniqueness_of :email, case_sensitive: false, allow_blank: false, if: :email_changed?
    validates_format_of :email, with: Devise.email_regexp, allow_blank: false, if: :email_changed?

    validate :new_password_changed?, if: :password
    validate :no_matching_prev_passwords, if: :password
    validates :password, password_strength: password_config, if: :password_changed?
    validate :password_like_email, if: :password_changed?
    validate :check_strength, if: :password_changed?
    before_create :setup_two_factor_auth
    before_save :handle_password_change
    after_save :handle_password_reminder_setup, if: :set_reminder
    after_save :clear_plaintext_password
    after_create :notify_admin
    attr_accessor :new_two_factor_auth_code, :forced_password_reset, :new_password, :set_reminder

    scope :can_email, -> { where 'do_not_email IS NULL or do_not_email = FALSE' }
  end

  class_methods do
    #
    # @return [Boolean] - true if 2FA is disabled
    def two_factor_auth_disabled
      return Settings::TwoFactorAuthDisabledForUser if self == User
      return Settings::TwoFactorAuthDisabledForAdmin if self == Admin

      nil
    end

    #
    # Number of days after a password has been created or updated to expire it
    def expire_password_after
      Settings::PasswordAgeLimit
    end

    #
    # Number of days before a password expires to remind the user
    def remind_days_before
      Settings::PasswordReminderDays
    end

    #
    # Number of days before a password expires to remind the user
    def remind_repeat_days
      Settings::PasswordReminderRepeatDays
    end

    #
    # Key used to encrypt OTP keys
    def otp_enc_key
      (Devise.secret_key || Rails.application.secrets[:secret_key_base]) + "-#{name}"
    end

    #
    # Config for password complexity
    def password_config
      Settings::PasswordConfig
    end

    #
    # Is the supplied password strong enough, based on either entropy, regex, or other future rules
    # @param [String] password
    # @param [Hash] result - Hash to be updated with result {test:, result:, reason:}
    # @return [true|false]
    def password_strong_enough(password, result: nil)
      result ||= {}

      min_entropy = password_config[:min_entropy]

      if min_entropy > 0
        entropy_strength = calculate_entropy_strength(password)

        if entropy_strength < min_entropy
          result.merge! test: :entropy,
                        result: false,
                        reason: "strength is #{(entropy_strength.to_f / min_entropy * 100).to_i}%. " \
                                'Try to use a mix of upper and lower case, symbols and numbers, ' \
                                'and avoid dictionary words.'

          return false
        end
      end

      unless password_regex_matched?(password)
        result.merge! test: :regex,
                      result: false,
                      reason: "is not complex enough. #{password_config[:regex_requirements]}"

        return false
      end

      result.merge! test: :all, result: true
      true
    end

    #
    # Calculate password strength, setting up the strength checker based on
    # Settings::PasswordConfig
    # @param [String] password
    # @return [Integer]
    def calculate_entropy_strength(password)
      c = password_config
      # extra_dictionary_words: is specified in the config and points to any method in this class.
      # In reality it is likely to be :word_list
      checker = StrongPassword::StrengthChecker.new(min_word_length: c[:min_word_length],
                                                    use_dictionary: true,
                                                    extra_dictionary_words: send(c[:extra_dictionary_words]))
      checker.calculate_entropy password
    end

    #
    # Checks the supplied password matches the configured regex, if there is one
    # @param [String] password
    # @return [true|false]
    def password_regex_matched?(password)
      c = password_config
      return true if c[:regex].blank?

      reg = Regexp.new(c[:regex])

      reg.match?(password)
    end

    #
    # Word list to prevent use of in passwords
    def word_list
      return [] if Rails.env.test?

      words = []
      File.open(Settings::OsWordsFile) do |file|
        file.each do |line|
          words << line.strip
        end
      end

      User.all.each do |u|
        words += u.email.split(/[^a-zA-Z]/).reject { |w| w.length < 4 }.map(&:downcase) if u.email
      end
      Admin.all.each do |u|
        words += u.email.split(/[^a-zA-Z]/).reject { |w| w.length < 4 }.map(&:downcase) if u.email
      end

      words
    end
  end

  def expires_in
    return 0 unless password_updated_at

    [
      ((password_updated_at - self.class.expire_password_after.days.ago) / 1.day).ceil,
      0
    ].max
  end

  def two_factor_auth_disabled
    self.class.two_factor_auth_disabled
  end

  #
  # Does the password need to be changed (due to being too old)?
  def need_change_password?
    set_default_password_expiration
    password_updated_at < self.class.expire_password_after.days.ago
  end

  #
  # If the password is expiring soon, return the number of days left
  # Othewise return nil
  # @return [Integer | nil]
  def password_expiring_soon?
    set_default_password_expiration
    return unless password_updated_at < (self.class.expire_password_after - self.class.remind_days_before).days.ago

    ((password_updated_at - self.class.expire_password_after.days.ago) / 1.day).to_i
  end

  #
  # Force a user password reset by an admin, and unlock the account if it was locked
  # @return (String) - a newly generated temporary password
  def force_password_reset
    unlock_access!
    @forced_password_reset = true
    generate_password
  end

  #
  # Check if the user or admin password is a temporary password generated by a force_password_reset
  def has_temp_password?
    !!reset_password_sent_at
  end

  #
  # Return the newly generated API token
  # @return [String]
  def new_token
    @new_token
  end

  #
  # Disable the user or admin account
  def disable!
    self.disabled = true
    save
  end

  #
  # URI to be used in a two factor auth QR code
  def two_factor_auth_uri
    issuer = Settings::TwoFactorAuthIssuer
    label = "#{issuer} (#{self.class.name.downcase}) #{email}"
    otp_provisioning_uri(label, issuer: issuer)
  end

  #
  # Reset the two factor auth secret
  def reset_two_factor_auth
    setup_two_factor_auth
  end

  #
  # Allow an admin to extend the expiration date for user accounts by 5 days
  def extend_expiration
    self.password_updated_at = (self.class.expire_password_after - ExtendExpirationDays).days.ago
  end

  #
  # Allow an admin to unlock the account if number of failed password
  # attempts was reached and we don't want to wait for the timeout
  def unlock_failed_attempts
    unlock_access!
  end

  #
  # Validate that the provided two-factor authentication code is valid for the user
  # @param code (String) - the code to check
  # @return (Boolean) - true if valid
  def validate_one_time_code(code)
    return unless validate_and_consume_otp!(code)

    self.otp_required_for_login = true
    save
  end

  #
  # Ensure 2FA has been set up if required
  def two_factor_setup_required?
    !two_factor_auth_disabled && !(otp_secret.present? && otp_required_for_login)
  end

  #
  # Generate a random password for a user
  # Capture the plain text password in the @new_password attribute
  # @return (String) - Generated plain text password
  def generate_password
    res = false
    i = 0
    until res
      generated_password = Devise.friendly_token.first(16)
      res = self.class.password_strong_enough(generated_password)
      i += 1
    end

    if i > 1
      Rails.logger.info "Took #{i} times to make password"
      # puts "Took #{i} times to make password"
    end

    @new_token = Devise.friendly_token(30)
    self.authentication_token = @new_token

    @new_password = generated_password
    self.password = generated_password
  end

  protected

  #
  # Validation to check the password strength is sufficient
  def check_strength
    return if errors.any? || password.nil?

    res = {}
    return true if self.class.password_strong_enough(password, result: res)

    errors.add :password, res[:reason]
    false
  end

  #
  # Validation to check if a password is like the user's email address
  def password_like_email
    return unless password && email && password.downcase.include?(email)

    errors.add :password, 'can not be similar to your email address'
  end

  # Setup password for new user
  def setup_new_password
    return if allow_users_to_register? && (current_admin == RegistrationHandler.registration_admin)

    generate_password
    @forced_password_reset = true
  end

  # Get the password word blacklist
  def word_list
    self.class.word_list
  end

  #
  # Validation for a new password, to check it has actually changed
  def new_password_changed?
    errors.add :password, 'must be changed' unless password_changed?
  end

  #
  # A direct comparison of encrypted_password against what is saved in the DB is not possible, since
  # bcrypt generates a new salt every time.
  # Instead, extract the salt from the old password, then generate a temp hash
  # of the new password to see if it matches the old hash
  # @param prev_password_hash (String)
  # optionally specify a password hash to compare against, otherwise
  # use the last saved password
  # @return (Boolean)
  # true if the password has actually changed
  def password_changed?(prev_password_hash: nil)
    prev_password_hash ||= encrypted_password_was
    return false unless password
    return true if prev_password_hash.blank? && password.present?

    # Get salt from saved encrypted_password
    salt = BCrypt::Password.new(prev_password_hash).salt
    # Recreate the new password with the old salt
    temp_password_hash = BCrypt::Engine.hash_secret(password, salt)
    # Compare
    temp_password_hash != prev_password_hash
  end

  #
  # Setup two factor auth for the current user
  # A secret is generated, ready to be communicated to the user in the form of a QR code
  # the next time they login.
  def setup_two_factor_auth
    return true if self.class.two_factor_auth_disabled

    # initially we say that otp is not required for login, so that on the first login we can show the QR code to users
    self.otp_required_for_login = false
    self.otp_secret = self.class.generate_otp_secret
    self.new_two_factor_auth_code = true
  end

  # Force the reset_password_sent_at date to 'now' to reflect if this was a temp password
  # generated by an admin resetting a user's password.
  # If the user has actually changed their password, then reset this flag to nil
  # In either case, record the timestamp the password was updated at
  # and set a password reminder job up for a User
  def handle_password_change
    @set_reminder = nil
    if @forced_password_reset
      self.reset_password_sent_at = DateTime.now
      self.password_updated_at = DateTime.now
      @set_reminder = true
    elsif password_changed?
      self.reset_password_sent_at = nil
      self.password_updated_at = DateTime.now
      @set_reminder = true
    end
  end

  #
  # Callback after save to handle the setup of password expiration reminders
  # to the user's email address.
  # The reminder will happen if the password was forcibly reset or the user
  # changed the password (based on the value of @set_reminder).
  # Other User model changes will not trigger the reminder.
  # NOTE: currently reminders are only sent for User models not Admin
  # @return [HandlePasswordExpirationReminderJob]
  def handle_password_reminder_setup
    Users::Reminders.password_expiration(self) if @set_reminder && is_a?(User)
  end

  # Check if there are no matching previous passwords in the history
  # The number of passwords to look back is in Settings::CheckPrevPasswords
  def no_matching_prev_passwords
    num = Settings::CheckPrevPasswords

    # If number is 1, this counts as the previous password, which we are checking anyway in default new_password_changed?
    return true if num < 2

    history_table = "#{self.class.name.downcase.singularize}_history"

    # We limit to one more than the specified number in history table, since this contains the current one in addition to the previous
    # Also, we have to pick only the distinct items, since the history table records logins, not just password changes
    userid = id
    tn = self.class.table_name

    pwhs = self.class.unscope(:order)
               .joins(
                 Arel.sql(
                   self.class.send(
                     :sanitize_sql_array,
                     ["inner join #{history_table} on #{history_table}.#{tn.singularize}_id = #{tn}.id"]
                   )
                 )
               )
               .where(tn => { id: userid })
               .order(
                 Arel.sql(
                   self.class.send(
                     :sanitize_sql_array,
                     ["#{history_table}.id desc"]
                   )
                 )
               )
               .limit(num + 1)
               .pluck(
                 Arel.sql(
                   self.class.send(
                     :sanitize_sql_array,
                     ["distinct on (#{history_table}.id) #{history_table}.encrypted_password"]
                   )
                 )
               )

    limited_pwhs = pwhs[1..]

    # Nothing to check against. All ok
    return true if limited_pwhs.nil?

    # Skip the first one, which we've checked, as mentioned above
    limited_pwhs.each do |pwh|
      c = password_changed? prev_password_hash: pwh
      # If not changed then we found a match
      unless c
        errors.add :new_password, "matches a previous password. #{num} previous passwords are checked."
        break
      end
    end
  end

  #
  # Clear the plain text password after saving to avoid accidental leakage
  def clear_plaintext_password
    @password = nil
  end

  #
  # Set a default value for password_updated_at
  # if nothing is currently set
  def set_default_password_expiration
    return if password_updated_at

    self.password_updated_at = (self.class.expire_password_after - self.class.remind_days_before).days.ago
    save
  end

  #
  # Optionally notify the administration when new users or admins are registered
  def notify_admin
    notify = Settings::NotifyOnRegistration
    return unless notify.present?

    Users::NewUserAdded.notify(self) if is_a?(Admin) && notify.include?('admin')
    Users::NewUserAdded.notify(self) if is_a?(User) && notify.include?('user')
  end
end
