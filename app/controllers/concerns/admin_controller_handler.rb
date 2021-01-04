# frozen_string_literal: true

module AdminControllerHandler
  extend ActiveSupport::Concern

  included do
    before_action :init_vars_admin_controller_handler
    before_action :authenticate_admin!
    before_action :set_instance_from_id, only: %i[edit update destroy]

    helper_method :filters, :filters_on, :index_path, :index_params, :permitted_params, :object_instance,
                  :objects_instance, :human_name, :no_edit, :primary_model,
                  :view_path, :extra_field_attributes, :admin_links, :view_embedded?, :hide_app_type?
  end

  def index
    pm = filtered_primary_model

    set_objects_instance pm.limited_index.order(default_index_order)
    response_to_index
  end

  def new(options = {})
    if params[:copy_with_id].present?
      # Get the model with ID in the copy_with_id parameter and generate a hash that has only the permitted params for forms
      # This hash will be used to initialize a new model
      @copy_with = primary_model.find(params[:copy_with_id]).attributes.select do |k, _v|
        permitted_params.include? k.to_sym
      end
    end

    # Ensure the app type is defaulted, if not copying an existing item and the primary model uses app types
    if !@copy_with && primary_model_uses_app_type?
      @copy_with = {
        app_type_id: current_admin.matching_user&.app_type_id
      }
    end

    set_object_instance primary_model.new(@copy_with) unless options[:use_current_object]
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
      object_instance.errors.add 'error', e.message
    end
    if res
      @updated_with = object_instance
      begin
        render partial: view_path('item'), locals: { list_item: object_instance }
      rescue ActionView::MissingTemplate
        index
      end
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
      begin
        render partial: view_path('item'), locals: { list_item: object_instance }
      rescue ActionView::MissingTemplate
        index
      end
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

  def canceled?
    params[:id] == 'cancel'
  end

  def filters
    {}
  end

  def filters_on
    []
  end

  def index_params
    permitted_params + [:admin_id] - [:disabled]
  end

  def admin_link_params
    []
  end

  def index_partial
    view = 'index'
    return view unless view_folder

    [view_folder, view].join('/')
  end

  def view_path(view)
    if view_folder
      [view_folder, view].join('/')
    else
      return 'admin_handler/index' if view == 'index'

      view
    end
  end

  def view_folder
    nil
  end

  def response_to_index
    respond_to do |format|
      format.html do
        if @updated_with || view_embedded?
          render partial: index_partial
        else
          render view_path('index')
        end
      end
      format.csv do
        res_a = []
        res_a << objects_instance.attribute_names.to_csv
        objects_instance.each do |row|
          res_a << (row.attributes.map { |_k, val| val || '' }).to_csv
        end
        send_data res_a.join(''), filename: 'admin.csv'
      end
      format.all { render json: objects_instance.as_json(except: %i[created_at updated_at id admin_id user_id]) }
    end
  end

  def primary_model
    Admin::AdminBase.class_from_name controller_name
  end

  def object_name
    @object_name = primary_model.name.ns_underscore.singularize
  end

  def objects_name
    object_name.pluralize.to_sym
  end

  def human_name
    object_name.humanize
  end

  #
  # Make index lists appear without edit buttons
  # By default, (although the method may be overridden for certain controllers),
  # edit is allowed. For certain embedded displays it makes sense not to,
  # so the param readonly=true allows the requester to control this.
  # @return [Boolean]
  def no_edit
    false || params[:readonly] == 'true'
  end

  def default_index_order
    nil
  end

  # Additional option attributes to attach to forms
  # For example: {app_type_id: {'data-attribute': 234}, ...}
  # @return [Hash] symbolized keys for fields to match with Hash values representing the attributes to add
  def extra_field_attributes
    {}
  end

  private

  # In order to clear up a multitude of Ruby warnings
  def init_vars_admin_controller_handler
    instance_var_init :master_objects
    instance_var_init :updated_with
    set_object_instance nil
  end

  def error_message
    res = ''
    object_instance.errors.full_messages.each do |message|
      res += '; ' unless res.blank?
      res += message.to_s
    end
    res
  end

  def index_path(opt = {})
    redir = { controller: controller_name, action: :index }
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

  def set_object_instance(o)
    instance_variable_set("@#{object_name}", o)
  end

  def set_objects_instance(o)
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

  def no_action_log
    true
  end

  #
  # Overridable method in individual admin controllers, to allow admin links to appear in admin lists
  # @param [Integer] _id - the id of the record
  # @return [Array {Array}] - returns an array of settings for each type of admin link
  #   Each item is an array representing the arguments passed to the #link_to method
  #   For example:
  #     [ ['details', admin_external_id_details_path(id) ], ... ]
  def admin_links(_id = nil)
    nil
  end

  #
  # Allow admin tables to be embedded in other pages by passing the param
  # view_as=embedded or view_as=simple-embedded
  # This returns a partial index, and hides the filter buttons
  # @return [Boolean]
  def view_embedded?
    params[:view_as]&.in? %w[embedded simple-embedded]
  end

  #
  # Allow admin tables to be viewed without the app type column by passing the param view_as=simple-embedded
  # @return [Boolean]
  def hide_app_type?
    params[:view_as] == 'simple-embedded'
  end
end
