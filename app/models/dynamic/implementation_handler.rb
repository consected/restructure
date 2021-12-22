# Handle option type configurations for a dynamic class implementation
module Dynamic
  module ImplementationHandler
    extend ActiveSupport::Concern

    included do
      # Ensure that memoized versioned definition is cleared on creation, or if we
      # force an updated of the created_at timestamp to make it use a later definition
      before_save :reset_versioned_definition!, if: -> { !persisted? || created_at_changed? }
      before_save :handle_before_save_triggers
      after_commit :handle_save_triggers
      after_commit :reset_access_evaluations!
    end

    class_methods do
      # The base string for route
      # For example "dynamic_model/some_models"
      def base_route_segments
        definition.base_route_segments
      end
    end

    # resource_name used as a universal identifier
    def resource_name
      current_definition.resource_name
    end

    # Option type configuration for the current instance
    # For a dynamic model this is just the 'default'
    # For an activity log this is the config matching the extra_log_type
    def option_type_config
      res = versioned_definition.option_type_config_for option_type,
                                                        result_if_empty: :first_config
      unless res || option_type.blank? || option_type == :blank || option_type == :blank_log
        logger.warn "No extra log type configuration exists for #{option_type || 'primary'} in #{self.class.name}"
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

    #
    # List field names that explicitly state *no_downcase: true* or
    # edit_as: field_type: includes the string 'notes'
    # @return [Array{Symbol}]
    def no_downcase_attributes
      fo = option_type_config&.field_options || {}
      res = fo&.filter { |_k, v| v[:no_downcase] || v[:edit_as] && v[:edit_as][:field_type]&.include?('notes') }

      res&.keys
    end

    # Provide a default human message identifying a record
    # If the extra log type config for an activity includes
    #
    #   view_options:
    #     data_attribute: some text {{substitution}}
    #
    # or
    #   view_options:
    #     data_attribute: attrib_name
    #
    # then appropriate substitutions will be made
    #
    # If a list is provided to data_attribute, such as
    #
    # - attr1
    # - ": "
    # - attr2
    #
    # then the attribute names that can be substituted will be and the
    # result of all items will be joined into a single string
    #
    # If no data_attribute configuration is provided then the first of the following is used:
    # - if there is a data attribute, use its value
    # - if a label is specified in the config, use it
    # - otherwise the extra_log_type value is humanized and used
    #
    def data
      dopt = option_type_config
      return unless dopt&.view_options

      da = data_attribute_name

      if da
        @processing_data = true
        res = Formatter::Formatters.format_data_attribute da, self, ignore_missing: :show_tag
        @processing_data = false
        return res
      end

      res = if attribute_names.include? 'data'
              attributes['data']
            else
              dopt&.label || option_type.to_s.humanize
            end
      res.to_s
    end

    #
    # Return the data_attribute as defined in the options, or nil if there is nothing defined
    # @return [String | nil]
    def data_attribute_name
      dopt = option_type_config
      return unless dopt&.view_options

      # Prevent recursion in the creation of the data attribute with substitution
      return if @processing_data

      dopt.view_options[:data_attribute]
    end

    # @return [Boolean | nil] returns true or false based on the result of a conditional calculation,
    #    or nil if there is no `add_reference_if` configuration
    def can_add_reference?
      return @can_add_reference unless @can_add_reference.nil?

      @can_add_reference = false
      dopt = option_type_config
      return unless dopt

      return unless dopt.add_reference_if.is_a?(Hash) && dopt.add_reference_if.first

      res = dopt.calc_if(:add_reference_if, self)
      @can_add_reference = !!res
    end

    # Calculate the can rules for the required type, based on user access controls and showable_if rules
    # Returns true or false if the appropriate showable_if or editable_if rule is defined, or
    # nil if the rule is not defined
    # @param type [Symbol] either :access or :edit for showable_if or editable_if
    # @return [Boolean | nil]
    def calc_can(type)
      dopt = option_type_config
      return unless dopt

      case type
      when :edit
        doptif = dopt.editable_if
      when :access
        doptif = dopt.showable_if
      else
        return
      end

      return unless doptif.is_a?(Hash) && doptif.first && respond_to?(:master)

      # Generate an old version of the object prior to changes
      old_obj = dup
      changes.each do |k, v|
        old_obj.send("#{k}=", v.first) if k.to_s != 'user_id'
      end

      # Set the id, since dup doesn't do this and we may need it
      old_obj.id = id

      # Ensure the duplicate old_obj references the real master, ensuring current user can
      # be referenced correctly in conditional calculations
      old_obj.master = master

      case type
      when :edit
        res = !!dopt.calc_if(:editable_if, old_obj)
      when :access
        res = !!dopt.calc_if(:showable_if, old_obj)
      end

      res
    end

    # If access has changed since an initial check, reset the cached results
    def reset_access_evaluations!
      @can_access = nil
      @can_create = nil
      @can_add_reference = nil
      @can_edit = nil
    end

    #
    # Handle on save save triggers
    def handle_save_triggers
      option_type_config&.calc_save_trigger_if self
      true
    end

    #
    # Handle actions that must be performed before on save save triggers
    def handle_before_save_triggers
      option_type_config&.calc_save_trigger_if self, alt_on: :before_save
      true
    end
  end
end
