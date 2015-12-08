class DataDowncasePlayerInfo < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do
# Enhance the trackers trigger writing to tracker_history for insert and update
execute <<EOF
    
  DROP TRIGGER IF EXISTS player_info_update on player_infos;
  DROP TRIGGER IF EXISTS player_info_insert on player_infos;
  DROP FUNCTION IF EXISTS handle_player_info_update();
  CREATE FUNCTION handle_player_info_update() RETURNS trigger
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
    
    CREATE TRIGGER player_info_update BEFORE UPDATE ON player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_player_info_update();
    CREATE TRIGGER player_info_insert BEFORE INSERT ON player_infos FOR EACH ROW EXECUTE PROCEDURE handle_player_info_update();

EOF
        end
        dir.down do
execute <<EOF

  
  DROP TRIGGER IF EXISTS player_info_update on player_infos;
  DROP TRIGGER IF EXISTS player_info_insert on player_infos;
  DROP FUNCTION IF EXISTS handle_player_info_update();

EOF
      end
    end
  end
end
