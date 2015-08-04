class RemoveProInfoFromPlayerInfo < ActiveRecord::Migration
  def change    
      remove_reference :player_infos, :pro_info, index: true, foreign_key: true
  end
end
