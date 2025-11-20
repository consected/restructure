module OptionConfigs
  class DynamicModelOptions < ExtraOptions
    def self.set_defaults(config_obj, all_options = {})
      dotn = config_obj.default_option_type_name
      all_options[dotn] ||= {}
      all_options[dotn][:fields] ||= config_obj.all_implementation_fields
    end

    def self.raise_bad_configs(option_configs)
      # None defined - override with real checks
      # @todo
    end
  end
end
