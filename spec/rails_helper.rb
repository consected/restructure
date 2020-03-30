# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
ENV['FPHS_ADMIN_SETUP']='yes'
ENV['FPHS_USE_LOGGER']='TRUE'

# Ensure that we have access to the AWS client when working with AWS MFA
# Relies on aws-mfa-login, which is a Python wheel. To install:
#   pip install aws-mfa-login
# To avoid needing this, get an STS security token and set the environment variables
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_SESSION_TOKEN
#


res = `aws sts get-caller-identity | grep "756598248234"`
if res == ''
  puts "AWS MFA is needed. Run\n  fphs-scripts/aws_mfa_set.rb"
  exit
end


require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rspec'
require 'devise'

require 'browser_helper'
require 'setup_helper'
include BrowserHelper


setup_browser

include Warden::Test::Helpers
Warden.test_mode!
# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# Seed the database before loading files, since things like Scantron model and
# controller will not exist without the seed
require "#{::Rails.root}/db/seeds.rb"
Seeds.setup
raise "Scantron not defined by seeds" unless defined?(Scantron) && defined?(ScantronsController)

res = `#{::Rails.root}/fphs-scripts/setup-dev-filestore.sh`
if res != "mountpoint OK\n"
  puts res
  puts "Run fphs-scripts/setup-dev-filestore.sh and try again"
  exit
end

# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
require "#{::Rails.root}/spec/support/master_support.rb"
require "#{::Rails.root}/spec/support/model_support.rb"

Dir[Rails.root.join('spec/support/*.rb')].each { |f| require f }
Dir[Rails.root.join('spec/support/*/*.rb')].sort.each { |f| require f }

SetupHelper.setup_byebug
SetupHelper.validate_db_setup

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!




RSpec.configure do |config|

  config.before(:suite) do
    # Do some setup that could impact all tests through the availability of master associations

    # Seeds.setup
    Seeds::ActivityLogPlayerContactPhone.setup

    als = ActivityLog.active.where(item_type: 'zeus_bulk_message')
    als.each do |a|
      a.update! current_admin: a.admin, disabled: true if a.enabled?
    end


    Rails.application.load_tasks
    Rake::Task["assets:precompile"].invoke
  end
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!


  # removed Devise::TestHelpers from the following line, since it is now deprecated.
  # Using Devise::Test::ControllerHelpers as advised
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.extend ControllerMacros, :type => :controller
  config.after :each do
    Warden.test_reset!
  end
#  config.after(:suite) do
#    `brakeman`
#    `bundle-audit update`
#    `bundle-audit check`
#  end


end
