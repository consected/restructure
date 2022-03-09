class AddCreatedByUserToMasters < ActiveRecord::Migration[5.2]
  def change
    add_reference :masters, :created_by_user, foreign_key: { to_table: 'users' }
  end
end
