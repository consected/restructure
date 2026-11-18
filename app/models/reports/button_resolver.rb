# frozen_string_literal: true

module Reports
  # Resolves button and auto-submit behavior for the new report report type.
  class ButtonResolver
    Button = Struct.new(:key, :label, :commit, :hidden, :classes, keyword_init: true) do
      def hidden?
        hidden
      end
    end

    Result = Struct.new(:buttons, :auto_submit_target, :auto_submit_on_load,
                        :auto_submit_on_change, :hide_result_count, :hide_export_buttons,
                        :no_report_results_scroll,
                        :prevent_collapse_for_search_panel_results,
                        keyword_init: true) do
      def auto_submit_on_load?
        auto_submit_on_load
      end

      def auto_submit_on_change?
        auto_submit_on_change
      end

      def hide_result_count?
        hide_result_count
      end

      def hide_export_buttons?
        hide_export_buttons
      end

      def no_report_results_scroll?
        no_report_results_scroll
      end

      def prevent_collapse_for_search_panel_results?
        prevent_collapse_for_search_panel_results
      end
    end

    Contexts = %i[search_panel report_page embedded].freeze

    def self.resolve(report:, context:, options: nil, force_run: false)
      return unless report.report_type == 'report'

      context = context.to_sym
      raise ArgumentError, "Unknown report button context: #{context}" unless context.in?(Contexts)

      new(report:, context:, options:, force_run:).resolve
    end

    def initialize(report:, context:, options:, force_run:)
      @report = report
      @context = context
      @options = options
      @force_run = [true, 'true'].include?(force_run)
    end

    def resolve
      @auto_submit_on_load = @force_run || enabled_option?(:auto_submit_on_load)
      @auto_submit_on_change = enabled_option?(:auto_submit_on_change)
      @auto_submit_target = target_button

      Result.new(
        buttons: context_buttons,
        auto_submit_target: @auto_submit_target,
        auto_submit_on_load: @auto_submit_on_load,
        auto_submit_on_change: @auto_submit_on_change,
        hide_result_count: option_value(:view_options, :hide_result_count) == true,
        hide_export_buttons: option_value(:view_options, :hide_export_buttons) == true,
        no_report_results_scroll: no_report_results_scroll?,
        prevent_collapse_for_search_panel_results: prevent_collapse_for_search_panel_results?
      )
    end

    private

    def context_buttons
      buttons = { list_records: nil, report: nil, count: nil }
      buttons.merge!(
        case @context
        when :search_panel then search_panel_buttons
        when :report_page then report_page_buttons
        when :embedded then embedded_buttons
        end
      )
    end

    def search_panel_buttons
      {
        list_records: build_button(
          :list_records,
          option_value(:search_panel_options, :search_records_button_label).presence || 'search',
          'search',
          option_value(:search_panel_options, :hide_search_records_button) == true
        )
      }
    end

    def report_page_buttons
      {
        list_records: build_button(
          :list_records,
          option_value(:view_options, :list_records_button_label).presence || 'list records',
          'search',
          option_value(:view_options, :show_list_records_button) != true
        ),
        report: build_button(
          :report,
          option_value(:view_options, :report_button_label).presence || 'report',
          'table',
          option_value(:view_options, :hide_report_button) == true
        ),
        count: build_button(:count, 'count', 'count', option_value(:view_options, :hide_count_button) == true)
      }
    end

    def embedded_buttons
      {
        report: build_button(
          :report,
          option_value(:embedded_options, :report_button_label).presence || 'report',
          'table',
          option_value(:embedded_options, :hide_report_button) == true
        )
      }
    end

    def target_button
      case @context
      when :search_panel
        :list_records
      when :embedded
        :report
      when :report_page
        configured_target = option_value(:view_options, :auto_submit_target)
        return configured_target.to_sym if configured_target.present?
        return :list_records if option_value(:view_options, :hide_report_button) == true

        :report
      end
    end

    def build_button(key, label, commit, hidden)
      classes = []
      classes << 'hidden' if hidden
      if key == @auto_submit_target
        classes << 'auto-submitter' if @auto_submit_on_change
        classes << 'auto-run' if @auto_submit_on_load
      end

      Button.new(key:, label:, commit:, hidden:, classes:)
    end

    def enabled_option?(name)
      option_value(option_context, name) == true
    end

    def option_context
      case @context
      when :search_panel then :search_panel_options
      when :embedded then :embedded_options
      else :view_options
      end
    end

    def option_value(group_name, option_name)
      group = fetch_value(@options, group_name)
      fetch_value(group, option_name)
    end

    def fetch_value(container, key)
      return if container.nil?
      return container.public_send(key) if container.respond_to?(key)
      return container[key] if container.respond_to?(:key?) && container.key?(key)

      string_key = key.to_s
      container[string_key] if container.respond_to?(:key?) && container.key?(string_key)
    end

    def no_report_results_scroll?
      return true if @context == :embedded
      return false unless @context == :report_page

      option_value(:view_options, :no_report_results_scroll) == true
    end

    def prevent_collapse_for_search_panel_results?
      return false unless @context == :search_panel

      option_value(:search_panel_options, :prevent_collapse_for_search_panel_results) == true
    end
  end
end
