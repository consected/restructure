class GeneralSelectionsController < ApplicationController

  include AdminControllerHandler

  
  protected
  
    def filters
      GeneralSelection::ItemTypes.dup.map {|g| [g,g]}.to_h
    end
    
    def filters_on
      :item_type
    end
  
    def default_index_order      
      {updated_at: :desc}
    end
  private
    def secure_params
      params.require(:general_selection).permit(:name, :value, :item_type, :disabled, :edit_if_set, :edit_always, :create_with, :position, :lock, :description)
    end
    
end
