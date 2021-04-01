# frozen_string_literal: true

module OptionConfigs
  #
  # Definition of the model generator configuration, typically for defining fields.
  # These become accessible in a Imports::ModelGenerator instance as:
  #   model_generator.generator_config
  class ImportModelGeneratorConfigs
    include OptionsHandler

    # Fields hash of FieldConfiguration
    configure_hash :fields, with: %i[name type label caption comment]

    #
    # Set up the fields configuration from the CSV field types hash
    # @param [Hash] field_types
    def setup_fields_config(field_types)
      f = {
        fields: {}
      }
      field_types.each do |name, field_type|
        f[:fields][name] ||= {}
        f[:fields][name].merge! name: name.to_s, type: field_type
      end

      setup_options_hash(f, :fields)
    end

    #
    # The persisted configuration YAML (or JSON) in the report definition record
    # @return [String]
    def config_text
      owner.options
    end

    def config_text=(value)
      owner.options = value
    end

    def valid?
      hash_configuration
      true
    rescue StandardError => e
      errors << "Invalid: #{e}"
      nil
    end

    def persisted?
      owner.persisted?
    end
  end
end
