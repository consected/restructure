# frozen_string_literal: true

Rails.application.configure do
  config.log_level = :debug
  config.log_formatter = ::Logger::Formatter.new

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    # config.cache_store = :null_store
    config.cache_store = :mem_cache_store

  end

  config.i18n.fallbacks = [I18n.default_locale]

  # Store uploaded files on the local file system (see config/storage.yml for options)
  # config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.delivery_method = :test

  # config.action_mailer.smtp_settings = {
  #   address: ENV['SMTP_SERVER'] || 'email-smtp.us-east-1.amazonaws.com',
  #   port: ENV['SMTP_PORT'] || 465,
  #   user_name: ENV['SMTP_USER_NAME'],
  #   password: ENV['SMTP_PASSWORD'],
  #   authentication: (ENV['SMTP_AUTHENTICATION_MODE'] || 'login').to_sym,
  #   enable_starttls_auto: true,
  #   # openssl_verify_mode: :peer,
  #   tls: true
  # }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  config.active_job.queue_adapter = :inline
  # config.active_job.queue_adapter = :delayed_job

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.assets.js_compressor = :terser

  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
end
