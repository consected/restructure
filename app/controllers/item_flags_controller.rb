class ItemFlagsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :set_parent_item
  before_action :set_item, only: [:show, :edit, :update]
  
  def index
    
    @item_flags = @item.item_flags
    s = @item_flags.as_json
    
    k = "item_flags"
    
    res = {results: s, item_id: @item.id, item_type: @item_type.singularize, item_types_name: @item_type, master_id: @master.id, update_action: @update_action}
    
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
    
    flag_list = secure_params[:item_flag_name_id].select {|f| !f.blank?}.map {|f| f.to_i}
    current_flags = @item.item_flags.map {|f| f.item_flag_name_id}.uniq
    added_flags = flag_list - current_flags
    removed_flags =  current_flags - flag_list
    
    logger.debug "Reqested Flag list: #{flag_list}"
    logger.info "Current flags #{current_flags} in #{@item}"    
    logger.info "Removing flags #{removed_flags} from #{@item}"
    logger.info "Adding flags #{added_flags} to #{@item}"
    
    @item.item_flags.where(item_flag_name_id: removed_flags).destroy_all
        
    added_flags.each do |f|
      unless f.blank?
        i = @item.item_flags.build item_flag_name_id: f
        logger.info "Added flag #{f} to #{@item}"
        i.save
      end
    end
    
    # Reload the association to have it register the changes    
    @item.item_flags.reload
    
    # FIXME This should have happened automatically
    @item.master.current_user = current_user  
    
    logger.info "Remaining flags in #{@item} for #{@item.master_user}: #{@item.item_flags.map {|f| f.id}}"
    if added_flags.length > 0 || removed_flags.length > 0
      ItemFlag.track_flag_updates @item, added_flags, removed_flags
      @update_action = true
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
