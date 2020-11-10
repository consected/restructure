class AddAdminFieldsToUsersContactInfo < ActiveRecord::Migration
  def change
    add_reference :users_contact_infos, :admin, index: true, foreign_key: true
    add_column :users_contact_infos, :disabled, :boolean
  end
end
