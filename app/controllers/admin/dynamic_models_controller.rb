# frozen_string_literal: true

class Admin::DynamicModelsController < AdminController
  helper_method :permitted_params, :objects_instance, :human_name
  before_action :set_defaults
  helper_method :view_folder
  after_action :routes_reload, only: %i[update create]

  protected

  def routes_reload
    DynamicModel.routes_reload
  end

  def default_index_order
    { updated_at: :desc }
  end

  def set_defaults
    @show_again_on_save = true
    @show_extra_help_info = { form_info_partial: 'admin/dynamic_models/form_info' }
  end

  def filters
    {
      category: DynamicModel.categories
    }
  end

  def filters_on
    [:category]
  end


  def view_folder
    'admin/common_templates'
  end

  def permitted_params
    @permitted_params = %i[id name table_name schema_name category
                           table_key_name primary_key_name
                           foreign_key_name result_order field_list position options
                           description disabled]
  end
end
