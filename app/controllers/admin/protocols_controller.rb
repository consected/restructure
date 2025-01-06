# frozen_string_literal: true

class Admin::ProtocolsController < AdminController
  include AdminControllerHandler

  before_action :setup_tree_list, only: [:index]

  helper_method :extra_part

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
