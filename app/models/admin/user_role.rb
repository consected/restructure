class Admin::UserRole < ActiveRecord::Base

  self.table_name = 'user_roles'

  include AdminHandler
  include AppTyped

  belongs_to :user

  validates :role_name, presence: true
  validates :user_id, uniqueness: {scope: [:app_type_id, :role_name]}

  def self.role_names
    select("role_name").distinct.pluck(:role_name)
  end

  def self.role_names_for app_type: nil
    active.where(app_type: app_type).role_names
  end

  def self.users
    user_ids = select("user_id").distinct.pluck(:user_id)
    User.where id: user_ids
  end

  # conditions may include app_type and role_name
  def self.active_user_ids conditions
    res = select("user_id").joins(:user).where(
      "(user_roles.disabled is null or user_roles.disabled = false) AND (users.disabled is null or users.disabled = false)"
    )

    res = res.where conditions if conditions

    res.distinct.pluck(:user_id)
  end

  def self.find_user_role_for_user user, app_type, role_name
    user.user_roles.where(app_type: app_type, role_name: role_name).first
  end

  def self.add_to_role user, app_type, role_name, admin
    res = find_user_role_for_user user, app_type, role_name
    if res
      res.with_admin(admin).enable! if res if res.disabled?
    else
      user.user_roles.create!(app_type: app_type, role_name: role_name, disabled: false, current_admin: admin)
    end
  end

  def self.remove_from_role user, app_type, role_name, admin
    res = find_user_role_for_user user, app_type, role_name
    res.with_admin(admin).disable! if res
  end

end
