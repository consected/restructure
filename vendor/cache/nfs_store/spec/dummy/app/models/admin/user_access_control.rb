class Admin::UserAccessControl < ApplicationRecord

  self.table_name = 'user_access_controls'


  def self.access_for? user, can_perform, on_resource_type, named, alt_app_type_id: nil, alt_role_name: nil, add_conditions: nil

    if user.id == 1
      return true
    end

  end

end
