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
-- Name: ml_app; Type: SCHEMA; Schema: -; Owner: fphs
--

CREATE SCHEMA ml_app;


ALTER SCHEMA ml_app OWNER TO fphs;

SET search_path = ml_app, pg_catalog;

--
-- Name: current_user_id(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.current_user_id() OWNER TO fphs;

--
-- Name: handle_delete(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.handle_delete() OWNER TO fphs;

--
-- Name: handle_tracker_history_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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

      RETURN NEW;
    END;
    $$;


ALTER FUNCTION ml_app.handle_tracker_history_update() OWNER TO fphs;

--
-- Name: log_accuracy_score_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_accuracy_score_update() OWNER TO fphs;

--
-- Name: log_address_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_address_update() OWNER TO fphs;

--
-- Name: log_admin_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_admin_update() OWNER TO fphs;

--
-- Name: log_college_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_college_update() OWNER TO fphs;

--
-- Name: log_dynamic_model_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_dynamic_model_update() OWNER TO fphs;

--
-- Name: log_external_link_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_external_link_update() OWNER TO fphs;

--
-- Name: log_general_selection_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_general_selection_update() OWNER TO fphs;

--
-- Name: log_item_flag_name_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_item_flag_name_update() OWNER TO fphs;

--
-- Name: log_item_flag_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_item_flag_update() OWNER TO fphs;

--
-- Name: log_player_contact_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_player_contact_update() OWNER TO fphs;

--
-- Name: log_player_info_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


ALTER FUNCTION ml_app.log_player_info_update() OWNER TO fphs;

--
-- Name: log_protocol_event_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_protocol_event_update() OWNER TO fphs;

--
-- Name: log_protocol_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_protocol_update() OWNER TO fphs;

--
-- Name: log_report_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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
                    updated_at
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
                NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$;


ALTER FUNCTION ml_app.log_report_update() OWNER TO fphs;

--
-- Name: log_scantron_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_scantron_update() OWNER TO fphs;

--
-- Name: log_sub_process_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_sub_process_update() OWNER TO fphs;

--
-- Name: log_tracker_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_tracker_update() OWNER TO fphs;

--
-- Name: log_user_authorization_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_user_authorization_update() OWNER TO fphs;

--
-- Name: log_user_update(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.log_user_update() OWNER TO fphs;

--
-- Name: tracker_upsert(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.tracker_upsert() OWNER TO fphs;

--
-- Name: update_master_with_player_info(); Type: FUNCTION; Schema: ml_app; Owner: fphs
--

CREATE FUNCTION update_master_with_player_info() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE masters 
            set rank = (
            case when NEW.rank is null then -1000 
                 when (NEW.rank > 12) then NEW.rank * -1 
                 else new.rank
            end
            )

        WHERE masters.id = NEW.master_id;

        RETURN NEW;
    END;
    $$;


ALTER FUNCTION ml_app.update_master_with_player_info() OWNER TO fphs;

--
-- Name: update_master_with_pro_info(); Type: FUNCTION; Schema: ml_app; Owner: fphs
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


ALTER FUNCTION ml_app.update_master_with_pro_info() OWNER TO fphs;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accuracy_score_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE accuracy_score_history OWNER TO fphs;

--
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE accuracy_score_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE accuracy_score_history_id_seq OWNER TO fphs;

--
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE accuracy_score_history_id_seq OWNED BY accuracy_score_history.id;


--
-- Name: accuracy_scores; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE accuracy_scores OWNER TO fphs;

--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE accuracy_scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE accuracy_scores_id_seq OWNER TO fphs;

--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE accuracy_scores_id_seq OWNED BY accuracy_scores.id;


--
-- Name: address_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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
    updated_at timestamp without time zone DEFAULT now(),
    country character varying(3),
    postal_code character varying,
    region character varying,
    address_id integer
);


ALTER TABLE address_history OWNER TO fphs;

--
-- Name: address_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE address_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE address_history_id_seq OWNER TO fphs;

--
-- Name: address_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE address_history_id_seq OWNED BY address_history.id;


--
-- Name: addresses; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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
    updated_at timestamp without time zone DEFAULT now(),
    country character varying(3),
    postal_code character varying,
    region character varying
);


ALTER TABLE addresses OWNER TO fphs;

--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE addresses_id_seq OWNER TO fphs;

--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE addresses_id_seq OWNED BY addresses.id;


--
-- Name: admin_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE admin_history OWNER TO fphs;

--
-- Name: admin_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE admin_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE admin_history_id_seq OWNER TO fphs;

--
-- Name: admin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE admin_history_id_seq OWNED BY admin_history.id;


--
-- Name: admins; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE admins OWNER TO fphs;

--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE admins_id_seq OWNER TO fphs;

--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE admins_id_seq OWNED BY admins.id;


--
-- Name: college_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE college_history OWNER TO fphs;

--
-- Name: college_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE college_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE college_history_id_seq OWNER TO fphs;

--
-- Name: college_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE college_history_id_seq OWNED BY college_history.id;


--
-- Name: colleges; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE colleges OWNER TO fphs;

--
-- Name: colleges_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE colleges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE colleges_id_seq OWNER TO fphs;

--
-- Name: colleges_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE colleges_id_seq OWNED BY colleges.id;


--
-- Name: dynamic_model_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE dynamic_model_history OWNER TO fphs;

--
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE dynamic_model_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dynamic_model_history_id_seq OWNER TO fphs;

--
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE dynamic_model_history_id_seq OWNED BY dynamic_model_history.id;


--
-- Name: dynamic_models; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE dynamic_models OWNER TO fphs;

--
-- Name: dynamic_models_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE dynamic_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dynamic_models_id_seq OWNER TO fphs;

--
-- Name: dynamic_models_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE dynamic_models_id_seq OWNED BY dynamic_models.id;


--
-- Name: external_link_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE external_link_history OWNER TO fphs;

--
-- Name: external_link_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE external_link_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE external_link_history_id_seq OWNER TO fphs;

--
-- Name: external_link_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE external_link_history_id_seq OWNED BY external_link_history.id;


--
-- Name: external_links; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE TABLE external_links (
    id integer,
    name character varying,
    value character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE external_links OWNER TO fphs;

--
-- Name: external_links_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE external_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE external_links_id_seq OWNER TO fphs;

--
-- Name: external_links_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE external_links_id_seq OWNED BY external_links.id;


--
-- Name: general_selection_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE general_selection_history OWNER TO fphs;

--
-- Name: general_selection_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE general_selection_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE general_selection_history_id_seq OWNER TO fphs;

--
-- Name: general_selection_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE general_selection_history_id_seq OWNED BY general_selection_history.id;


--
-- Name: general_selections; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE general_selections OWNER TO fphs;

--
-- Name: general_selections_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE general_selections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE general_selections_id_seq OWNER TO fphs;

--
-- Name: general_selections_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE general_selections_id_seq OWNED BY general_selections.id;


--
-- Name: item_flag_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE item_flag_history OWNER TO fphs;

--
-- Name: item_flag_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE item_flag_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE item_flag_history_id_seq OWNER TO fphs;

--
-- Name: item_flag_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE item_flag_history_id_seq OWNED BY item_flag_history.id;


--
-- Name: item_flag_name_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE item_flag_name_history OWNER TO fphs;

--
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE item_flag_name_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE item_flag_name_history_id_seq OWNER TO fphs;

--
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE item_flag_name_history_id_seq OWNED BY item_flag_name_history.id;


--
-- Name: item_flag_names; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE item_flag_names OWNER TO fphs;

--
-- Name: item_flag_names_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE item_flag_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE item_flag_names_id_seq OWNER TO fphs;

--
-- Name: item_flag_names_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE item_flag_names_id_seq OWNED BY item_flag_names.id;


--
-- Name: item_flags; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE item_flags OWNER TO fphs;

--
-- Name: item_flags_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE item_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE item_flags_id_seq OWNER TO fphs;

--
-- Name: item_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE item_flags_id_seq OWNED BY item_flags.id;


--
-- Name: manage_users; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE TABLE manage_users (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE manage_users OWNER TO fphs;

--
-- Name: manage_users_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE manage_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE manage_users_id_seq OWNER TO fphs;

--
-- Name: manage_users_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE manage_users_id_seq OWNED BY manage_users.id;


--
-- Name: masters; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE masters OWNER TO fphs;

--
-- Name: masters_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE masters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE masters_id_seq OWNER TO fphs;

--
-- Name: masters_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE masters_id_seq OWNED BY masters.id;


--
-- Name: player_career_data; Type: TABLE; Schema: ml_app; Owner: pda11; Tablespace: 
--

CREATE TABLE player_career_data (
    contactid integer,
    draftedbyteam character varying(255),
    draftyear integer,
    draftround integer,
    draftposition integer,
    startyear integer,
    accruedseasons integer,
    college character varying(255),
    teamhistory character varying(255),
    infochangestatus character varying(255)
);


ALTER TABLE player_career_data OWNER TO pda11;

--
-- Name: player_contact_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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
    updated_at timestamp without time zone DEFAULT now(),
    player_contact_id integer
);


ALTER TABLE player_contact_history OWNER TO fphs;

--
-- Name: player_contact_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE player_contact_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE player_contact_history_id_seq OWNER TO fphs;

--
-- Name: player_contact_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE player_contact_history_id_seq OWNED BY player_contact_history.id;


--
-- Name: player_contacts; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE player_contacts OWNER TO fphs;

--
-- Name: player_contacts_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE player_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE player_contacts_id_seq OWNER TO fphs;

--
-- Name: player_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE player_contacts_id_seq OWNED BY player_contacts.id;


--
-- Name: player_info_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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
    updated_at timestamp without time zone DEFAULT now(),
    contact_pref character varying,
    start_year integer,
    rank integer,
    notes character varying,
    contact_id integer,
    college character varying,
    end_year integer,
    source character varying,
    player_info_id integer
);


ALTER TABLE player_info_history OWNER TO fphs;

--
-- Name: player_info_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE player_info_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE player_info_history_id_seq OWNER TO fphs;

--
-- Name: player_info_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE player_info_history_id_seq OWNED BY player_info_history.id;


--
-- Name: player_infos; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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
    updated_at timestamp without time zone DEFAULT now(),
    contact_pref character varying,
    start_year integer,
    rank integer,
    notes character varying,
    contact_id integer,
    college character varying,
    end_year integer,
    source character varying
);


ALTER TABLE player_infos OWNER TO fphs;

--
-- Name: player_infos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE player_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE player_infos_id_seq OWNER TO fphs;

--
-- Name: player_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE player_infos_id_seq OWNED BY player_infos.id;


--
-- Name: player_severance; Type: TABLE; Schema: ml_app; Owner: pda11; Tablespace: 
--

CREATE TABLE player_severance (
    contactid integer,
    payoutdate date,
    infochangestatus character varying(255)
);


ALTER TABLE player_severance OWNER TO pda11;

--
-- Name: player_transactions; Type: TABLE; Schema: ml_app; Owner: pda11; Tablespace: 
--

CREATE TABLE player_transactions (
    contactid integer,
    transactiondate date,
    transactiontype character varying(255),
    transactionstatus character varying(255),
    transactionsubstatus character varying(255),
    transactionhistoricalteamname character varying(255),
    transactioncurrentteamname character varying(255),
    infochangestatus character varying(255)
);


ALTER TABLE player_transactions OWNER TO pda11;

--
-- Name: pro_infos; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE pro_infos OWNER TO fphs;

--
-- Name: pro_infos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE pro_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pro_infos_id_seq OWNER TO fphs;

--
-- Name: pro_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE pro_infos_id_seq OWNED BY pro_infos.id;


--
-- Name: profootball_master; Type: TABLE; Schema: ml_app; Owner: pda11; Tablespace: 
--

CREATE TABLE profootball_master (
    pro_id integer,
    lastname character varying(255),
    firstname character varying(255),
    middlename character varying(255),
    middleinitial character varying(1),
    name character varying(255),
    full_name character varying(255),
    nickname character varying(255),
    dob date,
    date_of_death date,
    "position" character varying(255),
    height date,
    weight integer,
    birthplace character varying(255),
    deathplace character varying(255),
    startyear integer,
    endyear integer,
    careeryears character varying(9),
    career_info character varying(255),
    high_school character varying(255),
    college character varying(255)
);


ALTER TABLE profootball_master OWNER TO pda11;

--
-- Name: protocol_event_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE protocol_event_history OWNER TO fphs;

--
-- Name: protocol_event_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE protocol_event_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE protocol_event_history_id_seq OWNER TO fphs;

--
-- Name: protocol_event_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE protocol_event_history_id_seq OWNED BY protocol_event_history.id;


--
-- Name: protocol_events; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE protocol_events OWNER TO fphs;

--
-- Name: protocol_events_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE protocol_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE protocol_events_id_seq OWNER TO fphs;

--
-- Name: protocol_events_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE protocol_events_id_seq OWNED BY protocol_events.id;


--
-- Name: protocol_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE protocol_history OWNER TO fphs;

--
-- Name: protocol_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE protocol_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE protocol_history_id_seq OWNER TO fphs;

--
-- Name: protocol_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE protocol_history_id_seq OWNED BY protocol_history.id;


--
-- Name: protocols; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE protocols OWNER TO fphs;

--
-- Name: protocols_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE protocols_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE protocols_id_seq OWNER TO fphs;

--
-- Name: protocols_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE protocols_id_seq OWNED BY protocols.id;


--
-- Name: report_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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
    report_id integer
);


