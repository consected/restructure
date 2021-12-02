# frozen_string_literal: true

module Dynamic
  module FieldEditAs
    #
    # Handle the translation of received strong parameters
    # into persistable data according to specific {field_options: edit_as:} configurations
    # The translations are performed for the parameters with names containing
    # any one of the items in TransformFieldTypes.
    # This indicates which of the classes in FieldEditAs to use for translation
    class Handler
      attr_accessor :object_instance, :params

      TransformFieldTypes = %w[multi_editable_list multi_editable_choices col_type_json].freeze

      #
      # Initialize with the object instance to be stored to, and the params from
      # the controller to translate
      # @param [UserBase] object_instance
      # @param [ActionController::Parameters] params
      def initialize(object_instance, params)
        self.object_instance = object_instance
        self.params = params
      end

      #
      # Translate all params in the @object_instance to a persistable value,
      # based on the edit_as configuration
      # Returns a hash of any params that have been updated, so they can be merged in
      # @return [Hash]
      def translate_to_persistable
        res = {}
        edit_as_field_types.each do |field_name, edit_as_field_type|
          use = TransformFieldTypes.find { |f| edit_as_field_type.include? f }
          next unless use

          value = params[field_name]
          new_value = "dynamic/field_edit_as/#{use}".camelize.constantize.persistable_value(value)

          res[field_name] = new_value
        end

        res
      end

      private

      #
      # Return a hash of field_options: <field>: edit_as: field_type: <field type value> as
      # { <field>: <field type value> }
      # The result uses column type for those that don't have a field_type specified
      # @return [Hash]
      def edit_as_field_types
        fo = object_instance.option_type_config&.field_options || {}
        cols = object_instance.class.columns_hash
        field_list = object_instance.attribute_names
        field_list.map do |fn|
          [
            fn.to_sym,
            fo.dig(fn.to_sym, :edit_as, :field_type) || "col_type_#{cols[fn].type}"
          ]
        end.to_h
      end
    end
  end
end
