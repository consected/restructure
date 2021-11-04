# frozen_string_literal: true

#
# A non-helper class to support ReportsTableHelper, without
# polluting the global namespace
class ReportsTableCell
  attr_accessor :field_num, :cell_content, :col_tags, :show_as, :col_name, :view_options, :options

  def initialize(field_num, cell_content, col_name, options)
    self.field_num = field_num
    self.cell_content = cell_content
    self.col_name = col_name
    self.options = options
    self.col_tags = options[:col_tags]
    self.show_as = options[:show_as]
    self.view_options = options[:view_options]
  end

  #
  # Alter the cell tag based on configurations
  def html_tag
    col_show_as = @show_as[col_name]
    col_tag = @col_tags[col_name] || 'pre' if content_lines >= 1
    return col_tag if col_show_as.blank?

    mapping = {
      'div' => 'div',
      'fixed-pre' => 'pre',
      'checkbox' => 'div',
      'options' => 'div',
      'list' => 'ul',
      'url' => 'div'
    }

    mapping[col_show_as] || col_show_as
  end

  #
  # Update the cell content based on the original type
  def view_content
    col_show_as = @show_as[col_name]
    content_method = "cell_content_for_#{col_show_as}"
    if respond_to? content_method
      send(content_method)
    elsif cell_content.is_a?(Hash)
      cell_content.to_json
    else
      cell_content
    end
  end

  #
  # For "pre" strings with more than 4 lines, set the class as expandable,
  # unless the configuration states it should be a *fixed-pre*
  def expandable?
    col_tag = @col_tags[col_name]

    lines = content_lines
    col_tag ||= 'pre' if lines >= 1
    res = true if col_tag == 'pre' && lines > 4
    res = nil if @show_as[col_name] == 'fixed-pre'
    res
  end

  #
  # Count number of lines in the content if it is a String
  def content_lines
    l = cell_content&.scan("\n")&.length if cell_content.is_a?(String)
    l || 0
  end

  def column_comment
    return unless show_col_comments_tables

    if show_col_comments_tables.is_a? Array
      schema_tables = show_col_comments_tables
    elsif show_col_comments_tables
      tn = options[:table_name]
      sn = options[:schema_name]
      schema_tables = ["#{sn}.#{tn}"]
    end

    tab_col_comments = Admin::MigrationGenerator.column_comments
    comment = tab_col_comments.find do |tc|
      "#{tc['schema_name']}.#{tc['table_name']}".in?(schema_tables) && tc['column_name'] == cell_content
    end
    comment = comment['column_comment'] if comment

    comment
  end

  def data_dictionary_view
    tn = options[:table_name]

    corr_data_dic = view_options&.corresponding_data_dic || tn&.sub('_data', '')
    data_dic = Admin::MigrationGenerator.data_dic(corr_data_dic, nil_if_empty: true) if corr_data_dic

    comm_attrib = data_dic.find { |dd| dd['variable_name'] == @cell_content } if data_dic

    comm_attrib_txt = nil
    if comm_attrib
      comm_attrib = comm_attrib.dup
      domain = comm_attrib['domain']
      fa = comm_attrib['field_attributes']
      fn = comm_attrib['field_note']

      fa = "#{fa.split(' | ').join('<br/>')}<br/>" if fa.present?
      fn = "(#{fn})" if fn.present?

      comm_attrib_txt = "<div><span class=\"domain\">#{domain}</span><br/><span>#{fa}</span>#{fn}</div>"
    end

    comm_attrib_txt
  end

  def show_col_comments_tables
    view_options&.show_column_comments
  end

  #####
  # Cell content rendering for different types of original content
  #####

  def cell_content_for_checkbox
    cb = if cell_content
           '<span class="glyphicon glyphicon-check val-true"></span>'
         else
           '<span class="val-false"></span>'
         end
    "<div class=\"report-cb-inner\">#{cb}</div>".html_safe
  end

  def cell_content_for_options
    # We expect options to be a Hash, but if it is a String we'll assume it is JSON
    opts = JSON.parse(cell_content) if cell_content.is_a?(String) && cell_content.present?

    if opts
      cell_content = opts.map do |citem|
        "<div class=\"report-option-items\"><div><strong>#{citem.first}</strong>&nbsp;<span>#{citem.last}</span></div></div>"
      end.join('').html_safe
    end
    cell_content
  end

  def cell_content_for_list
    # We expect options to be an Array, but if it is a String we'll assume it is JSON
    list = JSON.parse(cell_content) if cell_content.is_a?(String) && cell_content.present?

    if list
      cell_content = list.map do |citem|
        "<li class=\"report-list-items\">#{citem}</li>"
      end.join('').html_safe
    end
    cell_content
  end

  def cell_content_for_url
    return cell_content unless cell_content.present?

    col_url_parts = cell_content&.scan(/^\[([\w\s\d]+)\]\((.+)\)$/)
    html = <<~END_HTML
      <a href="#{col_url_parts&.first&.last}" target="_blank">#{col_url_parts&.first&.first}</a>
    END_HTML

    html.html_safe
  end
end
