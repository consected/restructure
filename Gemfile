# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activerecord-import'
gem 'activerecord-session_store'
gem 'aws-sdk-cloudwatchlogs', '~> 1'
gem 'aws-sdk-pinpoint', '~> 1'
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sdk-sns', '~> 1'
gem 'country_select'
gem 'crass', '~> 1.0.4'
gem 'daemons'
gem 'dalli'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'delayed_job_recurring'
gem 'devise', '>= 4.6.1'
gem 'devise-two-factor'
gem 'dicom'
gem 'jquery-fileupload-rails', '0.4.7'
gem 'jquery-rails'
gem 'kramdown'
gem 'kramdown-parser-gfm'
gem 'mime-types'
gem 'nokogiri', '1.13.6'
gem 'pg' # , '~> 0.15'

# puma has been moved to all environments and will be included in the production packaging
# this allows EB to run with the latest version of puma, without breaking if the preinstalled version
# is lower or has different dependencies.
# For this to work, Procfile must call puma with `bundle exec`
gem 'puma'

gem 'rails', '~> 5.0'
gem 'redcap', git: 'https://github.com/consected/redcap.git'
# for development, replace with with:
# gem 'redcap', path: '../redcap'
gem 'rqrcode'
gem 'rubyzip'
gem 'simple_token_authentication', '~> 1.0', git: 'https://github.com/philayres/simple_token_authentication.git'
gem 'strong_password', '~> 0.0.5'
gem 'syslog-logger'

group :development do
  gem 'flog'
  gem 'listen'
  # gem 'memory_profiler'
  # gem 'rack-mini-profiler'
  gem 'solargraph'
  gem 'solargraph-rails', '~> 0.2.0'
  gem 'web-console'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'brakeman', require: false
  gem 'bundler-audit'
  gem 'byebug'
  gem 'debase'
  gem 'jasmine-rails'
  gem 'parallel_tests', '3.8.1'
  gem 'readapt'
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
  gem 'shoulda-matchers', '~> 5.1'
  gem 'simplecov'
  gem 'simplecov-console'
  gem 'spring-commands-rspec'
  gem 'webmock'
end

group :development, :production, :assets do
  gem 'execjs'
  gem 'sass-rails', '~> 5.1'
  gem 'therubyracer'
  gem 'uglifier', '>= 1.3.0'
end
