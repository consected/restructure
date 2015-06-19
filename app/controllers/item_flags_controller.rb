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
    index
  end
  
  def new
    @item_flag = @item.item_flags.build
    render partial: 'edit_form'
  end
  
  def create
    
    logger.debug "Flag list: #{secure_params}"
    flag_list = secure_params[:item_flag_name_id]
    
    @item.item_flags.destroy_all
    flag_list.each do |f|
      unless f.blank?
        i = @item.item_flags.build item_flag_name_id: f
        logger.info "Added flag #{f} to #{@item}"
        i.save
      end
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
      item_class = item_controller.singularize.camelize.constantize
      @item = item_class.find(params[:item_id])
      @master = @item.master
    end
  
    def secure_params
      params.require(:item_flag).permit(item_flag_name_id: [])
    end
end
