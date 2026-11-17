# frozen_string_literal: true

module OptionConfigs
  module ExtraOptionConfigs
    # Base class for all ExtraOptions configuration classes.
    # Each subclass encapsulates the normalization/cleaning logic
    # for one top-level configuration area in ExtraOptions.
    #
    # Subclasses should:
    # - Declare managed attributes with `attribute :name`
    # - Implement `#clean` to normalize values
    # - Use `#failed_config` to report configuration errors
    #
    # @example
    #   class LabelDef < ConfigBase
    #     attribute :label
    #
    #     def clean
    #       self.label = parent_options.label || parent_options.name.to_s.humanize
    #     end
    #   end
    class ConfigBase
      include ActiveModel::Validations

      attr_reader :parent_options

      # Track which attributes this config class manages
      # Each subclass maintains its own list via Ruby class instance variables
      # @return [Array<Symbol>]
      def self.managed_attributes
        @managed_attributes ||= []
      end

      # Declare one or more managed attributes on this config class.
      # Creates attr_accessor and registers the attribute names.
      # @param names [Array<Symbol>] attribute names
      def self.attribute(*names)
        attr_accessor(*names)

        managed_attributes.push(*names)
      end

      # Declare that this class stores a single direct value of a given type.
      # Records type metadata in option_types[:direct] for reflection.
      # @param config_item_name [Symbol] the attribute name
      # @param type [Symbol] the value type (:string, :array, :hash, :if_condition)
      def self.configure_direct(config_item_name, type:)
        attribute(config_item_name) unless managed_attributes.include?(config_item_name)

        option_types[:direct] << config_item_name

        @direct_types ||= {}
        @direct_types[config_item_name] = type
      end

      # Returns the option types declared on this class.
      # @return [Hash{Symbol => Array<Symbol>}]
      def self.option_types
        @option_types ||= { direct: [] }
      end

      # Returns the registered direct types for this class.
      # @return [Hash{Symbol => Symbol}]
      def self.direct_types
        @direct_types || {}
      end

      # @param parent_options [OptionConfigs::ExtraOptions] the parent ExtraOptions instance
      def initialize(parent_options)
        @parent_options = parent_options
        clean
      end

      # Write cleaned attribute values back to the parent ExtraOptions instance.
      # Called after #clean to synchronize values.
      def apply_to_parent!
        self.class.managed_attributes.each do |attr|
          parent_options.send("#{attr}=", send(attr))
        end
      end

      # Override in subclasses to perform cleaning/normalization
      # @raise [NotImplementedError] if not overridden
      def clean
        raise NotImplementedError, "#{self.class.name} must implement #clean"
      end

      private

      # Access the dynamic definition record (DynamicModel, ActivityLog, etc.)
      # @return [ActiveRecord::Base]
      def config_obj
        parent_options.config_obj
      end

      # Delegate error reporting to the parent ExtraOptions instance
      # @param type [Symbol] error category
      # @param message [String] error message
      # @param extra_details [Object] additional detail
      # @param level [Symbol] :error or :warn
      def failed_config(type, message, extra_details: nil, level: :error)
        parent_options.send(:failed_config, type, message, extra_details:, level:)
      end
    end
  end
end
