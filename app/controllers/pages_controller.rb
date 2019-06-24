class PagesController < ApplicationController
  before_action :authenticate_user_or_admin!
  def index
    if current_user && ! current_admin
      redirect_to :masters
    end
  end

  # Simple action to refresh the session timeout
  def show
    render json: {version: Application.version}
  end

  # template
  def template
    return not_authorized unless current_user || current_admin
    response.headers["Cache-Control"] = "max-age=604800"
    response.headers["Pragma"] = ""
    response.headers["Expires"] = "Fri, 01 Jan 2090 00:00:00 GMT"

    render partial: 'masters/cache_search_results_template'
  end

  private

    def no_action_log
      true
    end
end
