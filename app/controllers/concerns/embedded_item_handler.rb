module EmbeddedItemHandler
  extend ActiveSupport::Concern

  included do
    before_action :handle_embedded_item, only: %i[show edit new create update]
    attr_accessor :embedded_item
  end

  #
  # Allow passing of params to embedded item to initialize the new form
  def set_embedded_item_optional_params
    return unless @embedded_item

    embedded_item_secure_params&.each do |p, v|
      @embedded_item.send("#{p}=", v)
    end
  end

  #
  # Set up all the requirements for an embedded item, based on the current action
  # This includes setting the current user on the item, and updating the embedded item
  # with secure params from the request if the item is being created.
  # @param [UserBase | nil] use_object - force the use of a specific instance as
  #                                      the parent (rather than default requested instance)
  def handle_embedded_item(use_object = nil)
    oi = use_object || object_instance
    return unless oi

    oi.current_user = current_user
    oi.action_name = action_name
    @embedded_item = oi.embedded_item(current_admin_sample:)

    return unless @embedded_item

    @embedded_item.force_preset_values
    case action_name
    when 'new'
      set_embedded_item_optional_params
    when 'create', 'update'
      begin
        @embedded_item.update embedded_item_secure_params if embedded_item_secure_params
        oi.updated_at = @embedded_item.updated_at
      rescue ActionController::ParameterMissing
        raise FphsException, 'Could not save the item, since you do not have access to any of the data it references.'
      end
    end
  end

  #
  # List the embedded items for the @master_objects index list, for items that
  # have an embedded item that matches the item_type
  # @param [String] item_type - typically @item_type from an activity log
  # @return [Array{UserBase}]
  def master_objects_embedded_items(item_type)
    mos = @master_objects.select do |o|
      o.respond_to?(:embedded_item) &&
        ModelReference.record_type_to_ns_table_name(o.embedded_item, pluralize: true) == item_type
    end
    mos.map(&:embedded_item)
  end

  #
  # Tell each object in the index results to populate embedded items for each model reference
  def embed_all_references
    return @master_objects unless params[:embed_all_references] == 'true' && @master_objects.present?

    @master_objects.each do |mo|
      mo.populate_embedded_items if mo.respond_to?(:populate_embedded_items)
    end
    @master_objects
  end

  #
  # Add the embedded_item to permitted params array
  # The embedded_item params are only used in an update. Create actions are handled separately
  def extend_permitted_params_with_embedded_item(pp_array)
    pp_array << { embedded_item: embedded_item_permitted_params } if @embedded_item
  end

  #
  # The list of permitted parameters for an embedded item
  def embedded_item_permitted_params
    epp = @embedded_item.class.permitted_params
    @embedded_item.class.refine_permitted_params(epp)
  end

  #
  # Set up embedded items for each instance list item
  def refresh_embedded_item_for(instance_list)
    instance_list.each do |oi|
      handle_embedded_item oi
    end
  end

  def embedded_item_secure_params
    return unless params.dig(params_namespace, :embedded_item)

    params[params_namespace].require(:embedded_item).permit(embedded_item_permitted_params)
  end
end
