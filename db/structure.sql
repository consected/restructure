--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: ml_app; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ml_app;


SET search_path = ml_app, pg_catalog;

--
-- Name: add_study_update_entry(integer, character varying, character varying, date, character varying, integer, integer, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION add_study_update_entry(master_id integer, update_type character varying, update_name character varying, event_date date, update_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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


--
-- Name: add_tracker_entry_by_name(integer, character varying, character varying, character varying, character varying, integer, integer, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION add_tracker_entry_by_name(master_id integer, protocol_name character varying, sub_process_name character varying, protocol_event_name character varying, set_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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


--
-- Name: add_tracker_entry_by_name(integer, character varying, character varying, character varying, date, character varying, integer, integer, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION add_tracker_entry_by_name(master_id integer, protocol_name character varying, sub_process_name character varying, protocol_event_name character varying, event_date date, set_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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


--
-- Name: assign_sage_ids_to_players(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION assign_sage_ids_to_players() RETURNS record
    LANGUAGE plpgsql
    AS $$
      DECLARE
        min_sa integer;
        max_sa integer;
        res record;
      BEGIN

        -- update the precreated Sage ID records with the master_id from the player info, based on matching ID. 
        -- apply an offset here if the Sage ID does not start at zero
        -- find the first unassigned Sage ID
        select min(id) into min_sa from sage_assignments where master_id is null;
        -- update the sage assignments in a block starting from the minimum unassigned ID
        update sage_assignments sa set master_id = (select master_id from temp_pit where id = sa.id - min_sa) where sa.master_id is null and sa.id >= min_sa;
        -- get the max value to return the results
        select max(id) into max_sa from sage_assignments where master_id is not null;
        select min_sa, max_sa into res;
        return res;

       END;
    $$;


--
-- Name: current_user_id(); Type: FUNCTION; Schema: ml_app; Owner: -
--

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


--
-- Name: format_update_notes(character varying, character varying, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION format_update_notes(field_name character varying, old_val character varying, new_val character varying) RETURNS character varying
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


--
-- Name: handle_address_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

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


--
-- Name: handle_delete(); Type: FUNCTION; Schema: ml_app; Owner: -
--

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


--
-- Name: handle_player_contact_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

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


--
-- Name: handle_player_info_before_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

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


--
-- Name: handle_rc_cis_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION handle_rc_cis_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
          new_master_id integer;
          new_msid integer;
          updated_item_id integer;
          register_tracker boolean;
          update_notes VARCHAR;
          event_date DATE;
          track_p varchar;
          track_sp varchar;
          track_pe varchar;
          res_status varchar;
          
        BEGIN


          track_p := 'study';
          track_sp := 'CIS-received';
          track_pe := 'REDCap';

          register_tracker := FALSE;
          update_notes := '';
          res_status := NEW.status;

          event_date :=  NEW.time_stamp::date;

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
                  (new_master_id, NEW.first_name, NEW.last_name, 'cis-redcap', now(), now(), NEW.user_id);
                
                register_tracker := TRUE;
                
            ELSE              
                SELECT id INTO new_master_id FROM masters WHERE id = NEW.master_id;
            END IF;
  
            IF NEW.status = 'update name' OR NEW.status = 'update all' OR NEW.status = 'create master' THEN  
                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;


                SELECT format_update_notes('first name', first_name, NEW.first_name) ||
                  format_update_notes('last name', last_name, NEW.last_name) ||
                  format_update_notes('middle name', middle_name, NEW.middle_name) ||
                  format_update_notes('nick name', nick_name, NEW.nick_name)
                INTO update_notes
                FROM player_infos
                WHERE master_id = new_master_id order by rank desc limit 1;

                UPDATE player_infos SET
                  master_id = new_master_id, first_name = NEW.first_name, last_name = NEW.last_name, 
                  middle_name = NEW.middle_name, nick_name = NEW.nick_name, 
                  source = 'cis-redcap', created_at = now(), updated_at = now(), user_id = NEW.user_id
                  WHERE master_id = new_master_id
                  RETURNING id INTO updated_item_id;
                

                PERFORM add_study_update_entry(new_master_id, 'updated', 'player info', event_date, update_notes, NEW.user_id, updated_item_id, 'PlayerInfo');

                register_tracker := TRUE;                
                res_status := 'updated name';
            END IF;

            IF NEW.status = 'update address' OR NEW.status = 'update all' OR NEW.status = 'create master' THEN  
                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;

                IF NEW.street IS NOT NULL AND trim(NEW.street) <> '' OR
                    NEW.state IS NOT NULL AND trim(NEW.state) <> '' OR
                    NEW.zipcode IS NOT NULL AND trim(NEW.zipcode) <> '' THEN   

                  SELECT format_update_notes('street', NULL, NEW.street) ||
                    format_update_notes('street2', NULL, NEW.street2) ||
                    format_update_notes('city', NULL, NEW.city) ||
                    format_update_notes('state', NULL, NEW.state) ||
                    format_update_notes('zip', NULL, NEW.zipcode)                  
                  INTO update_notes;
                  -- FROM addresses
                  -- WHERE master_id = new_master_id;


                  
                  INSERT INTO addresses
                    (master_id, street, street2, city, state, zip, source, rank, created_at, updated_at, user_id)
                    VALUES
                    (new_master_id, NEW.street, NEW.street2, NEW.city, NEW.state, NEW.zipcode, 'cis-redcap', 10, now(), now(), NEW.user_id)
                    RETURNING id INTO updated_item_id;
                  
                  PERFORM update_address_ranks(new_master_id);
                  PERFORM add_study_update_entry(new_master_id, 'updated', 'address', event_date, update_notes, NEW.user_id, updated_item_id, 'Address');

                  register_tracker := TRUE;
                  res_status := 'updated address';
                ELSE
                  res_status := 'address not updated - details blank';
                END IF;

                
            END IF;

            IF NEW.status = 'update email' OR NEW.status = 'update all' OR NEW.status = 'create master' THEN  

                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;

                IF NEW.email IS NOT NULL AND trim(NEW.email) <> '' THEN   

                  SELECT format_update_notes('data', NULL, NEW.email)           
                  INTO update_notes;                  


                  INSERT INTO player_contacts
                    (master_id, data, rec_type, source, rank, created_at, updated_at, user_id)
                    VALUES
                    (new_master_id, NEW.email, 'email', 'cis-redcap', 10, now(), now(), NEW.user_id)
                    RETURNING id INTO updated_item_id;


                  PERFORM update_player_contact_ranks(new_master_id, 'email');
                  PERFORM add_study_update_entry(new_master_id, 'updated', 'player contact', event_date, update_notes, NEW.user_id, updated_item_id, 'PlayerContact');

                  register_tracker := TRUE;
                  res_status := 'updated email';
                ELSE
                  res_status := 'email not updated - details blank';
                END IF;                
            END IF;

            IF NEW.status = 'update phone' OR NEW.status = 'update all' OR NEW.status = 'create master' THEN  
                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;

                IF NEW.phone IS NOT NULL AND trim(NEW.phone) <> '' THEN   

                  SELECT format_update_notes('data', NULL, NEW.phone)           
                  INTO update_notes;                  

                  INSERT INTO player_contacts
                    (master_id, data, rec_type, source, rank, created_at, updated_at, user_id)
                    VALUES
                    (new_master_id, NEW.phone, 'phone', 'cis-redcap', 10, now(), now(), NEW.user_id)
                    RETURNING id INTO updated_item_id;

                  PERFORM update_player_contact_ranks(new_master_id, 'phone');
                  PERFORM add_study_update_entry(new_master_id, 'updated', 'player contact', event_date, update_notes, NEW.user_id, updated_item_id, 'PlayerContact');

                  register_tracker := TRUE;
                  res_status := 'updated phone';
                ELSE
                  res_status := 'phone not updated - details blank';
                END IF;
            END IF;
            

            CASE 
              WHEN NEW.status = 'create master' THEN 
                res_status := 'created master';
              WHEN NEW.status = 'update all' THEN 
                res_status := 'updated all';              
              ELSE
            END CASE;

            -- the master_id was set and an action performed. Register the tracker event
            IF coalesce(NEW.added_tracker, FALSE) = FALSE AND new_master_id IS NOT NULL AND register_tracker THEN
              PERFORM add_tracker_entry_by_name(new_master_id, track_p, track_sp, track_pe, OLD.time_stamp::date, ('Heard about: ' || coalesce(OLD.hearabout, '(not set)') || E'
Submitted by REDCap ID '|| OLD.redcap_survey_identifier), NEW.user_id, NULL, NULL);
              NEW.added_tracker = TRUE;
            END IF;

            NEW.master_id := new_master_id;
            NEW.updated_at := now();
            NEW.status := res_status;

          END IF;

          RETURN NEW;
            
        END;   
    $$;


--
-- Name: handle_tracker_history_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

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


--
-- Name: log_accuracy_score_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_accuracy_score_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO accuracy_score_history
            (
                    accuracy_score_id,
                    name ,
                    value ,                    
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id                      
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.value ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id                      
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_activity_log_ext_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_activity_log_ext_assignment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ext_assignment_history
                  (
                      master_id,
                      ext_assignment_id,
                      do_when,
notes,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ext_assignment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ext_assignment_id,
                      NEW.do_when,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_activity_log_ipa_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_activity_log_ipa_assignment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_history
                  (
                      master_id,
                      ipa_assignment_id,
                      return_call_availability_notes,
                      questions_from_call_notes,
                      results_link,
                      pi_notes_from_return_call,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.return_call_availability_notes,
                      NEW.questions_from_call_notes,
                      NEW.results_link,
                      NEW.pi_notes_from_return_call,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_activity_log_new_test_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_activity_log_new_test_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_new_test_history
                  (
                      master_id,
                      new_test_id,
                      done_when,
                      select_result,
                      notes,
                      protocol_id,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_new_test_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.new_test_id,
                      NEW.done_when,
                      NEW.select_result,
                      NEW.notes,
                      NEW.protocol_id,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_activity_log_player_contact_phone_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_activity_log_player_contact_phone_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            BEGIN
                INSERT INTO activity_log_player_contact_phone_history
                (
                    master_id,
                    player_contact_id,
                    data,
                    select_call_direction,
                    select_who,
                    called_when,
                    select_result,
                    select_next_step,
                    follow_up_when,
                    notes,
                    protocol_id,
                    set_related_player_contact_rank,
                    user_id,
                    created_at,
                    updated_at,
                    activity_log_player_contact_phone_id
                    )
                SELECT
                    NEW.master_id,
                    NEW.player_contact_id,
                    NEW.data,
                    NEW.select_call_direction,
                    NEW.select_who,
                    NEW.called_when,
                    NEW.select_result,
                    NEW.select_next_step,
                    NEW.follow_up_when,
                    NEW.notes,
                    NEW.protocol_id,
                    NEW.set_related_player_contact_rank,
                    NEW.user_id,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;


--
-- Name: log_activity_log_player_info_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_activity_log_player_info_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_player_info_history
                  (
                      master_id,
                      player_info_id,
                      done_when,
                      notes,
                      protocol_id,
                      select_who,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_player_info_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.player_info_id,
                      NEW.done_when,
                      NEW.notes,
                      NEW.protocol_id,
                      NEW.select_who,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_activity_log_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_activity_log_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                BEGIN
                    INSERT INTO activity_log_history
                    (
                        name,
                        activity_log_id,
                        admin_id,
                        created_at,
                        updated_at,
                        item_type,
                        rec_type,
                        disabled,
                        action_when_attribute,
                        field_list,
                        blank_log_field_list
                        )
                    SELECT
                        NEW.name,
                        NEW.id,
                        NEW.admin_id,
                        NEW.created_at,
                        NEW.updated_at,
                        NEW.item_type,
                        NEW.rec_type,
                        NEW.disabled,
                        NEW.action_when_attribute,
                        NEW.field_list,
                        NEW.blank_log_field_list
                    ;
                    RETURN NEW;
                END;
            $$;


--
-- Name: log_address_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_address_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO address_history 
                (
                    master_id,
                    street,
                    street2,
                    street3,
                    city,
                    state,
                    zip,
                    source,
                    rank,
                    rec_type,
                    user_id,
                    created_at,
                    updated_at,
                    country,
                    postal_code,
                    region,
                    address_id
                )
                 
            SELECT                 
                NEW.master_id,
                NEW.street,
                NEW.street2,
                NEW.street3,
                NEW.city,
                NEW.state,
                NEW.zip,
                NEW.source,
                NEW.rank,
                NEW.rec_type,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.country,
                NEW.postal_code,
                NEW.region,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_admin_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_admin_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO admin_history
            (
                    admin_id,
    email,
    encrypted_password,    
    sign_in_count,
    current_sign_in_at,
    last_sign_in_at,
    current_sign_in_ip ,
    last_sign_in_ip ,
    created_at ,
    updated_at,
    failed_attempts,
    unlock_token,
    locked_at,
    disabled 

                )                 
            SELECT                 
                NEW.id,
                NEW.email,
    NEW.encrypted_password,    
    NEW.sign_in_count,
    NEW.current_sign_in_at,
    NEW.last_sign_in_at,
    NEW.current_sign_in_ip ,
    NEW.last_sign_in_ip ,
    NEW.created_at ,
    NEW.updated_at,
    NEW.failed_attempts,
    NEW.unlock_token,
    NEW.locked_at,
    NEW.disabled 
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_college_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_college_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO college_history
            (
                    college_id,
                    name ,
                    synonym_for_id,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id,
                    user_id            
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.synonym_for_id ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id,
                    NEW.user_id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_dynamic_model_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_dynamic_model_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO dynamic_model_history
            (
                    dynamic_model_id,
                    name,                    
                    table_name, 
                    schema_name,
                    primary_key_name,
                    foreign_key_name,
                    description,
                    admin_id,
                    disabled,                    
                    created_at,
                    updated_at,
                    position,
                    category,
                    table_key_name,
                    field_list,
                    result_order
                    
                    
                )                 
            SELECT                 
                NEW.id,
                                    NEW.name,    
                    NEW.table_name, 
                    NEW.schema_name,
                    NEW.primary_key_name,
                    NEW.foreign_key_name,
                    NEW.description,
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.position,
                    NEW.category,
                    NEW.table_key_name,
                    NEW.field_list,
                    NEW.result_order
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_ext_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_ext_assignment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ext_assignment_history
                  (
                      master_id,
                      ext_id,
                      user_id,
                      created_at,
                      updated_at,
                      ext_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ext_id,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ext_gen_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_ext_gen_assignment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ext_gen_assignment_history
                  (
                      master_id,
                      ext_gen_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      ext_gen_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ext_gen_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_external_identifier_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_external_identifier_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                BEGIN
                    INSERT INTO external_identifier_history
                    (
                        name,
                        external_identifier_id,
                        label,
                        external_id_attribute,
                        external_id_view_formatter,
                        external_id_edit_pattern,
                        prevent_edit,
                        pregenerate_ids,
                        min_id,
                        max_id,
                        admin_id,
                        created_at,
                        updated_at,
                        disabled
                        )
                    SELECT
                        NEW.name,
                        NEW.id,
                        NEW.label,
                        NEW.external_id_attribute,
                        NEW.external_id_view_formatter,
                        NEW.external_id_edit_pattern,
                        NEW.prevent_edit,
                        NEW.pregenerate_ids,
                        NEW.min_id,
                        NEW.max_id,
                        NEW.admin_id,
                        NEW.created_at,
                        NEW.updated_at,
                        NEW.disabled
                    ;
                    RETURN NEW;
                END;
            $$;


--
-- Name: log_external_link_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_external_link_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO external_link_history
            (
                    external_link_id,                    
                    name,                    
                    value,
                    admin_id,
                    disabled,                    
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.name,    
                    NEW.value,                     
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_general_selection_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_general_selection_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO general_selection_history
            (
                    general_selection_id,
                    name ,
                    value ,
                    item_type ,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id ,
                    create_with ,
                    edit_if_set ,
                    edit_always ,
                    position ,
                    description ,
                    lock 
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                NEW.value ,
                NEW.item_type ,
                NEW.created_at ,
                NEW.updated_at ,
                NEW.disabled ,
                NEW.admin_id ,
                NEW.create_with ,
                NEW.edit_if_set ,
                NEW.edit_always ,
                NEW.position "position",
                NEW.description ,
                NEW.lock
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_ipa_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_ipa_assignment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_assignment_history
                  (
                      master_id,
                      ipa_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      ipa_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_item_flag_name_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_item_flag_name_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO item_flag_name_history
            (
                    item_flag_name_id,
                    name ,
                    item_type,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.item_type ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_item_flag_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_item_flag_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO item_flag_history
            (
                    item_flag_id,
                    item_id ,
                    item_type,
                    item_flag_name_id,
                    created_at ,
                    updated_at ,
                    user_id ,
                    disabled
                )                 
            SELECT                 
                NEW.id,
                NEW.item_id ,
                    NEW.item_type,
                    NEW.item_flag_name_id,
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.user_id ,
                    NEW.disabled
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_new_test_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_new_test_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO new_test_history
                  (
                      master_id,
                      new_test_ext_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      new_test_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.new_test_ext_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_player_contact_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_player_contact_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO player_contact_history
            (
                    player_contact_id,
                    master_id,
                    rec_type,
                    data,
                    source,
                    rank,
                    user_id,
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.master_id,
                NEW.rec_type,
                NEW.data,
                NEW.source,
                NEW.rank,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_player_info_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_player_info_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
 BEGIN
 INSERT INTO player_info_history
 (
 master_id,
 first_name,
 last_name,
 middle_name,
 nick_name,
 birth_date,
 death_date,
 user_id,
 created_at,
 updated_at,
 contact_pref,
 start_year,
 rank,
 notes,
 contact_id,
 college,
 end_year,
 source,
 other_count, -- <<<< added
 other_type, -- <<<< added
 player_info_id
 ) 
 SELECT
 NEW.master_id,
 NEW.first_name,
 NEW.last_name,
 NEW.middle_name,
 NEW.nick_name,
 NEW.birth_date,
 NEW.death_date,
 NEW.user_id,
 NEW.created_at,
 NEW.updated_at,
 NEW.contact_pref,
 NEW.start_year,
 NEW.rank,
 NEW.notes,
 NEW.contact_id,
 NEW.college,
 NEW.end_year, 
 NEW.source, 
 NEW.other_count, -- <<<< added
 NEW.other_type,  -- <<<< added
 NEW.id
 ;
 RETURN NEW;
 END;
 $$;


--
-- Name: log_protocol_event_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_protocol_event_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO protocol_event_history
            (
                    protocol_event_id,                    
    name ,
    admin_id,
    created_at,
    updated_at,
    disabled ,
    sub_process_id,
    milestone ,
    description

                )                 
            SELECT                 
                NEW.id,
                NEW.name ,                    
                    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.disabled ,
    NEW.sub_process_id,
    NEW.milestone ,
    NEW.description
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_protocol_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_protocol_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO protocol_history
            (
                    protocol_id,
                    name ,                    
                    created_at ,
                    updated_at ,
                    disabled,
                    admin_id ,
                    "position"
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled,
                    NEW.admin_id ,
                    NEW.position
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_report_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_report_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO report_history
            (
                    report_id,
                    name,                    
                    description,
                    sql,
                    search_attrs,
                    admin_id,
                    disabled,
                    report_type,
                    auto,
                    searchable,
                    position,
                    created_at,
                    updated_at,
                    edit_field_names,
                    selection_fields,
                    item_type
                )                 
            SELECT                 
                NEW.id,
                NEW.name,                
                NEW.description,
                NEW.sql,
                NEW.search_attrs,
                NEW.admin_id,                
                NEW.disabled,
                NEW.report_type,
                NEW.auto,
                NEW.searchable,
                NEW.position,                
                NEW.created_at,
                NEW.updated_at,
                NEW.edit_field_names,
                NEW.selection_fields,
                NEW.item_type
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_sage_two_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_sage_two_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO sage_two_history
            (
                    sage_two_id,                    
                    external_id,
                    user_id,
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.external_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at 
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_scantron_series_two_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_scantron_series_two_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO scantron_series_two_history
            (
                    scantron_series_two_id,                    
                    external_id,
                    user_id,
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.external_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at 
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_scantron_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_scantron_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO scantron_history
            (
                master_id,
                scantron_id,
                user_id,
                created_at,
                updated_at,
                scantron_table_id
                )                 
            SELECT
                NEW.master_id,
                NEW.scantron_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_sub_process_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_sub_process_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO sub_process_history
            (
                    sub_process_id,                    
    
    name,
    disabled,
    protocol_id,
    admin_id ,
    created_at,
    updated_at

                )                 
            SELECT                 
                NEW.id,
                NEW.name,
    NEW.disabled,
    NEW.protocol_id,
    NEW.admin_id ,
    NEW.created_at,
    NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_test1_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_test1_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO test1_history
                  (
                      master_id,
                      test1_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      test1_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.test1_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_test2_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_test2_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO test2_history
                  (
                      master_id,
                      test_2ext_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      test2_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.test_2ext_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_test_2_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_test_2_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO test_2_history
                  (
                      master_id,
                      test_2ext_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      test_2_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.test_2ext_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_test_ext2_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_test_ext2_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            BEGIN
                INSERT INTO test_ext2_history
                (
                    master_id,
                    test_e2_id,
                    user_id,
                    created_at,
                    updated_at,
                    test_ext2_table_id
                    )
                SELECT
                    NEW.master_id,
                    NEW.test_e2_id,
                    NEW.user_id,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;


--
-- Name: log_test_ext_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_test_ext_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            BEGIN
                INSERT INTO test_ext_history
                (
                    master_id,
                    test_e_id,
                    user_id,
                    created_at,
                    updated_at,
                    test_ext_table_id
                    )
                SELECT
                    NEW.master_id,
                    NEW.test_e_id,
                    NEW.user_id,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;


--
-- Name: log_test_item_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_test_item_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO test_item_history
            (
                    test_item_id,                    
                    external_id,
                    user_id,
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.external_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at 
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_tracker_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

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


--
-- Name: log_user_authorization_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_user_authorization_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_authorization_history
            (
                    user_authorization_id,
                    user_id,                    
                    has_authorization,                    
                    admin_id,
                    disabled,                    
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.user_id,                
                NEW.has_authorization,               
                NEW.admin_id,                
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_user_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION log_user_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_history
            (
                    user_id,
    email,
    encrypted_password,
    reset_password_token,
    reset_password_sent_at,
    remember_created_at,
    sign_in_count,
    current_sign_in_at,
    last_sign_in_at,
    current_sign_in_ip ,
    last_sign_in_ip ,
    created_at ,
    updated_at,
    failed_attempts,
    unlock_token,
    locked_at,
    disabled ,
    admin_id 

                )                 
            SELECT                 
                NEW.id,
                NEW.email,
    NEW.encrypted_password,
    NEW.reset_password_token,
    NEW.reset_password_sent_at,
    NEW.remember_created_at,
    NEW.sign_in_count,
    NEW.current_sign_in_at,
    NEW.last_sign_in_at,
    NEW.current_sign_in_ip ,
    NEW.last_sign_in_ip ,
    NEW.created_at ,
    NEW.updated_at,
    NEW.failed_attempts,
    NEW.unlock_token,
    NEW.locked_at,
    NEW.disabled ,
    NEW.admin_id  
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: tracker_upsert(); Type: FUNCTION; Schema: ml_app; Owner: -
--

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


--
-- Name: update_address_ranks(integer); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION update_address_ranks(set_master_id integer) RETURNS integer
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
            master_id = set_master_id 
            AND rank = 10
            AND id <> latest_primary.id;
          

          RETURN 1;
        END;
    $$;


--
-- Name: update_master_with_player_info(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION update_master_with_player_info() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
      $$;


--
-- Name: update_master_with_pro_info(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION update_master_with_pro_info() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE masters 
            set pro_info_id = NEW.id, pro_id = NEW.pro_id             
        WHERE masters.id = NEW.master_id;

        RETURN NEW;
    END;
    $$;


--
-- Name: update_player_contact_ranks(integer, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION update_player_contact_ranks(set_master_id integer, set_rec_type character varying) RETURNS integer
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


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accuracy_score_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE accuracy_score_history (
    id integer NOT NULL,
    name character varying,
    value integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    accuracy_score_id integer
);


--
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE accuracy_score_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE accuracy_score_history_id_seq OWNED BY accuracy_score_history.id;


--
-- Name: accuracy_scores; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE accuracy_scores (
    id integer NOT NULL,
    name character varying,
    value integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean
);


--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE accuracy_scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE accuracy_scores_id_seq OWNED BY accuracy_scores.id;


--
-- Name: activity_log_ext_assignment_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_ext_assignment_history (
    id integer NOT NULL,
    master_id integer,
    ext_assignment_id integer,
    do_when date,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ext_assignment_id integer
);


--
-- Name: activity_log_ext_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_ext_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ext_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_ext_assignment_history_id_seq OWNED BY activity_log_ext_assignment_history.id;


--
-- Name: activity_log_ext_assignments; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_ext_assignments (
    id integer NOT NULL,
    master_id integer,
    ext_assignment_id integer,
    do_when date,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    select_call_direction character varying,
    select_who character varying,
    extra_text character varying,
    extra_log_type character varying
);


--
-- Name: activity_log_ext_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_ext_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ext_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_ext_assignments_id_seq OWNED BY activity_log_ext_assignments.id;


--
-- Name: activity_log_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_history (
    id integer NOT NULL,
    activity_log_id integer,
    name character varying,
    item_type character varying,
    rec_type character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    action_when_attribute character varying,
    field_list character varying,
    blank_log_field_list character varying
);


--
-- Name: activity_log_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_history_id_seq OWNED BY activity_log_history.id;


--
-- Name: activity_log_ipa_assignment_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_ipa_assignment_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    return_call_availability_notes character varying,
    questions_from_call_notes character varying,
    results_link character varying,
    pi_notes_from_return_call character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_id integer
);


--
-- Name: activity_log_ipa_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_ipa_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_ipa_assignment_history_id_seq OWNED BY activity_log_ipa_assignment_history.id;


--
-- Name: activity_log_ipa_assignments; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_ipa_assignments (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    return_call_availability_notes character varying,
    questions_from_call_notes character varying,
    results_link character varying,
    pi_notes_from_return_call character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    select_record_from_player_contact_phones character varying
);


--
-- Name: activity_log_ipa_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_ipa_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_ipa_assignments_id_seq OWNED BY activity_log_ipa_assignments.id;


--
-- Name: activity_log_new_test_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_new_test_history (
    id integer NOT NULL,
    master_id integer,
    new_test_id integer,
    done_when date,
    select_result character varying,
    notes character varying,
    protocol_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_new_test_id integer
);


--
-- Name: activity_log_new_test_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_new_test_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_new_test_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_new_test_history_id_seq OWNED BY activity_log_new_test_history.id;


--
-- Name: activity_log_new_tests; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_new_tests (
    id integer NOT NULL,
    master_id integer,
    new_test_id integer,
    done_when date,
    select_result character varying,
    notes character varying,
    protocol_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    new_test_ext_id bigint
);


--
-- Name: activity_log_new_tests_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_new_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_new_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_new_tests_id_seq OWNED BY activity_log_new_tests.id;


--
-- Name: activity_log_player_contact_emails; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_player_contact_emails (
    id integer NOT NULL,
    data character varying,
    select_email_direction character varying,
    select_who character varying,
    emailed_when date,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    protocol_id integer,
    notes character varying,
    user_id integer,
    player_contact_id integer,
    master_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    set_related_player_contact_rank character varying
);


--
-- Name: activity_log_player_contact_emails_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_player_contact_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_contact_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_player_contact_emails_id_seq OWNED BY activity_log_player_contact_emails.id;


--
-- Name: activity_log_player_contact_phone_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_player_contact_phone_history (
    id integer NOT NULL,
    master_id integer,
    player_contact_id integer,
    data character varying,
    select_call_direction character varying,
    select_who character varying,
    called_when date,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    notes character varying,
    protocol_id integer,
    set_related_player_contact_rank character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_player_contact_phone_id integer
);


--
-- Name: activity_log_player_contact_phone_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_player_contact_phone_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_contact_phone_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_player_contact_phone_history_id_seq OWNED BY activity_log_player_contact_phone_history.id;


--
-- Name: activity_log_player_contact_phones; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_player_contact_phones (
    id integer NOT NULL,
    data character varying,
    select_call_direction character varying,
    select_who character varying,
    called_when date,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    protocol_id integer,
    notes character varying,
    user_id integer,
    player_contact_id integer,
    master_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    set_related_player_contact_rank character varying
);


--
-- Name: activity_log_player_contact_phones_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_player_contact_phones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_contact_phones_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_player_contact_phones_id_seq OWNED BY activity_log_player_contact_phones.id;


--
-- Name: activity_log_player_info_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_player_info_history (
    id integer NOT NULL,
    master_id integer,
    player_info_id integer,
    done_when date,
    notes character varying,
    protocol_id integer,
    select_who character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_player_info_id integer
);


--
-- Name: activity_log_player_info_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_player_info_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_info_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_player_info_history_id_seq OWNED BY activity_log_player_info_history.id;


--
-- Name: activity_log_player_infos; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_log_player_infos (
    id integer NOT NULL,
    master_id integer,
    player_info_id integer,
    done_when date,
    notes character varying,
    protocol_id integer,
    select_who character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_player_infos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_log_player_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_log_player_infos_id_seq OWNED BY activity_log_player_infos.id;


--
-- Name: activity_logs; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE activity_logs (
    id integer NOT NULL,
    name character varying,
    item_type character varying,
    rec_type character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    action_when_attribute character varying,
    field_list character varying,
    blank_log_field_list character varying,
    blank_log_name character varying,
    extra_log_types character varying,
    hide_item_list_panel boolean,
    main_log_name character varying
);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE activity_logs_id_seq OWNED BY activity_logs.id;


--
-- Name: address_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE address_history (
    id integer NOT NULL,
    master_id integer,
    street character varying,
    street2 character varying,
    street3 character varying,
    city character varying,
    state character varying,
    zip character varying,
    source character varying,
    rank integer,
    rec_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:35.841791'::timestamp without time zone,
    country character varying(3),
    postal_code character varying,
    region character varying,
    address_id integer
);


--
-- Name: address_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE address_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: address_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE address_history_id_seq OWNED BY address_history.id;


--
-- Name: addresses; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE addresses (
    id integer NOT NULL,
    master_id integer,
    street character varying,
    street2 character varying,
    street3 character varying,
    city character varying,
    state character varying,
    zip character varying,
    source character varying,
    rank integer,
    rec_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:35.929228'::timestamp without time zone,
    country character varying(3),
    postal_code character varying,
    region character varying
);


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE addresses_id_seq OWNED BY addresses.id;


--
-- Name: admin_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE admin_history (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    disabled boolean,
    admin_id integer
);


--
-- Name: admin_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE admin_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE admin_history_id_seq OWNED BY admin_history.id;


--
-- Name: admins; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE admins (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    disabled boolean
);


--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE admins_id_seq OWNED BY admins.id;


--
-- Name: app_configurations; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE app_configurations (
    id integer NOT NULL,
    name character varying,
    value character varying,
    disabled boolean,
    admin_id integer,
    user_id integer,
    app_type_id integer
);


--
-- Name: app_configurations_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE app_configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE app_configurations_id_seq OWNED BY app_configurations.id;


--
-- Name: app_types; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE app_types (
    id integer NOT NULL,
    name character varying,
    label character varying,
    disabled boolean,
    admin_id integer
);


--
-- Name: app_types_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE app_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_types_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE app_types_id_seq OWNED BY app_types.id;


--
-- Name: college_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE college_history (
    id integer NOT NULL,
    name character varying,
    synonym_for_id integer,
    disabled boolean,
    admin_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    college_id integer
);


--
-- Name: college_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE college_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: college_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE college_history_id_seq OWNED BY college_history.id;


--
-- Name: colleges; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE colleges (
    id integer NOT NULL,
    name character varying,
    synonym_for_id integer,
    disabled boolean,
    admin_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: colleges_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE colleges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: colleges_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE colleges_id_seq OWNED BY colleges.id;


--
-- Name: copy_player_infos; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE copy_player_infos (
    id integer,
    master_id integer,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    nick_name character varying,
    birth_date date,
    death_date date,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    contact_pref character varying,
    start_year integer,
    rank integer,
    notes character varying,
    contactid integer,
    college character varying,
    end_year integer,
    source character varying
);


--
-- Name: dynamic_model_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE dynamic_model_history (
    id integer NOT NULL,
    name character varying,
    table_name character varying,
    schema_name character varying,
    primary_key_name character varying,
    foreign_key_name character varying,
    description character varying,
    admin_id integer,
    disabled boolean,
    "position" integer,
    category character varying,
    table_key_name character varying,
    field_list character varying,
    result_order character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    dynamic_model_id integer
);


--
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE dynamic_model_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE dynamic_model_history_id_seq OWNED BY dynamic_model_history.id;


--
-- Name: dynamic_models; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE dynamic_models (
    id integer NOT NULL,
    name character varying,
    table_name character varying,
    schema_name character varying,
    primary_key_name character varying,
    foreign_key_name character varying,
    description character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "position" integer,
    category character varying,
    table_key_name character varying,
    field_list character varying,
    result_order character varying
);


--
-- Name: dynamic_models_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE dynamic_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dynamic_models_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE dynamic_models_id_seq OWNED BY dynamic_models.id;


--
-- Name: ext_assignment_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE ext_assignment_history (
    id integer NOT NULL,
    master_id integer,
    ext_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ext_assignment_table_id integer
);


--
-- Name: ext_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ext_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ext_assignment_history_id_seq OWNED BY ext_assignment_history.id;


--
-- Name: ext_assignments; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE ext_assignments (
    id integer NOT NULL,
    master_id integer,
    ext_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ext_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ext_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ext_assignments_id_seq OWNED BY ext_assignments.id;


--
-- Name: ext_gen_assignment_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE ext_gen_assignment_history (
    id integer NOT NULL,
    master_id integer,
    ext_gen_id integer,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ext_gen_assignment_table_id integer
);


--
-- Name: ext_gen_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ext_gen_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_gen_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ext_gen_assignment_history_id_seq OWNED BY ext_gen_assignment_history.id;


--
-- Name: ext_gen_assignments; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE ext_gen_assignments (
    id integer NOT NULL,
    master_id integer,
    ext_gen_id integer,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ext_gen_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ext_gen_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_gen_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ext_gen_assignments_id_seq OWNED BY ext_gen_assignments.id;


--
-- Name: external_identifier_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE external_identifier_history (
    id integer NOT NULL,
    name character varying,
    label character varying,
    external_id_attribute character varying,
    external_id_view_formatter character varying,
    external_id_edit_pattern character varying,
    prevent_edit boolean,
    pregenerate_ids boolean,
    min_id bigint,
    max_id bigint,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    external_identifier_id integer
);


--
-- Name: external_identifier_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE external_identifier_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_identifier_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE external_identifier_history_id_seq OWNED BY external_identifier_history.id;


--
-- Name: external_identifiers; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE external_identifiers (
    id integer NOT NULL,
    name character varying,
    label character varying,
    external_id_attribute character varying,
    external_id_view_formatter character varying,
    external_id_edit_pattern character varying,
    prevent_edit boolean,
    pregenerate_ids boolean,
    min_id bigint,
    max_id bigint,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: external_identifiers_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE external_identifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_identifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE external_identifiers_id_seq OWNED BY external_identifiers.id;


--
-- Name: external_link_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE external_link_history (
    id integer NOT NULL,
    name character varying,
    value character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    external_link_id integer
);


--
-- Name: external_link_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE external_link_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_link_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE external_link_history_id_seq OWNED BY external_link_history.id;


--
-- Name: external_links; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE external_links (
    id integer NOT NULL,
    name character varying,
    value character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: external_links_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE external_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_links_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE external_links_id_seq OWNED BY external_links.id;


--
-- Name: general_selection_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE general_selection_history (
    id integer NOT NULL,
    name character varying,
    value character varying,
    item_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    create_with boolean,
    edit_if_set boolean,
    edit_always boolean,
    "position" integer,
    description character varying,
    lock boolean,
    general_selection_id integer
);


--
-- Name: general_selection_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE general_selection_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: general_selection_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE general_selection_history_id_seq OWNED BY general_selection_history.id;


--
-- Name: general_selections; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE general_selections (
    id integer NOT NULL,
    name character varying,
    value character varying,
    item_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    create_with boolean,
    edit_if_set boolean,
    edit_always boolean,
    "position" integer,
    description character varying,
    lock boolean
);


--
-- Name: general_selections_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE general_selections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: general_selections_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE general_selections_id_seq OWNED BY general_selections.id;


--
-- Name: imports; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE imports (
    id integer NOT NULL,
    primary_table character varying,
    item_count integer,
    filename character varying,
    imported_items integer[],
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: imports_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE imports_id_seq OWNED BY imports.id;


--
-- Name: ipa_assignment_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE ipa_assignment_history (
    id integer NOT NULL,
    master_id integer,
    ipa_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_assignment_table_id integer
);


--
-- Name: ipa_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ipa_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ipa_assignment_history_id_seq OWNED BY ipa_assignment_history.id;


--
-- Name: ipa_assignments; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE ipa_assignments (
    id integer NOT NULL,
    master_id integer,
    ipa_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ipa_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ipa_assignments_id_seq OWNED BY ipa_assignments.id;


--
-- Name: item_flag_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE item_flag_history (
    id integer NOT NULL,
    item_id integer,
    item_type character varying,
    item_flag_name_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    item_flag_id integer,
    disabled boolean
);


--
-- Name: item_flag_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE item_flag_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE item_flag_history_id_seq OWNED BY item_flag_history.id;


--
-- Name: item_flag_name_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE item_flag_name_history (
    id integer NOT NULL,
    name character varying,
    item_type character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    item_flag_name_id integer
);


--
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE item_flag_name_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE item_flag_name_history_id_seq OWNED BY item_flag_name_history.id;


--
-- Name: item_flag_names; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE item_flag_names (
    id integer NOT NULL,
    name character varying,
    item_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer
);


--
-- Name: item_flag_names_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE item_flag_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_names_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE item_flag_names_id_seq OWNED BY item_flag_names.id;


--
-- Name: item_flags; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE item_flags (
    id integer NOT NULL,
    item_id integer,
    item_type character varying,
    item_flag_name_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    disabled boolean
);


--
-- Name: item_flags_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE item_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE item_flags_id_seq OWNED BY item_flags.id;


--
-- Name: manage_users; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE manage_users (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: manage_users_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE manage_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manage_users_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE manage_users_id_seq OWNED BY manage_users.id;


--
-- Name: masters; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE masters (
    id integer NOT NULL,
    msid integer,
    pro_id integer,
    pro_info_id integer,
    rank integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    contact_id integer
);


--
-- Name: masters_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE masters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: masters_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE masters_id_seq OWNED BY masters.id;


--
-- Name: ml_copy; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE ml_copy (
    procontactid integer,
    fill_in_addresses character varying(255),
    in_survey character varying(255),
    verify_survey_participation character varying(255),
    verify_player_and_or_match character varying(255),
    accuracy character varying(255),
    accuracy_score character varying(255),
    contactid integer,
    pro_id integer,
    separator_a text,
    first_name character varying(255),
    middle_name character varying(255),
    last_name character varying(255),
    nick_name character varying(255),
    separator_b text,
    pro_first_name character varying(255),
    pro_middle_name character varying(255),
    pro_last_name character varying(255),
    pro_nick_name character varying(255),
    birthdate character varying(255),
    pro_dob character varying(255),
    pro_dod character varying(255),
    startyear character varying(255),
    pro_start_year character varying(255),
    accruedseasons integer,
    pro_end_year character varying(255),
    first_contract character varying(255),
    second_contract character varying(255),
    third_contract character varying(255),
    pro_career_info character varying(255),
    pro_birthplace character varying(255),
    pro_college character varying(255),
    email character varying(255),
    homecity character varying(255),
    homestate character varying(50),
    homezipcode character varying(10),
    homestreet character varying(255),
    homestreet2 character varying(255),
    homestreet3 character varying(255),
    businesscity character varying(255),
    businessstate character varying(50),
    businesszipcode character varying(10),
    businessstreet character varying(255),
    businessstreet2 character varying(255),
    businessstreet3 character varying(255),
    changed integer,
    changed_column character varying(255),
    verified integer,
    notes text,
    email2 character varying(255),
    email3 character varying(255),
    updatehomestreet character varying(255),
    updatehomestreet2 character varying(255),
    updatehomecity character varying(255),
    updatehomestate character varying(50),
    updatehomezipcode character varying(10),
    lastmod character varying(255),
    sourc character varying(255),
    changed_by character varying(255),
    msid integer,
    mailing character varying(255),
    outreach_vfy character varying(255),
    lastupdate text,
    lastupdateby text,
    cprefs character varying(255),
    scantronid integer,
    insertauditkey text
);


--
-- Name: msid_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE msid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_test_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE new_test_history (
    id integer NOT NULL,
    master_id integer,
    new_test_ext_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    new_test_table_id integer
);


--
-- Name: new_test_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE new_test_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_test_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE new_test_history_id_seq OWNED BY new_test_history.id;


--
-- Name: new_tests; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE new_tests (
    id integer NOT NULL,
    master_id integer,
    new_test_ext_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: new_tests_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE new_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE new_tests_id_seq OWNED BY new_tests.id;


--
-- Name: player_contact_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE player_contact_history (
    id integer NOT NULL,
    master_id integer,
    rec_type character varying,
    data character varying,
    source character varying,
    rank integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:36.835851'::timestamp without time zone,
    player_contact_id integer
);


--
-- Name: player_contact_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE player_contact_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_contact_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE player_contact_history_id_seq OWNED BY player_contact_history.id;


--
-- Name: player_contacts; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE player_contacts (
    id integer NOT NULL,
    master_id integer,
    rec_type character varying,
    data character varying,
    source character varying,
    rank integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:36.922871'::timestamp without time zone
);


--
-- Name: player_contacts_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE player_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE player_contacts_id_seq OWNED BY player_contacts.id;


--
-- Name: player_info_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE player_info_history (
    id integer NOT NULL,
    master_id integer,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    nick_name character varying,
    birth_date date,
    death_date date,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:36.99602'::timestamp without time zone,
    contact_pref character varying,
    start_year integer,
    rank integer,
    notes character varying,
    contact_id integer,
    college character varying,
    end_year integer,
    source character varying,
    player_info_id integer,
    other_count integer,
    other_type character varying
);


--
-- Name: player_info_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE player_info_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_info_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE player_info_history_id_seq OWNED BY player_info_history.id;


--
-- Name: player_infos; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE player_infos (
    id integer NOT NULL,
    master_id integer,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    nick_name character varying,
    birth_date date,
    death_date date,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:37.094626'::timestamp without time zone,
    contact_pref character varying,
    start_year integer,
    rank integer,
    notes character varying,
    contact_id integer,
    college character varying,
    end_year integer,
    source character varying,
    other_count integer,
    other_type character varying
);


--
-- Name: player_infos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE player_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE player_infos_id_seq OWNED BY player_infos.id;


--
-- Name: pro_infos; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE pro_infos (
    id integer NOT NULL,
    master_id integer,
    pro_id integer,
    first_name character varying,
    middle_name character varying,
    nick_name character varying,
    last_name character varying,
    birth_date date,
    death_date date,
    start_year integer,
    end_year integer,
    college character varying,
    birthplace character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:37.165247'::timestamp without time zone
);


--
-- Name: pro_infos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE pro_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pro_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE pro_infos_id_seq OWNED BY pro_infos.id;


--
-- Name: protocol_event_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE protocol_event_history (
    id integer NOT NULL,
    name character varying,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    sub_process_id integer,
    milestone character varying,
    description character varying,
    protocol_event_id integer
);


--
-- Name: protocol_event_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE protocol_event_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_event_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE protocol_event_history_id_seq OWNED BY protocol_event_history.id;


--
-- Name: protocol_events; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE protocol_events (
    id integer NOT NULL,
    name character varying,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    sub_process_id integer,
    milestone character varying,
    description character varying
);


--
-- Name: protocol_events_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE protocol_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_events_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE protocol_events_id_seq OWNED BY protocol_events.id;


--
-- Name: protocol_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE protocol_history (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    "position" integer,
    protocol_id integer
);


--
-- Name: protocol_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE protocol_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE protocol_history_id_seq OWNED BY protocol_history.id;


--
-- Name: protocols; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE protocols (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    "position" integer
);


--
-- Name: protocols_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE protocols_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocols_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE protocols_id_seq OWNED BY protocols.id;


--
-- Name: rc_cis; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE rc_cis (
    id integer NOT NULL,
    fname character varying,
    lname character varying,
    status character varying,
    created_at timestamp without time zone DEFAULT '2017-09-25 15:43:37.367264'::timestamp without time zone,
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:37.367264'::timestamp without time zone,
    user_id integer,
    master_id integer,
    street character varying,
    street2 character varying,
    city character varying,
    state character varying,
    zip character varying,
    phone character varying,
    email character varying,
    form_date timestamp without time zone
);


--
-- Name: rc_cis2; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE rc_cis2 (
    id integer,
    fname character varying,
    lname character varying,
    status character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: rc_cis_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE rc_cis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rc_cis_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE rc_cis_id_seq OWNED BY rc_cis.id;


--
-- Name: rc_stage_cif_copy; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE rc_stage_cif_copy (
    id integer NOT NULL,
    record_id integer,
    redcap_survey_identifier integer,
    time_stamp timestamp without time zone,
    first_name character varying,
    middle_name character varying,
    last_name character varying,
    nick_name character varying,
    street character varying,
    street2 character varying,
    city character varying,
    state character varying,
    zipcode character varying,
    phone character varying,
    email character varying,
    hearabout character varying,
    completed integer,
    status character varying,
    created_at timestamp without time zone DEFAULT '2017-09-25 15:43:37.419709'::timestamp without time zone,
    user_id integer,
    master_id integer,
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:37.419709'::timestamp without time zone,
    added_tracker boolean
);


--
-- Name: rc_stage_cif_copy_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE rc_stage_cif_copy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rc_stage_cif_copy_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE rc_stage_cif_copy_id_seq OWNED BY rc_stage_cif_copy.id;


--
-- Name: report_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE report_history (
    id integer NOT NULL,
    name character varying,
    description character varying,
    sql character varying,
    search_attrs character varying,
    admin_id integer,
    disabled boolean,
    report_type character varying,
    auto boolean,
    searchable boolean,
    "position" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    report_id integer,
    item_type character varying,
    edit_model character varying,
    edit_field_names character varying,
    selection_fields character varying
);


--
-- Name: report_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE report_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE report_history_id_seq OWNED BY report_history.id;


--
-- Name: reports; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE reports (
    id integer NOT NULL,
    name character varying,
    description character varying,
    sql character varying,
    search_attrs character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    report_type character varying,
    auto boolean,
    searchable boolean,
    "position" integer,
    edit_model character varying,
    edit_field_names character varying,
    selection_fields character varying,
    item_type character varying
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE reports_id_seq OWNED BY reports.id;


--
-- Name: sage_assignments; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE sage_assignments (
    id integer NOT NULL,
    sage_id character varying(10),
    assigned_by character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    master_id integer,
    admin_id integer
);


--
-- Name: sage_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE sage_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sage_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE sage_assignments_id_seq OWNED BY sage_assignments.id;


--
-- Name: sage_two_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE sage_two_history (
    id integer NOT NULL,
    sage_two_id integer,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sage_two_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE sage_two_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sage_two_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE sage_two_history_id_seq OWNED BY sage_two_history.id;


--
-- Name: sage_twos; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE sage_twos (
    id integer NOT NULL,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sage_twos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE sage_twos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sage_twos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE sage_twos_id_seq OWNED BY sage_twos.id;


--
-- Name: scantron_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE scantron_history (
    id integer NOT NULL,
    master_id integer,
    scantron_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    scantron_table_id integer
);


--
-- Name: scantron_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE scantron_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantron_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE scantron_history_id_seq OWNED BY scantron_history.id;


--
-- Name: scantron_series_two_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE scantron_series_two_history (
    id integer NOT NULL,
    scantron_series_two_id integer,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: scantron_series_two_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE scantron_series_two_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantron_series_two_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE scantron_series_two_history_id_seq OWNED BY scantron_series_two_history.id;


--
-- Name: scantron_series_twos; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE scantron_series_twos (
    id integer NOT NULL,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: scantron_series_twos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE scantron_series_twos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantron_series_twos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE scantron_series_twos_id_seq OWNED BY scantron_series_twos.id;


--
-- Name: scantrons; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE scantrons (
    id integer NOT NULL,
    master_id integer,
    scantron_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: scantrons_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE scantrons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantrons_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE scantrons_id_seq OWNED BY scantrons.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: smback; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE smback (
    version character varying
);


--
-- Name: sub_process_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE sub_process_history (
    id integer NOT NULL,
    name character varying,
    disabled boolean,
    protocol_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sub_process_id integer
);


--
-- Name: sub_process_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE sub_process_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_process_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE sub_process_history_id_seq OWNED BY sub_process_history.id;


--
-- Name: sub_processes; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE sub_processes (
    id integer NOT NULL,
    name character varying,
    disabled boolean,
    protocol_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sub_processes_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE sub_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE sub_processes_id_seq OWNED BY sub_processes.id;


--
-- Name: test1_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test1_history (
    id integer NOT NULL,
    master_id integer,
    test1_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    test1_table_id integer
);


--
-- Name: test1_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test1_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test1_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test1_history_id_seq OWNED BY test1_history.id;


--
-- Name: test1s; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test1s (
    id integer NOT NULL,
    master_id integer,
    test1_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test1s_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test1s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test1s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test1s_id_seq OWNED BY test1s.id;


--
-- Name: test2_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test2_history (
    id integer NOT NULL,
    master_id integer,
    test_2ext_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    test2_table_id integer
);


--
-- Name: test2_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test2_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test2_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test2_history_id_seq OWNED BY test2_history.id;


--
-- Name: test2s; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test2s (
    id integer NOT NULL,
    master_id integer,
    test_2ext_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test2s_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test2s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test2s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test2s_id_seq OWNED BY test2s.id;


--
-- Name: test_2_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test_2_history (
    id integer NOT NULL,
    master_id integer,
    test_2ext_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    test_2_table_id integer
);


--
-- Name: test_2_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test_2_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_2_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test_2_history_id_seq OWNED BY test_2_history.id;


--
-- Name: test_2s; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test_2s (
    id integer NOT NULL,
    master_id integer,
    test_2ext_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test_2s_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test_2s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_2s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test_2s_id_seq OWNED BY test_2s.id;


--
-- Name: test_ext2_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test_ext2_history (
    id integer NOT NULL,
    master_id integer,
    test_e2_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    test_ext2_table_id integer
);


--
-- Name: test_ext2_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test_ext2_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_ext2_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test_ext2_history_id_seq OWNED BY test_ext2_history.id;


--
-- Name: test_ext2s; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test_ext2s (
    id integer NOT NULL,
    master_id integer,
    test_e2_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test_ext2s_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test_ext2s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_ext2s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test_ext2s_id_seq OWNED BY test_ext2s.id;


--
-- Name: test_ext_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test_ext_history (
    id integer NOT NULL,
    master_id integer,
    test_e_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    test_ext_table_id integer
);


--
-- Name: test_ext_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test_ext_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_ext_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test_ext_history_id_seq OWNED BY test_ext_history.id;


--
-- Name: test_exts; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test_exts (
    id integer NOT NULL,
    master_id integer,
    test_e_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test_exts_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test_exts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_exts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test_exts_id_seq OWNED BY test_exts.id;


--
-- Name: test_item_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test_item_history (
    id integer NOT NULL,
    test_item_id integer,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test_item_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test_item_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_item_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test_item_history_id_seq OWNED BY test_item_history.id;


--
-- Name: test_items; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE test_items (
    id integer NOT NULL,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test_items_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE test_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_items_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE test_items_id_seq OWNED BY test_items.id;


--
-- Name: tracker_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE tracker_history (
    id integer NOT NULL,
    master_id integer,
    protocol_id integer,
    tracker_id integer,
    event_date timestamp without time zone,
    user_id integer,
    notes character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    sub_process_id integer,
    protocol_event_id integer,
    item_id integer,
    item_type character varying
);


--
-- Name: tracker_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE tracker_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracker_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE tracker_history_id_seq OWNED BY tracker_history.id;


--
-- Name: trackers; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE trackers (
    id integer NOT NULL,
    master_id integer,
    protocol_id integer NOT NULL,
    event_date timestamp without time zone,
    user_id integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    notes character varying,
    sub_process_id integer NOT NULL,
    protocol_event_id integer,
    item_id integer,
    item_type character varying
);


--
-- Name: trackers_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE trackers_id_seq OWNED BY trackers.id;


--
-- Name: user_access_controls; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE user_access_controls (
    id integer NOT NULL,
    user_id integer,
    resource_type character varying,
    resource_name character varying,
    options character varying,
    access character varying,
    disabled boolean,
    admin_id integer,
    app_type_id integer
);


--
-- Name: user_access_controls_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE user_access_controls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_access_controls_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE user_access_controls_id_seq OWNED BY user_access_controls.id;


--
-- Name: user_authorization_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE user_authorization_history (
    id integer NOT NULL,
    user_id character varying,
    has_authorization character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_authorization_id integer
);


--
-- Name: user_authorization_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE user_authorization_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_authorization_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE user_authorization_history_id_seq OWNED BY user_authorization_history.id;


--
-- Name: user_authorizations; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE user_authorizations (
    id integer NOT NULL,
    user_id integer,
    has_authorization character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_authorizations_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE user_authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE user_authorizations_id_seq OWNED BY user_authorizations.id;


--
-- Name: user_history; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE user_history (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    disabled boolean,
    admin_id integer,
    user_id integer
);


--
-- Name: user_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE user_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE user_history_id_seq OWNED BY user_history.id;


--
-- Name: users; Type: TABLE; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    disabled boolean,
    admin_id integer,
    app_type_id integer
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY accuracy_score_history ALTER COLUMN id SET DEFAULT nextval('accuracy_score_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY accuracy_scores ALTER COLUMN id SET DEFAULT nextval('accuracy_scores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ext_assignment_history ALTER COLUMN id SET DEFAULT nextval('activity_log_ext_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ext_assignments ALTER COLUMN id SET DEFAULT nextval('activity_log_ext_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_history ALTER COLUMN id SET DEFAULT nextval('activity_log_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ipa_assignment_history ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ipa_assignments ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_new_test_history ALTER COLUMN id SET DEFAULT nextval('activity_log_new_test_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_new_tests ALTER COLUMN id SET DEFAULT nextval('activity_log_new_tests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_contact_emails ALTER COLUMN id SET DEFAULT nextval('activity_log_player_contact_emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_contact_phone_history ALTER COLUMN id SET DEFAULT nextval('activity_log_player_contact_phone_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_contact_phones ALTER COLUMN id SET DEFAULT nextval('activity_log_player_contact_phones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_info_history ALTER COLUMN id SET DEFAULT nextval('activity_log_player_info_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_infos ALTER COLUMN id SET DEFAULT nextval('activity_log_player_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_logs ALTER COLUMN id SET DEFAULT nextval('activity_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY address_history ALTER COLUMN id SET DEFAULT nextval('address_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY admin_history ALTER COLUMN id SET DEFAULT nextval('admin_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY admins ALTER COLUMN id SET DEFAULT nextval('admins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY app_configurations ALTER COLUMN id SET DEFAULT nextval('app_configurations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY app_types ALTER COLUMN id SET DEFAULT nextval('app_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY college_history ALTER COLUMN id SET DEFAULT nextval('college_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY colleges ALTER COLUMN id SET DEFAULT nextval('colleges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY dynamic_model_history ALTER COLUMN id SET DEFAULT nextval('dynamic_model_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY dynamic_models ALTER COLUMN id SET DEFAULT nextval('dynamic_models_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_assignment_history ALTER COLUMN id SET DEFAULT nextval('ext_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_assignments ALTER COLUMN id SET DEFAULT nextval('ext_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_gen_assignment_history ALTER COLUMN id SET DEFAULT nextval('ext_gen_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_gen_assignments ALTER COLUMN id SET DEFAULT nextval('ext_gen_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY external_identifier_history ALTER COLUMN id SET DEFAULT nextval('external_identifier_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY external_identifiers ALTER COLUMN id SET DEFAULT nextval('external_identifiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY external_link_history ALTER COLUMN id SET DEFAULT nextval('external_link_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY external_links ALTER COLUMN id SET DEFAULT nextval('external_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY general_selection_history ALTER COLUMN id SET DEFAULT nextval('general_selection_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY general_selections ALTER COLUMN id SET DEFAULT nextval('general_selections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY imports ALTER COLUMN id SET DEFAULT nextval('imports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ipa_assignment_history ALTER COLUMN id SET DEFAULT nextval('ipa_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ipa_assignments ALTER COLUMN id SET DEFAULT nextval('ipa_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY item_flag_history ALTER COLUMN id SET DEFAULT nextval('item_flag_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY item_flag_name_history ALTER COLUMN id SET DEFAULT nextval('item_flag_name_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY item_flag_names ALTER COLUMN id SET DEFAULT nextval('item_flag_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY item_flags ALTER COLUMN id SET DEFAULT nextval('item_flags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY manage_users ALTER COLUMN id SET DEFAULT nextval('manage_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY masters ALTER COLUMN id SET DEFAULT nextval('masters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY new_test_history ALTER COLUMN id SET DEFAULT nextval('new_test_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY new_tests ALTER COLUMN id SET DEFAULT nextval('new_tests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_contact_history ALTER COLUMN id SET DEFAULT nextval('player_contact_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_contacts ALTER COLUMN id SET DEFAULT nextval('player_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_info_history ALTER COLUMN id SET DEFAULT nextval('player_info_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_infos ALTER COLUMN id SET DEFAULT nextval('player_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY pro_infos ALTER COLUMN id SET DEFAULT nextval('pro_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY protocol_event_history ALTER COLUMN id SET DEFAULT nextval('protocol_event_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY protocol_events ALTER COLUMN id SET DEFAULT nextval('protocol_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY protocol_history ALTER COLUMN id SET DEFAULT nextval('protocol_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY protocols ALTER COLUMN id SET DEFAULT nextval('protocols_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY rc_cis ALTER COLUMN id SET DEFAULT nextval('rc_cis_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY rc_stage_cif_copy ALTER COLUMN id SET DEFAULT nextval('rc_stage_cif_copy_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY report_history ALTER COLUMN id SET DEFAULT nextval('report_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY reports ALTER COLUMN id SET DEFAULT nextval('reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY sage_assignments ALTER COLUMN id SET DEFAULT nextval('sage_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY sage_two_history ALTER COLUMN id SET DEFAULT nextval('sage_two_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY sage_twos ALTER COLUMN id SET DEFAULT nextval('sage_twos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY scantron_history ALTER COLUMN id SET DEFAULT nextval('scantron_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY scantron_series_two_history ALTER COLUMN id SET DEFAULT nextval('scantron_series_two_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY scantron_series_twos ALTER COLUMN id SET DEFAULT nextval('scantron_series_twos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY scantrons ALTER COLUMN id SET DEFAULT nextval('scantrons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY sub_process_history ALTER COLUMN id SET DEFAULT nextval('sub_process_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY sub_processes ALTER COLUMN id SET DEFAULT nextval('sub_processes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test1_history ALTER COLUMN id SET DEFAULT nextval('test1_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test1s ALTER COLUMN id SET DEFAULT nextval('test1s_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test2_history ALTER COLUMN id SET DEFAULT nextval('test2_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test2s ALTER COLUMN id SET DEFAULT nextval('test2s_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_2_history ALTER COLUMN id SET DEFAULT nextval('test_2_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_2s ALTER COLUMN id SET DEFAULT nextval('test_2s_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_ext2_history ALTER COLUMN id SET DEFAULT nextval('test_ext2_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_ext2s ALTER COLUMN id SET DEFAULT nextval('test_ext2s_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_ext_history ALTER COLUMN id SET DEFAULT nextval('test_ext_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_exts ALTER COLUMN id SET DEFAULT nextval('test_exts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_item_history ALTER COLUMN id SET DEFAULT nextval('test_item_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_items ALTER COLUMN id SET DEFAULT nextval('test_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY tracker_history ALTER COLUMN id SET DEFAULT nextval('tracker_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY trackers ALTER COLUMN id SET DEFAULT nextval('trackers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY user_access_controls ALTER COLUMN id SET DEFAULT nextval('user_access_controls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY user_authorization_history ALTER COLUMN id SET DEFAULT nextval('user_authorization_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY user_authorizations ALTER COLUMN id SET DEFAULT nextval('user_authorizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY user_history ALTER COLUMN id SET DEFAULT nextval('user_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: accuracy_score_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY accuracy_score_history
    ADD CONSTRAINT accuracy_score_history_pkey PRIMARY KEY (id);


--
-- Name: accuracy_scores_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY accuracy_scores
    ADD CONSTRAINT accuracy_scores_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ext_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_ext_assignment_history
    ADD CONSTRAINT activity_log_ext_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ext_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_ext_assignments
    ADD CONSTRAINT activity_log_ext_assignments_pkey PRIMARY KEY (id);


--
-- Name: activity_log_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_history
    ADD CONSTRAINT activity_log_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_ipa_assignment_history
    ADD CONSTRAINT activity_log_ipa_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_ipa_assignments
    ADD CONSTRAINT activity_log_ipa_assignments_pkey PRIMARY KEY (id);


--
-- Name: activity_log_new_test_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_new_test_history
    ADD CONSTRAINT activity_log_new_test_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_new_tests_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_new_tests
    ADD CONSTRAINT activity_log_new_tests_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_contact_emails_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_player_contact_emails
    ADD CONSTRAINT activity_log_player_contact_emails_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_contact_phone_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_player_contact_phone_history
    ADD CONSTRAINT activity_log_player_contact_phone_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_contact_phones_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_player_contact_phones
    ADD CONSTRAINT activity_log_player_contact_phones_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_info_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_player_info_history
    ADD CONSTRAINT activity_log_player_info_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_log_player_infos
    ADD CONSTRAINT activity_log_player_infos_pkey PRIMARY KEY (id);


--
-- Name: activity_logs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: address_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT address_history_pkey PRIMARY KEY (id);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: admin_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admin_history
    ADD CONSTRAINT admin_history_pkey PRIMARY KEY (id);


--
-- Name: admins_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: app_configurations_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY app_configurations
    ADD CONSTRAINT app_configurations_pkey PRIMARY KEY (id);


--
-- Name: app_types_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY app_types
    ADD CONSTRAINT app_types_pkey PRIMARY KEY (id);


--
-- Name: college_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY college_history
    ADD CONSTRAINT college_history_pkey PRIMARY KEY (id);


--
-- Name: colleges_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY colleges
    ADD CONSTRAINT colleges_pkey PRIMARY KEY (id);


--
-- Name: dynamic_model_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dynamic_model_history
    ADD CONSTRAINT dynamic_model_history_pkey PRIMARY KEY (id);


--
-- Name: dynamic_models_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dynamic_models
    ADD CONSTRAINT dynamic_models_pkey PRIMARY KEY (id);


--
-- Name: ext_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ext_assignment_history
    ADD CONSTRAINT ext_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: ext_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ext_assignments
    ADD CONSTRAINT ext_assignments_pkey PRIMARY KEY (id);


--
-- Name: ext_gen_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ext_gen_assignment_history
    ADD CONSTRAINT ext_gen_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: ext_gen_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ext_gen_assignments
    ADD CONSTRAINT ext_gen_assignments_pkey PRIMARY KEY (id);


--
-- Name: external_identifier_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY external_identifier_history
    ADD CONSTRAINT external_identifier_history_pkey PRIMARY KEY (id);


--
-- Name: external_identifiers_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY external_identifiers
    ADD CONSTRAINT external_identifiers_pkey PRIMARY KEY (id);


--
-- Name: external_link_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY external_link_history
    ADD CONSTRAINT external_link_history_pkey PRIMARY KEY (id);


--
-- Name: external_links_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY external_links
    ADD CONSTRAINT external_links_pkey PRIMARY KEY (id);


--
-- Name: general_selection_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY general_selection_history
    ADD CONSTRAINT general_selection_history_pkey PRIMARY KEY (id);


--
-- Name: general_selections_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY general_selections
    ADD CONSTRAINT general_selections_pkey PRIMARY KEY (id);


--
-- Name: imports_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: ipa_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ipa_assignment_history
    ADD CONSTRAINT ipa_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ipa_assignments
    ADD CONSTRAINT ipa_assignments_pkey PRIMARY KEY (id);


--
-- Name: item_flag_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_flag_history
    ADD CONSTRAINT item_flag_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_name_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_flag_name_history
    ADD CONSTRAINT item_flag_name_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_names_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_flag_names
    ADD CONSTRAINT item_flag_names_pkey PRIMARY KEY (id);


--
-- Name: item_flags_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT item_flags_pkey PRIMARY KEY (id);


--
-- Name: manage_users_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY manage_users
    ADD CONSTRAINT manage_users_pkey PRIMARY KEY (id);


--
-- Name: masters_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY masters
    ADD CONSTRAINT masters_pkey PRIMARY KEY (id);


--
-- Name: new_test_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY new_test_history
    ADD CONSTRAINT new_test_history_pkey PRIMARY KEY (id);


--
-- Name: new_tests_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY new_tests
    ADD CONSTRAINT new_tests_pkey PRIMARY KEY (id);


--
-- Name: player_contact_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT player_contact_history_pkey PRIMARY KEY (id);


--
-- Name: player_contacts_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT player_contacts_pkey PRIMARY KEY (id);


--
-- Name: player_info_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT player_info_history_pkey PRIMARY KEY (id);


--
-- Name: player_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT player_infos_pkey PRIMARY KEY (id);


--
-- Name: pro_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT pro_infos_pkey PRIMARY KEY (id);


--
-- Name: protocol_event_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocol_event_history
    ADD CONSTRAINT protocol_event_history_pkey PRIMARY KEY (id);


--
-- Name: protocol_events_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT protocol_events_pkey PRIMARY KEY (id);


--
-- Name: protocol_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocol_history
    ADD CONSTRAINT protocol_history_pkey PRIMARY KEY (id);


--
-- Name: protocols_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- Name: rc_cis_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY rc_cis
    ADD CONSTRAINT rc_cis_pkey PRIMARY KEY (id);


--
-- Name: rc_stage_cif_copy_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY rc_stage_cif_copy
    ADD CONSTRAINT rc_stage_cif_copy_pkey PRIMARY KEY (id);


--
-- Name: report_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY report_history
    ADD CONSTRAINT report_history_pkey PRIMARY KEY (id);


--
-- Name: reports_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: sage_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sage_assignments
    ADD CONSTRAINT sage_assignments_pkey PRIMARY KEY (id);


--
-- Name: sage_two_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sage_two_history
    ADD CONSTRAINT sage_two_history_pkey PRIMARY KEY (id);


--
-- Name: sage_twos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sage_twos
    ADD CONSTRAINT sage_twos_pkey PRIMARY KEY (id);


--
-- Name: scantron_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT scantron_history_pkey PRIMARY KEY (id);


--
-- Name: scantron_series_two_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scantron_series_two_history
    ADD CONSTRAINT scantron_series_two_history_pkey PRIMARY KEY (id);


--
-- Name: scantron_series_twos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scantron_series_twos
    ADD CONSTRAINT scantron_series_twos_pkey PRIMARY KEY (id);


--
-- Name: scantrons_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT scantrons_pkey PRIMARY KEY (id);


--
-- Name: sub_process_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sub_process_history
    ADD CONSTRAINT sub_process_history_pkey PRIMARY KEY (id);


--
-- Name: sub_processes_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT sub_processes_pkey PRIMARY KEY (id);


--
-- Name: test1_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test1_history
    ADD CONSTRAINT test1_history_pkey PRIMARY KEY (id);


--
-- Name: test1s_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test1s
    ADD CONSTRAINT test1s_pkey PRIMARY KEY (id);


--
-- Name: test2_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test2_history
    ADD CONSTRAINT test2_history_pkey PRIMARY KEY (id);


--
-- Name: test2s_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test2s
    ADD CONSTRAINT test2s_pkey PRIMARY KEY (id);


--
-- Name: test_2_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_2_history
    ADD CONSTRAINT test_2_history_pkey PRIMARY KEY (id);


--
-- Name: test_2s_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_2s
    ADD CONSTRAINT test_2s_pkey PRIMARY KEY (id);


--
-- Name: test_ext2_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_ext2_history
    ADD CONSTRAINT test_ext2_history_pkey PRIMARY KEY (id);


--
-- Name: test_ext2s_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_ext2s
    ADD CONSTRAINT test_ext2s_pkey PRIMARY KEY (id);


--
-- Name: test_ext_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_ext_history
    ADD CONSTRAINT test_ext_history_pkey PRIMARY KEY (id);


--
-- Name: test_exts_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_exts
    ADD CONSTRAINT test_exts_pkey PRIMARY KEY (id);


--
-- Name: test_item_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_item_history
    ADD CONSTRAINT test_item_history_pkey PRIMARY KEY (id);


--
-- Name: test_items_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_items
    ADD CONSTRAINT test_items_pkey PRIMARY KEY (id);


--
-- Name: tracker_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT tracker_history_pkey PRIMARY KEY (id);


--
-- Name: trackers_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT trackers_pkey PRIMARY KEY (id);


--
-- Name: user_access_controls_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_access_controls
    ADD CONSTRAINT user_access_controls_pkey PRIMARY KEY (id);


--
-- Name: user_authorization_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_authorization_history
    ADD CONSTRAINT user_authorization_history_pkey PRIMARY KEY (id);


--
-- Name: user_authorizations_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_authorizations
    ADD CONSTRAINT user_authorizations_pkey PRIMARY KEY (id);


--
-- Name: user_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_history
    ADD CONSTRAINT user_history_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_accuracy_score_history_on_accuracy_score_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_accuracy_score_history_on_accuracy_score_id ON accuracy_score_history USING btree (accuracy_score_id);


--
-- Name: index_accuracy_scores_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_accuracy_scores_on_admin_id ON accuracy_scores USING btree (admin_id);


--
-- Name: index_activity_log_ext_assignment_history_on_activity_log_ext_a; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ext_assignment_history_on_activity_log_ext_a ON activity_log_ext_assignment_history USING btree (activity_log_ext_assignment_id);


--
-- Name: index_activity_log_ext_assignment_history_on_ext_assignment_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ext_assignment_history_on_ext_assignment_id ON activity_log_ext_assignment_history USING btree (ext_assignment_id);


--
-- Name: index_activity_log_ext_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ext_assignment_history_on_master_id ON activity_log_ext_assignment_history USING btree (master_id);


--
-- Name: index_activity_log_ext_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ext_assignment_history_on_user_id ON activity_log_ext_assignment_history USING btree (user_id);


--
-- Name: index_activity_log_ext_assignments_on_ext_assignment_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ext_assignments_on_ext_assignment_id ON activity_log_ext_assignments USING btree (ext_assignment_id);


--
-- Name: index_activity_log_ext_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ext_assignments_on_master_id ON activity_log_ext_assignments USING btree (master_id);


--
-- Name: index_activity_log_ext_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ext_assignments_on_user_id ON activity_log_ext_assignments USING btree (user_id);


--
-- Name: index_activity_log_history_on_activity_log_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_history_on_activity_log_id ON activity_log_history USING btree (activity_log_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_activity_log_ipa_a; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_activity_log_ipa_a ON activity_log_ipa_assignment_history USING btree (activity_log_ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_ipa_assignment_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_ipa_assignment_id ON activity_log_ipa_assignment_history USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_master_id ON activity_log_ipa_assignment_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_user_id ON activity_log_ipa_assignment_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignments_on_ipa_assignment_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ipa_assignments_on_ipa_assignment_id ON activity_log_ipa_assignments USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ipa_assignments_on_master_id ON activity_log_ipa_assignments USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_ipa_assignments_on_user_id ON activity_log_ipa_assignments USING btree (user_id);


--
-- Name: index_activity_log_new_test_history_on_activity_log_new_test_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_new_test_history_on_activity_log_new_test_id ON activity_log_new_test_history USING btree (activity_log_new_test_id);


--
-- Name: index_activity_log_new_test_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_new_test_history_on_master_id ON activity_log_new_test_history USING btree (master_id);


--
-- Name: index_activity_log_new_test_history_on_new_test_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_new_test_history_on_new_test_id ON activity_log_new_test_history USING btree (new_test_id);


--
-- Name: index_activity_log_new_test_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_new_test_history_on_user_id ON activity_log_new_test_history USING btree (user_id);


--
-- Name: index_activity_log_new_tests_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_new_tests_on_master_id ON activity_log_new_tests USING btree (master_id);


--
-- Name: index_activity_log_new_tests_on_new_test_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_new_tests_on_new_test_id ON activity_log_new_tests USING btree (new_test_id);


--
-- Name: index_activity_log_new_tests_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_new_tests_on_user_id ON activity_log_new_tests USING btree (user_id);


--
-- Name: index_activity_log_player_contact_emails_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_emails_on_master_id ON activity_log_player_contact_emails USING btree (master_id);


--
-- Name: index_activity_log_player_contact_emails_on_player_contact_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_emails_on_player_contact_id ON activity_log_player_contact_emails USING btree (player_contact_id);


--
-- Name: index_activity_log_player_contact_emails_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_emails_on_protocol_id ON activity_log_player_contact_emails USING btree (protocol_id);


--
-- Name: index_activity_log_player_contact_emails_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_emails_on_user_id ON activity_log_player_contact_emails USING btree (user_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_activity_log; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_activity_log ON activity_log_player_contact_phone_history USING btree (activity_log_player_contact_phone_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_master_id ON activity_log_player_contact_phone_history USING btree (master_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_player_conta; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_player_conta ON activity_log_player_contact_phone_history USING btree (player_contact_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_user_id ON activity_log_player_contact_phone_history USING btree (user_id);


--
-- Name: index_activity_log_player_contact_phones_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_phones_on_master_id ON activity_log_player_contact_phones USING btree (master_id);


--
-- Name: index_activity_log_player_contact_phones_on_player_contact_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_phones_on_player_contact_id ON activity_log_player_contact_phones USING btree (player_contact_id);


--
-- Name: index_activity_log_player_contact_phones_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_phones_on_protocol_id ON activity_log_player_contact_phones USING btree (protocol_id);


--
-- Name: index_activity_log_player_contact_phones_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_contact_phones_on_user_id ON activity_log_player_contact_phones USING btree (user_id);


--
-- Name: index_activity_log_player_info_history_on_activity_log_player_i; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_info_history_on_activity_log_player_i ON activity_log_player_info_history USING btree (activity_log_player_info_id);


--
-- Name: index_activity_log_player_info_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_info_history_on_master_id ON activity_log_player_info_history USING btree (master_id);


--
-- Name: index_activity_log_player_info_history_on_player_info_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_info_history_on_player_info_id ON activity_log_player_info_history USING btree (player_info_id);


--
-- Name: index_activity_log_player_info_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_info_history_on_user_id ON activity_log_player_info_history USING btree (user_id);


--
-- Name: index_activity_log_player_infos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_infos_on_master_id ON activity_log_player_infos USING btree (master_id);


--
-- Name: index_activity_log_player_infos_on_player_info_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_infos_on_player_info_id ON activity_log_player_infos USING btree (player_info_id);


--
-- Name: index_activity_log_player_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_activity_log_player_infos_on_user_id ON activity_log_player_infos USING btree (user_id);


--
-- Name: index_address_history_on_address_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_address_history_on_address_id ON address_history USING btree (address_id);


--
-- Name: index_address_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_address_history_on_master_id ON address_history USING btree (master_id);


--
-- Name: index_address_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_address_history_on_user_id ON address_history USING btree (user_id);


--
-- Name: index_addresses_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_addresses_on_master_id ON addresses USING btree (master_id);


--
-- Name: index_addresses_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_addresses_on_user_id ON addresses USING btree (user_id);


--
-- Name: index_admin_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_admin_history_on_admin_id ON admin_history USING btree (admin_id);


--
-- Name: index_app_configurations_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_app_configurations_on_admin_id ON app_configurations USING btree (admin_id);


--
-- Name: index_app_configurations_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_app_configurations_on_app_type_id ON app_configurations USING btree (app_type_id);


--
-- Name: index_app_configurations_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_app_configurations_on_user_id ON app_configurations USING btree (user_id);


--
-- Name: index_app_types_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_app_types_on_admin_id ON app_types USING btree (admin_id);


--
-- Name: index_college_history_on_college_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_college_history_on_college_id ON college_history USING btree (college_id);


--
-- Name: index_colleges_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_colleges_on_admin_id ON colleges USING btree (admin_id);


--
-- Name: index_colleges_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_colleges_on_user_id ON colleges USING btree (user_id);


--
-- Name: index_dynamic_model_history_on_dynamic_model_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_dynamic_model_history_on_dynamic_model_id ON dynamic_model_history USING btree (dynamic_model_id);


--
-- Name: index_dynamic_models_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_dynamic_models_on_admin_id ON dynamic_models USING btree (admin_id);


--
-- Name: index_ext_assignment_history_on_ext_assignment_table_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_assignment_history_on_ext_assignment_table_id ON ext_assignment_history USING btree (ext_assignment_table_id);


--
-- Name: index_ext_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_assignment_history_on_master_id ON ext_assignment_history USING btree (master_id);


--
-- Name: index_ext_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_assignment_history_on_user_id ON ext_assignment_history USING btree (user_id);


--
-- Name: index_ext_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_assignments_on_master_id ON ext_assignments USING btree (master_id);


--
-- Name: index_ext_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_assignments_on_user_id ON ext_assignments USING btree (user_id);


--
-- Name: index_ext_gen_assignment_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_gen_assignment_history_on_admin_id ON ext_gen_assignment_history USING btree (admin_id);


--
-- Name: index_ext_gen_assignment_history_on_ext_gen_assignment_table_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_gen_assignment_history_on_ext_gen_assignment_table_id ON ext_gen_assignment_history USING btree (ext_gen_assignment_table_id);


--
-- Name: index_ext_gen_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_gen_assignment_history_on_master_id ON ext_gen_assignment_history USING btree (master_id);


--
-- Name: index_ext_gen_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_gen_assignment_history_on_user_id ON ext_gen_assignment_history USING btree (user_id);


--
-- Name: index_ext_gen_assignments_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_gen_assignments_on_admin_id ON ext_gen_assignments USING btree (admin_id);


--
-- Name: index_ext_gen_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_gen_assignments_on_master_id ON ext_gen_assignments USING btree (master_id);


--
-- Name: index_ext_gen_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ext_gen_assignments_on_user_id ON ext_gen_assignments USING btree (user_id);


--
-- Name: index_external_identifier_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_external_identifier_history_on_admin_id ON external_identifier_history USING btree (admin_id);


--
-- Name: index_external_identifier_history_on_external_identifier_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_external_identifier_history_on_external_identifier_id ON external_identifier_history USING btree (external_identifier_id);


--
-- Name: index_external_identifiers_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_external_identifiers_on_admin_id ON external_identifiers USING btree (admin_id);


--
-- Name: index_external_link_history_on_external_link_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_external_link_history_on_external_link_id ON external_link_history USING btree (external_link_id);


--
-- Name: index_external_links_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_external_links_on_admin_id ON external_links USING btree (admin_id);


--
-- Name: index_general_selection_history_on_general_selection_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_general_selection_history_on_general_selection_id ON general_selection_history USING btree (general_selection_id);


--
-- Name: index_general_selections_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_general_selections_on_admin_id ON general_selections USING btree (admin_id);


--
-- Name: index_imports_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_imports_on_user_id ON imports USING btree (user_id);


--
-- Name: index_ipa_assignment_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ipa_assignment_history_on_admin_id ON ipa_assignment_history USING btree (admin_id);


--
-- Name: index_ipa_assignment_history_on_ipa_assignment_table_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ipa_assignment_history_on_ipa_assignment_table_id ON ipa_assignment_history USING btree (ipa_assignment_table_id);


--
-- Name: index_ipa_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ipa_assignment_history_on_master_id ON ipa_assignment_history USING btree (master_id);


--
-- Name: index_ipa_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ipa_assignment_history_on_user_id ON ipa_assignment_history USING btree (user_id);


--
-- Name: index_ipa_assignments_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ipa_assignments_on_admin_id ON ipa_assignments USING btree (admin_id);


--
-- Name: index_ipa_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ipa_assignments_on_master_id ON ipa_assignments USING btree (master_id);


--
-- Name: index_ipa_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_ipa_assignments_on_user_id ON ipa_assignments USING btree (user_id);


--
-- Name: index_item_flag_history_on_item_flag_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_item_flag_history_on_item_flag_id ON item_flag_history USING btree (item_flag_id);


--
-- Name: index_item_flag_name_history_on_item_flag_name_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_item_flag_name_history_on_item_flag_name_id ON item_flag_name_history USING btree (item_flag_name_id);


--
-- Name: index_item_flag_names_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_item_flag_names_on_admin_id ON item_flag_names USING btree (admin_id);


--
-- Name: index_item_flags_on_item_flag_name_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_item_flags_on_item_flag_name_id ON item_flags USING btree (item_flag_name_id);


--
-- Name: index_item_flags_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_item_flags_on_user_id ON item_flags USING btree (user_id);


--
-- Name: index_masters_on_msid; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_masters_on_msid ON masters USING btree (msid);


--
-- Name: index_masters_on_pro_info_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_masters_on_pro_info_id ON masters USING btree (pro_info_id);


--
-- Name: index_masters_on_proid; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_masters_on_proid ON masters USING btree (pro_id);


--
-- Name: index_masters_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_masters_on_user_id ON masters USING btree (user_id);


--
-- Name: index_new_test_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_new_test_history_on_admin_id ON new_test_history USING btree (admin_id);


--
-- Name: index_new_test_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_new_test_history_on_master_id ON new_test_history USING btree (master_id);


--
-- Name: index_new_test_history_on_new_test_table_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_new_test_history_on_new_test_table_id ON new_test_history USING btree (new_test_table_id);


--
-- Name: index_new_test_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_new_test_history_on_user_id ON new_test_history USING btree (user_id);


--
-- Name: index_new_tests_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_new_tests_on_admin_id ON new_tests USING btree (admin_id);


--
-- Name: index_new_tests_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_new_tests_on_master_id ON new_tests USING btree (master_id);


--
-- Name: index_new_tests_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_new_tests_on_user_id ON new_tests USING btree (user_id);


--
-- Name: index_player_contact_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_player_contact_history_on_master_id ON player_contact_history USING btree (master_id);


--
-- Name: index_player_contact_history_on_player_contact_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_player_contact_history_on_player_contact_id ON player_contact_history USING btree (player_contact_id);


--
-- Name: index_player_contact_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_player_contact_history_on_user_id ON player_contact_history USING btree (user_id);


--
-- Name: index_player_contacts_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_player_contacts_on_master_id ON player_contacts USING btree (master_id);


--
-- Name: index_player_contacts_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_player_contacts_on_user_id ON player_contacts USING btree (user_id);


--
-- Name: index_player_info_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_player_info_history_on_master_id ON player_info_history USING btree (master_id);


--
-- Name: index_player_info_history_on_player_info_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_player_info_history_on_player_info_id ON player_info_history USING btree (player_info_id);


--
-- Name: index_player_info_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_player_info_history_on_user_id ON player_info_history USING btree (user_id);


--
-- Name: index_player_infos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_player_infos_on_master_id ON player_infos USING btree (master_id);


--
-- Name: index_player_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_player_infos_on_user_id ON player_infos USING btree (user_id);


--
-- Name: index_pro_infos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_pro_infos_on_master_id ON pro_infos USING btree (master_id);


--
-- Name: index_pro_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_pro_infos_on_user_id ON pro_infos USING btree (user_id);


--
-- Name: index_protocol_event_history_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_protocol_event_history_on_protocol_event_id ON protocol_event_history USING btree (protocol_event_id);


--
-- Name: index_protocol_events_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_protocol_events_on_admin_id ON protocol_events USING btree (admin_id);


--
-- Name: index_protocol_events_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_protocol_events_on_sub_process_id ON protocol_events USING btree (sub_process_id);


--
-- Name: index_protocol_history_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_protocol_history_on_protocol_id ON protocol_history USING btree (protocol_id);


--
-- Name: index_protocols_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_protocols_on_admin_id ON protocols USING btree (admin_id);


--
-- Name: index_report_history_on_report_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_report_history_on_report_id ON report_history USING btree (report_id);


--
-- Name: index_reports_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_reports_on_admin_id ON reports USING btree (admin_id);


--
-- Name: index_sage_assignments_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_sage_assignments_on_admin_id ON sage_assignments USING btree (admin_id);


--
-- Name: index_sage_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_sage_assignments_on_master_id ON sage_assignments USING btree (master_id);


--
-- Name: index_sage_assignments_on_sage_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_sage_assignments_on_sage_id ON sage_assignments USING btree (sage_id);


--
-- Name: index_sage_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_sage_assignments_on_user_id ON sage_assignments USING btree (user_id);


--
-- Name: index_sage_two_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_sage_two_history_on_master_id ON sage_two_history USING btree (master_id);


--
-- Name: index_sage_two_history_on_sage_two_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_sage_two_history_on_sage_two_id ON sage_two_history USING btree (sage_two_id);


--
-- Name: index_sage_two_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_sage_two_history_on_user_id ON sage_two_history USING btree (user_id);


--
-- Name: index_sage_twos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_sage_twos_on_master_id ON sage_twos USING btree (master_id);


--
-- Name: index_sage_twos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_sage_twos_on_user_id ON sage_twos USING btree (user_id);


--
-- Name: index_scantron_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_scantron_history_on_master_id ON scantron_history USING btree (master_id);


--
-- Name: index_scantron_history_on_scantron_table_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_scantron_history_on_scantron_table_id ON scantron_history USING btree (scantron_table_id);


--
-- Name: index_scantron_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_scantron_history_on_user_id ON scantron_history USING btree (user_id);


--
-- Name: index_scantron_series_two_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_scantron_series_two_history_on_master_id ON scantron_series_two_history USING btree (master_id);


--
-- Name: index_scantron_series_two_history_on_scantron_series_two_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_scantron_series_two_history_on_scantron_series_two_id ON scantron_series_two_history USING btree (scantron_series_two_id);


--
-- Name: index_scantron_series_two_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_scantron_series_two_history_on_user_id ON scantron_series_two_history USING btree (user_id);


--
-- Name: index_scantron_series_twos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_scantron_series_twos_on_master_id ON scantron_series_twos USING btree (master_id);


--
-- Name: index_scantron_series_twos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_scantron_series_twos_on_user_id ON scantron_series_twos USING btree (user_id);


--
-- Name: index_scantrons_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_scantrons_on_master_id ON scantrons USING btree (master_id);


--
-- Name: index_scantrons_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_scantrons_on_user_id ON scantrons USING btree (user_id);


--
-- Name: index_sub_process_history_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_sub_process_history_on_sub_process_id ON sub_process_history USING btree (sub_process_id);


--
-- Name: index_sub_processes_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_sub_processes_on_admin_id ON sub_processes USING btree (admin_id);


--
-- Name: index_sub_processes_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_sub_processes_on_protocol_id ON sub_processes USING btree (protocol_id);


--
-- Name: index_test1_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test1_history_on_admin_id ON test1_history USING btree (admin_id);


--
-- Name: index_test1_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test1_history_on_master_id ON test1_history USING btree (master_id);


--
-- Name: index_test1_history_on_test1_table_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test1_history_on_test1_table_id ON test1_history USING btree (test1_table_id);


--
-- Name: index_test1_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test1_history_on_user_id ON test1_history USING btree (user_id);


--
-- Name: index_test1s_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test1s_on_admin_id ON test1s USING btree (admin_id);


--
-- Name: index_test1s_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test1s_on_master_id ON test1s USING btree (master_id);


--
-- Name: index_test1s_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test1s_on_user_id ON test1s USING btree (user_id);


--
-- Name: index_test2_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test2_history_on_admin_id ON test2_history USING btree (admin_id);


--
-- Name: index_test2_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test2_history_on_master_id ON test2_history USING btree (master_id);


--
-- Name: index_test2_history_on_test2_table_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test2_history_on_test2_table_id ON test2_history USING btree (test2_table_id);


--
-- Name: index_test2_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test2_history_on_user_id ON test2_history USING btree (user_id);


--
-- Name: index_test2s_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test2s_on_admin_id ON test2s USING btree (admin_id);


--
-- Name: index_test2s_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test2s_on_master_id ON test2s USING btree (master_id);


--
-- Name: index_test2s_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test2s_on_user_id ON test2s USING btree (user_id);


--
-- Name: index_test_2_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_2_history_on_admin_id ON test_2_history USING btree (admin_id);


--
-- Name: index_test_2_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_2_history_on_master_id ON test_2_history USING btree (master_id);


--
-- Name: index_test_2_history_on_test_2_table_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_2_history_on_test_2_table_id ON test_2_history USING btree (test_2_table_id);


--
-- Name: index_test_2_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_2_history_on_user_id ON test_2_history USING btree (user_id);


--
-- Name: index_test_2s_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_2s_on_admin_id ON test_2s USING btree (admin_id);


--
-- Name: index_test_2s_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_2s_on_master_id ON test_2s USING btree (master_id);


--
-- Name: index_test_2s_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_2s_on_user_id ON test_2s USING btree (user_id);


--
-- Name: index_test_ext2_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_ext2_history_on_master_id ON test_ext2_history USING btree (master_id);


--
-- Name: index_test_ext2_history_on_test_ext2_table_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_ext2_history_on_test_ext2_table_id ON test_ext2_history USING btree (test_ext2_table_id);


--
-- Name: index_test_ext2_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_ext2_history_on_user_id ON test_ext2_history USING btree (user_id);


--
-- Name: index_test_ext2s_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_ext2s_on_master_id ON test_ext2s USING btree (master_id);


--
-- Name: index_test_ext2s_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_ext2s_on_user_id ON test_ext2s USING btree (user_id);


--
-- Name: index_test_ext_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_ext_history_on_master_id ON test_ext_history USING btree (master_id);


--
-- Name: index_test_ext_history_on_test_ext_table_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_ext_history_on_test_ext_table_id ON test_ext_history USING btree (test_ext_table_id);


--
-- Name: index_test_ext_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_ext_history_on_user_id ON test_ext_history USING btree (user_id);


--
-- Name: index_test_exts_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_exts_on_master_id ON test_exts USING btree (master_id);


--
-- Name: index_test_exts_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_exts_on_user_id ON test_exts USING btree (user_id);


--
-- Name: index_test_item_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_item_history_on_master_id ON test_item_history USING btree (master_id);


--
-- Name: index_test_item_history_on_test_item_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_item_history_on_test_item_id ON test_item_history USING btree (test_item_id);


--
-- Name: index_test_item_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_item_history_on_user_id ON test_item_history USING btree (user_id);


--
-- Name: index_test_items_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_items_on_master_id ON test_items USING btree (master_id);


--
-- Name: index_test_items_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_test_items_on_user_id ON test_items USING btree (user_id);


--
-- Name: index_tracker_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_master_id ON tracker_history USING btree (master_id);


--
-- Name: index_tracker_history_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_protocol_event_id ON tracker_history USING btree (protocol_event_id);


--
-- Name: index_tracker_history_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_protocol_id ON tracker_history USING btree (protocol_id);


--
-- Name: index_tracker_history_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_sub_process_id ON tracker_history USING btree (sub_process_id);


--
-- Name: index_tracker_history_on_tracker_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_tracker_id ON tracker_history USING btree (tracker_id);


--
-- Name: index_tracker_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_user_id ON tracker_history USING btree (user_id);


--
-- Name: index_trackers_on_master_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_trackers_on_master_id ON trackers USING btree (master_id);


--
-- Name: index_trackers_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_trackers_on_protocol_event_id ON trackers USING btree (protocol_event_id);


--
-- Name: index_trackers_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_trackers_on_protocol_id ON trackers USING btree (protocol_id);


--
-- Name: index_trackers_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_trackers_on_sub_process_id ON trackers USING btree (sub_process_id);


--
-- Name: index_trackers_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_trackers_on_user_id ON trackers USING btree (user_id);


--
-- Name: index_user_access_controls_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_user_access_controls_on_app_type_id ON user_access_controls USING btree (app_type_id);


--
-- Name: index_user_authorization_history_on_user_authorization_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_user_authorization_history_on_user_authorization_id ON user_authorization_history USING btree (user_authorization_id);


--
-- Name: index_user_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_user_history_on_user_id ON user_history USING btree (user_id);


--
-- Name: index_users_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_admin_id ON users USING btree (admin_id);


--
-- Name: index_users_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_app_type_id ON users USING btree (app_type_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: unique_master_protocol; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_master_protocol ON trackers USING btree (master_id, protocol_id);


--
-- Name: unique_master_protocol_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_master_protocol_id ON trackers USING btree (master_id, protocol_id, id);


--
-- Name: unique_protocol_and_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_protocol_and_id ON sub_processes USING btree (protocol_id, id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: unique_sub_process_and_id; Type: INDEX; Schema: ml_app; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_sub_process_and_id ON protocol_events USING btree (sub_process_id, id);


--
-- Name: accuracy_score_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER accuracy_score_history_insert AFTER INSERT ON accuracy_scores FOR EACH ROW EXECUTE PROCEDURE log_accuracy_score_update();


--
-- Name: accuracy_score_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER accuracy_score_history_update AFTER UPDATE ON accuracy_scores FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_accuracy_score_update();


--
-- Name: activity_log_ext_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_ext_assignment_history_insert AFTER INSERT ON activity_log_ext_assignments FOR EACH ROW EXECUTE PROCEDURE log_activity_log_ext_assignment_update();


--
-- Name: activity_log_ext_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_ext_assignment_history_update AFTER UPDATE ON activity_log_ext_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_ext_assignment_update();


--
-- Name: activity_log_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_history_insert AFTER INSERT ON activity_logs FOR EACH ROW EXECUTE PROCEDURE log_activity_log_update();


--
-- Name: activity_log_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_history_update AFTER UPDATE ON activity_logs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_update();


--
-- Name: activity_log_ipa_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_history_insert AFTER INSERT ON activity_log_ipa_assignments FOR EACH ROW EXECUTE PROCEDURE log_activity_log_ipa_assignment_update();


--
-- Name: activity_log_ipa_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_history_update AFTER UPDATE ON activity_log_ipa_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_ipa_assignment_update();


--
-- Name: activity_log_new_test_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_new_test_history_insert AFTER INSERT ON activity_log_new_tests FOR EACH ROW EXECUTE PROCEDURE log_activity_log_new_test_update();


--
-- Name: activity_log_new_test_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_new_test_history_update AFTER UPDATE ON activity_log_new_tests FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_new_test_update();


--
-- Name: activity_log_player_contact_phone_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_player_contact_phone_history_insert AFTER INSERT ON activity_log_player_contact_phones FOR EACH ROW EXECUTE PROCEDURE log_activity_log_player_contact_phone_update();


--
-- Name: activity_log_player_contact_phone_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_player_contact_phone_history_update AFTER UPDATE ON activity_log_player_contact_phones FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_player_contact_phone_update();


--
-- Name: activity_log_player_info_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_player_info_history_insert AFTER INSERT ON activity_log_player_infos FOR EACH ROW EXECUTE PROCEDURE log_activity_log_player_info_update();


--
-- Name: activity_log_player_info_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_player_info_history_update AFTER UPDATE ON activity_log_player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_player_info_update();


--
-- Name: address_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER address_history_insert AFTER INSERT ON addresses FOR EACH ROW EXECUTE PROCEDURE log_address_update();


--
-- Name: address_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER address_history_update AFTER UPDATE ON addresses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_address_update();


--
-- Name: address_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER address_insert BEFORE INSERT ON addresses FOR EACH ROW EXECUTE PROCEDURE handle_address_update();


--
-- Name: address_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER address_update BEFORE UPDATE ON addresses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_address_update();


--
-- Name: admin_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER admin_history_insert AFTER INSERT ON admins FOR EACH ROW EXECUTE PROCEDURE log_admin_update();


--
-- Name: admin_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER admin_history_update AFTER UPDATE ON admins FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_admin_update();


--
-- Name: college_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER college_history_insert AFTER INSERT ON colleges FOR EACH ROW EXECUTE PROCEDURE log_college_update();


--
-- Name: college_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER college_history_update AFTER UPDATE ON colleges FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_college_update();


--
-- Name: dynamic_model_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER dynamic_model_history_insert AFTER INSERT ON dynamic_models FOR EACH ROW EXECUTE PROCEDURE log_dynamic_model_update();


--
-- Name: dynamic_model_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER dynamic_model_history_update AFTER UPDATE ON dynamic_models FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_dynamic_model_update();


--
-- Name: ext_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ext_assignment_history_insert AFTER INSERT ON ext_assignments FOR EACH ROW EXECUTE PROCEDURE log_ext_assignment_update();


--
-- Name: ext_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ext_assignment_history_update AFTER UPDATE ON ext_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ext_assignment_update();


--
-- Name: ext_gen_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ext_gen_assignment_history_insert AFTER INSERT ON ext_gen_assignments FOR EACH ROW EXECUTE PROCEDURE log_ext_gen_assignment_update();


--
-- Name: ext_gen_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ext_gen_assignment_history_update AFTER UPDATE ON ext_gen_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ext_gen_assignment_update();


--
-- Name: external_identifier_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER external_identifier_history_insert AFTER INSERT ON external_identifiers FOR EACH ROW EXECUTE PROCEDURE log_external_identifier_update();


--
-- Name: external_identifier_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER external_identifier_history_update AFTER UPDATE ON external_identifiers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_external_identifier_update();


--
-- Name: external_link_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER external_link_history_insert AFTER INSERT ON external_links FOR EACH ROW EXECUTE PROCEDURE log_external_link_update();


--
-- Name: external_link_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER external_link_history_update AFTER UPDATE ON external_links FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_external_link_update();


--
-- Name: general_selection_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER general_selection_history_insert AFTER INSERT ON general_selections FOR EACH ROW EXECUTE PROCEDURE log_general_selection_update();


--
-- Name: general_selection_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER general_selection_history_update AFTER UPDATE ON general_selections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_general_selection_update();


--
-- Name: ipa_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ipa_assignment_history_insert AFTER INSERT ON ipa_assignments FOR EACH ROW EXECUTE PROCEDURE log_ipa_assignment_update();


--
-- Name: ipa_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ipa_assignment_history_update AFTER UPDATE ON ipa_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_assignment_update();


--
-- Name: item_flag_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER item_flag_history_insert AFTER INSERT ON item_flags FOR EACH ROW EXECUTE PROCEDURE log_item_flag_update();


--
-- Name: item_flag_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER item_flag_history_update AFTER UPDATE ON item_flags FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_item_flag_update();


--
-- Name: item_flag_name_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER item_flag_name_history_insert AFTER INSERT ON item_flag_names FOR EACH ROW EXECUTE PROCEDURE log_item_flag_name_update();


--
-- Name: item_flag_name_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER item_flag_name_history_update AFTER UPDATE ON item_flag_names FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_item_flag_name_update();


--
-- Name: new_test_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER new_test_history_insert AFTER INSERT ON new_tests FOR EACH ROW EXECUTE PROCEDURE log_new_test_update();


--
-- Name: new_test_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER new_test_history_update AFTER UPDATE ON new_tests FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_new_test_update();


--
-- Name: player_contact_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_contact_history_insert AFTER INSERT ON player_contacts FOR EACH ROW EXECUTE PROCEDURE log_player_contact_update();


--
-- Name: player_contact_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_contact_history_update AFTER UPDATE ON player_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_player_contact_update();


--
-- Name: player_contact_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_contact_insert BEFORE INSERT ON player_contacts FOR EACH ROW EXECUTE PROCEDURE handle_player_contact_update();


--
-- Name: player_contact_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_contact_update BEFORE UPDATE ON player_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_player_contact_update();


--
-- Name: player_info_before_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_info_before_update BEFORE UPDATE ON player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_player_info_before_update();


--
-- Name: player_info_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_info_history_insert AFTER INSERT ON player_infos FOR EACH ROW EXECUTE PROCEDURE log_player_info_update();


--
-- Name: player_info_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_info_history_update AFTER UPDATE ON player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_player_info_update();


--
-- Name: player_info_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_info_insert AFTER INSERT ON player_infos FOR EACH ROW EXECUTE PROCEDURE update_master_with_player_info();


--
-- Name: player_info_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_info_update AFTER UPDATE ON player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_master_with_player_info();


--
-- Name: pro_info_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER pro_info_insert AFTER INSERT ON pro_infos FOR EACH ROW EXECUTE PROCEDURE update_master_with_pro_info();


--
-- Name: pro_info_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER pro_info_update AFTER UPDATE ON pro_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_master_with_pro_info();


--
-- Name: protocol_event_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER protocol_event_history_insert AFTER INSERT ON protocol_events FOR EACH ROW EXECUTE PROCEDURE log_protocol_event_update();


--
-- Name: protocol_event_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER protocol_event_history_update AFTER UPDATE ON protocol_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_protocol_event_update();


--
-- Name: protocol_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER protocol_history_insert AFTER INSERT ON protocols FOR EACH ROW EXECUTE PROCEDURE log_protocol_update();


--
-- Name: protocol_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER protocol_history_update AFTER UPDATE ON protocols FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_protocol_update();


--
-- Name: rc_cis_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER rc_cis_update BEFORE UPDATE ON rc_stage_cif_copy FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_rc_cis_update();


--
-- Name: report_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER report_history_insert AFTER INSERT ON reports FOR EACH ROW EXECUTE PROCEDURE log_report_update();


--
-- Name: report_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER report_history_update AFTER UPDATE ON reports FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_report_update();


--
-- Name: scantron_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER scantron_history_insert AFTER INSERT ON scantrons FOR EACH ROW EXECUTE PROCEDURE log_scantron_update();


--
-- Name: scantron_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER scantron_history_update AFTER UPDATE ON scantrons FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_scantron_update();


--
-- Name: sub_process_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER sub_process_history_insert AFTER INSERT ON sub_processes FOR EACH ROW EXECUTE PROCEDURE log_sub_process_update();


--
-- Name: sub_process_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER sub_process_history_update AFTER UPDATE ON sub_processes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sub_process_update();


--
-- Name: test1_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test1_history_insert AFTER INSERT ON test1s FOR EACH ROW EXECUTE PROCEDURE log_test1_update();


--
-- Name: test1_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test1_history_update AFTER UPDATE ON test1s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_test1_update();


--
-- Name: test2_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test2_history_insert AFTER INSERT ON test2s FOR EACH ROW EXECUTE PROCEDURE log_test2_update();


--
-- Name: test2_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test2_history_update AFTER UPDATE ON test2s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_test2_update();


--
-- Name: test_2_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_2_history_insert AFTER INSERT ON test_2s FOR EACH ROW EXECUTE PROCEDURE log_test_2_update();


--
-- Name: test_2_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_2_history_update AFTER UPDATE ON test_2s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_test_2_update();


--
-- Name: test_ext2_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_ext2_history_insert AFTER INSERT ON test_ext2s FOR EACH ROW EXECUTE PROCEDURE log_test_ext2_update();


--
-- Name: test_ext2_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_ext2_history_update AFTER UPDATE ON test_ext2s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_test_ext2_update();


--
-- Name: test_ext_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_ext_history_insert AFTER INSERT ON test_exts FOR EACH ROW EXECUTE PROCEDURE log_test_ext_update();


--
-- Name: test_ext_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_ext_history_update AFTER UPDATE ON test_exts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_test_ext_update();


--
-- Name: tracker_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_history_insert AFTER INSERT ON trackers FOR EACH ROW EXECUTE PROCEDURE log_tracker_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_history_update AFTER UPDATE ON trackers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_tracker_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_history_update BEFORE UPDATE ON tracker_history FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_tracker_history_update();


--
-- Name: tracker_record_delete; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_record_delete AFTER DELETE ON tracker_history FOR EACH ROW EXECUTE PROCEDURE handle_delete();


--
-- Name: tracker_upsert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_upsert BEFORE INSERT ON trackers FOR EACH ROW EXECUTE PROCEDURE tracker_upsert();


--
-- Name: user_authorization_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_authorization_history_insert AFTER INSERT ON user_authorizations FOR EACH ROW EXECUTE PROCEDURE log_user_authorization_update();


--
-- Name: user_authorization_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_authorization_history_update AFTER UPDATE ON user_authorizations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_user_authorization_update();


--
-- Name: user_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_history_insert AFTER INSERT ON users FOR EACH ROW EXECUTE PROCEDURE log_user_update();


--
-- Name: user_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_history_update AFTER UPDATE ON users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_user_update();


--
-- Name: fk_accuracy_score_history_accuracy_scores; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY accuracy_score_history
    ADD CONSTRAINT fk_accuracy_score_history_accuracy_scores FOREIGN KEY (accuracy_score_id) REFERENCES accuracy_scores(id);


--
-- Name: fk_activity_log_ext_assignment_history_activity_log_ext_assignm; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_activity_log_ext_assignm FOREIGN KEY (activity_log_ext_assignment_id) REFERENCES activity_log_ext_assignments(id);


--
-- Name: fk_activity_log_ext_assignment_history_ext_assignment_id; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_ext_assignment_id FOREIGN KEY (ext_assignment_id) REFERENCES ext_assignments(id);


--
-- Name: fk_activity_log_ext_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_activity_log_ext_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_activity_log_ipa_assignment_history_activity_log_ipa_assignm; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_activity_log_ipa_assignm FOREIGN KEY (activity_log_ipa_assignment_id) REFERENCES activity_log_ipa_assignments(id);


--
-- Name: fk_activity_log_ipa_assignment_history_ipa_assignment_id; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_ipa_assignment_id FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);


--
-- Name: fk_activity_log_ipa_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_activity_log_ipa_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_activity_log_new_test_history_activity_log_new_tests; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_activity_log_new_tests FOREIGN KEY (activity_log_new_test_id) REFERENCES activity_log_new_tests(id);


--
-- Name: fk_activity_log_new_test_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_activity_log_new_test_history_new_test_id; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_new_test_id FOREIGN KEY (new_test_id) REFERENCES new_tests(id);


--
-- Name: fk_activity_log_new_test_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_activity_log_player_contact_phone_history_activity_log_playe; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_activity_log_playe FOREIGN KEY (activity_log_player_contact_phone_id) REFERENCES activity_log_player_contact_phones(id);


--
-- Name: fk_activity_log_player_contact_phone_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_activity_log_player_contact_phone_history_player_contact_pho; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_player_contact_pho FOREIGN KEY (player_contact_id) REFERENCES player_contacts(id);


--
-- Name: fk_activity_log_player_contact_phone_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_activity_log_player_info_history_activity_log_player_infos; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_activity_log_player_infos FOREIGN KEY (activity_log_player_info_id) REFERENCES activity_log_player_infos(id);


--
-- Name: fk_activity_log_player_info_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_activity_log_player_info_history_player_info_id; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_player_info_id FOREIGN KEY (player_info_id) REFERENCES player_infos(id);


--
-- Name: fk_activity_log_player_info_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_address_history_addresses; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT fk_address_history_addresses FOREIGN KEY (address_id) REFERENCES addresses(id);


--
-- Name: fk_address_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT fk_address_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_address_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT fk_address_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_admin_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY admin_history
    ADD CONSTRAINT fk_admin_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_college_history_colleges; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY college_history
    ADD CONSTRAINT fk_college_history_colleges FOREIGN KEY (college_id) REFERENCES colleges(id);


--
-- Name: fk_dynamic_model_history_dynamic_models; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY dynamic_model_history
    ADD CONSTRAINT fk_dynamic_model_history_dynamic_models FOREIGN KEY (dynamic_model_id) REFERENCES dynamic_models(id);


--
-- Name: fk_ext_assignment_history_ext_assignments; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_assignment_history
    ADD CONSTRAINT fk_ext_assignment_history_ext_assignments FOREIGN KEY (ext_assignment_table_id) REFERENCES ext_assignments(id);


--
-- Name: fk_ext_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_assignment_history
    ADD CONSTRAINT fk_ext_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_ext_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_assignment_history
    ADD CONSTRAINT fk_ext_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_ext_gen_assignment_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_ext_gen_assignment_history_ext_gen_assignments; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_ext_gen_assignments FOREIGN KEY (ext_gen_assignment_table_id) REFERENCES ext_gen_assignments(id);


--
-- Name: fk_ext_gen_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_ext_gen_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_external_link_history_external_links; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY external_link_history
    ADD CONSTRAINT fk_external_link_history_external_links FOREIGN KEY (external_link_id) REFERENCES external_links(id);


--
-- Name: fk_general_selection_history_general_selections; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY general_selection_history
    ADD CONSTRAINT fk_general_selection_history_general_selections FOREIGN KEY (general_selection_id) REFERENCES general_selections(id);


--
-- Name: fk_ipa_assignment_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_ipa_assignment_history_ipa_assignments; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_ipa_assignments FOREIGN KEY (ipa_assignment_table_id) REFERENCES ipa_assignments(id);


--
-- Name: fk_ipa_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_ipa_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_item_flag_history_item_flags; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY item_flag_history
    ADD CONSTRAINT fk_item_flag_history_item_flags FOREIGN KEY (item_flag_id) REFERENCES item_flags(id);


--
-- Name: fk_item_flag_name_history_item_flag_names; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY item_flag_name_history
    ADD CONSTRAINT fk_item_flag_name_history_item_flag_names FOREIGN KEY (item_flag_name_id) REFERENCES item_flag_names(id);


--
-- Name: fk_new_test_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY new_test_history
    ADD CONSTRAINT fk_new_test_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_new_test_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY new_test_history
    ADD CONSTRAINT fk_new_test_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_new_test_history_new_tests; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY new_test_history
    ADD CONSTRAINT fk_new_test_history_new_tests FOREIGN KEY (new_test_table_id) REFERENCES new_tests(id);


--
-- Name: fk_new_test_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY new_test_history
    ADD CONSTRAINT fk_new_test_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_player_contact_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT fk_player_contact_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_player_contact_history_player_contacts; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT fk_player_contact_history_player_contacts FOREIGN KEY (player_contact_id) REFERENCES player_contacts(id);


--
-- Name: fk_player_contact_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT fk_player_contact_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_player_info_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT fk_player_info_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_player_info_history_player_infos; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT fk_player_info_history_player_infos FOREIGN KEY (player_info_id) REFERENCES player_infos(id);


--
-- Name: fk_player_info_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT fk_player_info_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_protocol_event_history_protocol_events; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY protocol_event_history
    ADD CONSTRAINT fk_protocol_event_history_protocol_events FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);


--
-- Name: fk_protocol_history_protocols; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY protocol_history
    ADD CONSTRAINT fk_protocol_history_protocols FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_00b234154d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY masters
    ADD CONSTRAINT fk_rails_00b234154d FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_00f31a00c4; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY app_configurations
    ADD CONSTRAINT fk_rails_00f31a00c4 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_0210618434; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY external_identifier_history
    ADD CONSTRAINT fk_rails_0210618434 FOREIGN KEY (external_identifier_id) REFERENCES external_identifiers(id);


--
-- Name: fk_rails_08e7f66647; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT fk_rails_08e7f66647 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_0a64e1160a; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT fk_rails_0a64e1160a FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_1694bfe639; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_1694bfe639 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_16d57266f7; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_history
    ADD CONSTRAINT fk_rails_16d57266f7 FOREIGN KEY (activity_log_id) REFERENCES activity_logs(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_exts
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_ext2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ext_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_gen_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test1s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_infos
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY new_tests
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_new_tests
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test1s
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY new_tests
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_1fc7475261; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT fk_rails_1fc7475261 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_20667815e3; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT fk_rails_20667815e3 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_22ccfd95e1; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY item_flag_names
    ADD CONSTRAINT fk_rails_22ccfd95e1 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_23cd255bc6; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT fk_rails_23cd255bc6 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_447d125f63; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_447d125f63 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_exts
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_ext2s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ext_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ext_gen_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test1s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_2s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test2s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_infos
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ipa_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY new_tests
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_new_tests
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ipa_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_47b051d356; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_47b051d356 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_48c9e0c5a2; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT fk_rails_48c9e0c5a2 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_49306e4f49; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY colleges
    ADD CONSTRAINT fk_rails_49306e4f49 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_564af80fb6; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT fk_rails_564af80fb6 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_5b0628cf42; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY external_identifier_history
    ADD CONSTRAINT fk_rails_5b0628cf42 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_623e0ca5ac; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_623e0ca5ac FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_647c63b069; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY app_configurations
    ADD CONSTRAINT fk_rails_647c63b069 FOREIGN KEY (app_type_id) REFERENCES app_types(id);


--
-- Name: fk_rails_6a971dc818; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_6a971dc818 FOREIGN KEY (app_type_id) REFERENCES app_types(id);


--
-- Name: fk_rails_6de4fd560d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT fk_rails_6de4fd560d FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_6e050927c2; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_6e050927c2 FOREIGN KEY (tracker_id) REFERENCES trackers(id);


--
-- Name: fk_rails_70c17e88fd; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY accuracy_scores
    ADD CONSTRAINT fk_rails_70c17e88fd FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_7218113eac; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY external_identifiers
    ADD CONSTRAINT fk_rails_7218113eac FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_72b1afe72f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT fk_rails_72b1afe72f FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ext_assignments
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ext_assignment_id) REFERENCES ext_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_player_infos
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (player_info_id) REFERENCES player_infos(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_new_tests
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (new_test_id) REFERENCES new_tests(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY activity_log_ipa_assignments
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);


--
-- Name: fk_rails_7c10a99849; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT fk_rails_7c10a99849 FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_8108e25f83; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY user_access_controls
    ADD CONSTRAINT fk_rails_8108e25f83 FOREIGN KEY (app_type_id) REFERENCES app_types(id);


--
-- Name: fk_rails_83aa075398; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_83aa075398 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_86cecb1e36; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT fk_rails_86cecb1e36 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_8be93bcf4b; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY app_types
    ADD CONSTRAINT fk_rails_8be93bcf4b FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_9513fd1c35; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9513fd1c35 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_971255ec2c; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY sage_assignments
    ADD CONSTRAINT fk_rails_971255ec2c FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_9e92bdfe65; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9e92bdfe65 FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);


--
-- Name: fk_rails_9f5797d684; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9f5797d684 FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_a44670b00a; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT fk_rails_a44670b00a FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_b0a6220067; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY colleges
    ADD CONSTRAINT fk_rails_b0a6220067 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_b138baacff; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT fk_rails_b138baacff FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_b1e2154c26; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY imports
    ADD CONSTRAINT fk_rails_b1e2154c26 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_b822840dc1; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_b822840dc1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_bb6af37155; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_bb6af37155 FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);


--
-- Name: fk_rails_c2d5bb8930; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT fk_rails_c2d5bb8930 FOREIGN KEY (item_flag_name_id) REFERENCES item_flag_names(id);


--
-- Name: fk_rails_c55341c576; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_c55341c576 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_c9d7977c0c; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY masters
    ADD CONSTRAINT fk_rails_c9d7977c0c FOREIGN KEY (pro_info_id) REFERENCES pro_infos(id);


--
-- Name: fk_rails_d3c0ddde90; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT fk_rails_d3c0ddde90 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_dce5169cfd; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT fk_rails_dce5169cfd FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_deec8fcb38; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY dynamic_models
    ADD CONSTRAINT fk_rails_deec8fcb38 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_e3c559b547; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY sage_assignments
    ADD CONSTRAINT fk_rails_e3c559b547 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_ebab73db27; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY sage_assignments
    ADD CONSTRAINT fk_rails_ebab73db27 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_ebf3863277; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY external_links
    ADD CONSTRAINT fk_rails_ebf3863277 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_f0ac516fff; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY app_configurations
    ADD CONSTRAINT fk_rails_f0ac516fff FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_f62500107f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY general_selections
    ADD CONSTRAINT fk_rails_f62500107f FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_report_history_reports; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY report_history
    ADD CONSTRAINT fk_report_history_reports FOREIGN KEY (report_id) REFERENCES reports(id);


--
-- Name: fk_scantron_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT fk_scantron_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_scantron_history_scantrons; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT fk_scantron_history_scantrons FOREIGN KEY (scantron_table_id) REFERENCES scantrons(id);


--
-- Name: fk_scantron_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT fk_scantron_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_sub_process_history_sub_processes; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY sub_process_history
    ADD CONSTRAINT fk_sub_process_history_sub_processes FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_test1_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test1_history
    ADD CONSTRAINT fk_test1_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_test1_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test1_history
    ADD CONSTRAINT fk_test1_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_test1_history_test1s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test1_history
    ADD CONSTRAINT fk_test1_history_test1s FOREIGN KEY (test1_table_id) REFERENCES test1s(id);


--
-- Name: fk_test1_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test1_history
    ADD CONSTRAINT fk_test1_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_test2_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test2_history
    ADD CONSTRAINT fk_test2_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_test2_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test2_history
    ADD CONSTRAINT fk_test2_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_test2_history_test2s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test2_history
    ADD CONSTRAINT fk_test2_history_test2s FOREIGN KEY (test2_table_id) REFERENCES test2s(id);


--
-- Name: fk_test2_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test2_history
    ADD CONSTRAINT fk_test2_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_test_2_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_2_history
    ADD CONSTRAINT fk_test_2_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_test_2_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_2_history
    ADD CONSTRAINT fk_test_2_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_test_2_history_test_2s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_2_history
    ADD CONSTRAINT fk_test_2_history_test_2s FOREIGN KEY (test_2_table_id) REFERENCES test_2s(id);


--
-- Name: fk_test_2_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_2_history
    ADD CONSTRAINT fk_test_2_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_test_ext2_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_ext2_history
    ADD CONSTRAINT fk_test_ext2_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_test_ext2_history_test_ext2s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_ext2_history
    ADD CONSTRAINT fk_test_ext2_history_test_ext2s FOREIGN KEY (test_ext2_table_id) REFERENCES test_ext2s(id);


--
-- Name: fk_test_ext2_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_ext2_history
    ADD CONSTRAINT fk_test_ext2_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_test_ext_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_ext_history
    ADD CONSTRAINT fk_test_ext_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_test_ext_history_test_exts; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_ext_history
    ADD CONSTRAINT fk_test_ext_history_test_exts FOREIGN KEY (test_ext_table_id) REFERENCES test_exts(id);


--
-- Name: fk_test_ext_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY test_ext_history
    ADD CONSTRAINT fk_test_ext_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_user_authorization_history_user_authorizations; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY user_authorization_history
    ADD CONSTRAINT fk_user_authorization_history_user_authorizations FOREIGN KEY (user_authorization_id) REFERENCES user_authorizations(id);


--
-- Name: fk_user_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY user_history
    ADD CONSTRAINT fk_user_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: rc_cis_master_id_fkey; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY rc_cis
    ADD CONSTRAINT rc_cis_master_id_fkey FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: unique_master_protocol_tracker_id; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT unique_master_protocol_tracker_id FOREIGN KEY (master_id, protocol_id, tracker_id) REFERENCES trackers(master_id, protocol_id, id);


--
-- Name: valid_protocol_sub_process; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT valid_protocol_sub_process FOREIGN KEY (protocol_id, sub_process_id) REFERENCES sub_processes(protocol_id, id) MATCH FULL;


--
-- Name: valid_protocol_sub_process; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT valid_protocol_sub_process FOREIGN KEY (protocol_id, sub_process_id) REFERENCES sub_processes(protocol_id, id) MATCH FULL;


--
-- Name: valid_sub_process_event; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT valid_sub_process_event FOREIGN KEY (sub_process_id, protocol_event_id) REFERENCES protocol_events(sub_process_id, id);


--
-- Name: valid_sub_process_event; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT valid_sub_process_event FOREIGN KEY (sub_process_id, protocol_event_id) REFERENCES protocol_events(sub_process_id, id);


--
-- PostgreSQL database dump complete
--

SET search_path TO ml_app;

INSERT INTO schema_migrations (version) VALUES ('20150602181200');

INSERT INTO schema_migrations (version) VALUES ('20150602181229');

INSERT INTO schema_migrations (version) VALUES ('20150602181400');

INSERT INTO schema_migrations (version) VALUES ('20150602181925');

INSERT INTO schema_migrations (version) VALUES ('20150602205642');

INSERT INTO schema_migrations (version) VALUES ('20150603135202');

INSERT INTO schema_migrations (version) VALUES ('20150603153758');

INSERT INTO schema_migrations (version) VALUES ('20150603170429');

INSERT INTO schema_migrations (version) VALUES ('20150604160659');

INSERT INTO schema_migrations (version) VALUES ('20150609140033');

INSERT INTO schema_migrations (version) VALUES ('20150609150931');

INSERT INTO schema_migrations (version) VALUES ('20150609160545');

INSERT INTO schema_migrations (version) VALUES ('20150609161656');

INSERT INTO schema_migrations (version) VALUES ('20150609185229');

INSERT INTO schema_migrations (version) VALUES ('20150609185749');

INSERT INTO schema_migrations (version) VALUES ('20150609190556');

INSERT INTO schema_migrations (version) VALUES ('20150610142403');

INSERT INTO schema_migrations (version) VALUES ('20150610143629');

INSERT INTO schema_migrations (version) VALUES ('20150610155810');

INSERT INTO schema_migrations (version) VALUES ('20150610160257');

INSERT INTO schema_migrations (version) VALUES ('20150610183502');

INSERT INTO schema_migrations (version) VALUES ('20150610220253');

INSERT INTO schema_migrations (version) VALUES ('20150610220320');

INSERT INTO schema_migrations (version) VALUES ('20150610220451');

INSERT INTO schema_migrations (version) VALUES ('20150611144834');

INSERT INTO schema_migrations (version) VALUES ('20150611145259');

INSERT INTO schema_migrations (version) VALUES ('20150611180303');

INSERT INTO schema_migrations (version) VALUES ('20150611202453');

INSERT INTO schema_migrations (version) VALUES ('20150616202753');

INSERT INTO schema_migrations (version) VALUES ('20150616202829');

INSERT INTO schema_migrations (version) VALUES ('20150618143506');

INSERT INTO schema_migrations (version) VALUES ('20150618161857');

INSERT INTO schema_migrations (version) VALUES ('20150618161945');

INSERT INTO schema_migrations (version) VALUES ('20150619165405');

INSERT INTO schema_migrations (version) VALUES ('20150622144725');

INSERT INTO schema_migrations (version) VALUES ('20150623191520');

INSERT INTO schema_migrations (version) VALUES ('20150623194212');

INSERT INTO schema_migrations (version) VALUES ('20150625213040');

INSERT INTO schema_migrations (version) VALUES ('20150626190344');

INSERT INTO schema_migrations (version) VALUES ('20150629210656');

INSERT INTO schema_migrations (version) VALUES ('20150630202829');

INSERT INTO schema_migrations (version) VALUES ('20150702200308');

INSERT INTO schema_migrations (version) VALUES ('20150707142702');

INSERT INTO schema_migrations (version) VALUES ('20150707143233');

INSERT INTO schema_migrations (version) VALUES ('20150707150524');

INSERT INTO schema_migrations (version) VALUES ('20150707150615');

INSERT INTO schema_migrations (version) VALUES ('20150707150921');

INSERT INTO schema_migrations (version) VALUES ('20150707151004');

INSERT INTO schema_migrations (version) VALUES ('20150707151010');

INSERT INTO schema_migrations (version) VALUES ('20150707151032');

INSERT INTO schema_migrations (version) VALUES ('20150707151129');

INSERT INTO schema_migrations (version) VALUES ('20150707153720');

INSERT INTO schema_migrations (version) VALUES ('20150707222630');

INSERT INTO schema_migrations (version) VALUES ('20150710135307');

INSERT INTO schema_migrations (version) VALUES ('20150710135959');

INSERT INTO schema_migrations (version) VALUES ('20150710160209');

INSERT INTO schema_migrations (version) VALUES ('20150710160215');

INSERT INTO schema_migrations (version) VALUES ('20150715181110');

INSERT INTO schema_migrations (version) VALUES ('20150720141845');

INSERT INTO schema_migrations (version) VALUES ('20150720173900');

INSERT INTO schema_migrations (version) VALUES ('20150720175827');

INSERT INTO schema_migrations (version) VALUES ('20150721204937');

INSERT INTO schema_migrations (version) VALUES ('20150724165441');

INSERT INTO schema_migrations (version) VALUES ('20150727164955');

INSERT INTO schema_migrations (version) VALUES ('20150728133359');

INSERT INTO schema_migrations (version) VALUES ('20150728203820');

INSERT INTO schema_migrations (version) VALUES ('20150728213254');

INSERT INTO schema_migrations (version) VALUES ('20150728213551');

INSERT INTO schema_migrations (version) VALUES ('20150729182424');

INSERT INTO schema_migrations (version) VALUES ('20150730174055');

INSERT INTO schema_migrations (version) VALUES ('20150730181206');

INSERT INTO schema_migrations (version) VALUES ('20150730202422');

INSERT INTO schema_migrations (version) VALUES ('20150803181029');

INSERT INTO schema_migrations (version) VALUES ('20150803194546');

INSERT INTO schema_migrations (version) VALUES ('20150803194551');

INSERT INTO schema_migrations (version) VALUES ('20150804160523');

INSERT INTO schema_migrations (version) VALUES ('20150804203710');

INSERT INTO schema_migrations (version) VALUES ('20150805132950');

INSERT INTO schema_migrations (version) VALUES ('20150805161302');

INSERT INTO schema_migrations (version) VALUES ('20150805200932');

INSERT INTO schema_migrations (version) VALUES ('20150811174323');

INSERT INTO schema_migrations (version) VALUES ('20150812194032');

INSERT INTO schema_migrations (version) VALUES ('20150820151214');

INSERT INTO schema_migrations (version) VALUES ('20150820151728');

INSERT INTO schema_migrations (version) VALUES ('20150820152721');

INSERT INTO schema_migrations (version) VALUES ('20150820155555');

INSERT INTO schema_migrations (version) VALUES ('20150826145029');

INSERT INTO schema_migrations (version) VALUES ('20150826145125');

INSERT INTO schema_migrations (version) VALUES ('20150924163412');

INSERT INTO schema_migrations (version) VALUES ('20150924183936');

INSERT INTO schema_migrations (version) VALUES ('20151005143945');

INSERT INTO schema_migrations (version) VALUES ('20151009191559');

INSERT INTO schema_migrations (version) VALUES ('20151013191910');

INSERT INTO schema_migrations (version) VALUES ('20151015142035');

INSERT INTO schema_migrations (version) VALUES ('20151015150733');

INSERT INTO schema_migrations (version) VALUES ('20151015183136');

INSERT INTO schema_migrations (version) VALUES ('20151016160248');

INSERT INTO schema_migrations (version) VALUES ('20151019203248');

INSERT INTO schema_migrations (version) VALUES ('20151019204910');

INSERT INTO schema_migrations (version) VALUES ('20151020145339');

INSERT INTO schema_migrations (version) VALUES ('20151021162145');

INSERT INTO schema_migrations (version) VALUES ('20151021171534');

INSERT INTO schema_migrations (version) VALUES ('20151022142507');

INSERT INTO schema_migrations (version) VALUES ('20151022191658');

INSERT INTO schema_migrations (version) VALUES ('20151023171217');

INSERT INTO schema_migrations (version) VALUES ('20151026181305');

INSERT INTO schema_migrations (version) VALUES ('20151028145802');

INSERT INTO schema_migrations (version) VALUES ('20151028155426');

INSERT INTO schema_migrations (version) VALUES ('20151109223309');

INSERT INTO schema_migrations (version) VALUES ('20151120150828');

INSERT INTO schema_migrations (version) VALUES ('20151120151912');

INSERT INTO schema_migrations (version) VALUES ('20151123203524');

INSERT INTO schema_migrations (version) VALUES ('20151124151501');

INSERT INTO schema_migrations (version) VALUES ('20151125192206');

INSERT INTO schema_migrations (version) VALUES ('20151202180745');

INSERT INTO schema_migrations (version) VALUES ('20151208144918');

INSERT INTO schema_migrations (version) VALUES ('20151208200918');

INSERT INTO schema_migrations (version) VALUES ('20151208200919');

INSERT INTO schema_migrations (version) VALUES ('20151208200920');

INSERT INTO schema_migrations (version) VALUES ('20151208244916');

INSERT INTO schema_migrations (version) VALUES ('20151208244917');

INSERT INTO schema_migrations (version) VALUES ('20151208244918');

INSERT INTO schema_migrations (version) VALUES ('20151215165127');

INSERT INTO schema_migrations (version) VALUES ('20151215170733');

INSERT INTO schema_migrations (version) VALUES ('20151216102328');

INSERT INTO schema_migrations (version) VALUES ('20151218203119');

INSERT INTO schema_migrations (version) VALUES ('20160203120436');

INSERT INTO schema_migrations (version) VALUES ('20160203121701');

INSERT INTO schema_migrations (version) VALUES ('20160203130714');

INSERT INTO schema_migrations (version) VALUES ('20160203151737');

INSERT INTO schema_migrations (version) VALUES ('20160203211330');

INSERT INTO schema_migrations (version) VALUES ('20160204120512');

INSERT INTO schema_migrations (version) VALUES ('20160210200918');

INSERT INTO schema_migrations (version) VALUES ('20160210200919');

INSERT INTO schema_migrations (version) VALUES ('20170823145313');

INSERT INTO schema_migrations (version) VALUES ('20170830100037');

INSERT INTO schema_migrations (version) VALUES ('20170830105123');

INSERT INTO schema_migrations (version) VALUES ('20170901152707');

INSERT INTO schema_migrations (version) VALUES ('20170908074038');

INSERT INTO schema_migrations (version) VALUES ('20170922182052');

INSERT INTO schema_migrations (version) VALUES ('20170926144234');

INSERT INTO schema_migrations (version) VALUES ('20171002120537');

INSERT INTO schema_migrations (version) VALUES ('20171013141835');

INSERT INTO schema_migrations (version) VALUES ('20171013141837');

INSERT INTO schema_migrations (version) VALUES ('20171025095942');

INSERT INTO schema_migrations (version) VALUES ('20171031145807');

INSERT INTO schema_migrations (version) VALUES ('20171207163040');

INSERT INTO schema_migrations (version) VALUES ('20171207170748');

INSERT INTO schema_migrations (version) VALUES ('20180119173411');

INSERT INTO schema_migrations (version) VALUES ('20180123111956');

INSERT INTO schema_migrations (version) VALUES ('20180123154108');

INSERT INTO schema_migrations (version) VALUES ('20180126120818');

INSERT INTO schema_migrations (version) VALUES ('20180206173516');

INSERT INTO schema_migrations (version) VALUES ('20180209145336');

INSERT INTO schema_migrations (version) VALUES ('20180209152723');

INSERT INTO schema_migrations (version) VALUES ('20180209152747');

INSERT INTO schema_migrations (version) VALUES ('20180209171641');

