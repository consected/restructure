module MasterHandler
  extend ActiveSupport::Concern
  
  UseMasterParam = %w(new create index) 
  
  included do
    before_action :authenticate_user!
    before_action :set_me_and_master, only: [:index, :new, :edit, :create, :update, :destroy]
    before_action :set_instance_from_id, only: [:show]

    PrimaryModel = controller_name.classify.constantize
    ObjectName = controller_name.singularize
    ObjectsName = controller_name.to_sym
    HumanName = controller_name.singularize.humanize
  end

  def index
    set_objects_instance @master_objects
    s = @master_objects.as_json
    logger.debug "List: #{s}"
    render json: s
  end
  

  
  def show
    p = {ObjectName => object_instance.as_json}
    
    logger.debug "p: #{p} for object_instance"
    render json: p
  end

  def new
    set_object_instance @master_objects.build
    render partial: 'edit_form'
  end

  def edit
    render partial: 'edit_form'
  end

  def create
  
    set_object_instance @master_objects.build(secure_params)

    if object_instance.save
      show
    else
      logger.warn "Error creating #{HumanName}: #{object_instance.errors.inspect}"
      render json: object_instance.errors, status: :unprocessable_entity     
    end
  end

  def update
    if object_instance.update(secure_params)
      show
    else
      logger.warn "Error updating #{HumanName}: #{object_instance.errors.inspect}"
      render json: object_instance.errors, status: :unprocessable_entity 
    end
    
  end

  def destroy
    not_authorized
  end

  
  def flags
    
  end
  
  private

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
        object = PrimaryModel.find(params[:id])
        set_object_instance object
        @master = object.master
        @id = object.id
      end
      
      @master_objects = @master.send(ObjectsName)

      @master.current_user = current_user  
      @master
    end



    def set_instance_from_id
      return if params[:id] == 'cancel'
      set_object_instance PrimaryModel.find(params[:id])            
      @id = object_instance.id
      
    end

    def set_object_instance o
      instance_variable_set("@#{ObjectName}", o)  
    end

    def set_objects_instance o
      instance_variable_set("@#{ObjectsName}", o)  
    end

    # This is not used: def object_instance=(o)
    # ... since it requires self. prefix to make it work in controller, and is 
    # therefore more confusing than helpful

    def object_instance
      instance_variable_get("@#{ObjectName}")
    end
  
    
    
end
