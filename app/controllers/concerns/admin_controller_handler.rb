module AdminControllerHandler
  extend ActiveSupport::Concern
  
  included do
    
    before_action :authenticate_admin!
    before_action :set_instance_from_id, only: [:edit, :update, :destroy]    
    
    after_action :do_log_action
    
    helper_method :filters, :filters_on, :index_path, :index_params, :permitted_params, :objects_instance, :human_name
  end

  def index    
    pm = primary_model    
    pm = pm.where filter_params if filter_params
    set_objects_instance pm.order(default_index_order)
    
    respond_to do |format|      
      format.html { render view_path('index') }
      format.all { render json: objects_instance.as_json(except: [:created_at, :updated_at, :id, :admin_id, :user_id])}
    end
  end
  

  def new options = {}
    set_object_instance primary_model.new unless options[:use_current_object]
    render partial: view_path('form')
  end

  def edit
    render partial: view_path('form')
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
  
    def filters
      
    end
    
    def index_params
      permitted_params + [:admin_id]
    end
  
    def view_path view
      return view unless view_folder
      [view_folder, view].join('/')
    end
  
    def view_folder
      nil
    end

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
  
    
    def filter_params
      return nil
    end
    
    def error_message
      res = ""
      object_instance.errors.full_messages.each do |message|
        res << "; " unless res.blank?
        res << "#{message}"
      end
      res
    end

    def index_path opt={}
      redir = {controller: controller_name, action: :index}
      redir.merge! @parent_param if @parent_param
      redir.merge! opt
      
      f = filter_params
      redir[:filter] ||= f if f
      
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

    def filter_params
      return nil if params[:filter].blank?
      params.require(:filter).permit(filters_on)
    end
  
    
end
