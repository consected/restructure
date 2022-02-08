module OptionConfigs
  class ExternalIdentifierOptions < ExtraOptions
    def self.set_defaults(config_obj, all_options = {})
      all_options[:default] ||= {}
      all_options[:default][:fields] ||= config_obj.all_implementation_fields

      never_show = config_obj.pregenerate_ids || config_obj.prevent_edit
      return unless never_show

      id_field = config_obj.external_id_attribute.to_sym
      all_options[:default][:show_if] ||= {}
      all_options[:default][:show_if][id_field] ||= {
        never: never_show
      }
    end

    def self.raise_bad_configs(option_configs)
      # None defined - override with real checks
      # @todo
    end
  end
end