ALTER TABLE report_history OWNER TO fphs;

--
-- Name: report_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE report_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE report_history_id_seq OWNER TO fphs;

--
-- Name: report_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE report_history_id_seq OWNED BY report_history.id;


--
-- Name: reports; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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
    "position" integer
);


ALTER TABLE reports OWNER TO fphs;

--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE reports_id_seq OWNER TO fphs;

--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE reports_id_seq OWNED BY reports.id;


--
-- Name: sage_assignments; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE sage_assignments OWNER TO fphs;

--
-- Name: sage_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE sage_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sage_assignments_id_seq OWNER TO fphs;

--
-- Name: sage_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE sage_assignments_id_seq OWNED BY sage_assignments.id;


--
-- Name: scantron_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE scantron_history OWNER TO fphs;

--
-- Name: scantron_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE scantron_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE scantron_history_id_seq OWNER TO fphs;

--
-- Name: scantron_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE scantron_history_id_seq OWNED BY scantron_history.id;


--
-- Name: scantrons; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE TABLE scantrons (
    id integer NOT NULL,
    master_id integer,
    scantron_id integer,
    user_id integer,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE scantrons OWNER TO fphs;

--
-- Name: scantrons_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE scantrons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE scantrons_id_seq OWNER TO fphs;

--
-- Name: scantrons_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE scantrons_id_seq OWNED BY scantrons.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE schema_migrations OWNER TO fphs;

--
-- Name: sub_process_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE sub_process_history OWNER TO fphs;

--
-- Name: sub_process_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE sub_process_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sub_process_history_id_seq OWNER TO fphs;

--
-- Name: sub_process_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE sub_process_history_id_seq OWNED BY sub_process_history.id;


--
-- Name: sub_processes; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE sub_processes OWNER TO fphs;

--
-- Name: sub_processes_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE sub_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sub_processes_id_seq OWNER TO fphs;

--
-- Name: sub_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE sub_processes_id_seq OWNED BY sub_processes.id;


--
-- Name: team_history; Type: TABLE; Schema: ml_app; Owner: pda11; Tablespace: 
--

CREATE TABLE team_history (
    contactid integer,
    teamhistory character varying(255),
    infochangestatus character varying(255)
);


ALTER TABLE team_history OWNER TO pda11;

--
-- Name: tracker_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE TABLE tracker_history (
    id integer NOT NULL,
    master_id integer,
    protocol_id integer,
    tracker_id integer,
    event_date timestamp without time zone,
    user_id integer,
    notes character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sub_process_id integer,
    protocol_event_id integer,
    item_id integer,
    item_type character varying
);


ALTER TABLE tracker_history OWNER TO fphs;

--
-- Name: tracker_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE tracker_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tracker_history_id_seq OWNER TO fphs;

--
-- Name: tracker_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE tracker_history_id_seq OWNED BY tracker_history.id;


--
-- Name: trackers; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE TABLE trackers (
    id integer NOT NULL,
    master_id integer,
    protocol_id integer,
    event_date timestamp without time zone,
    user_id integer DEFAULT current_user_id(),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    notes character varying,
    sub_process_id integer,
    protocol_event_id integer,
    item_id integer,
    item_type character varying
);


ALTER TABLE trackers OWNER TO fphs;

--
-- Name: trackers_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE trackers_id_seq OWNER TO fphs;

--
-- Name: trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE trackers_id_seq OWNED BY trackers.id;


--
-- Name: user_authorization_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE user_authorization_history OWNER TO fphs;

--
-- Name: user_authorization_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE user_authorization_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_authorization_history_id_seq OWNER TO fphs;

--
-- Name: user_authorization_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE user_authorization_history_id_seq OWNED BY user_authorization_history.id;


--
-- Name: user_authorizations; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE user_authorizations OWNER TO fphs;

--
-- Name: user_authorizations_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE user_authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_authorizations_id_seq OWNER TO fphs;

--
-- Name: user_authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE user_authorizations_id_seq OWNED BY user_authorizations.id;


--
-- Name: user_history; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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


ALTER TABLE user_history OWNER TO fphs;

--
-- Name: user_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE user_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_history_id_seq OWNER TO fphs;

--
-- Name: user_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE user_history_id_seq OWNED BY user_history.id;


--
-- Name: user_translation; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE TABLE user_translation (
    email character varying,
    orig_username character varying,
    user_id integer
);


ALTER TABLE user_translation OWNER TO fphs;

--
-- Name: users; Type: TABLE; Schema: ml_app; Owner: fphs; Tablespace: 
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
    admin_id integer
);


