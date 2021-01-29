# frozen_string_literal: true

# View Redcap project configurations
class Redcap::ProjectAdminsController < AdminController
  private

  def view_folder
    'admin/common_templates'
  end

  def default_index_order
    { updated_at: :desc }
  end

  def primary_model
    Redcap::ProjectAdmin
  end

  def permitted_params
    %i[name server_url api_key disabled]
  end
end
