# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :authenticate_user_or_admin!
  def index
    redirect_to :masters if current_user && !current_admin
  end

  # Simple action to refresh the session timeout
  def show
    render json: { version: Application.version }
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

  private

  def no_action_log
    true
  end

  def ignore_temp_password_for
    %w[show template]
  end
end
