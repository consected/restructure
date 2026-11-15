# Set same_site to :lax to allow the session cookie to be sent in cross-site requests,
# which is necessary for certain authentication flows and third-party integrations.
# This setting helps mitigate CSRF attacks while still allowing necessary cross-site interactions.
Rails.application.config.session_store :active_record_store, same_site: :lax
