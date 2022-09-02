# frozen_string_literal: true

module ReportResults
  module ReportsCommonHelper
    #
    # Setup column options at the start of the report
    def setup_column_options
      @col_classes = {}
      @col_tags = {}
      @col_hide = {}
      @show_as = {}
      @alt_column_header = {}

      @view_options = @report.report_options.view_options
      @tree_view_options = @report.report_options.tree_view_options
      @column_types = column_types

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

      column_options.alt_column_header&.each do |k, v|
        @alt_column_header[k] = v
      end
    end

    def report_cell_hide?(field_num)
      col_name = report_column_name(field_num)
      @col_hide[col_name]
    end

    def report_column_name(field_num)
      @results.fields[field_num]
    end

    def alt_column_header(field_num)
      col_name = report_column_name(field_num)
      @alt_column_header[col_name]
    end

    #
    # Returns a selection option handler set up for the specified table name
    # Memoizes it, allowing the internal memoization of the handler object to function
    # @param [String | Symbol] table_name
    # @return [Classification::SelectionOptionsHandler]
    def selection_options_handler_for(table_name)
      table_name = table_name.to_s
      @selection_options_for ||= {}
      return @selection_options_for[table_name] if @selection_options_for.key?(table_name)

      @selection_options_for[table_name] = Classification::SelectionOptionsHandler.new(table_name: table_name)
    end

    #
    # Return an array of DB column types (strings) for the columns
    # For example: ['timestamp', 'date', 'varchar', 'int4']
    # @return [Array{String}]
    def column_types
      @results&.type_map&.coders&.map(&:name) || []
    end
  end
end
