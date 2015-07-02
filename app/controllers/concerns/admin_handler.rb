module AdminHandler
  extend ActiveSupport::Concern
  
  UseMasterParam = %w(new create index) 
  
  included do
    before_action :authenticate_admin!
    before_action :set_instance_from_id, only: [:show, :edit, :update, :destroy]
    
    
    after_action :do_log_action
  end

  def do_log_action
    len = (@master_objects ? @master_objects.length : 0)
    log_action "#{controller_name}##{action_name}", "AUTO", len
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
    set_objects_instance primary_model.all
  end
  
  def show
  end

  def new
    set_object_instance primary_model.new
  end

  def edit
  end

  def create
  
    set_object_instance primary_model.new(secure_params)
    object_instance.admin = current_admin
    if object_instance.save
      redirect_to url_for(action: :index), notice: "#{human_name} created successfully"
    else
      logger.warn "Error creating #{human_name}: #{object_instance.errors.inspect}"
      render :new
    end
  end

  def update
    object_instance.admin = current_admin
    if object_instance.update(secure_params)
      redirect_to url_for(action: :index), notice: "#{human_name} updated successfully"
    else
      logger.warn "Error updating #{human_name}: #{object_instance.errors.inspect}"
      render :edit
    end
    
  end

  def destroy
    not_authorized
  end

  
  
  private

    
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
