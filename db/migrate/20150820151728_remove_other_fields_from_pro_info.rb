class RemoveOtherFieldsFromProInfo < ActiveRecord::Migration
  def change    
    remove_column :pro_infos, :accrued_seasons, :integer
    remove_column :pro_infos, :first_contract, :integer
    remove_column :pro_infos, :second_contract, :integer
    remove_column :pro_infos, :third_contract, :integer
    remove_column :pro_infos, :career_info, :integer
  end
end
