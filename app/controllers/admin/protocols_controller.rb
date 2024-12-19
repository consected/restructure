# frozen_string_literal: true

class Admin::ProtocolsController < AdminController
  include AdminControllerHandler

  private

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
