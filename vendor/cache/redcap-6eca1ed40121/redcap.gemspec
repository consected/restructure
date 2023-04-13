# -*- encoding: utf-8 -*-
# stub: redcap 0.3.5 ruby lib

Gem::Specification.new do |s|
  s.name = "redcap".freeze
  s.version = "0.3.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "TODO: Set to 'http://mygemserver.com'" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Peter Clark".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-01-19"
  s.description = "REDCap is a mature, secure web application for building and managing online surveys and databases. The redcap ruby gem allows programmatic access to a REDCap installation via the API using the ruby programming language.".freeze
  s.email = ["peter@5clarks.net".freeze]
  s.files = [".env.sample".freeze, ".gitignore".freeze, ".travis.yml".freeze, "Gemfile".freeze, "LICENSE".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "bin/console".freeze, "bin/setup".freeze, "lib/redcap.rb".freeze, "lib/redcap/configuration.rb".freeze, "lib/redcap/record.rb".freeze, "lib/redcap/version.rb".freeze, "redcap.gemspec".freeze]
  s.homepage = "https://github.com/peterclark/redcap".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "A Ruby gem for interacting with the REDCap API".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<dotenv>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<hashie>.freeze, ["~> 3.4.6"])
    s.add_runtime_dependency(%q<json>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<memoist>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<rest-client>.freeze, [">= 0"])
    s.add_development_dependency(%q<awesome_print>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 2.1"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
  else
    s.add_dependency(%q<dotenv>.freeze, [">= 0"])
    s.add_dependency(%q<hashie>.freeze, ["~> 3.4.6"])
    s.add_dependency(%q<json>.freeze, [">= 0"])
    s.add_dependency(%q<memoist>.freeze, [">= 0"])
    s.add_dependency(%q<rest-client>.freeze, [">= 0"])
    s.add_dependency(%q<awesome_print>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 2.1"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
  end
end
