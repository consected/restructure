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

    @implementation_class = implementation_class
    resname = @implementation_class.name.ns_underscore.gsub('__', '_').singularize.to_sym
    @secure_params = params.require(resname).permit(*permitted_params)
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
    etp = object_instance.option_type.to_s.underscore.to_sym

    # set_item

    unless etp.present? && @implementation_class && @implementation_class.definition.option_configs_names&.include?(etp)
      return
    end

    @option_type_name = etp
    # Get the options that were current when the form was originally created, or the current
    # options if this is a new instance
    @option_type_config = if object_instance.persisted?
                            object_instance.option_type_config
                          else
                            @implementation_class.definition.option_type_config_for(etp)
                          end

    @option_type_attr_name = :option_type
  end
end
