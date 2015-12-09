class RcCisTrigger < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do
# Enhance the trackers trigger writing to tracker_history for insert and update
execute <<EOF
    
  DROP TRIGGER IF EXISTS rc_cis_update on rc_cis;
  DROP FUNCTION IF EXISTS handle_rc_cis_update();
  CREATE FUNCTION handle_rc_cis_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
          new_master_id integer;
          new_msid integer;
          updated_item_id integer;
        BEGIN

          IF coalesce(NEW.status,'') <> '' THEN

            IF NEW.status = 'create master' THEN

                IF NEW.master_id IS NOT NULL THEN
                  RAISE EXCEPTION 'Can not create a master when the master ID is already set. Review the linked Master record, or to create a new Master record clear the master_id first and try again.';
                END IF;


                SELECT MAX(msid) + 1 INTO new_msid FROM masters;
                
                INSERT INTO masters
                  (msid, created_at, updated_at, user_id)
                  VALUES 
                  (new_msid, now(), now(), NEW.user_id)
                  RETURNING id INTO new_master_id;

                INSERT INTO player_infos
                  (master_id, first_name, last_name, source, created_at, updated_at, user_id)
                  VALUES
                  (new_master_id, NEW.fname, NEW.lname, 'cis-redcap', now(), now(), NEW.user_id);
            ELSE              
                SELECT id INTO new_master_id FROM masters WHERE id = NEW.master_id;
            END IF;
  
            IF NEW.status = 'update name' OR NEW.status = 'update all' THEN  
                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;


                UPDATE player_infos SET
                  master_id = new_master_id, first_name = NEW.fname, last_name = NEW.lname, 
                  source = 'cis-redcap', created_at = now(), updated_at = now(), user_id = NEW.user_id
                  WHERE master_id = new_master_id
                  RETURNING id INTO updated_item_id;

                PERFORM add_study_update_entry(new_master_id, 'updated', 'player info', '', NEW.user_id, updated_item_id, 'PlayerInfo');

            END IF;

            IF NEW.status = 'update address' OR NEW.status = 'update all' OR NEW.status = 'create master' THEN  
                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;

                IF NEW.street IS NOT NULL AND trim(NEW.street) <> '' OR
                    NEW.state IS NOT NULL AND trim(NEW.state) <> '' OR
                    NEW.zip IS NOT NULL AND trim(NEW.zip) <> '' THEN   
                  
                  INSERT INTO addresses
                    (master_id, street, street2, city, state, zip, source, rank, created_at, updated_at, user_id)
                    VALUES
                    (new_master_id, NEW.street, NEW.street2, NEW.city, NEW.state, NEW.zip, 'cis-redcap', 10, now(), now(), NEW.user_id);
                  
                  PERFORM update_address_ranks(new_master_id);
                END IF;
            END IF;

            IF NEW.status = 'update email' OR NEW.status = 'update all' OR NEW.status = 'create master' THEN  

                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;

                IF NEW.email IS NOT NULL AND trim(NEW.email) <> '' THEN   
                  INSERT INTO player_contacts
                    (master_id, data, rec_type, source, rank, created_at, updated_at, user_id)
                    VALUES
                    (new_master_id, NEW.email, 'email', 'cis-redcap', 10, now(), now(), NEW.user_id);


                  PERFORM update_player_contact_ranks(new_master_id, 'email');
                END IF;                
            END IF;

            IF NEW.status = 'update phone' OR NEW.status = 'update all' OR NEW.status = 'create master' THEN  
                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;

                IF NEW.phone IS NOT NULL AND trim(NEW.phone) <> '' THEN   
                  INSERT INTO player_contacts
                    (master_id, data, rec_type, source, rank, created_at, updated_at, user_id)
                    VALUES
                    (new_master_id, NEW.phone, 'phone', 'cis-redcap', 10, now(), now(), NEW.user_id);

                    PERFORM update_player_contact_ranks(new_master_id, 'phone');
                END IF;
            END IF;
            
            NEW.master_id := new_master_id;


          END IF;

          RETURN NEW;
            
        END;   
    $$;
    
    CREATE TRIGGER rc_cis_update BEFORE UPDATE ON rc_cis FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_rc_cis_update();

EOF
        end
        dir.down do
execute <<EOF

  
  DROP TRIGGER IF EXISTS rc_cis_update on rc_cis;
  DROP FUNCTION IF EXISTS handle_rc_cis_update();

EOF
      end
    end
  end
end
