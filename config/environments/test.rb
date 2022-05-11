# frozen_string_literal: true

require File.expand_path('../../lib/logger/do_nothing_logger.rb', __dir__)

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  # config.public_file_server.enabled = true
  # config.public_file_server.headers = {
  #   'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  # }

  config.i18n.fallbacks = [I18n.default_locale]

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # # Store uploaded files on the local file system in a temporary directory
  # config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Randomize the order test cases are executed.
  # config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  if ENV['FPHS_USE_LOGGER'] == 'TRUE'
    puts '!!!!!!!!!!!!!!!!!!!!!! DoNothingLogger disabled !!!!!!!!!!!!!!!!!!!!!!'
    config.log_level = :info
    config.log_formatter = ::Logger::Formatter.new
  else
    puts '!!!!!!!!!!!!!!!!!!!!!! DoNothingLogger enabled !!!!!!!!!!!!!!!!!!!!!!'
    config.logger = DoNothingLogger.new
  end

  config.active_job.queue_adapter = :delayed_job

  # Support parallel tests
  assets_cache_path = Rails.root.join("tmp/cache/assets/paralleltests#{ENV['TEST_ENV_NUMBER']}")
  config.assets.configure do |env|
    FileUtils.mkdir_p assets_cache_path
    env.cache = Sprockets::Cache::FileStore.new(assets_cache_path)
  end

  fs_cache_path = Rails.root.join('tmp', 'cache', 'cache-fs', "paralleltests#{ENV['TEST_ENV_NUMBER']}")
  FileUtils.mkdir_p fs_cache_path
  config.cache_store = :file_store, fs_cache_path

  config.active_record.dump_schema_after_migration = false
end
