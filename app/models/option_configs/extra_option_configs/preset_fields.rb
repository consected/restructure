# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for preset field values.
    # Schema docs: docs/admin_reference/general/preset_fields.md
    # Extracted from ExtraOptions#clean_preset_fields
    #
    # Values are preset values (strings, hashes, or arrays) keyed by field name.
    # `with_result` and `with` are top-level directives for attribute-mapping from
    # related items — they are not field names and must be explicitly allowed.
    class PresetFields < BaseConfiguration
      extra_keys :with_result, :with

      validate :validate_field_key_names
    end
  end
end
