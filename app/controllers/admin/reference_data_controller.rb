# frozen_string_literal: true

class Admin::ReferenceDataController < ApplicationController
  before_action :authenticate_user_or_admin!

  def index
    render 'admin/reference_data/index'
  end

  def table_list
    return not_authorized unless current_admin || current_user.can?(:view_data_reference)

    @schemas = Admin::MigrationGenerator.current_search_paths.uniq.sort
    render partial: 'admin/reference_data/table_list_block_part'
  end

  def table_list_tables
    return not_authorized unless current_admin || current_user.can?(:view_data_reference)

    @schema_name = params[:schema_name]
    @can_view_table_data = current_admin || current_user.has_access_to?(:read, :report, :reference_data__table_data)
    @table_info_for_schema = Admin::MigrationGenerator.tables_and_views
                                                      .filter { |ti| ti['schema_name'] == @schema_name }

    render partial: 'table_list_schema_tables.html'
  end

  def table_list_columns
    return not_authorized unless current_admin || current_user.can?(:view_data_reference)

    @table_name = params[:table_name]
    @schema_name = params[:schema_name]

    connection = Admin::MigrationGenerator.connection
    @columns = connection.columns("#{@schema_name}.#{@table_name}")
    @column_comments = Admin::MigrationGenerator.column_comments
    @column_fks = Admin::MigrationGenerator.foreign_keys

    render partial: 'admin/reference_data/table_columns_part'
  end

  def data_dic
    return not_authorized unless current_admin || current_user.can?(:view_data_reference)

    render partial: 'admin/reference_data/data_dic_block'
  end

  private

  def no_action_log
    true
  end
end
