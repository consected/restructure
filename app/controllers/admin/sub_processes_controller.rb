class Admin::SubProcessesController < AdminController
  include AdminControllerHandler
  before_action :set_protocol, only: [:index, :new, :show, :edit]
  before_action :set_protocol_for_edit, only: [:create, :update]
  def index
    set_objects_instance(@sub_processes = @protocol.sub_processes)
    response_to_index
  end

  def new options = {}
    set_object_instance(@sub_process = @protocol.sub_processes.build) unless options[:use_current_object]
    render partial: 'form'
  end



  private
    def set_protocol
      @protocol = Classification::Protocol.find(params[:protocol_id])
    end

    def set_protocol_for_edit
      @protocol = Classification::Protocol.find(secure_params[:protocol_id])
      @parent_param = {protocol_id: @protocol.id}
    end

    def permitted_params
      [:name, :disabled, :protocol_id]
    end

end
