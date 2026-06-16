# frozen_string_literal: true

module StandardAuthenticationSafeOtp
  extend ActiveSupport::Concern

  # Single safe rescue point for otp_secret reads via the generated attribute method,
  # direct hash access (obj[:otp_secret]), dirty tracking, and similar paths that
  # go through AR's _read_attribute.
  def _read_attribute(attr_name, &block)
    super
  rescue ActiveRecord::Encryption::Errors::Decryption
    if attr_name.to_s == 'otp_secret'
      unless @otp_secret_decryption_failed
        Rails.logger.warn { "otp_secret decryption failed for #{self.class.name} id=#{id}: ActiveRecord::Encryption::Errors::Decryption" }
      end
      @otp_secret_decryption_failed = true
      nil
    else
      raise
    end
  end

  # Override the devise-two-factor otp_secret reader to use the safe low-level
  # reader, skipping the legacy attr_encrypted fallback path which is not used
  # in this Rails 7 application.
  def otp_secret
    _read_attribute('otp_secret')
  end

  # AR's `attributes` calls @attributes.to_hash directly, bypassing _read_attribute.
  # When otp_secret is corrupt the bulk read raises; we rebuild the hash one
  # attribute at a time via _read_attribute (which is already safe above).
  def attributes
    super
  rescue ActiveRecord::Encryption::Errors::Decryption
    unless @otp_secret_decryption_failed
      Rails.logger.warn { "otp_secret decryption failed in #attributes for #{self.class.name} id=#{id}: ActiveRecord::Encryption::Errors::Decryption" }
    end
    @otp_secret_decryption_failed = true
    self.class.attribute_names.each_with_object({}) do |name, hash|
      hash[name] = begin
                     _read_attribute(name)
                   rescue ActiveRecord::Encryption::Errors::Decryption
                     nil
                   end
    end
  end

  # Override the writer so that setting a new otp_secret after corruption
  # first nullifies the raw DB value, preventing AR dirty-tracking from
  # re-reading the undecryptable ciphertext during save.
  # Proactively reads the current value so the decryption failure flag is set
  # even when the reader hasn't been called yet (e.g. admin reset flow).
  def otp_secret=(value)
    otp_secret # ensure @otp_secret_decryption_failed is populated if corrupt
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
