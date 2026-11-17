# frozen_string_literal: true

class NfsStorePrepareDownloadJob < ApplicationJob
  queue_as :nfs_store_downloads

  class_attribute :notification_defaults, instance_accessor: false

  def perform(user_id:, app_type_id:, selected_items:, container_id:, activity_log_type:, activity_log_id:, multi:)
    user = nil
    path = nil
    temporary_path = nil

    begin
      user = User.find_by(id: user_id)
      raise ActiveRecord::RecordNotFound, 'Download user no longer exists' unless user

      # Match the user's app context at request time without persisting it to their profile.
      user.app_type_id = app_type_id
      raise FsException::NoAccess, 'User no longer has access to the selected application' unless user.app_type_valid?

      prepared_download = NfsStore::PreparedDownload.new
      token = prepared_download.generate_token
      path = prepared_download.path_for(user_id:, token:)
      temporary_path = "#{path}.#{SecureRandom.hex(8)}.tmp"

      download = build_download(user:, selected_items:, container_id:, activity_log_type:, activity_log_id:, multi:)
      items = normalize_items(selected_items)
      retrieved_files = download.retrieve_files_from(items, zip: false)
      raise FsException::Download, 'No files remain available for this download' if retrieved_files.blank?

      FileUtils.mkdir_p(File.dirname(path), mode: 0o750)
      NfsStore::Archive::ZipFileGenerator.zip_retrieved_items(download.all_action_items, target_path: temporary_path)
      File.chmod(0o640, temporary_path)
      File.rename(temporary_path, path)

      notify_user(user, :ready, download_link: download_link(token, app_type_id),
                                expires_at: (File.mtime(path) + Settings::NfsStorePreparedDownloadsTtlHours.hours).to_s)
    rescue StandardError => e
      FileUtils.rm_f(temporary_path) if temporary_path
      FileUtils.rm_f(path) if path
      Rails.logger.error("NFS background download failed for user #{user_id}: #{e.class}: #{e.message}")
      if user
        begin
          notify_user(user, :failed)
        rescue StandardError => notification_error
          Rails.logger.error("Could not send NFS download failure notification to user #{user.id}: " \
                             "#{notification_error.message}")
        end
      end
    end
  end

  private

  def build_download(user:, selected_items:, container_id:, activity_log_type:, activity_log_id:, multi:)
    items = normalize_items(selected_items)
    if multi
      container_ids = items.pluck(:container_id).uniq
      download = NfsStore::Download.new(multiple_items: true, container_ids:)
    else
      container = NfsStore::Browse.open_container(id: container_id, user:)
      activity_log = open_activity_log(activity_log_type, activity_log_id, user)
      download = NfsStore::Download.new(container:, activity_log:, multiple_items: true)
    end
    download.current_user = user
    download
  end

  def open_activity_log(resource_name, id, user)
    return unless resource_name.present? && id.present?

    if resource_name.start_with?('activity_log_')
      ActivityLog.open_activity_log(resource_name, id, user)
    else
      klass = Settings.filestore_admin_class_for(resource_name)
      raise FsException::Download, 'Invalid file store resource' unless klass

      item = klass.find(id)
      item.current_user = user
      item
    end
  end

  def normalize_items(selected_items)
    Array(selected_items).map do |item|
      item = item.stringify_keys
      { id: item['id'].to_i,
        container_id: item['container_id'].to_i,
        retrieval_type: NfsStore::Download.validated_retrieval_type!(item['retrieval_type']),
        activity_log_type: item['activity_log_type'],
        activity_log_id: item['activity_log_id'].to_i }
    end
  end

  def download_link(token, app_type_id)
    "#{Settings::BaseUrl}/nfs_store/downloads/prepared/#{token}?use_app_type=#{app_type_id}&no_redirect=true"
  end

  def notify_user(user, state, substitutions = {})
    defaults = self.class.notification_defaults.fetch(state)
    notification = Messaging::MessageNotification.create!(user:, recipient_user_ids: [user.id],
                                                          layout_template_name: defaults[:layout],
                                                          content_template_name: defaults[:content],
                                                          message_type: :email, subject: defaults[:subject],
                                                          item: user, from_user_email: Settings::NotificationsFromEmail,
                                                          extra_substitutions_data: substitutions)
    notification.handle_notification_now logger: Delayed::Worker.logger
  end
end
