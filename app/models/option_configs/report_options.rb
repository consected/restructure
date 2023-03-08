# frozen_string_literal: true

module OptionConfigs
  #
  # Report options, defining all options that are not directly SQL or search attributes.
  #
  # For details on about the YAML configuration
  # @see OptionConfigs::AttrDefs::Report
  class ReportOptions < BaseOptions
    include OptionsHandler

    configure :view_options, with: %i[hide_table_names
                                      hide_field_names_with_comments
                                      humanize_column_names
                                      hide_result_count hide_export_buttons hide_search_button
                                      hide_criteria_panel prevent_collapse_for_list
                                      show_column_comments corresponding_data_dic
                                      view_as search_button_label report_auto_submit_on_change
                                      no_results_scroll show_all_booleans_as_checkboxed
                                      hide_list_labels_for_empty_content
                                      force_show_search_button no_sorting result_handlers add_classes
                                      prevent_adding_items]

    configure :list_options, with: %i[hide_in_list list_description]
    configure :tree_view_options, with: %i[num_levels column_levels expand_level]
    configure :view_css, with: %i[classes selectors media_queries]
    configure :criteria_css, with: %i[classes selectors media_queries]
    configure :master_results_css, with: %i[classes selectors media_queries]
    configure :component, with: [:options]
    configure :column_options, with: %i[tags classes hide show_as alt_column_header]

    attr_accessor :report

    def self.raise_bad_configs(option_configs)
      vo = option_configs.view_options.result_handlers
      return if !vo || vo.is_a?(Array)

      raise FphsException, 'options view_options.result_handlers must be an array of handler names'
    end

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
