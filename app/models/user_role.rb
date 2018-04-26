class UserRole < ActiveRecord::Base

  include AdminHandler

  belongs_to :app_type
  belongs_to :user
  belongs_to :admin

  validates :role_name, presence: true
  validates :user_id, uniqueness: {scope: [:app_type_id, :role_name]}

  def self.role_names
    select("role_name").distinct.pluck(:role_name)
  end

  def self.users
    user_ids = select("user_id").distinct.pluck(:user_id)
    User.where id: user_ids
  end


end
