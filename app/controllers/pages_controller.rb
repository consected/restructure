class PagesController < ApplicationController
  before_action :authenticate_user_or_admin!
  def index
    if current_user && ! current_admin
      redirect_to :masters
    end
  end

  
  
  private
end
