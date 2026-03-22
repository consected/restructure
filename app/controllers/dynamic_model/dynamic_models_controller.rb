# frozen_string_literal: true

# User controller for interacting with dynamic model implementations
class DynamicModel::DynamicModelsController < UserBaseController
  include MasterHandler
  include EmbeddedItemHandler

  def template_config
    Application.refresh_dynamic_defs

    refresh_embedded_item_for @instance_list

    render partial: 'dynamic_models/common_search_results_template_set'
  end

  def destroy
    not_authorized
  end

  private

  #
  # The list of permitted parameters based on the definition
  def permitted_params
    @implementation_class ||= implementation_class

    res = @implementation_class.permitted_params
    @implementation_class.refine_permitted_params res
  end

  #
  # The secure parameters (key / value strong params) that can be used to
  # create or update instances
  def secure_params
    return @secure_params if @secure_params

    @secure_params = params.require(param_set_name).permit(*permitted_params)
  end

  #
  # Remove items that are not showable, based on showable_if in the default options config
  # In some special cases (user profile related items) there may not be a connection directly to this
  # master record, so the current user will not be set, but the set of @master_objects will be in place.
  # Set the current_user for these items so that they can be handled within the showable_if evaluation.
  # If there are no @master_objects set we just return with an empty (not nil) result.
  def filter_records
    return [] unless @master_objects
    return @master_objects if @master_objects.is_a? Array

    pk = @implementation_class.primary_key
    @filtered_ids = @master_objects
                    .each { |i| i.current_user.nil? && i.respond_to?(:current_user=) && i.current_user ||= current_user }
                    .select { |i| i.class.definition.default_options&.calc_if(:showable_if, i) }
                    .map { |o| o.attributes[pk] }
    @master_objects = @master_objects.where(pk => @filtered_ids)
    filter_requested_ids
    limit_results
  end

  #
  # Setup the option type config for :default
  def handle_option_type_config
    return @option_type_config if @option_type_config

    # Find the option type attribute name from the definition _configurations.option_type_attr_name
    impl_class = @implementation_class || object_instance.class
    @option_type_attr_name = impl_class.option_type_attr_name if impl_class.respond_to?(:option_type_attr_name)
    return unless @option_type_attr_name

    # Set the option type from the param if we are using a current admin sample form
    etp = params[:option_type_name] if current_admin_sample
    # Get the value from the specified attribute name
    etp = object_instance&.send(@option_type_attr_name).to_s.underscore.to_sym if etp.blank?
    return unless etp.present?

    etp = etp.to_sym
    return unless @implementation_class.definition.option_configs_names&.include?(etp)

    @option_type_name = etp
    # Get the options that were current when the form was originally created, or the current
    # options if this is a new instance
    @option_type_config = if object_instance&.persisted?
                            object_instance.option_type_config
                          else
                            object_instance&.send("#{@option_type_attr_name}=", @option_type_name)
                            @implementation_class.definition.option_type_config_for(etp)
                          end
  end

  def param_set_name
    @param_set_name ||= implementation_class.name.ns_underscore.gsub('__', '_').singularize.to_sym
  end

  #
  # Set the default build parameters to use the external id
  # for the new dynamic model by getting it from the foreign_key_through_external_id
  def setup_default_build_params
    eid_assoc = implementation_class.foreign_key_through_external_id
    return unless eid_assoc

    ext_item = @master.send(eid_assoc).first
    external_id = ext_item&.external_id

    @implementation_class ||= implementation_class
    resname = param_set_name
    params[resname] ||= {}

    if current_admin_sample
      @master.current_user = current_user
      params[resname].merge!(master_id: @master&.id)
      return
    end

    params[resname].merge! @implementation_class.foreign_key_name => external_id
  end
end
