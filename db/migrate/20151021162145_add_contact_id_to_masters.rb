class AddContactIdToMasters < ActiveRecord::Migration
  def change
    add_column :masters, :contact_id, :integer
  end
end
