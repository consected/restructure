class Admin::MessageNotificationsController < AdminController


  protected

    def view_folder
      'admin/common_templates'
    end

    def filters
      {
        message_type: ['email'],
        status: ['IS NULL', MessageNotification::StatusInProgress, MessageNotification::StatusFailed, MessageNotification::StatusComplete]
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

    def secure_params
      params.require(object_name.to_sym).permit(*permitted_params)
    end
end
