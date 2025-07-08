# frozen_string_literal: true

class Admin::ProtocolsController < AdminController
  include AdminControllerHandler

  before_action :setup_tree_list, only: [:index]

  helper_method :extra_part

  #
  # Handle the request to copy sub processes and their events from one protocol to another
  def copy_sub_processes
    from_protocol_id = params[:from_protocol_id]
    to_protocol_id = params[:to_protocol_id]

    from_protocol = Classification::Protocol.find from_protocol_id
    to_protocol = Classification::Protocol.find to_protocol_id
    to_protocol.current_admin = current_admin

    res = to_protocol.copy_from(from_protocol)

    flash[:notice] = if res.empty?
                       "#{from_protocol.name} has no new sub processes to copy"
                     else
                       "#{from_protocol.name} added:\n#{res.to_yaml}"
                     end

    redirect_to admin_protocol_sub_processes_path(to_protocol.id)
  end

  private

  def setup_tree_list
    @protocol_tree_list_no_help = true
  end

  def extra_part
    'tree_list'
  end

  def view_folder
    'admin/common_templates'
  end

  def admin_links(item = nil)
    return [true] unless item&.id

    [
      ['edit sub processes', admin_protocol_sub_processes_path(item)]
    ]
  end

  def show_head_info
    true
  end

  def filters
    {
      app_type_id: Admin::AppType.all_by_name.merge('IS NULL': '(not set)')
    }
  end

  def filters_on
    %i[app_type_id]
  end

  def permitted_params
    %i[app_type_id name position disabled]
  end
end
