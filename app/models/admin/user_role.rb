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

  def self.user_ids
    select("user_id").distinct.pluck(:user_id)
  end

end
