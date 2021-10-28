# frozen_string_literal: true

module Dynamic
  #
  # Represents the definition of a field in a dynamic model,
  # used by the data dictionary to generate DatadicVariable records
  class DynamicModelField
    # data to variable types
    DatabaseTypesToVariableTypes = {
      boolean: 'dichotomous',
      integer: 'integer',
      decimal: 'numeric',
      float: 'numeric',
      date: 'date',
      timestamp: 'date time',
      time: 'time',
      string: 'plain text'
    }.freeze

    MatchingAttribs = %i[name label_plain label_note_plain annotation is_required
                         valid_type valid_min valid_max is_identifier
                         owner field_type field_choices_plain_text
                         source_name checkbox_choice_fields
                         storage_type db_or_fs schema_or_path table_or_file
                         position section sub_section title_plain domain form_name study
                         source_type is_derived_var owner_email presentation_type
                         default_variable_type].freeze

    attr_accessor :position, :name, :dynamic_model, :data_dictionary, *MatchingAttribs

    #
    # Initializes a data dictionary variable ready for storage
    # This overrides #initialize in Dynamic::DatadicVariableHandler
    # to "cheat", rather than using an intermediate Field class.
    # @param [<Type>] data_dictionary <description>
    # @param [<Type>] name <description>
    # @param [<Type>] field_type <description>
    # @param [<Type>] position <description>
    def initialize(data_dictionary, name, field_type, position: nil)
      self.data_dictionary = data_dictionary
      self.dynamic_model = data_dictionary.dynamic_model
      self.name = name.to_sym
      self.field_type = field_type
      self.position = position
      self.field_type = :integer if field_type == :references

      set_from_default_config
      set_label_config
      override_with_field_config
    end

    def default_options
      dynamic_model.default_options
    end

    #
    # Quick way to get the field presentation field_type
    # @return [String]
    def presentation_type
      DatabaseTypesToVariableTypes[field_type]
    end

    #
    # Quick way to get the default variable field_type for fields
    # @return [String]
    def default_variable_type
      'plain text'
    end

    def to_s
      name.to_s
    end

    def owner
      dynamic_model
    end

    #
    # Refresh variable records (Datadic::Variable) based on
    # current definition.
    def refresh_variable_record
      DatadicVariable.new(self).refresh_variable_record
    end

    #
    # Set the default values for this variable.
    # @see Dynamic::DataDictionary#default_config
    def set_from_default_config
      MatchingAttribs.each do |k|
        next unless data_dictionary.default_config.key?(k)

        v = data_dictionary.default_config[k]
        send("#{k}=", v)
      end
    end

    #
    # Set the field config, using matching attributes in underlying data
    # and configurations from the dynamic model
    # Set the label, from one of the dynamic model configs for this field
    # The first existing config for the options configuration
    # - default: caption_before:
    # - _comments: fields:
    # - default: labels:
    def set_label_config
      fcs = dynamic_model.table_comments || {}
      fcs = fcs[:original_fields] || {}
      dmc = default_options.caption_before || {}
      dml = default_options.labels || {}
      self.label_plain = dmc.dig(name, :caption) || fcs[name] || dml[name]
    end

    #
    # Override any configurations with field configs set within the
    # options _data_dictionary: fields: name: attributes...
    def override_with_field_config
      dddd = data_dictionary.dynamic_model_data_dictionary_config
      field_defs = dddd[:fields]
      return unless field_defs

      MatchingAttribs.each do |k|
        fconf = field_defs[name]
        next unless fconf&.key?(k)

        v = fconf[k]
        send("#{k}=", v)
      end
    end
  end
end
