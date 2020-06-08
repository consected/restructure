# frozen_string_literal: true

module Reports
  class Template
    # Embed a report
    def self.embedded_report(report_name, list_id, list_type)
      t = Reports::Template.new
      t.embedded_report report_name, list_id, list_type
    end

    def embedded_report(report_name, list_id, list_type)
      search_attrs = { list_id: list_id, list_type: list_type }
      report = Report.active.find_category_short_name report_name
      results = report.run search_attrs
      result_tables = report.result_tables_by_index || []
      outer_block_id = "report-container-#{SecureRandom.hex}"

      # ActionController::Base.new.render_to_string()
      view = ActionView::Base.new(ActionController::Base.view_paths, {})
      view.class_eval do
        include ApplicationHelper
        include ReportsHelper
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
