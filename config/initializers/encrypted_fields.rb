# Set up Rails encrypted attribute support.
# In production, encryption keys are set from environment variables via Settings.
# In development/test, encryption keys should be configured via Rails credentials.
# If Settings-based keys are configured, they override credential-based keys.
if Rails.env.production? && Settings::EncryptionSecretKeyBase.present? && Settings::EncryptionSalt.present?
  Rails.application.config.active_record.encryption.primary_key = Settings::EncryptionSecretKeyBase
  Rails.application.config.active_record.encryption.deterministic_key = "#{Settings::SecretKeyBase}-deterministic_key"
  Rails.application.config.active_record.encryption.key_derivation_salt = Settings::EncryptionSalt
end

# NOTE: config.active_record.encryption.support_sha1_for_non_deterministic_encryption
# is set in config/application.rb, not here (issue #1015/#1293). config.active_record.encryption
# is just an ActiveSupport::OrderedOptions buffer that Rails' "active_record_encryption.configuration"
# railtie initializer merges into the real ActiveRecord::Encryption.config *before*
# config/initializers/*.rb files load, so setting it in this file would be a no-op
# (verified empirically: the same appears to apply to primary_key/deterministic_key/
# key_derivation_salt above in production - needs separate investigation/tracking).
