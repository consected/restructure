# frozen_string_literal: true

module Dynamic
  #
  # Store the field definition to a datadic variable
  class DatadicVariable
    MatchingAttribs = %i[name label_plain label_note_plain annotation is_required
                         valid_type valid_min valid_max is_identifier
                         owner field_type field_choices_plain_text
                         source_name checkbox_choice_fields
                         storage_type db_or_fs schema_or_path table_or_file
                         position section sub_section title_plain domain form_name study
                         source_type].freeze

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

    include Dynamic::DatadicVariableHandler

    attr_accessor :name, :dynamic_model, :data_dictionary

    def initialize(data_dictionary, name, field_type, position: nil)
      self.data_dictionary = data_dictionary
      self.dynamic_model = data_dictionary.dynamic_model
      self.name = name.to_sym
      self.field_type = field_type
      self.position = position

      default_data_dictionary_config
      field_config
    end

    def self.owner_identifier
      nil
    end

    def owner
      dynamic_model
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

    def default_data_dictionary_config
      MatchingAttribs.each do |k|
        next unless data_dictionary.source_default_config.key?(k)

        v = data_dictionary.source_default_config[k]
        send("#{k}=", v)
      end
    end

    def field_config
      self.field_type = :integer if field_type == :references

      fcs = dynamic_model.table_comments || {}
      # Comments will be in :original_fields if the config has been processed
      # for saving, or :fields if not
      fcs = fcs[:original_fields] || {}
      dmc = default_options.caption_before || {}
      dml = default_options.labels || {}
      self.label_plain = dmc.dig(name, :caption) || fcs[name] || dml[name]

      dddd = data_dictionary.dynamic_model_data_dictionary_config
      field_defs = dddd[:fields]
      return unless field_defs

      MatchingAttribs.each do |k|
        next unless field_defs.key?(k)

        v = field_defs[k]
        send("#{k}=", v)
      end
    end
  end
end
