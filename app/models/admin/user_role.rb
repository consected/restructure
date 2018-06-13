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

end
