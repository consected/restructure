# frozen_string_literal: true

# View Redcap project configurations
class Redcap::ProjectUserRequestsController < UserBaseController
  before_action :set_defaults

  #
  # Request records to be retrieved and stored, if the user has a matching admin profile or is logged in as an admin currently
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

  #
  # Request Redcap project archive, if the user has a matching admin profile or is logged in as an admin currently
  def request_archive
    set_instance_from_id
    @redcap__project_admin.dump_archive

    msg = "Project archive requested at #{DateTime.now}"
    render json: { message: msg }, status: 200
  end

  #
  # Request project user list, if the user has a matching admin profile or is logged in as an admin currently
  def request_users
    set_instance_from_id
    @redcap__project_admin.capture_project_users

    msg = "Project users requested at #{DateTime.now}"
    render json: { message: msg }, status: 200
  end

  #
  # Allows users to download field files stored in Redcap through appropriate links, if they have the appropriate
  # `nfs store group <admin role id>` assignment and file filters set up. A matching admin profile is not required.
  def download_field_file
    record_id = params[:record_id]
    field_name = params[:field_name]
    tn = "\\.#{params[:id].pluralize}"

    svp = { secure_view: params[:secure_view]&.to_unsafe_h }

    project_admin = Redcap::ProjectAdmin.active.order(id: :desc).find_by('dynamic_model_table ~ ?', tn)
    if project_admin
      project_admin.current_user = current_user
      container = project_admin.file_store
      path = "#{project_admin.dynamic_model_table}/file-fields/#{record_id}" if record_id
      sf = container&.stored_files&.find_by(path:, file_name: field_name) if path
    end
    if sf
      url = "/nfs_store/downloads/#{container.id}?activity_log_id=#{container.parent_item&.id}&" \
            "activity_log_type=redcap__project_admin&download_id=#{sf.id}&retrieval_type=stored_file&#{svp.to_query}"
      redirect_to url
    else
      Rails.logger.warn "Download field file failed for record_id: #{record_id}, field_name: #{field_name}, " \
                        "project_admin: #{project_admin&.id}, container: #{container&.id}, path: #{path}, tn: #{tn}"
      render json: { message: 'File not found or inaccessible' }, status: 404
    end
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

    ma = current_user.matching_admin
    raise FphsException, "Current user #{current_user.email} requires a matching admin" unless ma

    @redcap__project_admin.current_admin = ma
  end

  #
  # Set the Redcap project admin instance, from the first to match:
  #  - integer ID
  #  - id == project_id: REDCap project ID in param[:project_id]
  #  - id == project_name: project name in param[:project_name]
  # The id param is used in all cases, checking if the id is an integer or a string
  def set_instance_from_id
    pid = params[:id]
    project_id = params[:project_id]
    server_url = params[:server_url]
    project_name = params[:project_name]
    if pid.to_i.to_s == pid
      @redcap__project_admin = Redcap::ProjectAdmin.active.find(pid)
    elsif pid == 'project_id'
      # Find a matching data collection instrument by name and if found look up the project admin
      @redcap__project_admin = Redcap::ProjectAdmin
                               .active
                               .where("captured_project_info ->> 'project_id' = ?", project_id.to_s)
                               .where(server_url: server_url)
                               .reorder('')
                               .order(updated_at: :desc)
                               .first
    elsif pid == 'project_name'
      # Try the project by name instead
      @redcap__project_admin = Redcap::ProjectAdmin.active.find_by_name(project_name)
    end

    raise FphsException, 'no matching project found' unless @redcap__project_admin

    @id = @redcap__project_admin.id
    upgrade_user_to_admin

    @redcap__project_admin
  end
end
