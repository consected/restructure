# frozen_string_literal: true

#
# Handle selections options (that would appear in a drop down field)
# independently of where they are defined.
# Selection options may be defined in general selections or
# dynamic definition extra options {field_options: {edit_as: {alt_options: }}}.
class Classification::SelectionOptionsHandler
  attr_accessor :user_base_object, :table_name

  #
  # Get the selection option label for a field value in a user base object, if there is one
  # This does not benefit from memoization, so it is generally recommended to instantiate
  # the class and call #label_form(field_name, field_value)
  # where multiple requests against the same model are to be made.
  # @param [UserBase] user_base_object
  # @param [String | Symbol] field_name
  # @param [Object] field_value
  # @return [String | nil]
  def self.label_for(user_base_object, field_name, field_value)
    new(user_base_object: user_base_object).label_for(field_name, field_value)
  end

  #
  # The class may be initialized with either a user_base_object (UserBase) or a table name.
  # A user_base_object allow for selection options to come from a general selection or alt_options definition.
  # A table name will attempt to match against a user_base_object and use it. If not, only general selections
  # will be used to find selection options, against table names
  def initialize(user_base_object: nil, table_name: nil)
    if table_name
      self.table_name = table_name
      self.user_base_object = UserBase.class_from_table_name(table_name)&.new
    else
      self.user_base_object = user_base_object
    end
  end

  #
  # Get the label for the actual field value, based on general selections or
  # dynamic definition extra options {field_options: {edit_as: {alt_options: }}}
  # @param [String | Symbol] field_name
  # @param [String | Symbol] field_value
  # @return [Array|nil]
  def label_for(field_name, field_value)
    field_value = field_value.to_s
    res = edit_as_alt_option_label_for(field_name, field_value) if user_base_object
    res ||= edit_as_select_field(field_name, field_value) if user_base_object
    res ||= general_selection_label_for(field_name, field_value)
    res ||= get_field_label_for(field_name, field_value)
    res || field_value
  end

  #
  # Get all the alt_options for a field, memoizing the result
  # @param [String | Symbol] field_name
  # @return [Hash{label: field_value} | nil]
  def edit_as_alt_options_for(field_name)
    field_name = field_name.to_s
    @edit_as_alt_options_for ||= {}
    return @edit_as_alt_options_for[field_name] if @edit_as_alt_options_for.key?(field_name)

    @edit_as_alt_options_for[field_name] = nil
    return unless user_base_object.respond_to?(:option_type_config) && user_base_object.option_type_config

    opt = self.class.all_edit_as_alt_options(user_base_object)
    return unless opt

    @edit_as_alt_options_for[field_name] = opt[field_name.to_sym]
  end

  #
  # Get the label for the actual field value, based on
  # dynamic definition extra options {field_options: {edit_as: {alt_options: }}}
  # @param [String | Symbol] field_name
  # @param [Object] field_value
  # @return [Object| nil]
  def edit_as_alt_option_label_for(field_name, field_value)
    # If alt options are defined, return the key for the matching value, since
    # the key is the label we want to return.
    edit_as_alt_options_for(field_name)&.key(field_value)
  end

  #
  # Get the label for the actual field value, based on
  # dynamic definition extra options {field_options: {edit_as: field_type: select_...}}
  # @param [String | Symbol] field_name
  # @param [Object] field_value
  # @return [Object| nil]
  def edit_as_select_field(field_name, field_value)
    return unless field_value

    @all_edit_as_select_field ||= self.class.all_edit_as_select_field(user_base_object, only: field_name.to_s)
    return unless @all_edit_as_select_field

    f = @all_edit_as_select_field[field_name.to_sym]
    return unless f

    f.find { |v| v&.last&.to_s == field_value&.to_s }&.first
  end

  #
  # Get all the general selections for a field, memoizing the result
  # @param [String | Symbol] field_name
  # @return [Hash{label: field_value} | nil]
  def general_selection_for(field_name)
    field_name = field_name.to_s
    @general_selection_for ||= {}
    @general_selection_for[field_name] if @general_selection_for.key?(field_name)

    @general_selection_for[field_name] = nil
    # When a real user base object has been provided, use it to set the general selection name to find
    # But if we were given a table name that doesn't resolve to a class,
    # just attempt to use the singularized table name
    general_selection_name = if user_base_object
                               self.class.general_selection_prefix_name(user_base_object)
                             else
                               table_name.singularize
                             end
    general_selection_name = "#{general_selection_name}_#{field_name}"

    gs = Classification::GeneralSelection.selector_collection item_type: general_selection_name
    return unless gs

    gs = gs.map { |s| [s['name'], s['value']] }.to_h
    @general_selection_for[field_name] = gs
  end

  #
  # Get the label for the actual field value, based on general selections
  # being defined for the model and field.
  # @param [String | Symbol] field_name
  # @param [Object] field_value
  # @return [Object| nil]
  def general_selection_label_for(field_name, field_value)
    general_selection_for(field_name)&.key(field_value)
  end

  #
  # Get the label for the actual field value, based on a get_<field>_name class method
  # such as ViewHandlers::Subject.get_rank_name for PlayerInfo and general Subject models.
  def get_field_label_for(field_name, field_value)
    klass = user_base_object&.class
    mname = "get_#{field_name}_name"
    return unless klass.respond_to?(mname)

    klass.send(mname, field_value)
  end

  #
  # Get the form_options.edit_as.alt_options configurations for a specific (UserBase) object
  # For activity logs, generally the extra_log_type attribute is set, allowing the appropriate
  # configuration to be pulled.
  # The user_base_object does not need to be persisted for this to operate.
  # @param [UserBase] user_base_object
  # @return [Hash{field_name: {...alt_options}} | nil] returns the alt_options
  #      configurations per field, or nil if there are none
  def self.all_edit_as_alt_options(user_base_object)
    otc = user_base_object.option_type_config
    return unless otc

    fndefs = {}
    otc.field_options.each do |fn, opt|
      alt_options = opt.dig(:edit_as, :alt_options)
      fndefs[fn] = alt_options.stringify_keys if alt_options
    end
    return if fndefs.empty?

    fndefs
  end

  #
  # Get the form_options.edit_as.field_type select_record_... field array for a specific (UserBase) object
  # For activity logs, generally the extra_log_type attribute is set, allowing the appropriate
  # configuration to be pulled.
  # The user_base_object does not need to be persisted for this to operate. If the master is set then
  # the master specific results will be retrieved for those datasets having a master association
  # @param [UserBase] user_base_object
  # @param [String | nil] only - optionally return only a specified attribute in the result hash
  # @return [Hash{field_name: [name, value]} | nil] returns the selection results
  #      configurations per field, or nil if there are none
  def self.all_edit_as_select_field(user_base_object, only: nil)
    otc = user_base_object.option_type_config
    fndefs = {}

    ans = user_base_object.attribute_names
    ans = [only] if only && ans.include?(only)

    ans.each do |fn|
      fn = fn.to_sym
      opt = otc.field_options[fn] if otc
      edit_as = opt[:edit_as] if opt
      edit_as ||= {}
      alt_fn = (edit_as[:field_type] || fn).to_s
      alt_gs = edit_as[:general_selection]
      if alt_gs
        res = begin
          # GeneralSelectionsHelper.helpers.general_selection(alt_gs, return_all: true)
          attr = %i[name value]
          cond = { item_type: alt_gs }
          Classification::GeneralSelection.selector_attributes(attr, cond)
        rescue StandardError => e
          Rails.logger.error "Failed to get alternative general selection\n#{e}"
          nil
        end
        fndefs[fn] = res if res
      elsif alt_fn.index(/^(tag_)?select_record_/)
        group_split_char = edit_as[:group_split_char]
        label_attr = edit_as[:label_attr] || :data
        value_attr = if alt_fn.index(/^(tag_)?select_record_id_/)
                       :id
                     elsif alt_fn.index(/^(tag_)?select_user_with_role_/)
                       label_attr = :email
                       :email
                     else
                       edit_as[:value_attr] || :data
                     end

        assoc_or_class_name = alt_fn.sub(/^(tag_)?select_record_(id_)?from_(table_)?/, '').singularize

        got_res, res = EditFields::SelectFieldHandler.list_record_data_for_select(user_base_object,
                                                                                  assoc_or_class_name,
                                                                                  value_attr: value_attr,
                                                                                  label_attr: label_attr,
                                                                                  group_split_char: group_split_char)

        fndefs[fn] = res if got_res && res
      end
    end
    return if fndefs.empty?

    fndefs
  end

  #
  # Get all the general selection configurations and override them with the form_options.edit_as.alt_options
  # This is only used by UI requests to the DefinitionsController to get and cache general selections
  # options on the front end.
  #
  # If alt_options override an existing select_... field, the general selection records for this will
  # be removed from the results and the alt options will be used instead.
  #
  # If alt_options appear for a field that is not a select_... then the new options will just be added
  # with the current field name. It is the responsibility of the client to see this.
  #
  # This is used on the client side for the display of form values.
  #
  # The returned array of hashes follows this format:
  # [
  #   {
  #     id: GeneralSelection#id or nil if alt_option,
  #     item_type: (base_item_type)_(field_name),
  #     name: (label),
  #     value: (stored field value),
  #     create_with: GeneralSelection#create_with or nil if alt_option,
  #     edit_if_set: GeneralSelection#edit_if_set or nil if alt_option,
  #     edit_always: GeneralSelection#edit_always or true if alt_option,
  #     lock: GeneralSelection#lock or nil if alt_option,
  #     base_item_type: (the model#item_type),
  #     field_name: (field_name)
  #   }, ...
  # ]
  #
  # @param [Hash] conditions any conditions to be passed to retrieve the appropriate general selections
  # @return [Array{Hash}] serializable array of general_selection and alt_options overrides
  def self.selector_with_config_overrides(conditions = nil)
    if conditions.is_a? Hash
      extra_log_type = conditions.delete(:extra_log_type)
      item_type = conditions.delete(:item_type)
      single_field = conditions.delete(:field_name)
      only_field_names = [single_field] if single_field
    end

    # Get the all enabled general selection data as an array of results
    res = Classification::GeneralSelection.selector_collection.map { |c| c.attributes.symbolize_keys }

    # Get a list of implementations that may have alt_options defined
    impl_classes = implementation_classes
    # If an item type has been specified, filter the possible classes
    impl_classes = impl_classes.select { |ic| ic.item_type.singularize == item_type.singularize } if item_type
    # Check each definition is ready to use and prepare it for use
    impl_classes.select! { |ic| ic.definition.ready_to_generate? }

    impl_classes.each do |impl_class|
      dyn_object = impl_class.new

      # If an extra log type was specified, use it, since the alt_options are specified at that level
      dyn_object.extra_log_type = extra_log_type if extra_log_type && dyn_object.respond_to?(:extra_log_type)

      prefix = general_selection_prefix_name(dyn_object)

      # If item_type was specified, filter the results from the general selections that match it
      # This leaves us with all field definitions for that item_type
      if item_type
        fns = only_field_names || dyn_object.attribute_names
        item_types = fns.map { |a| "#{prefix}_#{a}" }
        res.select! { |r| r[:item_type].in? item_types }
      end

      res.each do |r|
        if r[:item_type].start_with?(prefix)
          r.merge!(base_item_type: prefix,
                   field_name: r[:item_type].sub("#{prefix}_", ''))
        end
      end

      # Get the select_... field options that add to or override the general selections
      alt_options = all_edit_as_select_field(dyn_object) || {}

      # Get the alt_options that add to or override the previous definitions
      alt_options.merge!(all_edit_as_alt_options(dyn_object) || {})

      next unless alt_options.present?

      # alt_options were found for this implementation.
      # Run through each field that has a definition
      # remove the existing general_selection results that match the item_type (if any)
      # and add in the new options
      alt_options.each do |field_name, opts|
        next if single_field && field_name.to_s != single_field.to_s

        gsit = "#{prefix}_#{field_name}"
        # Remove any existing general selections for this model / field combo
        res.reject! { |r| r[:item_type] == gsit }

        # If the options are a simple array (list of options, not key, value),
        # make them into a hash { item => item } for consistency with Hash definitions
        opts = opts.map { |oi| [oi, oi] }.to_h if opts.is_a? Array

        # Add the new items to the result
        opts.each do |k, v|
          res << {
            id: nil,
            item_type: gsit,
            name: k,
            value: v,
            create_with: nil,
            edit_if_set: nil,
            edit_always: true,
            lock: nil,
            base_item_type: prefix,
            field_name: field_name
          }
        end
      end
    rescue StandardError => e
      raise FphsException, "Failure getting selector_with_config_overrides(#{conditions}) for implementation: " \
      "#{impl_class}\n#{e}\n#{e.backtrace.join("\n")}"
    end

    res
  end

  #
  # Reset memoized items
  def self.reset!
    @implementation_classes = nil
  end

  #
  # Get implementation classes for dynamic definitions
  # that can provide form_options.edit_as.alt_options configurations
  # Memoize the result, since this is a slow process
  def self.implementation_classes
    @implementation_classes ||= ActivityLog.implementation_classes +
                                DynamicModel.implementation_classes +
                                ExternalIdentifier.implementation_classes
  end

  #
  # Get the prefix name for a user_base_object
  # @param [UserBase] user_base_object
  # @return [String]
  def self.general_selection_prefix_name(user_base_object)
    Classification::GeneralSelection.prefix_name(user_base_object)
  end
end
