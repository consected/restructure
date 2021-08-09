# frozen_string_literal: true

module OptionConfigs
  #
  # Map options to a format consumable by view templates
  # This is a stopgap until dynamic model and activity log definitions
  # are fully aligned
  class TemplateOptionMapping
    def self.external_identifier_mapping(def_record, option_type_config, current_user)
      external_id_type = def_record.implementation_class

      formatter = external_id_type.external_id_view_formatter
      pattern = external_id_type.external_id_edit_pattern
      formatter = 'pattern_mask "' + pattern.gsub('\\', '\\\\') + '"' if formatter.blank? && !pattern.blank?

      field_list = def_record.field_list_array
      view_options = option_type_config.view_options

      plural_name = external_id_type.plural_name

      {
        def_record: def_record,
        def_version: def_record.def_version,
        caption: view_options[:header_caption] || external_id_type.label,
        button_label: option_type_config.button_label || external_id_type.label,
        name: external_id_type.name.underscore,
        full_name: external_id_type.name.underscore,
        resource_name: def_record.resource_name,

        model_data_type: :external_identifier,
        prevent_edit: external_id_type.prevent_edit? ||
          !(current_user.has_access_to? :edit, :table, plural_name),
        prevent_create: external_id_type.prevent_create? ||
          !(current_user.has_access_to? :create, :table, plural_name),
        item_list: field_list,
        caption_before: option_type_config.caption_before,
        dialog_before: option_type_config.dialog_before,
        labels: option_type_config.labels,
        show_if: option_type_config.show_if,
        data_sort: [:desc, 'data-updated-at-ts'],
        category: def_record.category,
        view_options: view_options,
        extra_class: view_options[:extra_class],
        template_class: nil,
        extra_data_attribs: field_list.include?('rec_type') ? [:rec_type] : nil,
        extra_options_config: option_type_config,
        external_id_options: {
          label: external_id_type.label,
          formatter: formatter,
          attribute: external_id_type.external_id_attribute.to_s
        },
        orientation: 'vertical',
        add_item_label: external_id_type.label
      }
    end

    def self.dynamic_model_mapping(def_record, option_type_config, current_user)
      unless def_record.model_class
        raise FphsException,
              'dynamic_model_mapping model class not defined for ' \
              "#{def_record} #{def_record.implementation_model_name}\n" \
              'Check the user access controls allow access within this app'
      end

      dfla = def_record.field_list_array
      field_list = dfla.present? ? dfla : def_record.default_field_list_array

      item_list = field_list.dup

      # For address models, the front-end currently has a naming requirement that doesn't match the field
      # definitions. Change *country* and *state* to *country_name* and *state_name*
      if item_list - %w[country state] != item_list
        item_list[item_list.index('country')] = 'country_name' if item_list.include? 'country'
        item_list[item_list.index('state')] = 'state_name' if item_list.include? 'state'
      end

      data_sort = [:desc, 'data-rank'] if def_record.model_class&.attribute_names&.include? 'rank'
      default_options = option_type_config
      view_options = default_options.view_options

      {
        def_record: def_record,
        def_version: def_record.def_version,
        caption: view_options[:header_caption] || def_record.name,
        button_label: default_options.button_label,
        name: def_record.implementation_model_name,
        full_name: "dynamic_model__#{def_record.implementation_model_name}",
        resource_name: def_record.resource_name,

        model_data_type: :dynamic_model,
        prevent_edit: !(current_user.has_access_to? :edit, :table, def_record.full_item_type_name.pluralize),
        prevent_create: !(current_user.has_access_to? :create, :table, def_record.full_item_type_name.pluralize),
        item_list: item_list,
        caption_before: default_options.caption_before,
        dialog_before: default_options.dialog_before,
        labels: default_options.labels,
        show_if: default_options.show_if,
        data_sort: data_sort,
        category: def_record.category,
        view_options: view_options,
        extra_class: view_options[:extra_class],
        template_class: nil,
        extra_data_attribs: field_list.include?('rec_type') ? [:rec_type] : nil,
        extra_options_config: default_options
      }
    end

    def self.activity_log_mapping(def_record, option_type_config, current_user)
      current_definition = def_record.current_definition || def_record
      view_options = option_type_config.view_options || {}

      if def_record.hide_item_list_panel
        col_width = 6
        col_width_md = 8
      else
        col_width = 8
        col_width_md = 12
      end
      col_width_classes = "col-md-#{col_width_md} col-lg-#{col_width}"

      cwc = if view_options[:alt_width_classes]
              view_options[:alt_width_classes]
            elsif option_type_config.e_sign
              'e-sign-doc col-md-24 col-lg-12'
            else
              col_width_classes
            end

      full_name = def_record.full_item_type_name
      data_action_when = "data_#{current_definition.action_when_attribute}".to_sym

      {
        def_record: def_record,
        def_version: def_record.def_version,
        caption: view_options[:header_caption] || option_type_config.label,
        name: "#{full_name}_#{option_type_config.name}",
        full_name: "#{full_name}_#{option_type_config.name}",
        model_data_type: :activity_log,
        item_class_name: full_name,
        resource_name: "#{full_name}__#{option_type_config.name}",

        button_label: option_type_config.button_label,
        prevent_edit: !(current_user.has_access_to? :edit, :table, def_record.full_item_type_name.pluralize),
        prevent_create: !(current_user.has_access_to? :create, :table, def_record.full_item_type_name.pluralize),
        only_see_presence: current_user.has_access_to?(
          :see_presence,
          :activity_log_type,
          option_type_config.resource_name
        ),
        template_class: "alt-width #{cwc}",
        extra_class: view_options[:extra_class],
        item_list: option_type_config.fields,
        data_sort: [:desc, data_action_when],
        subsort_id: true,
        custom_activity_log: :none,
        implementation_class: def_record.implementation_class,
        implementation_class_name: def_record.item_type_name,
        item_blocks: { def_record.item_type.to_sym => def_record.implementation_class.parent_data_names },
        show_created_at: true,
        edit_button_href: "/masters/{{master_id}}/{{#if item_id}}#{def_record.item_type.pluralize}/"\
                          "{{item_id}}/{{/if}}activity_log/#{def_record.item_type_name.pluralize}/{{id}}/edit",
        caption_before: option_type_config.caption_before,
        dialog_before: option_type_config.dialog_before,
        labels: option_type_config.labels,
        item_flags_after: 'notes',
        item_flags_readonly: true,
        extra_type: option_type_config.name,
        references: option_type_config.references,
        show_if: option_type_config.show_if,
        view_options: view_options,
        extra_data_attribs: [:extra_log_type],
        extra_options_config: option_type_config
      }
    end

    def self.activity_log_all_configs_mapping(def_record, current_user)
      current_definition = def_record.current_definition || def_record

      {
        def_record: def_record,
        def_version: def_record.def_version,
        caption: def_record.name,
        name: def_record.item_type_name,
        prevent_edit: !(current_user.has_access_to? :edit, :table, def_record.full_item_type_name.pluralize),
        prevent_create: !(current_user.has_access_to? :create, :table, def_record.full_item_type_name.pluralize),
        item_list: def_record.implementation_class.view_attribute_list,
        implementation_class: def_record.implementation_class,
        implementation_class_name: def_record.item_type_name,
        option_configs: def_record.option_configs,
        al_name: def_record.name,
        rec_type: def_record.rec_type,
        item_type: def_record.item_type,
        action_when_attribute: current_definition.action_when_attribute,
        item_type_name: def_record.item_type_name,
        full_name: def_record.full_item_type_name,
        blank_log_full_name: "#{def_record.full_item_type_name}_blank_log",
        blank_log_label: (def_record.blank_log_name.blank? ? 'General Log' : def_record.blank_log_name),
        main_log_label: (def_record.main_log_name.blank? ? 'Add Log' : def_record.main_log_name),
        hide_item_list_panel: !!def_record.hide_item_list_panel,
        template_class: nil
      }
    end
  end
end
