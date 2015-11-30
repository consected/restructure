-- Script created @ 2015-11-30 17:37:28 -0500
set search_path=ml_app; 
 begin;  ;
  
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
              AND coalesce(event_date, '1900-01-01'::date)::date = coalesce(NEW.event_date, '1900-01-01')::date
              AND sub_process_id = NEW.sub_process_id
              AND coalesce(notes,'') = coalesce(NEW.notes,'')
              AND coalesce(item_id,-1) = coalesce(NEW.item_id,-1)
              AND coalesce(item_type,'') = coalesce(NEW.item_type,'')
              -- do not check created_at --
              AND updated_at::timestamp = NEW.updated_at::timestamp
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

;

  DROP TRIGGER IF EXISTS tracker_upsert on trackers;
  
  DROP FUNCTION IF EXISTS tracker_upsert();
  CREATE FUNCTION tracker_upsert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
        latest_tracker trackers%ROWTYPE;
      BEGIN

        

        -- Look for a row in trackers for the inserted master / protocol pair
        SELECT * into latest_tracker 
          FROM trackers 
          WHERE
            master_id = NEW.master_id 
            AND protocol_id = NEW.protocol_id              
          ORDER BY
            event_date DESC NULLS LAST, updated_at DESC NULLS LAST
          LIMIT 1
        ;

        IF NOT FOUND THEN
          -- Nothing was found, so just allow the insert to continue
          
          RETURN NEW;

        ELSE   
          -- A trackers row for the master / protocol pair was found.
          -- Check if it is more recent, by having an event date either later than the insert, or 
          -- has an event_date the same as the insert but with later updated_at time (unlikely)

          IF latest_tracker.event_date > NEW.event_date OR 
              latest_tracker.event_date = NEW.event_date AND latest_tracker.updated_at > NEW.updated_at
              THEN

            -- The retrieved record was more recent, we should not make a change to the trackers table,
            -- but instead we need to ensure an insert into the tracker_history table does happen even though there
            -- is no actual insert or update trigger to fire.
            -- We use the trackers record ID that was retrieved as the tracker_id in tracker_history

            INSERT INTO tracker_history (
                tracker_id, master_id, protocol_id, 
                protocol_event_id, event_date, sub_process_id, notes,
                item_id, item_type,
                created_at, updated_at, user_id
              )                 
              SELECT 
                latest_tracker.id, NEW.master_id, NEW.protocol_id, 
                NEW.protocol_event_id, NEW.event_date, 
                NEW.sub_process_id, NEW.notes, 
                NEW.item_id, NEW.item_type,
                NEW.created_at, NEW.updated_at, NEW.user_id  ;
            
            RETURN NULL;

          ELSE
            -- The tracker record for the master / protocol pair exists and was not more recent, therefore it
            -- needs to be replaced by the intended NEW record. Complete with an update and allow the cascading 
            -- trackers update trigger to handle the insert into tracker_history.

            UPDATE trackers SET
              master_id = NEW.master_id, 
              protocol_id = NEW.protocol_id, 
              protocol_event_id = NEW.protocol_event_id, 
              event_date = NEW.event_date, 
              sub_process_id = NEW.sub_process_id, 
              notes = NEW.notes, 
              item_id = NEW.item_id, 
              item_type = NEW.item_type,
              -- do not update created_at --
              updated_at = NEW.updated_at, 
              user_id = NEW.user_id
            WHERE master_id = NEW.master_id AND 
              protocol_id = NEW.protocol_id
            ;

            -- Prevent the original insert from actually completing.
            RETURN NULL;
          END IF;
        END IF;      
      END;
    $$;


  CREATE TRIGGER tracker_upsert BEFORE INSERT ON trackers FOR EACH ROW EXECUTE PROCEDURE tracker_upsert();


;

  DROP TRIGGER IF EXISTS tracker_record_delete ON tracker_history; 
  DROP FUNCTION IF EXISTS handle_delete();
  
  CREATE FUNCTION handle_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
        latest_tracker tracker_history%ROWTYPE;
      BEGIN

        -- Find the most recent remaining item in tracker_history for the master/protocol pair,
        -- now that the target record has been deleted.
        -- tracker_id is the foreign key onto the trackers table master/protocol record.

        SELECT * INTO latest_tracker
          FROM tracker_history 
          WHERE tracker_id = OLD.tracker_id 
          ORDER BY event_date DESC NULLS last, updated_at DESC NULLS last LIMIT 1;

        IF NOT FOUND THEN
          -- No record was found in tracker_history for the master/protocol pair.
          -- Therefore there should be no corresponding trackers record either. Delete it.
          DELETE FROM trackers WHERE trackers.id = OLD.tracker_id;

        ELSE
          -- A record was found in tracker_history. Since it is the latest one for the master/protocol pair,
          -- just go ahead and update the corresponding record in trackers.
          UPDATE trackers 
            SET 
              event_date = latest_tracker.event_date, 
              sub_process_id = latest_tracker.sub_process_id, 
              protocol_event_id = latest_tracker.protocol_event_id, 
              item_id = latest_tracker.item_id, 
              item_type = latest_tracker.item_type, 
              updated_at = latest_tracker.updated_at, 
              notes = latest_tracker.notes, 
              user_id = latest_tracker.user_id
            WHERE trackers.id = OLD.tracker_id;

        END IF;


        RETURN OLD;

      END
    $$;
        



  -- For every row that is deleted, call the function
  CREATE TRIGGER tracker_record_delete AFTER DELETE ON tracker_history FOR EACH ROW EXECUTE PROCEDURE handle_delete();



;

  ALTER table trackers alter column user_id set default null;
  DROP FUNCTION IF EXISTS current_user_id();
  
  CREATE FUNCTION current_user_id() RETURNS integer
    LANGUAGE plpgsql
    AS $$
      DECLARE
        user_id integer;
      BEGIN
        user_id := (select id from users where email = current_user limit 1);

        return user_id;
      END;
    $$;


    ALTER table trackers alter column user_id set default current_user_id();
    
;

  
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
  


;


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


;


GRANT SELECT, INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ML_APP TO FPHSUSR;
GRANT SELECT,UPDATE,INSERT,DELETE ON ALL TABLES IN SCHEMA ML_APP TO FPHSADM;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ML_APP TO FPHSUSR;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ML_APP TO FPHSADM;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ML_APP TO FPHSUSR;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ML_APP TO FPHSADM;
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = UTF8;
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = ml_app, pg_catalog;
COPY schema_migrations (version) FROM stdin;
20151109223309
20151120150828
20151120151912
20151123203524
20151124151501
20151125192206
\.

 commit; ;
