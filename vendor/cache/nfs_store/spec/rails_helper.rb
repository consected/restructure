require 'spec_helper'
require File.expand_path('../dummy/config/environment', __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rspec'
require 'devise'

require 'browser_helper'
include BrowserHelper
setup_browser

Capybara.server = :webrick
require "./spec/support/model_support.rb"
Dir[Rails.root.join('./spec/support/*.rb')].each { |f| require f }
Dir[Rails.root.join('./spec/support/**/*.rb')].sort.each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!



RSpec.configure do |config|

  config.before(:suite) do
    Rails.application.load_tasks
    # Rake::Task["assets:precompile"].invoke
  end

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
end
