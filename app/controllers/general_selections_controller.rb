class GeneralSelectionsController < ApplicationController

  include AdminControllerHandler


  protected
  
    def default_index_order
      logger.info "Doing index order"
      {updated_at: :desc}
    end
  private
    def secure_params
      params.require(:general_selection).permit(:name, :value, :item_type, :disabled, :edit_if_set, :edit_always, :create_with, :position, :lock, :description)
    end
    
    def filter_params
      return nil if params[:filter].blank?
      params.require(:filter).permit(:item_type)
    end
end
