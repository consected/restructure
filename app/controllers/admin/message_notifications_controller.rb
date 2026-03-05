class Admin::MessageNotificationsController < AdminController
  #
  # Download a generated attachment (e.g. calendar .ics file) from a message notification.
  # The attachment content is stored in extra_substitutions YAML column.
  def attachment
    mn = Messaging::MessageNotification.find(params[:id])
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
