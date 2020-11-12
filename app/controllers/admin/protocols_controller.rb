# frozen_string_literal: true

class Admin::ProtocolsController < AdminController
  include AdminControllerHandler

  private

  def filters
    {
      app_type_id: Admin::AppType.all_by_name.merge('IS NULL': '(not set)')
    }
  end

  def filters_on
    %i[app_type_id]
  end

  def permitted_params
    %i[app_type_id name disabled position]
  end
end
