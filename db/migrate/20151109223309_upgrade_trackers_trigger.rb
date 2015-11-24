class UpgradeTrackersTrigger < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do
# Enhance the trackers trigger writing to tracker_history for insert and update
execute <<EOF
  
  DROP TRIGGER IF EXISTS tracker_history_insert on trackers;
  DROP TRIGGER IF EXISTS tracker_history_update on trackers;
  DROP FUNCTION IF EXISTS log_tracker_update();
  CREATE FUNCTION log_tracker_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN

          -- Check to see if there is an existing record in tracker_history that matches the 
          -- that inserted or updated in trackers.
          -- If there is, just skip the insert into tracker_history, otherwise make the insert happen.

          PERFORM * from tracker_history 
            WHERE
              master_id = NEW.master_id 
              AND protocol_id = NEW.protocol_id
              AND coalesce(protocol_event_id,-1) = coalesce(NEW.protocol_event_id,-1)
              AND event_date = NEW.event_date
              AND sub_process_id = NEW.sub_process_id
              AND coalesce(notes,'') = coalesce(NEW.notes,'')
              AND coalesce(item_id,-1) = coalesce(NEW.item_id,-1)
              AND coalesce(item_type,'') = coalesce(NEW.item_type,'')
              -- do not check created_at --
              AND updated_at = NEW.updated_at
              AND coalesce(user_id,-1) = coalesce(NEW.user_id,-1);

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
        end
        dir.down do
execute <<EOF

  
  DROP TRIGGER IF EXISTS tracker_history_insert on trackers;
  DROP TRIGGER IF EXISTS tracker_history_update on trackers;
  DROP FUNCTION IF EXISTS log_tracker_update();
EOF
      end
    end
  end
end
