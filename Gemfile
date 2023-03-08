# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activerecord-import'
gem 'activerecord-session_store'
gem 'aws-sdk-cloudwatchlogs', '~> 1'
gem 'aws-sdk-pinpoint', '~> 1'
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sdk-sns', '~> 1'
gem 'bootsnap'
gem 'country_select', '~> 8.0'
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
gem 'mail', '2.7.1' # hold at this version in Rails 2.7 to avoid broken net / protocol gems
gem 'mime-types'
gem 'mini_portile2', '2.8.0' # attempt to fix issue with mini_portile2 not being installed to vendor/cache during build
gem 'nokogiri', '1.13.10'
gem 'pg', '~> 1.4', '>= 1.4.3'

# puma has been moved to all environments and will be included in the production packaging
# this allows EB to run with the latest version of puma, without breaking if the preinstalled version
# is lower or has different dependencies.
# For this to work, Procfile must call puma with `bundle exec`
gem 'puma', '~> 6.0'

gem 'rails', '~> 5.2', '>= 5.2.8.1'
gem 'redcap', git: 'https://github.com/consected/redcap.git'
# for development, replace with with:
# gem 'redcap', path: '../redcap'
gem 'rqrcode'
gem 'rubyzip', '~> 2.3.0'
gem 'simple_token_authentication', '~> 1.0', git: 'https://github.com/philayres/simple_token_authentication.git'
gem 'strong_password', '~> 0.0.5'
gem 'syslog-logger'

group :development do
  gem 'flog', '~> 4.6', '>= 4.6.4'
  gem 'listen', '~> 3.7', '>= 3.7.1'
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
  gem 'byebug', '~> 11.1', '>= 11.1.3'
  gem 'debase'
  gem 'parallel_tests', '3.8.1'
  gem 'readapt'
  gem 'rspec-rails'
  gem 'ruby-debug-ide'
  gem 'spring'
  gem 'spring-commands-parallel-tests'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver', '4.6.1'
  gem 'shoulda-matchers', '~> 5.1'
  gem 'simplecov'
  gem 'simplecov-console'
  gem 'spring-commands-rspec'
  gem 'webmock'
end

group :development, :assets do
  gem 'execjs'
  gem 'sass-rails', '~> 5.1'
  gem 'therubyracer'
  # gem 'mini_racer', github: 'rubyjs/mini_racer', branch: 'refs/pull/186/head'
  gem 'terser'
end
