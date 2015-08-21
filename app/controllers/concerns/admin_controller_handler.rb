module AdminControllerHandler
  extend ActiveSupport::Concern
  
  included do
    
    before_action :authenticate_admin!
    before_action :set_instance_from_id, only: [:edit, :update, :destroy]    
    
    after_action :do_log_action
  end

  def index    
    set_objects_instance primary_model.order(default_index_order)
    
    respond_to do |format|      
      format.html { render :index }
      format.all { render json: objects_instance.as_json(except: [:created_at, :updated_at, :id, :admin_id, :user_id])}
    end
  end
  

  def new options = {}
    set_object_instance primary_model.new unless options[:use_current_object]
    render partial: 'form'
  end

  def edit
    render partial: 'form'
  end

  def create
  
    set_object_instance primary_model.new(secure_params)
    object_instance.current_admin = current_admin
    if object_instance.save
      redirect_to index_path, notice: "#{human_name} created successfully"
    else
      logger.warn "Error creating #{human_name}: #{object_instance.errors.inspect}"
      flash.now[:warning] = "Error creating #{human_name}: #{error_message}"
      new use_current_object: true
    end
  end

  def update
    object_instance.current_admin = current_admin
    if object_instance.update(secure_params)
      redirect_to index_path, notice: "#{human_name} updated successfully"
    else
      logger.warn "Error updating #{human_name}: #{object_instance.errors.inspect}"      
      flash.now[:warning] = "Error updating #{human_name}: #{error_message}"
      edit
    end
    
  end

  def destroy
    not_authorized
  end

  protected

    def log_action action, sub, results, status="OK", extras={}
      extras[:master_id] ||= nil
      extras[:msid] ||= nil
      current_admin.log_action action, sub, results, request.method_symbol, params, status, extras
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
    
    def default_index_order
      nil
    end
  
  private
  
    def error_message
      res = ""
      object_instance.errors.full_messages.each do |message|
        res << "; " unless res.blank?
        res << "#{message}"
      end
      res
    end

    def index_path
      redir = {action: :index}
      redir.merge! @parent_param if @parent_param
      url_for(redir)
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

    def objects_instance
      instance_variable_get("@#{objects_name}")
    end    
    
end
