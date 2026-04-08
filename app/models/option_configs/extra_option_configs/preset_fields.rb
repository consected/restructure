# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for preset field values.
    # Schema docs: docs/admin_reference/general/preset_fields.md
    # Extracted from ExtraOptions#clean_preset_fields
    #
    # Values are preset values (strings, hashes, or arrays) keyed by field name.
    class PresetFields < BaseConfiguration
      validate :validate_field_key_names
    end
  end
end
