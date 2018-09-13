class Admin::UserRole < ApplicationRecord
  self.table_name = 'user_roles'

  belongs_to :user
  scope :active, -> {  }
  def self.role_names
    select("role_name").distinct.pluck(:role_name)
  end

end
