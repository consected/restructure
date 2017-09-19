module MasterHandler
  extend ActiveSupport::Concern
  
  UseMasterParam = %w(new create index) 
  
  included do
    
    before_action :init_vars_master_handler
    before_action :authenticate_user!
    before_action :set_me_and_master, only: [:index, :new, :edit, :create, :update, :destroy]
    before_action :set_instance_from_id, only: [:show]

    after_action :do_log_action
    
    helper_method :primary_model, :permitted_params, :edit_form_helper_prefix, :item_type_id
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

  # return the class for the current item
  # handles namespace if the item is like an ActivityLog:Something
  def primary_model
    if self.class.parent.name != 'Object'
      "#{self.class.parent.name}::#{object_name.camelize}".constantize
    else
      controller_name.classify.constantize
    end
  end

  def object_name
    controller_name.singularize
  end

  def full_object_name
    if self.class.parent.name != 'Object'
      "#{self.class.parent.name.underscore}_#{controller_name.singularize}"
    else
      controller_name.singularize
    end
  end
  
  # the association name from master to these objects
  # for example player_contacts or activity_log_player_contacts_phones
  def objects_name
    if self.class.parent.name != 'Object'
      "#{self.class.parent.name.underscore}_#{controller_name}".to_sym
    else
      controller_name.to_sym
    end
  end
  def human_name 
    controller_name.singularize.humanize
  end

  def extend_result
    {}
  end
  
  def index
    set_objects_instance @master_objects
    s = {objects_name => @master_objects.as_json, multiple_results: objects_name}
    s.merge!(extend_result)
    if object_instance
      s[:original_item] = object_instance
      s[objects_name] <<  object_instance
    end
    s[:master_id] = @master.id
    
    render json: s
  end
  
  def show
    p = {full_object_name => object_instance.as_json}
    
    logger.debug "p: #{p} for object_instance"
    render json: p
  end
  
  def new
    set_object_instance @master_objects.build
    render partial: edit_form, locals: edit_form_extras
  end

  def edit
    render partial: edit_form, locals: edit_form_extras
  end

  def create
  
    set_object_instance @master_objects.build(secure_params)
    set_additional_attributes object_instance
    if object_instance.save
      if object_instance.has_multiple_results
        @master_objects = object_instance.multiple_results
        index
      else
        show
      end
    else
      logger.warn "Error creating #{human_name}: #{object_instance_errors}"
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
      logger.warn "Error updating #{human_name}: #{object_instance_errors}"
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

    def edit_form_extras
      {}
    end

    def edit_form_helper_prefix
      'common'
    end

    def item_type_id
      "#{item_type_us}_id".to_sym if @item_type
    end
    
  private

    def set_additional_attributes obj

    end

    def object_instance_errors
      object_instance.errors.map{|k,av| "#{k}: #{av}"}.join(' | ')
    end

    # In order to clear up a multitude of Ruby warnings
    def init_vars_master_handler
      instance_var_init :object_name
      instance_var_init :id
      instance_var_init :master
      instance_var_init :master_objects
      set_object_instance nil
    end

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
