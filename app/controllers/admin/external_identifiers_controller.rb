class Admin::ExternalIdentifiersController < AdminController

  helper_method :permitted_params, :objects_instance, :human_name


  protected

    def view_folder
      'admin/common_templates'
    end


    def permitted_params
      @permitted_params = [:id, :name, :label, :external_id_attribute, :external_id_view_formatter, :external_id_edit_pattern, :prevent_edit, :pregenerate_ids, :min_id, :max_id,  :disabled]
    end

    def secure_params
      params.require(object_name.to_sym).permit(*permitted_params)
    end

end
