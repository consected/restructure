class GeneralSelectionsController < ApplicationController

  include AdminControllerHandler


  private
    def secure_params
      params.require(:general_selection).permit(:name, :value, :item_type, :disabled)
    end
end
