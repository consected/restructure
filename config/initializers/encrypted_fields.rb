
if Rails.env.production?
  # Set up encrypted fields
  Rails.application.config.active_record.encryption.primary_key = EncryptionSecretKeyBase
  Rails.application.config.active_record.encryption.deterministic_key = "#{ENV['FPHS_RAILS_SECRET_KEY_BASE']}-deterministic_key"
  Rails.application.config.active_record.encryption.key_derivation_salt = EncryptionSalt
end