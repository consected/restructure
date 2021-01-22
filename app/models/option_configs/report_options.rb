module OptionConfigs
  class ReportOptions < BaseOptions
    def self.raise_bad_configs(option_configs)
      # None defined - override with real checks
      # @todo
    end

    def self.attr_defs
      <<~END_YAML
        view_options:
          hide_table_names:
          humanize_column_names:
          hide_result_count:
          hide_export_buttons:
          hide_criteria_panel:
          prevent_collapse_for_list:
          show_column_comments:
          corresponding_data_dic:
          view_as:
          search_button_label:
          report_auto_submit_on_change:
          no_results_scroll:

        list_options:
          hide_in_list:
          list_description:

        view_css:
          classes:
          selectors:

        component:
          options:

        column_options:
          tags:
          classes:
          hide:
          show_as:

      END_YAML
    end
  end
end
