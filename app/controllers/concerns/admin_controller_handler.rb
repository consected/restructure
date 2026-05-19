# frozen_string_literal: true

module AdminControllerHandler
  EncodingToken = { base64: '<Base64Encoded>' }.freeze
  extend ActiveSupport::Concern

  included do
    before_action :init_vars_admin_controller_handler
    before_action :authenticate_admin!
    before_action :set_instance_from_id, only: %i[edit update destroy]
    before_action :handle_options_encoding, only: %i[create update]

    helper_method :filters, :filters_on, :effective_filters, :effective_filters_on,
                  :index_path, :index_params, :permitted_params, :object_instance,
                  :objects_instance, :human_name, :no_edit, :primary_model,
                  :view_path, :extra_field_attributes, :admin_links, :view_embedded?, :hide_app_type?,
                  :help_section, :help_subsection, :title, :sub_title, :no_create, :show_head_info, :view_folder,
                  :no_options_field, :admin_labels, :filters_prevent_disabled, :before_send_processor, :extra_index_columns,
                  :in_current_app_type_result_checkbox
  end

  def index
    pm = filtered_primary_model
    pm = pm.limited_index
    pm = pm.reorder('').order(default_index_order) if default_index_order.present?
    set_objects_instance pm
    response_to_index
  end

  def new(options = {})
    if params[:copy_with_id].present?
      # Get the model with ID in the copy_with_id parameter and generate a hash that has only the permitted params for forms
      # This hash will be used to initialize a new model
      @copy_with = primary_model.find(params[:copy_with_id]).attributes.select do |k, _v|
        permitted_params.include? k.to_sym
      end

      init_attrs = @copy_with
    end

    # Ensure the app type is defaulted, if not copying an existing item and the primary model uses app types
    if !@copy_with && primary_model_uses_app_type?
      init_attrs = {
        app_type_id: current_admin.matching_user&.app_type_id
      }
    end

    unless @copy_with
      # Add initialization of class specific attributes, if not set previously
      init_attrs ||= {}

      init_attrs.merge! params.require(:init_with).permit(*permitted_params) if params[:init_with]
      init_attrs = init_new_with_attrs.merge(init_attrs)
    end

    set_object_instance primary_model.new(init_attrs) unless options[:use_current_object]
    render partial: view_path('form')
  end

  def edit
    object_instance.current_admin = current_admin
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
        if @show_again_on_save
          index
        else
          render partial: view_path('item'), locals: { list_item: object_instance }
        end
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

    # Check if the user is attempting to update with an older record
    sent_ua = params[:updated_at]
    prev_ua = object_instance.updated_at&.to_s
    return update_out_of_date(prev_ua, sent_ua) if sent_ua.present? && prev_ua && prev_ua != sent_ua

    if object_instance.update(secure_params)
      flash.now[:notice] = "#{human_name} updated successfully"
      @updated_with = object_instance
      begin
        if @show_again_on_save
          index
        else
          render partial: view_path('item'), locals: { list_item: object_instance }
        end
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

  #
  # Returns filters merged with an auto-detected name filter if:
  # - the primary model has a `name` column
  # - `name` is not already in the defined filters
  # @return [Hash]
  def effective_filters
    result = filters.dup
    return result unless result.is_a?(Hash)
    return result if result.key?(:name)
    return result unless primary_model.respond_to?(:attribute_names) &&
                         primary_model.attribute_names.include?('name')

    name_values = filter_values_for(:name)
    result[:name] = name_values if name_values.present?
    result
  end

  #
  # Returns filters_on merged with `:name` if:
  # - the primary model has a `name` column
  # - `:name` is not already in filters_on
  # - `name` is not already in the defined filters
  # @return [Array]
  def effective_filters_on
    result = Array(filters_on).dup
    return result if result.include?(:name)
    return result if filters.is_a?(Hash) && filters.key?(:name)
    return result unless primary_model.respond_to?(:attribute_names) &&
                         primary_model.attribute_names.include?('name')

    result << :name
    result
  end

  #
  # Override to prevent filters showing "disabled" option
  def filters_prevent_disabled
    false
  end

  #
  # Override to specify _fpa.before_send_processors.<method name>
  # if processing of the admin form is required before sending to the client.
  def before_send_processor
    nil
  end

  #
  # Alternative labels to use for admin form fields
  def admin_labels
    {}
  end

  def index_params
    permitted_params + [:admin_id] - %i[disabled options]
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
          res_a << row.attributes.map { |_k, val| val || '' }.to_csv
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

  def title
    object_name.pluralize.split('__').map { |t| t.humanize.captionize }.join(': ')
  end

  def sub_title
    nil
  end

  #
  # Make index lists appear without edit buttons
  # By default, (although the method may be overridden for certain controllers),
  # edit is allowed. For certain embedded displays it makes sense not to,
  # so the param readonly=true allows the requester to control this.
  # @return [Boolean]
  def no_edit
    params[:readonly] == 'true'
  end

  def no_create
    no_edit
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
  # Hash of extra columns to display in admin index lists.
  # The keys are method names in the controller, which will be called on each item in the list.
  # The values are the humanized column names to display in the header.
  # @return [Hash {Symbol: String} | nil]
  def extra_index_columns
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
  # if there are no filters or the app_type_id filter does not appear in the params
  # @return [Boolean]
  def hide_app_type?
    params[:view_as] == 'simple-embedded' && (!params[:filter] || params[:filter][:app_type_id].nil?)
  end

  def help_section
    object_name.split('__').last.ns_underscore.pluralize
  end

  def help_subsection
    HelpController::IntroductionDocument
  end

  #
  # Should a head info partial be shown?
  def show_head_info
    false
  end

  #
  # Overridable method, ensuring that index view doesn't mistake a field
  # ending with "options" or "template" as a multiline code block
  def no_options_field
    false
  end

  #
  # Show index column checkbox if the item is in the current admin's app type
  # @param [ActiveRecord] list_item
  # @return [String|nil] HTML for the checkbox or nil if not applicable
  def in_current_app_type_result_checkbox(list_item)
    @current_app_type ||= current_admin.matching_user&.app_type
    return unless @current_app_type

    @in_current_app_ids ||= list_item.class.ids_in_app_type(@current_app_type)
    list_val = @in_current_app_ids.include?(list_item.id)
    helpers.index_list_item_boolean_field(list_val)
  end

  #
  # Apply the special "in_current_app_type" filter after standard filtering
  def filtered_in_current_app_type(pm)
    return pm unless @in_current_app_type_filter.present?

    app_type = current_admin.matching_user&.app_type
    return pm unless app_type

    in_app_ids = primary_model.ids_in_app_type(app_type)
    if @in_current_app_type_filter == 'yes'
      pm.where(id: in_app_ids)
    elsif @in_current_app_type_filter == 'no'
      pm.where.not(id: in_app_ids)
    else
      pm
    end
  end

  #
  # Override to specify attributes to initialize a definition with
  # @return [Hash]
  def init_new_with_attrs
    {}
  end

  def initial_attrs_config_for(key)
    res = app_config_text(key, '')
    return {} if res.strip.blank?

    app_type = current_admin.matching_user&.app_type
    subs = {
      default_schema_name: primary_model.default_schema_name(app_type:),
      default_category: primary_model.default_category(app_type:)
    }

    vals = YAML.safe_load(res)
    vals.transform_values do |v|
      res = if v.is_a?(Hash)
              String.yaml_dump(v)
            else
              v
            end
      Formatter::Substitution.substitute(res, data: subs, ignore_missing: true)
    end
  end

  #
  # Return a hash of fields to be encoded - override in individual admin controllers
  # Use the value for each to specify the encoding type, for example:
  #     { options: :base64, sql: :base64 }
  # @return [nil|Hash]
  def encode_options_fields
    nil
  end

  #
  # On update or creates, check if the SQL field has been base64 encoded on the front end.
  # The EncodingToken[encoding_type] token will be prepended if this is the case.
  # The SQL field is then decoded and the token is removed, so that the report definition
  # can be saved in the original plain text format.
  # The rationale for this is to avoid WAFs blocking requests that appear to be SQL injection.
  def handle_options_encoding
    return unless encode_options_fields

    encode_options_fields.each do |field, encoding_type|
      next unless secure_params[field].present?

      encoding_token = EncodingToken[encoding_type]
      options = secure_params[field]
      next unless options&.start_with?(encoding_token)

      b64options = options.sub(encoding_token, '')

      case encoding_type
      when :base64
        decoded = Base64.decode64(b64options).force_encoding('UTF-8')
        raise FphsException, "Invalid UTF-8 encoding in base64 data for field: #{field}" unless decoded.valid_encoding?

        secure_params[field].sub!(/.*/, decoded)
      else
        raise FphsException, "Unknown encoding type: #{encoding_type} for field: #{field}"
      end
    end
  end
end
