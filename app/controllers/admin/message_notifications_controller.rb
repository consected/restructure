class Admin::MessageNotificationsController < AdminController


  protected

    def view_folder

    end

    def filters
      {
        # message_type: ['email'],
        app_type_id: Admin::AppType.all_by_name,
        status: ['IS NULL', Messaging::MessageNotification::StatusInProgress, Messaging::MessageNotification::StatusFailed, Messaging::MessageNotification::StatusComplete]
      }
    end

    def filters_on
      [:app_type_id, :status]
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
