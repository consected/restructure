class  Admin::ExternalLinksController < AdminController


  private
    def permitted_params
      [:name, :value, :disabled]
    end
end
