# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Field type functionality for the data dictionaries
    class FieldType
      ValidFieldTypes = %i[
        text
        text_area
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
        calc: 'calculated',
        dropdown: 'categorical',
        radio: 'categorical',
        checkbox: 'categorical',
        checkbox_choice: 'dichotomous', # This is not a real REDCap type, but is used as a lookup
        yesno: 'dichotomous',
        truefalse: 'dichotomous',
        file: 'file',
        slider: 'integer',
        descriptive: 'fixed caption'
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

      ValidVariableTypes = (FieldToVariableTypes.values + TextFieldToVariableTypes.values).uniq.freeze

      # Non-string real type conversions for variable types
      VariableTypesToRealTypes = {
        'dichotomous' => :true_if_1,
        'integer' => :to_i,
        'numeric' => :to_d,
        'date' => :to_date,
        'date time' => :to_datetime,
        'time' => :to_time
      }.freeze

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
      # Use the real data type from the definition to cast the supplied value to the real data type
      # @param [String] value
      # @return [Object]
      def cast_value_to_real(value)
        real_type = VariableTypesToRealTypes[default_variable_type] || :to_s
        value.send(real_type)
      end
    end
  end
end
