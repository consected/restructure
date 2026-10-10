# frozen_string_literal: true

module Dynamic
  module FieldEditAs
    #
    # Handle validation of the YAML text edited by the user for `name_starts_with_yaml_object`
    # fields (see views/common_templates/edit_fields/_name_starts_with_yaml_object.html.erb),
    # for storage in a plain text/varchar database column.
    #
    # Unlike Dynamic::FieldEditAs::ColTypeJson (which parses the submitted YAML text into a
    # Hash/Array for storage in a json/jsonb column), this class stores the YAML TEXT ITSELF,
    # since the backing column here is text/varchar, not json/jsonb. Parsing here is used only
    # to validate that the submitted text is well-formed YAML representing a Hash or Array,
    # matching the same validation contract as ColTypeJson, before allowing it to be saved.
    class YamlObject
      #
      # Get the persistable value for the provided saved_value.
      # The incoming parameter is a YAML string submitted from the form's YAML code editor.
      # It is validated by parsing it, but the ORIGINAL YAML TEXT is returned for storage,
      # since the backing column is text/varchar (not json/jsonb).
      # @param [String] saved_value - YAML text value from the param
      # @return [String, nil] the original YAML text, once validated
      def self.persistable_value(saved_value)
        return unless saved_value.present?

        curr_val = YAML.safe_load(saved_value)
        unless curr_val.is_a?(Hash) || curr_val.is_a?(Array)
          raise FphsException, "yaml_object: cannot parse saved value: (#{saved_value.class.name}) #{saved_value}"
        end

        saved_value
      rescue Psych::Exception
        raise FphsException, "yaml_object: cannot parse saved value: (#{saved_value.class.name}) #{saved_value}"
      end
    end
  end
end
