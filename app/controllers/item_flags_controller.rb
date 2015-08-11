class ItemFlagsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :set_parent_item
  before_action :set_item, only: [:show]
  
  def index
    
    @item_flags = @item.item_flags
    s = @item_flags.as_json
    
    k = "item_flags"
    
    res = {item_flags: s, item_id: @item.id, item_type: @item_type.singularize, item_types_name: @item_type, master_id: @master.id, update_action: @update_action}
        
    render json: {k => res}
  end
  
  def show
    index
  end
  
  def new
    @item_flag = @item.item_flags.build
    render partial: 'edit_form'
  end
  
  def create
    
    flag_list = secure_params[:item_flag_name_id].select {|f| !f.blank?}.map {|f| f.to_i}
    
    begin
      @update_action = ItemFlag.set_flags flag_list, @item, current_user
    rescue ActiveRecord::RecordInvalid => e
      logger.warn "Bad request in create item flags: #{e.inspect}"
      @item_flags = nil
      return bad_request
    end
    
    show
  end
  

  private
    def set_item
      return if params[:id] == 'cancel'
      @item_flag = @item.item_flags.find(params[:id])
      @id = @item_flag
    end
  
    def set_parent_item
      @item_type = item_controller = params[:item_controller]      
      item_class_name = item_controller.singularize.camelize
      
      return not_found unless ItemFlag.works_with item_class_name
      
      item_class = item_class_name.constantize
      
      @item = item_class.find(params[:item_id])
      @master = @item.master
    end
  
    def secure_params
      params.require(:item_flag).permit(item_flag_name_id: [])
    end
end
