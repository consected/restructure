# frozen_string_literal: true

module Dynamic
  module FieldEditAs
    #
    # Handle translation of data for multi_editable_list field types
    class MultiEditableList
      #
      # Get the persistable value for the provided saved_value
      # The incoming parameter is a simple string with one entry of the list on each line
      # @param [Array] saved_value - value from the param
      # @return [Array] <description>
      def self.persistable_value(saved_value)
        return unless saved_value.present?

        saved_value.to_s.split("\n").compact
      end
    end
  end
end
