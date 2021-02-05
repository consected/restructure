# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Field representation of the field definition for the data dictionaries
    class Field
      attr_accessor :def_metadata, :form, :name, :label

      def initialize(form, field_metadata)
        super()

        self.form = form
        self.def_metadata = field_metadata.dup
        self.name = field_metadata[:field_name].to_sym
        self.label = field_metadata[:field_label]
      end

      #
      # Get the field type representation of for this field
      # @return [Redcap::DataDictionary::FieldType]
      def field_type
        @field_type ||= FieldType.new(self, def_metadata[:field_type])
      end

      def to_s
        name.to_s
      end

      #
      # Quick way to get a plain text label
      # @return [String]
      def label_plain
        Redcap::Utilities.html_to_plain_text label
      end

      #
      # Get an Hash of all field representations, keyed with the symbolized field name
      # for a form
      # @param [Form] form
      # @return [Array{Form}]
      def self.all_from(in_form)
        fields_metadata = in_form.def_metadata
        return unless fields_metadata.present?

        fields = {}

        fields_metadata.each do |field_metadata|
          form = Field.new(in_form, field_metadata)
          fields[form.name] = form
        end

        fields
      end
    end
  end
end
