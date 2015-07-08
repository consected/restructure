class PagesController < ApplicationController
  before_action :authenticate_user_or_admin!
  def index
    
  end

  def show
  end

  private
end
