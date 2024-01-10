# frozen_string_literal: true

# View Redcap API client request log
class Redcap::ClientRequestsController < AdminController
  protected

  def capability_name
    'redcap'
  end

  def filters
    {
      action: Redcap::ClientRequest.pluck(:action).uniq.compact.reject(&:blank?),
      name: Redcap::ClientRequest.pluck(:name).uniq.compact.reject(&:blank?),
      server_url: Redcap::ClientRequest.pluck(:server_url).uniq.reject(&:blank?)
    }
  end

  def filters_on
    %i[action name server_url]
  end

  def filters_prevent_disabled
    true
  end

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
    %i[name server_url action created_at result]
  end
end
