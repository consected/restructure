
if Rails.env.production?
  # Set up encrypted fields
  Rails.application.config.active_record.encryption.primary_key = Settings::EncryptionSecretKeyBase
  Rails.application.config.active_record.encryption.deterministic_key = "#{Settings::SecretKeyBase}-deterministic_key"
  Rails.application.config.active_record.encryption.key_derivation_salt = Settings::EncryptionSalt
end