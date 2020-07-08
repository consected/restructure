# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rails', '~> 5.0'
gem 'pg', '~> 0.15'
gem 'jquery-rails'
gem 'devise', '>= 4.6.1'
gem 'strong_password', '~> 0.0.5'
gem 'simple_token_authentication', '~> 1.0', git: 'https://github.com/philayres/simple_token_authentication.git'
gem 'dalli'
gem 'country_select'
gem 'syslog-logger'
gem 'dicom'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'delayed_job_recurring'
gem 'daemons'
gem 'jquery-fileupload-rails', '0.4.7'
gem 'rubyzip'
gem 'devise-two-factor'
gem 'rqrcode'
gem 'activerecord-import'
gem 'mime-types'
gem 'aws-sdk-sns', '~> 1'
gem 'aws-sdk-cloudwatchlogs', '~> 1'
gem 'aws-sdk-pinpoint', '~> 1'
gem 'aws-sdk-s3', '~> 1'
gem 'crass', '~> 1.0.4'
gem 'kramdown'

group :development do
  gem 'listen'
  gem 'web-console'
end

group :development, :test, :ipa_test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'brakeman', require: false
  gem 'bundler-audit'
  gem 'byebug'
  gem 'debase'
  gem 'jasmine-rails'
  gem 'parallel_tests'
  gem 'puma'
  gem 'rspec-rails'
  gem 'ruby-debug-ide'
  gem 'spring'
  gem 'spring-commands-parallel-tests'
end

group :test do
  gem 'capybara', '~> 2.18'
  gem 'database_cleaner'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver', '3.4.4'
  gem 'simplecov'
  gem 'simplecov-console'
end

group :assets do
  gem 'therubyracer'
  gem 'sass-rails', '~> 5.0'
  gem 'uglifier', '>= 1.3.0'
end
