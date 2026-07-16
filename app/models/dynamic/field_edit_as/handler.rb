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

      # Field types requiring translation from a submitted param string into a
      # persistable value. Matching is done with `edit_as_field_type.include? f`
      # (substring match, not equality) below, so `col_type_json` also matches
      # the `col_type_jsonb` field type derived from jsonb columns - both are
      # handled by Dynamic::FieldEditAs::ColTypeJson, which parses the submitted
      # YAML text back into a Hash/Array for storage.
      # `yaml_object` is resolved for name_starts_with_yaml_object fields backed by a
      # text/varchar column (see #edit_as_field_types below) and is handled by
      # Dynamic::FieldEditAs::YamlObject, which validates the YAML but stores the
      # original text (since the column is text, not json/jsonb).
      TransformFieldTypes = %w[multi_editable_list multi_editable_choices col_type_json yaml_object].freeze

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
      # The result uses column type for those that don't have a field_type specified.
      # Fields named `yaml_object_*` are resolved to the `yaml_object` field type,
      # ONLY when the underlying column is text/varchar (the only supported backing
      # types for yaml_object). JSON/JSONB columns continue to use their existing
      # col_type_json/col_type_jsonb handling, and other incompatible column types
      # (integer, boolean, etc.) fall through to their normal col_type_* behavior.
      # Explicit yaml_object edit_as values are subject to the same column-type
      # restriction.
      # @return [Hash]
      def edit_as_field_types
        fo = object_instance.option_type_config&.field_options || {}
        cols = object_instance.class.columns_hash
        field_list = object_instance.attribute_names
        field_list.to_h do |fn|
          [
            fn.to_sym,
            field_type(fn, cols, fo)
          ]
        end
      end

      #
      # The configured field type when supported by the backing column, otherwise
      # the column-derived default. yaml_object fields may only target text/varchar
      # columns regardless of whether their type is inferred from the field name or
      # explicitly configured.
      # @param [String] field_name
      # @param [Hash] cols - object_instance.class.columns_hash
      # @param [Hash] field_options
      # @return [String]
      def field_type(field_name, cols, field_options)
        configured_type = field_options.dig(field_name.to_sym, :edit_as, :field_type)
        return default_field_type(field_name, cols) unless configured_type
        return configured_type unless configured_type.include?('yaml_object')
        return configured_type if %i[text string].include?(cols[field_name].type)

        default_field_type(field_name, cols)
      end

      #
      # The default edit_as field type for a field, derived from its name and column type.
      # @param [String] field_name
      # @param [Hash] cols - object_instance.class.columns_hash
      # @return [String]
      def default_field_type(field_name, cols)
        col_type = cols[field_name].type
        if field_name.start_with?('yaml_object_') && %i[text string].include?(col_type)
          'yaml_object'
        else
          "col_type_#{col_type}"
        end
      end
    end
  end
end
