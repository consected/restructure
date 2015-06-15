class RenameTypeToRecTypeForTables < ActiveRecord::Migration
  def change
    rename_column :addresses, :type, :rec_type
    rename_column :player_contacts, :type, :rec_type
    
  end
end
