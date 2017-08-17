class ItemFlagsController < ApplicationController

  before_action :init_vars
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
    def init_vars
      instance_var_init :id
      instance_var_init :item_flags
      instance_var_init :update_action
    end

    def set_item
      return if params[:id] == 'cancel'
      @item_flag = @item.item_flags.find(params[:id])
      @id = @item_flag
    end
  
    def set_parent_item
      @item_type = item_controller = params[:item_controller]      
      item_class_name = item_controller.singularize.camelize
      
      # We will return a 404 if the requested item_class_name is not one of the valid set.
      # This prevents insecure requests from the user being used to access objects below
      icn = ItemFlag.works_with item_class_name
      
      return not_found unless icn
      
      if defined? icn.constantize
        begin
          item_class = icn.constantize 
        rescue          
          item_class = "DynamicModel::#{icn}".constantize rescue nil
        end
      end
      
      raise "Failed to get #{item_class_name}" unless item_class
      
      @item = item_class.find(params[:item_id])
      
      raise "Failed to get @item for #{item_class_name}" unless @item
      
      @master = @item.master
      
      raise "Failed to get @master for #{@item.inspect}" unless @master
      @master
    end
  
    def secure_params
      params.require(:item_flag).permit(item_flag_name_id: [])
    end
end
