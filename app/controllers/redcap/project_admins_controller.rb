# frozen_string_literal: true

# View Redcap project configurations
class Redcap::ProjectAdminsController < AdminController
  include AppTypeChange

  before_action :set_defaults
  before_action :setup_file_store, only: [:edit]

  helper_method :transfer_mode_options, :notes_editor, :hide_edit_fields

  def request_latest_rc_configs
    set_instance_from_id

    @redcap__project_admin.current_admin ||= current_admin
    @redcap__project_admin.request_latest_config = true
    @redcap__project_admin.updated_at = Time.now
    @redcap__project_admin.save!

    msg = "Latest configurations requested at #{DateTime.now}"
    render json: { message: msg }, status: 200
  end

  def request_records
    set_instance_from_id
    if @redcap__project_admin.dynamic_model_table.blank?
      raise FphsException, 'set the dynamic model table name before requesting records'
    end

    unless @redcap__project_admin.dynamic_model_ready?
      raise FphsException,
            'set the dynamic model has not been set up'
    end

    @redcap__project_admin.dynamic_storage.request_records

    msg = "Records requested at #{DateTime.now}"
    render json: { message: msg }, status: 200
  end

  def request_archive
    set_instance_from_id
    @redcap__project_admin.current_admin ||= current_admin
    @redcap__project_admin.dump_archive

    msg = "Project archive requested at #{DateTime.now}"
    render json: { message: msg }, status: 200
  end

  def request_users
    set_instance_from_id
    @redcap__project_admin.current_admin ||= current_admin
    @redcap__project_admin.capture_project_users

    msg = "Project users requested at #{DateTime.now}"
    render json: { message: msg }, status: 200
  end

  def request_data_collection_instruments
    set_instance_from_id
    @redcap__project_admin.current_admin ||= current_admin
    @redcap__project_admin.request_data_collection_instruments

    msg = "Data collection instruments requested at #{DateTime.now}"
    render json: { message: msg }, status: 200
  end

  def force_reconfig
    set_instance_from_id
    @redcap__project_admin.current_admin ||= current_admin
    @redcap__project_admin.force_refresh = true
    @redcap__project_admin.data_dictionary_version = nil
    @redcap__project_admin.update!(captured_project_info: nil, transfer_mode: 'none')

    msg = "Reconfiguration requested at #{DateTime.now} - wait a few seconds then click the *refresh* button to review the changes"
    render json: { message: msg }, status: 200
  end

  def update_dynamic_model
    set_instance_from_id
    @redcap__project_admin.current_admin ||= current_admin
    @redcap__project_admin.update_dynamic_model

    msg = "Reconfiguration requested at #{DateTime.now} - wait a few seconds then click the *refresh* button to review the changes"
    render json: { message: msg }, status: 200
  end

  protected

  def capability_name
    'redcap'
  end

  private

  def set_defaults
    @show_again_on_save = true
    @show_extra_help_info = { form_info_partial: 'redcap/project_admins/form_info' }
  end

  #
  # Options for the select tag
  def transfer_mode_options
    [
      ['none', 'none'],
      ['manual', 'manual'],
      ['scheduled', 'scheduled']
    ]
  end

  def status_options
    Redcap::ProjectAdmin::Statuses.map { |_k, v| [v, v] }
  end

  def server_url_list
    Redcap::ProjectAdmin.active.pluck(:server_url).uniq
  end

  def notes_editor
    :markdown
  end

  def view_folder
    'admin/common_templates'
  end

  def hide_edit_fields
    return [] if object_instance.persisted?

    %i[dynamic_model_table transfer_mode frequency disabled]
  end

  def default_index_order
    { updated_at: :desc }
  end

  def primary_model
    Redcap::ProjectAdmin
  end

  def index_params
    %i[study name server_url dynamic_model_table transfer_mode frequency status admin_id]
  end

  def permitted_params
    %i[study name server_url api_key dynamic_model_table transfer_mode frequency disabled options notes]
  end

  def title
    'REDCap: Project Transfer'
  end

  def filters
    pas = Redcap::ProjectAdmin.pluck(:study).uniq
    {
      study: pas,
      status: status_options.transpose[0].uniq,
      transfer_mode: transfer_mode_options.transpose[0].uniq,
      server_url: server_url_list
    }
  end

  def filters_on
    %i[study status transfer_mode server_url]
  end

  #
  # Just in case the file store has not been set up for this project admin,
  # create it now if necessary
  def setup_file_store
    object_instance.current_admin ||= current_admin
    return if object_instance.file_store

    object_instance.create_file_store
  end
end
