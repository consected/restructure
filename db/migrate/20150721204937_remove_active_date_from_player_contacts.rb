class RemoveActiveDateFromPlayerContacts < ActiveRecord::Migration
  def change
    remove_column :player_contacts, :active_date, :date
  end
end
