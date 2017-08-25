class ActivityLogsController < ApplicationController

  
  before_action :init_vars
  before_action :authenticate_user!
  before_action :set_parent_item
  before_action :set_item, only: [:show]

  helper_method :permitted_params

  def show

  end

def new
    @activity_log = @item.activity_logs.build
    render partial: edit_form
  end

  def edit

  end

  def update

  end

  def create

  end
  
  def index

    @activity_logs = @item.activity_logs
    s = @activity_logs.as_json

    k = "activity_logs"


    phone_nums = @item.master.player_contacts.phone


    res = {activity_logs: s, player_contacts: phone_nums,  item_id: @item.id, item_type: @item_type.singularize, item_types_name: @item_type, item_data: @item.data, master_id: @master.id, update_action: @update_action, multiple_results: k}

    render json: {k => res}
  end


  private
    def edit_form
      'activity_logs/edit_form'
    end

    def init_vars

    end
    
    def set_item
      return if params[:id] == 'cancel'
      @activity_log = @item.activity_logs.find(params[:id])
      @id = @activity_log
    end

    def set_parent_item
      @item_type = item_controller = params[:item_controller]
      item_class_name = item_controller.singularize.camelize

      # We will return a 404 if the requested item_class_name is not one of the valid set.
      # This prevents insecure requests from the user being used to access objects below
      icn = ActivityLog.works_with item_class_name

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


    def permitted_params
      [:item_id, :item_type ]
    end
  private

    def secure_params
      params.require(object_name.to_sym).permit(*permitted_params)
    end


end
