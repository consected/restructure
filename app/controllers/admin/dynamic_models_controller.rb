# frozen_string_literal: true

class Admin::DynamicModelsController < AdminController
  helper_method :permitted_params, :objects_instance, :human_name
  before_action :set_defaults
  helper_method :view_folder
  after_action :routes_reload, only: %i[update create]

  def update_config_from_table
    set_instance_from_id
    object_instance.current_admin = current_admin
    object_instance.update_config_from_table
    object_instance.save!
    edit
  end

  def versions
    set_instance_from_id
    object_instance.current_admin = current_admin
    @all_versions = object_instance.all_versions_query
    render partial: 'admin/common_templates/def_versions'
  end

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
      category: DynamicModel.categories,
      table_name: DynamicModel.table_names
    }
  end

  def filters_on
    %i[category table_name]
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

  def index_params
    %i[id name schema_name table_name category
       table_key_name primary_key_name
       foreign_key_name result_order position admin_id]
  end

  #
  # Override to specify attributes to initialize a definition with
  # @return [Hash]
  def init_new_with_attrs
    {
      options: <<~END_CONFIG
        _configurations:
          use_current_version: true
      END_CONFIG
    }
  end
end
