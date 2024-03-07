# frozen_string_literal: true

def put_now(msg)
  puts "#{Time.now} #{msg}"
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
  ENV['SKIP_BROWSER_SETUP'] = 'true'
  ENV['SKIP_DB_SETUP'] = 'true'
  ENV['SKIP_APP_SETUP'] = 'true'
else
  put_now 'check_spec_db for skips'
  # Use a database table to track creations in the test db
  res = SetupHelper.check_spec_db
  names = res.map { |r| r['name'] }
  ENV['SKIP_DB_SETUP'] = 'true' if names.include?('db_setup')
  ENV['SKIP_APP_SETUP'] = 'true' if names.include?('app_setup')
end

put_now 'Require webmock'
require 'webmock/rspec'
# Enable or disable WebMock allowing requests to external resources.
# Generally, when preparing new stubs, call SetupHelper.get_webmock_responses
# at the top of a spec module (in before :all) to get full information on
# the requirements of each stub.

# WebMock.allow_net_connect!
WebMock.disable_net_connect!(allow_localhost: true)

put_now 'Browser setups'

# The setting for AllowUsersToRegister is forced to *true* for the test environment, to allow features tests to work.
# We set this back to false here, which does not affect those tests, but allows controllers, models, etc specs to
# run without AllowUsersToRegister being set.
change_setting('AllowUsersToRegister', false)

require 'capybara/rspec'
require 'browser_helper'
include BrowserHelper

setup_browser unless ENV['SKIP_BROWSER_SETUP']
SetupHelper.clean_conflicting_activity_logs
SetupHelper.setup_nfs_directories

`mkdir -p db/app_migrations/redcap_test; rm -f db/app_migrations/redcap_test/*test_*.rb`
`mkdir -p db/app_migrations/imports_test; rm -f db/app_migrations/imports_test/*test_imports*.rb`
`mkdir -p db/app_migrations/dynamic_test; rm -f db/app_migrations/dynamic_test/*test_imports*.rb`
`rm -f db/app_migrations/test/*test_*.rb`

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
SetupHelper.setup_full_test_db unless ENV['SKIP_DB_SETUP']

unless ENV['SKIP_FS_SETUP']
  put_now 'Filestore mount'

  res = `#{::Rails.root}/app-scripts/setup-dev-filestore.sh`
  if res != "mountpoint OK\n"
    put_now res
    put_now 'Run app-scripts/setup-dev-filestore.sh and try again'
    exit
  end
end

SetupHelper.check_bhs_assignments_table

put_now 'Require more'
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
require "#{::Rails.root}/spec/support/master_support.rb"
require "#{::Rails.root}/spec/support/model_support.rb"
SetupHelper.check_bhs_assignments_table
Dir[Rails.root.join('spec/support/*.rb')].sort.each { |f| require f }
Dir[Rails.root.join('spec/support/*/*.rb')].sort.each { |f| require f }
SetupHelper.check_bhs_assignments_table
unless ENV['SKIP_DB_SETUP']
  # Checks for pending migrations before tests are run.
  # If you are not using ActiveRecord, you can remove this line.
  put_now 'Enforce migrations'
  # ActiveRecord::Migration.maintain_test_schema!

  SetupHelper.check_bhs_assignments_table

  sql = <<~END_SQL
    DROP SCHEMA IF EXISTS redcap_test CASCADE;
    CREATE SCHEMA redcap_test;
    DROP SCHEMA IF EXISTS dynamic_test CASCADE;
    CREATE SCHEMA dynamic_test;

    -- Clean up the migrations that need to be rerun in redcap-test
    delete from schema_migrations where version in (
      '20211105105700',
      '20211105105701',
      '20211105105702',
      '20210215184600',
      '20210215184601',
      '20210305184601',
      '20211101051705'
    );
  END_SQL

  ActiveRecord::Base.connection.execute sql

  SetupHelper.check_bhs_assignments_table
  # We need to ensure that dynamic tables are in place before we setup dynamic models
  # in each example, otherwise the tests lock up.
  db_migration_dirname = Rails.root.join('spec/migrations')
  Admin::MigrationGenerator.migration_context(db_migration_dirname).migrate
  SetupHelper.check_bhs_assignments_table
  puts "Exists test_file_field_recs? > #{ActiveRecord::Base.connection.table_exists?('test_file_field_recs')}"
end

RSpec.configure do |config|
  config.before(:suite) do
    SetupHelper.check_bhs_assignments_table

    # Do some setup that could impact all tests through the availability of master associations
    SetupHelper.clear_delayed_job

    require "#{::Rails.root}/db/seeds.rb" unless User.active.find_by(email: Settings::TemplateUserEmail)
    tu = User.find_by(email: Settings::TemplateUserEmail)
    Seeds::BUsers.setup if tu.nil?

    Rails.cache.clear
    SetupHelper.reload_configs

    # Skip app setups with an env variable
    unless ENV['SKIP_APP_SETUP']
      SetupHelper.check_bhs_assignments_table

      put_now 'Setup apps'
      sql = "SELECT pg_catalog.setval('ml_app.app_types_id_seq', (select max(id)+1 from ml_app.app_types), true);"
      ActiveRecord::Base.connection.execute sql
      put_now 'Setup ActivityLogPlayerContactPhone'
      SetupHelper.setup_al_player_contact_phones
      # Seeds::ActivityLogPlayerContactPhone.setup
      put_now 'setup_al_player_contact_emails'
      SetupHelper.setup_al_player_contact_emails
      put_now 'Setup ext_identifier'
      SetupHelper.setup_ext_identifier
      put_now 'setup_test_app'
      SetupHelper.setup_test_app
      SetupHelper.check_bhs_assignments_table true

      raise FphsException, 'bhs_assignment not set up' unless Resources::Models.find_by resource_name: 'bhs_assignments'

      put_now 'setup_ref_data_app'
      SetupHelper.setup_ref_data_app

      put_now 'Handle zeus_bulk_message'
      als = ActivityLog.active.where(item_type: 'zeus_bulk_message')
      als.each do |a|
        a.update! current_admin: a.admin, disabled: true if a.enabled?
      end

      SetupHelper.add_to_spec_db('app_setup')
    end
    put_now 'load_tasks'
    Rails.application.load_tasks
    put_now 'Precompile assets'
    Rake::Task['assets:precompile'].invoke if ENV['JS_SETUP'] || !(ENV['SKIP_ASSETS'] || ENV['SKIP_APP_SETUP'])
    put_now 'Done before suite'
  end

  put_now 'Fixtures'
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
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.extend ControllerMacros, type: :controller
  config.after :each do
    Warden.test_reset!
  end

  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
end
