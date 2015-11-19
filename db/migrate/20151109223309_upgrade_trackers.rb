class UpgradeTrackers < ActiveRecord::Migration
  def change

# Enhance the trackers trigger writing to tracker_history for insert and update
execute <<EOF
  
  DROP TRIGGER tracker_history_insert on trackers;
  DROP TRIGGER tracker_history_update on trackers;
  DROP FUNCTION log_tracker_update();
  CREATE FUNCTION log_tracker_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN

          PERFORM * from tracker_history 
            WHERE
              master_id = NEW.master_id 
              AND protocol_id = NEW.protocol_id
              AND protocol_event_id = NEW.protocol_event_id
              AND event_date = NEW.event_date
              AND sub_process_id = NEW.sub_process_id
              AND notes = NEW.notes
              AND item_id = NEW.item_id
              AND item_type = NEW.item_type
              -- do not check created_at --
              AND updated_at = NEW.updated_at
              AND user_id = NEW.user_id;

            IF NOT FOUND THEN
              INSERT INTO tracker_history 
                  (tracker_id, master_id, protocol_id, 
                   protocol_event_id, event_date, sub_process_id, notes,
                   item_id, item_type,
                   created_at, updated_at, user_id)

                  SELECT NEW.id, NEW.master_id, NEW.protocol_id, 
                     NEW.protocol_event_id, NEW.event_date, 
                     NEW.sub_process_id, NEW.notes, 
                     NEW.item_id, NEW.item_type,
                     NEW.created_at, NEW.updated_at, NEW.user_id  ;
            END IF;

            RETURN NEW;
            
        END;   
    $$;

    CREATE TRIGGER tracker_history_insert AFTER INSERT ON trackers FOR EACH ROW EXECUTE PROCEDURE log_tracker_update();
    CREATE TRIGGER tracker_history_update AFTER UPDATE ON trackers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_tracker_update();

EOF

# Improve the tracker upsert trigger to ensure the update does not happen if the event date and update date are earlier than the current record

    
    
    
    # Create a trigger on delete to keep tracker_history and trackers in sync
    
    execute <<EOF


CREATE FUNCTION tracker_history_delete() RETURNS trigger
  LANGUAGE plpgsql
  AS $$
    DECLARE
      latest_tracker RECORD;
    BEGIN
     
      SELECT ... INTO latest_tracker ...
    

IF NOT FOUND THEN

 RETURN OLD;
 END;
$$;

-- For every row that is deleted by the statement, call the function
CREATE TRIGGER handle_delete AFTER DELETE
    ON ml_app.tracker_history
    FOR EACH ROW 
    EXECUTE PROCEDURE tracker_history_delete();


-- reset the foreign keys pointing to tracker.
-- handle the inserts into tracker
-- update the trackers upsert trigger 

-- also need constraints

EOF
  end
end
