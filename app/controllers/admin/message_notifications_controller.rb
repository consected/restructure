class Admin::MessageNotificationsController < AdminController
  #
  # Download a generated attachment (e.g. calendar .ics file or NfsStore file) from a message notification.
  # Calendar invite content is stored in extra_substitutions YAML column.
  # NfsStore attachments redirect to the NfsStore download path by stored_file_id.
  def attachment
    mn = Messaging::MessageNotification.find(params[:id])

    # Handle NfsStore file attachment download by stored_file_id
    if params[:stored_file_id].present?
      stored_file_id = params[:stored_file_id].to_i
      redirect_to nfs_store_download_path(stored_file_id)
      return
    end

    # Handle calendar invite attachment download
    ci_data = mn.calendar_invite_data

    if ci_data&.dig('generated_content').present?
      send_data ci_data['generated_content'],
                filename: 'calendar.ics',
                type: 'text/calendar',
                disposition: 'attachment'
    else
      head :not_found
    end
  end

  protected

  def view_folder; end

  def filters
    {
      # message_type: ['email'],
      app_type_id: Admin::AppType.all_by_name,
      status: ['IS NULL', Messaging::MessageNotification::StatusInProgress,
               Messaging::MessageNotification::StatusFailed, Messaging::MessageNotification::StatusComplete]
    }
  end

  def filters_on
    %i[app_type_id status]
  end

  def default_index_order
    { created_at: :desc }
  end

  def no_edit
    true
  end

  private

  def permitted_params
    %i[id app_type_id master_id user_id item_id message_type recipient_user_ids layout_template_name
       content_template_name subject data recipient_emails recipient_sms_numbers from_user_email generate_view status created_at updated_at]
  end
end
