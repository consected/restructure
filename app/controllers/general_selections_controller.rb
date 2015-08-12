class GeneralSelectionsController < ApplicationController

  include AdminControllerHandler


  protected
  
    def default_index_order
      logger.info "Doing index order"
      {updated_at: :desc}
    end
  private
    def secure_params
      params.require(:general_selection).permit(:name, :value, :item_type, :disabled)
    end
end
