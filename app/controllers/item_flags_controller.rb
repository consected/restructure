class ItemFlagsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :set_parent_item
  before_action :set_item, only: [:show, :edit, :update]
  
  def index
    
    @item_flags = @item.item_flags
    s = @item_flags.as_json
    
    k = "item_flags"
    
    res = {results: s, item_id: @item.id, item_type: @item_type.singularize, item_types_name: @item_type, master_id: @master.id}
    
    logger.debug "List: #{res}"
    
    
    render json: {k => res}
  end
  
  def show
    
    
  end
  
  def new
    @item_flag = @item.item_flags.build
    render partial: 'edit_form'
  end
  

  private
    def set_item
      @item_flag = @item.item_flags.find(params[:id])
      @id = @item_flag
    end
  
    def set_parent_item
      @item_type = item_controller = params[:item_controller]
      item_class = item_controller.singularize.camelize.constantize
      @item = item_class.find(params[:item_id])
      @master = @item.master
    end
  
    def secure_params
      params.require(:item_flag).permit(:item_id, :item_type, :item_flag_name_id)
    end
end
