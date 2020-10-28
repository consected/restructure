class DataDowncasePlayerInfo < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do
# Enhance the trackers trigger writing to tracker_history for insert and update
execute <<EOF
    
  DROP TRIGGER IF EXISTS player_info_before_update on player_infos;
  DROP TRIGGER IF EXISTS player_info_insert on player_infos;
  DROP FUNCTION IF EXISTS handle_player_info_before_update();
  CREATE FUNCTION handle_player_info_before_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          NEW.first_name := lower(NEW.first_name);          
          NEW.last_name := lower(NEW.last_name);          
          NEW.middle_name := lower(NEW.middle_name);          
          NEW.nick_name := lower(NEW.nick_name);          
          NEW.college := lower(NEW.college);                    
          NEW.source := lower(NEW.source);
          RETURN NEW;
            
        END;   
    $$;
    
    CREATE TRIGGER player_info_before_update BEFORE UPDATE ON player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_player_info_before_update();
    CREATE TRIGGER player_info_insert BEFORE INSERT ON player_infos FOR EACH ROW EXECUTE PROCEDURE handle_player_info_before_update();



    DROP TRIGGER IF EXISTS player_info_insert ON player_infos;
    DROP TRIGGER IF EXISTS player_info_update ON player_infos;

    CREATE OR REPLACE FUNCTION update_master_with_player_info() RETURNS TRIGGER AS $master_update$
      BEGIN
          UPDATE masters 
              set rank = (
              case when NEW.rank is null then null 
                   when (NEW.rank > 12) then NEW.rank * -1 
                   else new.rank
              end
              )

          WHERE masters.id = NEW.master_id;

          RETURN NEW;
      END;
      $master_update$ LANGUAGE plpgsql;

    

    CREATE TRIGGER player_info_update
        AFTER UPDATE ON player_infos
        FOR EACH ROW
        WHEN (OLD.* IS DISTINCT FROM NEW.*)
        EXECUTE PROCEDURE update_master_with_player_info();

    
    
    CREATE TRIGGER player_info_insert
        AFTER INSERT ON player_infos
        FOR EACH ROW
        EXECUTE PROCEDURE update_master_with_player_info();



EOF
        
        
        
        end
        dir.down do
execute <<EOF

  
  DROP TRIGGER IF EXISTS player_info_before_update on player_infos;
  DROP TRIGGER IF EXISTS player_info_insert on player_infos;
  DROP FUNCTION IF EXISTS handle_player_info_before_update();
  
  
  DROP TRIGGER IF EXISTS player_info_insert ON player_infos;
  DROP TRIGGER IF EXISTS player_info_update ON player_infos;
  DROP FUNCTION IF EXISTS handle_player_info_update();

EOF
      end
    end
  end
end
