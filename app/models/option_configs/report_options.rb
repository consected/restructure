module OptionConfigs
  class ReportOptions < BaseOptions
    include OptionsHandler

    configure :view_options, with: %i[hide_table_names humanize_column_names
                                      hide_result_count hide_export_buttons
                                      hide_criteria_panel prevent_collapse_for_list
                                      show_column_comments corresponding_data_dic
                                      view_as search_button_label report_auto_submit_on_change
                                      no_results_scroll]
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
    def options
      owner.options
    end

    #
    # Required to support the initialization of options outside of a model
    # @see ActiveRecord::Persistence#persisted?
    def persisted?
      owner.persisted?
    end
  end
end
