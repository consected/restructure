module MasterHandler
  extend ActiveSupport::Concern
  
  included do
    before_action :set_master, only: [:new, :edit, :create, :update, :destroy]
  end
  
  def set_master
    @master = Master.find(params[:master_id])
    @master.current_user = current_user  
    @master
  end
end
