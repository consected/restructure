class DataDowncasePlayerContact < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do
# Enhance the trackers trigger writing to tracker_history for insert and update
execute <<EOF
    
  DROP TRIGGER IF EXISTS player_contact_update on player_contacts;
  DROP TRIGGER IF EXISTS player_contact_insert on player_contacts;
  DROP FUNCTION IF EXISTS handle_player_contact_update();
  CREATE FUNCTION handle_player_contact_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
         

          NEW.rec_type := lower(NEW.rec_type);
          NEW.data := lower(NEW.data);
          NEW.source := lower(NEW.source);


          RETURN NEW;
            
        END;   
    $$;
    
    CREATE TRIGGER player_contact_update BEFORE UPDATE ON player_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_player_contact_update();
    CREATE TRIGGER player_contact_insert BEFORE INSERT ON player_contacts FOR EACH ROW EXECUTE PROCEDURE handle_player_contact_update();



  DROP FUNCTION IF EXISTS update_player_contact_ranks(set_master_id INTEGER, set_rec_type VARCHAR);
  CREATE FUNCTION update_player_contact_ranks(set_master_id INTEGER, set_rec_type VARCHAR) RETURNS INTEGER
    LANGUAGE plpgsql
    AS $$
        DECLARE
          latest_primary RECORD;
        BEGIN
  
          SELECT * into latest_primary 
          FROM player_contacts
          WHERE master_id = set_master_id
          AND rank = 10
          AND rec_type = set_rec_type
          ORDER BY updated_at DESC
          LIMIT 1;
        
          IF NOT FOUND THEN
            RETURN NULL;
          END IF;

          
          UPDATE player_contacts SET rank = 5 
          WHERE 
            master_id = set_master_id 
            AND rank = 10
            AND rec_type = set_rec_type
            AND id <> latest_primary.id;
          

          RETURN 1;
        END;
    $$;

EOF
        end
        dir.down do
execute <<EOF

  
  DROP TRIGGER IF EXISTS player_contact_update on player_contacts;
  DROP TRIGGER IF EXISTS player_contact_insert on player_contacts;
  DROP FUNCTION IF EXISTS handle_player_contact_update();

  DROP FUNCTION IF EXISTS update_player_contact_ranks(set_master_id INTEGER, set_rec_type VARCHAR);
EOF
      end
    end
  end
end
