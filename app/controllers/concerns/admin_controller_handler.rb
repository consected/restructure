module AdminControllerHandler
  extend ActiveSupport::Concern

  included do

    before_action :init_vars_admin_controller_handler
    before_action :authenticate_admin!
    before_action :set_instance_from_id, only: [:edit, :update, :destroy]


    helper_method :filters, :filters_on, :index_path, :index_params, :permitted_params, :objects_instance, :human_name
  end

  def index
    pm = primary_model
    pm = pm.where filter_params if filter_params
    set_objects_instance pm.order(default_index_order)
    response_to_index

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

    # Putting save into a rescue block enables us to raise FphsException in
    # after_save callbacks, providing an extra level of validation where it
    # is needed after records are persisted to the DB.
    # Without this, spec tests fail with incredibly hard to understand results,
    # where at least there would have been a visible exception in real life

    res = nil
    begin
      res = object_instance.save
    rescue FphsException => e
      flash.now[:warning] = e.message
      object_instance.errors.add "error", e.message
    end
    if res
      @updated_with = object_instance
      index
    else
      logger.warn "Error creating #{human_name}: #{object_instance.errors.inspect}"
      flash.now[:warning] ||= "Error creating #{human_name}: #{error_message}"
      new use_current_object: true
    end
  end

  def update
    object_instance.current_admin = current_admin
    if object_instance.update(secure_params)
      flash.now[:notice] = "#{human_name} updated successfully"
      @updated_with = object_instance
      index
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

    def index_partial
      view = 'index'
      return view unless view_folder
      [view_folder, view].join('/')
    end

    def view_path view
      unless view_folder
        return 'admin_handler/index' if view == 'index'
        return view
      else
        [view_folder, view].join('/')
      end
    end

    def view_folder
      nil
    end

    def response_to_index
      respond_to do |format|
        format.html {
          if @updated_with
            render partial: index_partial
          else
            render view_path('index')
          end
        }
        format.all { render json: objects_instance.as_json(except: [:created_at, :updated_at, :id, :admin_id, :user_id])}
      end
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

    # In order to clear up a multitude of Ruby warnings
    def init_vars_admin_controller_handler
      instance_var_init :master_objects
      instance_var_init :updated_with
      set_object_instance nil
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
      return nil if params[:filter].blank? || (params[:filter].is_a?( Array) && params[:filter][0].blank?)
      params.require(:filter).permit(filters_on)
    end


  private
    def no_action_log
      true
    end


end
