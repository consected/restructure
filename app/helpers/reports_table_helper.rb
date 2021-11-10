# frozen_string_literal: true

module ReportsTableHelper
  #
  # Setup column options at the start of the report
  def setup_column_options
    @col_classes = {}
    @col_tags = {}
    @col_hide = {}
    @show_as = {}

    @view_options = @report.report_options.view_options

    column_options = @report.report_options.column_options
    return unless column_options

    column_options.classes&.each do |k, v|
      @col_classes[k] = v.is_a?(Array) ? v.join(' ') : v
    end

    column_options.hide&.each do |k, v|
      @col_hide[k] = v
    end

    column_options.tags&.each do |k, v|
      @col_tags[k] = v
    end

    column_options.show_as&.each do |k, v|
      @show_as[k] = v
    end
  end

  #
  # Generate the full table cell markup
  def report_table_result_cell(field_num, col_content)
    orig_col_content = col_content
    col_name = report_column_name(field_num)

    if @view_options.show_all_booleans_as_checkboxed && [true, false].include?(col_content)
      @show_as[col_name] ||= 'checkbox'
    end

    cell = ReportsTableResultCell.new(col_content, col_name, @col_tags[col_name], @show_as[col_name])
    col_tag = cell.html_tag
    col_content = cell.view_content
    table_name = @result_tables[field_num]

    if col_tag.present?
      col_tag_start = "<#{col_tag} class=\"#{cell.expandable? ? 'expandable' : ''}\">"
      col_tag_end = "</#{col_tag}>"
    end

    extra_classes = ''
    extra_classes += 'report-el-object-id' if col_name == 'id'
    extra_classes += @col_classes[col_name] if @col_classes[col_name]
    if orig_col_content.instance_of?(Date) || orig_col_content.instance_of?(Time)
      # Keep an original version of the time, since the tag content will be updated with user preferences
      time_attr = "data-time-orig-val=\"#{orig_col_content}\""
    end

    res = <<~END_HTML
      <td data-col-type="#{col_name}"
          data-col-table="#{table_name}"
          data-col-var-type="#{orig_col_content.class.name}" #{time_attr}
          class="report-el #{extra_classes}">#{col_tag_start}#{col_content}#{col_tag_end}</td>
    END_HTML

    res.html_safe
  end

  def report_table_header_cell(field_num, header_content)
    col_name = report_column_name(field_num)
    cell = ReportsTableHeaderCell.new(header_content,
                                      table_name: @runner&.data_reference&.table_name,
                                      schema_name: @runner&.data_reference&.schema_name,
                                      view_options: @view_options)

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

    res = <<~END_HTML
      <th title="Click to sort. Shift+Click for sub-sort(s). Click again for descending sort." data-col-type="#{header_content}" class="table-header #{extra_classes}">
        #{field_name} #{show_table_name} #{col_comment}
      </th>
    END_HTML

    res.html_safe
  end

  def report_cell_hide?(field_num)
    col_name = report_column_name(field_num)
    @col_hide[col_name]
  end

  def report_column_name(field_num)
    @results.fields[field_num]
  end
end
