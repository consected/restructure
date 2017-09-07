class ActivityLogsController < ApplicationController

  include MasterHandler
  before_action :authenticate_user!
  before_action :set_item, only: [:index, :new, :edit, :create, :update, :destroy]


  

  private

    def edit_form
      'common_templates/edit_form'
    end

    def edit_form_extras
      {
        caption: "#{@item.data}"
      }
    end

    def edit_form_helper_prefix
      'activity_log'
    end

    def al_type
      @al_class.table_name
    end

    def item_data
      @item.data
    end

    def item_type_id
      "#{item_type_us}_id".to_sym
    end

    def item_type_us
      @item_type.singularize.underscore
    end

    def items
      @master.send(@item_type)
    end

    def extend_result
      {
        al_type: al_type,
        item_type: item_type_us,
        item_types_name: @item_type,
        item_id: @item.id,
        item_data: item_data,
        @item_type => items

      }
    end

    def set_additional_attributes obj
      obj.item_id = @item.id
    end



    # set the parent item for the activity log by getting it from the URL params
    # and also checking that it is actually valid based on Activity Log config
    def set_item

      raise "Failed to get @master" unless @master
      if UseMasterParam.include? action_name
        @item_type = item_controller
        item_class_name = item_controller.singularize.camelize

        # look up the item using the item_id parameter.
        @item  = item_class_name.constantize.find(params[:item_id])    
        raise "Failed to get @item for #{item_class_name}" unless @item
      else
        @item = object_instance.item
        @item_type = @item.class.name
      end

      @master_id = @item.master_id
      @item_id = @item.id
      #  return if the Activity Log does not work with this item_type / rec_type combo
      @al_class = ActivityLog.al_class @item
      return not_found unless @al_class

    end

    

    def permitted_params
     res =  @al_class.attribute_names.map{|a| a.to_sym} - [:disabled, :user_id, :created_at, :updated_at, item_type_id, @item_type.singularize.to_sym] + [:item_id]
     res
    end

    def secure_params
      params.require(al_type.singularize.to_sym).permit(*permitted_params)
    end


end
