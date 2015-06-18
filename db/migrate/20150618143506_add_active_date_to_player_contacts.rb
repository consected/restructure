class AddActiveDateToPlayerContacts < ActiveRecord::Migration
  def change
    add_column :player_contacts, :active_date, :date
  end
end
