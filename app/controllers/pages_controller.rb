# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :authenticate_user_or_admin!

  def home
    home_url = if current_user && !current_admin
                 app_config_text(:logo_link, '/')
               else
                 '/'
               end
    redirect_to home_url
  end

  def index
    unless current_user && !current_admin
      render 'index', layout: 'admin_application'
      return
    end

    home_url = app_config_text(:logo_link, masters_search_path)
    redirect_to home_url
  end

  # Simple action to refresh the session timeout
  def show
    if params[:id] == 'version'
      render json: { version: Application.version }
    else
      not_found
    end
  end

  # template
  def template
    return not_authorized unless current_user || current_admin

    if current_user
      response.headers['Cache-Control'] = 'max-age=604800'
      response.headers['Pragma'] = ''
      response.headers['Expires'] = 'Fri, 01 Jan 2090 00:00:00 GMT'
      render partial: 'masters/cache_search_results_template'
    else
      render plain: ''
    end
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

  def ignore_temp_password_for
    %w[show template]
  end
end
