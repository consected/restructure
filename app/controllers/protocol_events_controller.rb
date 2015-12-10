class ProtocolEventsController < ApplicationController
  include AdminControllerHandler

  before_action :set_protocol, only: [:index, :new, :show, :edit]    
  before_action :set_protocol_for_edit, only: [:create, :update]    
  def index
    if params[:all]
      @protocol_events = ProtocolEvent.all
      @sub_process_name = "All Sub Processes"
    else
      @protocol_events = @sub_process.protocol_events
      @sub_process_name = @sub_process.name
    end
    response_to_index
  end
  
  def new options = {}
    @protocol_event = @sub_process.protocol_events.build unless options[:use_current_object]
    render partial: 'form'
  end
  
  
  
  private
    def set_protocol
      return if params[:all]
      
      if @protocol_event
        @protocol = @protocol_event.protocol
        @sub_process = @protocol_event.sub_process      
      elsif params[:protocol_id].blank?
        @protocol = Protocol.new
        @sub_process = SubProcess.new
      else
        @protocol = Protocol.find(params[:protocol_id])      
        @sub_process = SubProcess.find(params[:sub_process_id])
      end
    end
    
    def set_protocol_for_edit
      @sub_process = SubProcess.find(secure_params[:sub_process_id])
      @protocol = @sub_process.protocol
      @parent_param = {protocol_id: @protocol.id, sub_process_id: @sub_process.id} 
    end
    
  private
    def secure_params
      params.require(:protocol_event).permit(:name, :sub_process_id, :disabled, :milestone, :description)
    end
end
