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

    # Keep raw-SQL `date` columns decoding as String (not Ruby Date) until all raw-SQL
    # consumers are audited. Tracking: issue #1295.
    config.active_record.postgresql_adapter_decode_dates = false

    # Keep Active Job enqueuing immediately (pre-7.2 behaviour) rather than deferring
    # until after transaction commit, until delayed_job commit-timing is validated.
    # Tracking: issue #1296.
    config.active_job.enqueue_after_transaction_commit = :never
  end
end
