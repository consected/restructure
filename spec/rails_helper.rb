# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
ENV['FPHS_ADMIN_SETUP']='yes'
require 'simplecov'
SimpleCov.start 'rails'

require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rspec'
require 'devise'

ENV['LANGUAGE']='en_US:en'
ENV['LC_TIME']='en_US.UTF-8'
ENV['LC_NAME']='en_US.UTF-8'
ENV['LC_LANG']='en_US.UTF-8'
ENV['LANG']='en_US.UTF-8'

unless ENV['NOT_HEADLESS']
  ENV['DISPLAY']=':99'
  if `pgrep Xvfb`.blank?
    puts "Running new Xvfb headless X server"
    `Xvfb +extension RANDR :99 -screen 0 1600x1200x16 &`
    `sleep 5; x11vnc -display $DISPLAY -bg -nopw -listen localhost -xkb  -rfbport 5901`
  end
  puts "Xvfb headless X server is running"
end

cb = Capybara

cb.register_driver :app_firefox_driver do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['browser.download.dir'] = "~/Downloads"
  profile['browser.download.folderList'] = 2
  profile['browser.helperApps.alwaysAsk.force'] = false
  profile['browser.download.manager.showWhenStarting'] = false
  profile['browser.helperApps.neverAsk.saveToDisk'] = "text/csv"
  profile['csvjs.disabled'] = true
  Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => profile)
end

cb.current_driver = :app_firefox_driver
cb.default_max_wait_time = 25


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
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
require "#{::Rails.root}/spec/support/master_support.rb"
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|

  config.before(:suite) do
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
