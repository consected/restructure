# Set up Rails encrypted attribute support.
# In production, encryption keys are set from environment variables via Settings.
# In development/test, encryption keys should be configured via Rails credentials.
# If Settings-based keys are configured, they override credential-based keys.
if Rails.env.production? && Settings::EncryptionSecretKeyBase.present? && Settings::EncryptionSalt.present?
  Rails.application.config.active_record.encryption.primary_key = Settings::EncryptionSecretKeyBase
  Rails.application.config.active_record.encryption.deterministic_key = "#{Settings::SecretKeyBase}-deterministic_key"
  Rails.application.config.active_record.encryption.key_derivation_salt = Settings::EncryptionSalt
end
