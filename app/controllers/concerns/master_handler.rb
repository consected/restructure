module MasterHandler
  extend ActiveSupport::Concern
  
  UseMasterParam = %w(new create index) 
  
  included do
    before_action :authenticate_user!

    before_action :set_me_and_master, only: [:index, :new, :edit, :create, :update, :destroy]
  end
  
  def set_me_and_master
    
    # Generically retrieve the current object referenced by parameter :id
    # Store it into the @singlular_name instance variable
    # This is the equivalent of e.g.
    # @player_info  = PlayerInfo.find(params[:id])
    # This allows for us to retrieve the @master consistently, so that the master association
    # is not used repetitively (potentially breaking the current_user functionality)
    if UseMasterParam.include? action_name 
      @master = Master.find(params[:master_id])
    else
      object = controller_name.classify.constantize.find(params[:id])
      instance_variable_set("@#{controller_name.singularize}", object)  

      @master = object.master
    
    end
    @master.current_user = current_user  
    @master
  end
end
