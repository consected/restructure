class AddRankToMaster < ActiveRecord::Migration
  def change
    add_column :masters, :rank, :integer
    
    
    execute "CREATE OR REPLACE FUNCTION update_master_with_player_info() RETURNS TRIGGER AS $master_update$
    BEGIN
        UPDATE masters 
            set rank = (
            case when NEW.rank is null then -1000 
                 when (NEW.rank > 12) then NEW.rank * -1 
                 else new.rank
            end
            )

        WHERE masters.id = NEW.master_id;

        RETURN NEW;
    END;
    $master_update$ LANGUAGE plpgsql;"

    #execute "DROP TRIGGER player_info_update ON player_infos;"

    execute "CREATE TRIGGER player_info_update
        AFTER UPDATE ON player_infos
        FOR EACH ROW
        WHEN (OLD.* IS DISTINCT FROM NEW.*)
        EXECUTE PROCEDURE update_master_with_player_info();"

    #execute "DROP TRIGGER player_info_insert ON player_infos;"
    
    execute "CREATE TRIGGER player_info_insert
        AFTER INSERT ON player_infos
        FOR EACH ROW
        EXECUTE PROCEDURE update_master_with_player_info();"



  end
end
