class TrackersUniqueConstraints < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
execute <<EOF  


  ALTER TABLE trackers DROP CONSTRAINT IF EXISTS valid_protocol_sub_process;
  ALTER TABLE tracker_history DROP CONSTRAINT IF EXISTS valid_protocol_sub_process;
  ALTER TABLE sub_processes DROP CONSTRAINT IF EXISTS unique_protocol_and_id;


  ALTER TABLE tracker_history DROP CONSTRAINT IF EXISTS valid_sub_process_event;
  ALTER TABLE trackers DROP CONSTRAINT IF EXISTS valid_sub_process_event;
  ALTER TABLE protocol_events DROP CONSTRAINT IF EXISTS unique_sub_process_and_id;  

  ALTER TABLE tracker_history DROP CONSTRAINT IF EXISTS unique_master_protocol_tracker_id;
  ALTER TABLE trackers DROP CONSTRAINT IF EXISTS unique_master_protocol_id;
  ALTER TABLE trackers DROP CONSTRAINT IF EXISTS unique_master_protocol;


  -- May wish to validate that this will work with:
  -- select  master_id, protocol_id  from trackers group by master_id, protocol_id having count(*) > 1;
  -- select count(distinct(master_id, protocol_id)) c, tracker_id from tracker_history group by tracker_id having count(distinct(master_id, protocol_id)) > 1;

  
  ALTER TABLE trackers ADD CONSTRAINT unique_master_protocol UNIQUE (master_id, protocol_id);
  ALTER TABLE trackers ADD CONSTRAINT unique_master_protocol_id UNIQUE (master_id, protocol_id, id);

  
  ALTER TABLE tracker_history ADD CONSTRAINT unique_master_protocol_tracker_id  FOREIGN KEY (master_id, protocol_id, tracker_id) REFERENCES trackers (master_id, protocol_id, id);


  -- Check that a valid set of protocol_id and sub_process_id are used. We use MATCH FULL in the foreign key constraint,
  -- since this ensures that the validation is not ignored if a null is provided for either of the affected fields.
  -- Validate this first with:
  -- select id from trackers t where not exists (select * from sub_processes where t.protocol_id = protocol_id and t.sub_process_id = id);
  -- select id from tracker_history t where not exists (select * from sub_processes where t.protocol_id = protocol_id and t.sub_process_id = id);

  
  ALTER TABLE sub_processes ADD CONSTRAINT unique_protocol_and_id UNIQUE (protocol_id, id);
  ALTER TABLE trackers ADD CONSTRAINT valid_protocol_sub_process FOREIGN KEY (protocol_id, sub_process_id) REFERENCES sub_processes (protocol_id, id) MATCH FULL;

  ALTER TABLE tracker_history ADD CONSTRAINT valid_protocol_sub_process FOREIGN KEY (protocol_id, sub_process_id) REFERENCES sub_processes (protocol_id, id) MATCH FULL;

  -- Note that the protocol_events foreign key relies on MATCH SIMPLE, which will allow the constraint to be ignored if any
  -- field (sub process or protocol event) is NULL. It is valid for protocol_event_id to be NULL, but not sub_process_id. 
  -- Fortunately, the simple foreign key constraints referencing the tables
  -- protocols, sub_processes and protocol_events individually handle this if we also add not null constraints to the 
  -- protocol_id and sub_process_id fields, especially in combination with the MATCH FULL constraint added above.

  -- Validate this with:
  -- select id from trackers t where not exists (select * from protocol_events where t.sub_process_id = sub_process_id and t.protocol_event_id = id);
  -- select id from tracker_history t where not exists (select * from protocol_events where t.sub_process_id = sub_process_id and t.protocol_event_id = id);

  ALTER TABLE trackers ALTER COLUMN protocol_id set not null;
  ALTER TABLE trackers ALTER COLUMN sub_process_id set not null;


  ALTER TABLE protocol_events ADD CONSTRAINT unique_sub_process_and_id UNIQUE (sub_process_id, id);
  ALTER TABLE trackers ADD CONSTRAINT valid_sub_process_event FOREIGN KEY (sub_process_id, protocol_event_id) REFERENCES protocol_events (sub_process_id, id);


  ALTER TABLE tracker_history ADD CONSTRAINT valid_sub_process_event FOREIGN KEY (sub_process_id, protocol_event_id) REFERENCES protocol_events (sub_process_id, id);


EOF
      end
      dir.down do
execute <<EOF  
  ALTER TABLE trackers DROP CONSTRAINT IF EXISTS valid_protocol_sub_process;
  ALTER TABLE tracker_history DROP CONSTRAINT IF EXISTS valid_protocol_sub_process;
  ALTER TABLE sub_processes DROP CONSTRAINT IF EXISTS unique_protocol_and_id;


  ALTER TABLE tracker_history DROP CONSTRAINT IF EXISTS valid_sub_process_event;
  ALTER TABLE trackers DROP CONSTRAINT IF EXISTS valid_sub_process_event;
  ALTER TABLE protocol_events DROP CONSTRAINT IF EXISTS unique_sub_process_and_id;  

  ALTER TABLE tracker_history DROP CONSTRAINT IF EXISTS unique_master_protocol_tracker_id;
  ALTER TABLE trackers DROP CONSTRAINT IF EXISTS unique_master_protocol_id;
  ALTER TABLE trackers DROP CONSTRAINT IF EXISTS unique_master_protocol;
  

EOF
      end      
    end
  end
end
