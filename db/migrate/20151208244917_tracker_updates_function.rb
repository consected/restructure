class TrackerUpdatesFunction < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do

        execute <<EOF
      
  DROP FUNCTION IF EXISTS add_study_update_entry(master_id INTEGER, update_type VARCHAR, update_name VARCHAR, event_date DATE, update_notes VARCHAR, user_id INTEGER, item_id INTEGER, item_type VARCHAR);
  DROP FUNCTION IF EXISTS format_update_notes(field_name VARCHAR, old_val VARCHAR, new_val VARCHAR);


  CREATE FUNCTION format_update_notes(field_name VARCHAR, old_val VARCHAR, new_val VARCHAR) returns VARCHAR
    LANGUAGE plpgsql
    AS $$
        DECLARE
          res VARCHAR;
        BEGIN
          res := '';
          old_val := lower(coalesce(old_val, '-')::varchar);
          new_val := lower(coalesce(new_val, '')::varchar);
          IF old_val <> new_val THEN 
            res := field_name;
            IF old_val <> '-' THEN
              res := res || ' from ' || old_val ;
            END IF;
            res := res || ' to ' || new_val || '; ';
          END IF;
          RETURN res;
        END;
      $$;

  -- update_type: created | updated
  -- update_name: player info | address | player contact | sage assignment | scantron
  -- user_id: <users.id of user updating item>
  -- item_id: <ID of updated or created object> | NULL
  -- item_type: PlayerInfo | Address | PlayerContact | SageAssignment | Scantron | NULL



  CREATE FUNCTION add_study_update_entry(master_id INTEGER, update_type VARCHAR, update_name VARCHAR, event_date DATE, update_notes VARCHAR, user_id INTEGER, item_id INTEGER, item_type VARCHAR) RETURNS integer
    LANGUAGE plpgsql
    AS $$
        DECLARE
          new_tracker_id integer;
          protocol_record RECORD;
        BEGIN
        
          SELECT add_tracker_entry_by_name(master_id, 'Updates', 'record updates', (update_type || ' ' || update_name), event_date, update_notes, user_id, item_id, item_type) into new_tracker_id;
          /*
          SELECT p.id protocol_id, sp.id sub_process_id, pe.id protocol_event_id 
          INTO protocol_record           
          FROM protocol_events pe 
          INNER JOIN sub_processes sp on pe.sub_process_id = sp.id 
          INNER JOIN protocols p on sp.protocol_id = p.id
          WHERE p.name = 'Updates' 
          AND sp.name = 'record updates' 
          AND pe.name = (update_type || ' ' || update_name) 
          AND (p.disabled IS NULL or p.disabled = FALSE) AND (sp.disabled IS NULL or sp.disabled = FALSE) AND (pe.disabled IS NULL or pe.disabled = FALSE);

          IF NOT FOUND THEN
            RAISE EXCEPTION 'Nonexistent protocol record --> %', (update_type || ' ' || update_name );
          ELSE

            INSERT INTO trackers 
            (master_id, protocol_id, sub_process_id, protocol_event_id, item_type, item_id, user_id, event_date, updated_at, created_at, notes)
            VALUES
            (master_id, protocol_record.protocol_id, protocol_record.sub_process_id, protocol_record.protocol_event_id, 
             item_type, item_id, user_id, now(), now(), now(), update_notes);                        

            RETURN new_tracker_id;
          END IF;
          */  
          RETURN new_tracker_id;
        END;   
    $$;
    

EOF
        end
        dir.down do
execute <<EOF

  
  DROP FUNCTION IF EXISTS add_study_update_entry(master_id INTEGER, update_type VARCHAR, update_name VARCHAR, event_date DATE, update_notes VARCHAR, user_id INTEGER, item_id INTEGER, item_type VARCHAR);
  DROP FUNCTION IF EXISTS format_update_notes(field_name VARCHAR, old_val VARCHAR, new_val VARCHAR);

EOF
      end
    end
  end
end
