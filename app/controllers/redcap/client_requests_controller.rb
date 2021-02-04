# frozen_string_literal: true

# View Redcap API client request log
class Redcap::ClientRequestsController < AdminController
  private

  def no_edit
    true
  end

  def view_folder
    'admin/common_templates'
  end

  def default_index_order
    { updated_at: :desc }
  end

  def primary_model
    Redcap::ClientRequest
  end

  def permitted_params
    %i[name server_url action created_at]
  end
end
