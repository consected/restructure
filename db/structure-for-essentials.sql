--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: filestore_admin; Type: SCHEMA; Schema: -; Owner: -
--
BEGIN;

CREATE SCHEMA filestore_admin;
set search_path=filestore_admin;


--
-- Name: add_study_update_entry(integer, character varying, character varying, date, character varying, integer, integer, character varying); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.add_study_update_entry(master_id integer, update_type character varying, update_name character varying, event_date date, update_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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
-- Name: add_tracker_entry_by_name(integer, character varying, character varying, character varying, character varying, integer, integer, character varying); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.add_tracker_entry_by_name(master_id integer, protocol_name character varying, sub_process_name character varying, protocol_event_name character varying, set_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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
-- Name: add_tracker_entry_by_name(integer, character varying, character varying, character varying, date, character varying, integer, integer, character varying); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.add_tracker_entry_by_name(master_id integer, protocol_name character varying, sub_process_name character varying, protocol_event_name character varying, event_date date, set_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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
-- Name: create_message_notification_email(character varying, character varying, character varying, json, character varying[], character varying, timestamp without time zone); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.create_message_notification_email(layout_template_name character varying, content_template_name character varying, subject character varying, data json, recipient_emails character varying[], from_user_email character varying, run_at timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      last_id INTEGER;
    BEGIN

      IF run_at IS NULL THEN
        run_at := now();
      END IF;

      INSERT INTO filestore_admin.message_notifications
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
-- Name: create_message_notification_email(integer, integer, integer, character varying, integer, integer[], character varying, character varying, character varying, timestamp without time zone); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.create_message_notification_email(app_type_id integer, master_id integer, item_id integer, item_type character varying, user_id integer, recipient_user_ids integer[], layout_template_name character varying, content_template_name character varying, subject character varying, run_at timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      last_id INTEGER;
    BEGIN

      IF run_at IS NULL THEN
        run_at := now();
      END IF;

      INSERT INTO filestore_admin.message_notifications
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
-- Name: create_message_notification_job(integer, timestamp without time zone); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.create_message_notification_job(message_notification_id integer, run_at timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      last_id INTEGER;
    BEGIN

      IF run_at IS NULL THEN
        run_at := now();
      END IF;

      INSERT INTO filestore_admin.delayed_jobs
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
-- Name: current_user_id(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.current_user_id() RETURNS integer
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
-- Name: format_update_notes(character varying, character varying, character varying); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.format_update_notes(field_name character varying, old_val character varying, new_val character varying) RETURNS character varying
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
-- Name: handle_delete(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.handle_delete() RETURNS trigger
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
-- Name: handle_tracker_history_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.handle_tracker_history_update() RETURNS trigger
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
-- Name: log_accuracy_score_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_accuracy_score_update() RETURNS trigger
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
    -- Name: log_activity_log_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
    --

CREATE FUNCTION filestore_admin.log_activity_log_update() RETURNS trigger
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
-- Name: log_admin_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_admin_update() RETURNS trigger
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
-- Name: log_college_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_college_update() RETURNS trigger
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
-- Name: log_dynamic_model_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_dynamic_model_update() RETURNS trigger
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
-- Name: log_external_identifier_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_external_identifier_update() RETURNS trigger
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
                        extra_fields,
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
                        NEW.extra_fields,
                        NEW.admin_id,
                        NEW.created_at,
                        NEW.updated_at,
                        NEW.disabled
                    ;
                    RETURN NEW;
                END;
            $$;


--
-- Name: log_external_link_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_external_link_update() RETURNS trigger
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
-- Name: log_general_selection_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_general_selection_update() RETURNS trigger
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
-- Name: log_item_flag_name_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_item_flag_name_update() RETURNS trigger
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
-- Name: log_item_flag_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_item_flag_update() RETURNS trigger
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
-- Name: log_protocol_event_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_protocol_event_update() RETURNS trigger
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
-- Name: log_protocol_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_protocol_update() RETURNS trigger
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
-- Name: log_report_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_report_update() RETURNS trigger
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
-- Name: log_sub_process_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_sub_process_update() RETURNS trigger
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
-- Name: log_tracker_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_tracker_update() RETURNS trigger
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
-- Name: log_user_authorization_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_user_authorization_update() RETURNS trigger
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
-- Name: log_user_update(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.log_user_update() RETURNS trigger
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
-- Name: tracker_upsert(); Type: FUNCTION; Schema: filestore_admin; Owner: -
--

CREATE FUNCTION filestore_admin.tracker_upsert() RETURNS trigger
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



SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accuracy_score_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.accuracy_score_history (
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
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.accuracy_score_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.accuracy_score_history_id_seq OWNED BY filestore_admin.accuracy_score_history.id;


--
-- Name: accuracy_scores; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.accuracy_scores (
    id integer NOT NULL,
    name character varying,
    value integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean
);


--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.accuracy_scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.accuracy_scores_id_seq OWNED BY filestore_admin.accuracy_scores.id;


--
-- Name: activity_log_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.activity_log_history (
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
-- Name: activity_log_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.activity_log_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.activity_log_history_id_seq OWNED BY filestore_admin.activity_log_history.id;




--
-- Name: activity_logs; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.activity_logs (
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
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.activity_logs_id_seq OWNED BY filestore_admin.activity_logs.id;



--
-- Name: admin_action_logs; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.admin_action_logs (
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
-- Name: admin_action_logs_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.admin_action_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_action_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.admin_action_logs_id_seq OWNED BY filestore_admin.admin_action_logs.id;


--
-- Name: admin_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.admin_history (
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
-- Name: admin_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.admin_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.admin_history_id_seq OWNED BY filestore_admin.admin_history.id;


--
-- Name: admins; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.admins (
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
-- Name: admins_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.admins_id_seq OWNED BY filestore_admin.admins.id;


--
-- Name: app_configurations; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.app_configurations (
    id integer NOT NULL,
    name character varying,
    value character varying,
    disabled boolean,
    admin_id integer,
    user_id integer,
    app_type_id integer,
    role_name character varying
);


--
-- Name: app_configurations_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.app_configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.app_configurations_id_seq OWNED BY filestore_admin.app_configurations.id;


--
-- Name: app_types; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.app_types (
    id integer NOT NULL,
    name character varying,
    label character varying,
    disabled boolean,
    admin_id integer
);


--
-- Name: app_types_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.app_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_types_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.app_types_id_seq OWNED BY filestore_admin.app_types.id;


--
-- Name: college_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.college_history (
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
-- Name: college_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.college_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: college_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.college_history_id_seq OWNED BY filestore_admin.college_history.id;


--
-- Name: colleges; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.colleges (
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
-- Name: colleges_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.colleges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: colleges_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.colleges_id_seq OWNED BY filestore_admin.colleges.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.delayed_jobs (
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
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.delayed_jobs_id_seq OWNED BY filestore_admin.delayed_jobs.id;


--
-- Name: dynamic_model_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.dynamic_model_history (
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
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.dynamic_model_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.dynamic_model_history_id_seq OWNED BY filestore_admin.dynamic_model_history.id;


--
-- Name: dynamic_models; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.dynamic_models (
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
-- Name: dynamic_models_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.dynamic_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dynamic_models_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.dynamic_models_id_seq OWNED BY filestore_admin.dynamic_models.id;


--
-- Name: exception_logs; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.exception_logs (
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
-- Name: exception_logs_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.exception_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exception_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.exception_logs_id_seq OWNED BY filestore_admin.exception_logs.id;


--
-- Name: external_identifier_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.external_identifier_history (
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
    external_identifier_id integer,
    extra_fields character varying
);


--
-- Name: external_identifier_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.external_identifier_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_identifier_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.external_identifier_history_id_seq OWNED BY filestore_admin.external_identifier_history.id;


--
-- Name: external_identifiers; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.external_identifiers (
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
    alphanumeric boolean,
    extra_fields character varying
);


--
-- Name: external_identifiers_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.external_identifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_identifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.external_identifiers_id_seq OWNED BY filestore_admin.external_identifiers.id;


--
-- Name: external_link_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.external_link_history (
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
-- Name: external_link_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.external_link_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_link_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.external_link_history_id_seq OWNED BY filestore_admin.external_link_history.id;


--
-- Name: external_links; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.external_links (
    id integer NOT NULL,
    name character varying,
    value character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: external_links_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.external_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_links_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.external_links_id_seq OWNED BY filestore_admin.external_links.id;


--
-- Name: general_selection_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.general_selection_history (
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
-- Name: general_selection_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.general_selection_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: general_selection_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.general_selection_history_id_seq OWNED BY filestore_admin.general_selection_history.id;


--
-- Name: general_selections; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.general_selections (
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
-- Name: general_selections_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.general_selections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: general_selections_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.general_selections_id_seq OWNED BY filestore_admin.general_selections.id;


--
-- Name: imports; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.imports (
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
-- Name: imports_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.imports_id_seq OWNED BY filestore_admin.imports.id;


--
-- Name: item_flag_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.item_flag_history (
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
-- Name: item_flag_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.item_flag_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.item_flag_history_id_seq OWNED BY filestore_admin.item_flag_history.id;


--
-- Name: item_flag_name_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.item_flag_name_history (
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
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.item_flag_name_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.item_flag_name_history_id_seq OWNED BY filestore_admin.item_flag_name_history.id;


--
-- Name: item_flag_names; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.item_flag_names (
    id integer NOT NULL,
    name character varying,
    item_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer
);


--
-- Name: item_flag_names_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.item_flag_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_names_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.item_flag_names_id_seq OWNED BY filestore_admin.item_flag_names.id;


--
-- Name: item_flags; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.item_flags (
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
-- Name: item_flags_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.item_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.item_flags_id_seq OWNED BY filestore_admin.item_flags.id;


--
-- Name: manage_users; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.manage_users (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: manage_users_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.manage_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manage_users_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.manage_users_id_seq OWNED BY filestore_admin.manage_users.id;


--
-- Name: masters; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.masters (
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
-- Name: masters_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.masters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: masters_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.masters_id_seq OWNED BY filestore_admin.masters.id;


--
-- Name: message_notifications; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.message_notifications (
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
-- Name: message_notifications_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.message_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.message_notifications_id_seq OWNED BY filestore_admin.message_notifications.id;


--
-- Name: message_templates; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.message_templates (
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
-- Name: message_templates_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.message_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.message_templates_id_seq OWNED BY filestore_admin.message_templates.id;


--
-- Name: model_references; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.model_references (
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
-- Name: model_references_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.model_references_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: model_references_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.model_references_id_seq OWNED BY filestore_admin.model_references.id;


--
-- Name: msid_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.msid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_archived_files; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.nfs_store_archived_files (
    id integer NOT NULL,
    file_hash character varying,
    file_name character varying NOT NULL,
    content_type character varying NOT NULL,
    archive_file character varying NOT NULL,
    path character varying NOT NULL,
    file_size bigint NOT NULL,
    file_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    nfs_store_container_id integer,
    user_id integer,
    title character varying,
    description character varying,
    nfs_store_stored_file_id integer,
    file_metadata jsonb
);


--
-- Name: nfs_store_archived_files_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.nfs_store_archived_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_archived_files_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.nfs_store_archived_files_id_seq OWNED BY filestore_admin.nfs_store_archived_files.id;


--
-- Name: nfs_store_containers; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.nfs_store_containers (
    id integer NOT NULL,
    name character varying,
    user_id integer,
    app_type_id integer,
    nfs_store_container_id integer,
    master_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: nfs_store_containers_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.nfs_store_containers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_containers_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.nfs_store_containers_id_seq OWNED BY filestore_admin.nfs_store_containers.id;


--
-- Name: nfs_store_downloads; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.nfs_store_downloads (
    id integer NOT NULL,
    user_groups integer[] DEFAULT '{}'::integer[],
    path character varying,
    retrieval_path character varying,
    retrieved_items character varying,
    user_id integer NOT NULL,
    nfs_store_container_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: nfs_store_downloads_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.nfs_store_downloads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_downloads_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.nfs_store_downloads_id_seq OWNED BY filestore_admin.nfs_store_downloads.id;


--
-- Name: nfs_store_filters; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.nfs_store_filters (
    id integer NOT NULL,
    app_type_id integer,
    role_name character varying,
    user_id integer,
    resource_name character varying,
    filter character varying,
    description character varying,
    disabled boolean,
    admin_id integer
);


--
-- Name: nfs_store_filters_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.nfs_store_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.nfs_store_filters_id_seq OWNED BY filestore_admin.nfs_store_filters.id;


--
-- Name: nfs_store_stored_files; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.nfs_store_stored_files (
    id integer NOT NULL,
    file_hash character varying NOT NULL,
    file_name character varying NOT NULL,
    content_type character varying NOT NULL,
    file_size bigint NOT NULL,
    path character varying,
    file_updated_at timestamp without time zone,
    user_id integer,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    title character varying,
    description character varying,
    last_process_name_run character varying,
    file_metadata jsonb
);


--
-- Name: nfs_store_stored_files_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.nfs_store_stored_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_stored_files_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.nfs_store_stored_files_id_seq OWNED BY filestore_admin.nfs_store_stored_files.id;


--
-- Name: nfs_store_uploads; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.nfs_store_uploads (
    id integer NOT NULL,
    file_hash character varying NOT NULL,
    file_name character varying NOT NULL,
    content_type character varying NOT NULL,
    file_size bigint NOT NULL,
    chunk_count integer,
    completed boolean,
    file_updated_at timestamp without time zone,
    user_id integer,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    path character varying,
    nfs_store_stored_file_id integer
);


--
-- Name: nfs_store_uploads_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.nfs_store_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.nfs_store_uploads_id_seq OWNED BY filestore_admin.nfs_store_uploads.id;


--
-- Name: page_layouts; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.page_layouts (
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
-- Name: page_layouts_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.page_layouts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_layouts_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.page_layouts_id_seq OWNED BY filestore_admin.page_layouts.id;


--
-- Name: protocol_event_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.protocol_event_history (
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
-- Name: protocol_event_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.protocol_event_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_event_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.protocol_event_history_id_seq OWNED BY filestore_admin.protocol_event_history.id;


--
-- Name: protocol_events; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.protocol_events (
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
-- Name: protocol_events_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.protocol_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_events_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.protocol_events_id_seq OWNED BY filestore_admin.protocol_events.id;


--
-- Name: protocol_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.protocol_history (
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
-- Name: protocol_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.protocol_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.protocol_history_id_seq OWNED BY filestore_admin.protocol_history.id;


--
-- Name: protocols; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.protocols (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    "position" integer
);


--
-- Name: protocols_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.protocols_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocols_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.protocols_id_seq OWNED BY filestore_admin.protocols.id;


--
-- Name: report_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.report_history (
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
-- Name: report_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.report_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.report_history_id_seq OWNED BY filestore_admin.report_history.id;


--
-- Name: reports; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.reports (
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
-- Name: reports_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.reports_id_seq OWNED BY filestore_admin.reports.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sub_process_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.sub_process_history (
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
-- Name: sub_process_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.sub_process_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_process_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.sub_process_history_id_seq OWNED BY filestore_admin.sub_process_history.id;


--
-- Name: sub_processes; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.sub_processes (
    id integer NOT NULL,
    name character varying,
    disabled boolean,
    protocol_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sub_processes_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.sub_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.sub_processes_id_seq OWNED BY filestore_admin.sub_processes.id;


--
-- Name: tracker_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.tracker_history (
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
-- Name: tracker_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.tracker_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracker_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.tracker_history_id_seq OWNED BY filestore_admin.tracker_history.id;


--
-- Name: trackers; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.trackers (
    id integer NOT NULL,
    master_id integer,
    protocol_id integer NOT NULL,
    event_date timestamp without time zone,
    user_id integer DEFAULT filestore_admin.current_user_id(),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    notes character varying,
    sub_process_id integer NOT NULL,
    protocol_event_id integer,
    item_id integer,
    item_type character varying
);


--
-- Name: trackers_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.trackers_id_seq OWNED BY filestore_admin.trackers.id;


--
-- Name: user_access_controls; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.user_access_controls (
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
-- Name: user_access_controls_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.user_access_controls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_access_controls_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.user_access_controls_id_seq OWNED BY filestore_admin.user_access_controls.id;


--
-- Name: user_action_logs; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.user_action_logs (
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
-- Name: user_action_logs_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.user_action_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_action_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.user_action_logs_id_seq OWNED BY filestore_admin.user_action_logs.id;


--
-- Name: user_authorization_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.user_authorization_history (
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
-- Name: user_authorization_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.user_authorization_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_authorization_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.user_authorization_history_id_seq OWNED BY filestore_admin.user_authorization_history.id;


--
-- Name: user_authorizations; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.user_authorizations (
    id integer NOT NULL,
    user_id integer,
    has_authorization character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_authorizations_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.user_authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.user_authorizations_id_seq OWNED BY filestore_admin.user_authorizations.id;


--
-- Name: user_history; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.user_history (
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
-- Name: user_history_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.user_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_history_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.user_history_id_seq OWNED BY filestore_admin.user_history.id;


--
-- Name: user_roles; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.user_roles (
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
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.user_roles_id_seq OWNED BY filestore_admin.user_roles.id;


--
-- Name: users; Type: TABLE; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE TABLE filestore_admin.users (
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
    app_type_id integer,
    authentication_token character varying(30)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: filestore_admin; Owner: -
--

CREATE SEQUENCE filestore_admin.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: filestore_admin; Owner: -
--

ALTER SEQUENCE filestore_admin.users_id_seq OWNED BY filestore_admin.users.id;


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.accuracy_score_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.accuracy_score_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.accuracy_scores ALTER COLUMN id SET DEFAULT nextval('filestore_admin.accuracy_scores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.activity_log_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.activity_log_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.activity_logs ALTER COLUMN id SET DEFAULT nextval('filestore_admin.activity_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.admin_action_logs ALTER COLUMN id SET DEFAULT nextval('filestore_admin.admin_action_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.admin_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.admin_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.admins ALTER COLUMN id SET DEFAULT nextval('filestore_admin.admins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.app_configurations ALTER COLUMN id SET DEFAULT nextval('filestore_admin.app_configurations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.app_types ALTER COLUMN id SET DEFAULT nextval('filestore_admin.app_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.college_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.college_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.colleges ALTER COLUMN id SET DEFAULT nextval('filestore_admin.colleges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('filestore_admin.delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.dynamic_model_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.dynamic_model_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.dynamic_models ALTER COLUMN id SET DEFAULT nextval('filestore_admin.dynamic_models_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.exception_logs ALTER COLUMN id SET DEFAULT nextval('filestore_admin.exception_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.external_identifier_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.external_identifier_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.external_identifiers ALTER COLUMN id SET DEFAULT nextval('filestore_admin.external_identifiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.external_link_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.external_link_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.external_links ALTER COLUMN id SET DEFAULT nextval('filestore_admin.external_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.general_selection_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.general_selection_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.general_selections ALTER COLUMN id SET DEFAULT nextval('filestore_admin.general_selections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.imports ALTER COLUMN id SET DEFAULT nextval('filestore_admin.imports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.item_flag_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.item_flag_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.item_flag_name_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.item_flag_name_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.item_flag_names ALTER COLUMN id SET DEFAULT nextval('filestore_admin.item_flag_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.item_flags ALTER COLUMN id SET DEFAULT nextval('filestore_admin.item_flags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.manage_users ALTER COLUMN id SET DEFAULT nextval('filestore_admin.manage_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.masters ALTER COLUMN id SET DEFAULT nextval('filestore_admin.masters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.message_notifications ALTER COLUMN id SET DEFAULT nextval('filestore_admin.message_notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.message_templates ALTER COLUMN id SET DEFAULT nextval('filestore_admin.message_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.model_references ALTER COLUMN id SET DEFAULT nextval('filestore_admin.model_references_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_archived_files ALTER COLUMN id SET DEFAULT nextval('filestore_admin.nfs_store_archived_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_containers ALTER COLUMN id SET DEFAULT nextval('filestore_admin.nfs_store_containers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_downloads ALTER COLUMN id SET DEFAULT nextval('filestore_admin.nfs_store_downloads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_filters ALTER COLUMN id SET DEFAULT nextval('filestore_admin.nfs_store_filters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_stored_files ALTER COLUMN id SET DEFAULT nextval('filestore_admin.nfs_store_stored_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_uploads ALTER COLUMN id SET DEFAULT nextval('filestore_admin.nfs_store_uploads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.page_layouts ALTER COLUMN id SET DEFAULT nextval('filestore_admin.page_layouts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.protocol_event_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.protocol_event_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.protocol_events ALTER COLUMN id SET DEFAULT nextval('filestore_admin.protocol_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.protocol_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.protocol_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.protocols ALTER COLUMN id SET DEFAULT nextval('filestore_admin.protocols_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.report_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.report_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.reports ALTER COLUMN id SET DEFAULT nextval('filestore_admin.reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.sub_process_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.sub_process_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.sub_processes ALTER COLUMN id SET DEFAULT nextval('filestore_admin.sub_processes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.tracker_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.tracker_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.trackers ALTER COLUMN id SET DEFAULT nextval('filestore_admin.trackers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_access_controls ALTER COLUMN id SET DEFAULT nextval('filestore_admin.user_access_controls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_action_logs ALTER COLUMN id SET DEFAULT nextval('filestore_admin.user_action_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_authorization_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.user_authorization_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_authorizations ALTER COLUMN id SET DEFAULT nextval('filestore_admin.user_authorizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_history ALTER COLUMN id SET DEFAULT nextval('filestore_admin.user_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_roles ALTER COLUMN id SET DEFAULT nextval('filestore_admin.user_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.users ALTER COLUMN id SET DEFAULT nextval('filestore_admin.users_id_seq'::regclass);


--
-- Name: accuracy_score_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.accuracy_score_history
    ADD CONSTRAINT accuracy_score_history_pkey PRIMARY KEY (id);


--
-- Name: accuracy_scores_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.accuracy_scores
    ADD CONSTRAINT accuracy_scores_pkey PRIMARY KEY (id);


--
-- Name: activity_log_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.activity_log_history
    ADD CONSTRAINT activity_log_history_pkey PRIMARY KEY (id);


--
-- Name: activity_logs_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: admin_action_logs_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.admin_action_logs
    ADD CONSTRAINT admin_action_logs_pkey PRIMARY KEY (id);


--
-- Name: admin_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.admin_history
    ADD CONSTRAINT admin_history_pkey PRIMARY KEY (id);


--
-- Name: admins_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: app_configurations_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.app_configurations
    ADD CONSTRAINT app_configurations_pkey PRIMARY KEY (id);


--
-- Name: app_types_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.app_types
    ADD CONSTRAINT app_types_pkey PRIMARY KEY (id);


--
-- Name: college_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.college_history
    ADD CONSTRAINT college_history_pkey PRIMARY KEY (id);


--
-- Name: colleges_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.colleges
    ADD CONSTRAINT colleges_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: dynamic_model_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.dynamic_model_history
    ADD CONSTRAINT dynamic_model_history_pkey PRIMARY KEY (id);


--
-- Name: dynamic_models_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.dynamic_models
    ADD CONSTRAINT dynamic_models_pkey PRIMARY KEY (id);


--
-- Name: exception_logs_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.exception_logs
    ADD CONSTRAINT exception_logs_pkey PRIMARY KEY (id);


--
-- Name: external_identifier_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.external_identifier_history
    ADD CONSTRAINT external_identifier_history_pkey PRIMARY KEY (id);


--
-- Name: external_identifiers_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.external_identifiers
    ADD CONSTRAINT external_identifiers_pkey PRIMARY KEY (id);


--
-- Name: external_link_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.external_link_history
    ADD CONSTRAINT external_link_history_pkey PRIMARY KEY (id);


--
-- Name: external_links_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.external_links
    ADD CONSTRAINT external_links_pkey PRIMARY KEY (id);


--
-- Name: general_selection_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.general_selection_history
    ADD CONSTRAINT general_selection_history_pkey PRIMARY KEY (id);


--
-- Name: general_selections_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.general_selections
    ADD CONSTRAINT general_selections_pkey PRIMARY KEY (id);


--
-- Name: imports_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: item_flag_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.item_flag_history
    ADD CONSTRAINT item_flag_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_name_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.item_flag_name_history
    ADD CONSTRAINT item_flag_name_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_names_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.item_flag_names
    ADD CONSTRAINT item_flag_names_pkey PRIMARY KEY (id);


--
-- Name: item_flags_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.item_flags
    ADD CONSTRAINT item_flags_pkey PRIMARY KEY (id);


--
-- Name: manage_users_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.manage_users
    ADD CONSTRAINT manage_users_pkey PRIMARY KEY (id);


--
-- Name: masters_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.masters
    ADD CONSTRAINT masters_pkey PRIMARY KEY (id);


--
-- Name: message_notifications_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.message_notifications
    ADD CONSTRAINT message_notifications_pkey PRIMARY KEY (id);


--
-- Name: message_templates_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.message_templates
    ADD CONSTRAINT message_templates_pkey PRIMARY KEY (id);


--
-- Name: model_references_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.model_references
    ADD CONSTRAINT model_references_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_archived_files_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.nfs_store_archived_files
    ADD CONSTRAINT nfs_store_archived_files_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_containers_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.nfs_store_containers
    ADD CONSTRAINT nfs_store_containers_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_downloads_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.nfs_store_downloads
    ADD CONSTRAINT nfs_store_downloads_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_filters_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.nfs_store_filters
    ADD CONSTRAINT nfs_store_filters_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_stored_files_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.nfs_store_stored_files
    ADD CONSTRAINT nfs_store_stored_files_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_uploads_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.nfs_store_uploads
    ADD CONSTRAINT nfs_store_uploads_pkey PRIMARY KEY (id);


--
-- Name: page_layouts_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.page_layouts
    ADD CONSTRAINT page_layouts_pkey PRIMARY KEY (id);

--
-- Name: protocol_event_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.protocol_event_history
    ADD CONSTRAINT protocol_event_history_pkey PRIMARY KEY (id);


--
-- Name: protocol_events_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.protocol_events
    ADD CONSTRAINT protocol_events_pkey PRIMARY KEY (id);


--
-- Name: protocol_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.protocol_history
    ADD CONSTRAINT protocol_history_pkey PRIMARY KEY (id);


--
-- Name: protocols_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- Name: report_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.report_history
    ADD CONSTRAINT report_history_pkey PRIMARY KEY (id);


--
-- Name: reports_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: sub_process_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.sub_process_history
    ADD CONSTRAINT sub_process_history_pkey PRIMARY KEY (id);


--
-- Name: sub_processes_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.sub_processes
    ADD CONSTRAINT sub_processes_pkey PRIMARY KEY (id);


--
-- Name: tracker_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.tracker_history
    ADD CONSTRAINT tracker_history_pkey PRIMARY KEY (id);


--
-- Name: trackers_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.trackers
    ADD CONSTRAINT trackers_pkey PRIMARY KEY (id);


--
-- Name: unique_master_protocol; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.trackers
    ADD CONSTRAINT unique_master_protocol UNIQUE (master_id, protocol_id);


--
-- Name: unique_master_protocol_id; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.trackers
    ADD CONSTRAINT unique_master_protocol_id UNIQUE (master_id, protocol_id, id);


--
-- Name: unique_protocol_and_id; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.sub_processes
    ADD CONSTRAINT unique_protocol_and_id UNIQUE (protocol_id, id);


--
-- Name: unique_sub_process_and_id; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.protocol_events
    ADD CONSTRAINT unique_sub_process_and_id UNIQUE (sub_process_id, id);


--
-- Name: user_access_controls_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.user_access_controls
    ADD CONSTRAINT user_access_controls_pkey PRIMARY KEY (id);


--
-- Name: user_action_logs_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.user_action_logs
    ADD CONSTRAINT user_action_logs_pkey PRIMARY KEY (id);


--
-- Name: user_authorization_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.user_authorization_history
    ADD CONSTRAINT user_authorization_history_pkey PRIMARY KEY (id);


--
-- Name: user_authorizations_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.user_authorizations
    ADD CONSTRAINT user_authorizations_pkey PRIMARY KEY (id);


--
-- Name: user_history_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.user_history
    ADD CONSTRAINT user_history_pkey PRIMARY KEY (id);


--
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: filestore_admin; Owner: -; Tablespace:
--

ALTER TABLE ONLY filestore_admin.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX delayed_jobs_priority ON filestore_admin.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_accuracy_score_history_on_accuracy_score_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_accuracy_score_history_on_accuracy_score_id ON filestore_admin.accuracy_score_history USING btree (accuracy_score_id);


--
-- Name: index_accuracy_scores_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_accuracy_scores_on_admin_id ON filestore_admin.accuracy_scores USING btree (admin_id);


--
-- Name: index_activity_log_history_on_activity_log_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_activity_log_history_on_activity_log_id ON filestore_admin.activity_log_history USING btree (activity_log_id);


--
-- Name: index_admin_action_logs_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_admin_action_logs_on_admin_id ON filestore_admin.admin_action_logs USING btree (admin_id);


--
-- Name: index_admin_history_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_admin_history_on_admin_id ON filestore_admin.admin_history USING btree (admin_id);


--
-- Name: index_app_configurations_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_app_configurations_on_admin_id ON filestore_admin.app_configurations USING btree (admin_id);


--
-- Name: index_app_configurations_on_app_type_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_app_configurations_on_app_type_id ON filestore_admin.app_configurations USING btree (app_type_id);


--
-- Name: index_app_configurations_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_app_configurations_on_user_id ON filestore_admin.app_configurations USING btree (user_id);


--
-- Name: index_app_types_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_app_types_on_admin_id ON filestore_admin.app_types USING btree (admin_id);


--
-- Name: index_college_history_on_college_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_college_history_on_college_id ON filestore_admin.college_history USING btree (college_id);


--
-- Name: index_colleges_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_colleges_on_admin_id ON filestore_admin.colleges USING btree (admin_id);


--
-- Name: index_colleges_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_colleges_on_user_id ON filestore_admin.colleges USING btree (user_id);


--
-- Name: index_dynamic_model_history_on_dynamic_model_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_dynamic_model_history_on_dynamic_model_id ON filestore_admin.dynamic_model_history USING btree (dynamic_model_id);


--
-- Name: index_dynamic_models_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_dynamic_models_on_admin_id ON filestore_admin.dynamic_models USING btree (admin_id);


--
-- Name: index_exception_logs_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_exception_logs_on_admin_id ON filestore_admin.exception_logs USING btree (admin_id);


--
-- Name: index_exception_logs_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_exception_logs_on_user_id ON filestore_admin.exception_logs USING btree (user_id);


--
-- Name: index_external_identifier_history_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_external_identifier_history_on_admin_id ON filestore_admin.external_identifier_history USING btree (admin_id);


--
-- Name: index_external_identifier_history_on_external_identifier_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_external_identifier_history_on_external_identifier_id ON filestore_admin.external_identifier_history USING btree (external_identifier_id);


--
-- Name: index_external_identifiers_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_external_identifiers_on_admin_id ON filestore_admin.external_identifiers USING btree (admin_id);


--
-- Name: index_external_link_history_on_external_link_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_external_link_history_on_external_link_id ON filestore_admin.external_link_history USING btree (external_link_id);


--
-- Name: index_external_links_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_external_links_on_admin_id ON filestore_admin.external_links USING btree (admin_id);


--
-- Name: index_general_selection_history_on_general_selection_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_general_selection_history_on_general_selection_id ON filestore_admin.general_selection_history USING btree (general_selection_id);


--
-- Name: index_general_selections_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_general_selections_on_admin_id ON filestore_admin.general_selections USING btree (admin_id);


--
-- Name: index_imports_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_imports_on_user_id ON filestore_admin.imports USING btree (user_id);


--
-- Name: index_item_flag_history_on_item_flag_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_item_flag_history_on_item_flag_id ON filestore_admin.item_flag_history USING btree (item_flag_id);


--
-- Name: index_item_flag_name_history_on_item_flag_name_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_item_flag_name_history_on_item_flag_name_id ON filestore_admin.item_flag_name_history USING btree (item_flag_name_id);


--
-- Name: index_item_flag_names_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_item_flag_names_on_admin_id ON filestore_admin.item_flag_names USING btree (admin_id);


--
-- Name: index_item_flags_on_item_flag_name_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_item_flags_on_item_flag_name_id ON filestore_admin.item_flags USING btree (item_flag_name_id);


--
-- Name: index_item_flags_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_item_flags_on_user_id ON filestore_admin.item_flags USING btree (user_id);


--
-- Name: index_masters_on_msid; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_masters_on_msid ON filestore_admin.masters USING btree (msid);


--
-- Name: index_masters_on_pro_info_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_masters_on_pro_info_id ON filestore_admin.masters USING btree (pro_info_id);


--
-- Name: index_masters_on_proid; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_masters_on_proid ON filestore_admin.masters USING btree (pro_id);


--
-- Name: index_masters_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_masters_on_user_id ON filestore_admin.masters USING btree (user_id);


--
-- Name: index_message_notifications_on_app_type_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_message_notifications_on_app_type_id ON filestore_admin.message_notifications USING btree (app_type_id);


--
-- Name: index_message_notifications_on_master_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_message_notifications_on_master_id ON filestore_admin.message_notifications USING btree (master_id);


--
-- Name: index_message_notifications_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_message_notifications_on_user_id ON filestore_admin.message_notifications USING btree (user_id);


--
-- Name: index_message_notifications_status; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_message_notifications_status ON filestore_admin.message_notifications USING btree (status);


--
-- Name: index_message_templates_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_message_templates_on_admin_id ON filestore_admin.message_templates USING btree (admin_id);


--
-- Name: index_model_references_on_from_record_master_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_model_references_on_from_record_master_id ON filestore_admin.model_references USING btree (from_record_master_id);


--
-- Name: index_model_references_on_from_record_type_and_from_record_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_model_references_on_from_record_type_and_from_record_id ON filestore_admin.model_references USING btree (from_record_type, from_record_id);


--
-- Name: index_model_references_on_to_record_master_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_model_references_on_to_record_master_id ON filestore_admin.model_references USING btree (to_record_master_id);


--
-- Name: index_model_references_on_to_record_type_and_to_record_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_model_references_on_to_record_type_and_to_record_id ON filestore_admin.model_references USING btree (to_record_type, to_record_id);


--
-- Name: index_model_references_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_model_references_on_user_id ON filestore_admin.model_references USING btree (user_id);


--
-- Name: index_nfs_store_archived_files_on_nfs_store_container_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_nfs_store_archived_files_on_nfs_store_container_id ON filestore_admin.nfs_store_archived_files USING btree (nfs_store_container_id);


--
-- Name: index_nfs_store_archived_files_on_nfs_store_stored_file_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_nfs_store_archived_files_on_nfs_store_stored_file_id ON filestore_admin.nfs_store_archived_files USING btree (nfs_store_stored_file_id);


--
-- Name: index_nfs_store_containers_on_master_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_nfs_store_containers_on_master_id ON filestore_admin.nfs_store_containers USING btree (master_id);


--
-- Name: index_nfs_store_containers_on_nfs_store_container_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_nfs_store_containers_on_nfs_store_container_id ON filestore_admin.nfs_store_containers USING btree (nfs_store_container_id);


--
-- Name: index_nfs_store_filters_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_nfs_store_filters_on_admin_id ON filestore_admin.nfs_store_filters USING btree (admin_id);


--
-- Name: index_nfs_store_filters_on_app_type_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_nfs_store_filters_on_app_type_id ON filestore_admin.nfs_store_filters USING btree (app_type_id);


--
-- Name: index_nfs_store_filters_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_nfs_store_filters_on_user_id ON filestore_admin.nfs_store_filters USING btree (user_id);


--
-- Name: index_nfs_store_stored_files_on_nfs_store_container_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_nfs_store_stored_files_on_nfs_store_container_id ON filestore_admin.nfs_store_stored_files USING btree (nfs_store_container_id);


--
-- Name: index_nfs_store_uploads_on_nfs_store_stored_file_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_nfs_store_uploads_on_nfs_store_stored_file_id ON filestore_admin.nfs_store_uploads USING btree (nfs_store_stored_file_id);


--
-- Name: index_page_layouts_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_page_layouts_on_admin_id ON filestore_admin.page_layouts USING btree (admin_id);


--
-- Name: index_page_layouts_on_app_type_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_page_layouts_on_app_type_id ON filestore_admin.page_layouts USING btree (app_type_id);


--
--
-- Name: index_protocol_event_history_on_protocol_event_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_protocol_event_history_on_protocol_event_id ON filestore_admin.protocol_event_history USING btree (protocol_event_id);


--
-- Name: index_protocol_events_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_protocol_events_on_admin_id ON filestore_admin.protocol_events USING btree (admin_id);


--
-- Name: index_protocol_events_on_sub_process_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_protocol_events_on_sub_process_id ON filestore_admin.protocol_events USING btree (sub_process_id);


--
-- Name: index_protocol_history_on_protocol_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_protocol_history_on_protocol_id ON filestore_admin.protocol_history USING btree (protocol_id);


--
-- Name: index_protocols_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_protocols_on_admin_id ON filestore_admin.protocols USING btree (admin_id);


--
-- Name: index_report_history_on_report_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_report_history_on_report_id ON filestore_admin.report_history USING btree (report_id);


--
-- Name: index_reports_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_reports_on_admin_id ON filestore_admin.reports USING btree (admin_id);


--
-- Name: index_sub_process_history_on_sub_process_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_sub_process_history_on_sub_process_id ON filestore_admin.sub_process_history USING btree (sub_process_id);


--
-- Name: index_sub_processes_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_sub_processes_on_admin_id ON filestore_admin.sub_processes USING btree (admin_id);


--
-- Name: index_sub_processes_on_protocol_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_sub_processes_on_protocol_id ON filestore_admin.sub_processes USING btree (protocol_id);


--
-- Name: index_tracker_history_on_master_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_tracker_history_on_master_id ON filestore_admin.tracker_history USING btree (master_id);


--
-- Name: index_tracker_history_on_protocol_event_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_tracker_history_on_protocol_event_id ON filestore_admin.tracker_history USING btree (protocol_event_id);


--
-- Name: index_tracker_history_on_protocol_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_tracker_history_on_protocol_id ON filestore_admin.tracker_history USING btree (protocol_id);


--
-- Name: index_tracker_history_on_sub_process_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_tracker_history_on_sub_process_id ON filestore_admin.tracker_history USING btree (sub_process_id);


--
-- Name: index_tracker_history_on_tracker_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_tracker_history_on_tracker_id ON filestore_admin.tracker_history USING btree (tracker_id);


--
-- Name: index_tracker_history_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_tracker_history_on_user_id ON filestore_admin.tracker_history USING btree (user_id);


--
-- Name: index_trackers_on_master_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_trackers_on_master_id ON filestore_admin.trackers USING btree (master_id);


--
-- Name: index_trackers_on_protocol_event_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_trackers_on_protocol_event_id ON filestore_admin.trackers USING btree (protocol_event_id);


--
-- Name: index_trackers_on_protocol_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_trackers_on_protocol_id ON filestore_admin.trackers USING btree (protocol_id);


--
-- Name: index_trackers_on_sub_process_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_trackers_on_sub_process_id ON filestore_admin.trackers USING btree (sub_process_id);


--
-- Name: index_trackers_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_trackers_on_user_id ON filestore_admin.trackers USING btree (user_id);


--
-- Name: index_user_access_controls_on_app_type_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_user_access_controls_on_app_type_id ON filestore_admin.user_access_controls USING btree (app_type_id);


--
-- Name: index_user_action_logs_on_app_type_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_user_action_logs_on_app_type_id ON filestore_admin.user_action_logs USING btree (app_type_id);


--
-- Name: index_user_action_logs_on_master_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_user_action_logs_on_master_id ON filestore_admin.user_action_logs USING btree (master_id);


--
-- Name: index_user_action_logs_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_user_action_logs_on_user_id ON filestore_admin.user_action_logs USING btree (user_id);


--
-- Name: index_user_authorization_history_on_user_authorization_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_user_authorization_history_on_user_authorization_id ON filestore_admin.user_authorization_history USING btree (user_authorization_id);


--
-- Name: index_user_history_on_app_type_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_user_history_on_app_type_id ON filestore_admin.user_history USING btree (app_type_id);


--
-- Name: index_user_history_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_user_history_on_user_id ON filestore_admin.user_history USING btree (user_id);


--
-- Name: index_user_roles_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_user_roles_on_admin_id ON filestore_admin.user_roles USING btree (admin_id);


--
-- Name: index_user_roles_on_app_type_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_user_roles_on_app_type_id ON filestore_admin.user_roles USING btree (app_type_id);


--
-- Name: index_user_roles_on_user_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_user_roles_on_user_id ON filestore_admin.user_roles USING btree (user_id);


--
-- Name: index_users_on_admin_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_users_on_admin_id ON filestore_admin.users USING btree (admin_id);


--
-- Name: index_users_on_app_type_id; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE INDEX index_users_on_app_type_id ON filestore_admin.users USING btree (app_type_id);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_users_on_authentication_token ON filestore_admin.users USING btree (authentication_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_users_on_email ON filestore_admin.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON filestore_admin.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON filestore_admin.users USING btree (unlock_token);


--
-- Name: nfs_store_stored_files_unique_file; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX nfs_store_stored_files_unique_file ON filestore_admin.nfs_store_stored_files USING btree (nfs_store_container_id, file_hash, file_name, path);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: filestore_admin; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX unique_schema_migrations ON filestore_admin.schema_migrations USING btree (version);


--
-- Name: accuracy_score_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER accuracy_score_history_insert AFTER INSERT ON filestore_admin.accuracy_scores FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_accuracy_score_update();


--
-- Name: accuracy_score_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER accuracy_score_history_update AFTER UPDATE ON filestore_admin.accuracy_scores FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_accuracy_score_update();


--
-- Name: activity_log_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER activity_log_history_insert AFTER INSERT ON filestore_admin.activity_logs FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_activity_log_update();


--
-- Name: activity_log_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER activity_log_history_update AFTER UPDATE ON filestore_admin.activity_logs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_activity_log_update();


--
-- Name: admin_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER admin_history_insert AFTER INSERT ON filestore_admin.admins FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_admin_update();


--
-- Name: admin_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER admin_history_update AFTER UPDATE ON filestore_admin.admins FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_admin_update();


--
-- Name: college_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER college_history_insert AFTER INSERT ON filestore_admin.colleges FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_college_update();


--
-- Name: college_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER college_history_update AFTER UPDATE ON filestore_admin.colleges FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_college_update();


--
-- Name: dynamic_model_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER dynamic_model_history_insert AFTER INSERT ON filestore_admin.dynamic_models FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_dynamic_model_update();


--
-- Name: dynamic_model_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER dynamic_model_history_update AFTER UPDATE ON filestore_admin.dynamic_models FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_dynamic_model_update();


--
-- Name: external_identifier_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER external_identifier_history_insert AFTER INSERT ON filestore_admin.external_identifiers FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_external_identifier_update();


--
-- Name: external_identifier_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER external_identifier_history_update AFTER UPDATE ON filestore_admin.external_identifiers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_external_identifier_update();


--
-- Name: external_link_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER external_link_history_insert AFTER INSERT ON filestore_admin.external_links FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_external_link_update();


--
-- Name: external_link_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER external_link_history_update AFTER UPDATE ON filestore_admin.external_links FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_external_link_update();


--
-- Name: general_selection_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER general_selection_history_insert AFTER INSERT ON filestore_admin.general_selections FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_general_selection_update();


--
-- Name: general_selection_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER general_selection_history_update AFTER UPDATE ON filestore_admin.general_selections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_general_selection_update();


--
-- Name: item_flag_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER item_flag_history_insert AFTER INSERT ON filestore_admin.item_flags FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_item_flag_update();


--
-- Name: item_flag_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER item_flag_history_update AFTER UPDATE ON filestore_admin.item_flags FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_item_flag_update();


--
-- Name: item_flag_name_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER item_flag_name_history_insert AFTER INSERT ON filestore_admin.item_flag_names FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_item_flag_name_update();


--
-- Name: item_flag_name_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER item_flag_name_history_update AFTER UPDATE ON filestore_admin.item_flag_names FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_item_flag_name_update();


--
-- Name: protocol_event_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER protocol_event_history_insert AFTER INSERT ON filestore_admin.protocol_events FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_protocol_event_update();


--
-- Name: protocol_event_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER protocol_event_history_update AFTER UPDATE ON filestore_admin.protocol_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_protocol_event_update();


--
-- Name: protocol_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER protocol_history_insert AFTER INSERT ON filestore_admin.protocols FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_protocol_update();


--
-- Name: protocol_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER protocol_history_update AFTER UPDATE ON filestore_admin.protocols FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_protocol_update();



--
-- Name: report_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER report_history_insert AFTER INSERT ON filestore_admin.reports FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_report_update();


--
-- Name: report_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER report_history_update AFTER UPDATE ON filestore_admin.reports FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_report_update();


--
-- Name: sub_process_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER sub_process_history_insert AFTER INSERT ON filestore_admin.sub_processes FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_sub_process_update();


--
-- Name: sub_process_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER sub_process_history_update AFTER UPDATE ON filestore_admin.sub_processes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_sub_process_update();


--
-- Name: tracker_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER tracker_history_insert AFTER INSERT ON filestore_admin.trackers FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_tracker_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER tracker_history_update AFTER UPDATE ON filestore_admin.trackers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_tracker_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER tracker_history_update BEFORE UPDATE ON filestore_admin.tracker_history FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.handle_tracker_history_update();


--
-- Name: tracker_record_delete; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER tracker_record_delete AFTER DELETE ON filestore_admin.tracker_history FOR EACH ROW EXECUTE PROCEDURE filestore_admin.handle_delete();


--
-- Name: tracker_upsert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER tracker_upsert BEFORE INSERT ON filestore_admin.trackers FOR EACH ROW EXECUTE PROCEDURE filestore_admin.tracker_upsert();


--
-- Name: user_authorization_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER user_authorization_history_insert AFTER INSERT ON filestore_admin.user_authorizations FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_user_authorization_update();


--
-- Name: user_authorization_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER user_authorization_history_update AFTER UPDATE ON filestore_admin.user_authorizations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_user_authorization_update();


--
-- Name: user_history_insert; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER user_history_insert AFTER INSERT ON filestore_admin.users FOR EACH ROW EXECUTE PROCEDURE filestore_admin.log_user_update();


--
-- Name: user_history_update; Type: TRIGGER; Schema: filestore_admin; Owner: -
--

CREATE TRIGGER user_history_update AFTER UPDATE ON filestore_admin.users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE filestore_admin.log_user_update();


--
-- Name: fk_accuracy_score_history_accuracy_scores; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.accuracy_score_history
    ADD CONSTRAINT fk_accuracy_score_history_accuracy_scores FOREIGN KEY (accuracy_score_id) REFERENCES filestore_admin.accuracy_scores(id);


--
-- Name: fk_admin_history_admins; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.admin_history
    ADD CONSTRAINT fk_admin_history_admins FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_college_history_colleges; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.college_history
    ADD CONSTRAINT fk_college_history_colleges FOREIGN KEY (college_id) REFERENCES filestore_admin.colleges(id);


--
-- Name: fk_dynamic_model_history_dynamic_models; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.dynamic_model_history
    ADD CONSTRAINT fk_dynamic_model_history_dynamic_models FOREIGN KEY (dynamic_model_id) REFERENCES filestore_admin.dynamic_models(id);


--
-- Name: fk_external_link_history_external_links; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.external_link_history
    ADD CONSTRAINT fk_external_link_history_external_links FOREIGN KEY (external_link_id) REFERENCES filestore_admin.external_links(id);


--
-- Name: fk_general_selection_history_general_selections; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.general_selection_history
    ADD CONSTRAINT fk_general_selection_history_general_selections FOREIGN KEY (general_selection_id) REFERENCES filestore_admin.general_selections(id);


--
-- Name: fk_item_flag_history_item_flags; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.item_flag_history
    ADD CONSTRAINT fk_item_flag_history_item_flags FOREIGN KEY (item_flag_id) REFERENCES filestore_admin.item_flags(id);


--
-- Name: fk_item_flag_name_history_item_flag_names; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.item_flag_name_history
    ADD CONSTRAINT fk_item_flag_name_history_item_flag_names FOREIGN KEY (item_flag_name_id) REFERENCES filestore_admin.item_flag_names(id);


--
-- Name: fk_protocol_event_history_protocol_events; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.protocol_event_history
    ADD CONSTRAINT fk_protocol_event_history_protocol_events FOREIGN KEY (protocol_event_id) REFERENCES filestore_admin.protocol_events(id);


--
-- Name: fk_protocol_history_protocols; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.protocol_history
    ADD CONSTRAINT fk_protocol_history_protocols FOREIGN KEY (protocol_id) REFERENCES filestore_admin.protocols(id);


--
-- Name: fk_rails_00b234154d; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.masters
    ADD CONSTRAINT fk_rails_00b234154d FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_00f31a00c4; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.app_configurations
    ADD CONSTRAINT fk_rails_00f31a00c4 FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_0208c3b54d; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_filters
    ADD CONSTRAINT fk_rails_0208c3b54d FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_0210618434; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.external_identifier_history
    ADD CONSTRAINT fk_rails_0210618434 FOREIGN KEY (external_identifier_id) REFERENCES filestore_admin.external_identifiers(id);



--
-- Name: fk_rails_08eec3f089; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_action_logs
    ADD CONSTRAINT fk_rails_08eec3f089 FOREIGN KEY (master_id) REFERENCES filestore_admin.masters(id);


--
-- Name: fk_rails_0a64e1160a; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.protocol_events
    ADD CONSTRAINT fk_rails_0a64e1160a FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_0c84487284; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_containers
    ADD CONSTRAINT fk_rails_0c84487284 FOREIGN KEY (nfs_store_container_id) REFERENCES filestore_admin.nfs_store_containers(id);


--
-- Name: fk_rails_0de144234e; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_stored_files
    ADD CONSTRAINT fk_rails_0de144234e FOREIGN KEY (nfs_store_container_id) REFERENCES filestore_admin.nfs_store_containers(id);


--
-- Name: fk_rails_1694bfe639; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.users
    ADD CONSTRAINT fk_rails_1694bfe639 FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_16d57266f7; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.activity_log_history
    ADD CONSTRAINT fk_rails_16d57266f7 FOREIGN KEY (activity_log_id) REFERENCES filestore_admin.activity_logs(id);


--
-- Name: fk_rails_174e058eb3; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_roles
    ADD CONSTRAINT fk_rails_174e058eb3 FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_1cc4562569; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_stored_files
    ADD CONSTRAINT fk_rails_1cc4562569 FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);



--
-- Name: fk_rails_1fc7475261; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.sub_processes
    ADD CONSTRAINT fk_rails_1fc7475261 FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);



--
-- Name: fk_rails_22ccfd95e1; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.item_flag_names
    ADD CONSTRAINT fk_rails_22ccfd95e1 FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);



--
-- Name: fk_rails_2708bd6a94; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_containers
    ADD CONSTRAINT fk_rails_2708bd6a94 FOREIGN KEY (master_id) REFERENCES filestore_admin.masters(id);


--
-- Name: fk_rails_272f69e6af; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_downloads
    ADD CONSTRAINT fk_rails_272f69e6af FOREIGN KEY (nfs_store_container_id) REFERENCES filestore_admin.nfs_store_containers(id);


--
-- Name: fk_rails_2b59e23148; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_archived_files
    ADD CONSTRAINT fk_rails_2b59e23148 FOREIGN KEY (nfs_store_stored_file_id) REFERENCES filestore_admin.nfs_store_stored_files(id);


--
-- Name: fk_rails_2d8072edea; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.model_references
    ADD CONSTRAINT fk_rails_2d8072edea FOREIGN KEY (to_record_master_id) REFERENCES filestore_admin.masters(id);


--
-- Name: fk_rails_2eab578259; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_archived_files
    ADD CONSTRAINT fk_rails_2eab578259 FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_318345354e; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_roles
    ADD CONSTRAINT fk_rails_318345354e FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_3389f178f6; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.admin_action_logs
    ADD CONSTRAINT fk_rails_3389f178f6 FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_37a2f11066; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.page_layouts
    ADD CONSTRAINT fk_rails_37a2f11066 FOREIGN KEY (app_type_id) REFERENCES filestore_admin.app_types(id);


--
-- Name: fk_rails_3a3553e146; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.message_notifications
    ADD CONSTRAINT fk_rails_3a3553e146 FOREIGN KEY (master_id) REFERENCES filestore_admin.masters(id);


--
-- Name: fk_rails_3f5167a964; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_uploads
    ADD CONSTRAINT fk_rails_3f5167a964 FOREIGN KEY (nfs_store_container_id) REFERENCES filestore_admin.nfs_store_containers(id);


--
-- Name: fk_rails_447d125f63; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.trackers
    ADD CONSTRAINT fk_rails_447d125f63 FOREIGN KEY (master_id) REFERENCES filestore_admin.masters(id);


--
-- Name: fk_rails_47b051d356; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.trackers
    ADD CONSTRAINT fk_rails_47b051d356 FOREIGN KEY (sub_process_id) REFERENCES filestore_admin.sub_processes(id);


--
-- Name: fk_rails_49306e4f49; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.colleges
    ADD CONSTRAINT fk_rails_49306e4f49 FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_4bbf83b940; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.model_references
    ADD CONSTRAINT fk_rails_4bbf83b940 FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_4fe5122ed4; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.message_templates
    ADD CONSTRAINT fk_rails_4fe5122ed4 FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_4ff6d28f98; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_uploads
    ADD CONSTRAINT fk_rails_4ff6d28f98 FOREIGN KEY (nfs_store_stored_file_id) REFERENCES filestore_admin.nfs_store_stored_files(id);


--
-- Name: fk_rails_51ae125c4f; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.exception_logs
    ADD CONSTRAINT fk_rails_51ae125c4f FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_564af80fb6; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.protocol_events
    ADD CONSTRAINT fk_rails_564af80fb6 FOREIGN KEY (sub_process_id) REFERENCES filestore_admin.sub_processes(id);


--
-- Name: fk_rails_5b0628cf42; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.external_identifier_history
    ADD CONSTRAINT fk_rails_5b0628cf42 FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_623e0ca5ac; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.trackers
    ADD CONSTRAINT fk_rails_623e0ca5ac FOREIGN KEY (protocol_id) REFERENCES filestore_admin.protocols(id);


--
-- Name: fk_rails_647c63b069; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.app_configurations
    ADD CONSTRAINT fk_rails_647c63b069 FOREIGN KEY (app_type_id) REFERENCES filestore_admin.app_types(id);


--
-- Name: fk_rails_6a3d7bf39f; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_containers
    ADD CONSTRAINT fk_rails_6a3d7bf39f FOREIGN KEY (app_type_id) REFERENCES filestore_admin.app_types(id);


--
-- Name: fk_rails_6a971dc818; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.users
    ADD CONSTRAINT fk_rails_6a971dc818 FOREIGN KEY (app_type_id) REFERENCES filestore_admin.app_types(id);


--
-- Name: fk_rails_6de4fd560d; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.protocols
    ADD CONSTRAINT fk_rails_6de4fd560d FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_6e050927c2; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.tracker_history
    ADD CONSTRAINT fk_rails_6e050927c2 FOREIGN KEY (tracker_id) REFERENCES filestore_admin.trackers(id);


--
-- Name: fk_rails_70c17e88fd; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.accuracy_scores
    ADD CONSTRAINT fk_rails_70c17e88fd FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_7218113eac; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.external_identifiers
    ADD CONSTRAINT fk_rails_7218113eac FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_776e17eafd; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_filters
    ADD CONSTRAINT fk_rails_776e17eafd FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_7c10a99849; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.sub_processes
    ADD CONSTRAINT fk_rails_7c10a99849 FOREIGN KEY (protocol_id) REFERENCES filestore_admin.protocols(id);


--
-- Name: fk_rails_8108e25f83; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_access_controls
    ADD CONSTRAINT fk_rails_8108e25f83 FOREIGN KEY (app_type_id) REFERENCES filestore_admin.app_types(id);


--
-- Name: fk_rails_83aa075398; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.tracker_history
    ADD CONSTRAINT fk_rails_83aa075398 FOREIGN KEY (master_id) REFERENCES filestore_admin.masters(id);


--
-- Name: fk_rails_8be93bcf4b; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.app_types
    ADD CONSTRAINT fk_rails_8be93bcf4b FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_9513fd1c35; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.tracker_history
    ADD CONSTRAINT fk_rails_9513fd1c35 FOREIGN KEY (sub_process_id) REFERENCES filestore_admin.sub_processes(id);


--
-- Name: fk_rails_9e92bdfe65; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.tracker_history
    ADD CONSTRAINT fk_rails_9e92bdfe65 FOREIGN KEY (protocol_event_id) REFERENCES filestore_admin.protocol_events(id);


--
-- Name: fk_rails_9f5797d684; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.tracker_history
    ADD CONSTRAINT fk_rails_9f5797d684 FOREIGN KEY (protocol_id) REFERENCES filestore_admin.protocols(id);


--
-- Name: fk_rails_a4eb981c4a; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.model_references
    ADD CONSTRAINT fk_rails_a4eb981c4a FOREIGN KEY (from_record_master_id) REFERENCES filestore_admin.masters(id);


--
-- Name: fk_rails_af2f6ffc55; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_history
    ADD CONSTRAINT fk_rails_af2f6ffc55 FOREIGN KEY (app_type_id) REFERENCES filestore_admin.app_types(id);


--
-- Name: fk_rails_b0a6220067; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.colleges
    ADD CONSTRAINT fk_rails_b0a6220067 FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_b138baacff; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.reports
    ADD CONSTRAINT fk_rails_b138baacff FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_b1e2154c26; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.imports
    ADD CONSTRAINT fk_rails_b1e2154c26 FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_b345649dfe; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_roles
    ADD CONSTRAINT fk_rails_b345649dfe FOREIGN KEY (app_type_id) REFERENCES filestore_admin.app_types(id);


--
-- Name: fk_rails_b822840dc1; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.trackers
    ADD CONSTRAINT fk_rails_b822840dc1 FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_bb6af37155; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.trackers
    ADD CONSTRAINT fk_rails_bb6af37155 FOREIGN KEY (protocol_event_id) REFERENCES filestore_admin.protocol_events(id);


--
-- Name: fk_rails_bdb308087e; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_uploads
    ADD CONSTRAINT fk_rails_bdb308087e FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_c2d5bb8930; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.item_flags
    ADD CONSTRAINT fk_rails_c2d5bb8930 FOREIGN KEY (item_flag_name_id) REFERENCES filestore_admin.item_flag_names(id);


--
-- Name: fk_rails_c55341c576; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.tracker_history
    ADD CONSTRAINT fk_rails_c55341c576 FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_c720bf523c; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.exception_logs
    ADD CONSTRAINT fk_rails_c720bf523c FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_c94bae872a; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_action_logs
    ADD CONSTRAINT fk_rails_c94bae872a FOREIGN KEY (app_type_id) REFERENCES filestore_admin.app_types(id);



--
-- Name: fk_rails_cd756b42dd; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_downloads
    ADD CONSTRAINT fk_rails_cd756b42dd FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_cfc9dc539f; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_action_logs
    ADD CONSTRAINT fk_rails_cfc9dc539f FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_d3566ee56d; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.message_notifications
    ADD CONSTRAINT fk_rails_d3566ee56d FOREIGN KEY (app_type_id) REFERENCES filestore_admin.app_types(id);


--
-- Name: fk_rails_dce5169cfd; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.item_flags
    ADD CONSTRAINT fk_rails_dce5169cfd FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_deec8fcb38; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.dynamic_models
    ADD CONSTRAINT fk_rails_deec8fcb38 FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_e01d928507; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_containers
    ADD CONSTRAINT fk_rails_e01d928507 FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_rails_e410af4010; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.page_layouts
    ADD CONSTRAINT fk_rails_e410af4010 FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_ebf3863277; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.external_links
    ADD CONSTRAINT fk_rails_ebf3863277 FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_ecfa3cb151; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_archived_files
    ADD CONSTRAINT fk_rails_ecfa3cb151 FOREIGN KEY (nfs_store_container_id) REFERENCES filestore_admin.nfs_store_containers(id);


--
-- Name: fk_rails_f0ac516fff; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.app_configurations
    ADD CONSTRAINT fk_rails_f0ac516fff FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_f547361daa; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.nfs_store_filters
    ADD CONSTRAINT fk_rails_f547361daa FOREIGN KEY (app_type_id) REFERENCES filestore_admin.app_types(id);


--
-- Name: fk_rails_f62500107f; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.general_selections
    ADD CONSTRAINT fk_rails_f62500107f FOREIGN KEY (admin_id) REFERENCES filestore_admin.admins(id);


--
-- Name: fk_rails_fa6dbd15de; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.message_notifications
    ADD CONSTRAINT fk_rails_fa6dbd15de FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: fk_report_history_reports; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.report_history
    ADD CONSTRAINT fk_report_history_reports FOREIGN KEY (report_id) REFERENCES filestore_admin.reports(id);


--
-- Name: fk_sub_process_history_sub_processes; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.sub_process_history
    ADD CONSTRAINT fk_sub_process_history_sub_processes FOREIGN KEY (sub_process_id) REFERENCES filestore_admin.sub_processes(id);


--
-- Name: fk_user_authorization_history_user_authorizations; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_authorization_history
    ADD CONSTRAINT fk_user_authorization_history_user_authorizations FOREIGN KEY (user_authorization_id) REFERENCES filestore_admin.user_authorizations(id);


--
-- Name: fk_user_history_users; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.user_history
    ADD CONSTRAINT fk_user_history_users FOREIGN KEY (user_id) REFERENCES filestore_admin.users(id);


--
-- Name: unique_master_protocol_tracker_id; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.tracker_history
    ADD CONSTRAINT unique_master_protocol_tracker_id FOREIGN KEY (master_id, protocol_id, tracker_id) REFERENCES filestore_admin.trackers(master_id, protocol_id, id);


--
-- Name: valid_protocol_sub_process; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.trackers
    ADD CONSTRAINT valid_protocol_sub_process FOREIGN KEY (protocol_id, sub_process_id) REFERENCES filestore_admin.sub_processes(protocol_id, id) MATCH FULL;


--
-- Name: valid_protocol_sub_process; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.tracker_history
    ADD CONSTRAINT valid_protocol_sub_process FOREIGN KEY (protocol_id, sub_process_id) REFERENCES filestore_admin.sub_processes(protocol_id, id) MATCH FULL;


--
-- Name: valid_sub_process_event; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.trackers
    ADD CONSTRAINT valid_sub_process_event FOREIGN KEY (sub_process_id, protocol_event_id) REFERENCES filestore_admin.protocol_events(sub_process_id, id);


--
-- Name: valid_sub_process_event; Type: FK CONSTRAINT; Schema: filestore_admin; Owner: -
--

ALTER TABLE ONLY filestore_admin.tracker_history
    ADD CONSTRAINT valid_sub_process_event FOREIGN KEY (sub_process_id, protocol_event_id) REFERENCES filestore_admin.protocol_events(sub_process_id, id);


--
-- PostgreSQL database dump complete
--

SET search_path TO filestore_admin;

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

INSERT INTO schema_migrations (version) VALUES ('20151216102328');

INSERT INTO schema_migrations (version) VALUES ('20151218203119');

INSERT INTO schema_migrations (version) VALUES ('20160210200918');

INSERT INTO schema_migrations (version) VALUES ('20160210200919');

INSERT INTO schema_migrations (version) VALUES ('20170823145313');

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

INSERT INTO schema_migrations (version) VALUES ('20180228145731');

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

INSERT INTO schema_migrations (version) VALUES ('20180814142112');

INSERT INTO schema_migrations (version) VALUES ('20180814142559');

INSERT INTO schema_migrations (version) VALUES ('20180814142560');

INSERT INTO schema_migrations (version) VALUES ('20180814142561');

INSERT INTO schema_migrations (version) VALUES ('20180814142562');

INSERT INTO schema_migrations (version) VALUES ('20180814142924');

INSERT INTO schema_migrations (version) VALUES ('20180814180843');

INSERT INTO schema_migrations (version) VALUES ('20180815104221');

INSERT INTO schema_migrations (version) VALUES ('20180817114138');

INSERT INTO schema_migrations (version) VALUES ('20180817114157');

INSERT INTO schema_migrations (version) VALUES ('20180818133205');

INSERT INTO schema_migrations (version) VALUES ('20180821123717');

INSERT INTO schema_migrations (version) VALUES ('20180822085118');

INSERT INTO schema_migrations (version) VALUES ('20180822093147');

INSERT INTO schema_migrations (version) VALUES ('20180830144523');

INSERT INTO schema_migrations (version) VALUES ('20180831132605');

INSERT INTO schema_migrations (version) VALUES ('20180911153518');

INSERT INTO schema_migrations (version) VALUES ('20180913142103');

INSERT INTO schema_migrations (version) VALUES ('20180924153547');

INSERT INTO schema_migrations (version) VALUES ('20181002142656');

INSERT INTO schema_migrations (version) VALUES ('20181002165822');

INSERT INTO schema_migrations (version) VALUES ('20181003182428');

INSERT INTO schema_migrations (version) VALUES ('20181004113953');

INSERT INTO schema_migrations (version) VALUES ('20181008104204');

END;