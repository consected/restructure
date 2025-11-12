module OptionConfigs
  class ExternalIdentifierOptions < ExtraOptions
    def self.set_defaults(config_obj, all_options = {})
      dotn = config_obj.default_option_type_name
      all_options[dotn] ||= {}
      all_options[dotn][:fields] ||= config_obj.all_implementation_fields

      never_show = config_obj.pregenerate_ids || config_obj.prevent_edit
      return unless never_show

      id_field = config_obj.external_id_attribute.to_sym
      all_options[dotn][:show_if] ||= {}
      all_options[dotn][:show_if][id_field] ||= {
        never: never_show
      }
    end

    def self.raise_bad_configs(option_configs)
      # None defined - override with real checks
      # @todo
    end
  end
end
