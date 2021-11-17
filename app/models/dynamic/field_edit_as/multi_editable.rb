# frozen_string_literal: true

module Dynamic
  module FieldEditAs
    #
    # Handle translation of data for multi_editable field types
    class MultiEditable
      #
      # Get the persistable value for the provided saved_value
      # The incoming parameter is a YAML string. This provides a mechanism for passing
      # an array or hash of data.
      # Accepted formats are:
      #   Hash {key: value}
      #   Array [key, value]
      #   Array [value]
      # @param [Array] saved_value - value from the param
      # @return [Array] <description>
      def self.persistable_value(saved_value)
        return unless saved_value.present?

        curr_val = YAML.safe_load(saved_value)
        return curr_val.to_a if curr_val.is_a? Hash

        # Map single element items to be a pair of the same
        curr_val = curr_val.map { |v| [v, v] } if curr_val.is_a?(Array) && curr_val.first.length
        curr_val
      end
    end
  end
end
