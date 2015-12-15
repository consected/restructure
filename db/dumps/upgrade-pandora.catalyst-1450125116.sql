-- Script created @ 2015-12-14 15:38:57 -0500
set search_path=public; 
 begin;  ;

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
ALTER TABLE "reports" ADD "edit_model" character varying;
ALTER TABLE "reports" ADD "edit_field_names" character varying;
ALTER TABLE "reports" ADD "selection_fields" character varying;
    
  DROP TRIGGER IF EXISTS address_update on addresses;
  DROP TRIGGER IF EXISTS address_insert on addresses;
  DROP FUNCTION IF EXISTS handle_address_update();
  CREATE FUNCTION handle_address_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          
          NEW.street := lower(NEW.street);
          NEW.street2 := lower(NEW.street2);
          NEW.street3 := lower(NEW.street3);
          NEW.city := lower(NEW.city);
          NEW.state := lower(NEW.state);
          NEW.zip := lower(NEW.zip);
          NEW.country := lower(NEW.country);
          NEW.postal_code := lower(NEW.postal_code);
          NEW.region := lower(NEW.region);
          NEW.source := lower(NEW.source);
          RETURN NEW;
            
        END;   
    $$;
    
    CREATE TRIGGER address_update BEFORE UPDATE ON addresses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_address_update();
    CREATE TRIGGER address_insert BEFORE INSERT ON addresses FOR EACH ROW EXECUTE PROCEDURE handle_address_update();


  DROP FUNCTION IF EXISTS update_address_ranks(set_master_id INTEGER);
  CREATE FUNCTION update_address_ranks(set_master_id INTEGER) RETURNS INTEGER
    LANGUAGE plpgsql
    AS $$
        DECLARE
          latest_primary RECORD;
        BEGIN
  
          SELECT * into latest_primary 
          FROM addresses
          WHERE master_id = set_master_id
          AND rank = 10
          ORDER BY updated_at DESC
          LIMIT 1;
        
          IF NOT FOUND THEN
            RETURN NULL;
          END IF;

          
          UPDATE addresses SET rank = 5 
          WHERE 
            master_id = master_id 
            AND rank = 10
            AND id <> latest_primary.id;
          

          RETURN 1;
        END;
    $$;



;
    
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
            master_id = master_id 
            AND rank = 10
            AND rec_type = set_rec_type
            AND id <> latest_primary.id;
          

          RETURN 1;
        END;
    $$;

;
    
  DROP TRIGGER IF EXISTS player_info_before_update on player_infos;
  DROP TRIGGER IF EXISTS player_info_insert on player_infos;
  DROP FUNCTION IF EXISTS handle_player_info_before_update();
  CREATE FUNCTION handle_player_info_before_update() RETURNS trigger
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
    
    CREATE TRIGGER player_info_before_update BEFORE UPDATE ON player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_player_info_before_update();
    CREATE TRIGGER player_info_insert BEFORE INSERT ON player_infos FOR EACH ROW EXECUTE PROCEDURE handle_player_info_before_update();



    DROP TRIGGER IF EXISTS player_info_insert ON player_infos;
    DROP TRIGGER IF EXISTS player_info_update ON player_infos;

    CREATE OR REPLACE FUNCTION update_master_with_player_info() RETURNS TRIGGER AS $master_update$
      BEGIN
          UPDATE masters 
              set rank = (
              case when NEW.rank is null then null 
                   when (NEW.rank > 12) then NEW.rank * -1 
                   else new.rank
              end
              )

          WHERE masters.id = NEW.master_id;

          RETURN NEW;
      END;
      $master_update$ LANGUAGE plpgsql;

    

    CREATE TRIGGER player_info_update
        AFTER UPDATE ON player_infos
        FOR EACH ROW
        WHEN (OLD.* IS DISTINCT FROM NEW.*)
        EXECUTE PROCEDURE update_master_with_player_info();

    
    
    CREATE TRIGGER player_info_insert
        AFTER INSERT ON player_infos
        FOR EACH ROW
        EXECUTE PROCEDURE update_master_with_player_info();



;
      
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
          WHERE lower(p.name) = lower(protocol_name)
          AND lower(sp.name) = lower(sub_process_name) 
          AND lower(pe.name) = lower(protocol_event_name)
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
    

;
      
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
SET search_path = public, pg_catalog;
COPY schema_migrations (version) FROM stdin;
20151123203524
20151124151501
20151125192206
20151202180745
20151208144918
20151208200918
20151208200919
20151208200920
20151208244916
20151208244917
20151208244918
\.

 commit; ;
