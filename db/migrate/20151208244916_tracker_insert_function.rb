class TrackerInsertFunction < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do

execute <<EOF
      
  DROP FUNCTION IF EXISTS add_tracker_entry_by_name(master_id INTEGER, protocol_name VARCHAR, sub_process_name VARCHAR, protocol_event_name VARCHAR, event_date DATE, set_notes VARCHAR, user_id INTEGER, item_id INTEGER, item_type VARCHAR);

  -- user_id: <users.id of user updating item>
  -- item_id: <ID of updated or created object> | NULL
  -- item_type: PlayerInfo | Address | PlayerContact | SageAssignment | Scantron | NULL

  CREATE FUNCTION add_tracker_entry_by_name(master_id INTEGER, protocol_name VARCHAR, sub_process_name VARCHAR, protocol_event_name VARCHAR, event_date DATE, set_notes VARCHAR, user_id INTEGER, item_id INTEGER, item_type VARCHAR) RETURNS integer
    LANGUAGE plpgsql
    AS $$
        DECLARE
          new_tracker_id integer;
          protocol_record RECORD;
        BEGIN

          
          SELECT p.id protocol_id, sp.id sub_process_id, pe.id protocol_event_id 
          INTO protocol_record           
          FROM protocol_events pe 
          INNER JOIN sub_processes sp on pe.sub_process_id = sp.id 
          INNER JOIN protocols p on sp.protocol_id = p.id
          WHERE p.name = protocol_name
          AND sp.name = sub_process_name 
          AND pe.name = protocol_event_name
          AND (p.disabled IS NULL or p.disabled = FALSE) AND (sp.disabled IS NULL or sp.disabled = FALSE) AND (pe.disabled IS NULL or pe.disabled = FALSE);

          IF NOT FOUND THEN
            RAISE EXCEPTION 'Nonexistent protocol record --> %', (protocol_name || ' ' || sub_process_name || ' ' || protocol_event_name);
          ELSE

            INSERT INTO trackers 
            (master_id, protocol_id, sub_process_id, protocol_event_id, item_type, item_id, user_id, event_date, updated_at, created_at, notes)
            VALUES
            (master_id, protocol_record.protocol_id, protocol_record.sub_process_id, protocol_record.protocol_event_id, 
             item_type, item_id, user_id, now(), now(), now(), set_notes);                        

            RETURN new_tracker_id;
          END IF;
            
        END;   
    $$;
    

EOF
        end
        dir.down do
execute <<EOF

  
  DROP FUNCTION IF EXISTS add_tracker_entry_by_name(master_id INTEGER, protocol_name VARCHAR, sub_process_name VARCHAR, protocol_event_name VARCHAR, event_date DATE, set_notes VARCHAR, user_id INTEGER, item_id INTEGER, item_type VARCHAR);

EOF
      end
    end
  end
end
