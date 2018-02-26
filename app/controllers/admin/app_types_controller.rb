class Admin::AppTypesController < AdminController

  private
    def secure_params
        params.require(object_name.to_sym).permit(:name, :label, :app_type_id, :disabled)
    end
end
