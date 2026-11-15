# frozen_string_literal: true

module Dynamic
  module FieldEditAs
    #
    # Handle translation of the YAML text edited by the user (see
    # views/common_templates/edit_fields/_column_type_json.html.erb and
    # _column_type_jsonb.html.erb) back into a Hash/Array to be stored in a
    # json/jsonb database column.
    #
    # Dynamic::FieldEditAs::Handler matches this class for both `col_type_json`
    # and `col_type_jsonb` column edit_as field types (jsonb matches since
    # 'col_type_jsonb' includes the substring 'col_type_json'), so the same
    # translation is used for both column types.
    class ColTypeJson
      #
      # Get the persistable value for the provided saved_value
      # The incoming parameter is a YAML string submitted from the form's YAML
      # code editor. This provides a mechanism for editing a json/jsonb column's
      # Hash or Array contents as plain YAML text.
      # Accepted formats are:
      #   Hash
      #   Array
      # @param [String] saved_value - YAML text value from the param
      # @return [Hash, Array, nil] the parsed object ready to persist to the json/jsonb column
      def self.persistable_value(saved_value)
        return unless saved_value.present?

        curr_val = YAML.safe_load(saved_value)
        return curr_val if curr_val.is_a?(Hash) || curr_val.is_a?(Array)

        raise FphsException, "col_type_json: cannot parse saved value: (#{saved_value.class.name}) #{saved_value}"
      rescue Psych::Exception
        raise FphsException, "col_type_json: cannot parse saved value: (#{saved_value.class.name}) #{saved_value}"
      end
    end
  end
end
