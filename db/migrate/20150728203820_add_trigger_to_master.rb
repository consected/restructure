class AddTriggerToMaster < ActiveRecord::Migration
  def change
    
    execute "CREATE OR REPLACE FUNCTION update_master_with_pro_info() RETURNS TRIGGER AS $master_update$
    BEGIN
        UPDATE masters 
            set pro_info_id = NEW.id, pro_id = NEW.pro_id             
        WHERE masters.id = NEW.master_id;

        RETURN NEW;
    END;
    $master_update$ LANGUAGE plpgsql;"

 #   execute "DROP TRIGGER pro_info_update ON pro_infos;"

    execute "CREATE TRIGGER pro_info_update
        AFTER UPDATE ON pro_infos
        FOR EACH ROW
        WHEN (OLD.* IS DISTINCT FROM NEW.*)
        EXECUTE PROCEDURE update_master_with_pro_info();"

   # execute "DROP TRIGGER pro_info_insert ON pro_infos;"
    
    execute "CREATE TRIGGER pro_info_insert
        AFTER INSERT ON pro_infos
        FOR EACH ROW
        EXECUTE PROCEDURE update_master_with_pro_info();"



    
  end
end
