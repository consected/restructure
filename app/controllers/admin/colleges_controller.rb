class Admin::CollegesController < AdminController
  
  private
    def secure_params
        params.require(object_name.to_sym).permit(:name, :synonym_for_id, :disabled)
    end
end
