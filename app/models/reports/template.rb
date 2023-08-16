# frozen_string_literal: true

module Reports
  #
  # Handle substitution of report tables into message templates
  class Template
    # Embed a report
    def self.embedded_report(report_name, list_id, list_type, list_master_id = nil)
      t = Reports::Template.new
      t.embedded_report report_name, list_id, list_type, list_master_id
    end

    def embedded_report(report_name, list_id, list_type, list_master_id = nil)
      search_attrs = { list_id: list_id, list_type: list_type }
      search_attrs[:master_id] = list_master_id if list_master_id
      report = Report.active.find_by_alt_resource_name report_name
      runner = report.runner
      results = runner.run search_attrs
      result_tables = runner.result_tables_by_index || []
      outer_block_id = "report-container-#{SecureRandom.hex}"

      html = ApplicationController.render(partial: 'reports/result_template/table',
                                          locals: {
                                            result_tables: result_tables,
                                            report: report,
                                            results: results,
                                            outer_block_id: outer_block_id
                                          }).html_safe
      html = <<~END_HTML
        <div class="embedded-report-block" id="embedded-report-block--#{list_id}-#{list_type}-#{list_master_id}">
          #{html}
        </div>
      END_HTML

      html.html_safe
    end
  end
end
