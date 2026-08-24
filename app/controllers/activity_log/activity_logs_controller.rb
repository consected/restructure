# frozen_string_literal: true

class ActivityLog::ActivityLogsController < UserBaseController
  before_action :set_extra_type_in_secure_params, only: :new

  include MasterHandler
  include ParentHandler
  include EmbeddedItemHandler
  include ESignature::ESignatureHandler

  # The @item is set to represent the instance that activity log belongs to
  # e.g. a player contact
  # Not called for new or edit, since these are call elsewhere
  before_action :set_item, only: %i[index create update destroy]
  before_action :apply_perspective, only: :index
  after_action :check_authentication_still_valid

  def template_config
    Application.refresh_dynamic_defs

    cache_key = Digest::SHA256.hexdigest(helpers.partial_cache_key("activity-log-template-config-#{@item_type}-#{@id_list}"))
    set_browser_cache(max_age: 30)
    return unless stale?(etag: cache_key)

    refresh_embedded_item_for @instance_list

    render partial: 'activity_logs/common_search_results_template_set'
  end

  private

  def edit_form
    'common_templates/edit_form'
  end

  #
  # Set up extra configurations for an edit form, such as save actions, captions and tracker history links,
  # based on the extra option configs and viewable attributes
  def edit_form_extras
    extras_caption_before = {}
    if @option_type_config
      caption = @option_type_config.label
      item_list = @option_type_config.fields - @implementation_class.fields_to_sync.map(&:to_s) - ['tracker_history_id']
      extras_caption_before = @option_type_config.caption_before
      sa = @option_type_config.save_action
      vo = @option_type_config.view_options || {}
      l = @option_type_config.labels || {}
    end
    if @item
      caption ||= @item.data
      item_list ||= @implementation_class.view_attribute_list -
                    @implementation_class.fields_to_sync.map(&:to_s) -
                    ['tracker_history_id']
    else
      caption ||= 'log item'
      item_list ||= @implementation_class.view_blank_log_attribute_list - ['tracker_history_id']
    end

    cb = {}
    if extras_caption_before[:notes].blank?
      nfc = app_config_text(:notes_field_caption)
      unless nfc.blank?
        cb[:notes] = {
          caption: nfc
        }
      end
    end
    cb.merge! extras_caption_before

    {
      caption:,
      caption_before: cb,
      labels: l,
      view_options: vo,
      item_list:,
      item_flags_after: :notes,
      save_action: sa
    }
  end

  def edit_form_helper_prefix
    'activity_log'
  end

  def item_data
    @item.data if @item&.respond_to?(:data)
  end

  def item_type_id
    :"#{item_type_us}_id"
  end

  def item_type_us
    @item_type.singularize.ns_underscore
  end

  # Get associated items for the activity log list, based on the @item_type, which is specified in the request route
  # as /masters/1/item_type/2/activity_log_self/3
  # If the left-hand item list panel for activity logs is hidden, don't return everything, just
  # get the items that are in the filtered objects as embedded items
  # Otherwise get all items for this master
  def items
    if @implementation_class.definition.hide_item_list_panel
      master_objects_embedded_items @item_type
    elsif @master.respond_to? @item_type
      @master.send(@item_type)
    elsif @master.respond_to? "dynamic_model__#{@item_type}"
      @master.send("dynamic_model__#{@item_type}")
    end
  end

  #
  # Remove items that are not showable, based on showable_if in the extra log type config
  # This is a soft filtering of items, rather than a secure approach to avoiding them being seen,
  # since we are using showable_if only to filter in the activity log list, but continue to show the
  # items as an embedded log item.
  # Be sure to check that the item responds to this, since it is possible for the items
  # being retrieved to be the underlying parent items that activity log records belong to
  # For example, in a phone log, the log records belong to player contacts, and these are retrieved
  # through the activity log controller
  def filter_records
    return @master_objects if @master_objects.is_a? Array

    @filtered_ids = @master_objects
                    .select { |i| i.option_type_config&.calc_if(:showable_if, i) }
                    .map(&:id)
    @master_objects = @master_objects.where(id: @filtered_ids)
    filter_requested_ids
    limit_results
    embed_all_references
  end

  #
  # Extend the data returned for an index request
  # to include an item listing the "creatables", the activity logs
  # that can be created by a user directly in this master,
  # not as model references within a specific item.
  def extend_result
    item_id = @item.id if @item

    options = if action_name == 'index'
                { include_references: false }
              else
                {}
              end

    creatables = @master_objects.build.creatables(**options)

    {
      al_type: params_namespace,
      item_type: item_type_us,
      item_types_name: @item_type,
      item_id:,
      item_data:,
      @item_type => items,
      creatables:
    }
  end

  #
  # Actions new or create need to set up the @item relationship
  # which is the model instance the activity log is related to.
  def set_additional_attributes(obj)
    return unless @item && obj.class != @item.class

    obj.item_id = @item.id
    obj.send("#{item_type_us}=", @item)
  end

  #
  # Set the parent item for the activity log by getting it from the URL params
  # and also checking that it is actually valid based on Activity Log config.
  # For example an @item is a PlayerContact in activity_log__player_contacts
  # or ExtAssignment in activity_log__ext_assignments
  def set_item
    return @item if @item && @implementation_class

    @master ||= object_instance.master
    raise 'Failed to get @master' unless @master

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
        @item = item_class.find(param_item_id)
        raise "Failed to get @item for #{item_class_name}" unless @item
      end
    else
      @item = object_instance.item
      @item_type = @item.class.name
    end

    return unless @item

    @master_id = @item.master_id
    @item_id = @item.id
    #  return if the Activity Log does not work with this item_type / rec_type combo
    @implementation_class = ActivityLog.implementation_class_for @item
    not_found unless @implementation_class
  end

  #
  # The list of permitted parameters based on the definition
  def permitted_params
    res = @implementation_class.permitted_params
    res = @implementation_class.refine_permitted_params res
    extend_permitted_params_with_embedded_item(res)
    res
  end

  #
  # The secure parameters (key / value strong params) that can be used to
  # create or update instances
  def secure_params
    @secure_params ||= params.require(params_namespace.singularize.to_sym).permit(*permitted_params)
  end

  #
  # The activity log implementation class, based on the controller name.
  # Resolved through the Resources::Models registry rather than String#constantize
  # so only registered (allow-listed) ActivityLog implementations can be returned.
  def implementation_class
    cn = controller_name.singularize.to_s.camelize
    Resources::Models.find_model!("ActivityLog::#{cn}")
  end

  #
  # Use the correct extra log type value, based on either the param (for a new action) or
  # the object_instance attribute (for an edit action)
  def handle_option_type_config
    etp = params[:extra_type]
    etp = params[:extra_log_type] if etp.blank?
    etp = object_instance&.extra_log_type if etp.blank?
    @is_activity_log_option_type = true

    etp = if etp.blank?
            object_instance ? :primary : :blank_log
          else
            etp.to_s.underscore.to_sym
          end

    set_item

    unless etp.present? && @implementation_class && @implementation_class.definition.option_configs_names&.include?(etp)
      return
    end

    @option_type_name = etp
    # Get the options that were current when the form was originally created, or the current
    # options if this is a new instance
    @option_type_config = if object_instance&.persisted?
                            object_instance.option_type_config
                          else
                            @implementation_class.definition.option_type_config_for(etp)
                          end
    @option_type_attr_name = :extra_log_type
    object_instance.extra_log_type = @option_type_name unless object_instance.nil? || object_instance.persisted?
  end

  #
  # Force a sign out if the current user access is locked since we started the action.
  # This may happen during an e-signature if the user fails the authentication challenge
  # too many times.
  def check_authentication_still_valid
    sign_out(current_user) if current_user.access_locked?
  end

  def set_extra_type_in_secure_params
    pname = params_namespace.singularize.to_sym

    return if params[pname]

    et = params[:extra_type]
    params[pname] = { extra_log_type: et }
  end

  #
  # Apply a named perspective to @master_objects when params[:perspective] is present,
  # or when a default perspective is configured in the app configuration for the current
  # user and resource. Looks up the panel by params[:panel_name] and the current user's
  # app type, then resolves the matching perspective config and runs the backend runner.
  def apply_perspective
    panel_name = params[:panel_name].presence
    return unless panel_name && @implementation_class && @master

    perspective_name = params[:perspective].presence
    resource_name    = @implementation_class.resource_name.to_s

    # When no explicit perspective param, check the app config for a per-user default
    if perspective_name.blank?
      defaults = Admin::AppConfiguration.hash_for(:default_activity_log_perspective, current_user)
      raw_default = defaults[resource_name.to_sym].presence || defaults[resource_name].presence
      if raw_default.present?
        resolved = if raw_default.is_a?(String) && raw_default.include?('{{')
                     # Only role_name is exposed to the substitution (issue #1362) - mirrors
                     # the fix in masters/_search_results_resources_panel.html.erb, so a
                     # literal (non-structural) tag such as {{first_name}} can never resolve
                     # to real per-user data here; it silently resolves blank instead.
                     current_user_role_name = current_user&.role_names&.first.to_s
                     substitution_data = { role_name: current_user_role_name }
                     Formatter::Substitution.substitute(raw_default, data: substitution_data, tag_subs: nil,
                                                                     ignore_missing: true)&.strip
                   else
                     raw_default
                   end
        perspective_name = resolved.presence
      end
    end

    return unless perspective_name

    # Any missing or invalid configuration raises FphsException so the error surfaces
    # immediately rather than silently showing unfiltered results.

    panel = Admin::PageLayout.active
                             .where(app_type_id: current_user.app_type_id, panel_name:)
                             .first

    unless panel
      raise FphsException, "apply_perspective: no active panel found for panel_name=#{panel_name.inspect} app_type_id=#{current_user.app_type_id}"
    end

    all_perspectives = panel.view_options&.perspectives

    unless all_perspectives.present?
      raise FphsException, "apply_perspective: panel #{panel.id} has no perspectives configured"
    end

    perspectives_for_resource = (all_perspectives.with_indifferent_access[resource_name] || [])
    config = perspectives_for_resource.find { |p| p.with_indifferent_access[:name].to_s == perspective_name }

    unless config
      raise FphsException, "apply_perspective: no perspective named #{perspective_name.inspect} found for resource #{resource_name.inspect}; available keys: #{all_perspectives.keys.inspect}"
    end

    # Wrap only the runner so unexpected runtime errors are logged with context
    # before being re-raised. The validation guards above propagate directly.
    begin
      result = ActivityLog::Perspectives::Runner.new(
        config, @implementation_class, current_user, master: @master
      ).run
    rescue StandardError => e
      msg = "apply_perspective: runner failed for perspective #{perspective_name.inspect} on #{resource_name.inspect}: #{e.message}"
      Rails.logger.error msg
      Rails.logger.error e.short_string_backtrace
      raise FphsException, msg
    end

    Rails.logger.debug { "apply_perspective: runner result=#{result.nil? ? 'nil (no matching records)' : result.to_sql}" }
    @master_objects = @master_objects.merge(result) if result
  end
end
