ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# Skip bootsnap for parallel test workers to avoid frozen array issues with Ruby 3.4
# TEST_ENV_NUMBER is only set in forked parallel test workers
if ENV['TEST_ENV_NUMBER'].nil? || ENV['RAILS_ENV'] != 'test'
  require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
end
