# frozen_string_literal: true

module Dynamic
  module FieldEditAs
    class MultiEditable
      def self.persistable_value(saved_value)
        return unless saved_value.present?

        # The value from a param will be a single element array. Flatten it to a string first
        str = saved_value.first
        return unless str.present?

        curr_val = YAML.safe_load(str)
        return curr_val.to_a if curr_val.is_a? Hash

        # Map single element items to be a pair of the same
        curr_val = curr_val.map { |v| [v, v] } if curr_val.is_a?(Array) && curr_val.first.length
        curr_val
      end
    end
  end
end
