class Admin::MessageNotificationsController < AdminController


  protected

    def view_folder
      'admin/common_templates'
    end

    def filters
      {
        message_type: ['email'],
        status: ['IS NULL', Messaging::MessageNotification::StatusInProgress, Messaging::MessageNotification::StatusFailed, Messaging::MessageNotification::StatusComplete]
      }
    end

    def filters_on
      [:message_type, :status]
    end

    def default_index_order
      {created_at: :desc}
    end

    def no_edit
      true
    end


  private
    def permitted_params
      [:id, :app_type_id, :master_id, :user_id, :item_id, :message_type, :recipient_user_ids, :layout_template_name, :content_template_name, :subject, :data, :recipient_emails, :from_user_email, :generate_view, :status, :created_at, :updated_at]
    end

end
