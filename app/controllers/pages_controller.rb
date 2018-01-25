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

  private
end
