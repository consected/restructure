#
# Add configurations for ActionMailer centrally, allowing for test configurations to
# exercise real configurations.
#
# In test, call with the following environment variable to test real SMTP sending:
# TEST_MAIL=t
# The `mail` gem has previously caused issues after an upgrade, so exercise that a bad configuration
# is raised properly by setting:
# TEST_MAIL_BAD_CONFIG=t
Rails.application.configure do
  Settings::TestMailBadConfig = ENV['TEST_MAIL_BAD_CONFIG'].present?
  Settings::TestMail = ENV['TEST_MAIL'].present?

  if Settings::TestMailBadConfig
    # Test ActionMailer with bad configuration (passed to `mail` gem)
    smtp_starttls_auto = true
    smtp_tls = true
  else
    # For production
    # assume SMTP with STARTTLS if TLS is not set
    # It is a requirement of the `mail` gem used by ActionMailer that
    # both are not set at the same time. This ensures that one TLS option is set.
    smtp_tls = ENV['SMTP_TLS'].present?
    smtp_starttls_auto = !smtp_tls
  end

  use_smtp = Rails.env.production? || Settings::TestMail
  config.action_mailer.delivery_method = use_smtp ? :smtp : :test

  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_SERVER'],
    port: ENV['SMTP_PORT'],
    user_name: ENV['SMTP_USER_NAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: (ENV['SMTP_AUTHENTICATION_MODE'] || 'login').to_sym,
    enable_starttls_auto: smtp_starttls_auto,
    tls: smtp_tls
  }

  # Set both the `:open_timeout` and `:read_timeout` values for `:smtp` delivery method.
  config.action_mailer.smtp_timeout = ENV['SMTP_TIMEOUT'].presence&.to_i || 5
  config.action_mailer.perform_caching = false
end
