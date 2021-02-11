# frozen_string_literal: true

# View Redcap project configurations
class Redcap::ProjectAdminsController < AdminController
  before_action :set_defaults

  helper_method :transfer_mode_options, :notes_editor

  private

  def set_defaults
    @show_extra_help_info = { form_info_partial: 'redcap/project_admins/form_info' }
  end

  #
  # Options for the select tag
  def transfer_mode_options
    [
      ['no transfer', 'no transfer'],
      ['manually transferred', 'manually transferred'],
      ['automatically transferred once', 'automatically transferred once'],
      ['automatic transfer running', 'automatic transfer running']
    ]
  end

  def status_options
    [
      ['never run', 'never run'],
      ['ran once', 'ran once'],
      ['running periodically', 'running periodically'],
      ['stopped - changes detected', 'stopped - changes detected'],
      ['stopped - manually', 'stopped - manually'],
      ['stopped - failed', 'stopped - failed']
    ]
  end

  def notes_editor
    :markdown
  end

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
    %i[study name server_url api_key transfer_mode frequency status disabled notes]
  end
end
