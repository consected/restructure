class Admin::ProtocolEventsController < AdminController
  include AdminControllerHandler

  before_action :set_protocol, only: %i[index new show edit]
  before_action :set_protocol_for_edit, only: %i[create update]
  def index
    if params[:all]
      set_objects_instance(@protocol_events = Classification::ProtocolEvent.all)
      @sub_process_name = 'All Sub Processes'
    else
      set_objects_instance(@protocol_events = @sub_process.protocol_events.reload)
      @sub_process_name = @sub_process.name
    end
    response_to_index
  end

  def new(options = {})
    set_object_instance(@protocol_event = @sub_process.protocol_events.build) unless options[:use_current_object]
    render partial: 'form'
  end

  private

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
  end

  def set_protocol_for_edit
    @sub_process = Classification::SubProcess.find(secure_params[:sub_process_id])
    @protocol = @sub_process.protocol
    @parent_param = { protocol_id: @protocol.id, sub_process_id: @sub_process.id }
  end

  def permitted_params
    %i[name sub_process_id disabled milestone description]
  end
end
