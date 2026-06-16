# frozen_string_literal: true

module StandardAuthenticationSafeOtp
  extend ActiveSupport::Concern

  # Override the devise-two-factor otp_secret reader to handle decryption failures
  # gracefully. When the otp_secret column contains undecryptable ciphertext
  # (key rotation, manual DB edit, corruption), return nil instead of raising.
  def otp_secret
    self[:otp_secret].presence
  rescue ActiveRecord::Encryption::Errors::Decryption => e
    unless @otp_secret_decryption_failed
      Rails.logger.warn { "otp_secret decryption failed for #{self.class.name} id=#{id}: #{e.class}" }
    end
    @otp_secret_decryption_failed = true
    nil
  end

  # Override the writer so that setting a new otp_secret after corruption
  # first nullifies the raw DB value, preventing AR dirty-tracking from
  # re-reading the undecryptable ciphertext during save.
  def otp_secret=(value)
    if @otp_secret_decryption_failed
      self.class.where(id: id).update_all(otp_secret: nil) if persisted?
      @otp_secret_decryption_failed = false
      reload
    end
    super
  end

  def otp_secret_decryption_failed?
    @otp_secret_decryption_failed == true
  end
end
