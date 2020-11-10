class AddIndexesToMaster < ActiveRecord::Migration
  def change
    
    #execute "ALTER TABLE masters RENAME column proid TO pro_id;"
    
    add_index :masters, :msid
    add_index :masters, :pro_id
    add_index :masters, :pro_info_id
    add_foreign_key :masters, :pro_infos

    #### DO NOT ADD MSID sequence, since we do not always want an MSID assigned 
    # For example, inserts during initial migration will not have an MSID if there is pro info not matched to player info
    # Inserts performed outside Rails subsequently are the responsibility of the DBA to decide whether an MSID should be assigned 
    # 
    
    
  end
end
