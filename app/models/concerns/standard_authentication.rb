require 'bcrypt'

module StandardAuthentication
  extend ActiveSupport::Concern

  included do
    before_validation :generate_password, on: :create
    validates_uniqueness_of :email, :case_sensitive => false, :allow_blank => false, :if => :email_changed?
    validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => false, :if => :email_changed?

    validate :new_password_changed?, if: :password
    validates :password, password_strength: password_config, if: :password_changed?
    validate :password_like_email, if: :password_changed?
    validate :check_strength, if: :password_changed?
    before_create :setup_two_factor_auth
    before_save :is_temp_password!
    attr_accessor :new_two_factor_auth_code, :forced_password_reset
  end

  class_methods do

    def otp_enc_key
      (ENV['FPHS_RAILS_DEVISE_SECRET_KEY'] || Rails.application.secrets[:secret_key_base]) + "-#{self.name}"
    end


    def password_config
      Settings::PasswordEntropyConfig
    end

    def calculate_strength password
      checker = StrongPassword::StrengthChecker.new(password)
      c = self.password_config
      checker.calculate_entropy min_word_length: c[:min_word_length], use_dictionary: true, extra_dictionary_words: self.send(c[:extra_dictionary_words])
    end

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

  def force_password_reset
    unlock_access!
    @forced_password_reset = true
    generate_password
  end

  def has_temp_password?
    !!self.reset_password_sent_at
  end

  def new_password
    @new_password
  end

  def new_token
    @new_token
  end


  def disable!
    self.disabled = true
    self.save
  end

  def two_factor_auth_uri
    issuer = Settings::TwoFactorAuthIssuer
    label = "#{issuer}:#{self.email}"
    self.otp_provisioning_uri(label, issuer: issuer)
  end

  def reset_two_factor_auth
    setup_two_factor_auth
  end

  protected

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

    def password_like_email
      if password
        errors.add :password, "can not be similar to your email address" if password && email && password.downcase == email
      end
    end

    # Generate a random password for a new user
    # Return the plain text password in the new_password attribute
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

      @forced_password_reset = true

      @new_password = generated_password
      self.password = generated_password
    end

    def word_list
      self.class.word_list
    end


    def new_password_changed?
      errors.add :password, 'must be changed' unless password_changed?
    end

    # A direct comparison of encrypted_password against what is saved in the DB is not possible, since
    # bcrypt generates a new salt every time.
    # Instead, extract the salt from the old password, then generate a temp hash
    # of the new password to see if it matches the old hash
    def password_changed?
      return false unless self.password
      return true if encrypted_password_was.blank? && self.password.present?
      # Get salt from saved encrypted_password
      salt = BCrypt::Password.new(encrypted_password_was).salt
      # Recreate the new password with the old salt
      temp_password_hash = BCrypt::Engine.hash_secret(self.password, salt)
      # Compare
      temp_password_hash != encrypted_password_was
    end

    def setup_two_factor_auth
      self.otp_required_for_login = true
      self.otp_secret = User.generate_otp_secret
      self.new_two_factor_auth_code = true
    end

    def is_temp_password!
      if @forced_password_reset
        self.reset_password_sent_at = DateTime.now
      elsif password_changed?
        self.reset_password_sent_at = nil
      end
    end

end
