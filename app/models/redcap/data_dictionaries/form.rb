# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Form representation of the field definition for the data dictionaries
    class Form
      attr_accessor :def_metadata, :name, :data_dictionary

      def initialize(name, data_dictionary, fields_metadata)
        super()
        self.data_dictionary = data_dictionary
        self.def_metadata = fields_metadata.dup
        self.name = name.to_sym
      end

      #
      # All field type representations for this form
      # @return [Hash] { <field_name>: Redcap::DataDictionaries::Field }
      def fields
        @fields ||= Field.all_from(self)
      end

      #
      # List all field names for a specified form in the captured metadata
      # @return [Array{Symbol}]
      def field_names
        fields&.keys
      end

      def fields_of_type(field_type)
        unless field_type.in? FieldType::ValidFieldTypes
          raise FphsException,
                "Redcap field definition lookup failed for bad field_type: #{field_type}"
        end

        fields.filter { |_k, f| f.field_type.name == field_type }
      end

      def to_s
        name.to_s
      end

      #
      # Get an Hash of all form representations, keyed with the symbolized form name
      # @param [Redcap::DataDictorary] data_dictionary
      # @return [Array{Form}]
      def self.all_from(data_dictionary)
        captured_metadata = data_dictionary.captured_metadata
        return unless captured_metadata.present?

        forms = {}
        form_names(captured_metadata).each do |fn|
          form = Form.new(fn, data_dictionary, form_field_definitions(captured_metadata, fn))
          forms[fn] = form
        end

        forms
      end

      #
      # List all field definitions for a specified form in the captured metadata
      # @param [Symbol] form_name
      # @return [Array{Hash}]
      def self.form_field_definitions(captured_metadata, form_name)
        captured_metadata.filter { |f| f[:form_name] == form_name.to_s }
      end

      #
      # List all form names in the captured metadata
      # @return [Array{Symbol}]
      def self.form_names(captured_metadata)
        captured_metadata.map { |f| f[:form_name].to_sym }.uniq
      end
    end
  end
end
