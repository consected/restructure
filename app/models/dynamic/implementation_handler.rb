# Handle option type configurations for a dynamic class implementation
module Dynamic
  module ImplementationHandler
    extend ActiveSupport::Concern

    included do
      # Ensure that memoized versioned definition is cleared on creation, or if we
      # force an updated of the created_at timestamp to make it use a later definition
      before_save :reset_versioned_definition!, if: -> { !persisted? || created_at_changed? }
      after_commit :reset_access_evaluations!
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
      unless res || (option_type.blank? || option_type == :blank)
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

      @versioned_definition = self.class.definition.versioned(created_at) || current_definition
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

    def no_downcase_attributes
      fo = option_type_config&.field_options || {}
      fo&.filter { |_k, v| v[:no_downcase] }&.keys
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

      da = dopt.view_options[:data_attribute]

      if da
        Formatter::Formatters.format_data_attribute da, self
      else
        n = if attribute_names.include? 'data'
              attributes['data']
            else
              dopt.label || option_type.to_s.humanize
            end
        n.to_s
      end
    end

    # @return [Boolean | nil] returns true or false based on the result of a conditional calculation,
    #    or nil if there is no `add_reference_if` configuration
    def can_add_reference?
      return @can_add_reference unless @can_add_reference.nil?

      @can_add_reference = false
      dopt = option_type_config
      return unless dopt

      if dopt.add_reference_if.is_a?(Hash) && dopt.add_reference_if.first
        res = dopt.calc_add_reference_if(self)
        @can_add_reference = !!res
      end
    end

    # Calculate the can rules for the required type, based on user access controls and showable_if rules
    # Returns true or false if the appropriate showable_if or editable_if rule is defined, or
    # nil if the rule is not defined
    # @param type [Symbol] either :access or :edit for showable_if or editable_if
    # @return [Boolean | nil]
    def calc_can(type)
      # either use the editable_if configuration if there is one
      dopt = option_type_config
      return unless dopt

      if type == :edit
        doptif = dopt.editable_if
      elsif type == :access
        doptif = dopt.showable_if
      end

      if doptif.is_a?(Hash) && doptif.first
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

        if type == :edit
          res = !!dopt.calc_editable_if(old_obj)
        elsif type == :access
          res = !!dopt.calc_showable_if(old_obj)
        end
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
  end
end
