class RemoveColsFromPlayerInfo < ActiveRecord::Migration
  def change
    remove_column :player_infos, :occupation_category, :string
    remove_column :player_infos, :company, :string
    remove_column :player_infos, :company_description, :string
    remove_column :player_infos, :transaction_status, :string
    remove_column :player_infos, :transaction_substatus, :string
    
  end
end
