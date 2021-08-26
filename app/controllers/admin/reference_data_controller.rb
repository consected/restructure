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

  def data_dic
    return not_authorized unless current_admin || current_user.can?(:view_data_reference)

    render partial: 'admin/reference_data/data_dic_block'
  end

  def reference_data
    return not_authorized unless current_admin || current_user.can?(:view_data_reference)

    case params[:type]
    when 'table_list'
      render partial: 'admin/reference_data/table_list_block'
    when 'data_dic'
      render partial: 'admin/reference_data/data_dic_block'
    else
      render 'admin/reference_data/index'
    end
  end

  private

  def no_action_log
    true
  end

end
