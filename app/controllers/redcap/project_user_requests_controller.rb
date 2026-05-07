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
    m = Resources::Models.find_by(resource_name:)
    raise FphsException, "download_field_file resource model not found for resource_name: #{resource_name}" unless m

    tn = "\\.#{m.table_name}"

    svp = { secure_view: params[:secure_view]&.to_unsafe_h }

    project_admin = Redcap::ProjectAdmin.active.order(id: :desc).find_by('dynamic_model_table ~ ?', tn)
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
      # Find a matching project admin by project_id, first with an exact server_url match, then
      # falling back to matching on protocol + host only to tolerate path differences
      # (e.g. caller sends https://redcap.partners.org/redcap/ but project stores .../redcap/api/)
      by_project_id = Redcap::ProjectAdmin
                      .active
                      .where("captured_project_info ->> 'project_id' = ?", project_id.to_s)
                      .reorder('')
                      .order(updated_at: :desc)

      @redcap__project_admin = by_project_id.where(server_url: server_url).first

      if @redcap__project_admin.nil? && server_url.present?
        begin
          uri = URI.parse(server_url)

          if uri.scheme.present? && uri.host.present?
            request_scheme = uri.scheme.downcase
            request_host = uri.host.downcase

            @redcap__project_admin = by_project_id.find do |project_admin|
              begin
                stored_uri = URI.parse(project_admin.server_url.to_s)
                stored_uri.scheme.present? &&
                  stored_uri.host.present? &&
                  stored_uri.scheme.downcase == request_scheme &&
                  stored_uri.host.downcase == request_host
              rescue URI::InvalidURIError
                Rails.logger.warn "Invalid stored server_url for project_admin #{project_admin.id}: #{project_admin.server_url}"
                false
              end
            end
          end
        rescue URI::InvalidURIError
          Rails.logger.warn "Invalid server_url param in set_instance_from_id: #{server_url}"
        end
      end
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
