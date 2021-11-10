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
                                      hide_result_count hide_export_buttons
                                      hide_criteria_panel prevent_collapse_for_list
                                      show_column_comments corresponding_data_dic
                                      view_as search_button_label report_auto_submit_on_change
                                      no_results_scroll show_all_booleans_as_checkboxed]
    configure :list_options, with: %i[hide_in_list list_description]
    configure :view_css, with: %i[classes selectors]
    configure :component, with: [:options]
    configure :column_options, with: %i[tags classes hide show_as]

    attr_accessor :report

    def self.raise_bad_configs(option_configs)
      # None defined - override with real checks
      # @todo
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
