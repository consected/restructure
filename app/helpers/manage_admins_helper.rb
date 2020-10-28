module ManageAdminsHelper
  def admin_path admin
    manage_admin_path(admin)
  end

  def admins_path
    manage_admins_path
  end
end
