class ChangeDatesOnProInfos < ActiveRecord::Migration
  def change
    change_column :pro_infos, :birth_date,  'date USING CAST(birth_date AS date)'
    change_column :pro_infos, :death_date,  'date USING CAST(death_date AS date)'
  end
end
