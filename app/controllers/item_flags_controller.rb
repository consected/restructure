class ItemFlagsController < ApplicationController

  include ParentHandler

  before_action :init_vars
  before_action :authenticate_user!
  before_action :set_parent_item
  before_action :set_item, only: [:show]

  def index

    @item_flags = @flag_item.item_flags
    s = @item_flags.as_json

    k = "item_flags"

    res = {item_flags: s, item_id: @flag_item.id, item_type: @flag_item_type.singularize, item_types_name: @flag_item_type, master_id: @master.id, update_action: @update_action}

    render json: {k => res}
  end

  def show
    index
  end

  def new
    @item_flag = @flag_item.item_flags.build
    render partial: 'edit_form'
  end

  def create

    flag_list = secure_params[:item_flag_name_id].select {|f| !f.blank?}.map {|f| f.to_i}

    begin
      @update_action = ItemFlag.set_flags flag_list, @flag_item, current_user
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

    def item_controller
      params[:item_controller]
    end

    def set_item
      return if params[:id] == 'cancel'
      @item_flag = @flag_item.item_flags.find(params[:id])
      @id = @item_flag
    end

    def set_parent_item
      @flag_item_type = item_controller


      # We will return a 404 if the requested item_class_name is not one of the valid set.
      # This prevents insecure requests from the user being used to access objects below
      icn = ItemFlag.works_with item_class_name

      return not_found unless icn

      item_class = icn.ns_constantize if icn
      # if defined? icn.ns_constantize
      #   begin
      #     item_class = icn.ns_constantize
      #   rescue
      #     item_class = "DynamicModel::#{icn}".constantize rescue nil
      #   end
      # end

      raise "Failed to get #{item_class_name}" unless item_class

      @flag_item = item_class.find(params[:item_id])
      raise "Failed to get @flag_item for #{item_class_name}" unless @flag_item

      @master = @flag_item.master
      @master.current_user = current_user

      raise "Failed to get @master for #{@flag_item.inspect}" unless @master
      @master
    end

    def secure_params
      params.require(:item_flag).permit(item_flag_name_id: [])
    end
end
