# frozen_string_literal: true

#
# A non-helper class to support ReportsTableHelper, without
# polluting the global namespace
class ReportsTableHeaderCell
  attr_accessor :header_content, :view_options, :options, :table_name, :schema_name

  def initialize(header_content, options)
    self.header_content = header_content
    self.options = options
    self.view_options = options[:view_options]
    self.table_name = options[:table_name]
    self.schema_name = options[:schema_name]
  end

  def html_escape(str)
    ERB::Util.html_escape str
  end

  def column_comment
    return unless show_col_comments_tables

    if show_col_comments_tables.is_a? Array
      schema_tables = show_col_comments_tables
    elsif show_col_comments_tables
      schema_tables = ["#{schema_name}.#{table_name}"]
    end

    tab_col_comments = Admin::MigrationGenerator.column_comments
    comment_config = tab_col_comments.find do |tc|
      "#{tc['schema_name']}.#{tc['table_name']}".in?(schema_tables) && tc['column_name'] == header_content
    end
    comment = comment_config['column_comment'] if comment_config

    comment
  end

  def data_dictionary_view
    corr_data_dic = view_options&.corresponding_data_dic || table_name&.sub('_data', '')
    return unless corr_data_dic

    data_dic = Admin::MigrationGenerator.data_dic(corr_data_dic, nil_if_empty: true)
    return unless data_dic

    comm_attrib = data_dic.find { |dd| dd['variable_name'] == header_content }
    return unless comm_attrib

    comm_attrib = comm_attrib.dup
    domain = comm_attrib['domain']

    fa = comm_attrib['field_attributes']
    fn = comm_attrib['field_note']
    fa = "#{fa.split(' | ').map { |a| html_escape a }.join('<br/>')}<br/>" if fa.present?
    fn = "html_escape (#{fn})" if fn.present?

    comm_attrib_txt = <<~END_HTML
      <div><span class="domain">#{html_escape domain}</span><br/><span>#{fa}</span>#{fn}</div>
    END_HTML

    comm_attrib_txt.html_safe
  end

  def show_col_comments_tables
    view_options&.show_column_comments
  end
end
