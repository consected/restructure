# frozen_string_literal: true

module ReportResults
  module ReportsListHelper
    #
    # Generate the full table cell markup
    def report_list_result_cell(field_num, col_content)
      orig_col_content = col_content
      col_name = report_column_name(field_num)

      if @view_options&.show_all_booleans_as_checkboxed && [true, false].include?(col_content)
        @show_as[col_name] ||= 'checkbox'
      end

      table_name = @result_tables[field_num]

      cell = ReportResults::ReportsListResultCell.new(table_name, col_content, col_name, @col_tags[col_name], @show_as[col_name],
                                                      selection_options_handler_for(table_name))
      col_tag = cell.html_tag
      col_content = cell.view_content

      col_tag = 'rldata' unless col_tag.present?

      col_tag_start = "<#{col_tag} class=\"#{cell.expandable? ? 'expandable' : ''}\">"
      col_tag_end = "</#{col_tag}>"

      extra_classes = ''
      extra_classes += 'report-el-object-id' if col_name == 'id'
      extra_classes += @col_classes[col_name] if @col_classes[col_name]
      if orig_col_content.instance_of?(Date) || orig_col_content.instance_of?(Time)
        # Keep an original version of the time, since the tag content will be updated with user preferences
        orig_col_content = orig_col_content.utc if orig_col_content.respond_to?(:utc)
        time_attr = "data-time-orig-val=\"#{orig_col_content}\""
        col_content = orig_col_content
      end

      header_content = alt_column_header(field_num) || @results.fields[field_num]
      header_content = @view_options&.humanize_column_names ? header_content.humanize : header_content
      if header_content.present? && !(@view_options&.hide_list_labels_for_empty_content && !orig_col_content.present?)
        header_markup = <<~END_HTML
          <span class="report-list-header-item">#{header_content}</span>
        END_HTML
      end

      res = <<~END_HTML
        <div data-col-type="#{col_name}"
            data-col-table="#{table_name}"
            data-col-var-type="#{orig_col_content.class.name}" #{time_attr}
            class="report-list-el #{extra_classes}">
          #{header_markup}
          #{col_tag_start}#{col_content}#{col_tag_end}
        </div>
      END_HTML

      res.html_safe
    end
  end
end
