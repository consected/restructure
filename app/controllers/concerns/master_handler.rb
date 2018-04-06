module MasterHandler
  extend ActiveSupport::Concern

  UseMasterParam = %w(new create index)

  included do

    before_action :init_vars_master_handler
    before_action :authenticate_user!
    before_action :set_me_and_master, only: [:index, :new, :edit, :create, :update, :destroy]
    before_action :set_instance_from_id, only: [:show]
    before_action :set_instance_from_build, only: [:new, :create]
    before_action :check_showable?, only: [:show]
    before_action :check_editable?, only: [:edit, :update]
    before_action :check_creatable?, only: [:new, :create]

    helper_method :primary_model, :permitted_params, :edit_form_helper_prefix, :item_type_id
  end

  def index
    set_objects_instance @master_objects
    s = {objects_name => @master_objects.as_json(current_user: current_user), multiple_results: objects_name}
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

    render json: p
  end

  def new

    prep_item_flags

    set_additional_attributes object_instance
    render partial: edit_form, locals: edit_form_extras
  end

  def edit
    prep_item_flags

    render partial: edit_form, locals: edit_form_extras
  end

  def create

    set_additional_attributes object_instance
    if object_instance.save
      handle_additional_updates
      @id = object_instance.id
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
      handle_additional_updates
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
      {
        caption: object_instance.human_name
      }
    end

    def edit_form_helper_prefix
      'common'
    end

    def item_type_id
      "#{item_type_us}_id".to_sym
    end

    def item_type_us
      self.item_type.ns_underscore
    end

    # Returns the full model name, namespaced like 'module__class' if there is a namespace.
    # otherwise it returns just the basic name
    def item_type
      self.class.name.singularize.ns_underscore
    end

    private

      def check_showable?
        return unless object_instance
        unless object_instance.allows_current_user_access_to? :access
          not_authorized
          return
        end
      end

      def check_editable?
        unless object_instance.allows_current_user_access_to? :edit
          not_editable
          return
        end
      end

      def check_creatable?
        unless object_instance.allows_current_user_access_to? :create
          not_creatable
          return
        end
      end


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
        if object_instance.respond_to?(:master) && object_instance.master
          object_instance.master.current_user = current_user
        end
        @id = object_instance.id

      end

      def set_instance_from_build

        if defined? set_item
          set_item
        end
        build_with = secure_params rescue nil
        set_object_instance @master_objects.build(build_with)

        if @item && object_instance.respond_to?(:item_id) && !object_instance.item_id
          object_instance.item_id = @item_id
        end
      end

      def set_object_instance o
        instance_variable_set("@#{object_name}", o)

        if object_instance.respond_to? :current_user
          object_instance.current_user = current_user
        elsif object_instance.respond_to? :master
          object_instance.master.current_user = current_user
        end
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

      def prep_item_flags
        # Handle the presentation of item flags, if enabled for this type of object
        if object_instance.class.uses_item_flags?(current_user)
          @flag_item_type = object_instance.item_type
          @item_flag = object_instance.item_flags.build
        end
      end

      def handle_additional_updates
        @flag_item_type = object_instance.item_type
        # Check for blank item_flag param to cover testing scenarios that do not return
        # the item_flag set. Which is reasonable and conceivable in a real form too
        if ItemFlag.is_active_for?(@flag_item_type) && params[:item_flag]
          secure_item_flag_params = params.require(:item_flag).permit(item_flag_name_id: [])
          flag_list = secure_item_flag_params[:item_flag_name_id].select {|f| !f.blank?}.map {|f| f.to_i}
          ItemFlag.set_flags flag_list, object_instance, current_user
        end

        # Follow the pattern of the tracker to capture referenced items
        # The submitted item has hidden fields that state the 'from' item referencing this object instance
        pr = params[full_object_name.gsub('__', '_').to_sym]
        if pr.present? && pr[:ref_record_type].present? && pr[:ref_record_id].present?
          ref_item_class_name = pr[:ref_record_type].singularize.camelize

          # Find the matching UserBase subclass that has this name, avoiding using the supplied param
          # in a way that could be risky by allowing code injection
          ic = UserBase.subclasses.select {|s| s.name == ref_item_class_name}.first

          # look up the item using the item_id parameter.
          rid = pr[:ref_record_id].to_i
          @ref_item  = ic.find(rid)

          if @ref_item
            ModelReference.create_with @ref_item, object_instance
          end
        end

        # Based on an embedded item coming from an activity log form, create the reference.
        # In this mode we are in the activity log record, so the order is different from the previous create_with usage
        if object_instance.embedded_item
          ModelReference.create_with object_instance, object_instance.embedded_item
        end

        true

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

      # notice the double underscore for namespaced models to indicate the delimiter
      # to remain consistent with the associations
      def full_object_name
        if self.class.parent.name != 'Object'
          "#{self.class.parent.name.underscore}__#{controller_name.singularize}"
        else
          controller_name.singularize
        end
      end

      # the association name from master to these objects
      # for example player_contacts or activity_log__player_contacts_phones
      # notice the double underscore for namespaced models to indicate the delimiter
      def objects_name

        if self.class.parent.name != 'Object'
          "#{self.class.parent.name.underscore}__#{controller_name}".to_sym
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


      def permitted_params
        full_object_name.gsub('__', '/').camelize.constantize.permitted_params
      end

      def secure_params
        params.require(full_object_name.gsub('__', '_').to_sym).permit(*permitted_params)
      end

end
