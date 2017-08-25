ENV['RAILS_ENV'] ||= 'test'
ENV['FPHS_ADMIN_SETUP']='yes'

Rails.application.load_tasks
Rake::Task["assets:precompile"].invoke

require "#{::Rails.root}/spec/support/master_support.rb"
require "#{::Rails.root}/spec/support/master_data_support.rb"
require "#{::Rails.root}/spec/support/model_support.rb"
require "#{::Rails.root}/spec/support/feature_support.rb"
require "#{::Rails.root}/spec/support/controller_macros.rb"


require "#{::Rails.root}/features/support/setup_support"
#Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }


include FeatureSupport


