class Admin::ProtocolEventsController < AdminController
  include AdminControllerHandler

  before_action :set_protocol, only: %i[index new show edit]
  before_action :set_protocol_for_edit, only: %i[create update]
  before_action :setup_tree_list, only: [:index]

  helper_method :extra_part

  def index
    @prevent_copy_item = true

    if params[:all]
      @protocol_events = Classification::ProtocolEvent.all
      @sub_process_name = 'All Sub Processes'
    else
      @protocol_events = @sub_process.protocol_events.reload
      @sub_process_name = @sub_process.name
    end
    @protocol_events = filtered_primary_model(@protocol_events)
    @protocol_events = @protocol_events.limited_index
    @protocol_events = @protocol_events.reorder('').order(default_index_order) if default_index_order.present?
    set_objects_instance(@protocol_events)
    response_to_index
  end

  def new(options = {})
    set_object_instance(@protocol_event = @sub_process.protocol_events.build) unless options[:use_current_object]
    object_instance.sub_process_id = @sub_process_id
    options[:use_current_object] = true
    super
  end

  private

  def show_head_info
    true
  end

  def setup_tree_list
    @filter_protocol_tree_list = { protocol_id: @protocol.id, sub_process_id: @sub_process.id }
    @protocol_tree_list_no_help = true
  end

  def extra_part
    'admin/protocols/tree_list'
  end

  def title
    'Events'
  end

  def sub_title
    "Protocol: #{@protocol.name} / Sub Process: #{@sub_process.name}"
  end

  def view_folder
    'admin/common_templates'
  end

  def set_protocol
    return if params[:all]

    if @protocol_event
      @protocol = @protocol_event.protocol
      @sub_process = @protocol_event.sub_process
    elsif params[:protocol_id].blank?
      @protocol = Classification::Protocol.new
      @sub_process = Classification::SubProcess.new
    else
      @protocol = Classification::Protocol.find(params[:protocol_id])
      @sub_process = Classification::SubProcess.find(params[:sub_process_id])
    end

    @protocol_id = @protocol.id
    @sub_process_id = @sub_process.id
    @parent_param = { protocol_id: @protocol_id, sub_process_id: @sub_process_id }
  end

  def set_protocol_for_edit
    @prevent_copy_item = true

    @sub_process = Classification::SubProcess.find(secure_params[:sub_process_id])
    @sub_process_id = @sub_process.id
    @protocol = @sub_process.protocol
    @protocol_id = @protocol.id
    @parent_param = { protocol_id: @protocol_id, sub_process_id: @sub_process_id }
  end

  def permitted_params
    %i[name milestone description disabled sub_process_id]
  end
end
