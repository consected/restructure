# frozen_string_literal: true

# View Redcap project configurations
class Redcap::ProjectUserRequestsController < UserBaseController
  before_action :set_defaults

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
    @redcap__project_admin.dump_archive

    msg = "Project archive requested at #{DateTime.now}"
    render json: { message: msg }, status: 200
  end

  def request_users
    set_instance_from_id
    @redcap__project_admin.capture_project_users

    msg = "Project users requested at #{DateTime.now}"
    render json: { message: msg }, status: 200
  end

  private

  def set_defaults
    @show_again_on_save = true
    @show_extra_help_info = { form_info_partial: 'redcap/project_admins/form_info' }
  end

  def permitted_params
    %i[study name server_url api_key dynamic_model_table transfer_mode frequency disabled options notes]
  end

  #
  # If a current_admin is not set, and a user has access control for
  # redcap_pull_request then upgrade to the matching admin profile for the
  # duration of the call
  def upgrade_user_to_admin
    return if @redcap__project_admin.current_admin

    return not_authorized unless current_user.can? :redcap_pull_request

    @redcap__project_admin.current_admin = current_user.matching_admin
  end

  #
  # Set the Redcap project admin instance, from either an integer ID, or by its name.
  # The id param is used in both cases, checking if the id is an integer or a string
  def set_instance_from_id
    pid = params[:id]
    @redcap__project_admin = if pid.to_i.to_s == pid
                               Redcap::ProjectAdmin.active.find(pid)
                             else
                               Redcap::ProjectAdmin.active.find_by_name(pid)
                             end
    @id = @redcap__project_admin.id
    @redcap__project_admin.current_admin = upgrade_user_to_admin

    @redcap__project_admin
  end
end
