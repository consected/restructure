class AddIndexesToMaster < ActiveRecord::Migration
  def change
    
    execute "ALTER TABLE masters RENAME column proid TO pro_id;"
    
    add_index :masters, :msid
    add_index :masters, :pro_id
    add_index :masters, :pro_info_id
    add_foreign_key :masters, :pro_infos

    #### DO NOT ADD MSID sequence, since we do not always want an MSID assigned 
    # For example, inserts during initial migration will not have an MSID if there is pro info not matched to player info
    # Inserts performed outside Rails subsequently are the responsibility of the DBA to decide whether an MSID should be assigned 
    # 
    # The following migration code is retained in case we change this requirement before releasing the application to production
    # 
#    execute "CREATE SEQUENCE msid_seq;"
#    execute "ALTER TABLE masters ALTER msid SET DEFAULT NEXTVAL('msid_seq');  "
#    
#    # Based on http://stackoverflow.com/questions/244243/how-to-reset-postgres-primary-key-sequence-when-it-falls-out-of-sync
#    # set the sequence to the max value for MSID
#    if Masters.length > 0
#      execute "SELECT setval('msid_seq', (SELECT MAX(msid) FROM masters));"
#    else
#      execute "SELECT setval('msid_seq', COALESCE((SELECT MAX(msid)+1 FROM masters), 1), false);"
#    end
    
    
  end
end
