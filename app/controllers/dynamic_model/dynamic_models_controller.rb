# frozen_string_literal: true

class DynamicModel::DynamicModelsController < UserBaseController
  include MasterHandler

  def destroy
    not_authorized
  end

  private

  def permitted_params
    @implementation_class ||= implementation_class

    res = @implementation_class.permitted_params
    @implementation_class.refine_permitted_params res
  end

  def secure_params
    @implementation_class = implementation_class
    params.require(@implementation_class.name.ns_underscore.gsub('__', '_').singularize.to_sym).permit(*permitted_params)
  end

  # Remove items that are not showable, based on showable_if in the default options config
  def filter_records
    @filtered_ids = @master_objects.select { |i| i.definition_default_options&.calc_showable_if(i) }.map(&:id)
    @master_objects = primary_model.where(id: @filtered_ids)
    limit_results
  end
end
