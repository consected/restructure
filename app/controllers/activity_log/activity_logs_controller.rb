class ActivityLog::ActivityLogsController < UserBaseController

  include MasterHandler
  include ParentHandler
  # Not for new or edit, since these are call elsewhere
  before_action :set_item, only: [:index, :create, :update, :destroy]
  # before_action :handle_extra_log_type, only: [:edit, :new]
  before_action :handle_embedded_item, only: [:show, :edit, :new, :create, :update]
  before_action :handle_embedded_items, only: [:index]

  attr_accessor :embedded_item

  private


    def edit_form
      'common_templates/edit_form'
    end

    def set_embedded_item_optional_params
      return unless @embedded_item

      # Allow passing of params to embedded item to initialize the new form
      if params[al_type.singularize.to_sym] && params[al_type.singularize.to_sym][:embedded_item]
        ei_secure_params = params[al_type.singularize.to_sym].require(:embedded_item).permit(@embedded_item.class.permitted_params)
        ei_secure_params.each do |p,v|
          @embedded_item.send("#{p}=", v)
        end
      end

    end

    def handle_embedded_items
      @master_objects.each {|o| handle_embedded_item o}
    end

    def handle_embedded_item use_object=nil

      not_embedded_options = ['not_embedded', 'select_or_add']

      oi = use_object || object_instance
      mrs = oi.model_references

      cmrs = oi.creatable_model_references only_creatables: true

      always_embed_reference = oi.extra_log_type_config.view_options[:always_embed_reference]

      always_embed_item = mrs.select{|m| m.to_record_type == always_embed_reference.ns_camelize}.first if always_embed_reference

      if always_embed_item
        # Always embed if instructed to do so by the options config
        @embedded_item = always_embed_item.to_record
      elsif action_name.in?(['new', 'create']) && cmrs.length == 1
        # If exactly one item is creatable, use this, unless the embeddable item is an activity log.
        cmr_view_as = cmrs.first.last.first.last[:ref_config][:view_as] rescue nil
        @embedded_item = oi.build_model_reference cmrs.first
        @embedded_item = nil if @embedded_item.class.parent == ActivityLog || cmr_view_as && cmr_view_as[:new].in?(not_embedded_options)
      elsif action_name.in?( ['new', 'create']) && cmrs.length > 1
        # If more than one item is creatable, don't use it
        @embedded_item = nil
      elsif action_name.in?( ['new', 'create']) && cmrs.length == 0 && mrs.length == 1
        # Nothing is creatable, but one has been created. Use the existing one.
        @embedded_item = mrs.first.to_record
      elsif action_name.in?(['edit', 'update', 'show', 'index']) && mrs.length == 0
        # If nothing has been embedded, there is nothing to show
        @embedded_item = nil
      elsif action_name.in?(['edit', 'update']) && mrs.length == 1
        # A referenced record exists - the form expects this to be embedded
        # Therefore just use this existing item
        @embedded_item = mrs.first.to_record
        mr_view_as = mrs.first.to_record_options_config[:view_as] rescue nil
        @embedded_item = nil if mr_view_as && mr_view_as[:edit].in?(not_embedded_options)

      elsif action_name.in?(['show', 'index']) && mrs.length == 1 && cmrs.length == 0
        # A referenced record exists and no more are creatable
        # Therefore just use this existing item
        @embedded_item = mrs.first.to_record

      end

      if @embedded_item
        if @embedded_item.class.no_master_association
          @embedded_item.current_user ||= oi.master_user
        else
          @embedded_item.master ||= oi.master
          @embedded_item.master.current_user ||= oi.master_user
        end

        set_embedded_item_optional_params if action_name == 'new'

        if action_name == 'create'
          begin
            ei_secure_params = params[al_type.singularize.to_sym].require(:embedded_item).permit(@embedded_item.class.permitted_params)
            @embedded_item.update ei_secure_params
            oi.updated_at = @embedded_item.updated_at
          rescue ActionController::ParameterMissing
            raise FphsException.new "Could not save the item, since you do not have access to any of the data it references."
          end
        end
      end


      oi.embedded_item = @embedded_item
    end

    def edit_form_extras
      extras_caption_before = {}
      if @extra_log_type_config
        caption = @extra_log_type_config.label
        item_list = @extra_log_type_config.fields - @implementation_class.fields_to_sync.map(&:to_s) - ['tracker_history_id']
        extras_caption_before  = @extra_log_type_config.caption_before
        sa = @extra_log_type_config.save_action
        vo = @extra_log_type_config.view_options || {}
      end
      if @item
        caption ||= @item.data
        item_list ||= @implementation_class.view_attribute_list - @implementation_class.fields_to_sync.map(&:to_s) - ['tracker_history_id']
      else
        caption ||= 'log item'
        item_list ||= @implementation_class.view_blank_log_attribute_list - ['tracker_history_id']
      end

      cb = {}
      if extras_caption_before[:notes].blank?
        nfc = app_config_text(:notes_field_caption)
        cb[:notes] =  {
          caption: nfc
          } unless nfc.blank?
      end
      cb.merge! extras_caption_before

      {
        caption: caption,
        caption_before: cb,
        view_options: vo,
        item_list: item_list,
        item_flags_after: :notes,
        save_action: sa
      }
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

    def filter_records records
      # Remove items that are not showable, based on showable_if in the extra log type config
      # This is a soft filtering of items, rather than a secure approach to avoiding them being seen,
      # since we are using showable_if only to filter in the activity log list, but continue to show the
      # items as an embedded log item.
      # Be sure to check that the item responds to this, since it is possible for the items
      # being retrieved to be the underlying parent items that activity log records belong to
      # For example, in a phone log, the log records belong to player contacts, and these are retrieved
      # through the activity log controller
      records.select { |i| i.extra_log_type_config && i.extra_log_type_config.calc_showable_if(i) }
    end


    def extend_result
      item_id = @item.id if @item

      creatables = @master_objects.build.creatables

      extras = {
        al_type: al_type,
        item_type: item_type_us,
        item_types_name: @item_type,
        item_id: item_id,
        item_data: item_data,
        @item_type => items,
        creatables: creatables
      }

      extras
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
      etp = params[:extra_log_type] if etp.blank?
      if etp.blank?
        etp = object_instance.extra_log_type
      end

      if etp.blank?
        etp = object_instance ? :primary : :blank_log
      else
        etp = etp.to_s.underscore.to_sym
      end

      set_item

      if etp.present? && @implementation_class && @implementation_class.extra_log_type_config_names.include?(etp)
        @extra_log_type_name = etp
        @extra_log_type_config = @implementation_class.extra_log_type_config_for(etp)
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
