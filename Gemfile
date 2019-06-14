source 'https://rubygems.org'


gem 'rails', '~> 4.2.10'
gem 'pg', '~> 0.15'

gem 'jquery-rails'

gem 'devise', '>= 4.6.1'
gem 'strong_password', '~> 0.0.5'

gem 'simple_token_authentication', '~> 1.0', git: 'https://github.com/philayres/simple_token_authentication.git'

gem 'dalli'

gem 'country_select'

gem 'syslog-logger'

#  explicitly remove sdoc since it is holding back JSON, which needs to be upgraded due to a CVE
# group :doc do
#   gem 'sdoc', '~> 0.4.0', group: :doc
# end

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

gem 'aws-sdk-sns'
gem 'aws-sdk-cloudwatchlogs'

gem 'crass', '~> 1.0.4'

# gem 'kramdown'

group :development do

  gem 'web-console', '~> 2.0'


end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  gem 'rspec-rails', '~> 3.0'

  gem 'webrick'

  gem "brakeman", :require => false
  gem "bundler-audit"


  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

end

group :test do
  gem 'capybara', '~> 2.18'
  gem 'selenium-webdriver', '3.4.4'
  gem 'database_cleaner'
  gem 'simplecov', :require => false
  gem 'test_after_commit'
end

group :assets do
  gem 'therubyracer'
  gem 'sass-rails', '~> 5.0'
  gem 'uglifier', '>= 1.3.0'
end
