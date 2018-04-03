module StandardAuthentication
  extend ActiveSupport::Concern

  included do
    before_validation :generate_password, on: :create
    validates_uniqueness_of :email, :case_sensitive => false, :allow_blank => false, :if => :email_changed?
    validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => false, :if => :email_changed?
    validates :password, password_strength: password_config, if: :password_changed?
    validate :password_like_email, if: :password_changed?
    validate :calculate_strength, if: :password_changed?
  end

  class_methods do
    def password_config
      Settings::PasswordEntropyConfig
    end
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

    def calculate_strength
      if errors.any? && password
        checker = StrongPassword::StrengthChecker.new(password)
        c = self.class.password_config
        res = checker.calculate_entropy  min_word_length: c[:min_word_length], use_dictionary: true, extra_dictionary_words: self.send(c[:extra_dictionary_words])
        unless res >= c[:min_entropy]
          errors.add :password, "strength was #{(res.to_f / self.class.password_config[:min_entropy] * 100).to_i}%. Try to use a mix of upper and lower case, symbols and numbers, and avoid dictionary words."
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
      generated_password = Devise.friendly_token.first(16)
      @new_password = generated_password
      self.password = generated_password
    end

    def word_list
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

    def password_changed?
      encrypted_password_changed?
    end

end
