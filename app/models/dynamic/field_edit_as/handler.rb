# frozen_string_literal: true

module Dynamic
  module FieldEditAs
    class Handler
      attr_accessor :object_instance

      TransformFieldTypes = %w[multi_editable].freeze

      def initialize(object_instance)
        self.object_instance = object_instance
      end

      #
      # Translate all fields in the @object_instance to a persistable value,
      # based on the edit_as configuration
      def translate_to_persistable
        edit_as_field_types.each do |field_name, edit_as_field_type|
          use = TransformFieldTypes.find { |f| edit_as_field_type.include? f }
          next unless use

          value = object_instance[field_name]
          new_value = "dynamic/field_edit_as/#{use}".classify.constantize.persistable_value(value)

          object_instance[field_name] = new_value
        end
      end

      private

      #
      # Return a hash of field_options: <field>: edit_as: field_type: <field type value> as
      # { <field>: <field type value> }
      # @return [Hash]
      def edit_as_field_types
        fo = object_instance.option_type_config&.field_options || {}

        fo.transform_values { |v| v[:edit_as] && v[:edit_as][:field_type] }.delete_if { |_k, v| !v }
      end
    end
  end
end
