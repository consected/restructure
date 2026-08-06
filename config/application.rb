require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require "active_storage/engine"
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Fpa1
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.active_record.schema_format = :sql

    # Enables YJIT as of Ruby 3.3, to bring sizeable performance improvements.
    # Moved here from config/initializers/new_framework_defaults_7_2.rb (issue #1015).
    config.yjit = true

    # Conservative overrides of Rails 7.2 defaults adopted via load_defaults 7.2 (issue #1015).
    # These are pinned to the pre-7.2 behaviour until their risk areas are validated.
    # Remove each override when the corresponding tracking sub-issue is resolved.

    # Rails 7.1+ defaults to a SHA256-derived key for non-deterministic ActiveRecord
    # Encryption attributes (e.g. otp_secret, dynamic model fields marked encrypted: true).
    # This app has existing production data encrypted under the old SHA1-derived key.
    # Keep SHA1 supported as a decrypt-only "previous scheme" so that data stays
    # readable; new writes still use the SHA256-derived key. Must be set here (not in
    # config/initializers) because config.active_record.encryption is a buffer that
    # Rails' "active_record_encryption.configuration" railtie initializer merges
    # into ActiveRecord::Encryption.config before config/initializers/*.rb load.
    # Tracking: issue #1293 (re-encrypt existing data and drop this fallback).
    config.active_record.encryption.support_sha1_for_non_deterministic_encryption = true
  end
end
