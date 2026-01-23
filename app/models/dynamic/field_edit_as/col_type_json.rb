# frozen_string_literal: true

module Dynamic
  module FieldEditAs
    #
    # Handle translation of data for multi_editable_choices field types
    class ColTypeJson
      #
      # Get the persistable value for the provided saved_value
      # The incoming parameter is a YAML string. This provides a mechanism for passing
      # an array or hash of data.
      # Accepted formats are:
      #   Hash
      #   Array
      # @param [Array] saved_value - value from the param
      # @return [Hash]
      def self.persistable_value(saved_value)
        return unless saved_value.present?

        curr_val = YAML.safe_load(saved_value)
        curr_val.presence.to_h
      rescue StandardError
        begin
          curr_val.to_a
        rescue StandardError
          raise FphsException, "col_type_json: cannot parse saved value: (#{saved_value.class.name}) #{saved_value}"
        end
      end
    end
  end
end
