# frozen_string_literal: true

# Make Active Record use stable #cache_key alongside new #cache_version method.
# This is needed for recyclable cache keys.
Rails.application.config.active_record.cache_versioning = true

# Use AES-256-GCM authenticated encryption for encrypted cookies.
# Also, embed cookie expiry in signed or encrypted cookies for increased security.
#
# Existing cookies will be converted on read then written with the new scheme.
Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = true

# Use AES-256-GCM authenticated encryption as default cipher for encrypting messages
# instead of AES-256-CBC, when use_authenticated_message_encryption is set to true.
# Rails.application.config.active_support.use_authenticated_message_encryption = true

# Use SHA-1 instead of MD5 to generate non-sensitive digests, such as the ETag header.
# Rails.application.config.active_support.use_sha1_digests = true
Rails.application.config.active_support.hash_digest_class = ::Digest::SHA1

# Make `form_with` generate id attributes for any generated HTML tags.
# Rails.application.config.action_view.form_with_generates_ids = true
