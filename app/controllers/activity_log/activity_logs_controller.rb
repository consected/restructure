class ActivityLog::ActivityLogsController < ApplicationController

  before_action :authenticate_user!

  include MasterHandler
  include ParentHandler
  # Not for new or edit, since these are call elsewhere
  before_action :set_item, only: [:index, :create, :update, :destroy]
  # before_action :handle_extra_log_type, only: [:edit, :new]
  before_action :handle_embedded_item, only: [:edit, :new, :create, :update]


  private


    def edit_form
      'common_templates/edit_form'
    end

    def handle_embedded_item

      if object_instance.model_references.length == 1 && object_instance.creatable_model_references.length == 0
        @embedded_item = object_instance.model_references.first.to_record
      elsif object_instance.model_references.length == 0 && object_instance.creatable_model_references.length == 1
        @embedded_item = object_instance.creatable_model_references.first.first.camelize.constantize.new
      end

      if @embedded_item
        @embedded_item.master ||= object_instance.master
        @embedded_item.master.current_user ||= object_instance.master_user

        if action_name == 'create'
          begin
            ei_secure_params = params[al_type.singularize.to_sym].require(:embedded_item).permit(@embedded_item.class.permitted_params)
            @embedded_item.update ei_secure_params
          rescue ActionController::ParameterMissing
            raise FphsException.new "Could not save the item, since you do not have access to any of the data it references."
          end
        end
      end


      object_instance.embedded_item = @embedded_item
    end

    def edit_form_extras
      extras_caption_before = {}
      if @extra_log_type
        caption = @extra_log_type.label
        item_list = @extra_log_type.fields - @implementation_class.fields_to_sync.map(&:to_s) - ['tracker_history_id']
        extras_caption_before  = @extra_log_type.caption_before
        sa = @extra_log_type.save_action
      end
      if @item
        caption ||= @item.data
        item_name = @item.class.human_name
        item_list ||= @implementation_class.view_attribute_list - @implementation_class.fields_to_sync.map(&:to_s) - ['tracker_history_id']
      else
        caption ||= 'log item'
        item_name = ''
        item_list ||= @implementation_class.view_blank_log_attribute_list - ['tracker_history_id']
      end
      cb = {
        protocol_id: "Select the protocol this  #{activity_log_name} is related to. A tracker event will be recorded under this protocol.",
        "set_related_#{item_type_us}_rank".to_sym => "To change the rank of the related #{item_name}, select it:"
      }

      cb[:all_fields] = "Enter details about the #{activity_log_name}" if extras_caption_before[:all_fields].blank? && permitted_params.include?(:select_call_direction)
      if extras_caption_before[:notes].blank?
        nfc = app_config_text(:notes_field_caption)
        cb[:notes] = nfc  unless nfc.blank?
      end
      cb[:submit] = 'To add specific protocol status and method records, save this form first.' if item_list.include?(:protocol_id) && !item_list.include?(:sub_process_id )

      cb.merge! extras_caption_before

      {
        caption: caption,
        caption_before: cb,
        item_list: item_list,
        item_flags_after: :notes,
        save_action: sa
      }
    end

    def activity_log_name
      object_instance.class.activity_log_name
    end

    def edit_form_helper_prefix
      'activity_log'
    end

    def al_type
      @implementation_class.table_name
    end

    def item_data
      @item.data if @item && @item.respond_to?(:data)
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
      return @item if @item && @implementation_class
      raise "Failed to get @master" unless @master

      if params[:item_id].blank?
        @item_type = item_controller
        @master_id = params[:master_id]
        @implementation_class = implementation_class
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
        @implementation_class = ActivityLog.implementation_class_for @item
        return not_found unless @implementation_class
      end
    end



    def permitted_params
      res =  @implementation_class.permitted_params
      # The embedded_item params are only used in an update. Create actions are handled separately
      if @embedded_item
       res << {embedded_item: @embedded_item.class.permitted_params}
      end

      res
    end

    def secure_params
      params.require(al_type.singularize.to_sym).permit(*permitted_params)
    end

    def implementation_class
      cn = "#{controller_name.singularize}".camelize
      cnf = "ActivityLog::#{cn}"
      cnf.constantize
    end

    # Use the correct extra log type, based on either the param (for a new action) or
    # the object_instance attribute (for an edit action)
    def handle_extra_log_type

      etp = params[:extra_type]
      if etp.blank?
        etp = object_instance.extra_log_type
      end

      if etp.blank?
        etp = object_instance ? 'primary' : 'blank_log'
      end

      set_item

      if etp.present? && @implementation_class && @implementation_class.extra_log_type_config_names.include?(etp.underscore)
        @extra_log_type_name = etp.underscore
        @extra_log_type = @implementation_class.extra_log_type_config_for(etp.underscore)
        object_instance.extra_log_type = @extra_log_type_name unless object_instance.persisted?
      end

    end

    def check_editable?
      handle_extra_log_type if action_name == 'edit'
      unless object_instance.allows_current_user_access_to? :edit
        not_editable
        return
      end
    end

    def check_creatable?
      handle_extra_log_type if action_name == 'new'
      unless object_instance.allows_current_user_access_to? :create
        not_creatable
        return
      end
    end


end
