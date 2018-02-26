class  Admin::ExternalLinksController < AdminController


  private
    def secure_params
      params.require(:external_link).permit(:name, :value, :disabled)
    end
end
