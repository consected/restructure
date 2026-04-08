# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Configuration class for field labels.
    # Schema docs: docs/admin_reference/general/labels.md
    # Extracted from ExtraOptions#clean_labels_def
    #
    # Values are plain strings keyed by field name.
    # No NamedConfiguration needed — values are simple strings.
    class Labels < BaseConfiguration
      value_pattern :label_string,
                    description: 'Display label string',
                    match: String

      validate :validate_field_key_names
      validate :validate_value_patterns
    end
  end
end
