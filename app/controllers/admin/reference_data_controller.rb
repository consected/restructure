# frozen_string_literal: true

class Admin::ReferenceDataController < ApplicationController
  before_action :authenticate_user_or_admin!

  def index
    render 'admin/reference_data/index'
  end

  def table_list
    return not_authorized unless current_admin || current_user.can?(:view_data_reference)

    Admin::MigrationGenerator.tables_and_views_reset!
    @schemas = Admin::MigrationGenerator.current_search_paths.uniq.sort
    @table_search_items = Admin::TableViewInfo.search_items
    render partial: 'admin/reference_data/table_list_block_part'
  end

  def table_list_tables
    return not_authorized unless current_admin || current_user.can?(:view_data_reference)
    return head :bad_request if params[:schema_name].blank?

    Admin::MigrationGenerator.tables_and_views_reset!
    @schema_name = params[:schema_name].to_s
    @can_view_table_data = current_admin || current_user.has_access_to?(:read, :report, :reference_data__table_data)
    @table_info_for_schema = Admin::MigrationGenerator.tables_and_views
                                                      .filter { |ti| ti['schema_name'] == @schema_name }
    @dynamic_definitions = Admin::TableViewInfo.dynamic_definitions_in_schema(@schema_name)

    render partial: 'table_list_schema_tables'
  end

  def table_list_columns
    return not_authorized unless current_admin || current_user.can?(:view_data_reference)

    return head :bad_request if params[:schema_name].blank? || params[:table_name].blank?

    table_info = Admin::TableViewInfo.new(schema_name: params[:schema_name], table_name: params[:table_name])
    return head :not_found unless table_info.exists?

    render partial: 'admin/reference_data/table_view_details', locals: { table_info: }
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
