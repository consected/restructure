# frozen_string_literal: true

module ReportResults
  module ReportsTableHelper
    #
    # Generate the full table cell markup
    def report_table_result_cell(field_num, col_content)
      orig_col_content = col_content
      col_name = report_column_name(field_num)

      if @view_options&.show_all_booleans_as_checkboxed && [true, false].include?(col_content)
        @show_as[col_name] ||= 'checkbox'
      end

      table_name = @result_tables[field_num]

      cell = ReportResults::ReportsTableResultCell.new(table_name, col_content, col_name, @col_tags[col_name], @show_as[col_name],
                                                       selection_options_handler_for(table_name))
      col_tag = cell.html_tag
      col_content = cell.view_content

      if col_tag.present?
        col_tag_start = "<#{col_tag} class=\"#{cell.expandable? ? 'expandable' : ''}\">"
        col_tag_end = "</#{col_tag}>"
      end

      extra_classes = ''
      extra_classes += 'report-el-object-id' if col_name == 'id'
      extra_classes += @col_classes[col_name] if @col_classes[col_name]
      if orig_col_content.instance_of?(Date) || orig_col_content.instance_of?(Time)
        # Keep an original version of the time, since the tag content will be updated with user preferences
        orig_col_content = orig_col_content.utc if orig_col_content.respond_to?(:utc)
        time_attr = "data-time-orig-val=\"#{orig_col_content}\""
        col_content = orig_col_content
      end

      res = <<~END_HTML
        <td data-col-type="#{col_name}"
            data-col-table="#{table_name}"
            data-col-var-type="#{orig_col_content.class.name}" #{time_attr}
            class="report-el #{extra_classes}">#{col_tag_start}#{col_content}#{col_tag_end}</td>
      END_HTML

      res.html_safe
    end

    def report_table_header_cell(field_num, header_content, alt_html_tag = nil)
      alt_html_tag ||= 'th'
      col_name = report_column_name(field_num)
      cell = ReportResults::ReportsTableHeaderCell.new(header_content,
                                                       table_name: @runner&.data_reference&.table_name,
                                                       schema_name: @runner&.data_reference&.schema_name,
                                                       view_options: @view_options)

      header_content = alt_column_header(field_num) || header_content

      comment = cell.column_comment
      view_opt = @view_options
      unless view_opt.hide_field_names_with_comments && comment
        new_col_content = view_opt.humanize_column_names ? header_content.humanize : header_content
        field_name = "<p class=\"table-header-col-type\">#{new_col_content}</p>"
      end

      num_tables = @result_tables.uniq.length
      table_name = @result_tables[field_num]

      unless num_tables == 1 || view_opt.hide_table_names
        show_table_name = <<~END_HTML
          <p class="small report-table-name" title="#{table_name}">#{table_name}</p>
        END_HTML
      end

      if cell.show_col_comments_tables
        comm_attrib_txt = cell.data_dictionary_view
        if comm_attrib_txt
          comm_attrib_tag = <<~END_HTML
            <div class="report-column-comment report-column-attribs">
              #{comm_attrib_txt}
            </div>
          END_HTML
          comm_attrib_tag = comm_attrib_tag.html_safe
        end

        col_comment = <<~END_HTML
          <p class="report-column-comment">#{comment}</p>
          #{comm_attrib_tag}
        END_HTML
        col_comment = col_comment.html_safe
      end

      extra_classes = @col_classes[col_name] || ''
      extra_classes = "#{extra_classes} #{comment.present? ? 'has-comment' : 'no-comment'}"

      extra_data = "data-db-col-type=\"#{@column_types[field_num]}\""
      extra_data += ' data-sorter="sqlDate"' if @column_types[field_num]&.in?(['timestamp', 'date'])

      show_as = @show_as[col_name]

      res = <<~END_HTML
        <#{alt_html_tag} title="Click to sort. Shift+Click for sub-sort(s). Click again for descending sort." data-col-type="#{header_content}" data-col-name="#{col_name}" data-col-show-as="#{show_as}" class="table-header #{extra_classes}" #{extra_data}>
          #{field_name} #{show_table_name} #{col_comment}
        </#{alt_html_tag}>
      END_HTML

      res.html_safe
    end
  end
end
