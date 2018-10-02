module MasterHandler
  extend ActiveSupport::Concern

  UseMasterParam = %w(new create index)

  included do

    before_action :init_vars_master_handler

    before_action :set_me_and_master, only: [:index, :new, :edit, :create, :update, :destroy]
    before_action :set_instance_from_id, only: [:show]
    before_action :set_instance_from_reference_id, only: [:create]
    before_action :set_instance_from_build, only: [:new, :create]
    before_action :check_showable?, only: [:show]
    before_action :check_editable?, only: [:edit, :update]
    before_action :check_creatable?, only: [:new, :create]
    before_action :capture_ref_item, only: [:create, :update]

    helper_method :primary_model, :permitted_params, :edit_form_helper_prefix, :item_type_id, :object_name
  end

  def index
    set_objects_instance @master_objects
    s = {objects_name => filter_records(@master_objects).as_json(current_user: current_user), multiple_results: objects_name}
    s.merge!(extend_result)
    if object_instance
      s[:original_item] = object_instance
      s[objects_name] <<  object_instance
    end
    s[:master_id] = @master.id unless primary_model.no_master_association

    render json: s
  end

  def show
    p = {full_object_name => object_instance.as_json, _control: control_feedback}

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
        object_instance.reload
        if object_instance.class.no_master_association
          object_instance.current_user = current_user
        else
          object_instance.master.current_user = current_user
        end
        show
      end
    else
      logger.warn "Error creating #{human_name}: #{object_instance_errors}"
      # Force an exception to show if no errors reported for the object instance because
      # a related object failed to save
      object_instance.save! unless object_instance.errors.present?
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
        object_instance.reload
        if object_instance.class.no_master_association
          object_instance.current_user = current_user
        else
          object_instance.master.current_user = current_user
        end
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
      cb = object_instance.class.default_options.caption_before if object_instance.class.default_options
      {
        caption: object_instance.human_name,
        caption_before: cb
      }
    end

    def edit_form_helper_prefix
      'common'
    end

    def control_feedback
      res = {}

      if object_instance
        c = object_instance.creatables
        sa = object_instance.save_action
      end
      res[:creatables] = c if c
      res[:save_action] = sa if sa

      res
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

        if UseMasterParam.include?(action_name)
          @master = Master.find(params[:master_id]) unless primary_model.no_master_association
        else
          object = primary_model.find(params[:id])
          set_object_instance object
          @master = object.master unless primary_model.no_master_association
          @id = object.id
        end

        if @master&.respond_to? objects_name
          # Get the list of objects related to the master, in other words triggering the association
          # off of the master object
          @master_objects = @master.send(objects_name)
        else
          klass = primary_model #DynamicModel.const_get(object_name.ns_camelize)
          @master_objects = klass.all if klass.no_master_association
        end
        return unless @master
        @master.current_user = current_user
        @master.current_admin = current_admin
        @master
      end


      def canceled?
        params[:id] == 'cancel'
      end


      def set_instance_from_id
        return if canceled?
        set_object_instance primary_model.find(params[:id])
        if object_instance.respond_to?(:master) && object_instance.master
          object_instance.master.current_user = current_user
        end
        @id = object_instance.id

      end

      def set_instance_from_reference_id
        return if canceled? || params[:ref_to_record_id].blank?
        set_object_instance primary_model.find(params[:ref_to_record_id])
        if object_instance.respond_to?(:master) && object_instance.master
          object_instance.master.current_user = current_user
        else
          object_instance.current_user = current_user
        end
        @id = @set_from_reference_id = object_instance.id

      end


      def set_instance_from_build
        return if @set_from_reference_id
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


        # Based on an embedded item coming from an activity log form, create the reference.
        # In this mode we are in the activity log record, so the order is different from the previous create_with usage
        if object_instance.embedded_item && object_instance.embedded_item.id
          ModelReference.create_with object_instance, object_instance.embedded_item
        end

        true

      end

      def capture_ref_item
        # Follow the pattern of the tracker to capture referenced items
        # The submitted item has hidden fields that state the 'from' item referencing this object instance
        pr = params[full_object_name.gsub('__', '_').to_sym]
        if pr.present?
          ref_record_type = pr[:ref_record_type]
          ref_record_id = pr[:ref_record_id]
          if ref_record_type.present? && ref_record_id.present? && object_instance.respond_to?(:set_referring_record)

            object_instance.set_referring_record(ref_record_type, ref_record_id)
            # The reference will actually get created when the object instance is saved
          end
        end
      end

      def filter_records records
        records
      end

      def extend_result
        {}
      end


      def permitted_params
        full_object_name.gsub('__', '/').camelize.constantize.permitted_params
      end

      def readonly_params
        c = full_object_name.gsub('__', '/').camelize.constantize
        if c.respond_to? :readonly_params
          c.readonly_params
        else
          []
        end
      end

      def secure_params
        params.require(full_object_name.gsub('__', '_').to_sym).permit(*permitted_params)
      end

end
