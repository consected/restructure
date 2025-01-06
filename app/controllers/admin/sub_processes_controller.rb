class Admin::SubProcessesController < AdminController
  include AdminControllerHandler

  before_action :set_protocol, only: %i[index new show edit]
  before_action :set_protocol_for_edit, only: %i[create update]
  before_action :setup_tree_list, only: [:index]

  helper_method :extra_part

  def index
    @prevent_copy_item = true
    @sub_processes = filtered_primary_model(@protocol.sub_processes)
    @sub_processes = @sub_processes.limited_index
    @sub_processes = @sub_processes.reorder('').order(default_index_order) if default_index_order.present?
    set_objects_instance(@sub_processes)
    response_to_index
  end

  def new(options = {})
    set_object_instance(@sub_process = @protocol.sub_processes.build) unless options[:use_current_object]
    object_instance.protocol_id = @protocol_id
    options[:use_current_object] = true
    super
  end

  private

  def show_head_info
    true
  end

  def setup_tree_list
    @filter_protocol_tree_list = { protocol_id: @protocol.id }
    @protocol_tree_list_no_help = true
  end

  def extra_part
    'admin/protocols/tree_list'
  end

  def title
    'Sub Processes'
  end

  def sub_title
    "Protocol: #{@protocol.name}"
  end

  def view_folder
    'admin/common_templates'
  end

  def admin_links(item = nil)
    return [true] unless item&.id

    [
      ['edit events', admin_protocol_sub_process_protocol_events_path(@protocol, item)]
    ]
  end

  def set_protocol
    protocol_id = params[:protocol_id] || object_instance.protocol_id
    @protocol = Classification::Protocol.find(protocol_id)
    @protocol_id = @protocol.id
    @parent_param = { protocol_id: @protocol_id }
  end

  def set_protocol_for_edit
    @prevent_copy_item = true

    protocol_id = secure_params[:protocol_id] || object_instance.protocol_id
    @protocol = Classification::Protocol.find(protocol_id)
    @protocol_id = @protocol.id
    @parent_param = { protocol_id: @protocol_id }
  end

  def permitted_params
    %i[name disabled protocol_id]
  end
end
