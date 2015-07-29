class AddMsidProToMaster < ActiveRecord::Migration
  def change
    add_column :masters, :msid, :integer
    add_column :masters, :pro_id, :integer
    add_column :masters, :pro_info_id, :integer
    
    
    ProInfo.all.each do |p|
      m = p.master
      m.pro_id = p.pro_id
      m.pro_info_id = p.id
      
      if m.player_infos.length > 0
        m.msid = m.id
      end
      
      m.save
    end
    
  end
end
