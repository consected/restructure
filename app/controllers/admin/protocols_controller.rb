class Admin::ProtocolsController < AdminController
  include AdminControllerHandler


  private

    def permitted_params
      [:name, :disabled, :position]
    end
end
