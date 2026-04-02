# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for top-level _constants options.
    # Extracted from ExtraOptions.parse_config
    #
    # Stores user-defined constant key-value pairs available for
    # runtime {{constants.name}} template substitutions.
    # All keys are valid — no recognized-key restriction since
    # constants are user-defined arbitrary names.
    class Constants < BaseConfiguration
    end
  end
end
