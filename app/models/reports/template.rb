# frozen_string_literal: true

module Reports
  #
  # Handle substitution of report tables into message templates
  class Template
    # Embed a report
    def self.embedded_report(report_name, list_id, list_type)
      t = Reports::Template.new
      t.embedded_report report_name, list_id, list_type
    end

    def embedded_report(report_name, list_id, list_type)
      search_attrs = { list_id: list_id, list_type: list_type }
      report = Report.active.find_by_alt_resource_name report_name
      runner = report.runner
      results = runner.run search_attrs
      result_tables = runner.result_tables_by_index || []
      outer_block_id = "report-container-#{SecureRandom.hex}"

      # Rails 5 or before, constructor was an argument with nil default value.
      # Rails 6, controller is required
      controller = nil
      view = ActionView::Base.new(ActionController::Base.view_paths, {}, controller)
      view.class_eval do
        include ApplicationHelper
        include ReportsHelper
        include ReportResults::ReportsCommonHelper
        include ReportResults::ReportsTableHelper
      end
      view.render(partial: 'reports/result_template/table',
                  locals: {
                    result_tables: result_tables,
                    report: report,
                    results: results,
                    outer_block_id: outer_block_id
                  }).html_safe
    end
  end
end
