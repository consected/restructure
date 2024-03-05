# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Field type functionality for the data dictionaries
    class FieldType
      ValidFieldTypes = %i[
        text
        text_area
        notes
        calc
        dropdown
        radio
        checkbox
        yesno
        truefalse
        file
        slider
        descriptive
      ].freeze

      FieldToVariableTypes = {
        text: 'plain text',
        text_area: 'free text',
        notes: 'free text',
        calc: 'calculated',
        dropdown: 'categorical',
        radio: 'categorical',
        checkbox: 'categorical',
        checkbox_choice: 'dichotomous item', # This is not a real REDCap type, but is used as a lookup
        checkbox_chosen_array: 'categorical array', # This is not a real REDCap type, but is used as a lookup
        yesno: 'dichotomous',
        truefalse: 'dichotomous',
        file: 'file',
        slider: 'integer',
        descriptive: 'fixed caption',
        form_complete: 'redcap status', # This is not a real REDCap type, but is used as a lookup
        form_timestamp: 'redcap completion timestamp', # This is not a real REDCap type, but is used as a lookup
        survey_identifier: 'survey identifier', # This is not a real REDCap type, but is used as a lookup
        repeat: 'repeat instrument' # This is not a real REDCap type, but is used as a lookup
      }.freeze

      TextFieldToVariableTypes = {
        'date_dmy' => 'date',
        'date_mdy' => 'date',
        'date_ymd' => 'date',
        'datetime_dmy' => 'date time',
        'datetime_mdy' => 'date time',
        'datetime_ymd' => 'date time',
        'datetime_seconds_dmy' => 'date time',
        'datetime_seconds_mdy' => 'date time',
        'datetime_seconds_ymd' => 'date time',
        'email' => 'email address',
        'integer' => 'integer',
        'alpha_only' => 'alphabetic',
        'number' => 'numeric',
        'phone' => 'phone',
        'time' => 'time',
        'time_mm_ss' => 'time',
        'zipcode' => 'zipcode'
      }.freeze

      # Map the field type to model edit field types
      # nil indicates default handling
      FieldToModelTypes = {
        text: nil,
        text_area: 'notes',
        notes: 'notes',
        calc: 'fixed',
        dropdown: 'select',
        radio: 'radio',
        checkbox: nil, # boolean
        checkbox_choice: nil, # boolean
        checkbox_chosen_array: 'tag_select_checkbox',
        yesno: 'yes_no',
        truefalse: 'true_false',
        file: 'file',
        slider: nil, # integer
        descriptive: nil,
        form_complete: 'status', # This is not a real REDCap type, but is used as a lookup
        form_timestamp: 'completion_timestamp', # This is not a real REDCap type, but is used as a lookup
        survey_identifier: 'survey_identifier', # This is not a real REDCap type, but is used as a lookup
        repeat: 'repeat_instrument' # This is not a real REDCap type, but is used as a lookup
      }.freeze

      TextFieldToModelTypes = {
        'date_dmy' => nil,
        'date_mdy' => nil,
        'date_ymd' => nil,
        'datetime_dmy' => nil,
        'datetime_mdy' => nil,
        'datetime_ymd' => nil,
        'datetime_seconds_dmy' => nil,
        'datetime_seconds_mdy' => nil,
        'datetime_seconds_ymd' => nil,
        'email' => 'email',
        'integer' => nil,
        'alpha_only' => 'alpha_only',
        'number' => nil,
        'phone' => 'phone',
        'time' => nil,
        'time_mm_ss' => 'time_mm_ss',
        'zipcode' => 'zip'
      }.freeze

      ValidVariableTypes = (FieldToVariableTypes.values + TextFieldToVariableTypes.values).uniq.freeze

      # Non-string real type conversions for variable types
      VariableTypesToRealTypes = {
        'dichotomous' => :true_if_1,
        'dichotomous item' => :true_if_1,
        'categorical array' => :to_a,
        'integer' => :to_i,
        'numeric' => :to_d,
        'date' => :to_date,
        'date time' => :to_datetime,
        'time' => :to_time,
        'redcap status' => :to_i,
        'redcap completion timestamp' => :to_datetime_or_null
      }.freeze

      # Non-string database types
      VariableTypesToDatabaseTypes = {
        'dichotomous' => :boolean,
        'dichotomous item' => :boolean,
        'categorical array' => :string,
        'integer' => :integer,
        'numeric' => :decimal,
        'date' => :date,
        'date time' => :timestamp,
        'time' => :time,
        'redcap status' => :integer,
        'redcap completion timestamp' => :timestamp
      }.freeze

      # Types that are array fields
      VariableTypesToDatabaseArrays = {
        'categorical array' => true
      }

      attr_accessor :name, :field

      def initialize(field, field_type_name)
        self.field = field
        self.name = field_type_name.to_sym
      end

      def to_s
        name.to_s
      end

      #
      # The default common variable type, independent of source type
      # The actual variable type may not match the default when stored,
      # in order to be more meaningful,
      # such as Likert rather Categorical,
      # if an analyst decides appropriately
      # @return [String]
      def default_variable_type
        if name == :text
          TextFieldToVariableTypes[text_validation_type] || 'plain text'
        else
          FieldToVariableTypes[name]
        end
      end

      def model_variable_type
        if name == :text
          TextFieldToModelTypes[text_validation_type]
        else
          FieldToModelTypes[name]
        end
      end

      #
      # The presentation type is a combination of the main field type
      # and the text validation type
      # @return [String]
      def presentation_type
        val_type = text_validation_type
        val_type = 'none' if val_type.blank?

        self.class.presentation_type_for name, val_type
      end

      def self.presentation_type_for(name, val_type)
        "#{name} [#{val_type}]"
      end

      #
      # The text validation type from the definition
      # @return [String]
      def text_validation_type
        field.def_metadata[:text_validation_type_or_show_slider_number]
      end

      #
      # Data type for the field in the study database
      # @return [Symbol]
      def database_type
        VariableTypesToDatabaseTypes[default_variable_type] || :string
      end

      #
      # Is an array field in the study database?
      # @return [true|false]
      def database_array?
        VariableTypesToDatabaseArrays[default_variable_type]
      end

      #
      # Use the real data type from the definition to cast the supplied value to the real data type.
      # We handle '' blank strings carefully, since we don't want blank being converted to numeric zero
      # @param [Object] value
      # @return [Object]
      def cast_value_to_real(value)
        real_type = VariableTypesToRealTypes[default_variable_type] || :to_s
        return nil if value.blank? && real_type != :to_s && real_type != :to_a

        if real_type == :to_time
          vtime = value.to_time(:utc)
          return Time.utc(2000, 1, 1, vtime.hour, vtime.min, vtime.sec)
        end

        if value.respond_to?(real_type)
          value.send(real_type)
        else
          value
        end
      end

      #
      # Do the values from an existing record and a newly retrieved Redcap record match?
      # @param [Object] new_value
      # @param [Object] existing_value
      # @return [true|false]
      def values_match?(new_value, existing_value)
        cast_value_to_real(new_value) == existing_value
      end

      #
      # Convert the value stored in the database to a string matching how it would be retrieved through the
      # REDCap API.
      # @param [Object] value
      # @return [String]
      def cast_stored_value_to_redcap_string(value)
        if default_variable_type == 'dichotomous'
          case value
          when true
            '1'
          when false
            '0'
          else
            ''
          end
        elsif value.blank?
          ''
        elsif default_variable_type == 'date time' && !value.is_a?(String)
          Redcap::Utilities.date_time_to_api_string(value)
        else
          value.to_s
        end
      end
    end
  end
end
