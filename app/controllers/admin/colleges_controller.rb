class Admin::CollegesController < AdminController

  private
    def permitted_params
        [:name, :synonym_for_id, :disabled]
    end
end
