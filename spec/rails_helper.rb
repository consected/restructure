# frozen_string_literal: true

def put_now(msg)
  puts "#{Time.now} #{msg}"
end

def put_to_saved_log(msg)
  msg = "#{Time.now} #{msg}\n"
  File.write('tmp/test_saved.log', msg, mode: 'a')
end

# Provide a method to change app settings without a warning
def change_setting(name, value)
  silence_warnings { Settings.const_set(name, value) }
end

# Expectation / Matcher to handle the default matcher in routes when no route is actually matched
# We can not use expect(...).not_to be_routable since everything is matched
def expect_to_be_bad_route(for_request)
  method = for_request.first.first
  path = for_request.first.last
  path = path.split('/').select(&:present?).join('/')
  expect(for_request).to route_to(controller: 'bad_route', action: 'not_routed', path:)
end

put_now 'Starting rspec'

ENV['RAILS_ENV'] ||= 'test'
ENV['FPHS_ADMIN_SETUP'] = 'yes'
ENV['FPHS_USE_LOGGER'] = 'TRUE'

# Ensure that we have access to the AWS client when working with AWS MFA
# Relies on aws-mfa-login, which is a Python wheel. To install:
#   pip install aws-mfa-login
# To avoid needing this, get an STS security token and set the environment variables
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_SESSION_TOKEN
#

# By default, AWS APIs are mocked. Real AWS APIs can be exercised
# by setting environment variable `NO_AWS_MOCKS=true`
# When mocks are used by default, we also skip the AWS check for MFA authentication checks that follow.
ENV['IGNORE_MFA'] = 'true' unless ENV['NO_AWS_MOCKS'] == 'true'

unless ENV['IGNORE_MFA'] == 'true'
  # Check if MFA setup is required to access the AWS API and exit if it has not been set up.
  res = `aws sts get-caller-identity | grep "UserId"`
  if res == ''
    put_now "AWS MFA is needed. Run\n
    export AWS_PROFILE=<profile name>
    export AWS_ACCT_ID=<account id>
    app-scripts/aws_mfa_set.rb"
    exit
  end
end

put_now 'Require spec_helper'
require 'spec_helper'
put_now 'Require environment'

require File.expand_path('../config/environment', __dir__)
put_now 'Require rspec/rails'
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

put_now 'Require setup_helper'
require 'setup_helper'

if ENV['QUICK'] == 'true'
  put_now 'Running QUICK'
  ENV['SKIP_BROWSER_SETUP'] = 'true'
  ENV['SKIP_DB_SETUP'] = 'true'
  ENV['SKIP_APP_SETUP'] = 'true'
else
  put_now 'check_spec_db for skips'
  # Use a database table to track creations in the test db
  ENV['SKIP_DB_SETUP'] = 'true' if SetupHelper.spec_tally_done?('db_setup')
  if SetupHelper.spec_tally_done?('app_setup')
    put_now 'Already done app_setup'
    ENV['SKIP_APP_SETUP'] = 'true'
  end
end

put_now 'Require webmock'
require 'webmock/rspec'
# Enable or disable WebMock allowing requests to external resources.
# Generally, when preparing new stubs, call SetupHelper.get_webmock_responses
# at the top of a spec module (in before :all) to get full information on
# the requirements of each stub.

if ENV['WEBMOCK_NET_CONNECT'] == 'allow'
  WebMock.allow_net_connect!
else
  WebMock.disable_net_connect!(allow_localhost: true)
end

put_now 'Browser setups'

# The setting for AllowUsersToRegister is forced to *true* for the test environment, to allow system tests to work.
# We set this back to false here, which does not affect those tests, but allows controllers, models, etc specs to
# run without AllowUsersToRegister being set.
change_setting('AllowUsersToRegister', false)

require 'capybara/rspec'
require 'browser_helper'
include BrowserHelper

setup_browser unless ENV['SKIP_BROWSER_SETUP']
SetupHelper.clean_conflicting_activity_logs
SetupHelper.setup_nfs_directories
SetupHelper.clean_app_migrations_dirs

put_now 'Devise and warden'
require 'devise'
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
SetupHelper.check_bhs_assignments_table
unless ENV['SKIP_DB_SETUP']
  SetupHelper.setup_full_test_db
  SetupHelper.create_view_activity_labels
end

unless ENV['SKIP_FS_SETUP']
  put_now 'Filestore mount'

  res = `#{Rails.root}/app-scripts/setup-dev-filestore.sh`
  if res != "mountpoint OK\n"
    put_now res
    put_now 'Run app-scripts/setup-dev-filestore.sh and try again'
    exit
  end
end

put_now 'Require essential support files'
require "#{Rails.root}/spec/support/master_support.rb" unless defined? MasterSupport
require "#{Rails.root}/spec/support/model_support.rb" unless defined? ModelSupport
put_now 'Require all support files'
Dir[Rails.root.join('spec/support/*.rb')].sort.each { |f| require f }
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }
Dir[Rails.root.join('spec/support/apps/*/*.rb')].sort.each { |f| require f }
SetupHelper.check_bhs_assignments_table

SetupHelper.run_test_migrations unless ENV['SKIP_DB_SETUP']

if ENV['RUN_APP_SPECS'] == 'true' && !ENV.fetch('SKIP_APP_SETUP', nil)
  put_now 'Run extra app setups'
  SetupHelper.run_extra_setups
end

put_now 'RSpec configure'

RSpec.configure do |config|
  config.before(:suite) do
    SetupHelper.check_bhs_assignments_table
    SetupHelper.clear_delayed_job
    SetupHelper.setup_template_user
    SetupHelper.reload_configs

    # Skip app setups with an env variable
    SetupHelper.full_app_setup unless ENV['SKIP_APP_SETUP']
    put_now 'load_tasks'
    Rails.application.load_tasks
    put_now 'Precompile assets'
    if ENV['JS_SETUP'] || !(ENV['SKIP_ASSETS'] || ENV.fetch('SKIP_APP_SETUP', nil))
      Rake::Task['assets:precompile'].invoke
    end
    put_now 'Done before suite'
  end

  put_now 'Fixtures'
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = ["#{Rails.root}/spec/fixtures"]

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

  config.exclude_pattern = 'spec/system/apps/**/*_spec.rb' unless ENV['RUN_APP_SPECS'] == 'true'

  # removed Devise::TestHelpers from the following line, since it is now deprecated.
  # Using Devise::Test::ControllerHelpers as advised
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.extend ControllerMacros, type: :controller
  config.after :each do
    Warden.test_reset!
  end

  # For system tests that need javascript, use selenium_chrome
  # The following avoids this needing to be specified in each spec file
  # The js: true metadata is also set to true to ensure proper handling
  config.before(:each, type: :system, js: true) do |example|
    driven_by $browser_driver
    Capybara.page.driver.browser.manage.window.maximize
    example.metadata[:js] = true
  end

  config.before(:each) do
    SetupHelper.raise_if_stale_instance_variables!(instance_variables)
  end

  # Set a default before(:all) for system tests setup consistent app settings.
  config.before(:all, type: :system) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', false)
    change_setting('AllowDynamicMigrations', true)
  end

  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
end
