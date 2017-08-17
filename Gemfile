source 'https://rubygems.org'


gem 'rails', '4.2.9'
gem 'pg', '~> 0.15'

gem 'jquery-rails'

gem 'devise'

gem 'dalli'

gem 'country_select'

gem 'syslog-logger'

group :doc do
  gem 'sdoc', '~> 0.4.0', group: :doc
end

group :development do

  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  
  gem 'rspec-rails', '~> 3.0'
  
  gem 'webrick'
  
  gem "brakeman", :require => false
  gem "bundler-audit"
  
  
  gem 'sass-rails', '~> 5.0'
  gem 'uglifier', '>= 1.3.0'
  
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'simplecov', :require => false
end

group :production do
  #gem 'passenger'
end
