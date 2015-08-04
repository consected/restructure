class ProInfosController < ApplicationController
  include MasterHandler

  def edit
    not_authorized
  end
  
  def update
    not_authorized
  end
  
  def new
    not_authorized
  end
  
  def create
    not_authorized
  end

  def destroy
    not_authorized
  end
    
  private
    
    def secure_params
      params.require(:pro_info).permit(:master_id, :user_id)
    end
end
