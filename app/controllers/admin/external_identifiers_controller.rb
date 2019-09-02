class Admin::ExternalIdentifiersController < AdminController

  helper_method :permitted_params, :objects_instance, :human_name
  after_action :routes_reload, only: [:update, :create]

  protected
    def routes_reload
      DynamicModel.routes_reload
    end

    def view_folder
      'admin/common_templates'
    end


    def permitted_params
      @permitted_params = [:id, :name, :label, :external_id_attribute, :alphanumeric, :external_id_view_formatter, :external_id_edit_pattern, :prevent_edit, :pregenerate_ids, :min_id, :max_id, :extra_fields, :disabled]
    end

end
