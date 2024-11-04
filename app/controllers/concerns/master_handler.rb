# frozen_string_literal: true

module MasterHandler
  extend ActiveSupport::Concern

  UseMasterParam = %w[new create index template_config].freeze

  included do
    before_action :init_vars_master_handler

    before_action :set_me_and_master, only: %i[index new edit create update destroy template_config]
    before_action :set_implementation_class
    before_action :set_fields_from_params, only: [:edit]
    before_action :set_instance_from_id, only: %i[show]
    before_action :set_instance_list_from_id, only: %i[template_config]
    before_action :set_instance_from_reference_id, only: [:create]
    before_action :set_instance_from_build, only: %i[new create]
    before_action :set_ref_item_for_new, only: [:new]
    before_action :check_showable?, only: [:show]
    before_action :check_editable?, only: %i[edit update]
    before_action :check_creatable?, only: %i[new create]
    before_action :capture_ref_item, only: %i[create update]

    helper_method :primary_model, :permitted_params, :edit_form_helper_prefix, :item_type_id, :object_name,
                  :current_admin_sample
  end

  # Get the index JSON results from cache if the :cache_result param is set,
  # otherwise just get the current data.
  # Any change to the params will cause a new version to be retrieved if using cache,
  # so simply add a parameter like :cache_version => current timestamp to force new data
  def index
    index_res = if params[:cache_result].present?
                  response.headers['Cache-Control'] = 'max-age=30'
                  response.headers.delete 'Expires'
                  return unless stale?(etag: index_cache_key)

                  Rails.cache.fetch(index_cache_key) do
                    retrieve_index.as_json
                  end
                else
                  retrieve_index.as_json
                end

    render json: index_res
  end

  def show
    p = { full_object_name => object_instance.as_json, _control: control_feedback }

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
    do_show = false
    object_instance.transaction do
      set_additional_attributes object_instance
      translate_params_to_persistable
      if object_instance.save
        reload_objects
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
          do_show = true
        end
      else
        logger.warn "Error creating #{human_name}: #{object_instance_errors}"
        # Force an exception to show if no errors reported for the object instance because
        # a related object failed to save
        object_instance.save! unless object_instance.errors.present?
        render json: object_instance.errors, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
    # Ensure that show happens outside of the commit, otherwise we get incomplete results from save triggers
    now_show if do_show
  end

  def update
    do_show = false
    object_instance.transaction do
      translate_params_to_persistable
      if object_instance.update(secure_params)
        reload_objects
        handle_additional_updates :update
        if object_instance.has_multiple_results && !@assigning_master_to_existing_instance
          @master_objects = object_instance.multiple_results
          index
        else
          object_instance.reload
          if object_instance.class.no_master_association
            object_instance.current_user = current_user
          else
            object_instance.master.current_user = current_user
          end
          do_show = true
        end

      else
        logger.warn "Error updating #{human_name}: #{object_instance_errors}"
        # Force an exception to show if no errors reported for the object instance because
        # a related object failed to save        object_instance.save! unless object_instance.errors.present?
        render json: object_instance.errors, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
    # Ensure that show happens outside of the commit, otherwise we get incomplete results from save triggers
    now_show if do_show
  end

  def destroy
    not_authorized
  end

  def flags; end

  protected

  #
  # Show the result of an update or create
  # Force the action_name to be show, so references are calculated correctly
  def now_show
    object_instance.action_name = 'show' if object_instance.respond_to? :action_name
    show
  end

  #
  # Retrieve the index action JSON from master objects and extended data
  # @return [String] JSON
  def retrieve_index
    s = { objects_name => filter_records.as_json(current_user:), multiple_results: objects_name }

    set_objects_instance(@master_objects) # re add_trackers collection
    s.merge!(extend_result)

    if object_instance
      s[:original_item] = object_instance
      s[objects_name] << object_instance
    end
    s[:master_id] = @master.id unless primary_model.no_master_association

    s.to_json
  end

  #
  # Cache key for index action, ensuring uniqueness for:
  # - request params
  # - app version
  # - user
  # - controller / action
  # - each object instance in @master_objects:
  #   - class / id / updated_at
  #   - each model reference for the object instance:
  #     - class / id / updated_at
  # Although typically web pages would not require user specific caching, the
  # difference user access / roles of users require cached data not to be shared
  # between users
  # By checking updates on object instances and the their model references, we ensure that
  # the cache automatically gets invalidated if a change is made to any related data
  # @return [Hash] <description>
  def index_cache_key
    return @index_cache_key if @index_cache_key

    upd_all = []
    upd_all << "#{Application.server_cache_version}-#{current_user&.id}-#{controller_name}-#{action_name}"
    @master_objects.each do |m|
      upd_all << m.class.name
      upd_all << m.id
      upd_all << m.updated_at

      next unless m.respond_to? :model_references

      m.model_references.each do |r|
        upd_all << r.to_record_type
        upd_all << r.to_record_id
        upd_all << r.to_record.updated_at
      end
    end
    upd_ver = Digest::SHA256.hexdigest upd_all.join('>')

    res = params.permit!.to_h
    res[:_upd_ver] = upd_ver
    @index_cache_key = Digest::SHA256.hexdigest(res.to_json)
  end

  # Before update and before insert triggers can lead update and create actions to return incorrect
  # values, since column values may have changed in the database at the point of #save or #update
  # being called. These changes are not reflected in the attributes of the object or embedded intem
  # and therefore a careful reload must be performed.
  def reload_objects
    object_instance.reload
    object_instance.current_user = current_user
    return unless object_instance.embedded_item&.persisted?

    object_instance.embedded_item.reload
    object_instance.embedded_item.current_user = current_user
  end

  #
  # Name of the edit form partial
  # @return [String]
  def edit_form
    'edit_form'
  end

  #
  # Extra local variable to be passed to the edit form partial for rendering
  # allowing for human friendly form naming and captions
  # The method may be overridden by actual controllers
  # @return [Hash]
  def edit_form_extras
    dopt = object_instance.class.default_options
    if dopt
      cb = dopt.caption_before
      l = dopt.labels
      db = dopt.dialog_before
    end

    {
      caption: object_instance.human_name,
      caption_before: cb,
      labels: l,
      dialog_before: db
    }
  end

  # Identify common helper methods for edit forms. This may be overridden
  # in specific controller implementations, allowing for alternative helper methods
  # to be used
  def edit_form_helper_prefix
    'common'
  end

  # Details for the *_control* data item to be returned in a #show action.
  # Provides creatable model references for the returned instance
  # and details about the latest save action (on_save, on_create, etc...)
  def control_feedback
    res = {}

    if object_instance
      c = object_instance.creatables(include_references: false)
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
    item_type.ns_underscore
  end

  # Returns the full model name, namespaced like 'module__class' if there is a namespace.
  # otherwise it returns just the basic name
  def item_type
    self.class.name.singularize.ns_underscore
  end

  private

  #
  # Render a plain 401 page if object doesn't allow access
  def check_showable?
    return unless object_instance

    return if object_instance.allows_current_user_access_to? :access

    not_authorized
    nil
  end

  def check_editable?
    handle_option_type_config if action_name == 'edit' && respond_to?(:handle_option_type_config, true)
    return if object_instance.allows_current_user_access_to?(:edit)

    not_editable
    nil
  end

  def check_creatable?
    handle_option_type_config if action_name == 'new' && respond_to?(:handle_option_type_config, true)
    return if current_admin_sample || object_instance.allows_current_user_access_to?(:create)

    Rails.logger.warn "This item is not creatable: #{object_instance.class.name} - #{object_instance&.attributes}"
    not_creatable
    nil
  end

  #
  # The name that embedded itenms
  def params_namespace
    primary_params_name.to_s
    # @implementation_class.resource_name.gsub('__', '_')
  end

  # Allow overrides
  def set_additional_attributes(obj); end

  # Errors for logging
  def object_instance_errors
    object_instance.errors.map { |err| "#{err.attribute}: #{err.message}" }.join(' | ')
  end

  # In order to clear up a multitude of Ruby warnings
  def init_vars_master_handler
    instance_var_init :object_name
    instance_var_init :id
    instance_var_init :master
    instance_var_init :master_objects
    set_object_instance nil
  end

  # Generically retrieve the current object referenced by parameter :id
  # Store it into the @singlular_name instance variable
  # This is the equivalent of e.g.
  # @player_info  = PlayerInfo.find(params[:id])
  # This allows for us to retrieve the @master consistently, so that the master association
  # is not used repetitively (potentially breaking the current_user functionality and poor performance)
  def set_me_and_master
    if UseMasterParam.include?(action_name)
      @master = Master.find(params[:master_id]) unless primary_model.no_master_association && !params[:master_id]
    else
      object = primary_model.find(params[:id])
      unless primary_model.no_master_association || object.master_id
        @assigning_master_to_existing_instance = true
        object.master = Master.find(params[:master_id])
      end
      set_object_instance object
      @master = object.master unless primary_model.no_master_association
      @id = object.id
    end

    if @master&.respond_to? objects_name
      # Get the list of objects related to the master, in other words triggering the association
      # off of the master object
      @master_objects = @master.send(objects_name)
    else
      klass = primary_model
      @master_objects = klass.all if klass.no_master_association
    end
    return unless @master

    @master.current_user = current_user
    @master.current_admin = current_admin
    @master
  end

  # Necessary to allow activity log to call permitted_params
  def set_implementation_class
    @implementation_class = implementation_class if defined? implementation_class
  end

  # Edit form fields can be preset based on permitted parameter values
  def set_fields_from_params
    p = begin
      secure_params
    rescue StandardError
      nil
    end
    p&.each do |k, v|
      object_instance.send("#{k}=", v)
    end
  end

  # A standard way of cancelling an edit form, reloading the show data
  def canceled?
    params[:id] == 'cancel'
  end

  # Setup the instance to show, based on :id param and
  # gets the current user set up in the master
  def set_instance_from_id
    return if canceled?

    id = params[:id]
    found_inst = primary_model.find_by_id_or_secondary_key(id)
    set_object_instance found_inst
    object_instance.master.current_user = current_user unless primary_model.no_master_association
    @id = object_instance.id
  end

  # If the :id param contains commas, split the list into an array of ids to retrieve
  # a list of instances for a template config request
  def set_instance_list_from_id
    @id_list = params[:id].split(',')
    @instance_list = primary_model.where(id: @id_list)
    @master.current_user = current_user unless primary_model.no_master_association
  end

  #
  # If an instance id is specified using a :ref_to_record_id param
  # use it to set the object instance and set up the current user
  # *ref_to_record_id* provides the functionality for an edit form to
  # provide a drop down to select an existing instance from a list, or
  # to add a new one as an embedded extension to the form.
  # @return [Integer] - the id of the object instance
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

  # #new and #create actions build a new instance on the current master
  # This method simple sets this up consistently
  def set_instance_from_build
    return if @set_from_reference_id

    set_item if defined? set_item
    build_with = nil

    if defined?(setup_default_build_params)
      # We may need to set default parameters before the build
      # to ensure we have associations back the the master record set up correctly,
      # or to set other attributes required for validation.
      setup_default_build_params
      set_master_on_build = !!params[:master_id]
    end

    begin
      build_with = secure_params
    rescue StandardError => e
      logger.warn("set_instance_from_build: #{e}")
      build_with = {}
    end
    build_with[:skip_presets] = 'preset_fields' if action_name != 'new'
    build_with[:current_admin_sample] = true if current_admin_sample
    set_object_instance @master_objects.build(build_with)

    if set_master_on_build
      object_instance.master = @master
      object_instance.current_user = current_user
    end

    object_instance.item_id = @item_id if @item && object_instance.respond_to?(:item_id) && !object_instance.item_id
  end

  #
  # Set the instance variable specific to the request, so we have both the
  # @object_instance and a usefully named instance variable (such as @player_contact)
  # to represent the action's instance
  def set_object_instance(o)
    instance_variable_set("@#{object_name}", o)

    if object_instance.respond_to? :current_user
      object_instance.current_user = current_user
    elsif object_instance.respond_to? :master
      object_instance.master.current_user = current_user
    end
  end

  #
  # Set a usefully named instance variable for the objects, representing
  # a list of results rather than a single instance
  def set_objects_instance(o)
    instance_variable_set("@#{objects_name}", o)
  end

  #
  # A consistent name to access the current object instance in forms and partials
  def object_instance
    instance_variable_get("@#{object_name}")
  end

  #
  # A consistent name to access the current list of instances in partials
  # using multiple results
  def objects_instance
    instance_variable_get("@#{objects_name}")
  end

  #
  # Handle the presentation of item flags, if enabled for this type of object
  def prep_item_flags
    return unless object_instance.class.uses_item_flags?(current_user)

    @flag_item_type = object_instance.item_type
    @item_flag = object_instance.item_flags.build
  end

  #
  # #create and #update actions require additional updates to be performed.
  # This:
  # - sets up flags changed during new / edit
  # - creates a model reference for an embedded item form
  def handle_additional_updates(action = :create)
    @flag_item_type = object_instance.item_type
    # Check for blank item_flag param to cover testing scenarios that do not return
    # the item_flag set. Which is reasonable and conceivable in a real form too
    if ItemFlag.active_for?(@flag_item_type) && params[:item_flag].present?
      secure_item_flag_params = params.require(:item_flag).permit(item_flag_name_id: [])
      flag_list = secure_item_flag_params[:item_flag_name_id].reject(&:blank?).map(&:to_i)
      ItemFlag.set_flags flag_list, object_instance, current_user
    end

    # Based on an embedded item coming from a dynamic form, create the reference.
    # In this mode we are in the dynamic record, so the order is different from the previous create_with usage
    if action == :create && object_instance.embedded_item&.id && !object_instance.direct_embed?
      ModelReference.create_with object_instance,
                                 object_instance.embedded_item

    end

    true
  end

  #
  # Items may be referenced in create and update forms, adding or updating embedded items
  # The params :ref_record_type and :ref_record_id  identify the type and id of the record
  # being referred to.
  def capture_ref_item
    # The submitted item has hidden fields that state the 'from' item referencing this object instance
    pr = params[primary_params_name]
    return unless pr.present?

    ref_record_type = pr[:ref_record_type]
    ref_record_id = pr[:ref_record_id]
    unless ref_record_type.present? && ref_record_id.present? && object_instance.respond_to?(:set_referring_record)
      return
    end

    # The reference will actually get created when the object instance is saved
    object_instance.set_referring_record(ref_record_type, ref_record_id, current_user)
  end

  #
  # For instances being used in a new action, set the referring record so it can be used in calc actions
  def set_ref_item_for_new
    ref_params = params[:references]
    if ref_params.present?
      ref_record_type = ref_params[:record_type]
      ref_record_id = ref_params[:record_id]
    end
    unless ref_record_type.present? && ref_record_id.present? && object_instance.respond_to?(:set_referring_record)
      return
    end

    # The reference will actually get created when the object instance is saved
    object_instance.set_referring_record(ref_record_type, ref_record_id, current_user)
  end

  # Overridable method for filtering objects based on the request,
  # such as setting a limit and filtering based on specific requested ids
  def filter_records
    filter_requested_ids
    limit_results
    order_results
  end

  #
  # Filter the object list to be returned based on a list of ids
  def filter_requested_ids
    pfilter = params[:filter]
    return @master_objects unless pfilter.present?

    requested_filtered_ids = pfilter[:resource_id]
    secondary_key_filtered_ids = pfilter[:secondary_key]
    attr_filter = pfilter[@master_objects.klass.resource_name.to_sym]
    if requested_filtered_ids.present?
      requested_filtered_ids = requested_filtered_ids.split(',').map { |i| i.strip.to_i }
      @master_objects = @master_objects.where(id: requested_filtered_ids)
    elsif secondary_key_filtered_ids.present?
      @master_objects = @master_objects.find_all_by_secondary_key(secondary_key_filtered_ids)
    elsif attr_filter.present?
      @master_objects = @master_objects.where(@master_objects.klass.table_name => attr_filter.to_unsafe_h)
    else
      @master_objects
    end
  end

  def requested_limit
    @requested_limit ||= params[:limit].to_i if params[:limit].present?
  end

  #
  # Limit the results to a specified limit if the limit param is set
  def limit_results
    return @master_objects unless requested_limit

    @master_objects = @master_objects.limit(requested_limit)
  end

  #
  # Override this method to provide ordering
  # Return nil if no reordering is required
  # @return [nil |String | Hash] scope order definition
  def requested_order
    nil
  end

  #
  # Reorder the results if a requested_order is set
  def order_results
    return @master_objects unless requested_order

    @master_objects = @master_objects.unscope(:order).order(requested_order)
  end

  #
  # Allow #index results to be extended by overriding this method
  def extend_result
    {}
  end

  #
  # Get the permitted params from the implementation class
  def permitted_params
    primary_model.permitted_params
  end

  def readonly_params
    if primary_model.respond_to? :readonly_params
      primary_model.readonly_params
    else
      []
    end
  end

  def primary_params_name
    full_object_name.gsub('__', '_').to_sym
  end

  def secure_params
    @secure_params ||= params.require(primary_params_name).permit(*permitted_params)
  end

  #
  # Allow sample forms to be displayed in the admin panel if an
  # admin is authenticated and the admin_sample param is 'true'
  # @return [Boolean]
  def current_admin_sample
    current_admin && params[:admin_sample] == 'true'
  end

  #
  # Params with certain field_options: edit_as configurations need to be translated
  # to allow them to be stored to the database. Strong parameters don't allow complex
  # structures such as arrays of arrays, so the result is pushed directly into the @object_instance
  # ready for #create or #update
  def translate_params_to_persistable
    rname = object_instance.class.name.underscore.gsub('/', '_')
    obj_params = params[rname]
    unless obj_params
      raise FphsException, "No params sent for #{rname} when creating or updating." \
        "Expect posted data #{rname}[<field_name>]"
    end

    updated_params = Dynamic::FieldEditAs::Handler.new(object_instance, obj_params).translate_to_persistable
    # We don't use #assign_attributes, since a Hash will be treated as an update of a nested object
    updated_params.each do |k, v|
      object_instance.send("#{k}=", v)
      secure_params.delete k
    end

    obj_params = params.dig(rname, :embedded_item)
    ei = object_instance.embedded_item
    return unless obj_params && ei

    updated_params = Dynamic::FieldEditAs::Handler.new(ei, obj_params).translate_to_persistable
    # We don't use #assign_attributes, since a Hash will be treated as an update of a nested object
    updated_params.each do |k, v|
      ei.send("#{k}=", v)
      secure_params[:embedded_item].delete k
    end
  end
end
