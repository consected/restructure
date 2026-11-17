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

    @redcap__project_admin.dynamic_storage.request_records(request_source: :api)

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
    resource_name = params[:id]
    m = find_resource_model(resource_name)
    raise FphsException, "download_field_file resource model not found for resource_name: #{resource_name}" unless m

    tn = m.table_name
    sn = m.model.respond_to?(:definition) ? m.model.definition.schema_name : nil
    tns = sn ? [tn, "#{sn}.#{tn}"] : [tn]

    svp = { secure_view: params[:secure_view]&.to_unsafe_h }

    # When more than one active project admin shares the same dynamic model table,
    # prefer one that actually pulls data (frequency != 'never') and the most recently
    # created (highest id), to match the project that actually captures files.
    project_admin = Redcap::ProjectAdmin.preferred_active(tns)
    if project_admin
      project_admin.current_user = current_user
      container = project_admin.file_store
      path = "#{project_admin.dynamic_model_table}/file-fields/#{record_id}" if record_id
      sf = container&.stored_files&.find_by(path:, file_name: field_name) if path
    else
      Rails.logger.warn "No matching project admin found for download_field_file with resource_name: #{resource_name}, record_id: #{record_id}, field_name: #{field_name}"
    end
    if sf
      url = "/nfs_store/downloads/#{container.id}?activity_log_id=#{container.parent_item&.id}&" \
            "activity_log_type=redcap__project_admin&download_id=#{sf.id}&retrieval_type=stored_file&#{svp.to_query}"
      redirect_to url
    else
      Rails.logger.warn "Download field file failed for record_id: #{record_id}, field_name: #{field_name}, " \
                        "project_admin: #{project_admin&.id}, container: #{container&.id}, path: #{path}, tns: #{tns.inspect}"
      render json: { message: 'File not found or inaccessible' }, status: 404
    end
  end

  #
  # REDCap Data Entry Trigger endpoint. Configured directly in a REDCap project's
  # "Data Entry Trigger" setting (Project Setup > Additional customizations), this is
  # called by REDCap whenever a record or survey response is created or modified, to
  # request this application pull the latest records for the matching project.
  #
  # Requires the standard user_email/user_token API credentials (see UserBaseController)
  # for a user granted access to both the ref-data app type and the redcap_pull_request
  # resource, plus a project-specific internal_project_token to prevent misuse if the
  # URL leaks. The app type used to check access is always ref-data, regardless of the
  # calling user's own current app type, and this is not persisted back to the user record.
  #
  # Also handles GET requests, used by REDCap's "Test" button: these are validated in
  # the same way but never trigger a pull. REDCap's "Test" button calls the configured
  # URL verbatim (project_id/redcap_url are only ever sent in REDCap's own POST payload),
  # so the matching project is looked up by internal_project_token alone whenever
  # project_id/redcap_url are not supplied.
  def data_entry_trigger
    ref_data_app_type = Admin::AppType.active.find_by(name: Settings::FilestoreAdminAppType)
    return render_data_entry_trigger_result(404, 'Not found') unless ref_data_app_type&.active_on_server?

    current_user.app_type_id = ref_data_app_type.id

    unless current_user.can?(:app_type) && current_user.can?(:redcap_pull_request)
      return render_data_entry_trigger_result(403, 'Not authorized')
    end

    project_admin = find_data_entry_trigger_project_admin
    return render_data_entry_trigger_result(400, 'No matching project found') unless project_admin

    unless project_admin.matches_internal_project_token?(params[:internal_project_token])
      return render_data_entry_trigger_result(401, 'Invalid internal_project_token')
    end

    return render_data_entry_trigger_result(200, 'OK') if request.get?

    if project_admin.dynamic_model_table.blank? || !project_admin.dynamic_model_ready?
      return render_data_entry_trigger_result(400, 'Project is not ready to accept records')
    end

    project_admin.current_user = current_user
    project_admin.dynamic_storage.request_records(request_source: :api)

    render_data_entry_trigger_result(200, "Records requested at #{DateTime.now}")
  end

  private

  #
  # Look up the project for a data_entry_trigger request. REDCap's real POST payload
  # always includes project_id/redcap_url, so prefer that match when present; otherwise
  # (e.g. a GET request from REDCap's "Test" button, which calls the configured URL
  # verbatim with no extra params) fall back to matching by internal_project_token alone.
  # @return [Redcap::ProjectAdmin, nil]
  def find_data_entry_trigger_project_admin
    if params[:project_id].present? && params[:redcap_url].present?
      Redcap::ProjectAdmin.find_active_by_redcap_project(params[:project_id], params[:redcap_url])
    else
      Redcap::ProjectAdmin.find_active_by_internal_project_token(params[:internal_project_token])
    end
  end

  def render_data_entry_trigger_result(status, message)
    render json: { message: message }, status: status
  end

  def set_defaults
    @show_again_on_save = true
    @show_extra_help_info = { form_info_partial: 'redcap/project_admins/form_info' }
  end

  def permitted_params
    %i[study name server_url api_key dynamic_model_table transfer_mode frequency disabled options notes]
  end

  #
  # Find a model in Resources::Models using the resource_name from the URL.
  # The URL may contain one of several name formats:
  #   - The exact plural resource_name (e.g. "dynamic_model__press_bp_measurement_rcs")
  #   - The singular item_type_name (e.g. "dynamic_model__press_bp_measurement_rc")
  #   - The name_with_option_type format used by longitudinal Redcap projects with multiple
  #     data collection instruments (e.g. "dynamic_model__press_bp_measurement_rc_day_home_bp_form_upload"),
  #     which is {item_type_name}_{option_type} - the singular name followed by underscore and option type name.
  # @param resource_name [String] the resource_name from the URL parameter
  # @return [Resources::Models::Item | nil]
  def find_resource_model(resource_name)
    return if resource_name.blank?

    found = Resources::Models.find_by(resource_name:) ||
            Resources::Models.find_by(resource_item_name: resource_name.to_sym)
    return found if found

    # Fall back to matching the longest {resource_item_name} prefix by progressively
    # trimming trailing "_segment" suffixes (which represent the option_type).
    # Stop once the candidate no longer contains the "__" namespace separator,
    # to avoid matching base type registrations such as :dynamic_model.
    candidate = resource_name.to_s
    while candidate.include?('__') && (idx = candidate.rindex('_'))
      candidate = candidate[0...idx]
      match = Resources::Models.find_by(resource_item_name: candidate.to_sym)
      return match if match
    end
    nil
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
      # Find a matching project admin by project_id, first with an exact server_url match, then
      # falling back to matching on protocol + host only to tolerate path differences
      # (e.g. caller sends https://redcap.partners.org/redcap/ but project stores .../redcap/api/)
      @redcap__project_admin = Redcap::ProjectAdmin.find_active_by_redcap_project(project_id, server_url)
    elsif pid == 'project_name'
      # Try the project by name instead
      @redcap__project_admin = Redcap::ProjectAdmin.active.find_by_name(project_name)
    end

    unless @redcap__project_admin
      msg = if pid == 'project_name'
              "no matching project found (project_name: #{project_name})"
            else
              "no matching project found (project_id: #{project_id}, server_url: #{server_url})"
            end
      raise FphsException, msg
    end

    @id = @redcap__project_admin.id
    upgrade_user_to_admin

    @redcap__project_admin
  end
end
