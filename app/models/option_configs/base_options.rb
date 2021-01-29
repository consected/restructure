module OptionConfigs
  class BaseOptions
    include ActiveModel::Validations

    def self.raise_bad_configs(option_configs)
      # None defined - override with real checks
      # @todo
    end

    def self.top_level_defs
      ''
    end

    def self.attr_defs
      ''
    end

    # Get an array of ConfigLibrary objects from the options text
    def self.config_libraries(config_obj)
      c = config_obj.options_text.dup
      return [] unless c.present?

      format = config_obj.is_a?(Report) ? :sql : :yaml

      Admin::ConfigLibrary.make_substitutions! c, format
    end
  end
end
