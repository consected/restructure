class RemoveActiveFromPlayerContact < ActiveRecord::Migration
  def change
    remove_column :player_contacts, :active, :boolean
  end
end
