# frozen_string_literal: true

module OptionConfigs
  #
  # Definition of the model generator configuration, typically for defining fields.
  # These become accessible in a Imports::ModelGenerator instance as:
  #   model_generator.generator_config
  class ImportModelGeneratorConfigs
    include OptionsHandler

    configure_hash :fields, with: %i[type label caption comment no_downcase]
    configure :data_dictionary, with: %i[study source_name source_type domain form_name]
    configure :options, with: %i[table_comment]

    #
    # Set up the fields configuration from the CSV field types hash
    # @param [Hash] field_types
    def setup_fields_config(field_types)
      f = {
        fields: {}
      }
      field_types.each do |name, field_type|
        f[:fields][name] ||= {}
        f[:fields][name].merge! type: field_type
      end

      setup_options_hash(f, :fields)
    end

    def setup_defaults
      options.table_comment ||= owner.name
    end

    #
    # Set up the field types hash from the persisted configuration
    # @param [Hash] field_types
    def setup_field_types_from_config(field_types)
      fields.each do |name, field|
        field_types[name] = field.type.to_sym
      end
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
