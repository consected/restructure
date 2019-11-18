class Users::ContactInfosController < AdminController

  helper_method :permitted_params, :objects_instance, :human_name


  protected

    def view_folder
      'admin/common_templates'
    end

    def filters
      {user_id: Admin::UserRole.active.users.pluck(:id, :email).to_h}
    end

    def filters_on
      [:user_id]
    end


    def permitted_params
      @permitted_params = [:user_id, :sms_number, :phone_number, :alt_email]
    end

end
