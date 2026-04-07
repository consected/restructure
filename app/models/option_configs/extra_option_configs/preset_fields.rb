# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for preset field values.
    # Schema docs: docs/admin_reference/general/preset_fields.md
    # Extracted from ExtraOptions#clean_preset_fields
    #
    # Values are preset values (strings, hashes, or arrays) keyed by field name.
    class PresetFields < BaseConfiguration
      # No special processing needed — values stored directly
    end
  end
end
