# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Reusable configuration class for if_condition hashes
    # (e.g. creatable_if, editable_if, showable_if conditions).
    #
    # Stores the entire conditions hash as a single attribute rather than
    # splitting it into individual field-keyed entries.
    #
    # @example
    #   cond = IfCondition.new(always: true, user_is_creator: true)
    #   cond.conditions  #=> { always: true, user_is_creator: true }
    #   cond.blank?      #=> false
    class IfCondition < BaseConfiguration
      configure_direct :conditions, type: :hash

      validate :validate_condition_shape

      # Override default field-keyed setup to store the hash as a single value
      # on the conditions attribute.
      # @return [void]
      def setup_named_configurations
        self.conditions = hash_configuration.is_a?(Hash) ? hash_configuration.symbolize_keys : {}
      end

      # Returns true when no conditions are defined.
      def blank?
        conditions.blank?
      end

      # Returns the conditions hash for backward compatibility.
      # @return [Hash{Symbol => Object}]
      def symbolize_keys
        conditions || {}
      end

      private

      def validate_condition_shape
        validate_hash_attribute(:conditions, hash_configuration)
      end
    end
  end
end
