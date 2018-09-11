--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.6
-- Dumped by pg_dump version 10.5 (Ubuntu 10.5-1.pgdg16.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ml_app_zeus_full; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ml_app_zeus_full;


--
-- Name: add_study_update_entry(integer, character varying, character varying, date, character varying, integer, integer, character varying); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.add_study_update_entry(master_id integer, update_type character varying, update_name character varying, event_date date, update_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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
-- Name: add_tracker_entry_by_name(integer, character varying, character varying, character varying, character varying, integer, integer, character varying); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.add_tracker_entry_by_name(master_id integer, protocol_name character varying, sub_process_name character varying, protocol_event_name character varying, set_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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
-- Name: add_tracker_entry_by_name(integer, character varying, character varying, character varying, date, character varying, integer, integer, character varying); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.add_tracker_entry_by_name(master_id integer, protocol_name character varying, sub_process_name character varying, protocol_event_name character varying, event_date date, set_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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
-- Name: assign_sage_ids_to_players(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.assign_sage_ids_to_players() RETURNS record
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
-- Name: create_message_notification_email(character varying, character varying, character varying, json, character varying[], character varying, timestamp without time zone); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.create_message_notification_email(layout_template_name character varying, content_template_name character varying, subject character varying, data json, recipient_emails character varying[], from_user_email character varying, run_at timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      last_id INTEGER;
    BEGIN

      IF run_at IS NULL THEN
        run_at := now();
      END IF;

      INSERT INTO ml_app.message_notifications
      (
        message_type,
        created_at,
        updated_at,
        layout_template_name,
        content_template_name,
        subject,
        data,
        recipient_emails,
        from_user_email
      )
      VALUES
      (
        'email',
        now(),
        now(),
        layout_template_name,
        content_template_name,
        subject,
        data,
        recipient_emails,
        from_user_email
      )
      RETURNING id
      INTO last_id
      ;

      SELECT create_message_notification_job(last_id, run_at)
      INTO last_id
      ;

      RETURN last_id;
    END;
    $$;


--
-- Name: create_message_notification_email(integer, integer, integer, character varying, integer, integer[], character varying, character varying, character varying, timestamp without time zone); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.create_message_notification_email(app_type_id integer, master_id integer, item_id integer, item_type character varying, user_id integer, recipient_user_ids integer[], layout_template_name character varying, content_template_name character varying, subject character varying, run_at timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      last_id INTEGER;
    BEGIN

      IF run_at IS NULL THEN
        run_at := now();
      END IF;

      INSERT INTO ml_app.message_notifications
      (
        subject,
        app_type_id,
        user_id,
        recipient_user_ids,
        layout_template_name,
        content_template_name,
        item_type,
        item_id,
        master_id,
        message_type,
        created_at,
        updated_at
      )
      VALUES
      (
        subject,
        app_type_id,
        user_id,
        recipient_user_ids,
        layout_template_name,
        content_template_name,
        item_type,
        item_id,
        master_id,
        'email',
        now(),
        now()
      )
      RETURNING id
      INTO last_id
      ;

      SELECT create_message_notification_job(last_id, run_at)
      INTO last_id
      ;

      RETURN last_id;
    END;
    $$;


--
-- Name: create_message_notification_job(integer, timestamp without time zone); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.create_message_notification_job(message_notification_id integer, run_at timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      last_id INTEGER;
    BEGIN

      IF run_at IS NULL THEN
        run_at := now();
      END IF;

      INSERT INTO ml_app.delayed_jobs
      (
        priority,
        attempts,
        handler,
        run_at,
        queue,
        created_at,
        updated_at
      )
      VALUES
      (
        0,
        0,
        '--- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
        job_data:
          job_class: HandleMessageNotificationJob
          job_id: ' || gen_random_uuid() || '
          queue_name: default
          arguments:
          - _aj_globalid: gid://fpa1/MessageNotification/' || message_notification_id::varchar || '
          locale: :en',
        run_at,
        'default',
        now(),
        now()
      )
      RETURNING id
      INTO last_id
      ;

    	RETURN last_id;
    END;
    $$;


--
-- Name: current_user_id(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.current_user_id() RETURNS integer
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
-- Name: format_update_notes(character varying, character varying, character varying); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.format_update_notes(field_name character varying, old_val character varying, new_val character varying) RETURNS character varying
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
-- Name: handle_address_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.handle_address_update() RETURNS trigger
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
-- Name: handle_delete(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.handle_delete() RETURNS trigger
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
-- Name: handle_player_contact_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.handle_player_contact_update() RETURNS trigger
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
-- Name: handle_player_info_before_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.handle_player_info_before_update() RETURNS trigger
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
-- Name: handle_rc_cis_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.handle_rc_cis_update() RETURNS trigger
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
-- Name: handle_tracker_history_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.handle_tracker_history_update() RETURNS trigger
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
-- Name: log_accuracy_score_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_accuracy_score_update() RETURNS trigger
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
-- Name: log_activity_log_bhs_assignment_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_activity_log_bhs_assignment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_bhs_assignment_history
                  (
                      master_id,
                      bhs_assignment_id,
                      select_record_from_player_contact_phones,
                      return_call_availability_notes,
                      questions_from_call_notes,
                      results_link,
                      select_result,
                      pi_notes_from_return_call,
                      completed_q1_no_yes,
                      completed_teamstudy_no_yes,
                      previous_contact_with_team_no_yes,
                      previous_contact_with_team_notes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_bhs_assignment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.bhs_assignment_id,
                      NEW.select_record_from_player_contact_phones,
                      NEW.return_call_availability_notes,
                      NEW.questions_from_call_notes,
                      NEW.results_link,
                      NEW.select_result,
                      NEW.pi_notes_from_return_call,
                      NEW.completed_q1_no_yes,
                      NEW.completed_teamstudy_no_yes,
                      NEW.previous_contact_with_team_no_yes,
                      NEW.previous_contact_with_team_notes,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_activity_log_ext_assignment_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_activity_log_ext_assignment_update() RETURNS trigger
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
-- Name: log_activity_log_ipa_assignment_minor_deviation_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_activity_log_ipa_assignment_minor_deviation_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_minor_deviation_history
                  (
                      master_id,
                      ipa_assignment_id,
                      activity_date,
                      deviation_discovered_when,
                      deviation_occurred_when,
                      deviation_description,
                      corrective_action_description,
                      select_status,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_minor_deviation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.activity_date,
                      NEW.deviation_discovered_when,
                      NEW.deviation_occurred_when,
                      NEW.deviation_description,
                      NEW.corrective_action_description,
                      NEW.select_status,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_activity_log_ipa_assignment_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_activity_log_ipa_assignment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_history
                  (
                      master_id,
                      ipa_assignment_id,
                      select_activity,
                      activity_date,
                      select_record_from_player_contacts,
                      select_direction,
                      select_who,
                      select_result,
                      select_next_step,
                      follow_up_when,
                      notes,
                      protocol_id,
                      select_record_from_addresses,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.select_activity,
                      NEW.activity_date,
                      NEW.select_record_from_player_contacts,
                      NEW.select_direction,
                      NEW.select_who,
                      NEW.select_result,
                      NEW.select_next_step,
                      NEW.follow_up_when,
                      NEW.notes,
                      NEW.protocol_id,
                      NEW.select_record_from_addresses,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_activity_log_ipa_survey_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_activity_log_ipa_survey_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_survey_history
                  (
                      master_id,
                      ipa_survey_id,
                      screened_by_who,
                      screening_date,
                      select_status,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_survey_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_survey_id,
                      NEW.screened_by_who,
                      NEW.screening_date,
                      NEW.select_status,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_activity_log_new_test_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_activity_log_new_test_update() RETURNS trigger
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
-- Name: log_activity_log_player_contact_phone_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_activity_log_player_contact_phone_update() RETURNS trigger
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
                        extra_log_type,
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
                        NEW.extra_log_type,
                        NEW.user_id,
                        NEW.created_at,
                        NEW.updated_at,
                        NEW.id
                    ;
                    RETURN NEW;
                END;
            $$;


--
-- Name: log_activity_log_player_info_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_activity_log_player_info_update() RETURNS trigger
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
-- Name: log_activity_log_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_activity_log_update() RETURNS trigger
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
-- Name: log_address_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_address_update() RETURNS trigger
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
-- Name: log_admin_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_admin_update() RETURNS trigger
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
-- Name: log_bhs_assignment_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_bhs_assignment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO bhs_assignment_history
                  (
                      master_id,
                      bhs_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      bhs_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.bhs_id,
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
-- Name: log_college_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_college_update() RETURNS trigger
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
-- Name: log_dynamic_model_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_dynamic_model_update() RETURNS trigger
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
-- Name: log_ext_assignment_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_ext_assignment_update() RETURNS trigger
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
-- Name: log_ext_gen_assignment_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_ext_gen_assignment_update() RETURNS trigger
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
-- Name: log_external_identifier_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_external_identifier_update() RETURNS trigger
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
-- Name: log_external_link_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_external_link_update() RETURNS trigger
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
-- Name: log_general_selection_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_general_selection_update() RETURNS trigger
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
-- Name: log_ipa_appointment_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_ipa_appointment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_appointment_history
                  (
                      master_id,
                      visit_start_date,
                      select_navigator,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_appointment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.visit_start_date,
                      NEW.select_navigator,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_assignment_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_ipa_assignment_update() RETURNS trigger
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
-- Name: log_ipa_consent_mailing_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_ipa_consent_mailing_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_consent_mailing_history
                  (
                      master_id,
                      copy_of_consent_docs_mailed_to_subject_no_yes,
                      mailed_when,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_consent_mailing_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.copy_of_consent_docs_mailed_to_subject_no_yes,
                      NEW.mailed_when,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_hotel_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_ipa_hotel_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_hotel_history
                  (
                      master_id,
                      hotel,
                      room_number,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_hotel_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.hotel,
                      NEW.room_number,
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
-- Name: log_ipa_payment_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_ipa_payment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_payment_history
                  (
                      master_id,
                      select_type,
                      sent_date,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_payment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_type,
                      NEW.sent_date,
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
-- Name: log_ipa_screening_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_ipa_screening_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_screening_history
                  (
                      master_id,
                      screening_date,
                      eligible_for_study_blank_yes_no,
                      select_reason_if_not_eligible,
                      select_status,
                      select_subject_withdrew_reason,
                      select_investigator_terminated,
                      lost_to_follow_up_no_yes,
                      no_longer_participating_no_yes,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_screening_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.screening_date,
                      NEW.eligible_for_study_blank_yes_no,
                      NEW.select_reason_if_not_eligible,
                      NEW.select_status,
                      NEW.select_subject_withdrew_reason,
                      NEW.select_investigator_terminated,
                      NEW.lost_to_follow_up_no_yes,
                      NEW.no_longer_participating_no_yes,
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
-- Name: log_ipa_survey_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_ipa_survey_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_survey_history
                  (
                      master_id,
                      select_survey_type,
                      sent_date,
                      completed_date,
                      send_next_survey_when,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_survey_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_survey_type,
                      NEW.sent_date,
                      NEW.completed_date,
                      NEW.send_next_survey_when,
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
-- Name: log_ipa_transportation_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_ipa_transportation_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_transportation_history
                  (
                      master_id,
                      travel_date,
                      travel_confirmed_no_yes,
                      select_direction,
                      origin_city_and_state,
                      destination_city_and_state,
                      select_mode_of_transport,
                      airline,
                      flight_number,
                      departure_time,
                      arrival_time,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_transportation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.travel_date,
                      NEW.travel_confirmed_no_yes,
                      NEW.select_direction,
                      NEW.origin_city_and_state,
                      NEW.destination_city_and_state,
                      NEW.select_mode_of_transport,
                      NEW.airline,
                      NEW.flight_number,
                      NEW.departure_time,
                      NEW.arrival_time,
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
-- Name: log_item_flag_name_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_item_flag_name_update() RETURNS trigger
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
-- Name: log_item_flag_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_item_flag_update() RETURNS trigger
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
-- Name: log_mrn_number_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_mrn_number_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO mrn_number_history
                  (
                      master_id,
                      mrn_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      mrn_number_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.mrn_id,
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
-- Name: log_new_test_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_new_test_update() RETURNS trigger
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
-- Name: log_player_contact_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_player_contact_update() RETURNS trigger
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
-- Name: log_player_info_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_player_info_update() RETURNS trigger
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
-- Name: log_protocol_event_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_protocol_event_update() RETURNS trigger
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
-- Name: log_protocol_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_protocol_update() RETURNS trigger
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
-- Name: log_report_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_report_update() RETURNS trigger
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
-- Name: log_sage_two_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_sage_two_update() RETURNS trigger
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
-- Name: log_scantron_series_two_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_scantron_series_two_update() RETURNS trigger
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
-- Name: log_scantron_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_scantron_update() RETURNS trigger
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
-- Name: log_social_security_number_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_social_security_number_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO social_security_number_history
                  (
                      master_id,
                      ssn_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      social_security_number_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ssn_id,
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
-- Name: log_sub_process_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_sub_process_update() RETURNS trigger
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
-- Name: log_test1_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_test1_update() RETURNS trigger
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
-- Name: log_test2_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_test2_update() RETURNS trigger
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
-- Name: log_test_2_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_test_2_update() RETURNS trigger
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
-- Name: log_test_ext2_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_test_ext2_update() RETURNS trigger
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
-- Name: log_test_ext_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_test_ext_update() RETURNS trigger
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
-- Name: log_test_item_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_test_item_update() RETURNS trigger
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
-- Name: log_tracker_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_tracker_update() RETURNS trigger
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
-- Name: log_user_authorization_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_user_authorization_update() RETURNS trigger
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
-- Name: log_user_update(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.log_user_update() RETURNS trigger
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
        admin_id,
        app_type_id

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
        NEW.admin_id,
        NEW.app_type_id
                ;
                RETURN NEW;
            END;
        $$;


--
-- Name: tracker_upsert(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.tracker_upsert() RETURNS trigger
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
-- Name: update_address_ranks(integer); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.update_address_ranks(set_master_id integer) RETURNS integer
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
-- Name: update_master_with_player_info(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.update_master_with_player_info() RETURNS trigger
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
-- Name: update_master_with_pro_info(); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.update_master_with_pro_info() RETURNS trigger
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
-- Name: update_player_contact_ranks(integer, character varying); Type: FUNCTION; Schema: ml_app_zeus_full; Owner: -
--

CREATE FUNCTION ml_app_zeus_full.update_player_contact_ranks(set_master_id integer, set_rec_type character varying) RETURNS integer
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
-- Name: accuracy_score_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.accuracy_score_history (
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
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.accuracy_score_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.accuracy_score_history_id_seq OWNED BY ml_app_zeus_full.accuracy_score_history.id;


--
-- Name: accuracy_scores; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.accuracy_scores (
    id integer NOT NULL,
    name character varying,
    value integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean
);


--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.accuracy_scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.accuracy_scores_id_seq OWNED BY ml_app_zeus_full.accuracy_scores.id;


--
-- Name: activity_log_bhs_assignment_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_bhs_assignment_history (
    id integer NOT NULL,
    master_id integer,
    bhs_assignment_id integer,
    select_record_from_player_contact_phones character varying,
    return_call_availability_notes character varying,
    questions_from_call_notes character varying,
    results_link character varying,
    select_result character varying,
    pi_notes_from_return_call character varying,
    completed_q1_no_yes character varying,
    completed_teamstudy_no_yes character varying,
    previous_contact_with_team_no_yes character varying,
    previous_contact_with_team_notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_bhs_assignment_id integer
);


--
-- Name: activity_log_bhs_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_bhs_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_bhs_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_bhs_assignment_history_id_seq OWNED BY ml_app_zeus_full.activity_log_bhs_assignment_history.id;


--
-- Name: activity_log_bhs_assignments; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_bhs_assignments (
    id integer NOT NULL,
    master_id integer,
    bhs_assignment_id integer,
    select_record_from_player_contact_phones character varying,
    return_call_availability_notes character varying,
    questions_from_call_notes character varying,
    results_link character varying,
    select_result character varying,
    pi_notes_from_return_call character varying,
    completed_q1_no_yes character varying,
    completed_teamstudy_no_yes character varying,
    previous_contact_with_team_no_yes character varying,
    previous_contact_with_team_notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_bhs_assignments_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_bhs_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_bhs_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_bhs_assignments_id_seq OWNED BY ml_app_zeus_full.activity_log_bhs_assignments.id;


--
-- Name: activity_log_ext_assignment_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_ext_assignment_history (
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
-- Name: activity_log_ext_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_ext_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ext_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_ext_assignment_history_id_seq OWNED BY ml_app_zeus_full.activity_log_ext_assignment_history.id;


--
-- Name: activity_log_ext_assignments; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_ext_assignments (
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
-- Name: activity_log_ext_assignments_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_ext_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ext_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_ext_assignments_id_seq OWNED BY ml_app_zeus_full.activity_log_ext_assignments.id;


--
-- Name: activity_log_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_history (
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
-- Name: activity_log_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_history_id_seq OWNED BY ml_app_zeus_full.activity_log_history.id;


--
-- Name: activity_log_ipa_assignment_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_ipa_assignment_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    select_activity character varying,
    activity_date date,
    select_record_from_player_contacts character varying,
    select_direction character varying,
    select_who character varying,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    notes character varying,
    protocol_id bigint,
    select_record_from_addresses character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_id integer
);


--
-- Name: activity_log_ipa_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_ipa_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_ipa_assignment_history_id_seq OWNED BY ml_app_zeus_full.activity_log_ipa_assignment_history.id;


--
-- Name: activity_log_ipa_assignment_minor_deviation_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    activity_date date,
    deviation_discovered_when date,
    deviation_occurred_when date,
    deviation_description character varying,
    corrective_action_description character varying,
    select_status character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_minor_deviation_id integer
);


--
-- Name: activity_log_ipa_assignment_minor_deviation_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_minor_deviation_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history_id_seq OWNED BY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history.id;


--
-- Name: activity_log_ipa_assignment_minor_deviations; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    activity_date date,
    deviation_discovered_when date,
    deviation_occurred_when date,
    deviation_description character varying,
    corrective_action_description character varying,
    select_status character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_assignment_minor_deviations_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_minor_deviations_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations_id_seq OWNED BY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations.id;


--
-- Name: activity_log_ipa_assignments; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_ipa_assignments (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    select_activity character varying,
    activity_date date,
    select_record_from_player_contacts character varying,
    select_direction character varying,
    select_who character varying,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    notes character varying,
    protocol_id bigint,
    select_record_from_addresses character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_assignments_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_ipa_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_ipa_assignments_id_seq OWNED BY ml_app_zeus_full.activity_log_ipa_assignments.id;


--
-- Name: activity_log_ipa_survey_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_ipa_survey_history (
    id integer NOT NULL,
    master_id integer,
    ipa_survey_id integer,
    screened_by_who character varying,
    screening_date date,
    select_status character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_survey_id integer
);


--
-- Name: activity_log_ipa_survey_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_ipa_survey_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_survey_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_ipa_survey_history_id_seq OWNED BY ml_app_zeus_full.activity_log_ipa_survey_history.id;


--
-- Name: activity_log_ipa_surveys; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_ipa_surveys (
    id integer NOT NULL,
    master_id integer,
    ipa_survey_id integer,
    screened_by_who character varying,
    screening_date date,
    select_status character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_surveys_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_ipa_surveys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_surveys_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_ipa_surveys_id_seq OWNED BY ml_app_zeus_full.activity_log_ipa_surveys.id;


--
-- Name: activity_log_new_test_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_new_test_history (
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
-- Name: activity_log_new_test_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_new_test_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_new_test_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_new_test_history_id_seq OWNED BY ml_app_zeus_full.activity_log_new_test_history.id;


--
-- Name: activity_log_new_tests; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_new_tests (
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
-- Name: activity_log_new_tests_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_new_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_new_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_new_tests_id_seq OWNED BY ml_app_zeus_full.activity_log_new_tests.id;


--
-- Name: activity_log_player_contact_emails; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_player_contact_emails (
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
-- Name: activity_log_player_contact_emails_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_player_contact_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_contact_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_player_contact_emails_id_seq OWNED BY ml_app_zeus_full.activity_log_player_contact_emails.id;


--
-- Name: activity_log_player_contact_phone_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_player_contact_phone_history (
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
    activity_log_player_contact_phone_id integer,
    extra_log_type character varying
);


--
-- Name: activity_log_player_contact_phone_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_player_contact_phone_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_contact_phone_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_player_contact_phone_history_id_seq OWNED BY ml_app_zeus_full.activity_log_player_contact_phone_history.id;


--
-- Name: activity_log_player_contact_phones; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_player_contact_phones (
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
    set_related_player_contact_rank character varying,
    extra_log_type character varying
);


--
-- Name: activity_log_player_contact_phones_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_player_contact_phones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_contact_phones_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_player_contact_phones_id_seq OWNED BY ml_app_zeus_full.activity_log_player_contact_phones.id;


--
-- Name: activity_log_player_info_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_player_info_history (
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
-- Name: activity_log_player_info_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_player_info_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_info_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_player_info_history_id_seq OWNED BY ml_app_zeus_full.activity_log_player_info_history.id;


--
-- Name: activity_log_player_infos; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_log_player_infos (
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
-- Name: activity_log_player_infos_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_log_player_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_log_player_infos_id_seq OWNED BY ml_app_zeus_full.activity_log_player_infos.id;


--
-- Name: activity_logs; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.activity_logs (
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
    main_log_name character varying,
    process_name character varying,
    table_name character varying
);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.activity_logs_id_seq OWNED BY ml_app_zeus_full.activity_logs.id;


--
-- Name: address_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.address_history (
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
-- Name: address_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.address_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: address_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.address_history_id_seq OWNED BY ml_app_zeus_full.address_history.id;


--
-- Name: addresses; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.addresses (
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
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.addresses_id_seq OWNED BY ml_app_zeus_full.addresses.id;


--
-- Name: admin_action_logs; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.admin_action_logs (
    id integer NOT NULL,
    admin_id integer,
    item_type character varying,
    item_id integer,
    action character varying,
    url character varying,
    prev_value json,
    new_value json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: admin_action_logs_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.admin_action_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_action_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.admin_action_logs_id_seq OWNED BY ml_app_zeus_full.admin_action_logs.id;


--
-- Name: admin_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.admin_history (
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
-- Name: admin_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.admin_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.admin_history_id_seq OWNED BY ml_app_zeus_full.admin_history.id;


--
-- Name: admins; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.admins (
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
-- Name: admins_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.admins_id_seq OWNED BY ml_app_zeus_full.admins.id;


--
-- Name: app_configurations; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.app_configurations (
    id integer NOT NULL,
    name character varying,
    value character varying,
    disabled boolean,
    admin_id integer,
    user_id integer,
    app_type_id integer
);


--
-- Name: app_configurations_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.app_configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.app_configurations_id_seq OWNED BY ml_app_zeus_full.app_configurations.id;


--
-- Name: app_types; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.app_types (
    id integer NOT NULL,
    name character varying,
    label character varying,
    disabled boolean,
    admin_id integer
);


--
-- Name: app_types_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.app_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_types_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.app_types_id_seq OWNED BY ml_app_zeus_full.app_types.id;


--
-- Name: bhs_assignment_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.bhs_assignment_history (
    id integer NOT NULL,
    master_id integer,
    bhs_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    bhs_assignment_table_id integer
);


--
-- Name: bhs_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.bhs_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bhs_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.bhs_assignment_history_id_seq OWNED BY ml_app_zeus_full.bhs_assignment_history.id;


--
-- Name: bhs_assignments; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.bhs_assignments (
    id integer NOT NULL,
    master_id integer,
    bhs_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bhs_assignments_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.bhs_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bhs_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.bhs_assignments_id_seq OWNED BY ml_app_zeus_full.bhs_assignments.id;


--
-- Name: college_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.college_history (
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
-- Name: college_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.college_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: college_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.college_history_id_seq OWNED BY ml_app_zeus_full.college_history.id;


--
-- Name: colleges; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.colleges (
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
-- Name: colleges_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.colleges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: colleges_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.colleges_id_seq OWNED BY ml_app_zeus_full.colleges.id;


--
-- Name: copy_player_infos; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.copy_player_infos (
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
-- Name: delayed_jobs; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.delayed_jobs_id_seq OWNED BY ml_app_zeus_full.delayed_jobs.id;


--
-- Name: dynamic_model_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.dynamic_model_history (
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
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.dynamic_model_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.dynamic_model_history_id_seq OWNED BY ml_app_zeus_full.dynamic_model_history.id;


--
-- Name: dynamic_models; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.dynamic_models (
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
    result_order character varying,
    options character varying
);


--
-- Name: dynamic_models_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.dynamic_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dynamic_models_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.dynamic_models_id_seq OWNED BY ml_app_zeus_full.dynamic_models.id;


--
-- Name: emergency_contacts; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.emergency_contacts (
    id integer NOT NULL,
    rec_type character varying,
    data character varying,
    first_name character varying,
    last_name character varying,
    select_relationship character varying,
    rank character varying,
    user_id integer,
    master_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: emergency_contacts_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.emergency_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emergency_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.emergency_contacts_id_seq OWNED BY ml_app_zeus_full.emergency_contacts.id;


--
-- Name: exception_logs; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.exception_logs (
    id integer NOT NULL,
    message character varying,
    main character varying,
    backtrace character varying,
    user_id integer,
    admin_id integer,
    notified_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: exception_logs_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.exception_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exception_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.exception_logs_id_seq OWNED BY ml_app_zeus_full.exception_logs.id;


--
-- Name: ext_assignment_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ext_assignment_history (
    id integer NOT NULL,
    master_id integer,
    ext_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ext_assignment_table_id integer
);


--
-- Name: ext_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ext_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ext_assignment_history_id_seq OWNED BY ml_app_zeus_full.ext_assignment_history.id;


--
-- Name: ext_assignments; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ext_assignments (
    id integer NOT NULL,
    master_id integer,
    ext_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ext_assignments_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ext_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ext_assignments_id_seq OWNED BY ml_app_zeus_full.ext_assignments.id;


--
-- Name: ext_gen_assignment_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ext_gen_assignment_history (
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
-- Name: ext_gen_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ext_gen_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_gen_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ext_gen_assignment_history_id_seq OWNED BY ml_app_zeus_full.ext_gen_assignment_history.id;


--
-- Name: ext_gen_assignments; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ext_gen_assignments (
    id integer NOT NULL,
    master_id integer,
    ext_gen_id integer,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ext_gen_assignments_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ext_gen_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_gen_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ext_gen_assignments_id_seq OWNED BY ml_app_zeus_full.ext_gen_assignments.id;


--
-- Name: external_identifier_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.external_identifier_history (
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
-- Name: external_identifier_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.external_identifier_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_identifier_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.external_identifier_history_id_seq OWNED BY ml_app_zeus_full.external_identifier_history.id;


--
-- Name: external_identifiers; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.external_identifiers (
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
    alphanumeric boolean
);


--
-- Name: external_identifiers_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.external_identifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_identifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.external_identifiers_id_seq OWNED BY ml_app_zeus_full.external_identifiers.id;


--
-- Name: external_link_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.external_link_history (
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
-- Name: external_link_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.external_link_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_link_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.external_link_history_id_seq OWNED BY ml_app_zeus_full.external_link_history.id;


--
-- Name: external_links; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.external_links (
    id integer NOT NULL,
    name character varying,
    value character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: external_links_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.external_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_links_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.external_links_id_seq OWNED BY ml_app_zeus_full.external_links.id;


--
-- Name: general_selection_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.general_selection_history (
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
-- Name: general_selection_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.general_selection_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: general_selection_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.general_selection_history_id_seq OWNED BY ml_app_zeus_full.general_selection_history.id;


--
-- Name: general_selections; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.general_selections (
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
-- Name: general_selections_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.general_selections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: general_selections_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.general_selections_id_seq OWNED BY ml_app_zeus_full.general_selections.id;


--
-- Name: imports; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.imports (
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
-- Name: imports_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.imports_id_seq OWNED BY ml_app_zeus_full.imports.id;


--
-- Name: ipa_appointment_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_appointment_history (
    id integer NOT NULL,
    master_id integer,
    visit_start_date date,
    select_navigator character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_appointment_id integer
);


--
-- Name: ipa_appointment_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_appointment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_appointment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_appointment_history_id_seq OWNED BY ml_app_zeus_full.ipa_appointment_history.id;


--
-- Name: ipa_appointments; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_appointments (
    id integer NOT NULL,
    master_id integer,
    visit_start_date date,
    select_navigator character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_appointments_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_appointments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_appointments_id_seq OWNED BY ml_app_zeus_full.ipa_appointments.id;


--
-- Name: ipa_assignment_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_assignment_history (
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
-- Name: ipa_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_assignment_history_id_seq OWNED BY ml_app_zeus_full.ipa_assignment_history.id;


--
-- Name: ipa_assignments; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_assignments (
    id integer NOT NULL,
    master_id integer,
    ipa_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_assignments_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_assignments_id_seq OWNED BY ml_app_zeus_full.ipa_assignments.id;


--
-- Name: ipa_consent_mailing_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_consent_mailing_history (
    id integer NOT NULL,
    master_id integer,
    copy_of_consent_docs_mailed_to_subject_no_yes character varying,
    mailed_when date,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_consent_mailing_id integer
);


--
-- Name: ipa_consent_mailing_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_consent_mailing_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_consent_mailing_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_consent_mailing_history_id_seq OWNED BY ml_app_zeus_full.ipa_consent_mailing_history.id;


--
-- Name: ipa_consent_mailings; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_consent_mailings (
    id integer NOT NULL,
    master_id integer,
    copy_of_consent_docs_mailed_to_subject_no_yes character varying,
    mailed_when date,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_consent_mailings_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_consent_mailings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_consent_mailings_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_consent_mailings_id_seq OWNED BY ml_app_zeus_full.ipa_consent_mailings.id;


--
-- Name: ipa_hotel_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_hotel_history (
    id integer NOT NULL,
    master_id integer,
    hotel character varying,
    room_number character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_hotel_id integer
);


--
-- Name: ipa_hotel_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_hotel_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_hotel_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_hotel_history_id_seq OWNED BY ml_app_zeus_full.ipa_hotel_history.id;


--
-- Name: ipa_hotels; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_hotels (
    id integer NOT NULL,
    master_id integer,
    hotel character varying,
    room_number character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_hotels_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_hotels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_hotels_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_hotels_id_seq OWNED BY ml_app_zeus_full.ipa_hotels.id;


--
-- Name: ipa_payment_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_payment_history (
    id integer NOT NULL,
    master_id integer,
    select_type character varying,
    sent_date date,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_payment_id integer
);


--
-- Name: ipa_payment_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_payment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_payment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_payment_history_id_seq OWNED BY ml_app_zeus_full.ipa_payment_history.id;


--
-- Name: ipa_payments; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_payments (
    id integer NOT NULL,
    master_id integer,
    select_type character varying,
    sent_date date,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_payments_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_payments_id_seq OWNED BY ml_app_zeus_full.ipa_payments.id;


--
-- Name: ipa_screening_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_screening_history (
    id integer NOT NULL,
    master_id integer,
    screening_date date,
    eligible_for_study_blank_yes_no character varying,
    select_reason_if_not_eligible character varying,
    select_status character varying,
    select_subject_withdrew_reason character varying,
    select_investigator_terminated character varying,
    lost_to_follow_up_no_yes character varying,
    no_longer_participating_no_yes character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_screening_id integer
);


--
-- Name: ipa_screening_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_screening_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_screening_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_screening_history_id_seq OWNED BY ml_app_zeus_full.ipa_screening_history.id;


--
-- Name: ipa_screenings; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_screenings (
    id integer NOT NULL,
    master_id integer,
    screening_date date,
    eligible_for_study_blank_yes_no character varying,
    select_reason_if_not_eligible character varying,
    select_status character varying,
    select_subject_withdrew_reason character varying,
    select_investigator_terminated character varying,
    lost_to_follow_up_no_yes character varying,
    no_longer_participating_no_yes character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_screenings_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_screenings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_screenings_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_screenings_id_seq OWNED BY ml_app_zeus_full.ipa_screenings.id;


--
-- Name: ipa_survey_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_survey_history (
    id integer NOT NULL,
    master_id integer,
    select_survey_type character varying,
    sent_date date,
    completed_date date,
    send_next_survey_when date,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_survey_id integer
);


--
-- Name: ipa_survey_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_survey_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_survey_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_survey_history_id_seq OWNED BY ml_app_zeus_full.ipa_survey_history.id;


--
-- Name: ipa_surveys; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_surveys (
    id integer NOT NULL,
    master_id integer,
    select_survey_type character varying,
    sent_date date,
    completed_date date,
    send_next_survey_when date,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_surveys_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_surveys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_surveys_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_surveys_id_seq OWNED BY ml_app_zeus_full.ipa_surveys.id;


--
-- Name: ipa_transportation_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_transportation_history (
    id integer NOT NULL,
    master_id integer,
    travel_date date,
    travel_confirmed_no_yes character varying,
    select_direction character varying,
    origin_city_and_state character varying,
    destination_city_and_state character varying,
    select_mode_of_transport character varying,
    airline character varying,
    flight_number character varying,
    departure_time character varying,
    arrival_time character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_transportation_id integer
);


--
-- Name: ipa_transportation_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_transportation_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_transportation_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_transportation_history_id_seq OWNED BY ml_app_zeus_full.ipa_transportation_history.id;


--
-- Name: ipa_transportations; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ipa_transportations (
    id integer NOT NULL,
    master_id integer,
    travel_date date,
    travel_confirmed_no_yes character varying,
    select_direction character varying,
    origin_city_and_state character varying,
    destination_city_and_state character varying,
    select_mode_of_transport character varying,
    airline character varying,
    flight_number character varying,
    departure_time character varying,
    arrival_time character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_transportations_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.ipa_transportations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_transportations_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.ipa_transportations_id_seq OWNED BY ml_app_zeus_full.ipa_transportations.id;


--
-- Name: item_flag_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.item_flag_history (
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
-- Name: item_flag_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.item_flag_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.item_flag_history_id_seq OWNED BY ml_app_zeus_full.item_flag_history.id;


--
-- Name: item_flag_name_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.item_flag_name_history (
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
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.item_flag_name_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.item_flag_name_history_id_seq OWNED BY ml_app_zeus_full.item_flag_name_history.id;


--
-- Name: item_flag_names; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.item_flag_names (
    id integer NOT NULL,
    name character varying,
    item_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer
);


--
-- Name: item_flag_names_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.item_flag_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_names_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.item_flag_names_id_seq OWNED BY ml_app_zeus_full.item_flag_names.id;


--
-- Name: item_flags; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.item_flags (
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
-- Name: item_flags_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.item_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.item_flags_id_seq OWNED BY ml_app_zeus_full.item_flags.id;


--
-- Name: manage_users; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.manage_users (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: manage_users_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.manage_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manage_users_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.manage_users_id_seq OWNED BY ml_app_zeus_full.manage_users.id;


--
-- Name: masters; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.masters (
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
-- Name: masters_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.masters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: masters_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.masters_id_seq OWNED BY ml_app_zeus_full.masters.id;


--
-- Name: message_notifications; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.message_notifications (
    id integer NOT NULL,
    app_type_id integer,
    master_id integer,
    user_id integer,
    item_id integer,
    item_type character varying,
    message_type character varying,
    recipient_user_ids integer[],
    layout_template_name character varying,
    content_template_name character varying,
    generated_content character varying,
    status character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status_changed character varying,
    subject character varying,
    data json,
    recipient_emails character varying[],
    from_user_email character varying
);


--
-- Name: message_notifications_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.message_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.message_notifications_id_seq OWNED BY ml_app_zeus_full.message_notifications.id;


--
-- Name: message_templates; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.message_templates (
    id integer NOT NULL,
    name character varying,
    message_type character varying,
    template_type character varying,
    template character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: message_templates_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.message_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.message_templates_id_seq OWNED BY ml_app_zeus_full.message_templates.id;


--
-- Name: ml_copy; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.ml_copy (
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
-- Name: model_references; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.model_references (
    id integer NOT NULL,
    from_record_type character varying,
    from_record_id integer,
    from_record_master_id integer,
    to_record_type character varying,
    to_record_id integer,
    to_record_master_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: model_references_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.model_references_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: model_references_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.model_references_id_seq OWNED BY ml_app_zeus_full.model_references.id;


--
-- Name: mrn_number_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.mrn_number_history (
    id integer NOT NULL,
    master_id integer,
    mrn_id character varying,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    mrn_number_table_id integer
);


--
-- Name: mrn_number_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.mrn_number_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mrn_number_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.mrn_number_history_id_seq OWNED BY ml_app_zeus_full.mrn_number_history.id;


--
-- Name: mrn_numbers; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.mrn_numbers (
    id integer NOT NULL,
    master_id integer,
    mrn_id character varying,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: mrn_numbers_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.mrn_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mrn_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.mrn_numbers_id_seq OWNED BY ml_app_zeus_full.mrn_numbers.id;


--
-- Name: msid_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.msid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_test_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.new_test_history (
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
-- Name: new_test_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.new_test_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_test_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.new_test_history_id_seq OWNED BY ml_app_zeus_full.new_test_history.id;


--
-- Name: new_tests; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.new_tests (
    id integer NOT NULL,
    master_id integer,
    new_test_ext_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: new_tests_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.new_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.new_tests_id_seq OWNED BY ml_app_zeus_full.new_tests.id;


--
-- Name: page_layouts; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.page_layouts (
    id integer NOT NULL,
    app_type_id integer,
    layout_name character varying,
    panel_name character varying,
    panel_label character varying,
    panel_position integer,
    options character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: page_layouts_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.page_layouts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_layouts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.page_layouts_id_seq OWNED BY ml_app_zeus_full.page_layouts.id;


--
-- Name: player_contact_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.player_contact_history (
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
-- Name: player_contact_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.player_contact_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_contact_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.player_contact_history_id_seq OWNED BY ml_app_zeus_full.player_contact_history.id;


--
-- Name: player_contacts; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.player_contacts (
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
-- Name: player_contacts_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.player_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.player_contacts_id_seq OWNED BY ml_app_zeus_full.player_contacts.id;


--
-- Name: player_info_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.player_info_history (
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
-- Name: player_info_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.player_info_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_info_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.player_info_history_id_seq OWNED BY ml_app_zeus_full.player_info_history.id;


--
-- Name: player_infos; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.player_infos (
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
-- Name: player_infos_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.player_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.player_infos_id_seq OWNED BY ml_app_zeus_full.player_infos.id;


--
-- Name: pro_infos; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.pro_infos (
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
-- Name: pro_infos_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.pro_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pro_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.pro_infos_id_seq OWNED BY ml_app_zeus_full.pro_infos.id;


--
-- Name: protocol_event_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.protocol_event_history (
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
-- Name: protocol_event_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.protocol_event_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_event_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.protocol_event_history_id_seq OWNED BY ml_app_zeus_full.protocol_event_history.id;


--
-- Name: protocol_events; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.protocol_events (
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
-- Name: protocol_events_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.protocol_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_events_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.protocol_events_id_seq OWNED BY ml_app_zeus_full.protocol_events.id;


--
-- Name: protocol_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.protocol_history (
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
-- Name: protocol_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.protocol_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.protocol_history_id_seq OWNED BY ml_app_zeus_full.protocol_history.id;


--
-- Name: protocols; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.protocols (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    "position" integer
);


--
-- Name: protocols_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.protocols_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocols_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.protocols_id_seq OWNED BY ml_app_zeus_full.protocols.id;


--
-- Name: rc_cis; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.rc_cis (
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
-- Name: rc_cis2; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.rc_cis2 (
    id integer,
    fname character varying,
    lname character varying,
    status character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: rc_cis_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.rc_cis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rc_cis_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.rc_cis_id_seq OWNED BY ml_app_zeus_full.rc_cis.id;


--
-- Name: rc_stage_cif_copy; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.rc_stage_cif_copy (
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
-- Name: rc_stage_cif_copy_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.rc_stage_cif_copy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rc_stage_cif_copy_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.rc_stage_cif_copy_id_seq OWNED BY ml_app_zeus_full.rc_stage_cif_copy.id;


--
-- Name: report_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.report_history (
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
-- Name: report_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.report_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.report_history_id_seq OWNED BY ml_app_zeus_full.report_history.id;


--
-- Name: reports; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.reports (
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
-- Name: reports_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.reports_id_seq OWNED BY ml_app_zeus_full.reports.id;


--
-- Name: sage_assignments; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.sage_assignments (
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
-- Name: sage_assignments_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.sage_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sage_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.sage_assignments_id_seq OWNED BY ml_app_zeus_full.sage_assignments.id;


--
-- Name: sage_two_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.sage_two_history (
    id integer NOT NULL,
    sage_two_id integer,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sage_two_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.sage_two_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sage_two_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.sage_two_history_id_seq OWNED BY ml_app_zeus_full.sage_two_history.id;


--
-- Name: sage_twos; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.sage_twos (
    id integer NOT NULL,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sage_twos_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.sage_twos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sage_twos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.sage_twos_id_seq OWNED BY ml_app_zeus_full.sage_twos.id;


--
-- Name: scantron_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.scantron_history (
    id integer NOT NULL,
    master_id integer,
    scantron_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    scantron_table_id integer
);


--
-- Name: scantron_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.scantron_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantron_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.scantron_history_id_seq OWNED BY ml_app_zeus_full.scantron_history.id;


--
-- Name: scantron_series_two_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.scantron_series_two_history (
    id integer NOT NULL,
    scantron_series_two_id integer,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: scantron_series_two_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.scantron_series_two_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantron_series_two_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.scantron_series_two_history_id_seq OWNED BY ml_app_zeus_full.scantron_series_two_history.id;


--
-- Name: scantron_series_twos; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.scantron_series_twos (
    id integer NOT NULL,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: scantron_series_twos_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.scantron_series_twos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantron_series_twos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.scantron_series_twos_id_seq OWNED BY ml_app_zeus_full.scantron_series_twos.id;


--
-- Name: scantrons; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.scantrons (
    id integer NOT NULL,
    master_id integer,
    scantron_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: scantrons_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.scantrons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantrons_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.scantrons_id_seq OWNED BY ml_app_zeus_full.scantrons.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: smback; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.smback (
    version character varying
);


--
-- Name: social_security_number_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.social_security_number_history (
    id integer NOT NULL,
    master_id integer,
    ssn_id character varying,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    social_security_number_table_id integer
);


--
-- Name: social_security_number_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.social_security_number_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_security_number_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.social_security_number_history_id_seq OWNED BY ml_app_zeus_full.social_security_number_history.id;


--
-- Name: social_security_numbers; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.social_security_numbers (
    id integer NOT NULL,
    master_id integer,
    ssn_id character varying,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: social_security_numbers_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.social_security_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_security_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.social_security_numbers_id_seq OWNED BY ml_app_zeus_full.social_security_numbers.id;


--
-- Name: sub_process_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.sub_process_history (
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
-- Name: sub_process_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.sub_process_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_process_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.sub_process_history_id_seq OWNED BY ml_app_zeus_full.sub_process_history.id;


--
-- Name: sub_processes; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.sub_processes (
    id integer NOT NULL,
    name character varying,
    disabled boolean,
    protocol_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sub_processes_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.sub_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.sub_processes_id_seq OWNED BY ml_app_zeus_full.sub_processes.id;


--
-- Name: test1_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test1_history (
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
-- Name: test1_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test1_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test1_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test1_history_id_seq OWNED BY ml_app_zeus_full.test1_history.id;


--
-- Name: test1s; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test1s (
    id integer NOT NULL,
    master_id integer,
    test1_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test1s_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test1s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test1s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test1s_id_seq OWNED BY ml_app_zeus_full.test1s.id;


--
-- Name: test2_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test2_history (
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
-- Name: test2_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test2_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test2_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test2_history_id_seq OWNED BY ml_app_zeus_full.test2_history.id;


--
-- Name: test2s; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test2s (
    id integer NOT NULL,
    master_id integer,
    test_2ext_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test2s_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test2s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test2s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test2s_id_seq OWNED BY ml_app_zeus_full.test2s.id;


--
-- Name: test_2_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test_2_history (
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
-- Name: test_2_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test_2_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_2_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test_2_history_id_seq OWNED BY ml_app_zeus_full.test_2_history.id;


--
-- Name: test_2s; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test_2s (
    id integer NOT NULL,
    master_id integer,
    test_2ext_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test_2s_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test_2s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_2s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test_2s_id_seq OWNED BY ml_app_zeus_full.test_2s.id;


--
-- Name: test_ext2_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test_ext2_history (
    id integer NOT NULL,
    master_id integer,
    test_e2_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    test_ext2_table_id integer
);


--
-- Name: test_ext2_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test_ext2_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_ext2_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test_ext2_history_id_seq OWNED BY ml_app_zeus_full.test_ext2_history.id;


--
-- Name: test_ext2s; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test_ext2s (
    id integer NOT NULL,
    master_id integer,
    test_e2_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test_ext2s_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test_ext2s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_ext2s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test_ext2s_id_seq OWNED BY ml_app_zeus_full.test_ext2s.id;


--
-- Name: test_ext_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test_ext_history (
    id integer NOT NULL,
    master_id integer,
    test_e_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    test_ext_table_id integer
);


--
-- Name: test_ext_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test_ext_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_ext_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test_ext_history_id_seq OWNED BY ml_app_zeus_full.test_ext_history.id;


--
-- Name: test_exts; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test_exts (
    id integer NOT NULL,
    master_id integer,
    test_e_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test_exts_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test_exts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_exts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test_exts_id_seq OWNED BY ml_app_zeus_full.test_exts.id;


--
-- Name: test_item_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test_item_history (
    id integer NOT NULL,
    test_item_id integer,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test_item_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test_item_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_item_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test_item_history_id_seq OWNED BY ml_app_zeus_full.test_item_history.id;


--
-- Name: test_items; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.test_items (
    id integer NOT NULL,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: test_items_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.test_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_items_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.test_items_id_seq OWNED BY ml_app_zeus_full.test_items.id;


--
-- Name: tracker_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.tracker_history (
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
-- Name: tracker_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.tracker_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracker_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.tracker_history_id_seq OWNED BY ml_app_zeus_full.tracker_history.id;


--
-- Name: trackers; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.trackers (
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
-- Name: trackers_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.trackers_id_seq OWNED BY ml_app_zeus_full.trackers.id;


--
-- Name: user_access_controls; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.user_access_controls (
    id integer NOT NULL,
    user_id integer,
    resource_type character varying,
    resource_name character varying,
    options character varying,
    access character varying,
    disabled boolean,
    admin_id integer,
    app_type_id integer,
    role_name character varying
);


--
-- Name: user_access_controls_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.user_access_controls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_access_controls_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.user_access_controls_id_seq OWNED BY ml_app_zeus_full.user_access_controls.id;


--
-- Name: user_action_logs; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.user_action_logs (
    id integer NOT NULL,
    user_id integer,
    app_type_id integer,
    master_id integer,
    item_type character varying,
    item_id integer,
    index_action_ids integer[],
    action character varying,
    url character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_action_logs_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.user_action_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_action_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.user_action_logs_id_seq OWNED BY ml_app_zeus_full.user_action_logs.id;


--
-- Name: user_authorization_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.user_authorization_history (
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
-- Name: user_authorization_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.user_authorization_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_authorization_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.user_authorization_history_id_seq OWNED BY ml_app_zeus_full.user_authorization_history.id;


--
-- Name: user_authorizations; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.user_authorizations (
    id integer NOT NULL,
    user_id integer,
    has_authorization character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_authorizations_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.user_authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.user_authorizations_id_seq OWNED BY ml_app_zeus_full.user_authorizations.id;


--
-- Name: user_history; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.user_history (
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
    user_id integer,
    app_type_id integer
);


--
-- Name: user_history_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.user_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.user_history_id_seq OWNED BY ml_app_zeus_full.user_history.id;


--
-- Name: user_roles; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.user_roles (
    id integer NOT NULL,
    app_type_id integer,
    role_name character varying,
    user_id integer,
    admin_id integer,
    disabled boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.user_roles_id_seq OWNED BY ml_app_zeus_full.user_roles.id;


--
-- Name: users; Type: TABLE; Schema: ml_app_zeus_full; Owner: -
--

CREATE TABLE ml_app_zeus_full.users (
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
-- Name: users_id_seq; Type: SEQUENCE; Schema: ml_app_zeus_full; Owner: -
--

CREATE SEQUENCE ml_app_zeus_full.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app_zeus_full; Owner: -
--

ALTER SEQUENCE ml_app_zeus_full.users_id_seq OWNED BY ml_app_zeus_full.users.id;


--
-- Name: accuracy_score_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.accuracy_score_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.accuracy_score_history_id_seq'::regclass);


--
-- Name: accuracy_scores id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.accuracy_scores ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.accuracy_scores_id_seq'::regclass);


--
-- Name: activity_log_bhs_assignment_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_bhs_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_bhs_assignment_history_id_seq'::regclass);


--
-- Name: activity_log_bhs_assignments id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_bhs_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_bhs_assignments_id_seq'::regclass);


--
-- Name: activity_log_ext_assignment_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ext_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_ext_assignment_history_id_seq'::regclass);


--
-- Name: activity_log_ext_assignments id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ext_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_ext_assignments_id_seq'::regclass);


--
-- Name: activity_log_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_history_id_seq'::regclass);


--
-- Name: activity_log_ipa_assignment_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_ipa_assignment_history_id_seq'::regclass);


--
-- Name: activity_log_ipa_assignment_minor_deviation_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history_id_seq'::regclass);


--
-- Name: activity_log_ipa_assignment_minor_deviations id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations_id_seq'::regclass);


--
-- Name: activity_log_ipa_assignments id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_ipa_assignments_id_seq'::regclass);


--
-- Name: activity_log_ipa_survey_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_survey_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_ipa_survey_history_id_seq'::regclass);


--
-- Name: activity_log_ipa_surveys id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_surveys ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_ipa_surveys_id_seq'::regclass);


--
-- Name: activity_log_new_test_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_new_test_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_new_test_history_id_seq'::regclass);


--
-- Name: activity_log_new_tests id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_new_tests ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_new_tests_id_seq'::regclass);


--
-- Name: activity_log_player_contact_emails id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_contact_emails ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_player_contact_emails_id_seq'::regclass);


--
-- Name: activity_log_player_contact_phone_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_contact_phone_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_player_contact_phone_history_id_seq'::regclass);


--
-- Name: activity_log_player_contact_phones id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_contact_phones ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_player_contact_phones_id_seq'::regclass);


--
-- Name: activity_log_player_info_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_info_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_player_info_history_id_seq'::regclass);


--
-- Name: activity_log_player_infos id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_infos ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_log_player_infos_id_seq'::regclass);


--
-- Name: activity_logs id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_logs ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.activity_logs_id_seq'::regclass);


--
-- Name: address_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.address_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.address_history_id_seq'::regclass);


--
-- Name: addresses id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.addresses ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.addresses_id_seq'::regclass);


--
-- Name: admin_action_logs id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.admin_action_logs ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.admin_action_logs_id_seq'::regclass);


--
-- Name: admin_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.admin_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.admin_history_id_seq'::regclass);


--
-- Name: admins id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.admins ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.admins_id_seq'::regclass);


--
-- Name: app_configurations id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.app_configurations ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.app_configurations_id_seq'::regclass);


--
-- Name: app_types id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.app_types ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.app_types_id_seq'::regclass);


--
-- Name: bhs_assignment_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.bhs_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.bhs_assignment_history_id_seq'::regclass);


--
-- Name: bhs_assignments id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.bhs_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.bhs_assignments_id_seq'::regclass);


--
-- Name: college_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.college_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.college_history_id_seq'::regclass);


--
-- Name: colleges id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.colleges ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.colleges_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.delayed_jobs_id_seq'::regclass);


--
-- Name: dynamic_model_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.dynamic_model_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.dynamic_model_history_id_seq'::regclass);


--
-- Name: dynamic_models id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.dynamic_models ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.dynamic_models_id_seq'::regclass);


--
-- Name: emergency_contacts id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.emergency_contacts ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.emergency_contacts_id_seq'::regclass);


--
-- Name: exception_logs id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.exception_logs ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.exception_logs_id_seq'::regclass);


--
-- Name: ext_assignment_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ext_assignment_history_id_seq'::regclass);


--
-- Name: ext_assignments id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ext_assignments_id_seq'::regclass);


--
-- Name: ext_gen_assignment_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_gen_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ext_gen_assignment_history_id_seq'::regclass);


--
-- Name: ext_gen_assignments id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_gen_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ext_gen_assignments_id_seq'::regclass);


--
-- Name: external_identifier_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_identifier_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.external_identifier_history_id_seq'::regclass);


--
-- Name: external_identifiers id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_identifiers ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.external_identifiers_id_seq'::regclass);


--
-- Name: external_link_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_link_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.external_link_history_id_seq'::regclass);


--
-- Name: external_links id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_links ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.external_links_id_seq'::regclass);


--
-- Name: general_selection_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.general_selection_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.general_selection_history_id_seq'::regclass);


--
-- Name: general_selections id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.general_selections ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.general_selections_id_seq'::regclass);


--
-- Name: imports id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.imports ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.imports_id_seq'::regclass);


--
-- Name: ipa_appointment_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_appointment_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_appointment_history_id_seq'::regclass);


--
-- Name: ipa_appointments id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_appointments ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_appointments_id_seq'::regclass);


--
-- Name: ipa_assignment_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_assignment_history_id_seq'::regclass);


--
-- Name: ipa_assignments id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_assignments_id_seq'::regclass);


--
-- Name: ipa_consent_mailing_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_consent_mailing_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_consent_mailing_history_id_seq'::regclass);


--
-- Name: ipa_consent_mailings id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_consent_mailings ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_consent_mailings_id_seq'::regclass);


--
-- Name: ipa_hotel_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_hotel_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_hotel_history_id_seq'::regclass);


--
-- Name: ipa_hotels id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_hotels ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_hotels_id_seq'::regclass);


--
-- Name: ipa_payment_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_payment_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_payment_history_id_seq'::regclass);


--
-- Name: ipa_payments id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_payments ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_payments_id_seq'::regclass);


--
-- Name: ipa_screening_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_screening_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_screening_history_id_seq'::regclass);


--
-- Name: ipa_screenings id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_screenings ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_screenings_id_seq'::regclass);


--
-- Name: ipa_survey_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_survey_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_survey_history_id_seq'::regclass);


--
-- Name: ipa_surveys id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_surveys ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_surveys_id_seq'::regclass);


--
-- Name: ipa_transportation_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_transportation_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_transportation_history_id_seq'::regclass);


--
-- Name: ipa_transportations id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_transportations ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.ipa_transportations_id_seq'::regclass);


--
-- Name: item_flag_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flag_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.item_flag_history_id_seq'::regclass);


--
-- Name: item_flag_name_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flag_name_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.item_flag_name_history_id_seq'::regclass);


--
-- Name: item_flag_names id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flag_names ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.item_flag_names_id_seq'::regclass);


--
-- Name: item_flags id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flags ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.item_flags_id_seq'::regclass);


--
-- Name: manage_users id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.manage_users ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.manage_users_id_seq'::regclass);


--
-- Name: masters id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.masters ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.masters_id_seq'::regclass);


--
-- Name: message_notifications id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.message_notifications ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.message_notifications_id_seq'::regclass);


--
-- Name: message_templates id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.message_templates ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.message_templates_id_seq'::regclass);


--
-- Name: model_references id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.model_references ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.model_references_id_seq'::regclass);


--
-- Name: mrn_number_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.mrn_number_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.mrn_number_history_id_seq'::regclass);


--
-- Name: mrn_numbers id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.mrn_numbers ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.mrn_numbers_id_seq'::regclass);


--
-- Name: new_test_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.new_test_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.new_test_history_id_seq'::regclass);


--
-- Name: new_tests id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.new_tests ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.new_tests_id_seq'::regclass);


--
-- Name: page_layouts id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.page_layouts ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.page_layouts_id_seq'::regclass);


--
-- Name: player_contact_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_contact_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.player_contact_history_id_seq'::regclass);


--
-- Name: player_contacts id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_contacts ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.player_contacts_id_seq'::regclass);


--
-- Name: player_info_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_info_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.player_info_history_id_seq'::regclass);


--
-- Name: player_infos id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_infos ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.player_infos_id_seq'::regclass);


--
-- Name: pro_infos id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.pro_infos ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.pro_infos_id_seq'::regclass);


--
-- Name: protocol_event_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocol_event_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.protocol_event_history_id_seq'::regclass);


--
-- Name: protocol_events id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocol_events ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.protocol_events_id_seq'::regclass);


--
-- Name: protocol_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocol_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.protocol_history_id_seq'::regclass);


--
-- Name: protocols id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocols ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.protocols_id_seq'::regclass);


--
-- Name: rc_cis id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.rc_cis ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.rc_cis_id_seq'::regclass);


--
-- Name: rc_stage_cif_copy id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.rc_stage_cif_copy ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.rc_stage_cif_copy_id_seq'::regclass);


--
-- Name: report_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.report_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.report_history_id_seq'::regclass);


--
-- Name: reports id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.reports ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.reports_id_seq'::regclass);


--
-- Name: sage_assignments id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sage_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.sage_assignments_id_seq'::regclass);


--
-- Name: sage_two_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sage_two_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.sage_two_history_id_seq'::regclass);


--
-- Name: sage_twos id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sage_twos ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.sage_twos_id_seq'::regclass);


--
-- Name: scantron_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantron_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.scantron_history_id_seq'::regclass);


--
-- Name: scantron_series_two_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantron_series_two_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.scantron_series_two_history_id_seq'::regclass);


--
-- Name: scantron_series_twos id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantron_series_twos ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.scantron_series_twos_id_seq'::regclass);


--
-- Name: scantrons id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantrons ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.scantrons_id_seq'::regclass);


--
-- Name: social_security_number_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.social_security_number_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.social_security_number_history_id_seq'::regclass);


--
-- Name: social_security_numbers id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.social_security_numbers ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.social_security_numbers_id_seq'::regclass);


--
-- Name: sub_process_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sub_process_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.sub_process_history_id_seq'::regclass);


--
-- Name: sub_processes id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sub_processes ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.sub_processes_id_seq'::regclass);


--
-- Name: test1_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test1_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test1_history_id_seq'::regclass);


--
-- Name: test1s id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test1s ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test1s_id_seq'::regclass);


--
-- Name: test2_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test2_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test2_history_id_seq'::regclass);


--
-- Name: test2s id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test2s ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test2s_id_seq'::regclass);


--
-- Name: test_2_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_2_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test_2_history_id_seq'::regclass);


--
-- Name: test_2s id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_2s ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test_2s_id_seq'::regclass);


--
-- Name: test_ext2_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext2_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test_ext2_history_id_seq'::regclass);


--
-- Name: test_ext2s id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext2s ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test_ext2s_id_seq'::regclass);


--
-- Name: test_ext_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test_ext_history_id_seq'::regclass);


--
-- Name: test_exts id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_exts ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test_exts_id_seq'::regclass);


--
-- Name: test_item_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_item_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test_item_history_id_seq'::regclass);


--
-- Name: test_items id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_items ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.test_items_id_seq'::regclass);


--
-- Name: tracker_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.tracker_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.tracker_history_id_seq'::regclass);


--
-- Name: trackers id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.trackers ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.trackers_id_seq'::regclass);


--
-- Name: user_access_controls id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_access_controls ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.user_access_controls_id_seq'::regclass);


--
-- Name: user_action_logs id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_action_logs ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.user_action_logs_id_seq'::regclass);


--
-- Name: user_authorization_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_authorization_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.user_authorization_history_id_seq'::regclass);


--
-- Name: user_authorizations id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_authorizations ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.user_authorizations_id_seq'::regclass);


--
-- Name: user_history id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_history ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.user_history_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_roles ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.user_roles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.users ALTER COLUMN id SET DEFAULT nextval('ml_app_zeus_full.users_id_seq'::regclass);


--
-- Name: accuracy_score_history accuracy_score_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.accuracy_score_history
    ADD CONSTRAINT accuracy_score_history_pkey PRIMARY KEY (id);


--
-- Name: accuracy_scores accuracy_scores_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.accuracy_scores
    ADD CONSTRAINT accuracy_scores_pkey PRIMARY KEY (id);


--
-- Name: activity_log_bhs_assignment_history activity_log_bhs_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_bhs_assignment_history
    ADD CONSTRAINT activity_log_bhs_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_bhs_assignments activity_log_bhs_assignments_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_bhs_assignments
    ADD CONSTRAINT activity_log_bhs_assignments_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ext_assignment_history activity_log_ext_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ext_assignment_history
    ADD CONSTRAINT activity_log_ext_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ext_assignments activity_log_ext_assignments_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ext_assignments
    ADD CONSTRAINT activity_log_ext_assignments_pkey PRIMARY KEY (id);


--
-- Name: activity_log_history activity_log_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_history
    ADD CONSTRAINT activity_log_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_history activity_log_ipa_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_history
    ADD CONSTRAINT activity_log_ipa_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_minor_deviation_history activity_log_ipa_assignment_minor_deviation_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history
    ADD CONSTRAINT activity_log_ipa_assignment_minor_deviation_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_minor_deviations activity_log_ipa_assignment_minor_deviations_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations
    ADD CONSTRAINT activity_log_ipa_assignment_minor_deviations_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignments activity_log_ipa_assignments_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignments
    ADD CONSTRAINT activity_log_ipa_assignments_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_survey_history activity_log_ipa_survey_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_survey_history
    ADD CONSTRAINT activity_log_ipa_survey_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_surveys activity_log_ipa_surveys_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_surveys
    ADD CONSTRAINT activity_log_ipa_surveys_pkey PRIMARY KEY (id);


--
-- Name: activity_log_new_test_history activity_log_new_test_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_new_test_history
    ADD CONSTRAINT activity_log_new_test_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_new_tests activity_log_new_tests_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_new_tests
    ADD CONSTRAINT activity_log_new_tests_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_contact_emails activity_log_player_contact_emails_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_contact_emails
    ADD CONSTRAINT activity_log_player_contact_emails_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_contact_phone_history activity_log_player_contact_phone_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_contact_phone_history
    ADD CONSTRAINT activity_log_player_contact_phone_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_contact_phones activity_log_player_contact_phones_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_contact_phones
    ADD CONSTRAINT activity_log_player_contact_phones_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_info_history activity_log_player_info_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_info_history
    ADD CONSTRAINT activity_log_player_info_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_infos activity_log_player_infos_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_infos
    ADD CONSTRAINT activity_log_player_infos_pkey PRIMARY KEY (id);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: address_history address_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.address_history
    ADD CONSTRAINT address_history_pkey PRIMARY KEY (id);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: admin_action_logs admin_action_logs_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.admin_action_logs
    ADD CONSTRAINT admin_action_logs_pkey PRIMARY KEY (id);


--
-- Name: admin_history admin_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.admin_history
    ADD CONSTRAINT admin_history_pkey PRIMARY KEY (id);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: app_configurations app_configurations_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.app_configurations
    ADD CONSTRAINT app_configurations_pkey PRIMARY KEY (id);


--
-- Name: app_types app_types_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.app_types
    ADD CONSTRAINT app_types_pkey PRIMARY KEY (id);


--
-- Name: bhs_assignment_history bhs_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.bhs_assignment_history
    ADD CONSTRAINT bhs_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: bhs_assignments bhs_assignments_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.bhs_assignments
    ADD CONSTRAINT bhs_assignments_pkey PRIMARY KEY (id);


--
-- Name: college_history college_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.college_history
    ADD CONSTRAINT college_history_pkey PRIMARY KEY (id);


--
-- Name: colleges colleges_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.colleges
    ADD CONSTRAINT colleges_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: dynamic_model_history dynamic_model_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.dynamic_model_history
    ADD CONSTRAINT dynamic_model_history_pkey PRIMARY KEY (id);


--
-- Name: dynamic_models dynamic_models_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.dynamic_models
    ADD CONSTRAINT dynamic_models_pkey PRIMARY KEY (id);


--
-- Name: emergency_contacts emergency_contacts_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.emergency_contacts
    ADD CONSTRAINT emergency_contacts_pkey PRIMARY KEY (id);


--
-- Name: exception_logs exception_logs_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.exception_logs
    ADD CONSTRAINT exception_logs_pkey PRIMARY KEY (id);


--
-- Name: ext_assignment_history ext_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_assignment_history
    ADD CONSTRAINT ext_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: ext_assignments ext_assignments_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_assignments
    ADD CONSTRAINT ext_assignments_pkey PRIMARY KEY (id);


--
-- Name: ext_gen_assignment_history ext_gen_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_gen_assignment_history
    ADD CONSTRAINT ext_gen_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: ext_gen_assignments ext_gen_assignments_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_gen_assignments
    ADD CONSTRAINT ext_gen_assignments_pkey PRIMARY KEY (id);


--
-- Name: external_identifier_history external_identifier_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_identifier_history
    ADD CONSTRAINT external_identifier_history_pkey PRIMARY KEY (id);


--
-- Name: external_identifiers external_identifiers_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_identifiers
    ADD CONSTRAINT external_identifiers_pkey PRIMARY KEY (id);


--
-- Name: external_link_history external_link_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_link_history
    ADD CONSTRAINT external_link_history_pkey PRIMARY KEY (id);


--
-- Name: external_links external_links_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_links
    ADD CONSTRAINT external_links_pkey PRIMARY KEY (id);


--
-- Name: general_selection_history general_selection_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.general_selection_history
    ADD CONSTRAINT general_selection_history_pkey PRIMARY KEY (id);


--
-- Name: general_selections general_selections_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.general_selections
    ADD CONSTRAINT general_selections_pkey PRIMARY KEY (id);


--
-- Name: imports imports_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: ipa_appointment_history ipa_appointment_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_appointment_history
    ADD CONSTRAINT ipa_appointment_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_appointments ipa_appointments_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_appointments
    ADD CONSTRAINT ipa_appointments_pkey PRIMARY KEY (id);


--
-- Name: ipa_appointments ipa_appointments_visit_start_date_key; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_appointments
    ADD CONSTRAINT ipa_appointments_visit_start_date_key UNIQUE (visit_start_date);


--
-- Name: ipa_assignment_history ipa_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_assignment_history
    ADD CONSTRAINT ipa_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_assignments ipa_assignments_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_assignments
    ADD CONSTRAINT ipa_assignments_pkey PRIMARY KEY (id);


--
-- Name: ipa_consent_mailing_history ipa_consent_mailing_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_consent_mailing_history
    ADD CONSTRAINT ipa_consent_mailing_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_consent_mailings ipa_consent_mailings_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_consent_mailings
    ADD CONSTRAINT ipa_consent_mailings_pkey PRIMARY KEY (id);


--
-- Name: ipa_hotel_history ipa_hotel_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_hotel_history
    ADD CONSTRAINT ipa_hotel_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_hotels ipa_hotels_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_hotels
    ADD CONSTRAINT ipa_hotels_pkey PRIMARY KEY (id);


--
-- Name: ipa_payment_history ipa_payment_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_payment_history
    ADD CONSTRAINT ipa_payment_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_payments ipa_payments_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_payments
    ADD CONSTRAINT ipa_payments_pkey PRIMARY KEY (id);


--
-- Name: ipa_screening_history ipa_screening_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_screening_history
    ADD CONSTRAINT ipa_screening_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_screenings ipa_screenings_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_screenings
    ADD CONSTRAINT ipa_screenings_pkey PRIMARY KEY (id);


--
-- Name: ipa_survey_history ipa_survey_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_survey_history
    ADD CONSTRAINT ipa_survey_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_surveys ipa_surveys_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_surveys
    ADD CONSTRAINT ipa_surveys_pkey PRIMARY KEY (id);


--
-- Name: ipa_transportation_history ipa_transportation_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_transportation_history
    ADD CONSTRAINT ipa_transportation_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_transportations ipa_transportations_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_transportations
    ADD CONSTRAINT ipa_transportations_pkey PRIMARY KEY (id);


--
-- Name: item_flag_history item_flag_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flag_history
    ADD CONSTRAINT item_flag_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_name_history item_flag_name_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flag_name_history
    ADD CONSTRAINT item_flag_name_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_names item_flag_names_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flag_names
    ADD CONSTRAINT item_flag_names_pkey PRIMARY KEY (id);


--
-- Name: item_flags item_flags_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flags
    ADD CONSTRAINT item_flags_pkey PRIMARY KEY (id);


--
-- Name: manage_users manage_users_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.manage_users
    ADD CONSTRAINT manage_users_pkey PRIMARY KEY (id);


--
-- Name: masters masters_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.masters
    ADD CONSTRAINT masters_pkey PRIMARY KEY (id);


--
-- Name: message_notifications message_notifications_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.message_notifications
    ADD CONSTRAINT message_notifications_pkey PRIMARY KEY (id);


--
-- Name: message_templates message_templates_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.message_templates
    ADD CONSTRAINT message_templates_pkey PRIMARY KEY (id);


--
-- Name: model_references model_references_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.model_references
    ADD CONSTRAINT model_references_pkey PRIMARY KEY (id);


--
-- Name: mrn_number_history mrn_number_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.mrn_number_history
    ADD CONSTRAINT mrn_number_history_pkey PRIMARY KEY (id);


--
-- Name: mrn_numbers mrn_numbers_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.mrn_numbers
    ADD CONSTRAINT mrn_numbers_pkey PRIMARY KEY (id);


--
-- Name: new_test_history new_test_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.new_test_history
    ADD CONSTRAINT new_test_history_pkey PRIMARY KEY (id);


--
-- Name: new_tests new_tests_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.new_tests
    ADD CONSTRAINT new_tests_pkey PRIMARY KEY (id);


--
-- Name: page_layouts page_layouts_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.page_layouts
    ADD CONSTRAINT page_layouts_pkey PRIMARY KEY (id);


--
-- Name: player_contact_history player_contact_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_contact_history
    ADD CONSTRAINT player_contact_history_pkey PRIMARY KEY (id);


--
-- Name: player_contacts player_contacts_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_contacts
    ADD CONSTRAINT player_contacts_pkey PRIMARY KEY (id);


--
-- Name: player_info_history player_info_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_info_history
    ADD CONSTRAINT player_info_history_pkey PRIMARY KEY (id);


--
-- Name: player_infos player_infos_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_infos
    ADD CONSTRAINT player_infos_pkey PRIMARY KEY (id);


--
-- Name: pro_infos pro_infos_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.pro_infos
    ADD CONSTRAINT pro_infos_pkey PRIMARY KEY (id);


--
-- Name: protocol_event_history protocol_event_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocol_event_history
    ADD CONSTRAINT protocol_event_history_pkey PRIMARY KEY (id);


--
-- Name: protocol_events protocol_events_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocol_events
    ADD CONSTRAINT protocol_events_pkey PRIMARY KEY (id);


--
-- Name: protocol_history protocol_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocol_history
    ADD CONSTRAINT protocol_history_pkey PRIMARY KEY (id);


--
-- Name: protocols protocols_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- Name: rc_cis rc_cis_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.rc_cis
    ADD CONSTRAINT rc_cis_pkey PRIMARY KEY (id);


--
-- Name: rc_stage_cif_copy rc_stage_cif_copy_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.rc_stage_cif_copy
    ADD CONSTRAINT rc_stage_cif_copy_pkey PRIMARY KEY (id);


--
-- Name: report_history report_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.report_history
    ADD CONSTRAINT report_history_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: sage_assignments sage_assignments_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sage_assignments
    ADD CONSTRAINT sage_assignments_pkey PRIMARY KEY (id);


--
-- Name: sage_two_history sage_two_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sage_two_history
    ADD CONSTRAINT sage_two_history_pkey PRIMARY KEY (id);


--
-- Name: sage_twos sage_twos_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sage_twos
    ADD CONSTRAINT sage_twos_pkey PRIMARY KEY (id);


--
-- Name: scantron_history scantron_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantron_history
    ADD CONSTRAINT scantron_history_pkey PRIMARY KEY (id);


--
-- Name: scantron_series_two_history scantron_series_two_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantron_series_two_history
    ADD CONSTRAINT scantron_series_two_history_pkey PRIMARY KEY (id);


--
-- Name: scantron_series_twos scantron_series_twos_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantron_series_twos
    ADD CONSTRAINT scantron_series_twos_pkey PRIMARY KEY (id);


--
-- Name: scantrons scantrons_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantrons
    ADD CONSTRAINT scantrons_pkey PRIMARY KEY (id);


--
-- Name: social_security_number_history social_security_number_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.social_security_number_history
    ADD CONSTRAINT social_security_number_history_pkey PRIMARY KEY (id);


--
-- Name: social_security_numbers social_security_numbers_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.social_security_numbers
    ADD CONSTRAINT social_security_numbers_pkey PRIMARY KEY (id);


--
-- Name: sub_process_history sub_process_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sub_process_history
    ADD CONSTRAINT sub_process_history_pkey PRIMARY KEY (id);


--
-- Name: sub_processes sub_processes_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sub_processes
    ADD CONSTRAINT sub_processes_pkey PRIMARY KEY (id);


--
-- Name: test1_history test1_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test1_history
    ADD CONSTRAINT test1_history_pkey PRIMARY KEY (id);


--
-- Name: test1s test1s_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test1s
    ADD CONSTRAINT test1s_pkey PRIMARY KEY (id);


--
-- Name: test2_history test2_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test2_history
    ADD CONSTRAINT test2_history_pkey PRIMARY KEY (id);


--
-- Name: test2s test2s_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test2s
    ADD CONSTRAINT test2s_pkey PRIMARY KEY (id);


--
-- Name: test_2_history test_2_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_2_history
    ADD CONSTRAINT test_2_history_pkey PRIMARY KEY (id);


--
-- Name: test_2s test_2s_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_2s
    ADD CONSTRAINT test_2s_pkey PRIMARY KEY (id);


--
-- Name: test_ext2_history test_ext2_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext2_history
    ADD CONSTRAINT test_ext2_history_pkey PRIMARY KEY (id);


--
-- Name: test_ext2s test_ext2s_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext2s
    ADD CONSTRAINT test_ext2s_pkey PRIMARY KEY (id);


--
-- Name: test_ext_history test_ext_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext_history
    ADD CONSTRAINT test_ext_history_pkey PRIMARY KEY (id);


--
-- Name: test_exts test_exts_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_exts
    ADD CONSTRAINT test_exts_pkey PRIMARY KEY (id);


--
-- Name: test_item_history test_item_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_item_history
    ADD CONSTRAINT test_item_history_pkey PRIMARY KEY (id);


--
-- Name: test_items test_items_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_items
    ADD CONSTRAINT test_items_pkey PRIMARY KEY (id);


--
-- Name: tracker_history tracker_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.tracker_history
    ADD CONSTRAINT tracker_history_pkey PRIMARY KEY (id);


--
-- Name: trackers trackers_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.trackers
    ADD CONSTRAINT trackers_pkey PRIMARY KEY (id);


--
-- Name: user_access_controls user_access_controls_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_access_controls
    ADD CONSTRAINT user_access_controls_pkey PRIMARY KEY (id);


--
-- Name: user_action_logs user_action_logs_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_action_logs
    ADD CONSTRAINT user_action_logs_pkey PRIMARY KEY (id);


--
-- Name: user_authorization_history user_authorization_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_authorization_history
    ADD CONSTRAINT user_authorization_history_pkey PRIMARY KEY (id);


--
-- Name: user_authorizations user_authorizations_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_authorizations
    ADD CONSTRAINT user_authorizations_pkey PRIMARY KEY (id);


--
-- Name: user_history user_history_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_history
    ADD CONSTRAINT user_history_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX delayed_jobs_priority ON ml_app_zeus_full.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_accuracy_score_history_on_accuracy_score_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_accuracy_score_history_on_accuracy_score_id ON ml_app_zeus_full.accuracy_score_history USING btree (accuracy_score_id);


--
-- Name: index_accuracy_scores_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_accuracy_scores_on_admin_id ON ml_app_zeus_full.accuracy_scores USING btree (admin_id);


--
-- Name: index_activity_log_bhs_assignment_history_on_activity_log_bhs_a; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignment_history_on_activity_log_bhs_a ON ml_app_zeus_full.activity_log_bhs_assignment_history USING btree (activity_log_bhs_assignment_id);


--
-- Name: index_activity_log_bhs_assignment_history_on_bhs_assignment_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignment_history_on_bhs_assignment_id ON ml_app_zeus_full.activity_log_bhs_assignment_history USING btree (bhs_assignment_id);


--
-- Name: index_activity_log_bhs_assignment_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignment_history_on_master_id ON ml_app_zeus_full.activity_log_bhs_assignment_history USING btree (master_id);


--
-- Name: index_activity_log_bhs_assignment_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignment_history_on_user_id ON ml_app_zeus_full.activity_log_bhs_assignment_history USING btree (user_id);


--
-- Name: index_activity_log_bhs_assignments_on_bhs_assignment_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignments_on_bhs_assignment_id ON ml_app_zeus_full.activity_log_bhs_assignments USING btree (bhs_assignment_id);


--
-- Name: index_activity_log_bhs_assignments_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignments_on_master_id ON ml_app_zeus_full.activity_log_bhs_assignments USING btree (master_id);


--
-- Name: index_activity_log_bhs_assignments_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignments_on_user_id ON ml_app_zeus_full.activity_log_bhs_assignments USING btree (user_id);


--
-- Name: index_activity_log_ext_assignment_history_on_activity_log_ext_a; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ext_assignment_history_on_activity_log_ext_a ON ml_app_zeus_full.activity_log_ext_assignment_history USING btree (activity_log_ext_assignment_id);


--
-- Name: index_activity_log_ext_assignment_history_on_ext_assignment_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ext_assignment_history_on_ext_assignment_id ON ml_app_zeus_full.activity_log_ext_assignment_history USING btree (ext_assignment_id);


--
-- Name: index_activity_log_ext_assignment_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ext_assignment_history_on_master_id ON ml_app_zeus_full.activity_log_ext_assignment_history USING btree (master_id);


--
-- Name: index_activity_log_ext_assignment_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ext_assignment_history_on_user_id ON ml_app_zeus_full.activity_log_ext_assignment_history USING btree (user_id);


--
-- Name: index_activity_log_ext_assignments_on_ext_assignment_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ext_assignments_on_ext_assignment_id ON ml_app_zeus_full.activity_log_ext_assignments USING btree (ext_assignment_id);


--
-- Name: index_activity_log_ext_assignments_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ext_assignments_on_master_id ON ml_app_zeus_full.activity_log_ext_assignments USING btree (master_id);


--
-- Name: index_activity_log_ext_assignments_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ext_assignments_on_user_id ON ml_app_zeus_full.activity_log_ext_assignments USING btree (user_id);


--
-- Name: index_activity_log_history_on_activity_log_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_history_on_activity_log_id ON ml_app_zeus_full.activity_log_history USING btree (activity_log_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_activity_log_ipa_a; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_activity_log_ipa_a ON ml_app_zeus_full.activity_log_ipa_assignment_history USING btree (activity_log_ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_ipa_assignment_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_ipa_assignment_id ON ml_app_zeus_full.activity_log_ipa_assignment_history USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_master_id ON ml_app_zeus_full.activity_log_ipa_assignment_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_user_id ON ml_app_zeus_full.activity_log_ipa_assignment_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviation_history_on_ac; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_ac ON ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history USING btree (activity_log_ipa_assignment_minor_deviation_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviation_history_on_ip; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_ip ON ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviation_history_on_ma; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_ma ON ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviation_history_on_us; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_us ON ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviations_on_ipa_assig; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviations_on_ipa_assig ON ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviations_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviations_on_master_id ON ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviations_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviations_on_user_id ON ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignments_on_ipa_assignment_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignments_on_ipa_assignment_id ON ml_app_zeus_full.activity_log_ipa_assignments USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignments_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignments_on_master_id ON ml_app_zeus_full.activity_log_ipa_assignments USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignments_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignments_on_user_id ON ml_app_zeus_full.activity_log_ipa_assignments USING btree (user_id);


--
-- Name: index_activity_log_ipa_survey_history_on_activity_log_ipa_surve; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_survey_history_on_activity_log_ipa_surve ON ml_app_zeus_full.activity_log_ipa_survey_history USING btree (activity_log_ipa_survey_id);


--
-- Name: index_activity_log_ipa_survey_history_on_ipa_survey_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_survey_history_on_ipa_survey_id ON ml_app_zeus_full.activity_log_ipa_survey_history USING btree (ipa_survey_id);


--
-- Name: index_activity_log_ipa_survey_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_survey_history_on_master_id ON ml_app_zeus_full.activity_log_ipa_survey_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_survey_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_survey_history_on_user_id ON ml_app_zeus_full.activity_log_ipa_survey_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_surveys_on_ipa_survey_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_surveys_on_ipa_survey_id ON ml_app_zeus_full.activity_log_ipa_surveys USING btree (ipa_survey_id);


--
-- Name: index_activity_log_ipa_surveys_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_surveys_on_master_id ON ml_app_zeus_full.activity_log_ipa_surveys USING btree (master_id);


--
-- Name: index_activity_log_ipa_surveys_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_ipa_surveys_on_user_id ON ml_app_zeus_full.activity_log_ipa_surveys USING btree (user_id);


--
-- Name: index_activity_log_new_test_history_on_activity_log_new_test_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_new_test_history_on_activity_log_new_test_id ON ml_app_zeus_full.activity_log_new_test_history USING btree (activity_log_new_test_id);


--
-- Name: index_activity_log_new_test_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_new_test_history_on_master_id ON ml_app_zeus_full.activity_log_new_test_history USING btree (master_id);


--
-- Name: index_activity_log_new_test_history_on_new_test_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_new_test_history_on_new_test_id ON ml_app_zeus_full.activity_log_new_test_history USING btree (new_test_id);


--
-- Name: index_activity_log_new_test_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_new_test_history_on_user_id ON ml_app_zeus_full.activity_log_new_test_history USING btree (user_id);


--
-- Name: index_activity_log_new_tests_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_new_tests_on_master_id ON ml_app_zeus_full.activity_log_new_tests USING btree (master_id);


--
-- Name: index_activity_log_new_tests_on_new_test_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_new_tests_on_new_test_id ON ml_app_zeus_full.activity_log_new_tests USING btree (new_test_id);


--
-- Name: index_activity_log_new_tests_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_new_tests_on_user_id ON ml_app_zeus_full.activity_log_new_tests USING btree (user_id);


--
-- Name: index_activity_log_player_contact_emails_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_emails_on_master_id ON ml_app_zeus_full.activity_log_player_contact_emails USING btree (master_id);


--
-- Name: index_activity_log_player_contact_emails_on_player_contact_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_emails_on_player_contact_id ON ml_app_zeus_full.activity_log_player_contact_emails USING btree (player_contact_id);


--
-- Name: index_activity_log_player_contact_emails_on_protocol_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_emails_on_protocol_id ON ml_app_zeus_full.activity_log_player_contact_emails USING btree (protocol_id);


--
-- Name: index_activity_log_player_contact_emails_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_emails_on_user_id ON ml_app_zeus_full.activity_log_player_contact_emails USING btree (user_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_activity_log; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_activity_log ON ml_app_zeus_full.activity_log_player_contact_phone_history USING btree (activity_log_player_contact_phone_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_master_id ON ml_app_zeus_full.activity_log_player_contact_phone_history USING btree (master_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_player_conta; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_player_conta ON ml_app_zeus_full.activity_log_player_contact_phone_history USING btree (player_contact_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_user_id ON ml_app_zeus_full.activity_log_player_contact_phone_history USING btree (user_id);


--
-- Name: index_activity_log_player_contact_phones_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phones_on_master_id ON ml_app_zeus_full.activity_log_player_contact_phones USING btree (master_id);


--
-- Name: index_activity_log_player_contact_phones_on_player_contact_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phones_on_player_contact_id ON ml_app_zeus_full.activity_log_player_contact_phones USING btree (player_contact_id);


--
-- Name: index_activity_log_player_contact_phones_on_protocol_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phones_on_protocol_id ON ml_app_zeus_full.activity_log_player_contact_phones USING btree (protocol_id);


--
-- Name: index_activity_log_player_contact_phones_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phones_on_user_id ON ml_app_zeus_full.activity_log_player_contact_phones USING btree (user_id);


--
-- Name: index_activity_log_player_info_history_on_activity_log_player_i; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_info_history_on_activity_log_player_i ON ml_app_zeus_full.activity_log_player_info_history USING btree (activity_log_player_info_id);


--
-- Name: index_activity_log_player_info_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_info_history_on_master_id ON ml_app_zeus_full.activity_log_player_info_history USING btree (master_id);


--
-- Name: index_activity_log_player_info_history_on_player_info_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_info_history_on_player_info_id ON ml_app_zeus_full.activity_log_player_info_history USING btree (player_info_id);


--
-- Name: index_activity_log_player_info_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_info_history_on_user_id ON ml_app_zeus_full.activity_log_player_info_history USING btree (user_id);


--
-- Name: index_activity_log_player_infos_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_infos_on_master_id ON ml_app_zeus_full.activity_log_player_infos USING btree (master_id);


--
-- Name: index_activity_log_player_infos_on_player_info_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_infos_on_player_info_id ON ml_app_zeus_full.activity_log_player_infos USING btree (player_info_id);


--
-- Name: index_activity_log_player_infos_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_activity_log_player_infos_on_user_id ON ml_app_zeus_full.activity_log_player_infos USING btree (user_id);


--
-- Name: index_address_history_on_address_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_address_history_on_address_id ON ml_app_zeus_full.address_history USING btree (address_id);


--
-- Name: index_address_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_address_history_on_master_id ON ml_app_zeus_full.address_history USING btree (master_id);


--
-- Name: index_address_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_address_history_on_user_id ON ml_app_zeus_full.address_history USING btree (user_id);


--
-- Name: index_addresses_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_addresses_on_master_id ON ml_app_zeus_full.addresses USING btree (master_id);


--
-- Name: index_addresses_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_addresses_on_user_id ON ml_app_zeus_full.addresses USING btree (user_id);


--
-- Name: index_admin_action_logs_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_admin_action_logs_on_admin_id ON ml_app_zeus_full.admin_action_logs USING btree (admin_id);


--
-- Name: index_admin_history_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_admin_history_on_admin_id ON ml_app_zeus_full.admin_history USING btree (admin_id);


--
-- Name: index_app_configurations_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_app_configurations_on_admin_id ON ml_app_zeus_full.app_configurations USING btree (admin_id);


--
-- Name: index_app_configurations_on_app_type_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_app_configurations_on_app_type_id ON ml_app_zeus_full.app_configurations USING btree (app_type_id);


--
-- Name: index_app_configurations_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_app_configurations_on_user_id ON ml_app_zeus_full.app_configurations USING btree (user_id);


--
-- Name: index_app_types_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_app_types_on_admin_id ON ml_app_zeus_full.app_types USING btree (admin_id);


--
-- Name: index_bhs_assignment_history_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_bhs_assignment_history_on_admin_id ON ml_app_zeus_full.bhs_assignment_history USING btree (admin_id);


--
-- Name: index_bhs_assignment_history_on_bhs_assignment_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_bhs_assignment_history_on_bhs_assignment_table_id ON ml_app_zeus_full.bhs_assignment_history USING btree (bhs_assignment_table_id);


--
-- Name: index_bhs_assignment_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_bhs_assignment_history_on_master_id ON ml_app_zeus_full.bhs_assignment_history USING btree (master_id);


--
-- Name: index_bhs_assignment_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_bhs_assignment_history_on_user_id ON ml_app_zeus_full.bhs_assignment_history USING btree (user_id);


--
-- Name: index_bhs_assignments_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_bhs_assignments_on_admin_id ON ml_app_zeus_full.bhs_assignments USING btree (admin_id);


--
-- Name: index_bhs_assignments_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_bhs_assignments_on_master_id ON ml_app_zeus_full.bhs_assignments USING btree (master_id);


--
-- Name: index_bhs_assignments_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_bhs_assignments_on_user_id ON ml_app_zeus_full.bhs_assignments USING btree (user_id);


--
-- Name: index_college_history_on_college_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_college_history_on_college_id ON ml_app_zeus_full.college_history USING btree (college_id);


--
-- Name: index_colleges_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_colleges_on_admin_id ON ml_app_zeus_full.colleges USING btree (admin_id);


--
-- Name: index_colleges_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_colleges_on_user_id ON ml_app_zeus_full.colleges USING btree (user_id);


--
-- Name: index_dynamic_model_history_on_dynamic_model_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_dynamic_model_history_on_dynamic_model_id ON ml_app_zeus_full.dynamic_model_history USING btree (dynamic_model_id);


--
-- Name: index_dynamic_models_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_dynamic_models_on_admin_id ON ml_app_zeus_full.dynamic_models USING btree (admin_id);


--
-- Name: index_emergency_contacts_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_emergency_contacts_on_master_id ON ml_app_zeus_full.emergency_contacts USING btree (master_id);


--
-- Name: index_emergency_contacts_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_emergency_contacts_on_user_id ON ml_app_zeus_full.emergency_contacts USING btree (user_id);


--
-- Name: index_exception_logs_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_exception_logs_on_admin_id ON ml_app_zeus_full.exception_logs USING btree (admin_id);


--
-- Name: index_exception_logs_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_exception_logs_on_user_id ON ml_app_zeus_full.exception_logs USING btree (user_id);


--
-- Name: index_ext_assignment_history_on_ext_assignment_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_assignment_history_on_ext_assignment_table_id ON ml_app_zeus_full.ext_assignment_history USING btree (ext_assignment_table_id);


--
-- Name: index_ext_assignment_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_assignment_history_on_master_id ON ml_app_zeus_full.ext_assignment_history USING btree (master_id);


--
-- Name: index_ext_assignment_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_assignment_history_on_user_id ON ml_app_zeus_full.ext_assignment_history USING btree (user_id);


--
-- Name: index_ext_assignments_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_assignments_on_master_id ON ml_app_zeus_full.ext_assignments USING btree (master_id);


--
-- Name: index_ext_assignments_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_assignments_on_user_id ON ml_app_zeus_full.ext_assignments USING btree (user_id);


--
-- Name: index_ext_gen_assignment_history_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_gen_assignment_history_on_admin_id ON ml_app_zeus_full.ext_gen_assignment_history USING btree (admin_id);


--
-- Name: index_ext_gen_assignment_history_on_ext_gen_assignment_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_gen_assignment_history_on_ext_gen_assignment_table_id ON ml_app_zeus_full.ext_gen_assignment_history USING btree (ext_gen_assignment_table_id);


--
-- Name: index_ext_gen_assignment_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_gen_assignment_history_on_master_id ON ml_app_zeus_full.ext_gen_assignment_history USING btree (master_id);


--
-- Name: index_ext_gen_assignment_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_gen_assignment_history_on_user_id ON ml_app_zeus_full.ext_gen_assignment_history USING btree (user_id);


--
-- Name: index_ext_gen_assignments_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_gen_assignments_on_admin_id ON ml_app_zeus_full.ext_gen_assignments USING btree (admin_id);


--
-- Name: index_ext_gen_assignments_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_gen_assignments_on_master_id ON ml_app_zeus_full.ext_gen_assignments USING btree (master_id);


--
-- Name: index_ext_gen_assignments_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ext_gen_assignments_on_user_id ON ml_app_zeus_full.ext_gen_assignments USING btree (user_id);


--
-- Name: index_external_identifier_history_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_external_identifier_history_on_admin_id ON ml_app_zeus_full.external_identifier_history USING btree (admin_id);


--
-- Name: index_external_identifier_history_on_external_identifier_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_external_identifier_history_on_external_identifier_id ON ml_app_zeus_full.external_identifier_history USING btree (external_identifier_id);


--
-- Name: index_external_identifiers_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_external_identifiers_on_admin_id ON ml_app_zeus_full.external_identifiers USING btree (admin_id);


--
-- Name: index_external_link_history_on_external_link_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_external_link_history_on_external_link_id ON ml_app_zeus_full.external_link_history USING btree (external_link_id);


--
-- Name: index_external_links_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_external_links_on_admin_id ON ml_app_zeus_full.external_links USING btree (admin_id);


--
-- Name: index_general_selection_history_on_general_selection_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_general_selection_history_on_general_selection_id ON ml_app_zeus_full.general_selection_history USING btree (general_selection_id);


--
-- Name: index_general_selections_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_general_selections_on_admin_id ON ml_app_zeus_full.general_selections USING btree (admin_id);


--
-- Name: index_imports_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_imports_on_user_id ON ml_app_zeus_full.imports USING btree (user_id);


--
-- Name: index_ipa_appointment_history_on_ipa_appointment_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_appointment_history_on_ipa_appointment_id ON ml_app_zeus_full.ipa_appointment_history USING btree (ipa_appointment_id);


--
-- Name: index_ipa_appointment_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_appointment_history_on_master_id ON ml_app_zeus_full.ipa_appointment_history USING btree (master_id);


--
-- Name: index_ipa_appointment_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_appointment_history_on_user_id ON ml_app_zeus_full.ipa_appointment_history USING btree (user_id);


--
-- Name: index_ipa_appointments_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_appointments_on_master_id ON ml_app_zeus_full.ipa_appointments USING btree (master_id);


--
-- Name: index_ipa_appointments_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_appointments_on_user_id ON ml_app_zeus_full.ipa_appointments USING btree (user_id);


--
-- Name: index_ipa_assignment_history_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_admin_id ON ml_app_zeus_full.ipa_assignment_history USING btree (admin_id);


--
-- Name: index_ipa_assignment_history_on_ipa_assignment_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_ipa_assignment_table_id ON ml_app_zeus_full.ipa_assignment_history USING btree (ipa_assignment_table_id);


--
-- Name: index_ipa_assignment_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_master_id ON ml_app_zeus_full.ipa_assignment_history USING btree (master_id);


--
-- Name: index_ipa_assignment_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_user_id ON ml_app_zeus_full.ipa_assignment_history USING btree (user_id);


--
-- Name: index_ipa_assignments_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_assignments_on_admin_id ON ml_app_zeus_full.ipa_assignments USING btree (admin_id);


--
-- Name: index_ipa_assignments_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_assignments_on_master_id ON ml_app_zeus_full.ipa_assignments USING btree (master_id);


--
-- Name: index_ipa_assignments_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_assignments_on_user_id ON ml_app_zeus_full.ipa_assignments USING btree (user_id);


--
-- Name: index_ipa_consent_mailing_history_on_ipa_consent_mailing_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_consent_mailing_history_on_ipa_consent_mailing_id ON ml_app_zeus_full.ipa_consent_mailing_history USING btree (ipa_consent_mailing_id);


--
-- Name: index_ipa_consent_mailing_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_consent_mailing_history_on_master_id ON ml_app_zeus_full.ipa_consent_mailing_history USING btree (master_id);


--
-- Name: index_ipa_consent_mailing_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_consent_mailing_history_on_user_id ON ml_app_zeus_full.ipa_consent_mailing_history USING btree (user_id);


--
-- Name: index_ipa_consent_mailings_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_consent_mailings_on_master_id ON ml_app_zeus_full.ipa_consent_mailings USING btree (master_id);


--
-- Name: index_ipa_consent_mailings_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_consent_mailings_on_user_id ON ml_app_zeus_full.ipa_consent_mailings USING btree (user_id);


--
-- Name: index_ipa_hotel_history_on_ipa_hotel_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_hotel_history_on_ipa_hotel_id ON ml_app_zeus_full.ipa_hotel_history USING btree (ipa_hotel_id);


--
-- Name: index_ipa_hotel_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_hotel_history_on_master_id ON ml_app_zeus_full.ipa_hotel_history USING btree (master_id);


--
-- Name: index_ipa_hotel_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_hotel_history_on_user_id ON ml_app_zeus_full.ipa_hotel_history USING btree (user_id);


--
-- Name: index_ipa_hotels_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_hotels_on_master_id ON ml_app_zeus_full.ipa_hotels USING btree (master_id);


--
-- Name: index_ipa_hotels_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_hotels_on_user_id ON ml_app_zeus_full.ipa_hotels USING btree (user_id);


--
-- Name: index_ipa_payment_history_on_ipa_payment_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_payment_history_on_ipa_payment_id ON ml_app_zeus_full.ipa_payment_history USING btree (ipa_payment_id);


--
-- Name: index_ipa_payment_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_payment_history_on_master_id ON ml_app_zeus_full.ipa_payment_history USING btree (master_id);


--
-- Name: index_ipa_payment_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_payment_history_on_user_id ON ml_app_zeus_full.ipa_payment_history USING btree (user_id);


--
-- Name: index_ipa_payments_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_payments_on_master_id ON ml_app_zeus_full.ipa_payments USING btree (master_id);


--
-- Name: index_ipa_payments_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_payments_on_user_id ON ml_app_zeus_full.ipa_payments USING btree (user_id);


--
-- Name: index_ipa_screening_history_on_ipa_screening_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_screening_history_on_ipa_screening_id ON ml_app_zeus_full.ipa_screening_history USING btree (ipa_screening_id);


--
-- Name: index_ipa_screening_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_screening_history_on_master_id ON ml_app_zeus_full.ipa_screening_history USING btree (master_id);


--
-- Name: index_ipa_screening_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_screening_history_on_user_id ON ml_app_zeus_full.ipa_screening_history USING btree (user_id);


--
-- Name: index_ipa_screenings_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_screenings_on_master_id ON ml_app_zeus_full.ipa_screenings USING btree (master_id);


--
-- Name: index_ipa_screenings_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_screenings_on_user_id ON ml_app_zeus_full.ipa_screenings USING btree (user_id);


--
-- Name: index_ipa_survey_history_on_ipa_survey_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_survey_history_on_ipa_survey_id ON ml_app_zeus_full.ipa_survey_history USING btree (ipa_survey_id);


--
-- Name: index_ipa_survey_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_survey_history_on_master_id ON ml_app_zeus_full.ipa_survey_history USING btree (master_id);


--
-- Name: index_ipa_survey_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_survey_history_on_user_id ON ml_app_zeus_full.ipa_survey_history USING btree (user_id);


--
-- Name: index_ipa_surveys_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_surveys_on_master_id ON ml_app_zeus_full.ipa_surveys USING btree (master_id);


--
-- Name: index_ipa_surveys_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_surveys_on_user_id ON ml_app_zeus_full.ipa_surveys USING btree (user_id);


--
-- Name: index_ipa_transportation_history_on_ipa_transportation_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_transportation_history_on_ipa_transportation_id ON ml_app_zeus_full.ipa_transportation_history USING btree (ipa_transportation_id);


--
-- Name: index_ipa_transportation_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_transportation_history_on_master_id ON ml_app_zeus_full.ipa_transportation_history USING btree (master_id);


--
-- Name: index_ipa_transportation_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_transportation_history_on_user_id ON ml_app_zeus_full.ipa_transportation_history USING btree (user_id);


--
-- Name: index_ipa_transportations_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_transportations_on_master_id ON ml_app_zeus_full.ipa_transportations USING btree (master_id);


--
-- Name: index_ipa_transportations_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_ipa_transportations_on_user_id ON ml_app_zeus_full.ipa_transportations USING btree (user_id);


--
-- Name: index_item_flag_history_on_item_flag_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_item_flag_history_on_item_flag_id ON ml_app_zeus_full.item_flag_history USING btree (item_flag_id);


--
-- Name: index_item_flag_name_history_on_item_flag_name_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_item_flag_name_history_on_item_flag_name_id ON ml_app_zeus_full.item_flag_name_history USING btree (item_flag_name_id);


--
-- Name: index_item_flag_names_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_item_flag_names_on_admin_id ON ml_app_zeus_full.item_flag_names USING btree (admin_id);


--
-- Name: index_item_flags_on_item_flag_name_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_item_flags_on_item_flag_name_id ON ml_app_zeus_full.item_flags USING btree (item_flag_name_id);


--
-- Name: index_item_flags_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_item_flags_on_user_id ON ml_app_zeus_full.item_flags USING btree (user_id);


--
-- Name: index_masters_on_msid; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_masters_on_msid ON ml_app_zeus_full.masters USING btree (msid);


--
-- Name: index_masters_on_pro_info_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_masters_on_pro_info_id ON ml_app_zeus_full.masters USING btree (pro_info_id);


--
-- Name: index_masters_on_proid; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_masters_on_proid ON ml_app_zeus_full.masters USING btree (pro_id);


--
-- Name: index_masters_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_masters_on_user_id ON ml_app_zeus_full.masters USING btree (user_id);


--
-- Name: index_message_notifications_on_app_type_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_message_notifications_on_app_type_id ON ml_app_zeus_full.message_notifications USING btree (app_type_id);


--
-- Name: index_message_notifications_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_message_notifications_on_master_id ON ml_app_zeus_full.message_notifications USING btree (master_id);


--
-- Name: index_message_notifications_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_message_notifications_on_user_id ON ml_app_zeus_full.message_notifications USING btree (user_id);


--
-- Name: index_message_notifications_status; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_message_notifications_status ON ml_app_zeus_full.message_notifications USING btree (status);


--
-- Name: index_message_templates_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_message_templates_on_admin_id ON ml_app_zeus_full.message_templates USING btree (admin_id);


--
-- Name: index_model_references_on_from_record_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_model_references_on_from_record_master_id ON ml_app_zeus_full.model_references USING btree (from_record_master_id);


--
-- Name: index_model_references_on_from_record_type_and_from_record_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_model_references_on_from_record_type_and_from_record_id ON ml_app_zeus_full.model_references USING btree (from_record_type, from_record_id);


--
-- Name: index_model_references_on_to_record_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_model_references_on_to_record_master_id ON ml_app_zeus_full.model_references USING btree (to_record_master_id);


--
-- Name: index_model_references_on_to_record_type_and_to_record_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_model_references_on_to_record_type_and_to_record_id ON ml_app_zeus_full.model_references USING btree (to_record_type, to_record_id);


--
-- Name: index_model_references_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_model_references_on_user_id ON ml_app_zeus_full.model_references USING btree (user_id);


--
-- Name: index_mrn_number_history_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_mrn_number_history_on_admin_id ON ml_app_zeus_full.mrn_number_history USING btree (admin_id);


--
-- Name: index_mrn_number_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_mrn_number_history_on_master_id ON ml_app_zeus_full.mrn_number_history USING btree (master_id);


--
-- Name: index_mrn_number_history_on_mrn_number_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_mrn_number_history_on_mrn_number_table_id ON ml_app_zeus_full.mrn_number_history USING btree (mrn_number_table_id);


--
-- Name: index_mrn_number_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_mrn_number_history_on_user_id ON ml_app_zeus_full.mrn_number_history USING btree (user_id);


--
-- Name: index_mrn_numbers_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_mrn_numbers_on_admin_id ON ml_app_zeus_full.mrn_numbers USING btree (admin_id);


--
-- Name: index_mrn_numbers_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_mrn_numbers_on_master_id ON ml_app_zeus_full.mrn_numbers USING btree (master_id);


--
-- Name: index_mrn_numbers_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_mrn_numbers_on_user_id ON ml_app_zeus_full.mrn_numbers USING btree (user_id);


--
-- Name: index_new_test_history_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_new_test_history_on_admin_id ON ml_app_zeus_full.new_test_history USING btree (admin_id);


--
-- Name: index_new_test_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_new_test_history_on_master_id ON ml_app_zeus_full.new_test_history USING btree (master_id);


--
-- Name: index_new_test_history_on_new_test_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_new_test_history_on_new_test_table_id ON ml_app_zeus_full.new_test_history USING btree (new_test_table_id);


--
-- Name: index_new_test_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_new_test_history_on_user_id ON ml_app_zeus_full.new_test_history USING btree (user_id);


--
-- Name: index_new_tests_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_new_tests_on_admin_id ON ml_app_zeus_full.new_tests USING btree (admin_id);


--
-- Name: index_new_tests_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_new_tests_on_master_id ON ml_app_zeus_full.new_tests USING btree (master_id);


--
-- Name: index_new_tests_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_new_tests_on_user_id ON ml_app_zeus_full.new_tests USING btree (user_id);


--
-- Name: index_page_layouts_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_page_layouts_on_admin_id ON ml_app_zeus_full.page_layouts USING btree (admin_id);


--
-- Name: index_page_layouts_on_app_type_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_page_layouts_on_app_type_id ON ml_app_zeus_full.page_layouts USING btree (app_type_id);


--
-- Name: index_player_contact_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_player_contact_history_on_master_id ON ml_app_zeus_full.player_contact_history USING btree (master_id);


--
-- Name: index_player_contact_history_on_player_contact_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_player_contact_history_on_player_contact_id ON ml_app_zeus_full.player_contact_history USING btree (player_contact_id);


--
-- Name: index_player_contact_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_player_contact_history_on_user_id ON ml_app_zeus_full.player_contact_history USING btree (user_id);


--
-- Name: index_player_contacts_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_player_contacts_on_master_id ON ml_app_zeus_full.player_contacts USING btree (master_id);


--
-- Name: index_player_contacts_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_player_contacts_on_user_id ON ml_app_zeus_full.player_contacts USING btree (user_id);


--
-- Name: index_player_info_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_player_info_history_on_master_id ON ml_app_zeus_full.player_info_history USING btree (master_id);


--
-- Name: index_player_info_history_on_player_info_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_player_info_history_on_player_info_id ON ml_app_zeus_full.player_info_history USING btree (player_info_id);


--
-- Name: index_player_info_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_player_info_history_on_user_id ON ml_app_zeus_full.player_info_history USING btree (user_id);


--
-- Name: index_player_infos_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_player_infos_on_master_id ON ml_app_zeus_full.player_infos USING btree (master_id);


--
-- Name: index_player_infos_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_player_infos_on_user_id ON ml_app_zeus_full.player_infos USING btree (user_id);


--
-- Name: index_pro_infos_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_pro_infos_on_master_id ON ml_app_zeus_full.pro_infos USING btree (master_id);


--
-- Name: index_pro_infos_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_pro_infos_on_user_id ON ml_app_zeus_full.pro_infos USING btree (user_id);


--
-- Name: index_protocol_event_history_on_protocol_event_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_protocol_event_history_on_protocol_event_id ON ml_app_zeus_full.protocol_event_history USING btree (protocol_event_id);


--
-- Name: index_protocol_events_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_protocol_events_on_admin_id ON ml_app_zeus_full.protocol_events USING btree (admin_id);


--
-- Name: index_protocol_events_on_sub_process_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_protocol_events_on_sub_process_id ON ml_app_zeus_full.protocol_events USING btree (sub_process_id);


--
-- Name: index_protocol_history_on_protocol_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_protocol_history_on_protocol_id ON ml_app_zeus_full.protocol_history USING btree (protocol_id);


--
-- Name: index_protocols_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_protocols_on_admin_id ON ml_app_zeus_full.protocols USING btree (admin_id);


--
-- Name: index_report_history_on_report_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_report_history_on_report_id ON ml_app_zeus_full.report_history USING btree (report_id);


--
-- Name: index_reports_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_reports_on_admin_id ON ml_app_zeus_full.reports USING btree (admin_id);


--
-- Name: index_sage_assignments_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_sage_assignments_on_admin_id ON ml_app_zeus_full.sage_assignments USING btree (admin_id);


--
-- Name: index_sage_assignments_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_sage_assignments_on_master_id ON ml_app_zeus_full.sage_assignments USING btree (master_id);


--
-- Name: index_sage_assignments_on_sage_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE UNIQUE INDEX index_sage_assignments_on_sage_id ON ml_app_zeus_full.sage_assignments USING btree (sage_id);


--
-- Name: index_sage_assignments_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_sage_assignments_on_user_id ON ml_app_zeus_full.sage_assignments USING btree (user_id);


--
-- Name: index_sage_two_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_sage_two_history_on_master_id ON ml_app_zeus_full.sage_two_history USING btree (master_id);


--
-- Name: index_sage_two_history_on_sage_two_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_sage_two_history_on_sage_two_id ON ml_app_zeus_full.sage_two_history USING btree (sage_two_id);


--
-- Name: index_sage_two_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_sage_two_history_on_user_id ON ml_app_zeus_full.sage_two_history USING btree (user_id);


--
-- Name: index_sage_twos_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_sage_twos_on_master_id ON ml_app_zeus_full.sage_twos USING btree (master_id);


--
-- Name: index_sage_twos_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_sage_twos_on_user_id ON ml_app_zeus_full.sage_twos USING btree (user_id);


--
-- Name: index_scantron_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_scantron_history_on_master_id ON ml_app_zeus_full.scantron_history USING btree (master_id);


--
-- Name: index_scantron_history_on_scantron_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_scantron_history_on_scantron_table_id ON ml_app_zeus_full.scantron_history USING btree (scantron_table_id);


--
-- Name: index_scantron_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_scantron_history_on_user_id ON ml_app_zeus_full.scantron_history USING btree (user_id);


--
-- Name: index_scantron_series_two_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_scantron_series_two_history_on_master_id ON ml_app_zeus_full.scantron_series_two_history USING btree (master_id);


--
-- Name: index_scantron_series_two_history_on_scantron_series_two_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_scantron_series_two_history_on_scantron_series_two_id ON ml_app_zeus_full.scantron_series_two_history USING btree (scantron_series_two_id);


--
-- Name: index_scantron_series_two_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_scantron_series_two_history_on_user_id ON ml_app_zeus_full.scantron_series_two_history USING btree (user_id);


--
-- Name: index_scantron_series_twos_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_scantron_series_twos_on_master_id ON ml_app_zeus_full.scantron_series_twos USING btree (master_id);


--
-- Name: index_scantron_series_twos_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_scantron_series_twos_on_user_id ON ml_app_zeus_full.scantron_series_twos USING btree (user_id);


--
-- Name: index_scantrons_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_scantrons_on_master_id ON ml_app_zeus_full.scantrons USING btree (master_id);


--
-- Name: index_scantrons_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_scantrons_on_user_id ON ml_app_zeus_full.scantrons USING btree (user_id);


--
-- Name: index_social_security_number_history_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_social_security_number_history_on_admin_id ON ml_app_zeus_full.social_security_number_history USING btree (admin_id);


--
-- Name: index_social_security_number_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_social_security_number_history_on_master_id ON ml_app_zeus_full.social_security_number_history USING btree (master_id);


--
-- Name: index_social_security_number_history_on_social_security_number_; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_social_security_number_history_on_social_security_number_ ON ml_app_zeus_full.social_security_number_history USING btree (social_security_number_table_id);


--
-- Name: index_social_security_number_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_social_security_number_history_on_user_id ON ml_app_zeus_full.social_security_number_history USING btree (user_id);


--
-- Name: index_social_security_numbers_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_social_security_numbers_on_admin_id ON ml_app_zeus_full.social_security_numbers USING btree (admin_id);


--
-- Name: index_social_security_numbers_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_social_security_numbers_on_master_id ON ml_app_zeus_full.social_security_numbers USING btree (master_id);


--
-- Name: index_social_security_numbers_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_social_security_numbers_on_user_id ON ml_app_zeus_full.social_security_numbers USING btree (user_id);


--
-- Name: index_sub_process_history_on_sub_process_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_sub_process_history_on_sub_process_id ON ml_app_zeus_full.sub_process_history USING btree (sub_process_id);


--
-- Name: index_sub_processes_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_sub_processes_on_admin_id ON ml_app_zeus_full.sub_processes USING btree (admin_id);


--
-- Name: index_sub_processes_on_protocol_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_sub_processes_on_protocol_id ON ml_app_zeus_full.sub_processes USING btree (protocol_id);


--
-- Name: index_test1_history_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test1_history_on_admin_id ON ml_app_zeus_full.test1_history USING btree (admin_id);


--
-- Name: index_test1_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test1_history_on_master_id ON ml_app_zeus_full.test1_history USING btree (master_id);


--
-- Name: index_test1_history_on_test1_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test1_history_on_test1_table_id ON ml_app_zeus_full.test1_history USING btree (test1_table_id);


--
-- Name: index_test1_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test1_history_on_user_id ON ml_app_zeus_full.test1_history USING btree (user_id);


--
-- Name: index_test1s_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test1s_on_admin_id ON ml_app_zeus_full.test1s USING btree (admin_id);


--
-- Name: index_test1s_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test1s_on_master_id ON ml_app_zeus_full.test1s USING btree (master_id);


--
-- Name: index_test1s_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test1s_on_user_id ON ml_app_zeus_full.test1s USING btree (user_id);


--
-- Name: index_test2_history_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test2_history_on_admin_id ON ml_app_zeus_full.test2_history USING btree (admin_id);


--
-- Name: index_test2_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test2_history_on_master_id ON ml_app_zeus_full.test2_history USING btree (master_id);


--
-- Name: index_test2_history_on_test2_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test2_history_on_test2_table_id ON ml_app_zeus_full.test2_history USING btree (test2_table_id);


--
-- Name: index_test2_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test2_history_on_user_id ON ml_app_zeus_full.test2_history USING btree (user_id);


--
-- Name: index_test2s_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test2s_on_admin_id ON ml_app_zeus_full.test2s USING btree (admin_id);


--
-- Name: index_test2s_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test2s_on_master_id ON ml_app_zeus_full.test2s USING btree (master_id);


--
-- Name: index_test2s_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test2s_on_user_id ON ml_app_zeus_full.test2s USING btree (user_id);


--
-- Name: index_test_2_history_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_2_history_on_admin_id ON ml_app_zeus_full.test_2_history USING btree (admin_id);


--
-- Name: index_test_2_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_2_history_on_master_id ON ml_app_zeus_full.test_2_history USING btree (master_id);


--
-- Name: index_test_2_history_on_test_2_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_2_history_on_test_2_table_id ON ml_app_zeus_full.test_2_history USING btree (test_2_table_id);


--
-- Name: index_test_2_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_2_history_on_user_id ON ml_app_zeus_full.test_2_history USING btree (user_id);


--
-- Name: index_test_2s_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_2s_on_admin_id ON ml_app_zeus_full.test_2s USING btree (admin_id);


--
-- Name: index_test_2s_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_2s_on_master_id ON ml_app_zeus_full.test_2s USING btree (master_id);


--
-- Name: index_test_2s_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_2s_on_user_id ON ml_app_zeus_full.test_2s USING btree (user_id);


--
-- Name: index_test_ext2_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_ext2_history_on_master_id ON ml_app_zeus_full.test_ext2_history USING btree (master_id);


--
-- Name: index_test_ext2_history_on_test_ext2_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_ext2_history_on_test_ext2_table_id ON ml_app_zeus_full.test_ext2_history USING btree (test_ext2_table_id);


--
-- Name: index_test_ext2_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_ext2_history_on_user_id ON ml_app_zeus_full.test_ext2_history USING btree (user_id);


--
-- Name: index_test_ext2s_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_ext2s_on_master_id ON ml_app_zeus_full.test_ext2s USING btree (master_id);


--
-- Name: index_test_ext2s_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_ext2s_on_user_id ON ml_app_zeus_full.test_ext2s USING btree (user_id);


--
-- Name: index_test_ext_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_ext_history_on_master_id ON ml_app_zeus_full.test_ext_history USING btree (master_id);


--
-- Name: index_test_ext_history_on_test_ext_table_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_ext_history_on_test_ext_table_id ON ml_app_zeus_full.test_ext_history USING btree (test_ext_table_id);


--
-- Name: index_test_ext_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_ext_history_on_user_id ON ml_app_zeus_full.test_ext_history USING btree (user_id);


--
-- Name: index_test_exts_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_exts_on_master_id ON ml_app_zeus_full.test_exts USING btree (master_id);


--
-- Name: index_test_exts_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_exts_on_user_id ON ml_app_zeus_full.test_exts USING btree (user_id);


--
-- Name: index_test_item_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_item_history_on_master_id ON ml_app_zeus_full.test_item_history USING btree (master_id);


--
-- Name: index_test_item_history_on_test_item_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_item_history_on_test_item_id ON ml_app_zeus_full.test_item_history USING btree (test_item_id);


--
-- Name: index_test_item_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_item_history_on_user_id ON ml_app_zeus_full.test_item_history USING btree (user_id);


--
-- Name: index_test_items_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_items_on_master_id ON ml_app_zeus_full.test_items USING btree (master_id);


--
-- Name: index_test_items_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_test_items_on_user_id ON ml_app_zeus_full.test_items USING btree (user_id);


--
-- Name: index_tracker_history_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_tracker_history_on_master_id ON ml_app_zeus_full.tracker_history USING btree (master_id);


--
-- Name: index_tracker_history_on_protocol_event_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_tracker_history_on_protocol_event_id ON ml_app_zeus_full.tracker_history USING btree (protocol_event_id);


--
-- Name: index_tracker_history_on_protocol_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_tracker_history_on_protocol_id ON ml_app_zeus_full.tracker_history USING btree (protocol_id);


--
-- Name: index_tracker_history_on_sub_process_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_tracker_history_on_sub_process_id ON ml_app_zeus_full.tracker_history USING btree (sub_process_id);


--
-- Name: index_tracker_history_on_tracker_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_tracker_history_on_tracker_id ON ml_app_zeus_full.tracker_history USING btree (tracker_id);


--
-- Name: index_tracker_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_tracker_history_on_user_id ON ml_app_zeus_full.tracker_history USING btree (user_id);


--
-- Name: index_trackers_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_trackers_on_master_id ON ml_app_zeus_full.trackers USING btree (master_id);


--
-- Name: index_trackers_on_protocol_event_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_trackers_on_protocol_event_id ON ml_app_zeus_full.trackers USING btree (protocol_event_id);


--
-- Name: index_trackers_on_protocol_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_trackers_on_protocol_id ON ml_app_zeus_full.trackers USING btree (protocol_id);


--
-- Name: index_trackers_on_sub_process_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_trackers_on_sub_process_id ON ml_app_zeus_full.trackers USING btree (sub_process_id);


--
-- Name: index_trackers_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_trackers_on_user_id ON ml_app_zeus_full.trackers USING btree (user_id);


--
-- Name: index_user_access_controls_on_app_type_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_user_access_controls_on_app_type_id ON ml_app_zeus_full.user_access_controls USING btree (app_type_id);


--
-- Name: index_user_action_logs_on_app_type_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_user_action_logs_on_app_type_id ON ml_app_zeus_full.user_action_logs USING btree (app_type_id);


--
-- Name: index_user_action_logs_on_master_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_user_action_logs_on_master_id ON ml_app_zeus_full.user_action_logs USING btree (master_id);


--
-- Name: index_user_action_logs_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_user_action_logs_on_user_id ON ml_app_zeus_full.user_action_logs USING btree (user_id);


--
-- Name: index_user_authorization_history_on_user_authorization_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_user_authorization_history_on_user_authorization_id ON ml_app_zeus_full.user_authorization_history USING btree (user_authorization_id);


--
-- Name: index_user_history_on_app_type_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_user_history_on_app_type_id ON ml_app_zeus_full.user_history USING btree (app_type_id);


--
-- Name: index_user_history_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_user_history_on_user_id ON ml_app_zeus_full.user_history USING btree (user_id);


--
-- Name: index_user_roles_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_user_roles_on_admin_id ON ml_app_zeus_full.user_roles USING btree (admin_id);


--
-- Name: index_user_roles_on_app_type_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_user_roles_on_app_type_id ON ml_app_zeus_full.user_roles USING btree (app_type_id);


--
-- Name: index_user_roles_on_user_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_user_roles_on_user_id ON ml_app_zeus_full.user_roles USING btree (user_id);


--
-- Name: index_users_on_admin_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_users_on_admin_id ON ml_app_zeus_full.users USING btree (admin_id);


--
-- Name: index_users_on_app_type_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE INDEX index_users_on_app_type_id ON ml_app_zeus_full.users USING btree (app_type_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON ml_app_zeus_full.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON ml_app_zeus_full.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON ml_app_zeus_full.users USING btree (unlock_token);


--
-- Name: unique_master_protocol; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE UNIQUE INDEX unique_master_protocol ON ml_app_zeus_full.trackers USING btree (master_id, protocol_id);


--
-- Name: unique_master_protocol_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE UNIQUE INDEX unique_master_protocol_id ON ml_app_zeus_full.trackers USING btree (master_id, protocol_id, id);


--
-- Name: unique_protocol_and_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE UNIQUE INDEX unique_protocol_and_id ON ml_app_zeus_full.sub_processes USING btree (protocol_id, id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON ml_app_zeus_full.schema_migrations USING btree (version);


--
-- Name: unique_sub_process_and_id; Type: INDEX; Schema: ml_app_zeus_full; Owner: -
--

CREATE UNIQUE INDEX unique_sub_process_and_id ON ml_app_zeus_full.protocol_events USING btree (sub_process_id, id);


--
-- Name: accuracy_scores accuracy_score_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER accuracy_score_history_insert AFTER INSERT ON ml_app_zeus_full.accuracy_scores FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_accuracy_score_update();


--
-- Name: accuracy_scores accuracy_score_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER accuracy_score_history_update AFTER UPDATE ON ml_app_zeus_full.accuracy_scores FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_accuracy_score_update();


--
-- Name: activity_log_bhs_assignments activity_log_bhs_assignment_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_bhs_assignment_history_insert AFTER INSERT ON ml_app_zeus_full.activity_log_bhs_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_bhs_assignment_update();


--
-- Name: activity_log_bhs_assignments activity_log_bhs_assignment_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_bhs_assignment_history_update AFTER UPDATE ON ml_app_zeus_full.activity_log_bhs_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_bhs_assignment_update();


--
-- Name: activity_log_ext_assignments activity_log_ext_assignment_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_ext_assignment_history_insert AFTER INSERT ON ml_app_zeus_full.activity_log_ext_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_ext_assignment_update();


--
-- Name: activity_log_ext_assignments activity_log_ext_assignment_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_ext_assignment_history_update AFTER UPDATE ON ml_app_zeus_full.activity_log_ext_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_ext_assignment_update();


--
-- Name: activity_logs activity_log_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_history_insert AFTER INSERT ON ml_app_zeus_full.activity_logs FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_update();


--
-- Name: activity_logs activity_log_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_history_update AFTER UPDATE ON ml_app_zeus_full.activity_logs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_update();


--
-- Name: activity_log_ipa_assignments activity_log_ipa_assignment_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_history_insert AFTER INSERT ON ml_app_zeus_full.activity_log_ipa_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_ipa_assignment_update();


--
-- Name: activity_log_ipa_assignments activity_log_ipa_assignment_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_history_update AFTER UPDATE ON ml_app_zeus_full.activity_log_ipa_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_ipa_assignment_update();


--
-- Name: activity_log_ipa_assignment_minor_deviations activity_log_ipa_assignment_minor_deviation_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_minor_deviation_history_insert AFTER INSERT ON ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_ipa_assignment_minor_deviation_update();


--
-- Name: activity_log_ipa_assignment_minor_deviations activity_log_ipa_assignment_minor_deviation_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_minor_deviation_history_update AFTER UPDATE ON ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_ipa_assignment_minor_deviation_update();


--
-- Name: activity_log_ipa_surveys activity_log_ipa_survey_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_ipa_survey_history_insert AFTER INSERT ON ml_app_zeus_full.activity_log_ipa_surveys FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_ipa_survey_update();


--
-- Name: activity_log_ipa_surveys activity_log_ipa_survey_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_ipa_survey_history_update AFTER UPDATE ON ml_app_zeus_full.activity_log_ipa_surveys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_ipa_survey_update();


--
-- Name: activity_log_new_tests activity_log_new_test_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_new_test_history_insert AFTER INSERT ON ml_app_zeus_full.activity_log_new_tests FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_new_test_update();


--
-- Name: activity_log_new_tests activity_log_new_test_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_new_test_history_update AFTER UPDATE ON ml_app_zeus_full.activity_log_new_tests FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_new_test_update();


--
-- Name: activity_log_player_contact_phones activity_log_player_contact_phone_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_player_contact_phone_history_insert AFTER INSERT ON ml_app_zeus_full.activity_log_player_contact_phones FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_player_contact_phone_update();


--
-- Name: activity_log_player_contact_phones activity_log_player_contact_phone_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_player_contact_phone_history_update AFTER UPDATE ON ml_app_zeus_full.activity_log_player_contact_phones FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_player_contact_phone_update();


--
-- Name: activity_log_player_infos activity_log_player_info_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_player_info_history_insert AFTER INSERT ON ml_app_zeus_full.activity_log_player_infos FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_player_info_update();


--
-- Name: activity_log_player_infos activity_log_player_info_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER activity_log_player_info_history_update AFTER UPDATE ON ml_app_zeus_full.activity_log_player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_activity_log_player_info_update();


--
-- Name: addresses address_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER address_history_insert AFTER INSERT ON ml_app_zeus_full.addresses FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_address_update();


--
-- Name: addresses address_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER address_history_update AFTER UPDATE ON ml_app_zeus_full.addresses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_address_update();


--
-- Name: addresses address_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER address_insert BEFORE INSERT ON ml_app_zeus_full.addresses FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.handle_address_update();


--
-- Name: addresses address_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER address_update BEFORE UPDATE ON ml_app_zeus_full.addresses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.handle_address_update();


--
-- Name: admins admin_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER admin_history_insert AFTER INSERT ON ml_app_zeus_full.admins FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_admin_update();


--
-- Name: admins admin_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER admin_history_update AFTER UPDATE ON ml_app_zeus_full.admins FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_admin_update();


--
-- Name: bhs_assignments bhs_assignment_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER bhs_assignment_history_insert AFTER INSERT ON ml_app_zeus_full.bhs_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_bhs_assignment_update();


--
-- Name: bhs_assignments bhs_assignment_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER bhs_assignment_history_update AFTER UPDATE ON ml_app_zeus_full.bhs_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_bhs_assignment_update();


--
-- Name: colleges college_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER college_history_insert AFTER INSERT ON ml_app_zeus_full.colleges FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_college_update();


--
-- Name: colleges college_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER college_history_update AFTER UPDATE ON ml_app_zeus_full.colleges FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_college_update();


--
-- Name: dynamic_models dynamic_model_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER dynamic_model_history_insert AFTER INSERT ON ml_app_zeus_full.dynamic_models FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_dynamic_model_update();


--
-- Name: dynamic_models dynamic_model_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER dynamic_model_history_update AFTER UPDATE ON ml_app_zeus_full.dynamic_models FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_dynamic_model_update();


--
-- Name: ext_assignments ext_assignment_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ext_assignment_history_insert AFTER INSERT ON ml_app_zeus_full.ext_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_ext_assignment_update();


--
-- Name: ext_assignments ext_assignment_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ext_assignment_history_update AFTER UPDATE ON ml_app_zeus_full.ext_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_ext_assignment_update();


--
-- Name: ext_gen_assignments ext_gen_assignment_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ext_gen_assignment_history_insert AFTER INSERT ON ml_app_zeus_full.ext_gen_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_ext_gen_assignment_update();


--
-- Name: ext_gen_assignments ext_gen_assignment_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ext_gen_assignment_history_update AFTER UPDATE ON ml_app_zeus_full.ext_gen_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_ext_gen_assignment_update();


--
-- Name: external_identifiers external_identifier_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER external_identifier_history_insert AFTER INSERT ON ml_app_zeus_full.external_identifiers FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_external_identifier_update();


--
-- Name: external_identifiers external_identifier_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER external_identifier_history_update AFTER UPDATE ON ml_app_zeus_full.external_identifiers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_external_identifier_update();


--
-- Name: external_links external_link_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER external_link_history_insert AFTER INSERT ON ml_app_zeus_full.external_links FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_external_link_update();


--
-- Name: external_links external_link_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER external_link_history_update AFTER UPDATE ON ml_app_zeus_full.external_links FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_external_link_update();


--
-- Name: general_selections general_selection_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER general_selection_history_insert AFTER INSERT ON ml_app_zeus_full.general_selections FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_general_selection_update();


--
-- Name: general_selections general_selection_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER general_selection_history_update AFTER UPDATE ON ml_app_zeus_full.general_selections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_general_selection_update();


--
-- Name: ipa_appointments ipa_appointment_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_appointment_history_insert AFTER INSERT ON ml_app_zeus_full.ipa_appointments FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_appointment_update();


--
-- Name: ipa_appointments ipa_appointment_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_appointment_history_update AFTER UPDATE ON ml_app_zeus_full.ipa_appointments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_appointment_update();


--
-- Name: ipa_assignments ipa_assignment_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_assignment_history_insert AFTER INSERT ON ml_app_zeus_full.ipa_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_assignment_update();


--
-- Name: ipa_assignments ipa_assignment_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_assignment_history_update AFTER UPDATE ON ml_app_zeus_full.ipa_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_assignment_update();


--
-- Name: ipa_consent_mailings ipa_consent_mailing_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_consent_mailing_history_insert AFTER INSERT ON ml_app_zeus_full.ipa_consent_mailings FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_consent_mailing_update();


--
-- Name: ipa_consent_mailings ipa_consent_mailing_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_consent_mailing_history_update AFTER UPDATE ON ml_app_zeus_full.ipa_consent_mailings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_consent_mailing_update();


--
-- Name: ipa_hotels ipa_hotel_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_hotel_history_insert AFTER INSERT ON ml_app_zeus_full.ipa_hotels FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_hotel_update();


--
-- Name: ipa_hotels ipa_hotel_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_hotel_history_update AFTER UPDATE ON ml_app_zeus_full.ipa_hotels FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_hotel_update();


--
-- Name: ipa_payments ipa_payment_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_payment_history_insert AFTER INSERT ON ml_app_zeus_full.ipa_payments FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_payment_update();


--
-- Name: ipa_payments ipa_payment_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_payment_history_update AFTER UPDATE ON ml_app_zeus_full.ipa_payments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_payment_update();


--
-- Name: ipa_screenings ipa_screening_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_screening_history_insert AFTER INSERT ON ml_app_zeus_full.ipa_screenings FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_screening_update();


--
-- Name: ipa_screenings ipa_screening_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_screening_history_update AFTER UPDATE ON ml_app_zeus_full.ipa_screenings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_screening_update();


--
-- Name: ipa_surveys ipa_survey_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_survey_history_insert AFTER INSERT ON ml_app_zeus_full.ipa_surveys FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_survey_update();


--
-- Name: ipa_surveys ipa_survey_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_survey_history_update AFTER UPDATE ON ml_app_zeus_full.ipa_surveys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_survey_update();


--
-- Name: ipa_transportations ipa_transportation_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_transportation_history_insert AFTER INSERT ON ml_app_zeus_full.ipa_transportations FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_transportation_update();


--
-- Name: ipa_transportations ipa_transportation_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER ipa_transportation_history_update AFTER UPDATE ON ml_app_zeus_full.ipa_transportations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_ipa_transportation_update();


--
-- Name: item_flags item_flag_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER item_flag_history_insert AFTER INSERT ON ml_app_zeus_full.item_flags FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_item_flag_update();


--
-- Name: item_flags item_flag_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER item_flag_history_update AFTER UPDATE ON ml_app_zeus_full.item_flags FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_item_flag_update();


--
-- Name: item_flag_names item_flag_name_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER item_flag_name_history_insert AFTER INSERT ON ml_app_zeus_full.item_flag_names FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_item_flag_name_update();


--
-- Name: item_flag_names item_flag_name_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER item_flag_name_history_update AFTER UPDATE ON ml_app_zeus_full.item_flag_names FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_item_flag_name_update();


--
-- Name: mrn_numbers mrn_number_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER mrn_number_history_insert AFTER INSERT ON ml_app_zeus_full.mrn_numbers FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_mrn_number_update();


--
-- Name: mrn_numbers mrn_number_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER mrn_number_history_update AFTER UPDATE ON ml_app_zeus_full.mrn_numbers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_mrn_number_update();


--
-- Name: new_tests new_test_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER new_test_history_insert AFTER INSERT ON ml_app_zeus_full.new_tests FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_new_test_update();


--
-- Name: new_tests new_test_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER new_test_history_update AFTER UPDATE ON ml_app_zeus_full.new_tests FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_new_test_update();


--
-- Name: player_contacts player_contact_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER player_contact_history_insert AFTER INSERT ON ml_app_zeus_full.player_contacts FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_player_contact_update();


--
-- Name: player_contacts player_contact_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER player_contact_history_update AFTER UPDATE ON ml_app_zeus_full.player_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_player_contact_update();


--
-- Name: player_contacts player_contact_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER player_contact_insert BEFORE INSERT ON ml_app_zeus_full.player_contacts FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.handle_player_contact_update();


--
-- Name: player_contacts player_contact_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER player_contact_update BEFORE UPDATE ON ml_app_zeus_full.player_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.handle_player_contact_update();


--
-- Name: player_infos player_info_before_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER player_info_before_update BEFORE UPDATE ON ml_app_zeus_full.player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.handle_player_info_before_update();


--
-- Name: player_infos player_info_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER player_info_history_insert AFTER INSERT ON ml_app_zeus_full.player_infos FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_player_info_update();


--
-- Name: player_infos player_info_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER player_info_history_update AFTER UPDATE ON ml_app_zeus_full.player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_player_info_update();


--
-- Name: player_infos player_info_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER player_info_insert AFTER INSERT ON ml_app_zeus_full.player_infos FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.update_master_with_player_info();


--
-- Name: player_infos player_info_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER player_info_update AFTER UPDATE ON ml_app_zeus_full.player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.update_master_with_player_info();


--
-- Name: pro_infos pro_info_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER pro_info_insert AFTER INSERT ON ml_app_zeus_full.pro_infos FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.update_master_with_pro_info();


--
-- Name: pro_infos pro_info_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER pro_info_update AFTER UPDATE ON ml_app_zeus_full.pro_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.update_master_with_pro_info();


--
-- Name: protocol_events protocol_event_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER protocol_event_history_insert AFTER INSERT ON ml_app_zeus_full.protocol_events FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_protocol_event_update();


--
-- Name: protocol_events protocol_event_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER protocol_event_history_update AFTER UPDATE ON ml_app_zeus_full.protocol_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_protocol_event_update();


--
-- Name: protocols protocol_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER protocol_history_insert AFTER INSERT ON ml_app_zeus_full.protocols FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_protocol_update();


--
-- Name: protocols protocol_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER protocol_history_update AFTER UPDATE ON ml_app_zeus_full.protocols FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_protocol_update();


--
-- Name: rc_stage_cif_copy rc_cis_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER rc_cis_update BEFORE UPDATE ON ml_app_zeus_full.rc_stage_cif_copy FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.handle_rc_cis_update();


--
-- Name: reports report_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER report_history_insert AFTER INSERT ON ml_app_zeus_full.reports FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_report_update();


--
-- Name: reports report_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER report_history_update AFTER UPDATE ON ml_app_zeus_full.reports FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_report_update();


--
-- Name: scantrons scantron_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER scantron_history_insert AFTER INSERT ON ml_app_zeus_full.scantrons FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_scantron_update();


--
-- Name: scantrons scantron_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER scantron_history_update AFTER UPDATE ON ml_app_zeus_full.scantrons FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_scantron_update();


--
-- Name: social_security_numbers social_security_number_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER social_security_number_history_insert AFTER INSERT ON ml_app_zeus_full.social_security_numbers FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_social_security_number_update();


--
-- Name: social_security_numbers social_security_number_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER social_security_number_history_update AFTER UPDATE ON ml_app_zeus_full.social_security_numbers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_social_security_number_update();


--
-- Name: sub_processes sub_process_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER sub_process_history_insert AFTER INSERT ON ml_app_zeus_full.sub_processes FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_sub_process_update();


--
-- Name: sub_processes sub_process_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER sub_process_history_update AFTER UPDATE ON ml_app_zeus_full.sub_processes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_sub_process_update();


--
-- Name: test1s test1_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER test1_history_insert AFTER INSERT ON ml_app_zeus_full.test1s FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_test1_update();


--
-- Name: test1s test1_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER test1_history_update AFTER UPDATE ON ml_app_zeus_full.test1s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_test1_update();


--
-- Name: test2s test2_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER test2_history_insert AFTER INSERT ON ml_app_zeus_full.test2s FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_test2_update();


--
-- Name: test2s test2_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER test2_history_update AFTER UPDATE ON ml_app_zeus_full.test2s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_test2_update();


--
-- Name: test_2s test_2_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER test_2_history_insert AFTER INSERT ON ml_app_zeus_full.test_2s FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_test_2_update();


--
-- Name: test_2s test_2_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER test_2_history_update AFTER UPDATE ON ml_app_zeus_full.test_2s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_test_2_update();


--
-- Name: test_ext2s test_ext2_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER test_ext2_history_insert AFTER INSERT ON ml_app_zeus_full.test_ext2s FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_test_ext2_update();


--
-- Name: test_ext2s test_ext2_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER test_ext2_history_update AFTER UPDATE ON ml_app_zeus_full.test_ext2s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_test_ext2_update();


--
-- Name: test_exts test_ext_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER test_ext_history_insert AFTER INSERT ON ml_app_zeus_full.test_exts FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_test_ext_update();


--
-- Name: test_exts test_ext_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER test_ext_history_update AFTER UPDATE ON ml_app_zeus_full.test_exts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_test_ext_update();


--
-- Name: trackers tracker_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER tracker_history_insert AFTER INSERT ON ml_app_zeus_full.trackers FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_tracker_update();


--
-- Name: trackers tracker_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER tracker_history_update AFTER UPDATE ON ml_app_zeus_full.trackers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_tracker_update();


--
-- Name: tracker_history tracker_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER tracker_history_update BEFORE UPDATE ON ml_app_zeus_full.tracker_history FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.handle_tracker_history_update();


--
-- Name: tracker_history tracker_record_delete; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER tracker_record_delete AFTER DELETE ON ml_app_zeus_full.tracker_history FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.handle_delete();


--
-- Name: trackers tracker_upsert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER tracker_upsert BEFORE INSERT ON ml_app_zeus_full.trackers FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.tracker_upsert();


--
-- Name: user_authorizations user_authorization_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER user_authorization_history_insert AFTER INSERT ON ml_app_zeus_full.user_authorizations FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_user_authorization_update();


--
-- Name: user_authorizations user_authorization_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER user_authorization_history_update AFTER UPDATE ON ml_app_zeus_full.user_authorizations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_user_authorization_update();


--
-- Name: users user_history_insert; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER user_history_insert AFTER INSERT ON ml_app_zeus_full.users FOR EACH ROW EXECUTE PROCEDURE ml_app_zeus_full.log_user_update();


--
-- Name: users user_history_update; Type: TRIGGER; Schema: ml_app_zeus_full; Owner: -
--

CREATE TRIGGER user_history_update AFTER UPDATE ON ml_app_zeus_full.users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app_zeus_full.log_user_update();


--
-- Name: accuracy_score_history fk_accuracy_score_history_accuracy_scores; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.accuracy_score_history
    ADD CONSTRAINT fk_accuracy_score_history_accuracy_scores FOREIGN KEY (accuracy_score_id) REFERENCES ml_app_zeus_full.accuracy_scores(id);


--
-- Name: activity_log_bhs_assignment_history fk_activity_log_bhs_assignment_history_activity_log_bhs_assignm; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_bhs_assignment_history
    ADD CONSTRAINT fk_activity_log_bhs_assignment_history_activity_log_bhs_assignm FOREIGN KEY (activity_log_bhs_assignment_id) REFERENCES ml_app_zeus_full.activity_log_bhs_assignments(id);


--
-- Name: activity_log_bhs_assignment_history fk_activity_log_bhs_assignment_history_bhs_assignment_id; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_bhs_assignment_history
    ADD CONSTRAINT fk_activity_log_bhs_assignment_history_bhs_assignment_id FOREIGN KEY (bhs_assignment_id) REFERENCES ml_app_zeus_full.bhs_assignments(id);


--
-- Name: activity_log_bhs_assignment_history fk_activity_log_bhs_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_bhs_assignment_history
    ADD CONSTRAINT fk_activity_log_bhs_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_bhs_assignment_history fk_activity_log_bhs_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_bhs_assignment_history
    ADD CONSTRAINT fk_activity_log_bhs_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_ext_assignment_history fk_activity_log_ext_assignment_history_activity_log_ext_assignm; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_activity_log_ext_assignm FOREIGN KEY (activity_log_ext_assignment_id) REFERENCES ml_app_zeus_full.activity_log_ext_assignments(id);


--
-- Name: activity_log_ext_assignment_history fk_activity_log_ext_assignment_history_ext_assignment_id; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_ext_assignment_id FOREIGN KEY (ext_assignment_id) REFERENCES ml_app_zeus_full.ext_assignments(id);


--
-- Name: activity_log_ext_assignment_history fk_activity_log_ext_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_ext_assignment_history fk_activity_log_ext_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_ipa_assignment_history fk_activity_log_ipa_assignment_history_activity_log_ipa_assignm; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_activity_log_ipa_assignm FOREIGN KEY (activity_log_ipa_assignment_id) REFERENCES ml_app_zeus_full.activity_log_ipa_assignments(id);


--
-- Name: activity_log_ipa_assignment_history fk_activity_log_ipa_assignment_history_ipa_assignment_id; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_ipa_assignment_id FOREIGN KEY (ipa_assignment_id) REFERENCES ml_app_zeus_full.ipa_assignments(id);


--
-- Name: activity_log_ipa_assignment_history fk_activity_log_ipa_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_ipa_assignment_history fk_activity_log_ipa_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_ipa_assignment_minor_deviation_history fk_activity_log_ipa_assignment_minor_deviation_history_activity; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_activity FOREIGN KEY (activity_log_ipa_assignment_minor_deviation_id) REFERENCES ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations(id);


--
-- Name: activity_log_ipa_assignment_minor_deviation_history fk_activity_log_ipa_assignment_minor_deviation_history_ipa_assi; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_ipa_assi FOREIGN KEY (ipa_assignment_id) REFERENCES ml_app_zeus_full.ipa_assignments(id);


--
-- Name: activity_log_ipa_assignment_minor_deviation_history fk_activity_log_ipa_assignment_minor_deviation_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_ipa_assignment_minor_deviation_history fk_activity_log_ipa_assignment_minor_deviation_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_ipa_survey_history fk_activity_log_ipa_survey_history_activity_log_ipa_surveys; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_survey_history
    ADD CONSTRAINT fk_activity_log_ipa_survey_history_activity_log_ipa_surveys FOREIGN KEY (activity_log_ipa_survey_id) REFERENCES ml_app_zeus_full.activity_log_ipa_surveys(id);


--
-- Name: activity_log_ipa_survey_history fk_activity_log_ipa_survey_history_ipa_survey_id; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_survey_history
    ADD CONSTRAINT fk_activity_log_ipa_survey_history_ipa_survey_id FOREIGN KEY (ipa_survey_id) REFERENCES ml_app_zeus_full.ipa_surveys(id);


--
-- Name: activity_log_ipa_survey_history fk_activity_log_ipa_survey_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_survey_history
    ADD CONSTRAINT fk_activity_log_ipa_survey_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_ipa_survey_history fk_activity_log_ipa_survey_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_survey_history
    ADD CONSTRAINT fk_activity_log_ipa_survey_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_new_test_history fk_activity_log_new_test_history_activity_log_new_tests; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_activity_log_new_tests FOREIGN KEY (activity_log_new_test_id) REFERENCES ml_app_zeus_full.activity_log_new_tests(id);


--
-- Name: activity_log_new_test_history fk_activity_log_new_test_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_new_test_history fk_activity_log_new_test_history_new_test_id; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_new_test_id FOREIGN KEY (new_test_id) REFERENCES ml_app_zeus_full.new_tests(id);


--
-- Name: activity_log_new_test_history fk_activity_log_new_test_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_player_contact_phone_history fk_activity_log_player_contact_phone_history_activity_log_playe; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_activity_log_playe FOREIGN KEY (activity_log_player_contact_phone_id) REFERENCES ml_app_zeus_full.activity_log_player_contact_phones(id);


--
-- Name: activity_log_player_contact_phone_history fk_activity_log_player_contact_phone_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_player_contact_phone_history fk_activity_log_player_contact_phone_history_player_contact_pho; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_player_contact_pho FOREIGN KEY (player_contact_id) REFERENCES ml_app_zeus_full.player_contacts(id);


--
-- Name: activity_log_player_contact_phone_history fk_activity_log_player_contact_phone_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_player_info_history fk_activity_log_player_info_history_activity_log_player_infos; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_activity_log_player_infos FOREIGN KEY (activity_log_player_info_id) REFERENCES ml_app_zeus_full.activity_log_player_infos(id);


--
-- Name: activity_log_player_info_history fk_activity_log_player_info_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_player_info_history fk_activity_log_player_info_history_player_info_id; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_player_info_id FOREIGN KEY (player_info_id) REFERENCES ml_app_zeus_full.player_infos(id);


--
-- Name: activity_log_player_info_history fk_activity_log_player_info_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: address_history fk_address_history_addresses; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.address_history
    ADD CONSTRAINT fk_address_history_addresses FOREIGN KEY (address_id) REFERENCES ml_app_zeus_full.addresses(id);


--
-- Name: address_history fk_address_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.address_history
    ADD CONSTRAINT fk_address_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: address_history fk_address_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.address_history
    ADD CONSTRAINT fk_address_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: admin_history fk_admin_history_admins; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.admin_history
    ADD CONSTRAINT fk_admin_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: bhs_assignment_history fk_bhs_assignment_history_admins; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.bhs_assignment_history
    ADD CONSTRAINT fk_bhs_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: bhs_assignment_history fk_bhs_assignment_history_bhs_assignments; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.bhs_assignment_history
    ADD CONSTRAINT fk_bhs_assignment_history_bhs_assignments FOREIGN KEY (bhs_assignment_table_id) REFERENCES ml_app_zeus_full.bhs_assignments(id);


--
-- Name: bhs_assignment_history fk_bhs_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.bhs_assignment_history
    ADD CONSTRAINT fk_bhs_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: bhs_assignment_history fk_bhs_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.bhs_assignment_history
    ADD CONSTRAINT fk_bhs_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: college_history fk_college_history_colleges; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.college_history
    ADD CONSTRAINT fk_college_history_colleges FOREIGN KEY (college_id) REFERENCES ml_app_zeus_full.colleges(id);


--
-- Name: dynamic_model_history fk_dynamic_model_history_dynamic_models; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.dynamic_model_history
    ADD CONSTRAINT fk_dynamic_model_history_dynamic_models FOREIGN KEY (dynamic_model_id) REFERENCES ml_app_zeus_full.dynamic_models(id);


--
-- Name: ext_assignment_history fk_ext_assignment_history_ext_assignments; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_assignment_history
    ADD CONSTRAINT fk_ext_assignment_history_ext_assignments FOREIGN KEY (ext_assignment_table_id) REFERENCES ml_app_zeus_full.ext_assignments(id);


--
-- Name: ext_assignment_history fk_ext_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_assignment_history
    ADD CONSTRAINT fk_ext_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ext_assignment_history fk_ext_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_assignment_history
    ADD CONSTRAINT fk_ext_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ext_gen_assignment_history fk_ext_gen_assignment_history_admins; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: ext_gen_assignment_history fk_ext_gen_assignment_history_ext_gen_assignments; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_ext_gen_assignments FOREIGN KEY (ext_gen_assignment_table_id) REFERENCES ml_app_zeus_full.ext_gen_assignments(id);


--
-- Name: ext_gen_assignment_history fk_ext_gen_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ext_gen_assignment_history fk_ext_gen_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: external_link_history fk_external_link_history_external_links; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_link_history
    ADD CONSTRAINT fk_external_link_history_external_links FOREIGN KEY (external_link_id) REFERENCES ml_app_zeus_full.external_links(id);


--
-- Name: general_selection_history fk_general_selection_history_general_selections; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.general_selection_history
    ADD CONSTRAINT fk_general_selection_history_general_selections FOREIGN KEY (general_selection_id) REFERENCES ml_app_zeus_full.general_selections(id);


--
-- Name: ipa_appointment_history fk_ipa_appointment_history_ipa_appointments; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_appointment_history
    ADD CONSTRAINT fk_ipa_appointment_history_ipa_appointments FOREIGN KEY (ipa_appointment_id) REFERENCES ml_app_zeus_full.ipa_appointments(id);


--
-- Name: ipa_appointment_history fk_ipa_appointment_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_appointment_history
    ADD CONSTRAINT fk_ipa_appointment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_appointment_history fk_ipa_appointment_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_appointment_history
    ADD CONSTRAINT fk_ipa_appointment_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_assignment_history fk_ipa_assignment_history_admins; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: ipa_assignment_history fk_ipa_assignment_history_ipa_assignments; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_ipa_assignments FOREIGN KEY (ipa_assignment_table_id) REFERENCES ml_app_zeus_full.ipa_assignments(id);


--
-- Name: ipa_assignment_history fk_ipa_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_assignment_history fk_ipa_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_consent_mailing_history fk_ipa_consent_mailing_history_ipa_consent_mailings; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_consent_mailing_history
    ADD CONSTRAINT fk_ipa_consent_mailing_history_ipa_consent_mailings FOREIGN KEY (ipa_consent_mailing_id) REFERENCES ml_app_zeus_full.ipa_consent_mailings(id);


--
-- Name: ipa_consent_mailing_history fk_ipa_consent_mailing_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_consent_mailing_history
    ADD CONSTRAINT fk_ipa_consent_mailing_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_consent_mailing_history fk_ipa_consent_mailing_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_consent_mailing_history
    ADD CONSTRAINT fk_ipa_consent_mailing_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_hotel_history fk_ipa_hotel_history_ipa_hotels; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_hotel_history
    ADD CONSTRAINT fk_ipa_hotel_history_ipa_hotels FOREIGN KEY (ipa_hotel_id) REFERENCES ml_app_zeus_full.ipa_hotels(id);


--
-- Name: ipa_hotel_history fk_ipa_hotel_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_hotel_history
    ADD CONSTRAINT fk_ipa_hotel_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_hotel_history fk_ipa_hotel_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_hotel_history
    ADD CONSTRAINT fk_ipa_hotel_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_payment_history fk_ipa_payment_history_ipa_payments; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_payment_history
    ADD CONSTRAINT fk_ipa_payment_history_ipa_payments FOREIGN KEY (ipa_payment_id) REFERENCES ml_app_zeus_full.ipa_payments(id);


--
-- Name: ipa_payment_history fk_ipa_payment_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_payment_history
    ADD CONSTRAINT fk_ipa_payment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_payment_history fk_ipa_payment_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_payment_history
    ADD CONSTRAINT fk_ipa_payment_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_screening_history fk_ipa_screening_history_ipa_screenings; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_screening_history
    ADD CONSTRAINT fk_ipa_screening_history_ipa_screenings FOREIGN KEY (ipa_screening_id) REFERENCES ml_app_zeus_full.ipa_screenings(id);


--
-- Name: ipa_screening_history fk_ipa_screening_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_screening_history
    ADD CONSTRAINT fk_ipa_screening_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_screening_history fk_ipa_screening_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_screening_history
    ADD CONSTRAINT fk_ipa_screening_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_survey_history fk_ipa_survey_history_ipa_surveys; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_survey_history
    ADD CONSTRAINT fk_ipa_survey_history_ipa_surveys FOREIGN KEY (ipa_survey_id) REFERENCES ml_app_zeus_full.ipa_surveys(id);


--
-- Name: ipa_survey_history fk_ipa_survey_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_survey_history
    ADD CONSTRAINT fk_ipa_survey_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_survey_history fk_ipa_survey_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_survey_history
    ADD CONSTRAINT fk_ipa_survey_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_transportation_history fk_ipa_transportation_history_ipa_transportations; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_transportation_history
    ADD CONSTRAINT fk_ipa_transportation_history_ipa_transportations FOREIGN KEY (ipa_transportation_id) REFERENCES ml_app_zeus_full.ipa_transportations(id);


--
-- Name: ipa_transportation_history fk_ipa_transportation_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_transportation_history
    ADD CONSTRAINT fk_ipa_transportation_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_transportation_history fk_ipa_transportation_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_transportation_history
    ADD CONSTRAINT fk_ipa_transportation_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: item_flag_history fk_item_flag_history_item_flags; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flag_history
    ADD CONSTRAINT fk_item_flag_history_item_flags FOREIGN KEY (item_flag_id) REFERENCES ml_app_zeus_full.item_flags(id);


--
-- Name: item_flag_name_history fk_item_flag_name_history_item_flag_names; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flag_name_history
    ADD CONSTRAINT fk_item_flag_name_history_item_flag_names FOREIGN KEY (item_flag_name_id) REFERENCES ml_app_zeus_full.item_flag_names(id);


--
-- Name: mrn_number_history fk_mrn_number_history_admins; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.mrn_number_history
    ADD CONSTRAINT fk_mrn_number_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: mrn_number_history fk_mrn_number_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.mrn_number_history
    ADD CONSTRAINT fk_mrn_number_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: mrn_number_history fk_mrn_number_history_mrn_numbers; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.mrn_number_history
    ADD CONSTRAINT fk_mrn_number_history_mrn_numbers FOREIGN KEY (mrn_number_table_id) REFERENCES ml_app_zeus_full.mrn_numbers(id);


--
-- Name: mrn_number_history fk_mrn_number_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.mrn_number_history
    ADD CONSTRAINT fk_mrn_number_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: new_test_history fk_new_test_history_admins; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.new_test_history
    ADD CONSTRAINT fk_new_test_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: new_test_history fk_new_test_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.new_test_history
    ADD CONSTRAINT fk_new_test_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: new_test_history fk_new_test_history_new_tests; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.new_test_history
    ADD CONSTRAINT fk_new_test_history_new_tests FOREIGN KEY (new_test_table_id) REFERENCES ml_app_zeus_full.new_tests(id);


--
-- Name: new_test_history fk_new_test_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.new_test_history
    ADD CONSTRAINT fk_new_test_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: player_contact_history fk_player_contact_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_contact_history
    ADD CONSTRAINT fk_player_contact_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: player_contact_history fk_player_contact_history_player_contacts; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_contact_history
    ADD CONSTRAINT fk_player_contact_history_player_contacts FOREIGN KEY (player_contact_id) REFERENCES ml_app_zeus_full.player_contacts(id);


--
-- Name: player_contact_history fk_player_contact_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_contact_history
    ADD CONSTRAINT fk_player_contact_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: player_info_history fk_player_info_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_info_history
    ADD CONSTRAINT fk_player_info_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: player_info_history fk_player_info_history_player_infos; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_info_history
    ADD CONSTRAINT fk_player_info_history_player_infos FOREIGN KEY (player_info_id) REFERENCES ml_app_zeus_full.player_infos(id);


--
-- Name: player_info_history fk_player_info_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_info_history
    ADD CONSTRAINT fk_player_info_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: protocol_event_history fk_protocol_event_history_protocol_events; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocol_event_history
    ADD CONSTRAINT fk_protocol_event_history_protocol_events FOREIGN KEY (protocol_event_id) REFERENCES ml_app_zeus_full.protocol_events(id);


--
-- Name: protocol_history fk_protocol_history_protocols; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocol_history
    ADD CONSTRAINT fk_protocol_history_protocols FOREIGN KEY (protocol_id) REFERENCES ml_app_zeus_full.protocols(id);


--
-- Name: masters fk_rails_00b234154d; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.masters
    ADD CONSTRAINT fk_rails_00b234154d FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: app_configurations fk_rails_00f31a00c4; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.app_configurations
    ADD CONSTRAINT fk_rails_00f31a00c4 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: external_identifier_history fk_rails_0210618434; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_identifier_history
    ADD CONSTRAINT fk_rails_0210618434 FOREIGN KEY (external_identifier_id) REFERENCES ml_app_zeus_full.external_identifiers(id);


--
-- Name: player_infos fk_rails_08e7f66647; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_infos
    ADD CONSTRAINT fk_rails_08e7f66647 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: user_action_logs fk_rails_08eec3f089; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_action_logs
    ADD CONSTRAINT fk_rails_08eec3f089 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: protocol_events fk_rails_0a64e1160a; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocol_events
    ADD CONSTRAINT fk_rails_0a64e1160a FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: users fk_rails_1694bfe639; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.users
    ADD CONSTRAINT fk_rails_1694bfe639 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: activity_log_history fk_rails_16d57266f7; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_history
    ADD CONSTRAINT fk_rails_16d57266f7 FOREIGN KEY (activity_log_id) REFERENCES ml_app_zeus_full.activity_logs(id);


--
-- Name: user_roles fk_rails_174e058eb3; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_roles
    ADD CONSTRAINT fk_rails_174e058eb3 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: scantrons fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantrons
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: test_exts fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_exts
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: test_ext2s fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ext_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_ext_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ext_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ext_gen_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_gen_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: test1s fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test1s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: test_2s fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: test2s fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_player_infos fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_infos
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: new_tests fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.new_tests
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_new_tests fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_new_tests
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: social_security_numbers fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.social_security_numbers
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: bhs_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.bhs_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: mrn_numbers fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.mrn_numbers
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_ipa_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_consent_mailings fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_consent_mailings
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_screenings fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_screenings
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_hotels fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_hotels
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_transportations fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_transportations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_payments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_payments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_surveys fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_surveys
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_ipa_surveys fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_surveys
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: ipa_appointments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_appointments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_bhs_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_bhs_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_ipa_assignment_minor_deviations fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: test1s fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test1s
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: test_2s fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: test2s fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: ipa_assignments fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: new_tests fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.new_tests
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: social_security_numbers fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.social_security_numbers
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: bhs_assignments fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.bhs_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: mrn_numbers fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.mrn_numbers
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: sub_processes fk_rails_1fc7475261; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sub_processes
    ADD CONSTRAINT fk_rails_1fc7475261 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: pro_infos fk_rails_20667815e3; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.pro_infos
    ADD CONSTRAINT fk_rails_20667815e3 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: item_flag_names fk_rails_22ccfd95e1; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flag_names
    ADD CONSTRAINT fk_rails_22ccfd95e1 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: player_infos fk_rails_23cd255bc6; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_infos
    ADD CONSTRAINT fk_rails_23cd255bc6 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: model_references fk_rails_2d8072edea; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.model_references
    ADD CONSTRAINT fk_rails_2d8072edea FOREIGN KEY (to_record_master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: user_roles fk_rails_318345354e; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_roles
    ADD CONSTRAINT fk_rails_318345354e FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: admin_action_logs fk_rails_3389f178f6; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.admin_action_logs
    ADD CONSTRAINT fk_rails_3389f178f6 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: page_layouts fk_rails_37a2f11066; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.page_layouts
    ADD CONSTRAINT fk_rails_37a2f11066 FOREIGN KEY (app_type_id) REFERENCES ml_app_zeus_full.app_types(id);


--
-- Name: message_notifications fk_rails_3a3553e146; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.message_notifications
    ADD CONSTRAINT fk_rails_3a3553e146 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: trackers fk_rails_447d125f63; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.trackers
    ADD CONSTRAINT fk_rails_447d125f63 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: scantrons fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantrons
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: test_exts fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_exts
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: test_ext2s fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext2s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ext_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_ext_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ext_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ext_gen_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ext_gen_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: test1s fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test1s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: test_2s fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_2s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: test2s fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test2s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_player_infos fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_infos
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: new_tests fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.new_tests
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_new_tests fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_new_tests
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: social_security_numbers fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.social_security_numbers
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: bhs_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.bhs_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: mrn_numbers fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.mrn_numbers
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_ipa_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_consent_mailings fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_consent_mailings
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_screenings fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_screenings
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_hotels fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_hotels
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_transportations fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_transportations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_payments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_payments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_surveys fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_surveys
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_ipa_surveys fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_surveys
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: ipa_appointments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.ipa_appointments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_bhs_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_bhs_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: activity_log_ipa_assignment_minor_deviations fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: trackers fk_rails_47b051d356; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.trackers
    ADD CONSTRAINT fk_rails_47b051d356 FOREIGN KEY (sub_process_id) REFERENCES ml_app_zeus_full.sub_processes(id);


--
-- Name: addresses fk_rails_48c9e0c5a2; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.addresses
    ADD CONSTRAINT fk_rails_48c9e0c5a2 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: colleges fk_rails_49306e4f49; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.colleges
    ADD CONSTRAINT fk_rails_49306e4f49 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: model_references fk_rails_4bbf83b940; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.model_references
    ADD CONSTRAINT fk_rails_4bbf83b940 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: message_templates fk_rails_4fe5122ed4; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.message_templates
    ADD CONSTRAINT fk_rails_4fe5122ed4 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: exception_logs fk_rails_51ae125c4f; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.exception_logs
    ADD CONSTRAINT fk_rails_51ae125c4f FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: protocol_events fk_rails_564af80fb6; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocol_events
    ADD CONSTRAINT fk_rails_564af80fb6 FOREIGN KEY (sub_process_id) REFERENCES ml_app_zeus_full.sub_processes(id);


--
-- Name: external_identifier_history fk_rails_5b0628cf42; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_identifier_history
    ADD CONSTRAINT fk_rails_5b0628cf42 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: trackers fk_rails_623e0ca5ac; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.trackers
    ADD CONSTRAINT fk_rails_623e0ca5ac FOREIGN KEY (protocol_id) REFERENCES ml_app_zeus_full.protocols(id);


--
-- Name: app_configurations fk_rails_647c63b069; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.app_configurations
    ADD CONSTRAINT fk_rails_647c63b069 FOREIGN KEY (app_type_id) REFERENCES ml_app_zeus_full.app_types(id);


--
-- Name: users fk_rails_6a971dc818; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.users
    ADD CONSTRAINT fk_rails_6a971dc818 FOREIGN KEY (app_type_id) REFERENCES ml_app_zeus_full.app_types(id);


--
-- Name: protocols fk_rails_6de4fd560d; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.protocols
    ADD CONSTRAINT fk_rails_6de4fd560d FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: tracker_history fk_rails_6e050927c2; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.tracker_history
    ADD CONSTRAINT fk_rails_6e050927c2 FOREIGN KEY (tracker_id) REFERENCES ml_app_zeus_full.trackers(id);


--
-- Name: accuracy_scores fk_rails_70c17e88fd; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.accuracy_scores
    ADD CONSTRAINT fk_rails_70c17e88fd FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: external_identifiers fk_rails_7218113eac; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_identifiers
    ADD CONSTRAINT fk_rails_7218113eac FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: player_contacts fk_rails_72b1afe72f; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_contacts
    ADD CONSTRAINT fk_rails_72b1afe72f FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: activity_log_ext_assignments fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ext_assignments
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ext_assignment_id) REFERENCES ml_app_zeus_full.ext_assignments(id);


--
-- Name: activity_log_player_infos fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_player_infos
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (player_info_id) REFERENCES ml_app_zeus_full.player_infos(id);


--
-- Name: activity_log_new_tests fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_new_tests
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (new_test_id) REFERENCES ml_app_zeus_full.new_tests(id);


--
-- Name: activity_log_ipa_assignments fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignments
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ml_app_zeus_full.ipa_assignments(id);


--
-- Name: activity_log_ipa_surveys fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_surveys
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_survey_id) REFERENCES ml_app_zeus_full.ipa_surveys(id);


--
-- Name: activity_log_bhs_assignments fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_bhs_assignments
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (bhs_assignment_id) REFERENCES ml_app_zeus_full.bhs_assignments(id);


--
-- Name: activity_log_ipa_assignment_minor_deviations fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.activity_log_ipa_assignment_minor_deviations
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ml_app_zeus_full.ipa_assignments(id);


--
-- Name: sub_processes fk_rails_7c10a99849; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sub_processes
    ADD CONSTRAINT fk_rails_7c10a99849 FOREIGN KEY (protocol_id) REFERENCES ml_app_zeus_full.protocols(id);


--
-- Name: emergency_contacts fk_rails_8104b3f11d; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.emergency_contacts
    ADD CONSTRAINT fk_rails_8104b3f11d FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: user_access_controls fk_rails_8108e25f83; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_access_controls
    ADD CONSTRAINT fk_rails_8108e25f83 FOREIGN KEY (app_type_id) REFERENCES ml_app_zeus_full.app_types(id);


--
-- Name: tracker_history fk_rails_83aa075398; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.tracker_history
    ADD CONSTRAINT fk_rails_83aa075398 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: pro_infos fk_rails_86cecb1e36; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.pro_infos
    ADD CONSTRAINT fk_rails_86cecb1e36 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: app_types fk_rails_8be93bcf4b; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.app_types
    ADD CONSTRAINT fk_rails_8be93bcf4b FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: tracker_history fk_rails_9513fd1c35; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.tracker_history
    ADD CONSTRAINT fk_rails_9513fd1c35 FOREIGN KEY (sub_process_id) REFERENCES ml_app_zeus_full.sub_processes(id);


--
-- Name: sage_assignments fk_rails_971255ec2c; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sage_assignments
    ADD CONSTRAINT fk_rails_971255ec2c FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: tracker_history fk_rails_9e92bdfe65; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.tracker_history
    ADD CONSTRAINT fk_rails_9e92bdfe65 FOREIGN KEY (protocol_event_id) REFERENCES ml_app_zeus_full.protocol_events(id);


--
-- Name: tracker_history fk_rails_9f5797d684; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.tracker_history
    ADD CONSTRAINT fk_rails_9f5797d684 FOREIGN KEY (protocol_id) REFERENCES ml_app_zeus_full.protocols(id);


--
-- Name: addresses fk_rails_a44670b00a; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.addresses
    ADD CONSTRAINT fk_rails_a44670b00a FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: model_references fk_rails_a4eb981c4a; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.model_references
    ADD CONSTRAINT fk_rails_a4eb981c4a FOREIGN KEY (from_record_master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: user_history fk_rails_af2f6ffc55; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_history
    ADD CONSTRAINT fk_rails_af2f6ffc55 FOREIGN KEY (app_type_id) REFERENCES ml_app_zeus_full.app_types(id);


--
-- Name: colleges fk_rails_b0a6220067; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.colleges
    ADD CONSTRAINT fk_rails_b0a6220067 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: reports fk_rails_b138baacff; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.reports
    ADD CONSTRAINT fk_rails_b138baacff FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: imports fk_rails_b1e2154c26; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.imports
    ADD CONSTRAINT fk_rails_b1e2154c26 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: user_roles fk_rails_b345649dfe; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_roles
    ADD CONSTRAINT fk_rails_b345649dfe FOREIGN KEY (app_type_id) REFERENCES ml_app_zeus_full.app_types(id);


--
-- Name: trackers fk_rails_b822840dc1; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.trackers
    ADD CONSTRAINT fk_rails_b822840dc1 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: trackers fk_rails_bb6af37155; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.trackers
    ADD CONSTRAINT fk_rails_bb6af37155 FOREIGN KEY (protocol_event_id) REFERENCES ml_app_zeus_full.protocol_events(id);


--
-- Name: item_flags fk_rails_c2d5bb8930; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flags
    ADD CONSTRAINT fk_rails_c2d5bb8930 FOREIGN KEY (item_flag_name_id) REFERENCES ml_app_zeus_full.item_flag_names(id);


--
-- Name: tracker_history fk_rails_c55341c576; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.tracker_history
    ADD CONSTRAINT fk_rails_c55341c576 FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: exception_logs fk_rails_c720bf523c; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.exception_logs
    ADD CONSTRAINT fk_rails_c720bf523c FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: user_action_logs fk_rails_c94bae872a; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_action_logs
    ADD CONSTRAINT fk_rails_c94bae872a FOREIGN KEY (app_type_id) REFERENCES ml_app_zeus_full.app_types(id);


--
-- Name: user_action_logs fk_rails_cfc9dc539f; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_action_logs
    ADD CONSTRAINT fk_rails_cfc9dc539f FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: message_notifications fk_rails_d3566ee56d; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.message_notifications
    ADD CONSTRAINT fk_rails_d3566ee56d FOREIGN KEY (app_type_id) REFERENCES ml_app_zeus_full.app_types(id);


--
-- Name: player_contacts fk_rails_d3c0ddde90; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.player_contacts
    ADD CONSTRAINT fk_rails_d3c0ddde90 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: item_flags fk_rails_dce5169cfd; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.item_flags
    ADD CONSTRAINT fk_rails_dce5169cfd FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: dynamic_models fk_rails_deec8fcb38; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.dynamic_models
    ADD CONSTRAINT fk_rails_deec8fcb38 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: sage_assignments fk_rails_e3c559b547; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sage_assignments
    ADD CONSTRAINT fk_rails_e3c559b547 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: page_layouts fk_rails_e410af4010; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.page_layouts
    ADD CONSTRAINT fk_rails_e410af4010 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: sage_assignments fk_rails_ebab73db27; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sage_assignments
    ADD CONSTRAINT fk_rails_ebab73db27 FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: external_links fk_rails_ebf3863277; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.external_links
    ADD CONSTRAINT fk_rails_ebf3863277 FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: app_configurations fk_rails_f0ac516fff; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.app_configurations
    ADD CONSTRAINT fk_rails_f0ac516fff FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: emergency_contacts fk_rails_f5033c91ed; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.emergency_contacts
    ADD CONSTRAINT fk_rails_f5033c91ed FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: general_selections fk_rails_f62500107f; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.general_selections
    ADD CONSTRAINT fk_rails_f62500107f FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: message_notifications fk_rails_fa6dbd15de; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.message_notifications
    ADD CONSTRAINT fk_rails_fa6dbd15de FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: report_history fk_report_history_reports; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.report_history
    ADD CONSTRAINT fk_report_history_reports FOREIGN KEY (report_id) REFERENCES ml_app_zeus_full.reports(id);


--
-- Name: scantron_history fk_scantron_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantron_history
    ADD CONSTRAINT fk_scantron_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: scantron_history fk_scantron_history_scantrons; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantron_history
    ADD CONSTRAINT fk_scantron_history_scantrons FOREIGN KEY (scantron_table_id) REFERENCES ml_app_zeus_full.scantrons(id);


--
-- Name: scantron_history fk_scantron_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.scantron_history
    ADD CONSTRAINT fk_scantron_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: social_security_number_history fk_social_security_number_history_admins; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.social_security_number_history
    ADD CONSTRAINT fk_social_security_number_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: social_security_number_history fk_social_security_number_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.social_security_number_history
    ADD CONSTRAINT fk_social_security_number_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: social_security_number_history fk_social_security_number_history_social_security_numbers; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.social_security_number_history
    ADD CONSTRAINT fk_social_security_number_history_social_security_numbers FOREIGN KEY (social_security_number_table_id) REFERENCES ml_app_zeus_full.social_security_numbers(id);


--
-- Name: social_security_number_history fk_social_security_number_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.social_security_number_history
    ADD CONSTRAINT fk_social_security_number_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: sub_process_history fk_sub_process_history_sub_processes; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.sub_process_history
    ADD CONSTRAINT fk_sub_process_history_sub_processes FOREIGN KEY (sub_process_id) REFERENCES ml_app_zeus_full.sub_processes(id);


--
-- Name: test1_history fk_test1_history_admins; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test1_history
    ADD CONSTRAINT fk_test1_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: test1_history fk_test1_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test1_history
    ADD CONSTRAINT fk_test1_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: test1_history fk_test1_history_test1s; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test1_history
    ADD CONSTRAINT fk_test1_history_test1s FOREIGN KEY (test1_table_id) REFERENCES ml_app_zeus_full.test1s(id);


--
-- Name: test1_history fk_test1_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test1_history
    ADD CONSTRAINT fk_test1_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: test2_history fk_test2_history_admins; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test2_history
    ADD CONSTRAINT fk_test2_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: test2_history fk_test2_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test2_history
    ADD CONSTRAINT fk_test2_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: test2_history fk_test2_history_test2s; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test2_history
    ADD CONSTRAINT fk_test2_history_test2s FOREIGN KEY (test2_table_id) REFERENCES ml_app_zeus_full.test2s(id);


--
-- Name: test2_history fk_test2_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test2_history
    ADD CONSTRAINT fk_test2_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: test_2_history fk_test_2_history_admins; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_2_history
    ADD CONSTRAINT fk_test_2_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app_zeus_full.admins(id);


--
-- Name: test_2_history fk_test_2_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_2_history
    ADD CONSTRAINT fk_test_2_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: test_2_history fk_test_2_history_test_2s; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_2_history
    ADD CONSTRAINT fk_test_2_history_test_2s FOREIGN KEY (test_2_table_id) REFERENCES ml_app_zeus_full.test_2s(id);


--
-- Name: test_2_history fk_test_2_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_2_history
    ADD CONSTRAINT fk_test_2_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: test_ext2_history fk_test_ext2_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext2_history
    ADD CONSTRAINT fk_test_ext2_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: test_ext2_history fk_test_ext2_history_test_ext2s; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext2_history
    ADD CONSTRAINT fk_test_ext2_history_test_ext2s FOREIGN KEY (test_ext2_table_id) REFERENCES ml_app_zeus_full.test_ext2s(id);


--
-- Name: test_ext2_history fk_test_ext2_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext2_history
    ADD CONSTRAINT fk_test_ext2_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: test_ext_history fk_test_ext_history_masters; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext_history
    ADD CONSTRAINT fk_test_ext_history_masters FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: test_ext_history fk_test_ext_history_test_exts; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext_history
    ADD CONSTRAINT fk_test_ext_history_test_exts FOREIGN KEY (test_ext_table_id) REFERENCES ml_app_zeus_full.test_exts(id);


--
-- Name: test_ext_history fk_test_ext_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.test_ext_history
    ADD CONSTRAINT fk_test_ext_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: user_authorization_history fk_user_authorization_history_user_authorizations; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_authorization_history
    ADD CONSTRAINT fk_user_authorization_history_user_authorizations FOREIGN KEY (user_authorization_id) REFERENCES ml_app_zeus_full.user_authorizations(id);


--
-- Name: user_history fk_user_history_users; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.user_history
    ADD CONSTRAINT fk_user_history_users FOREIGN KEY (user_id) REFERENCES ml_app_zeus_full.users(id);


--
-- Name: rc_cis rc_cis_master_id_fkey; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.rc_cis
    ADD CONSTRAINT rc_cis_master_id_fkey FOREIGN KEY (master_id) REFERENCES ml_app_zeus_full.masters(id);


--
-- Name: tracker_history unique_master_protocol_tracker_id; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.tracker_history
    ADD CONSTRAINT unique_master_protocol_tracker_id FOREIGN KEY (master_id, protocol_id, tracker_id) REFERENCES ml_app_zeus_full.trackers(master_id, protocol_id, id);


--
-- Name: trackers valid_protocol_sub_process; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.trackers
    ADD CONSTRAINT valid_protocol_sub_process FOREIGN KEY (protocol_id, sub_process_id) REFERENCES ml_app_zeus_full.sub_processes(protocol_id, id) MATCH FULL;


--
-- Name: tracker_history valid_protocol_sub_process; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.tracker_history
    ADD CONSTRAINT valid_protocol_sub_process FOREIGN KEY (protocol_id, sub_process_id) REFERENCES ml_app_zeus_full.sub_processes(protocol_id, id) MATCH FULL;


--
-- Name: trackers valid_sub_process_event; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.trackers
    ADD CONSTRAINT valid_sub_process_event FOREIGN KEY (sub_process_id, protocol_event_id) REFERENCES ml_app_zeus_full.protocol_events(sub_process_id, id);


--
-- Name: tracker_history valid_sub_process_event; Type: FK CONSTRAINT; Schema: ml_app_zeus_full; Owner: -
--

ALTER TABLE ONLY ml_app_zeus_full.tracker_history
    ADD CONSTRAINT valid_sub_process_event FOREIGN KEY (sub_process_id, protocol_event_id) REFERENCES ml_app_zeus_full.protocol_events(sub_process_id, id);


--
-- PostgreSQL database dump complete
--

SET search_path TO ml_app_zeus_full;

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

INSERT INTO schema_migrations (version) VALUES ('20180228111254');

INSERT INTO schema_migrations (version) VALUES ('20180228145731');

INSERT INTO schema_migrations (version) VALUES ('20180228174728');

INSERT INTO schema_migrations (version) VALUES ('20180301114206');

INSERT INTO schema_migrations (version) VALUES ('20180302144109');

INSERT INTO schema_migrations (version) VALUES ('20180313091440');

INSERT INTO schema_migrations (version) VALUES ('20180319133539');

INSERT INTO schema_migrations (version) VALUES ('20180319133540');

INSERT INTO schema_migrations (version) VALUES ('20180319175721');

INSERT INTO schema_migrations (version) VALUES ('20180320105954');

INSERT INTO schema_migrations (version) VALUES ('20180320113757');

INSERT INTO schema_migrations (version) VALUES ('20180320154951');

INSERT INTO schema_migrations (version) VALUES ('20180320183512');

INSERT INTO schema_migrations (version) VALUES ('20180321082612');

INSERT INTO schema_migrations (version) VALUES ('20180321095805');

INSERT INTO schema_migrations (version) VALUES ('20180404150536');

INSERT INTO schema_migrations (version) VALUES ('20180405141059');

INSERT INTO schema_migrations (version) VALUES ('20180416145033');

INSERT INTO schema_migrations (version) VALUES ('20180426091838');

INSERT INTO schema_migrations (version) VALUES ('20180502082334');

INSERT INTO schema_migrations (version) VALUES ('20180504080300');

INSERT INTO schema_migrations (version) VALUES ('20180531091440');

INSERT INTO schema_migrations (version) VALUES ('20180723165621');

INSERT INTO schema_migrations (version) VALUES ('20180725140502');

