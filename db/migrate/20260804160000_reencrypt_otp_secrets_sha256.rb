class ReencryptOtpSecretsSha256 < ActiveRecord::Migration[8.0]
  # Run only after every app server is deployed with support_sha1_for_non_deterministic_encryption
  # enabled (already the case here) - old-code servers cannot read SHA256 ciphertext.
  # Runs as one transaction (the default), so it's all-or-nothing.

  # Rewrites the ciphertext only - the decrypted OTP value is preserved, so no user
  # re-enrolment is needed. Uses update_column to bypass validations/callbacks
  # (password checks, notifications, etc).
  def up
    [User, Admin].each do |klass|
      unless encrypted_otp_secret?(klass)
        puts "#{klass.name}: otp_secret is not an encrypted attribute here (2FA disabled?) - skipping"
        next
      end

      reencrypted = 0
      skipped_blank = 0
      skipped_corrupt = 0

      klass.where.not(otp_secret: nil).find_each do |record|
        # Re-fetch and lock the row so a concurrent otp_secret reset (e.g. reset_two_factor_auth)
        # can't be overwritten by the stale value read here.
        locked = klass.lock.find(record.id)
        secret = locked.otp_secret # transparently decrypts via SHA256, or the SHA1 previous scheme

        if locked.otp_secret_decryption_failed?
          skipped_corrupt += 1
          Rails.logger.warn "ReencryptOtpSecretsSha256 - skipped #{klass.name} id=#{locked.id}: otp_secret could not be decrypted"
          next
        end

        if secret.blank?
          skipped_blank += 1
          next
        end

        # Re-serializes and re-encrypts under the current default scheme (SHA256) on write.
        locked.update_column(:otp_secret, secret)
        reencrypted += 1
      end

      puts "#{klass.name}: re-encrypted #{reencrypted}, skipped #{skipped_blank} blank, skipped #{skipped_corrupt} corrupt"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Original SHA1 ciphertext is not retained, so this re-encryption cannot be undone.'
  end

  private

  # @return [Boolean] true if otp_secret is declared via Rails `encrypts` for this class
  #   (false if 2FA - and therefore devise-two-factor's `encrypts :otp_secret` - is disabled)
  def encrypted_otp_secret?(klass)
    klass.type_for_attribute(:otp_secret).is_a?(ActiveRecord::Encryption::EncryptedAttributeType)
  end
end
