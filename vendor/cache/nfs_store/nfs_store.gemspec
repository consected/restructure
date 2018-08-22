$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "nfs_store/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "nfs_store"
  s.version     = NfsStore::VERSION
  s.authors     = ["Phil Ayres"]
  s.email       = ["phil.ayres@consected.com"]
  s.homepage    = "https://footballplayershealth.harvard.edu/"
  s.summary     = "NfsStore for FPHS"
  s.description = "Secure management of health and project files on a network file store."
  s.license     = "Proprietary"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]

  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-fileupload-rails'
  s.add_dependency 'rubyzip'
  s.add_dependency 'activerecord-import'
  s.add_dependency 'mime-types'

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'capybara'

end
