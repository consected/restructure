# frozen_string_literal: true

module ReportsHelper
  def editable?
    @editable = @report.editable_data? && (current_admin || current_user&.can?(:edit_report_data))
  end

  def creatable?
    @creatable = @report.creatable_data? &&
                 (current_admin || current_user&.can?(:create_report_data)) &&
                 !@view_options&.prevent_adding_items
  end

  def report_edit_btn(id)
    return unless id

    rp = edit_report_path(id, report_id: @report.id, filter: filter_params_permitted)
    link_to '',
            rp,
            remote: true,
            class: 'edit-entity glyphicon glyphicon-pencil'
  end

  def report_edit_cancel
    link_to '',
            '#',
            id: 'report-edit-cancel',
            class: 'btn btn-default glyphicon glyphicon-remove report-edit-cancel'
  end

  #
  # Show a report criteria field
  def report_criteria_field(name, config, value, options = {})
    return nil if config.is_a? String

    unless config.is_a? OptionConfigs::SearchAttributesConfig::NamedConfiguration
      raise FphsException, "Bad report field config configured: #{config}"
    end

    value ||= report_field_default config
    main_field = label_tag(config.label || name)
    main_field += report_criteria_multiple_field(name, config, value, options) ||
                  report_criteria_dropdown_field(name, config, value, options) ||
                  report_criteria_text_field(name, config, value, options)

    main_field
  end

  private

  #
  # Get the report field default value from the configuration
  # @param [OptionConfigs::SearchAttributesConfig::NamedConfiguration] config
  # @return [Object]
  def report_field_default(config)
    FieldDefaults.calculate_default(@report, config.default, config.type)
  end

  #
  # Set up the options for a select field, if the config says this is a select field,
  # otherwise return nil
  # @param [OptionConfigs::SearchAttributesConfig::NamedConfiguration] config
  # @param [Object] value - the field value
  # @return [#options_for_select | nil]
  def report_criteria_use_dropdown_options(config, value)
    classification_class = Classification.get_classification_type_by name: config.type

    if classification_class.respond_to?(:all_name_value_enable_flagged)
      if config.item_type == 'all'
        type_filter = nil
      elsif config.item_type
        type_filter = { item_type: config.item_type }
      elsif config.conditions
        type_filter = config.conditions
      end

      if config.disabled || !@report_page
        type_filter ||= {}
        type_filter[:disabled] = false
      end

      options_for_select(classification_class.all_name_value_enable_flagged(type_filter), value)
    elsif config.type == 'defined_selector'
      item_type, field_name = config.defined_selector.split('/')
      opts = Classification::GeneralSelection.selector_with_config_overrides item_type: item_type,
                                                                             field_name: field_name
      opts = opts.map { |r| [r[:name], r[:value]] }
      options_for_select(opts || [], value)
    elsif config.type == 'config_selector'
      options_for_select(config.selections || [], value)
    elsif config.type == 'select_from_model'
      # Get the model by the configured resource name
      def_value = value
      resource_name = config.resource_name
      res = Resources::Models.find_by(resource_name: resource_name) if resource_name
      raise FphsException, "No resource matches resource_name: #{resource_name}" unless res

      # Use the configuration of selections to define which fields to pull as the options
      # The selections configuration is "<label field>: <value field>"
      # For example, for a data dictionary variable, this might be "study: study"
      fields = (config.selections || { id: :id })
      model = res[:model]

      label = fields.keys.first
      value = fields.values.first

      # Make sure we can't call any arbitrary method on the model
      valid_attrs = model.attribute_names + ['data']
      unless label.to_s.in?(valid_attrs) && value.to_s.in?(valid_attrs)
        raise FphsException,
              "Invalid attribute requested #{label}: #{value}"
      end

      selections = model
      selections = selections.active if selections.attribute_names.include? 'disabled'

      selections = if label.to_s == 'data' || value.to_s == 'data'
                     # Map rather than pluck so we can get the data attribute successfully
                     selections.distinct.reorder('')
                               .map do |r|
                       [r.send(label), r.send(value)]
                     end
                   else
                     selections.distinct.reorder('').pluck(label, value)
                   end

      # NOTE: #uniq is called twice below on purpose, first to hugely limit large tables,
      # then second to merge what were previously nils that have become empty strings,
      # with the values that were actually empty strings
      selections = selections.uniq

      # Handle pluck returning only a single value for each result if the same
      # attribute for label and value are specified
      selections = selections.map { |a| [a, a] } unless selections.first.is_a?(Array)
      selections = selections.map { |a| [a.first.to_s, a.last.to_s] }
                             .uniq
                             .sort { |x, y| x.first <=> y.first }

      got_bar = selections.find { |s| s.first.include?('|') }
      return grouped_options_for_select(record_results_grouping(selections, '|'), def_value) if got_bar

      options_for_select(selections, def_value)
    end
  end

  #
  # The markup for a multiple entry field, or nil if this is not a multiple entry field
  # @param [String | Symbol] name - HTML field name
  # @param [OptionConfigs::SearchAttributesConfig::NamedConfiguration] config
  # @param [Object] value - the field value
  # @param [Hash] options - field options
  # @return [String | nil]
  def report_criteria_multiple_field(name, config, value, options)
    return unless config.multiple == 'multiple' || config.multiple == 'multiple-regex'

    use_dropdown = report_criteria_use_dropdown_options(config, value)
    if use_dropdown
      options.merge!(multiple: true)
      main_field = select_tag("search_attrs[#{name}]", use_dropdown, options)
    else
      options.merge!(
        type: config.type,
        class: 'form-control no-auto-submit multivalue-field-single',
        data: { attribute: name },
        placeholder: '(single value)'
      )

      main_field = text_field_tag("multiple_attrs[#{name}]", '', options)
      main_field += link_to('+', "add_multiple_attrs[#{name}]", data: { attribute: name },
                                                                class: 'btn btn-default add-btn multivalue-field-add',
                                                                title: 'add to search')
      v = value
      v = value.join("\n") if value.is_a? Array
      main_field += text_area_tag("search_attrs[#{name}]", v, class: 'auto-grow multivalue-field-vals',
                                                              placeholder: '(multiple values on separate lines)')

    end
    main_field
  end

  #
  # The markup for a single dropdown field, or nil if this is not a single dropdown field
  # @param [String | Symbol] name - HTML field name
  # @param [OptionConfigs::SearchAttributesConfig::NamedConfiguration] config
  # @param [Object] value - the field value
  # @param [Hash] options - field options
  # @return [String | nil]
  def report_criteria_dropdown_field(name, config, value, options)
    use_dropdown = report_criteria_use_dropdown_options(config, value)
    return unless use_dropdown

    options.merge!(include_blank: 'select', class: 'form-control')
    select_tag("search_attrs[#{name}]", use_dropdown, options)
  end

  #
  # The markup for a simple text field, which has an HTML5 type matching the config type
  # @param [String | Symbol] name - HTML field name
  # @param [OptionConfigs::SearchAttributesConfig::NamedConfiguration] config
  # @param [Object] value - the field value
  # @param [Hash] options - field options
  # @return [String | nil]
  def report_criteria_text_field(name, config, value, options)
    options.merge!(type: config.type, class: 'form-control')
    text_field_tag("search_attrs[#{name}]", value, options)
  end

  #
  # Options for select for a "select from model" resource names drop down
  # @return [options_for_select]
  def select_from_model_resource_name_options
    res = Resources::Models.all.values
                           .reject { |r| r.option_type }
                           .map { |r| ["#{r[:type]} - #{r[:model].human_name}", r[:resource_name]] }
                           .uniq
    options_for_select res
  end
end
