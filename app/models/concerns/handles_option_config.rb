# Handle option type configurations for a dynamic class implementation
module HandlesOptionConfig
  extend ActiveSupport::Concern

  # resource_name used as a universal identifier
  def resource_name
    self.class.definition.resource_name
  end

  # Option type configuration for the current instance
  # For a dynamic model this is just the 'default'
  # For an activity log this is the config matching the extra_log_type
  def option_type_config
    res = self.class.definition.option_type_config_for option_type,
                                                       result_if_empty: :first_config
    logger.warn "No extra log type configuration exists for #{option_type} in #{self.class.name}" unless res
    res
  end

  def no_downcase_attributes
    return unless option_type_config

    fo = option_type_config.field_options
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
      self.class.format_data_attribute da, self
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
end
