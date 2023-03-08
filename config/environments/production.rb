# frozen_string_literal: true

require File.expand_path('../../lib/logger/do_nothing_logger.rb', __dir__)

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  config.log_level = :fatal

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true
  config.require_master_key = false
  config.read_encrypted_secrets = false

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :terser # Uglifier.new(harmony: true)
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX
  config.action_dispatch.x_sendfile_header = ENV['FPHS_X_SENDFILE_HEADER']

  # Store uploaded files on the local file system (see config/storage.yml for options)
  # config.active_storage.service = :local

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Prepend all log lines with the following tags.
  # config.log_tags = [:request_id]

  # Use a different cache store in production.
  config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "fpa1_#{Rails.env}"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  config.action_mailer.delivery_method = :smtp

  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_SERVER'],
    port: ENV['SMTP_PORT'],
    user_name: ENV['SMTP_USER_NAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: (ENV['SMTP_AUTHENTICATION_MODE'] || 'login').to_sym,
    enable_starttls_auto: true,
    # openssl_verify_mode: :peer,
    tls: true
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  # Updated for breaking change in 1.1.0
  config.i18n.fallbacks = [I18n.default_locale]

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  config.log_level = if ENV['FPHS_LOG_LEVEL']
                       ENV['FPHS_LOG_LEVEL'].to_sym
                     else
                       :fatal
                     end

  case ENV['FPHS_USE_LOGGER']
  when 'TRUE', 'true', 'default'
    puts '!!!!!!!!!!!!!!!!!!!!!! Standard logger enabled !!!!!!!!!!!!!!!!!!!!!!'
    # Use default logging formatter so that PID and timestamp are not suppressed.
    config.log_formatter = ::Logger::Formatter.new
  when 'STDOUT'
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = ::Logger::Formatter.new
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  when 'syslog'
    # Use a different logger for distributed setups.
    puts '!!!!!!!!!!!!!!!!!!!!!! syslog enabled !!!!!!!!!!!!!!!!!!!!!!'
    require 'syslog/logger'
    config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new('restructure-app'))
  when 'DoNothing'
    puts '!!!!!!!!!!!!!!!!!!!!!! DoNothingLogger enabled !!!!!!!!!!!!!!!!!!!!!!'
    config.logger = DoNothingLogger.new
  else
    puts '!!!!!!!!!!!!!!!!!!!!!! Default (:fatal) logger   !!!!!!!!!!!!!!!!!!!!!!'
    config.log_level = :fatal
    config.log_formatter = ::Logger::Formatter.new
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.active_job.queue_adapter = :delayed_job
end
