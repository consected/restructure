# -*- encoding: utf-8 -*-
# stub: jquery-fileupload-rails 0.4.7 ruby lib

Gem::Specification.new do |s|
  s.name = "jquery-fileupload-rails".freeze
  s.version = "0.4.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tors Dalid".freeze]
  s.date = "2016-06-15"
  s.description = "jQuery File Upload by Sebastian Tschan integrated for Rails 3.1+ Asset Pipeline".freeze
  s.email = ["cletedalid@gmail.com".freeze]
  s.homepage = "https://github.com/tors/jquery-fileupload-rails".freeze
  s.rubyforge_project = "jquery-fileupload-rails".freeze
  s.rubygems_version = "2.6.14.1".freeze
  s.summary = "jQuery File Upload for Rails 3.1+ Asset Pipeline".freeze

  s.installed_by_version = "2.6.14.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>.freeze, [">= 3.1"])
      s.add_runtime_dependency(%q<actionpack>.freeze, [">= 3.1"])
      s.add_development_dependency(%q<rails>.freeze, [">= 3.1"])
      s.add_runtime_dependency(%q<sass>.freeze, [">= 3.2"])
    else
      s.add_dependency(%q<railties>.freeze, [">= 3.1"])
      s.add_dependency(%q<actionpack>.freeze, [">= 3.1"])
      s.add_dependency(%q<rails>.freeze, [">= 3.1"])
      s.add_dependency(%q<sass>.freeze, [">= 3.2"])
    end
  else
    s.add_dependency(%q<railties>.freeze, [">= 3.1"])
    s.add_dependency(%q<actionpack>.freeze, [">= 3.1"])
    s.add_dependency(%q<rails>.freeze, [">= 3.1"])
    s.add_dependency(%q<sass>.freeze, [">= 3.2"])
  end
end
