class TrackerHistoryUpdateTrigger < ActiveRecord::Migration
  def change
reversible do |dir|
      dir.up do
execute <<EOF

  
  DROP TRIGGER IF EXISTS tracker_history_update on tracker_history;
  
  
  DROP FUNCTION IF EXISTS handle_tracker_history_update();
  CREATE FUNCTION handle_tracker_history_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      
      DELETE FROM tracker_history WHERE id = OLD.id;
  
      INSERT INTO trackers 
        (master_id, protocol_id, 
         protocol_event_id, event_date, sub_process_id, notes,
         item_id, item_type,
         created_at, updated_at, user_id)

        SELECT NEW.master_id, NEW.protocol_id, 
           NEW.protocol_event_id, NEW.event_date, 
           NEW.sub_process_id, NEW.notes, 
           NEW.item_id, NEW.item_type,
           NEW.created_at, NEW.updated_at, NEW.user_id  ;

      RETURN NULL;
    END;
    $$;
  
  CREATE TRIGGER tracker_history_update BEFORE UPDATE ON tracker_history FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_tracker_history_update();
  


EOF
      end
      dir.down do
execute <<EOF

  
  DROP TRIGGER IF EXISTS tracker_history_update on tracker_history;
  
  DROP FUNCTION IF EXISTS handle_tracker_history_update();
EOF
      end
    end
  end
end
