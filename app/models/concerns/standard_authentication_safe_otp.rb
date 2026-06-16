# frozen_string_literal: true

module StandardAuthenticationSafeOtp
  extend ActiveSupport::Concern

  # Single safe rescue point for otp_secret reads via the generated attribute method,
  # direct hash access (obj[:otp_secret]), dirty tracking, and similar paths that
  # go through AR's _read_attribute.
  def _read_attribute(attr_name, &)
    super
  rescue ActiveRecord::Encryption::Errors::Decryption
    raise unless attr_name.to_s == 'otp_secret'

    unless @otp_secret_decryption_failed
      Rails.logger.warn { "otp_secret decryption failed for #{self.class.name} id=#{id}: ActiveRecord::Encryption::Errors::Decryption" }
    end
    @otp_secret_decryption_failed = true
    nil
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
    self.class.attribute_names.to_h do |name|
      [name, begin
        _read_attribute(name)
      rescue ActiveRecord::Encryption::Errors::Decryption
        # Only silence decryption errors for otp_secret; re-raise
        # for any other encrypted attribute so corruption is not hidden.
        raise unless name == 'otp_secret'

        nil
      end]
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
      # Write nil directly to the DB. Intentionally un-audited: this clears a
      # corrupt ciphertext so the subsequent encrypted write (via super) succeeds.
      self.class.where(id: id).update_all(otp_secret: nil) if persisted?
      # Reset the in-memory AR attribute to nil without a full reload, so that
      # other unsaved attribute changes on this record are preserved.
      @attributes.write_from_database('otp_secret', nil) if @attributes.key?('otp_secret')
      @otp_secret_decryption_failed = false
    end
    super
  end

  def otp_secret_decryption_failed?
    @otp_secret_decryption_failed == true
  end
end
