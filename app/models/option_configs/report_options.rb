# frozen_string_literal: true

module OptionConfigs
  #
  # Report options, defining all options that are not directly SQL or search attributes.
  #
  # For details on about the YAML configuration
  # @see OptionConfigs::AttrDefs::Report
  class ReportOptions < BaseOptions
    include OptionsHandler

    SHARED_VIEW_OPTIONS = %i[
      hide_table_names hide_field_names_with_comments humanize_column_names hide_result_count
      hide_export_buttons hide_criteria_panel show_column_comments corresponding_data_dic view_as
      show_all_booleans_as_checkboxed hide_list_labels_for_empty_content no_sorting result_handlers
      add_classes prevent_adding_items use_plain_attribute_names
    ].freeze
    REPORT_PAGE_VIEW_OPTIONS = %i[
      hide_report_button hide_count_button show_list_records_button report_button_label
      list_records_button_label no_report_results_scroll auto_submit_on_load auto_submit_on_change
      auto_submit_target
    ].freeze
    LEGACY_VIEW_OPTIONS = %i[hide_search_button hide_master_results_list_search_button
                             force_show_search_button search_button_label report_auto_submit_on_change
                             no_results_scroll prevent_collapse_for_list].freeze
    SEARCH_PANEL_OPTIONS = %i[search_records_button_label hide_search_records_button
                              prevent_collapse_for_search_panel_results auto_submit_on_load
                              auto_submit_on_change].freeze
    EMBEDDED_OPTIONS = %i[hide_report_button report_button_label auto_submit_on_load
                          auto_submit_on_change].freeze

    configure :view_options, with: REPORT_PAGE_VIEW_OPTIONS + SHARED_VIEW_OPTIONS + LEGACY_VIEW_OPTIONS
    configure :search_panel_options, with: SEARCH_PANEL_OPTIONS
    configure :embedded_options, with: EMBEDDED_OPTIONS

    configure :list_options, with: %i[hide_in_list list_description get_query_count]
    configure :tree_view_options, with: %i[num_levels column_levels expand_level]
    configure :plain_text_options, with: %i[results_column return_content_type
                                            line_join_string column_join_string
                                            line_prefix line_suffix
                                            column_prefix column_suffix
                                            header_text footer_text
                                            template]
    configure :json_options, with: %i[show_as template key_column single_result]
    configure :view_css, with: %i[classes selectors media_queries]
    configure :criteria_css, with: %i[classes selectors media_queries]
    configure :master_results_css, with: %i[classes selectors media_queries]
    configure :component, with: [:options]
    configure :column_options, with: %i[tags classes hide show_as alt_column_header]

    attr_accessor :report

    def self.raise_bad_configs(option_configs)
      result_handlers = option_configs.view_options.result_handlers
      if result_handlers && !result_handlers.is_a?(Array)
        raise FphsException, 'options view_options.result_handlers must be an array of handler names'
      end

      validate_auto_submit_flags!(:view_options, option_configs.view_options)
      validate_auto_submit_flags!(:search_panel_options, option_configs.search_panel_options)
      validate_auto_submit_flags!(:embedded_options, option_configs.embedded_options)

      target = option_configs.view_options.auto_submit_target
      return if target.nil? || %w[report list_records].include?(target)

      raise FphsException, 'options view_options.auto_submit_target must be report or list_records'
    end

    def self.new_report_options_skeleton
      view_options = ViewOptions.configure_with_items - LEGACY_VIEW_OPTIONS
      report_page_options = REPORT_PAGE_VIEW_OPTIONS & view_options
      shared_options = view_options - report_page_options
      groups = [
        ['view_options', [['report page view_options', report_page_options],
                          ['shared view_options', shared_options]]],
        ['search_panel_options', [['search_panel_options', SearchPanelOptions.configure_with_items]]],
        ['embedded_options', [['embedded_options', EmbeddedOptions.configure_with_items]]]
      ]

      lines = groups.flat_map do |section, option_groups|
        section_lines = ["#{section}:"]
        option_groups.each do |label, option_keys|
          section_lines << "  # #{label}"
          option_keys.each { |option_key| section_lines << "  #{option_key}:" }
        end
        section_lines << ''
        section_lines
      end.join("\n").rstrip
      "#{lines}\n"
    end

    def self.validate_auto_submit_flags!(context, configuration)
      %i[auto_submit_on_load auto_submit_on_change].each do |flag|
        value = configuration.public_send(flag)
        next if value.nil? || value == true || value == false

        raise FphsException, "options #{context}.#{flag} must be true, false or null"
      end
    end
    private_class_method :validate_auto_submit_flags!

    #
    # Returns the options text version specific to this report
    # @return [String] options text
    def config_text
      owner.options
    end

    def config_text=(value)
      owner.options = value
    end

    #
    # Required to support the initialization of options outside of a model
    # @see ActiveRecord::Persistence#persisted?
    def persisted?
      owner.persisted?
    end
  end
end
