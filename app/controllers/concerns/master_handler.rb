module MasterHandler
  extend ActiveSupport::Concern
  
  UseMasterParam = %w(new create index) 
  
  included do
    before_action :authenticate_user!
    before_action :set_me_and_master, only: [:index, :new, :edit, :create, :update, :destroy]
    before_action :set_instance_from_id, only: [:show]

    after_action :do_log_action
    
    helper_method :primary_model, :permitted_params
  end

  def do_log_action
    len = (@master_objects ? @master_objects.length : 0)
    extras = {}
    if @master
      extras[:master_id] = @master.id 
      extras[:msid] = @master.msid     
    else
      extras[:master_id] = nil
      extras[:msid] = nil
    end
    log_action "#{controller_name}##{action_name}", "AUTO", len, "OK", extras
  end
  
  def primary_model 
    controller_name.classify.constantize
  end
  def object_name 
    controller_name.singularize
  end
  def objects_name 
    controller_name.to_sym
  end
  def human_name 
    controller_name.singularize.humanize
  end
  
  def index
    set_objects_instance @master_objects
    s = {objects_name => @master_objects.as_json, multiple_results: objects_name}
    if object_instance
      s[:original_item] = object_instance
      s[objects_name] <<  object_instance
    end
    s[:master_id] = @master.id
    
    logger.debug "List: #{s} with objects_instance @#{objects_name}"
    render json: s
  end
  
  def show
    p = {object_name => object_instance.as_json}
    
    logger.debug "p: #{p} for object_instance"
    render json: p
  end
  
  def new
    set_object_instance @master_objects.build
    render partial: edit_form
  end

  def edit
    render partial: edit_form
  end

  def create
  
    set_object_instance @master_objects.build(secure_params)

    if object_instance.save
      if object_instance.has_multiple_results
        @master_objects = object_instance.multiple_results
        index
      else
        show
      end
    else
      logger.warn "Error creating #{human_name}: #{object_instance.errors.inspect}"
      render json: object_instance.errors, status: :unprocessable_entity     
    end
  end

  def update
    if object_instance.update(secure_params)
      if object_instance.has_multiple_results
        @master_objects = object_instance.multiple_results
        index
      else
        show
      end
      
    else
      logger.warn "Error updating #{human_name}: #{object_instance.errors.inspect}"
      render json: object_instance.errors, status: :unprocessable_entity 
    end
    
  end

  def destroy
    not_authorized
  end

  
  def flags
    
  end


  protected
  
    def edit_form
      'edit_form'
    end  
    
  private

    def set_me_and_master

      # Generically retrieve the current object referenced by parameter :id
      # Store it into the @singlular_name instance variable
      # This is the equivalent of e.g.
      # @player_info  = PlayerInfo.find(params[:id])
      # This allows for us to retrieve the @master consistently, so that the master association
      # is not used repetitively (potentially breaking the current_user functionality and poor performance)
      if UseMasterParam.include? action_name 
        @master = Master.find(params[:master_id])
      else
        object = primary_model.find(params[:id])
        set_object_instance object
        @master = object.master
        @id = object.id
      end
      
      # Get the list of objects related to the master, in other words triggering the association
      # off of the master object
      @master_objects = @master.send(objects_name)
      
      @master.current_user = current_user  
      @master.current_admin = current_admin
      @master
    end



    def set_instance_from_id
      return if params[:id] == 'cancel'
      set_object_instance primary_model.find(params[:id])            
      @id = object_instance.id
      
    end

    def set_object_instance o
      instance_variable_set("@#{object_name}", o)  
    end

    def set_objects_instance o
      instance_variable_set("@#{objects_name}", o)  
    end

    # This is not used: def object_instance=(o)
    # ... since it requires self. prefix to make it work in controller, and is 
    # therefore more confusing than helpful

    def object_instance
      instance_variable_get("@#{object_name}")
    end
  
    
    
end
