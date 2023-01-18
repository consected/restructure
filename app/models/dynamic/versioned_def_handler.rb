# Handle option type configurations for a dynamic class implementation
module Dynamic
  module VersionedDefHandler
    extend ActiveSupport::Concern

    included do
      # Ensure that memoized versioned definition is cleared on creation, or if we
      # force an updated of the created_at timestamp to make it use a later definition
      before_save :reset_versioned_definition!, if: -> { !persisted? || created_at_changed? }
    end

    class_methods do
      # The base string for route
      # For example "dynamic_model/some_models"
      def base_route_segments
        definition.base_route_segments
      end

      # Hyphenated name, typically used in HTML markup for referencing target blocks and panels
      def hyphenated_name
        definition.hyphenated_name
      end

      def category
        definition.category
      end
    end

    # resource_name used as a universal identifier
    def resource_name
      current_definition.resource_name
    end

    # Resource name for a single instance of the model
    def resource_item_name
      current_definition.resource_item_name
    end

    # Option type configuration for the current instance
    # For a dynamic model this is just the 'default'
    # For an activity log this is the config matching the extra_log_type
    def option_type_config
      res = versioned_definition.option_type_config_for option_type,
                                                        result_if_empty: :first_config
      unless res || option_type.blank? || option_type == :blank || option_type == :blank_log
        unless option_type.start_with?('ignore_missing_')
          if Rails.env.test?
            puts "No extra log type configuration exists for #{option_type || 'primary'} in #{self.class.name}"
          end
          logger.warn "No extra log type configuration exists for #{option_type || 'primary'} in #{self.class.name}"
        end
        res = current_definition.option_type_config_for option_type,
                                                        result_if_empty: :first_config
      end
      res
    end

    #
    # Returns the options text version specific to this instance
    # based on its creation date.
    # @return [String] options text
    def options_text
      versioned_definition.options_text
    end

    #
    # Return the current definition
    def current_definition
      self.class.definition
    end

    #
    # Get the definition record version from history, based on the created_at
    # timestamp of the current instance
    # If the versioned definition does not have a version number, and the current instance (self)
    # has an id (it is persisted), then we force a reload of the versioned definition to ensure
    # it doesn't reflect the wrong item.
    # @return [ActiveRecord::Base] dynamic class definition record
    def versioned_definition
      return @versioned_definition unless @versioned_definition.nil? ||
                                          @versioned_definition.def_version.nil? && id

      return @versioned_definition = current_definition if current_definition.use_current_version

      return @versioned_definition = current_definition if respond_to?(:use_current_version) && use_current_version

      unless respond_to?(:use_def_version_time) || respond_to?(:created_at)
        return @versioned_definition = current_definition
      end

      version_at = use_def_version_time if respond_to?(:use_def_version_time)
      version_at ||= created_at if respond_to?(:created_at)
      @versioned_definition = self.class.definition.versioned(version_at) || current_definition
    end

    #
    # Allow the versioned definition to be reloaded the next time it is requested
    # Called from an after_create trigger
    def reset_versioned_definition!
      @versioned_definition = nil
    end

    #
    # The version number of the versioned definition matching this instance
    # @return [Integer] version number (id of matching history table entry)
    def def_version
      versioned_definition.def_version
    end
  end
end
