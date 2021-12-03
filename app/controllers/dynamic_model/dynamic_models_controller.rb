# frozen_string_literal: true

# User controller for interacting with dynamic model implementations
class DynamicModel::DynamicModelsController < UserBaseController
  include MasterHandler

  def template_config
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
  # If dynamic model doesn't relate to a master there will be no master objects
  # Just return with an empty result
  def filter_records
    return [] unless @master_objects
    return @master_objects if @master_objects.is_a? Array

    pk = @implementation_class.primary_key
    @filtered_ids = @master_objects
                    .select { |i| i.class.definition.default_options&.calc_if(:showable_if, i) }
                    .map { |o| o.attributes[pk] }
    @master_objects = @master_objects.where(pk => @filtered_ids)
    filter_requested_ids
    limit_results
  end
end
