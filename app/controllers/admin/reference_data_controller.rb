# frozen_string_literal: true

class Admin::ReferenceDataController < ApplicationController
  before_action :authenticate_user_or_admin!

  def index
    render 'admin/reference_data/index'
  end

  def table_list
    return not_authorized unless current_admin || current_user.can?(:view_data_reference)

    render partial: 'admin/reference_data/table_list_block'
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
