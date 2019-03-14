# -*- encoding: utf-8 -*-
# stub: simple_token_authentication 1.16.1 ruby lib

Gem::Specification.new do |s|
  s.name = "simple_token_authentication".freeze
  s.version = "1.16.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gonzalo Bulnes Guilpain".freeze]
  s.date = "2019-03-14"
  s.email = ["gon.bulnes@gmail.com".freeze]
  s.files = ["Appraisals".freeze, "CHANGELOG.md".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "doc/README.md".freeze, "gemfiles/rails_4_devise_3.gemfile".freeze, "gemfiles/rails_5_devise_4.gemfile".freeze, "gemfiles/ruby_1.9.3_rails_3.2.gemfile".freeze, "lib/simple_token_authentication".freeze, "lib/simple_token_authentication.rb".freeze, "lib/simple_token_authentication/acts_as_token_authenticatable.rb".freeze, "lib/simple_token_authentication/acts_as_token_authentication_handler.rb".freeze, "lib/simple_token_authentication/adapter.rb".freeze, "lib/simple_token_authentication/adapters".freeze, "lib/simple_token_authentication/adapters/active_record_adapter.rb".freeze, "lib/simple_token_authentication/adapters/mongoid_adapter.rb".freeze, "lib/simple_token_authentication/adapters/rails_adapter.rb".freeze, "lib/simple_token_authentication/adapters/rails_api_adapter.rb".freeze, "lib/simple_token_authentication/adapters/rails_metal_adapter.rb".freeze, "lib/simple_token_authentication/cache.rb".freeze, "lib/simple_token_authentication/caches".freeze, "lib/simple_token_authentication/caches/dalli_provider.rb".freeze, "lib/simple_token_authentication/caches/rails_cache_provider.rb".freeze, "lib/simple_token_authentication/configuration.rb".freeze, "lib/simple_token_authentication/devise_fallback_handler.rb".freeze, "lib/simple_token_authentication/entities_manager.rb".freeze, "lib/simple_token_authentication/entity.rb".freeze, "lib/simple_token_authentication/errors.rb".freeze, "lib/simple_token_authentication/exception_fallback_handler.rb".freeze, "lib/simple_token_authentication/sign_in_handler.rb".freeze, "lib/simple_token_authentication/token_authenticatable.rb".freeze, "lib/simple_token_authentication/token_authentication_handler.rb".freeze, "lib/simple_token_authentication/token_comparator.rb".freeze, "lib/simple_token_authentication/token_generator.rb".freeze, "lib/simple_token_authentication/version.rb".freeze, "spec/configuration".freeze, "spec/configuration/action_controller_callbacks_options_spec.rb".freeze, "spec/configuration/fallback_to_devise_option_spec.rb".freeze, "spec/configuration/header_names_option_spec.rb".freeze, "spec/configuration/sign_in_token_option_spec.rb".freeze, "spec/configuration/skip_devise_trackable_option_spec.rb".freeze, "spec/lib".freeze, "spec/lib/simple_token_authentication".freeze, "spec/lib/simple_token_authentication/acts_as_token_authenticatable_spec.rb".freeze, "spec/lib/simple_token_authentication/acts_as_token_authentication_handler_spec.rb".freeze, "spec/lib/simple_token_authentication/adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/adapters".freeze, "spec/lib/simple_token_authentication/adapters/active_record_adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/adapters/mongoid_adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/adapters/rails_adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/adapters/rails_api_adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/adapters/rails_metal_adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/cache_spec.rb".freeze, "spec/lib/simple_token_authentication/caches".freeze, "spec/lib/simple_token_authentication/caches/dalli_provider_spec.rb".freeze, "spec/lib/simple_token_authentication/caches/rails_cache_provider_spec.rb".freeze, "spec/lib/simple_token_authentication/configuration_spec.rb".freeze, "spec/lib/simple_token_authentication/devise_fallback_handler_spec.rb".freeze, "spec/lib/simple_token_authentication/entities_manager_spec.rb".freeze, "spec/lib/simple_token_authentication/entity_spec.rb".freeze, "spec/lib/simple_token_authentication/errors_spec.rb".freeze, "spec/lib/simple_token_authentication/exception_fallback_handler_spec.rb".freeze, "spec/lib/simple_token_authentication/sign_in_handler_spec.rb".freeze, "spec/lib/simple_token_authentication/test_caching_spec.rb".freeze, "spec/lib/simple_token_authentication/token_authentication_handler_spec.rb".freeze, "spec/lib/simple_token_authentication/token_comparator_spec.rb".freeze, "spec/lib/simple_token_authentication/token_generator_spec.rb".freeze, "spec/lib/simple_token_authentication_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/support/dummy_classes_helper.rb".freeze, "spec/support/spec_for_adapter.rb".freeze, "spec/support/spec_for_authentication_handler_interface.rb".freeze, "spec/support/spec_for_cache.rb".freeze, "spec/support/spec_for_configuration_option_interface.rb".freeze, "spec/support/spec_for_entities_manager_interface.rb".freeze, "spec/support/spec_for_fallback_handler_interface.rb".freeze, "spec/support/spec_for_sign_in_handler_interface.rb".freeze, "spec/support/spec_for_token_comparator_interface.rb".freeze, "spec/support/spec_for_token_generator_interface.rb".freeze, "spec/support/specs_for_token_authentication_handler_interface.rb".freeze]
  s.homepage = "https://github.com/gonzalo-bulnes/simple_token_authentication".freeze
  s.licenses = ["GPL-3.0+".freeze]
  s.rubygems_version = "2.6.14.3".freeze
  s.summary = "Simple (but safe) token authentication for Rails apps or API with Devise.".freeze
  s.test_files = ["spec/configuration".freeze, "spec/configuration/skip_devise_trackable_option_spec.rb".freeze, "spec/configuration/action_controller_callbacks_options_spec.rb".freeze, "spec/configuration/sign_in_token_option_spec.rb".freeze, "spec/configuration/fallback_to_devise_option_spec.rb".freeze, "spec/configuration/header_names_option_spec.rb".freeze, "spec/support/spec_for_configuration_option_interface.rb".freeze, "spec/support/spec_for_sign_in_handler_interface.rb".freeze, "spec/support/spec_for_cache.rb".freeze, "spec/support/spec_for_token_generator_interface.rb".freeze, "spec/support/spec_for_authentication_handler_interface.rb".freeze, "spec/support/spec_for_entities_manager_interface.rb".freeze, "spec/support/spec_for_token_comparator_interface.rb".freeze, "spec/support/dummy_classes_helper.rb".freeze, "spec/support/spec_for_fallback_handler_interface.rb".freeze, "spec/support/spec_for_adapter.rb".freeze, "spec/support/specs_for_token_authentication_handler_interface.rb".freeze, "spec/lib".freeze, "spec/lib/simple_token_authentication_spec.rb".freeze, "spec/lib/simple_token_authentication".freeze, "spec/lib/simple_token_authentication/cache_spec.rb".freeze, "spec/lib/simple_token_authentication/devise_fallback_handler_spec.rb".freeze, "spec/lib/simple_token_authentication/token_generator_spec.rb".freeze, "spec/lib/simple_token_authentication/entity_spec.rb".freeze, "spec/lib/simple_token_authentication/caches".freeze, "spec/lib/simple_token_authentication/caches/dalli_provider_spec.rb".freeze, "spec/lib/simple_token_authentication/caches/rails_cache_provider_spec.rb".freeze, "spec/lib/simple_token_authentication/token_comparator_spec.rb".freeze, "spec/lib/simple_token_authentication/acts_as_token_authentication_handler_spec.rb".freeze, "spec/lib/simple_token_authentication/token_authentication_handler_spec.rb".freeze, "spec/lib/simple_token_authentication/exception_fallback_handler_spec.rb".freeze, "spec/lib/simple_token_authentication/entities_manager_spec.rb".freeze, "spec/lib/simple_token_authentication/sign_in_handler_spec.rb".freeze, "spec/lib/simple_token_authentication/errors_spec.rb".freeze, "spec/lib/simple_token_authentication/adapters".freeze, "spec/lib/simple_token_authentication/adapters/active_record_adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/adapters/rails_api_adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/adapters/mongoid_adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/adapters/rails_adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/adapters/rails_metal_adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/configuration_spec.rb".freeze, "spec/lib/simple_token_authentication/adapter_spec.rb".freeze, "spec/lib/simple_token_authentication/acts_as_token_authenticatable_spec.rb".freeze, "spec/lib/simple_token_authentication/test_caching_spec.rb".freeze, "spec/spec_helper.rb".freeze, "gemfiles/rails_5_devise_4.gemfile".freeze, "gemfiles/ruby_1.9.3_rails_3.2.gemfile".freeze, "gemfiles/rails_4_devise_3.gemfile".freeze, "Appraisals".freeze]

  s.installed_by_version = "2.6.14.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionmailer>.freeze, ["< 6", ">= 3.2.6"])
      s.add_runtime_dependency(%q<actionpack>.freeze, ["< 6", ">= 3.2.6"])
      s.add_runtime_dependency(%q<devise>.freeze, ["< 6", ">= 3.2"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<inch>.freeze, ["~> 0.4"])
      s.add_development_dependency(%q<activerecord>.freeze, ["< 6", ">= 3.2.6"])
      s.add_development_dependency(%q<mongoid>.freeze, ["< 7", ">= 3.1.0"])
      s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.0"])
      s.add_development_dependency(%q<dalli>.freeze, [">= 0"])
      s.add_development_dependency(%q<activesupport>.freeze, [">= 0"])
    else
      s.add_dependency(%q<actionmailer>.freeze, ["< 6", ">= 3.2.6"])
      s.add_dependency(%q<actionpack>.freeze, ["< 6", ">= 3.2.6"])
      s.add_dependency(%q<devise>.freeze, ["< 6", ">= 3.2"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_dependency(%q<inch>.freeze, ["~> 0.4"])
      s.add_dependency(%q<activerecord>.freeze, ["< 6", ">= 3.2.6"])
      s.add_dependency(%q<mongoid>.freeze, ["< 7", ">= 3.1.0"])
      s.add_dependency(%q<appraisal>.freeze, ["~> 2.0"])
      s.add_dependency(%q<dalli>.freeze, [">= 0"])
      s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<actionmailer>.freeze, ["< 6", ">= 3.2.6"])
    s.add_dependency(%q<actionpack>.freeze, ["< 6", ">= 3.2.6"])
    s.add_dependency(%q<devise>.freeze, ["< 6", ">= 3.2"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<inch>.freeze, ["~> 0.4"])
    s.add_dependency(%q<activerecord>.freeze, ["< 6", ">= 3.2.6"])
    s.add_dependency(%q<mongoid>.freeze, ["< 7", ">= 3.1.0"])
    s.add_dependency(%q<appraisal>.freeze, ["~> 2.0"])
    s.add_dependency(%q<dalli>.freeze, [">= 0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
  end
end