ALTER TABLE users OWNER TO fphs;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: fphs
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO fphs;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: fphs
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY accuracy_score_history ALTER COLUMN id SET DEFAULT nextval('accuracy_score_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY accuracy_scores ALTER COLUMN id SET DEFAULT nextval('accuracy_scores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY address_history ALTER COLUMN id SET DEFAULT nextval('address_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY admin_history ALTER COLUMN id SET DEFAULT nextval('admin_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY admins ALTER COLUMN id SET DEFAULT nextval('admins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY college_history ALTER COLUMN id SET DEFAULT nextval('college_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY colleges ALTER COLUMN id SET DEFAULT nextval('colleges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY dynamic_model_history ALTER COLUMN id SET DEFAULT nextval('dynamic_model_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY dynamic_models ALTER COLUMN id SET DEFAULT nextval('dynamic_models_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY external_link_history ALTER COLUMN id SET DEFAULT nextval('external_link_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY external_links ALTER COLUMN id SET DEFAULT nextval('external_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY general_selection_history ALTER COLUMN id SET DEFAULT nextval('general_selection_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY general_selections ALTER COLUMN id SET DEFAULT nextval('general_selections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY item_flag_history ALTER COLUMN id SET DEFAULT nextval('item_flag_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY item_flag_name_history ALTER COLUMN id SET DEFAULT nextval('item_flag_name_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY item_flag_names ALTER COLUMN id SET DEFAULT nextval('item_flag_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY item_flags ALTER COLUMN id SET DEFAULT nextval('item_flags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY manage_users ALTER COLUMN id SET DEFAULT nextval('manage_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY masters ALTER COLUMN id SET DEFAULT nextval('masters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_contact_history ALTER COLUMN id SET DEFAULT nextval('player_contact_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_contacts ALTER COLUMN id SET DEFAULT nextval('player_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_info_history ALTER COLUMN id SET DEFAULT nextval('player_info_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_infos ALTER COLUMN id SET DEFAULT nextval('player_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY pro_infos ALTER COLUMN id SET DEFAULT nextval('pro_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY protocol_event_history ALTER COLUMN id SET DEFAULT nextval('protocol_event_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY protocol_events ALTER COLUMN id SET DEFAULT nextval('protocol_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY protocol_history ALTER COLUMN id SET DEFAULT nextval('protocol_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY protocols ALTER COLUMN id SET DEFAULT nextval('protocols_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY report_history ALTER COLUMN id SET DEFAULT nextval('report_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY reports ALTER COLUMN id SET DEFAULT nextval('reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY sage_assignments ALTER COLUMN id SET DEFAULT nextval('sage_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY scantron_history ALTER COLUMN id SET DEFAULT nextval('scantron_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY scantrons ALTER COLUMN id SET DEFAULT nextval('scantrons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY sub_process_history ALTER COLUMN id SET DEFAULT nextval('sub_process_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY sub_processes ALTER COLUMN id SET DEFAULT nextval('sub_processes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY tracker_history ALTER COLUMN id SET DEFAULT nextval('tracker_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY trackers ALTER COLUMN id SET DEFAULT nextval('trackers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY user_authorization_history ALTER COLUMN id SET DEFAULT nextval('user_authorization_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY user_authorizations ALTER COLUMN id SET DEFAULT nextval('user_authorizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY user_history ALTER COLUMN id SET DEFAULT nextval('user_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: accuracy_score_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY accuracy_score_history
    ADD CONSTRAINT accuracy_score_history_pkey PRIMARY KEY (id);


--
-- Name: accuracy_scores_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY accuracy_scores
    ADD CONSTRAINT accuracy_scores_pkey PRIMARY KEY (id);


--
-- Name: address_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT address_history_pkey PRIMARY KEY (id);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: admin_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY admin_history
    ADD CONSTRAINT admin_history_pkey PRIMARY KEY (id);


--
-- Name: admins_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: college_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY college_history
    ADD CONSTRAINT college_history_pkey PRIMARY KEY (id);


--
-- Name: colleges_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY colleges
    ADD CONSTRAINT colleges_pkey PRIMARY KEY (id);


--
-- Name: dynamic_model_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY dynamic_model_history
    ADD CONSTRAINT dynamic_model_history_pkey PRIMARY KEY (id);


--
-- Name: dynamic_models_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY dynamic_models
    ADD CONSTRAINT dynamic_models_pkey PRIMARY KEY (id);


--
-- Name: external_link_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY external_link_history
    ADD CONSTRAINT external_link_history_pkey PRIMARY KEY (id);


--
-- Name: general_selection_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY general_selection_history
    ADD CONSTRAINT general_selection_history_pkey PRIMARY KEY (id);


--
-- Name: general_selections_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY general_selections
    ADD CONSTRAINT general_selections_pkey PRIMARY KEY (id);


--
-- Name: item_flag_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY item_flag_history
    ADD CONSTRAINT item_flag_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_name_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY item_flag_name_history
    ADD CONSTRAINT item_flag_name_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_names_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY item_flag_names
    ADD CONSTRAINT item_flag_names_pkey PRIMARY KEY (id);


--
-- Name: item_flags_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT item_flags_pkey PRIMARY KEY (id);


--
-- Name: manage_users_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY manage_users
    ADD CONSTRAINT manage_users_pkey PRIMARY KEY (id);


--
-- Name: masters_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY masters
    ADD CONSTRAINT masters_pkey PRIMARY KEY (id);


--
-- Name: player_contact_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT player_contact_history_pkey PRIMARY KEY (id);


--
-- Name: player_contacts_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT player_contacts_pkey PRIMARY KEY (id);


--
-- Name: player_info_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT player_info_history_pkey PRIMARY KEY (id);


--
-- Name: player_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT player_infos_pkey PRIMARY KEY (id);


--
-- Name: pro_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT pro_infos_pkey PRIMARY KEY (id);


--
-- Name: protocol_event_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY protocol_event_history
    ADD CONSTRAINT protocol_event_history_pkey PRIMARY KEY (id);


--
-- Name: protocol_events_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT protocol_events_pkey PRIMARY KEY (id);


--
-- Name: protocol_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY protocol_history
    ADD CONSTRAINT protocol_history_pkey PRIMARY KEY (id);


--
-- Name: protocols_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- Name: report_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY report_history
    ADD CONSTRAINT report_history_pkey PRIMARY KEY (id);


--
-- Name: reports_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: sage_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY sage_assignments
    ADD CONSTRAINT sage_assignments_pkey PRIMARY KEY (id);


--
-- Name: scantron_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT scantron_history_pkey PRIMARY KEY (id);


--
-- Name: scantrons_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT scantrons_pkey PRIMARY KEY (id);


--
-- Name: sub_process_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY sub_process_history
    ADD CONSTRAINT sub_process_history_pkey PRIMARY KEY (id);


--
-- Name: sub_processes_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT sub_processes_pkey PRIMARY KEY (id);


--
-- Name: tracker_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT tracker_history_pkey PRIMARY KEY (id);


--
-- Name: trackers_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT trackers_pkey PRIMARY KEY (id);


--
-- Name: user_authorization_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY user_authorization_history
    ADD CONSTRAINT user_authorization_history_pkey PRIMARY KEY (id);


--
-- Name: user_authorizations_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY user_authorizations
    ADD CONSTRAINT user_authorizations_pkey PRIMARY KEY (id);


--
-- Name: user_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY user_history
    ADD CONSTRAINT user_history_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: fphs; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_accuracy_score_history_on_accuracy_score_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_accuracy_score_history_on_accuracy_score_id ON accuracy_score_history USING btree (accuracy_score_id);


--
-- Name: index_accuracy_scores_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_accuracy_scores_on_admin_id ON accuracy_scores USING btree (admin_id);


--
-- Name: index_address_history_on_address_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_address_history_on_address_id ON address_history USING btree (address_id);


--
-- Name: index_address_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_address_history_on_master_id ON address_history USING btree (master_id);


--
-- Name: index_address_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_address_history_on_user_id ON address_history USING btree (user_id);


--
-- Name: index_addresses_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_addresses_on_master_id ON addresses USING btree (master_id);


--
-- Name: index_addresses_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_addresses_on_user_id ON addresses USING btree (user_id);


--
-- Name: index_admin_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_admin_history_on_admin_id ON admin_history USING btree (admin_id);


--
-- Name: index_college_history_on_college_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_college_history_on_college_id ON college_history USING btree (college_id);


--
-- Name: index_colleges_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_colleges_on_admin_id ON colleges USING btree (admin_id);


--
-- Name: index_colleges_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_colleges_on_user_id ON colleges USING btree (user_id);


--
-- Name: index_dynamic_model_history_on_dynamic_model_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_dynamic_model_history_on_dynamic_model_id ON dynamic_model_history USING btree (dynamic_model_id);


--
-- Name: index_dynamic_models_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_dynamic_models_on_admin_id ON dynamic_models USING btree (admin_id);


--
-- Name: index_external_link_history_on_external_link_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_external_link_history_on_external_link_id ON external_link_history USING btree (external_link_id);


--
-- Name: index_general_selection_history_on_general_selection_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_general_selection_history_on_general_selection_id ON general_selection_history USING btree (general_selection_id);


--
-- Name: index_general_selections_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_general_selections_on_admin_id ON general_selections USING btree (admin_id);


--
-- Name: index_item_flag_history_on_item_flag_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_item_flag_history_on_item_flag_id ON item_flag_history USING btree (item_flag_id);


--
-- Name: index_item_flag_name_history_on_item_flag_name_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_item_flag_name_history_on_item_flag_name_id ON item_flag_name_history USING btree (item_flag_name_id);


--
-- Name: index_item_flag_names_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_item_flag_names_on_admin_id ON item_flag_names USING btree (admin_id);


--
-- Name: index_item_flags_on_item_flag_name_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_item_flags_on_item_flag_name_id ON item_flags USING btree (item_flag_name_id);


--
-- Name: index_item_flags_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_item_flags_on_user_id ON item_flags USING btree (user_id);


--
-- Name: index_masters_on_msid; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_masters_on_msid ON masters USING btree (msid);


--
-- Name: index_masters_on_pro_info_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_masters_on_pro_info_id ON masters USING btree (pro_info_id);


--
-- Name: index_masters_on_proid; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_masters_on_proid ON masters USING btree (pro_id);


--
-- Name: index_masters_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_masters_on_user_id ON masters USING btree (user_id);


--
-- Name: index_player_contact_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_player_contact_history_on_master_id ON player_contact_history USING btree (master_id);


--
-- Name: index_player_contact_history_on_player_contact_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_player_contact_history_on_player_contact_id ON player_contact_history USING btree (player_contact_id);


--
-- Name: index_player_contact_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_player_contact_history_on_user_id ON player_contact_history USING btree (user_id);


--
-- Name: index_player_contacts_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_player_contacts_on_master_id ON player_contacts USING btree (master_id);


--
-- Name: index_player_contacts_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_player_contacts_on_user_id ON player_contacts USING btree (user_id);


--
-- Name: index_player_info_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_player_info_history_on_master_id ON player_info_history USING btree (master_id);


--
-- Name: index_player_info_history_on_player_info_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_player_info_history_on_player_info_id ON player_info_history USING btree (player_info_id);


--
-- Name: index_player_info_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_player_info_history_on_user_id ON player_info_history USING btree (user_id);


--
-- Name: index_player_infos_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_player_infos_on_master_id ON player_infos USING btree (master_id);


--
-- Name: index_player_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_player_infos_on_user_id ON player_infos USING btree (user_id);


--
-- Name: index_pro_infos_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_pro_infos_on_master_id ON pro_infos USING btree (master_id);


--
-- Name: index_pro_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_pro_infos_on_user_id ON pro_infos USING btree (user_id);


--
-- Name: index_protocol_event_history_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_protocol_event_history_on_protocol_event_id ON protocol_event_history USING btree (protocol_event_id);


--
-- Name: index_protocol_events_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_protocol_events_on_admin_id ON protocol_events USING btree (admin_id);


--
-- Name: index_protocol_events_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_protocol_events_on_sub_process_id ON protocol_events USING btree (sub_process_id);


--
-- Name: index_protocol_history_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_protocol_history_on_protocol_id ON protocol_history USING btree (protocol_id);


--
-- Name: index_protocols_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_protocols_on_admin_id ON protocols USING btree (admin_id);


--
-- Name: index_report_history_on_report_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_report_history_on_report_id ON report_history USING btree (report_id);


--
-- Name: index_reports_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_reports_on_admin_id ON reports USING btree (admin_id);


--
-- Name: index_sage_assignments_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_sage_assignments_on_admin_id ON sage_assignments USING btree (admin_id);


--
-- Name: index_sage_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_sage_assignments_on_master_id ON sage_assignments USING btree (master_id);


--
-- Name: index_sage_assignments_on_sage_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE UNIQUE INDEX index_sage_assignments_on_sage_id ON sage_assignments USING btree (sage_id);


--
-- Name: index_sage_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_sage_assignments_on_user_id ON sage_assignments USING btree (user_id);


--
-- Name: index_scantron_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_scantron_history_on_master_id ON scantron_history USING btree (master_id);


--
-- Name: index_scantron_history_on_scantron_table_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_scantron_history_on_scantron_table_id ON scantron_history USING btree (scantron_table_id);


--
-- Name: index_scantron_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_scantron_history_on_user_id ON scantron_history USING btree (user_id);


--
-- Name: index_scantrons_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_scantrons_on_master_id ON scantrons USING btree (master_id);


--
-- Name: index_scantrons_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_scantrons_on_user_id ON scantrons USING btree (user_id);


--
-- Name: index_sub_process_history_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_sub_process_history_on_sub_process_id ON sub_process_history USING btree (sub_process_id);


--
-- Name: index_sub_processes_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_sub_processes_on_admin_id ON sub_processes USING btree (admin_id);


--
-- Name: index_sub_processes_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_sub_processes_on_protocol_id ON sub_processes USING btree (protocol_id);


--
-- Name: index_tracker_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_tracker_history_on_master_id ON tracker_history USING btree (master_id);


--
-- Name: index_tracker_history_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_tracker_history_on_protocol_event_id ON tracker_history USING btree (protocol_event_id);


--
-- Name: index_tracker_history_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_tracker_history_on_protocol_id ON tracker_history USING btree (protocol_id);


--
-- Name: index_tracker_history_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_tracker_history_on_sub_process_id ON tracker_history USING btree (sub_process_id);


--
-- Name: index_tracker_history_on_tracker_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_tracker_history_on_tracker_id ON tracker_history USING btree (tracker_id);


--
-- Name: index_tracker_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_tracker_history_on_user_id ON tracker_history USING btree (user_id);


--
-- Name: index_trackers_on_master_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_trackers_on_master_id ON trackers USING btree (master_id);


--
-- Name: index_trackers_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_trackers_on_protocol_event_id ON trackers USING btree (protocol_event_id);


--
-- Name: index_trackers_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_trackers_on_protocol_id ON trackers USING btree (protocol_id);


--
-- Name: index_trackers_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_trackers_on_sub_process_id ON trackers USING btree (sub_process_id);


--
-- Name: index_trackers_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_trackers_on_user_id ON trackers USING btree (user_id);


--
-- Name: index_user_authorization_history_on_user_authorization_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_user_authorization_history_on_user_authorization_id ON user_authorization_history USING btree (user_authorization_id);


--
-- Name: index_user_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_user_history_on_user_id ON user_history USING btree (user_id);


--
-- Name: index_users_on_admin_id; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE INDEX index_users_on_admin_id ON users USING btree (admin_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: ml_app; Owner: fphs; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: accuracy_score_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER accuracy_score_history_insert AFTER INSERT ON accuracy_scores FOR EACH ROW EXECUTE PROCEDURE log_accuracy_score_update();


--
-- Name: accuracy_score_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER accuracy_score_history_update AFTER UPDATE ON accuracy_scores FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_accuracy_score_update();


--
-- Name: address_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER address_history_insert AFTER INSERT ON addresses FOR EACH ROW EXECUTE PROCEDURE log_address_update();


--
-- Name: address_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER address_history_update AFTER UPDATE ON addresses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_address_update();


--
-- Name: admin_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER admin_history_insert AFTER INSERT ON admins FOR EACH ROW EXECUTE PROCEDURE log_admin_update();


--
-- Name: admin_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER admin_history_update AFTER UPDATE ON admins FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_admin_update();


--
-- Name: college_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER college_history_insert AFTER INSERT ON colleges FOR EACH ROW EXECUTE PROCEDURE log_college_update();


--
-- Name: college_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER college_history_update AFTER UPDATE ON colleges FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_college_update();


--
-- Name: dynamic_model_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER dynamic_model_history_insert AFTER INSERT ON dynamic_models FOR EACH ROW EXECUTE PROCEDURE log_dynamic_model_update();


--
-- Name: dynamic_model_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER dynamic_model_history_update AFTER UPDATE ON dynamic_models FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_dynamic_model_update();


--
-- Name: external_link_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER external_link_history_insert AFTER INSERT ON external_links FOR EACH ROW EXECUTE PROCEDURE log_external_link_update();


--
-- Name: external_link_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER external_link_history_update AFTER UPDATE ON external_links FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_external_link_update();


--
-- Name: general_selection_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER general_selection_history_insert AFTER INSERT ON general_selections FOR EACH ROW EXECUTE PROCEDURE log_general_selection_update();


--
-- Name: general_selection_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER general_selection_history_update AFTER UPDATE ON general_selections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_general_selection_update();


--
-- Name: item_flag_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER item_flag_history_insert AFTER INSERT ON item_flags FOR EACH ROW EXECUTE PROCEDURE log_item_flag_update();


--
-- Name: item_flag_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER item_flag_history_update AFTER UPDATE ON item_flags FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_item_flag_update();


--
-- Name: item_flag_name_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER item_flag_name_history_insert AFTER INSERT ON item_flag_names FOR EACH ROW EXECUTE PROCEDURE log_item_flag_name_update();


--
-- Name: item_flag_name_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER item_flag_name_history_update AFTER UPDATE ON item_flag_names FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_item_flag_name_update();


--
-- Name: player_contact_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER player_contact_history_insert AFTER INSERT ON player_contacts FOR EACH ROW EXECUTE PROCEDURE log_player_contact_update();


--
-- Name: player_contact_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER player_contact_history_update AFTER UPDATE ON player_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_player_contact_update();


--
-- Name: player_info_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER player_info_history_insert AFTER INSERT ON player_infos FOR EACH ROW EXECUTE PROCEDURE log_player_info_update();


--
-- Name: player_info_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER player_info_history_update AFTER UPDATE ON player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_player_info_update();


--
-- Name: player_info_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER player_info_insert AFTER INSERT ON player_infos FOR EACH ROW EXECUTE PROCEDURE update_master_with_player_info();


--
-- Name: player_info_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER player_info_update AFTER UPDATE ON player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_master_with_player_info();


--
-- Name: pro_info_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER pro_info_insert AFTER INSERT ON pro_infos FOR EACH ROW EXECUTE PROCEDURE update_master_with_pro_info();


--
-- Name: pro_info_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER pro_info_update AFTER UPDATE ON pro_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_master_with_pro_info();


--
-- Name: protocol_event_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER protocol_event_history_insert AFTER INSERT ON protocol_events FOR EACH ROW EXECUTE PROCEDURE log_protocol_event_update();


--
-- Name: protocol_event_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER protocol_event_history_update AFTER UPDATE ON protocol_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_protocol_event_update();


--
-- Name: protocol_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER protocol_history_insert AFTER INSERT ON protocols FOR EACH ROW EXECUTE PROCEDURE log_protocol_update();


--
-- Name: protocol_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER protocol_history_update AFTER UPDATE ON protocols FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_protocol_update();


--
-- Name: report_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER report_history_insert AFTER INSERT ON reports FOR EACH ROW EXECUTE PROCEDURE log_report_update();


--
-- Name: report_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER report_history_update AFTER UPDATE ON reports FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_report_update();


--
-- Name: scantron_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER scantron_history_insert AFTER INSERT ON scantrons FOR EACH ROW EXECUTE PROCEDURE log_scantron_update();


--
-- Name: scantron_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER scantron_history_update AFTER UPDATE ON scantrons FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_scantron_update();


--
-- Name: sub_process_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER sub_process_history_insert AFTER INSERT ON sub_processes FOR EACH ROW EXECUTE PROCEDURE log_sub_process_update();


--
-- Name: sub_process_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER sub_process_history_update AFTER UPDATE ON sub_processes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sub_process_update();


--
-- Name: tracker_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER tracker_history_insert AFTER INSERT ON trackers FOR EACH ROW EXECUTE PROCEDURE log_tracker_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER tracker_history_update AFTER UPDATE ON tracker_history FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_tracker_history_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER tracker_history_update AFTER UPDATE ON trackers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_tracker_update();


--
-- Name: tracker_record_delete; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER tracker_record_delete AFTER DELETE ON tracker_history FOR EACH ROW EXECUTE PROCEDURE handle_delete();


--
-- Name: tracker_upsert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER tracker_upsert BEFORE INSERT ON trackers FOR EACH ROW EXECUTE PROCEDURE tracker_upsert();


--
-- Name: user_authorization_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER user_authorization_history_insert AFTER INSERT ON user_authorizations FOR EACH ROW EXECUTE PROCEDURE log_user_authorization_update();


--
-- Name: user_authorization_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER user_authorization_history_update AFTER UPDATE ON user_authorizations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_user_authorization_update();


--
-- Name: user_history_insert; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER user_history_insert AFTER INSERT ON users FOR EACH ROW EXECUTE PROCEDURE log_user_update();


--
-- Name: user_history_update; Type: TRIGGER; Schema: ml_app; Owner: fphs
--

CREATE TRIGGER user_history_update AFTER UPDATE ON users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_user_update();


--
-- Name: fk_accuracy_score_history_accuracy_scores; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY accuracy_score_history
    ADD CONSTRAINT fk_accuracy_score_history_accuracy_scores FOREIGN KEY (accuracy_score_id) REFERENCES accuracy_scores(id);


--
-- Name: fk_address_history_addresses; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT fk_address_history_addresses FOREIGN KEY (address_id) REFERENCES addresses(id);


--
-- Name: fk_address_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT fk_address_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_address_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT fk_address_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_admin_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY admin_history
    ADD CONSTRAINT fk_admin_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_college_history_colleges; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY college_history
    ADD CONSTRAINT fk_college_history_colleges FOREIGN KEY (college_id) REFERENCES colleges(id);


--
-- Name: fk_dynamic_model_history_dynamic_models; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY dynamic_model_history
    ADD CONSTRAINT fk_dynamic_model_history_dynamic_models FOREIGN KEY (dynamic_model_id) REFERENCES dynamic_models(id);


--
-- Name: fk_general_selection_history_general_selections; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY general_selection_history
    ADD CONSTRAINT fk_general_selection_history_general_selections FOREIGN KEY (general_selection_id) REFERENCES general_selections(id);


--
-- Name: fk_item_flag_history_item_flags; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY item_flag_history
    ADD CONSTRAINT fk_item_flag_history_item_flags FOREIGN KEY (item_flag_id) REFERENCES item_flags(id);


--
-- Name: fk_item_flag_name_history_item_flag_names; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY item_flag_name_history
    ADD CONSTRAINT fk_item_flag_name_history_item_flag_names FOREIGN KEY (item_flag_name_id) REFERENCES item_flag_names(id);


--
-- Name: fk_player_contact_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT fk_player_contact_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_player_contact_history_player_contacts; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT fk_player_contact_history_player_contacts FOREIGN KEY (player_contact_id) REFERENCES player_contacts(id);


--
-- Name: fk_player_contact_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT fk_player_contact_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_player_info_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT fk_player_info_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_player_info_history_player_infos; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT fk_player_info_history_player_infos FOREIGN KEY (player_info_id) REFERENCES player_infos(id);


--
-- Name: fk_player_info_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT fk_player_info_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_protocol_event_history_protocol_events; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY protocol_event_history
    ADD CONSTRAINT fk_protocol_event_history_protocol_events FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);


--
-- Name: fk_protocol_history_protocols; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY protocol_history
    ADD CONSTRAINT fk_protocol_history_protocols FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_00b234154d; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY masters
    ADD CONSTRAINT fk_rails_00b234154d FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_08e7f66647; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT fk_rails_08e7f66647 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_0a64e1160a; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT fk_rails_0a64e1160a FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_1694bfe639; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_1694bfe639 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1fc7475261; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT fk_rails_1fc7475261 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_20667815e3; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT fk_rails_20667815e3 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_22ccfd95e1; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY item_flag_names
    ADD CONSTRAINT fk_rails_22ccfd95e1 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_23cd255bc6; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT fk_rails_23cd255bc6 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_447d125f63; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_447d125f63 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_47b051d356; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_47b051d356 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_48c9e0c5a2; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT fk_rails_48c9e0c5a2 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_49306e4f49; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY colleges
    ADD CONSTRAINT fk_rails_49306e4f49 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_564af80fb6; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT fk_rails_564af80fb6 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_623e0ca5ac; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_623e0ca5ac FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_6de4fd560d; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT fk_rails_6de4fd560d FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_6e050927c2; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_6e050927c2 FOREIGN KEY (tracker_id) REFERENCES trackers(id);


--
-- Name: fk_rails_70c17e88fd; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY accuracy_scores
    ADD CONSTRAINT fk_rails_70c17e88fd FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_72b1afe72f; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT fk_rails_72b1afe72f FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_7c10a99849; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT fk_rails_7c10a99849 FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_83aa075398; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_83aa075398 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_86cecb1e36; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT fk_rails_86cecb1e36 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_9513fd1c35; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9513fd1c35 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_971255ec2c; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY sage_assignments
    ADD CONSTRAINT fk_rails_971255ec2c FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_9e92bdfe65; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9e92bdfe65 FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);


--
-- Name: fk_rails_9f5797d684; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9f5797d684 FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_a44670b00a; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT fk_rails_a44670b00a FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_b0a6220067; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY colleges
    ADD CONSTRAINT fk_rails_b0a6220067 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_b138baacff; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT fk_rails_b138baacff FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_b822840dc1; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_b822840dc1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_bb6af37155; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_bb6af37155 FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);


--
-- Name: fk_rails_c2d5bb8930; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT fk_rails_c2d5bb8930 FOREIGN KEY (item_flag_name_id) REFERENCES item_flag_names(id);


--
-- Name: fk_rails_c55341c576; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_c55341c576 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_c9d7977c0c; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY masters
    ADD CONSTRAINT fk_rails_c9d7977c0c FOREIGN KEY (pro_info_id) REFERENCES pro_infos(id);


--
-- Name: fk_rails_d3c0ddde90; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT fk_rails_d3c0ddde90 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_dce5169cfd; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT fk_rails_dce5169cfd FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_deec8fcb38; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY dynamic_models
    ADD CONSTRAINT fk_rails_deec8fcb38 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_e3c559b547; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY sage_assignments
    ADD CONSTRAINT fk_rails_e3c559b547 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_ebab73db27; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY sage_assignments
    ADD CONSTRAINT fk_rails_ebab73db27 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_f62500107f; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY general_selections
    ADD CONSTRAINT fk_rails_f62500107f FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_report_history_reports; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY report_history
    ADD CONSTRAINT fk_report_history_reports FOREIGN KEY (report_id) REFERENCES reports(id);


--
-- Name: fk_scantron_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT fk_scantron_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_scantron_history_scantrons; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT fk_scantron_history_scantrons FOREIGN KEY (scantron_table_id) REFERENCES scantrons(id);


--
-- Name: fk_scantron_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT fk_scantron_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_sub_process_history_sub_processes; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY sub_process_history
    ADD CONSTRAINT fk_sub_process_history_sub_processes FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_user_authorization_history_user_authorizations; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY user_authorization_history
    ADD CONSTRAINT fk_user_authorization_history_user_authorizations FOREIGN KEY (user_authorization_id) REFERENCES user_authorizations(id);


--
-- Name: fk_user_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: fphs
--

ALTER TABLE ONLY user_history
    ADD CONSTRAINT fk_user_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- PostgreSQL database dump complete
--

