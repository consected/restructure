source 'https://rubygems.org'


gem 'rails', '4.2.9'
gem 'pg', '~> 0.15'

gem 'jquery-rails'

gem 'devise'

gem 'dalli'

gem 'country_select'

gem 'syslog-logger'

#  explicitly remove sdoc since it is holding back JSON, which needs to be upgraded due to a CVE
# group :doc do
#   gem 'sdoc', '~> 0.4.0', group: :doc
# end

gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'daemons'


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
  gem 'capybara'
  gem 'selenium-webdriver', '3.4.4'
  gem 'database_cleaner'
  gem 'simplecov', :require => false
end

group :assets do
  gem 'therubyracer'
  gem 'sass-rails', '~> 5.0'
  gem 'uglifier', '>= 1.3.0'
end
