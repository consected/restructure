class Users::ContactInfosController < AdminController
  helper_method :permitted_params, :objects_instance, :human_name

  protected

  def no_create
    !req_user
  end

  def req_user
    User.find(params[:filter][:user_id])
  rescue StandardError
    nil
  end

  def view_folder
    'admin/common_templates'
  end

  def permitted_params
    @permitted_params = %i[user_id sms_number phone_number alt_email]
  end

  def admin_links(item = nil)
    return [true] if item.nil?

    [
      ['user profile', admin_manage_users_path(filter: { id: item.user_id })]
    ]
  end
end
