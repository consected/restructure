class ActivityLog::ActivityLogsController < ApplicationController

  include MasterHandler
  include ParentHandler
  before_action :authenticate_user!
  before_action :set_item, only: [:index, :new, :edit, :create, :update, :destroy]




  private

    def edit_form
      'common_templates/edit_form'
    end

    def edit_form_extras
      if @item
        caption = @item.data
        item_name = @item.class.human_name
        item_list = @al_class.view_attribute_list - @al_class.fields_to_sync.map(&:to_sym) - [:tracker_history_id]
      else
        caption = 'log item'
        item_name = ''
        item_list = @al_class.view_blank_log_attribute_list - [:tracker_history_id]
      end
      {
        caption: caption,
        caption_before: {
          select_call_direction: "Enter details about the #{activity_log_name}",
          protocol_id: "Select the protocol this  #{activity_log_name} is related to. A tracker event will be recorded under this protocol.",
          "set_related_#{item_type_us}_rank".to_sym => "To change the rank of the related #{item_name}, select it:",
          submit: 'To add specific protocol status and method records, save this form first.',
          notes: "Reminder: do not enter personal health information into the notes."

        },
        item_list: item_list,
        item_flags_after: :notes
      }
    end

    def activity_log_name
      object_instance.class.activity_log_name
    end

    def edit_form_helper_prefix
      'activity_log'
    end

    def al_type
      @al_class.table_name
    end

    def item_data
      @item.data if @item
    end

    def item_type_id
      "#{item_type_us}_id".to_sym
    end

    def item_type_us
      @item_type.singularize.ns_underscore
    end

    def items
      @master.send(@item_type)
    end

    def extend_result
      item_id = @item.id if @item

      {
        al_type: al_type,
        item_type: item_type_us,
        item_types_name: @item_type,
        item_id: item_id,
        item_data: item_data,
        @item_type => items
      }
    end

    def set_additional_attributes obj
      if @item && obj.class != @item.class
        obj.item_id = @item.id
        obj.send("#{item_type_us}=", @item)
      end
    end



    # set the parent item for the activity log by getting it from the URL params
    # and also checking that it is actually valid based on Activity Log config
    def set_item
      raise "Failed to get @master" unless @master

      if params[:item_id].blank?
        @item_type = item_controller
        @master_id = params[:master_id]
        @al_class = activity_log_class
        return
      end

      if UseMasterParam.include?(action_name)
        @item_type = item_controller

        # look up the item using the item_id parameter.
        param_item_id = params[:item_id]
        unless param_item_id == 'ignore'
          @item  = item_class.find(param_item_id)
          raise "Failed to get @item for #{item_class_name}" unless @item
        end
      else
        @item = object_instance.item
        @item_type = @item.class.name
      end

      if @item
        @master_id = @item.master_id
        @item_id = @item.id
        #  return if the Activity Log does not work with this item_type / rec_type combo
        @al_class = ActivityLog.al_class_for @item
        return not_found unless @al_class
      end
    end



    def permitted_params
     fts = @al_class.fields_to_sync.map(&:to_sym)

     res =  @al_class.attribute_names.map{|a| a.to_sym} - [:disabled, :user_id, :created_at, :updated_at, item_type_id, @item_type.singularize.to_sym, :tracker_id] + [:item_id] - fts
     res
    end

    def secure_params
      params.require(al_type.singularize.to_sym).permit(*permitted_params)
    end

    def activity_log_class
      cn = "#{item_controller.singularize}_#{item_rec_type}".camelize
      cnf = "ActivityLog::#{cn}"
      cnf.constantize
    end

end
