require 'bcrypt'

module StandardAuthentication
  extend ActiveSupport::Concern

  included do
    before_validation :setup_new_password, on: :create
    validates_uniqueness_of :email, :case_sensitive => false, :allow_blank => false, :if => :email_changed?
    validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => false, :if => :email_changed?

    validate :new_password_changed?, if: :password
    validate :no_matching_prev_passwords, if: :password
    validates :password, password_strength: password_config, if: :password_changed?
    validate :password_like_email, if: :password_changed?
    validate :check_strength, if: :password_changed?
    before_create :setup_two_factor_auth
    before_save :handle_password_change
    after_save :clear_plaintext_password
    attr_accessor :new_two_factor_auth_code, :forced_password_reset, :new_password
  end

  class_methods do

    def expire_password_after
      Settings::PasswordAgeLimit
    end

    # Key used to encrypt OTP keys
    def otp_enc_key
      (ENV['FPHS_RAILS_DEVISE_SECRET_KEY'] || Rails.application.secrets[:secret_key_base]) + "-#{self.name}"
    end

    # Config for password complexity
    def password_config
      Settings::PasswordEntropyConfig
    end

    # Calculate password strength
    def calculate_strength password
      checker = StrongPassword::StrengthChecker.new(password)
      c = self.password_config
      checker.calculate_entropy min_word_length: c[:min_word_length], use_dictionary: true, extra_dictionary_words: self.send(c[:extra_dictionary_words])
    end

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
        words += u.email.split(/[^a-zA-Z]/).reject {|w| w.length < 4}.map(&:downcase) if u.email
      end
      Admin.all.each do |u|
        words += u.email.split(/[^a-zA-Z]/).reject {|w| w.length < 4}.map(&:downcase) if u.email
      end

      return words
    end

  end

  # Does the password need to be changed (due to being too old)?
  def need_change_password?
    set_default_password_expiration
    self.password_updated_at < self.class.expire_password_after.days.ago
  end

  # If the password is expiring soon, return the number of days
  # Othewise return nil
  def password_expiring_soon?
    set_default_password_expiration
    if self.password_updated_at < (self.class.expire_password_after - 5).days.ago
      ((self.password_updated_at - self.class.expire_password_after.days.ago) / 1.day).to_i
    else
      nil
    end
  end

  # Force a user password reset by an admin, and unlock the account if it was locked
  # @return (String)
  #   a newly generated temporary password
  def force_password_reset
    unlock_access!
    @forced_password_reset = true
    generate_password
  end


  # Check if the user or admin password is a temporary password generated by a force_password_reset
  def has_temp_password?
    !!self.reset_password_sent_at
  end

  def new_token
    @new_token
  end

  # Disable the user or admin account
  def disable!
    self.disabled = true
    self.save
  end

  # URI to be used in a two factor auth QR code
  def two_factor_auth_uri
    issuer = Settings::TwoFactorAuthIssuer
    label = "#{issuer} (#{self.class.name.downcase}) #{self.email}"
    self.otp_provisioning_uri(label, issuer: issuer)
  end

  # Reset the two factor auth secret
  def reset_two_factor_auth
    setup_two_factor_auth
  end

  # Validate that the provided one time code is valid for the user
  # @param code (String)
  #  The code to check
  # @return (Boolean)
  # true if valid
  def validate_one_time_code code
    if code == self.current_otp
      self.otp_required_for_login = true
      self.save
    end
  end

  # Generate a random password for a user
  # Capture the plain text password in the @new_password attribute
  # @return (String)
  #   Generated plain text password
  def generate_password
    res = false
    i = 0
    while !res
      generated_password = Devise.friendly_token.first(16)
      res = (self.class.calculate_strength(generated_password) >= self.class.password_config[:min_entropy])
      i += 1
    end

    if i > 1
      Rails.logger.info "Took #{i} times to make password"
      puts "Took #{i} times to make password"
    end

    @new_token = Devise.friendly_token(30)
    self.authentication_token = @new_token

    @new_password = generated_password
    self.password = generated_password
  end


  protected

    # Check the password strength is sufficient
    def check_strength
      if errors.any? && password
        res = self.class.calculate_strength(password)
        c = self.class.password_config
        unless res >= c[:min_entropy]
          errors.add :password, "strength is #{(res.to_f / c[:min_entropy] * 100).to_i}%. Try to use a mix of upper and lower case, symbols and numbers, and avoid dictionary words."
          return false
        end
      end
    end

    # Check if a password is like the user's email address
    def password_like_email
      if password
        errors.add :password, "can not be similar to your email address" if password && email && password.downcase == email
      end
    end

    # Setup password for new user
    def setup_new_password
      generate_password
      @forced_password_reset = true
    end

    # Get the password word blacklist
    def word_list
      self.class.word_list
    end

    # Validation for a new password, to check it has actually changed
    def new_password_changed?
      errors.add :password, 'must be changed' unless password_changed?
    end

    # A direct comparison of encrypted_password against what is saved in the DB is not possible, since
    # bcrypt generates a new salt every time.
    # Instead, extract the salt from the old password, then generate a temp hash
    # of the new password to see if it matches the old hash
    # @param prev_password_hash (String)
    # optionally specify a password hash to compare against, otherwise
    # use the last saved password
    # @return (Boolean)
    # true if the password has actually changed
    def password_changed? prev_password_hash: nil
      prev_password_hash ||= encrypted_password_was
      return false unless self.password
      return true if prev_password_hash.blank? && self.password.present?
      # Get salt from saved encrypted_password
      salt = BCrypt::Password.new(prev_password_hash).salt
      # Recreate the new password with the old salt
      temp_password_hash = BCrypt::Engine.hash_secret(self.password, salt)
      # Compare
      temp_password_hash != prev_password_hash
    end

    # Setup two factor auth for the current user
    # A secret is generated, ready to be communicated to the user in the form of a QR code
    # the next time they login.
    def setup_two_factor_auth
      # initially we say that otp is not required for login, so that on the first login we can show the QR code to users
      self.otp_required_for_login = false
      self.otp_secret = self.class.generate_otp_secret
      self.new_two_factor_auth_code = true
    end

    # Force the reset_password_sent_at date to 'now' to reflect if this was a temp password
    # generated by an admin resetting a user's password.
    # If the user has actually changed their password, then reset this flag to nil
    # In either case, record the timestamp the password was updated at
    def handle_password_change
      if @forced_password_reset
        self.reset_password_sent_at = DateTime.now
        self.password_updated_at = DateTime.now
      elsif password_changed?
        self.reset_password_sent_at = nil
        self.password_updated_at = DateTime.now
      end
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
      userid = self.id
      tn = self.class.table_name

      pwhs = self.class.unscope(:order).joins(self.class.send :sanitize_sql_array, ["inner join #{history_table} on #{history_table}.#{tn.singularize}_id = #{tn}.id"]).
                    where(tn => {id: userid}).
                    order(self.class.send :sanitize_sql_array, ["#{history_table}.id desc"]).
                    limit(num + 1).
                    pluck(self.class.send :sanitize_sql_array, ["distinct on (#{history_table}.id) #{history_table}.encrypted_password"])


      limited_pwhs = pwhs[1..-1]

      # Nothing to check against. All ok
      return true if limited_pwhs.nil?

      # Skip the first one, which we've checked, as mentioned above
      limited_pwhs.each do |pwh|
        c = password_changed? prev_password_hash: pwh
        # If not changed then we found a match
        unless c
          errors.add :new_password, "matches a previous password. #{num} previous passwords are checked."
          return
        end
      end

    end

    # Clear the plain text password after saving to avoid accidental leakage
    def clear_plaintext_password
      self.password = nil
    end

    def set_default_password_expiration
      unless self.password_updated_at
        self.password_updated_at = (self.class.expire_password_after - 5).days.ago
        self.save
      end
    end

end
