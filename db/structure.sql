SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: data_requests; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA data_requests;


--
-- Name: dynamic; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA dynamic;


--
-- Name: extra_app; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extra_app;


--
-- Name: ml_app; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ml_app;


--
-- Name: projects; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA projects;


--
-- Name: redcap; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA redcap;


--
-- Name: ref_data; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ref_data;


--
-- Name: study_info; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA study_info;


--
-- Name: viva_ref_info; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA viva_ref_info;


--
-- Name: log_activity_log_data_request_assignments_update(); Type: FUNCTION; Schema: data_requests; Owner: -
--

CREATE FUNCTION data_requests.log_activity_log_data_request_assignments_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO activity_log_data_request_assignment_history (
    master_id,
    data_request_assignment_id,
    created_by_user_id, status, notes, next_step, disabled,
    extra_log_type,
    user_id,
    created_at,
    updated_at,
    activity_log_data_request_assignment_id)
  SELECT
    NEW.master_id,
    NEW.data_request_assignment_id,
    NEW.created_by_user_id, NEW.status, NEW.notes, NEW.next_step, NEW.disabled,
    NEW.extra_log_type,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_data_request_attribs_update(); Type: FUNCTION; Schema: data_requests; Owner: -
--

CREATE FUNCTION data_requests.log_data_request_attribs_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO data_request_attrib_history (
    master_id,
    data_source,
    user_id,
    created_at,
    updated_at,
    data_request_attrib_id)
  SELECT
    NEW.master_id,
    NEW.data_source,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_data_request_initial_reviews_update(); Type: FUNCTION; Schema: data_requests; Owner: -
--

CREATE FUNCTION data_requests.log_data_request_initial_reviews_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO data_request_initial_review_history (
    master_id,
    study_analyst_yes_no, review_notes, next_step, message_notes, review_approved_yes_no, created_by_user_id,
    user_id,
    created_at,
    updated_at,
    data_request_initial_review_id)
  SELECT
    NEW.master_id,
    NEW.study_analyst_yes_no, NEW.review_notes, NEW.next_step, NEW.message_notes, NEW.review_approved_yes_no, NEW.created_by_user_id,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_data_request_messages_update(); Type: FUNCTION; Schema: data_requests; Owner: -
--

CREATE FUNCTION data_requests.log_data_request_messages_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO data_request_message_history (
    master_id,
    message_notes, created_by_user_id,
    user_id,
    created_at,
    updated_at,
    data_request_message_id)
  SELECT
    NEW.master_id,
    NEW.message_notes, NEW.created_by_user_id,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_data_requests_selected_attribs_update(); Type: FUNCTION; Schema: data_requests; Owner: -
--

CREATE FUNCTION data_requests.log_data_requests_selected_attribs_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO data_requests_selected_attrib_history (
    master_id,
    record_id, data, data_request_id, disabled, variable_name, record_type,
    user_id,
    created_at,
    updated_at,
    data_requests_selected_attrib_id)
  SELECT
    NEW.master_id,
    NEW.record_id, NEW.data, NEW.data_request_id, NEW.disabled, NEW.variable_name, NEW.record_type,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_data_requests_update(); Type: FUNCTION; Schema: data_requests; Owner: -
--

CREATE FUNCTION data_requests.log_data_requests_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO data_request_history (
    master_id,
    status, study_analyst_yes_no, others_handling_data, select_pm_contact, other_pm_contact, select_purpose, other_purpose, data_start_date, data_end_date, project_title, request_notes, terms_of_use_yes_no, created_by_user_id,
    user_id,
    created_at,
    updated_at,
    data_request_id)
  SELECT
    NEW.master_id,
    NEW.status, NEW.study_analyst_yes_no, NEW.others_handling_data, NEW.select_pm_contact, NEW.other_pm_contact, NEW.select_purpose, NEW.other_purpose, NEW.data_start_date, NEW.data_end_date, NEW.project_title, NEW.request_notes, NEW.terms_of_use_yes_no, NEW.created_by_user_id,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_user_profiile_details_update(); Type: FUNCTION; Schema: data_requests; Owner: -
--

CREATE FUNCTION data_requests.log_user_profiile_details_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO user_profiile_detail_history (
    
    notes, user_id,
    user_id,
    created_at,
    updated_at,
    user_profiile_detail_id)
  SELECT
    
    NEW.notes, NEW.user_id,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_user_profile_academic_details_update(); Type: FUNCTION; Schema: data_requests; Owner: -
--

CREATE FUNCTION data_requests.log_user_profile_academic_details_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO user_profile_academic_detail_history (
    
    primary_affiliation, position_title, start_year, created_by_user_id,
    user_id,
    created_at,
    updated_at,
    user_profile_academic_detail_id)
  SELECT
    
    NEW.primary_affiliation, NEW.position_title, NEW.start_year, NEW.created_by_user_id,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_user_profile_details_update(); Type: FUNCTION; Schema: data_requests; Owner: -
--

CREATE FUNCTION data_requests.log_user_profile_details_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO user_profile_detail_history (
    
    title, notes, created_by_user_id,
    user_id,
    created_at,
    updated_at,
    user_profile_detail_id)
  SELECT
    
    NEW.title, NEW.notes, NEW.created_by_user_id,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_grit_assignments_update(); Type: FUNCTION; Schema: extra_app; Owner: -
--

CREATE FUNCTION extra_app.log_grit_assignments_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO grit_assignment_history (
    master_id,
    grit_id,
    user_id,
    admin_id,
    created_at,
    updated_at,
    grit_assignment_table_id)
  SELECT
    NEW.master_id,
    NEW.grit_id,
    NEW.user_id,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_pitt_bhi_assignments_update(); Type: FUNCTION; Schema: extra_app; Owner: -
--

CREATE FUNCTION extra_app.log_pitt_bhi_assignments_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO pitt_bhi_assignment_history (
    master_id,
    pitt_bhi_id,
    user_id,
    admin_id,
    created_at,
    updated_at,
    pitt_bhi_assignment_table_id)
  SELECT
    NEW.master_id,
    NEW.pitt_bhi_id,
    NEW.user_id,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_sleep_assignments_update(); Type: FUNCTION; Schema: extra_app; Owner: -
--

CREATE FUNCTION extra_app.log_sleep_assignments_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO sleep_assignment_history (
    master_id,
    sleep_id,
    user_id,
    admin_id,
    created_at,
    updated_at,
    sleep_assignment_table_id)
  SELECT
    NEW.master_id,
    NEW.sleep_id,
    NEW.user_id,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: add_study_update_entry(integer, character varying, character varying, date, character varying, integer, integer, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.add_study_update_entry(master_id integer, update_type character varying, update_name character varying, event_date date, update_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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

CREATE FUNCTION ml_app.add_tracker_entry_by_name(master_id integer, protocol_name character varying, sub_process_name character varying, protocol_event_name character varying, set_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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

CREATE FUNCTION ml_app.add_tracker_entry_by_name(master_id integer, protocol_name character varying, sub_process_name character varying, protocol_event_name character varying, event_date date, set_notes character varying, user_id integer, item_id integer, item_type character varying) RETURNS integer
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

CREATE FUNCTION ml_app.assign_sage_ids_to_players() RETURNS record
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
-- Name: create_message_notification_email(character varying, character varying, character varying, json, character varying[], character varying, timestamp without time zone); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_message_notification_email(layout_template_name character varying, content_template_name character varying, subject character varying, data json, recipient_emails character varying[], from_user_email character varying, run_at timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS integer
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
-- Name: create_message_notification_email(integer, integer, integer, character varying, integer, integer[], character varying, character varying, character varying, timestamp without time zone); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_message_notification_email(app_type_id integer, master_id integer, item_id integer, item_type character varying, user_id integer, recipient_user_ids integer[], layout_template_name character varying, content_template_name character varying, subject character varying, run_at timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS integer
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
-- Name: create_message_notification_job(integer, timestamp without time zone); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_message_notification_job(message_notification_id integer, run_at timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS integer
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
-- Name: current_user_id(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.current_user_id() RETURNS integer
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
-- Name: datadic_choice_history_upd(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.datadic_choice_history_upd() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO datadic_choice_history (
    source_name, source_type, form_name, field_name, value, label, redcap_data_dictionary_id,
    disabled,
    admin_id,
    created_at,
    updated_at,
    datadic_choice_id)
  SELECT
    NEW.source_name, NEW.source_type, NEW.form_name, NEW.field_name, NEW.value, NEW.label, NEW.redcap_data_dictionary_id,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: datadic_variable_history_upd(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.datadic_variable_history_upd() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO datadic_variable_history (
    study, source_name, source_type, domain, form_name, variable_name, variable_type, presentation_type, label, label_note, annotation, is_required, valid_type, valid_min, valid_max, multi_valid_choices, is_identifier, is_derived_var, multi_derived_from_id, doc_url, target_type, owner_email, classification, other_classification, multi_timepoints, equivalent_to_id, storage_type, db_or_fs, schema_or_path, table_or_file, storage_varname, redcap_data_dictionary_id, position, section_id, sub_section_id, title,
    disabled,
    admin_id,
    created_at,
    updated_at,
    datadic_variable_id)
  SELECT
    NEW.study, NEW.source_name, NEW.source_type, NEW.domain, NEW.form_name, NEW.variable_name, NEW.variable_type, NEW.presentation_type, NEW.label, NEW.label_note, NEW.annotation, NEW.is_required, NEW.valid_type, NEW.valid_min, NEW.valid_max, NEW.multi_valid_choices, NEW.is_identifier, NEW.is_derived_var, NEW.multi_derived_from_id, NEW.doc_url, NEW.target_type, NEW.owner_email, NEW.classification, NEW.other_classification, NEW.multi_timepoints, NEW.equivalent_to_id, NEW.storage_type, NEW.db_or_fs, NEW.schema_or_path, NEW.table_or_file, NEW.storage_varname, NEW.redcap_data_dictionary_id, NEW.position, NEW.section_id, NEW.sub_section_id, NEW.title,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: nfs_store_archived_files; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_archived_files (
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
-- Name: nfs_store_stored_files; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_stored_files (
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
-- Name: filestore_report_file_path(ml_app.nfs_store_stored_files, ml_app.nfs_store_archived_files); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.filestore_report_file_path(sf ml_app.nfs_store_stored_files, af ml_app.nfs_store_archived_files) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    BEGIN

      return CASE WHEN af.id IS NOT NULL THEN
        coalesce(sf.path, '') || '/' || sf.file_name || '/' || af.path
        ELSE sf.path
      END;

	END;
$$;


--
-- Name: filestore_report_full_file_path(ml_app.nfs_store_stored_files, ml_app.nfs_store_archived_files); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.filestore_report_full_file_path(sf ml_app.nfs_store_stored_files, af ml_app.nfs_store_archived_files) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    BEGIN

      return CASE WHEN af.id IS NOT NULL THEN
        coalesce(sf.path, '') || '/' || sf.file_name || '/' || af.path || '/' || af.file_name
        ELSE coalesce(sf.path, '') || '/' || sf.file_name
      END;

	END;
$$;


--
-- Name: filestore_report_perform_action(integer, character varying, integer, ml_app.nfs_store_stored_files, ml_app.nfs_store_archived_files); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.filestore_report_perform_action(cid integer, altype character varying, alid integer, sf ml_app.nfs_store_stored_files, af ml_app.nfs_store_archived_files) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
	DECLARE
        jo jsonb;
        rt varchar;
        fn varchar;
        alt varchar;
    BEGIN

        rt := '"' || (CASE WHEN af.id IS NOT NULL THEN 'archived_file' ELSE 'stored_file' END) || '"';
        fn := '"' || (CASE WHEN af.id IS NOT NULL THEN af.file_name ELSE sf.file_name END) || '"';
		alt := '"' || altype || '"';
        jo := '{}';

        jo := jsonb_set(jo, '{perform_action}', '"/nfs_store/downloads/!container_id"');
        jo := jsonb_set(jo, '{container_id}', cid::varchar::jsonb);
        jo := jsonb_set(jo, '{download_id}', coalesce(af.id, sf.id)::varchar::jsonb);
        jo := jsonb_set(jo, '{activity_log_type}', alt::jsonb);
        jo := jsonb_set(jo, '{activity_log_id}', alid::varchar::jsonb);
        jo := jsonb_set(jo, '{retrieval_type}', rt::jsonb );
        jo := jsonb_set(jo, '{label}', fn::jsonb);

        return jo;

	END;
$$;


--
-- Name: filestore_report_select_fields(integer, character varying, integer, integer, integer); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.filestore_report_select_fields(cid integer, altype character varying, alid integer, sfid integer, afid integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
	DECLARE
        jo jsonb;
        joid jsonb;
        rt varchar;
        alt varchar;
    BEGIN

    	rt := '"' || CASE WHEN afid IS NOT NULL THEN 'archived_file' ELSE 'stored_file' END || '"';
    	alt := '"' || altype || '"';

        joid := '{}'::jsonb;
        joid := jsonb_set(joid, '{id}', coalesce(afid, sfid)::varchar::jsonb);
        joid := jsonb_set(joid, '{retrieval_type}', rt::jsonb );
        joid := jsonb_set(joid, '{container_id}', cid::varchar::jsonb);
        joid := jsonb_set(joid, '{activity_log_type}', alt::jsonb);
        joid := jsonb_set(joid, '{activity_log_id}', alid::varchar::jsonb);


    	jo := '{}'::jsonb;
  		jo := jsonb_set(jo, '{field_name}', '"nfs_store_download[selected_items][]"');
    	jo := jsonb_set(jo, '{value}', joid);
    	return jo;

	END;
$$;


--
-- Name: format_update_notes(character varying, character varying, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.format_update_notes(field_name character varying, old_val character varying, new_val character varying) RETURNS character varying
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

CREATE FUNCTION ml_app.handle_address_update() RETURNS trigger
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

CREATE FUNCTION ml_app.handle_delete() RETURNS trigger
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

CREATE FUNCTION ml_app.handle_player_contact_update() RETURNS trigger
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

CREATE FUNCTION ml_app.handle_player_info_before_update() RETURNS trigger
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

CREATE FUNCTION ml_app.handle_rc_cis_update() RETURNS trigger
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

CREATE FUNCTION ml_app.handle_tracker_history_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_accuracy_score_update() RETURNS trigger
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
-- Name: log_activity_log_player_contact_phone_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_player_contact_phone_update() RETURNS trigger
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
-- Name: log_activity_log_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_update() RETURNS trigger
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
                blank_log_field_list,
                blank_log_name,
                extra_log_types,
                hide_item_list_panel,
                main_log_name,
                process_name,
                table_name,
                category,
                schema_name
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
                NEW.blank_log_field_list,
                NEW.blank_log_name,
                NEW.extra_log_types,
                NEW.hide_item_list_panel,
                NEW.main_log_name,
                NEW.process_name,
                NEW.table_name,
                NEW.category,
                NEW.schema_name
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_address_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_address_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_admin_update() RETURNS trigger
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
        disabled,
        encrypted_otp_secret,
        encrypted_otp_secret_iv,
        encrypted_otp_secret_salt,
        consumed_timestep,
        otp_required_for_login,
        reset_password_sent_at,
        password_updated_at,
        updated_by_admin_id

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
        NEW.disabled,
        NEW.encrypted_otp_secret,
        NEW.encrypted_otp_secret_iv,
        NEW.encrypted_otp_secret_salt,
        NEW.consumed_timestep,
        NEW.otp_required_for_login,
        NEW.reset_password_sent_at,
        NEW.password_updated_at,
        NEW.admin_id
        ;
        RETURN NEW;
    END;
    $$;


--
-- Name: log_app_configuration_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_app_configuration_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO app_configuration_history
                  (
                      name,
                      value,
                      app_type_id,
                      user_id,
                      role_name,
                      admin_id,
                      disabled,
                      created_at,
                      updated_at,
                      app_configuration_id
                      )
                  SELECT
                      NEW.name,
                      NEW.value,
                      NEW.app_type_id,
                      NEW.user_id,
                      NEW.role_name,
                      NEW.admin_id,
                      NEW.disabled,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_app_type_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_app_type_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
             BEGIN
                 INSERT INTO app_type_history
                 (
                     name,
                     label,
                     admin_id,
                     disabled,
                     created_at,
                     updated_at,
                     app_type_id
                     )
                 SELECT
                     NEW.name,
                     NEW.label,
                     NEW.admin_id,
                     NEW.disabled,
                     NEW.created_at,
                     NEW.updated_at,
                     NEW.id
                 ;
                 RETURN NEW;
             END;
         $$;


--
-- Name: log_college_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_college_update() RETURNS trigger
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
-- Name: log_config_library_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_config_library_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO config_library_history
            (
                    config_library_id,
                    category,
                    name,
                    options,
                    format,
                    disabled,
                    admin_id,
                    updated_at,
                    created_at
                )
            SELECT
                NEW.id,
                NEW.category,
                NEW.name,
                NEW.options,
                NEW.format,
                NEW.disabled,
                NEW.admin_id,
                NEW.updated_at,
                NEW.created_at
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_dynamic_model_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_dynamic_model_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            BEGIN
                INSERT INTO dynamic_model_history
                (
                    name,
                    table_name,
                    schema_name,
                    primary_key_name,
                    foreign_key_name,
                    description,
                    position,
                    category,
                    table_key_name,
                    field_list,
                    result_order,
                    options,
                    admin_id,
                    disabled,
                    created_at,
                    updated_at,
                    dynamic_model_id
                    )
                SELECT
                    NEW.name,
                    NEW.table_name,
                    NEW.schema_name,
                    NEW.primary_key_name,
                    NEW.foreign_key_name,
                    NEW.description,
                    NEW.position,
                    NEW.category,
                    NEW.table_key_name,
                    NEW.field_list,
                    NEW.result_order,
                    NEW.options,
                    NEW.admin_id,
                    NEW.disabled,
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

CREATE FUNCTION ml_app.log_external_identifier_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
          INSERT INTO external_identifier_history
          (
              name,
              label,
              external_id_attribute,
              external_id_view_formatter,
              external_id_edit_pattern,
              prevent_edit,
              pregenerate_ids,
              min_id,
              max_id,
              alphanumeric,
              extra_fields,
              admin_id,
              disabled,
              created_at,
              updated_at,
              external_identifier_id,
              schema_name,
              options
              )
          SELECT
              NEW.name,
              NEW.label,
              NEW.external_id_attribute,
              NEW.external_id_view_formatter,
              NEW.external_id_edit_pattern,
              NEW.prevent_edit,
              NEW.pregenerate_ids,
              NEW.min_id,
              NEW.max_id,
              NEW.alphanumeric,
              NEW.extra_fields,
              NEW.admin_id,
              NEW.disabled,
              NEW.created_at,
              NEW.updated_at,
              NEW.id,
              NEW.schema_name,
              NEW.options
          ;
          RETURN NEW;
      END;
  $$;


--
-- Name: log_external_link_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_external_link_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_general_selection_update() RETURNS trigger
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
-- Name: log_item_flag_name_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_item_flag_name_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_item_flag_update() RETURNS trigger
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
-- Name: log_message_template_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_message_template_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                  BEGIN
                      INSERT INTO message_template_history
                      (
                          name,
                          template_type,
                          message_type,
                          template,
                          category,
                          admin_id,
                          disabled,
                          created_at,
                          updated_at,
                          message_template_id
                          )
                      SELECT
                          NEW.name,
                          NEW.template_type,
                          NEW.message_type,
                          NEW.template,
                          NEW.category,
                          NEW.admin_id,
                          NEW.disabled,
                          NEW.created_at,
                          NEW.updated_at,
                          NEW.id
                      ;
                      RETURN NEW;
                  END;
              $$;


--
-- Name: log_nfs_store_archived_file_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_nfs_store_archived_file_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO nfs_store_archived_file_history
            (
                file_hash,
                file_name,
                content_type,
                archive_file,
                path,
                file_size,
                file_updated_at,
                nfs_store_container_id,
                title,
                description,
                file_metadata,
                nfs_store_stored_file_id,
                user_id,
                created_at,
                updated_at,
                nfs_store_archived_file_id
                )
            SELECT
                NEW.file_hash,
                NEW.file_name,
                NEW.content_type,
                NEW.archive_file,
                NEW.path,
                NEW.file_size,
                NEW.file_updated_at,
                NEW.nfs_store_container_id,
                NEW.title,
                NEW.description,
                NEW.file_metadata,
                NEW.nfs_store_stored_file_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_nfs_store_container_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_nfs_store_container_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO nfs_store_container_history
            (
                master_id,
                name,
                app_type_id,
                orig_nfs_store_container_id,
                user_id,
                created_at,
                updated_at,
                nfs_store_container_id
                )
            SELECT
                NEW.master_id,
                NEW.name,
                NEW.app_type_id,
                NEW.nfs_store_container_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_nfs_store_filter_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_nfs_store_filter_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO nfs_store_filter_history
            (
                app_type_id,
                role_name,
                user_id,
                resource_name,
                filter,
                description,
                admin_id,
                disabled,
                created_at,
                updated_at,
                nfs_store_filter_id
                )
            SELECT
                NEW.app_type_id,
                NEW.role_name,
                NEW.user_id,
                NEW.resource_name,
                NEW.filter,
                NEW.description,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_nfs_store_stored_file_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_nfs_store_stored_file_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO nfs_store_stored_file_history
            (
                file_hash,
                file_name,
                content_type,
                path,
                file_size,
                file_updated_at,
                nfs_store_container_id,
                title,
                description,
                file_metadata,
                last_process_name_run,
                user_id,
                created_at,
                updated_at,
                nfs_store_stored_file_id
                )
            SELECT
                NEW.file_hash,
                NEW.file_name,
                NEW.content_type,
                NEW.path,
                NEW.file_size,
                NEW.file_updated_at,
                NEW.nfs_store_container_id,
                NEW.title,
                NEW.description,
                NEW.file_metadata,
                NEW.last_process_name_run,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_page_layout_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_page_layout_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
              INSERT INTO page_layout_history
              (
                      page_layout_id,
                      app_type_id,
                      layout_name,
                      panel_name,
                      panel_label,
                      panel_position,
                      options,
                      disabled,
                      admin_id,
                      created_at,
                      updated_at,
                      description
                  )
              SELECT
                  NEW.id,
                  NEW.app_type_id,
                  NEW.layout_name,
                  NEW.panel_name,
                  NEW.panel_label,
                  NEW.panel_position,
                  NEW.options,
                  NEW.disabled,
                  NEW.admin_id,
                  NEW.created_at,
                  NEW.updated_at,
                  NEW.description
              ;
              RETURN NEW;
          END;
      $$;


--
-- Name: log_player_contact_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_player_contact_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_player_info_update() RETURNS trigger
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


--
-- Name: log_protocol_event_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_protocol_event_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_protocol_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_report_update() RETURNS trigger
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
                    item_type,
                    short_name,
                    options
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
                NEW.item_type,
                NEW.short_name,
                NEW.options
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_scantron_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_scantron_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_sub_process_update() RETURNS trigger
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
-- Name: log_tracker_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_tracker_update() RETURNS trigger
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
-- Name: log_user_access_control_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_user_access_control_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_access_control_history
            (
                user_id,
                resource_type,
                resource_name,
                options,
                access,
                app_type_id,
                role_name,
                admin_id,
                disabled,
                created_at,
                updated_at,
                user_access_control_id
                )
            SELECT
                NEW.user_id,
                NEW.resource_type,
                NEW.resource_name,
                NEW.options,
                NEW.access,
                NEW.app_type_id,
                NEW.role_name,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_user_authorization_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_user_authorization_update() RETURNS trigger
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
-- Name: log_user_role_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_user_role_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_role_history
            (
                app_type_id,
                role_name,
                user_id,
                admin_id,
                disabled,
                created_at,
                updated_at,
                user_role_id
                )
            SELECT
                NEW.app_type_id,
                NEW.role_name,
                NEW.user_id,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_user_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_user_update() RETURNS trigger
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
      app_type_id,
      authentication_token,
      encrypted_otp_secret,
      encrypted_otp_secret_iv,
      encrypted_otp_secret_salt,
      consumed_timestep,
      otp_required_for_login,
      password_updated_at,
      first_name,
      last_name,
      confirmation_token,
      confirmed_at,
      confirmation_sent_at
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
    NEW.app_type_id,
    NEW.authentication_token,
    NEW.encrypted_otp_secret,
    NEW.encrypted_otp_secret_iv,
    NEW.encrypted_otp_secret_salt,
    NEW.consumed_timestep,
    NEW.otp_required_for_login,
    NEW.password_updated_at,
    NEW.first_name,
    NEW.last_name,
    NEW.confirmation_token,
    NEW.confirmed_at,
    NEW.confirmation_sent_at
  ;
  RETURN NEW;
  END;
  $$;


--
-- Name: redcap_data_dictionary_history_upd(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.redcap_data_dictionary_history_upd() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO redcap_data_dictionary_history (
    redcap_project_admin_id, field_count, captured_metadata,
    disabled,
    admin_id,
    created_at,
    updated_at,
    redcap_data_dictionary_id)
  SELECT
    NEW.redcap_project_admin_id, NEW.field_count, NEW.captured_metadata,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: redcap_project_admin_history_upd(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.redcap_project_admin_history_upd() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO redcap_project_admin_history (
    name, api_key, server_url, captured_project_info, study, transfer_mode, frequency, status, post_transfer_pipeline, notes, dynamic_model_table,
    disabled,
    admin_id,
    created_at,
    updated_at,
    redcap_project_admin_id)
  SELECT
    NEW.name, NEW.api_key, NEW.server_url, NEW.captured_project_info, NEW.study, NEW.transfer_mode, NEW.frequency, NEW.status, NEW.post_transfer_pipeline, NEW.notes, NEW.dynamic_model_table,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: role_description_history_upd(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.role_description_history_upd() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO role_description_history (
    app_type_id, role_name, role_template, name, description,
    disabled,
    admin_id,
    created_at,
    updated_at,
    role_description_id)
  SELECT
    NEW.app_type_id, NEW.role_name, NEW.role_template, NEW.name, NEW.description,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: tracker_upsert(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.tracker_upsert() RETURNS trigger
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

CREATE FUNCTION ml_app.update_address_ranks(set_master_id integer) RETURNS integer
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

CREATE FUNCTION ml_app.update_master_with_player_info() RETURNS trigger
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

CREATE FUNCTION ml_app.update_master_with_pro_info() RETURNS trigger
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

CREATE FUNCTION ml_app.update_player_contact_ranks(set_master_id integer, set_rec_type character varying) RETURNS integer
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


--
-- Name: user_description_history_upd(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.user_description_history_upd() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO user_description_history (
    app_type_id, role_name, role_template, name, description,
    disabled,
    admin_id,
    created_at,
    updated_at,
    user_description_id)
  SELECT
    NEW.app_type_id, NEW.role_name, NEW.role_template, NEW.name, NEW.description,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_datadic_variables_update(); Type: FUNCTION; Schema: ref_data; Owner: -
--

CREATE FUNCTION ref_data.log_datadic_variables_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO datadic_variable_history (
    
    study, source_name, source_type, domain, form_name, variable_name, variable_type, presentation_type, label, label_note, annotation, is_required, valid_type, valid_min, valid_max, multi_valid_choices, is_identifier, is_derived_var, multi_derived_from_id, doc_url, target_type, owner_email, classification, other_classification, multi_timepoints, equivalent_to_id, storage_type, db_or_fs, schema_or_path, table_or_file, disabled, admin_id, redcap_data_dictionary_id, position, section_id, sub_section_id, title, storage_varname, contributor_type, n_for_timepoints, notes,
    user_id,
    created_at,
    updated_at,
    datadic_variable_id)
  SELECT
    
    NEW.study, NEW.source_name, NEW.source_type, NEW.domain, NEW.form_name, NEW.variable_name, NEW.variable_type, NEW.presentation_type, NEW.label, NEW.label_note, NEW.annotation, NEW.is_required, NEW.valid_type, NEW.valid_min, NEW.valid_max, NEW.multi_valid_choices, NEW.is_identifier, NEW.is_derived_var, NEW.multi_derived_from_id, NEW.doc_url, NEW.target_type, NEW.owner_email, NEW.classification, NEW.other_classification, NEW.multi_timepoints, NEW.equivalent_to_id, NEW.storage_type, NEW.db_or_fs, NEW.schema_or_path, NEW.table_or_file, NEW.disabled, NEW.admin_id, NEW.redcap_data_dictionary_id, NEW.position, NEW.section_id, NEW.sub_section_id, NEW.title, NEW.storage_varname, NEW.contributor_type, NEW.n_for_timepoints, NEW.notes,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: redcap_data_collection_instrument_history_upd(); Type: FUNCTION; Schema: ref_data; Owner: -
--

CREATE FUNCTION ref_data.redcap_data_collection_instrument_history_upd() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO redcap_data_collection_instrument_history (
    redcap_project_admin_id, name, label,
    disabled,
    admin_id,
    created_at,
    updated_at,
    redcap_data_collection_instrument_id)
  SELECT
    NEW.redcap_project_admin_id, NEW.name, NEW.label,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: redcap_project_user_history_upd(); Type: FUNCTION; Schema: ref_data; Owner: -
--

CREATE FUNCTION ref_data.redcap_project_user_history_upd() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO redcap_project_user_history (
    redcap_project_admin_id, username, email, expiration,
    disabled,
    admin_id,
    created_at,
    updated_at,
    redcap_project_user_id)
  SELECT
    NEW.redcap_project_admin_id, NEW.username, NEW.email, NEW.expiration,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_activity_log_study_info_parts_update(); Type: FUNCTION; Schema: study_info; Owner: -
--

CREATE FUNCTION study_info.log_activity_log_study_info_parts_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO activity_log_study_info_part_history (
    master_id,
    study_info_part_id,
    title, description, default_layout, slug, tag_select_allow_roles_access, footer, tag_select_page_tags, disabled, position_number, extra_classes, notes,
    extra_log_type,
    user_id,
    created_at,
    updated_at,
    activity_log_study_info_part_id)
  SELECT
    NEW.master_id,
    NEW.study_info_part_id,
    NEW.title, NEW.description, NEW.default_layout, NEW.slug, NEW.tag_select_allow_roles_access, NEW.footer, NEW.tag_select_page_tags, NEW.disabled, NEW.position_number, NEW.extra_classes, NEW.notes,
    NEW.extra_log_type,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_activity_log_view_user_data_user_procs_update(); Type: FUNCTION; Schema: study_info; Owner: -
--

CREATE FUNCTION study_info.log_activity_log_view_user_data_user_procs_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO activity_log_view_user_data_user_proc_history (
    master_id,
    view_user_id,
    is_complete, confirmed_read_terms_yes_no,
    extra_log_type,
    user_id,
    created_at,
    updated_at,
    activity_log_view_user_data_user_proc_id)
  SELECT
    NEW.master_id,
    NEW.view_user_id,
    NEW.is_complete, NEW.confirmed_read_terms_yes_no,
    NEW.extra_log_type,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_study_common_sections_update(); Type: FUNCTION; Schema: study_info; Owner: -
--

CREATE FUNCTION study_info.log_study_common_sections_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO study_common_section_history (
    
    title, content, position_number, block_width, extra_classes,
    user_id,
    created_at,
    updated_at,
    study_common_section_id)
  SELECT
    
    NEW.title, NEW.content, NEW.position_number, NEW.block_width, NEW.extra_classes,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_study_page_sections_update(); Type: FUNCTION; Schema: study_info; Owner: -
--

CREATE FUNCTION study_info.log_study_page_sections_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO study_page_section_history (
    master_id,
    title, content, position_number, block_width, extra_classes, tag_select_allow_roles_access, disabled,
    user_id,
    created_at,
    updated_at,
    study_page_section_id)
  SELECT
    NEW.master_id,
    NEW.title, NEW.content, NEW.position_number, NEW.block_width, NEW.extra_classes, NEW.tag_select_allow_roles_access, NEW.disabled,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_viva2_rcs_update(); Type: FUNCTION; Schema: viva_ref_info; Owner: -
--

CREATE FUNCTION viva_ref_info.log_viva2_rcs_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO viva2_rc_history (
    
    varname, var_label, var_type, restrict_var___0, restrict_var___1, restrict_var___2, restrict_var___3, restrict_var___4, oth_restrict, domain_viva, subdomain___1, subdomain___2, target_of_q, data_source, val_instr, ext_instrument, internal_instrument, doc_yn, doc_link, long_yn, long_timepts___1, long_timepts___2, long_timepts___3, long_timepts___4, long_timepts___5, long_timepts___6, long_timepts___7, long_timepts___8, long_timepts___9, long_timepts___10, long_timepts___11, long_timepts___12, long_timepts___13, long_timepts___14, long_timepts___15, long_timepts___16, long_timepts___17, long_timepts___18, long_timepts___19, long_timepts___20, long_timepts___21, long_timepts___22, long_timepts___23, static_variable_information_complete, event_type, visit_name, visit_time, assay_specimen, assay_type, lab_assay_dataset, form_label_ep, form_version_ep___1, form_version_ep___2, form_version_ep___3, form_version_ep___4, form_version_ep___5, form_version_ep___6, form_version_ep___7, form_version_ep___8, form_label_mp, form_version_mp___1, form_version_mp___2, form_version_mp___3, form_version_mp___4, form_label_del, form_version_del___1, form_version_del___2, form_version_del___3, form_version_del___4, form_version_del___5, form_version_del___6, form_version_del___7, form_label_6m, form_version_6m___1, form_version_6m___2, form_version_6m___3, form_version_6m___4, form_version_6m___5, form_version_6m___6, form_version_6m___7, form_version_6m___8, form_version_6m___9, form_version_6m___10, form_label_1y, form_version_1y___1, form_label_2y, form_version_2y___1, form_label_3y, form_version_3y___1, form_version_3y___2, form_version_3y___3, form_version_3y___4, form_version_3y___5, form_version_3y___6, form_version_3y___7, form_version_3y___8, form_version_3y___9, form_version_3y___10, form_version_3y___11, form_version_3y___12, form_version_3y___13, form_version_3y___14, form_label_4y, form_version_4y___1, form_label_5y, form_version_5y___1, form_label_6y, form_version_6y___1, form_label_7y, form_version_7y___1, form_version_7y___2, form_version_7y___3, form_version_7y___4, form_version_7y___5, form_version_7y___6, form_version_7y___7, form_version_7y___8, form_version_7y___9, form_version_7y___10, form_version_7y___11, form_version_7y___12, form_version_7y___13, form_version_7y___14, form_version_7y___15, form_version_7y___16, form_version_7y___17, form_label_8y, form_version_8y___1, form_label_9y, form_version_9y___1, form_version_9y___2, form_label_10y, form_version_10y___1, form_version_10y___2, form_label_11y, form_version_11y___1, form_version_11y___2, form_label_12y, form_version_12y___1, form_version_12y___2, form_version_12y___3, form_version_12y___4, form_version_12y___5, form_version_12y___6, form_version_12y___7, form_version_12y___8, form_version_12y___9, form_version_12y___10, form_version_12y___11, form_version_12y___12, form_version_12y___13, form_version_12y___14, form_version_12y___15, form_version_12y___16, form_label_14y, form_version_14y___1, form_version_14y___2, form_label_15y, form_version_15y___1, form_version_15y___2, form_label_16y, form_version_16y___1, form_version_16y___2, form_label_mt, form_version_mt, form_label_19y, form_version_19y___1, form_version_19y___2, not_time_specific, var_level, units, model_type, response_options, elig_sample, elig_n, actual_n, an_var, orig_deriv, corr_derived_yn___0, corr_derived_yn___1, der_varname, dervar_explain, orig_varnames, visitspecific_information_complete, redcap_repeat_instrument, redcap_repeat_instance,
    user_id,
    created_at,
    updated_at,
    viva2_rc_id)
  SELECT
    
    NEW.varname, NEW.var_label, NEW.var_type, NEW.restrict_var___0, NEW.restrict_var___1, NEW.restrict_var___2, NEW.restrict_var___3, NEW.restrict_var___4, NEW.oth_restrict, NEW.domain_viva, NEW.subdomain___1, NEW.subdomain___2, NEW.target_of_q, NEW.data_source, NEW.val_instr, NEW.ext_instrument, NEW.internal_instrument, NEW.doc_yn, NEW.doc_link, NEW.long_yn, NEW.long_timepts___1, NEW.long_timepts___2, NEW.long_timepts___3, NEW.long_timepts___4, NEW.long_timepts___5, NEW.long_timepts___6, NEW.long_timepts___7, NEW.long_timepts___8, NEW.long_timepts___9, NEW.long_timepts___10, NEW.long_timepts___11, NEW.long_timepts___12, NEW.long_timepts___13, NEW.long_timepts___14, NEW.long_timepts___15, NEW.long_timepts___16, NEW.long_timepts___17, NEW.long_timepts___18, NEW.long_timepts___19, NEW.long_timepts___20, NEW.long_timepts___21, NEW.long_timepts___22, NEW.long_timepts___23, NEW.static_variable_information_complete, NEW.event_type, NEW.visit_name, NEW.visit_time, NEW.assay_specimen, NEW.assay_type, NEW.lab_assay_dataset, NEW.form_label_ep, NEW.form_version_ep___1, NEW.form_version_ep___2, NEW.form_version_ep___3, NEW.form_version_ep___4, NEW.form_version_ep___5, NEW.form_version_ep___6, NEW.form_version_ep___7, NEW.form_version_ep___8, NEW.form_label_mp, NEW.form_version_mp___1, NEW.form_version_mp___2, NEW.form_version_mp___3, NEW.form_version_mp___4, NEW.form_label_del, NEW.form_version_del___1, NEW.form_version_del___2, NEW.form_version_del___3, NEW.form_version_del___4, NEW.form_version_del___5, NEW.form_version_del___6, NEW.form_version_del___7, NEW.form_label_6m, NEW.form_version_6m___1, NEW.form_version_6m___2, NEW.form_version_6m___3, NEW.form_version_6m___4, NEW.form_version_6m___5, NEW.form_version_6m___6, NEW.form_version_6m___7, NEW.form_version_6m___8, NEW.form_version_6m___9, NEW.form_version_6m___10, NEW.form_label_1y, NEW.form_version_1y___1, NEW.form_label_2y, NEW.form_version_2y___1, NEW.form_label_3y, NEW.form_version_3y___1, NEW.form_version_3y___2, NEW.form_version_3y___3, NEW.form_version_3y___4, NEW.form_version_3y___5, NEW.form_version_3y___6, NEW.form_version_3y___7, NEW.form_version_3y___8, NEW.form_version_3y___9, NEW.form_version_3y___10, NEW.form_version_3y___11, NEW.form_version_3y___12, NEW.form_version_3y___13, NEW.form_version_3y___14, NEW.form_label_4y, NEW.form_version_4y___1, NEW.form_label_5y, NEW.form_version_5y___1, NEW.form_label_6y, NEW.form_version_6y___1, NEW.form_label_7y, NEW.form_version_7y___1, NEW.form_version_7y___2, NEW.form_version_7y___3, NEW.form_version_7y___4, NEW.form_version_7y___5, NEW.form_version_7y___6, NEW.form_version_7y___7, NEW.form_version_7y___8, NEW.form_version_7y___9, NEW.form_version_7y___10, NEW.form_version_7y___11, NEW.form_version_7y___12, NEW.form_version_7y___13, NEW.form_version_7y___14, NEW.form_version_7y___15, NEW.form_version_7y___16, NEW.form_version_7y___17, NEW.form_label_8y, NEW.form_version_8y___1, NEW.form_label_9y, NEW.form_version_9y___1, NEW.form_version_9y___2, NEW.form_label_10y, NEW.form_version_10y___1, NEW.form_version_10y___2, NEW.form_label_11y, NEW.form_version_11y___1, NEW.form_version_11y___2, NEW.form_label_12y, NEW.form_version_12y___1, NEW.form_version_12y___2, NEW.form_version_12y___3, NEW.form_version_12y___4, NEW.form_version_12y___5, NEW.form_version_12y___6, NEW.form_version_12y___7, NEW.form_version_12y___8, NEW.form_version_12y___9, NEW.form_version_12y___10, NEW.form_version_12y___11, NEW.form_version_12y___12, NEW.form_version_12y___13, NEW.form_version_12y___14, NEW.form_version_12y___15, NEW.form_version_12y___16, NEW.form_label_14y, NEW.form_version_14y___1, NEW.form_version_14y___2, NEW.form_label_15y, NEW.form_version_15y___1, NEW.form_version_15y___2, NEW.form_label_16y, NEW.form_version_16y___1, NEW.form_version_16y___2, NEW.form_label_mt, NEW.form_version_mt, NEW.form_label_19y, NEW.form_version_19y___1, NEW.form_version_19y___2, NEW.not_time_specific, NEW.var_level, NEW.units, NEW.model_type, NEW.response_options, NEW.elig_sample, NEW.elig_n, NEW.actual_n, NEW.an_var, NEW.orig_deriv, NEW.corr_derived_yn___0, NEW.corr_derived_yn___1, NEW.der_varname, NEW.dervar_explain, NEW.orig_varnames, NEW.visitspecific_information_complete, NEW.redcap_repeat_instrument, NEW.redcap_repeat_instance,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_viva3_rcs_update(); Type: FUNCTION; Schema: viva_ref_info; Owner: -
--

CREATE FUNCTION viva_ref_info.log_viva3_rcs_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO viva3_rc_history (
    
    varname, var_label, var_type, restrict_var___0, restrict_var___1, restrict_var___2, restrict_var___3, restrict_var___4, oth_restrict, domain_viva, subdomain___1, subdomain___2, target_of_q, data_source, val_instr, ext_instrument, internal_instrument, doc_yn, doc_link, var_level, units, response_options, long_yn, long_timepts___1, long_timepts___2, long_timepts___3, long_timepts___4, long_timepts___5, long_timepts___6, long_timepts___7, long_timepts___8, long_timepts___9, long_timepts___10, long_timepts___11, long_timepts___12, long_timepts___13, long_timepts___14, long_timepts___15, long_timepts___16, long_timepts___17, long_timepts___18, long_timepts___19, long_timepts___20, long_timepts___21, long_timepts___22, long_timepts___23, static_variable_information_complete, event_type, visit_name, visit_time, assay_specimen, assay_type, lab_assay_dataset, form_label_ep, form_version_ep___1, form_version_ep___2, form_version_ep___3, form_version_ep___4, form_version_ep___5, form_version_ep___6, form_version_ep___7, form_version_ep___8, form_label_mp, form_version_mp___1, form_version_mp___2, form_version_mp___3, form_version_mp___4, form_label_del, form_version_del___1, form_version_del___2, form_version_del___3, form_version_del___4, form_version_del___5, form_version_del___6, form_version_del___7, form_label_6m, form_version_6m___1, form_version_6m___2, form_version_6m___3, form_version_6m___4, form_version_6m___5, form_version_6m___6, form_version_6m___7, form_version_6m___8, form_version_6m___9, form_version_6m___10, form_label_1y, form_version_1y___1, form_label_2y, form_version_2y___1, form_label_3y, form_version_3y___1, form_version_3y___2, form_version_3y___3, form_version_3y___4, form_version_3y___5, form_version_3y___6, form_version_3y___7, form_version_3y___8, form_version_3y___9, form_version_3y___10, form_version_3y___11, form_version_3y___12, form_version_3y___13, form_version_3y___14, form_label_4y, form_version_4y___1, form_label_5y, form_version_5y___1, form_label_6y, form_version_6y___1, form_label_7y, form_version_7y___1, form_version_7y___2, form_version_7y___3, form_version_7y___4, form_version_7y___5, form_version_7y___6, form_version_7y___7, form_version_7y___8, form_version_7y___9, form_version_7y___10, form_version_7y___11, form_version_7y___12, form_version_7y___13, form_version_7y___14, form_version_7y___15, form_version_7y___16, form_version_7y___17, form_label_8y, form_version_8y___1, form_label_9y, form_version_9y___1, form_version_9y___2, form_label_10y, form_version_10y___1, form_version_10y___2, form_label_11y, form_version_11y___1, form_version_11y___2, form_label_12y, form_version_12y___1, form_version_12y___2, form_version_12y___3, form_version_12y___4, form_version_12y___5, form_version_12y___6, form_version_12y___7, form_version_12y___8, form_version_12y___9, form_version_12y___10, form_version_12y___11, form_version_12y___12, form_version_12y___13, form_version_12y___14, form_version_12y___15, form_version_12y___16, form_label_14y, form_version_14y___1, form_version_14y___2, form_label_15y, form_version_15y___1, form_version_15y___2, form_label_16y, form_version_16y___1, form_version_16y___2, form_label_mt, form_version_mt, form_label_19y, form_version_19y___1, form_version_19y___2, not_time_specific, model_type, elig_sample, elig_n, actual_n, an_var, orig_deriv, corr_derived_yn___0, corr_derived_yn___1, der_varname, dervar_explain, orig_varnames, visitspecific_information_complete, redcap_repeat_instrument, redcap_repeat_instance,
    user_id,
    created_at,
    updated_at,
    viva3_rc_id)
  SELECT
    
    NEW.varname, NEW.var_label, NEW.var_type, NEW.restrict_var___0, NEW.restrict_var___1, NEW.restrict_var___2, NEW.restrict_var___3, NEW.restrict_var___4, NEW.oth_restrict, NEW.domain_viva, NEW.subdomain___1, NEW.subdomain___2, NEW.target_of_q, NEW.data_source, NEW.val_instr, NEW.ext_instrument, NEW.internal_instrument, NEW.doc_yn, NEW.doc_link, NEW.var_level, NEW.units, NEW.response_options, NEW.long_yn, NEW.long_timepts___1, NEW.long_timepts___2, NEW.long_timepts___3, NEW.long_timepts___4, NEW.long_timepts___5, NEW.long_timepts___6, NEW.long_timepts___7, NEW.long_timepts___8, NEW.long_timepts___9, NEW.long_timepts___10, NEW.long_timepts___11, NEW.long_timepts___12, NEW.long_timepts___13, NEW.long_timepts___14, NEW.long_timepts___15, NEW.long_timepts___16, NEW.long_timepts___17, NEW.long_timepts___18, NEW.long_timepts___19, NEW.long_timepts___20, NEW.long_timepts___21, NEW.long_timepts___22, NEW.long_timepts___23, NEW.static_variable_information_complete, NEW.event_type, NEW.visit_name, NEW.visit_time, NEW.assay_specimen, NEW.assay_type, NEW.lab_assay_dataset, NEW.form_label_ep, NEW.form_version_ep___1, NEW.form_version_ep___2, NEW.form_version_ep___3, NEW.form_version_ep___4, NEW.form_version_ep___5, NEW.form_version_ep___6, NEW.form_version_ep___7, NEW.form_version_ep___8, NEW.form_label_mp, NEW.form_version_mp___1, NEW.form_version_mp___2, NEW.form_version_mp___3, NEW.form_version_mp___4, NEW.form_label_del, NEW.form_version_del___1, NEW.form_version_del___2, NEW.form_version_del___3, NEW.form_version_del___4, NEW.form_version_del___5, NEW.form_version_del___6, NEW.form_version_del___7, NEW.form_label_6m, NEW.form_version_6m___1, NEW.form_version_6m___2, NEW.form_version_6m___3, NEW.form_version_6m___4, NEW.form_version_6m___5, NEW.form_version_6m___6, NEW.form_version_6m___7, NEW.form_version_6m___8, NEW.form_version_6m___9, NEW.form_version_6m___10, NEW.form_label_1y, NEW.form_version_1y___1, NEW.form_label_2y, NEW.form_version_2y___1, NEW.form_label_3y, NEW.form_version_3y___1, NEW.form_version_3y___2, NEW.form_version_3y___3, NEW.form_version_3y___4, NEW.form_version_3y___5, NEW.form_version_3y___6, NEW.form_version_3y___7, NEW.form_version_3y___8, NEW.form_version_3y___9, NEW.form_version_3y___10, NEW.form_version_3y___11, NEW.form_version_3y___12, NEW.form_version_3y___13, NEW.form_version_3y___14, NEW.form_label_4y, NEW.form_version_4y___1, NEW.form_label_5y, NEW.form_version_5y___1, NEW.form_label_6y, NEW.form_version_6y___1, NEW.form_label_7y, NEW.form_version_7y___1, NEW.form_version_7y___2, NEW.form_version_7y___3, NEW.form_version_7y___4, NEW.form_version_7y___5, NEW.form_version_7y___6, NEW.form_version_7y___7, NEW.form_version_7y___8, NEW.form_version_7y___9, NEW.form_version_7y___10, NEW.form_version_7y___11, NEW.form_version_7y___12, NEW.form_version_7y___13, NEW.form_version_7y___14, NEW.form_version_7y___15, NEW.form_version_7y___16, NEW.form_version_7y___17, NEW.form_label_8y, NEW.form_version_8y___1, NEW.form_label_9y, NEW.form_version_9y___1, NEW.form_version_9y___2, NEW.form_label_10y, NEW.form_version_10y___1, NEW.form_version_10y___2, NEW.form_label_11y, NEW.form_version_11y___1, NEW.form_version_11y___2, NEW.form_label_12y, NEW.form_version_12y___1, NEW.form_version_12y___2, NEW.form_version_12y___3, NEW.form_version_12y___4, NEW.form_version_12y___5, NEW.form_version_12y___6, NEW.form_version_12y___7, NEW.form_version_12y___8, NEW.form_version_12y___9, NEW.form_version_12y___10, NEW.form_version_12y___11, NEW.form_version_12y___12, NEW.form_version_12y___13, NEW.form_version_12y___14, NEW.form_version_12y___15, NEW.form_version_12y___16, NEW.form_label_14y, NEW.form_version_14y___1, NEW.form_version_14y___2, NEW.form_label_15y, NEW.form_version_15y___1, NEW.form_version_15y___2, NEW.form_label_16y, NEW.form_version_16y___1, NEW.form_version_16y___2, NEW.form_label_mt, NEW.form_version_mt, NEW.form_label_19y, NEW.form_version_19y___1, NEW.form_version_19y___2, NEW.not_time_specific, NEW.model_type, NEW.elig_sample, NEW.elig_n, NEW.actual_n, NEW.an_var, NEW.orig_deriv, NEW.corr_derived_yn___0, NEW.corr_derived_yn___1, NEW.der_varname, NEW.dervar_explain, NEW.orig_varnames, NEW.visitspecific_information_complete, NEW.redcap_repeat_instrument, NEW.redcap_repeat_instance,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_viva_collection_instruments_update(); Type: FUNCTION; Schema: viva_ref_info; Owner: -
--

CREATE FUNCTION viva_ref_info.log_viva_collection_instruments_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO viva_collection_instrument_history (
    
    name, select_data_source, select_data_target, select_record_id_from_viva_domains, select_record_id_from_viva_timepoints, sample_file, disabled,
    user_id,
    created_at,
    updated_at,
    viva_collection_instrument_id)
  SELECT
    
    NEW.name, NEW.select_data_source, NEW.select_data_target, NEW.select_record_id_from_viva_domains, NEW.select_record_id_from_viva_timepoints, NEW.sample_file, NEW.disabled,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_viva_domains_update(); Type: FUNCTION; Schema: viva_ref_info; Owner: -
--

CREATE FUNCTION viva_ref_info.log_viva_domains_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO viva_domain_history (
    
    select_topic, domain, sub_domain, disabled,
    user_id,
    created_at,
    updated_at,
    viva_domain_id)
  SELECT
    
    NEW.select_topic, NEW.domain, NEW.sub_domain, NEW.disabled,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: log_viva_timepoints_update(); Type: FUNCTION; Schema: viva_ref_info; Owner: -
--

CREATE FUNCTION viva_ref_info.log_viva_timepoints_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO viva_timepoint_history (
    
    name, disabled,
    user_id,
    created_at,
    updated_at,
    viva_timepoint_id)
  SELECT
    
    NEW.name, NEW.disabled,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;


--
-- Name: activity_log_data_request_assignment_history; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.activity_log_data_request_assignment_history (
    id bigint NOT NULL,
    master_id bigint,
    data_request_assignment_id bigint,
    created_by_user_id bigint,
    status character varying,
    notes character varying,
    next_step character varying,
    extra_log_type character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_data_request_assignment_id bigint,
    disabled boolean DEFAULT false
);


--
-- Name: activity_log_data_request_assignment_history_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.activity_log_data_request_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_data_request_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.activity_log_data_request_assignment_history_id_seq OWNED BY data_requests.activity_log_data_request_assignment_history.id;


--
-- Name: activity_log_data_request_assignments; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.activity_log_data_request_assignments (
    id bigint NOT NULL,
    master_id bigint,
    data_request_assignment_id bigint,
    created_by_user_id bigint,
    status character varying,
    notes character varying,
    next_step character varying,
    extra_log_type character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean DEFAULT false
);


--
-- Name: TABLE activity_log_data_request_assignments; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON TABLE data_requests.activity_log_data_request_assignments IS 'Activitylog: Data Request Form';


--
-- Name: activity_log_data_request_assignments_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.activity_log_data_request_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_data_request_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.activity_log_data_request_assignments_id_seq OWNED BY data_requests.activity_log_data_request_assignments.id;


--
-- Name: model_references; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.model_references (
    id integer NOT NULL,
    from_record_type character varying,
    from_record_id integer,
    from_record_master_id integer,
    to_record_type character varying,
    to_record_id integer,
    to_record_master_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean
);


--
-- Name: al_data_request_assignments_from_al_data_request_assignments; Type: VIEW; Schema: data_requests; Owner: -
--

CREATE VIEW data_requests.al_data_request_assignments_from_al_data_request_assignments AS
 SELECT dest.id,
    dest.master_id,
    dest.data_request_assignment_id,
    dest.created_by_user_id,
    dest.status,
    dest.notes,
    dest.next_step,
    dest.extra_log_type,
    dest.user_id,
    dest.created_at,
    dest.updated_at,
    dest.disabled,
    mr.from_record_master_id,
    mr.from_record_type,
    mr.from_record_id,
    mr.id AS model_reference_id,
    'data_requests.activity_log_data_request_assignments'::character varying AS from_table
   FROM (data_requests.activity_log_data_request_assignments dest
     JOIN ml_app.model_references mr ON (((dest.id = mr.to_record_id) AND (dest.master_id = mr.to_record_master_id) AND (NOT COALESCE(mr.disabled, false)) AND ((mr.from_record_type)::text = 'ActivityLog::DataRequestAssignment'::text) AND ((mr.to_record_type)::text = 'ActivityLog::DataRequestAssignment'::text))));


--
-- Name: data_request_assignment_history; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_request_assignment_history (
    id bigint NOT NULL,
    master_id bigint,
    data_request_id bigint,
    user_id bigint,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data_request_assignment_table_id bigint
);


--
-- Name: data_request_assignment_history_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_request_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_request_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_request_assignment_history_id_seq OWNED BY data_requests.data_request_assignment_history.id;


--
-- Name: data_request_assignments; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_request_assignments (
    id bigint NOT NULL,
    master_id bigint,
    data_request_id bigint,
    user_id bigint,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE data_request_assignments; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON TABLE data_requests.data_request_assignments IS 'Externalidentifier: Data Request Assignments';


--
-- Name: data_request_assignments_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_request_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_request_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_request_assignments_id_seq OWNED BY data_requests.data_request_assignments.id;


--
-- Name: data_request_attrib_history; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_request_attrib_history (
    id bigint NOT NULL,
    master_id bigint,
    data_source character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data_request_attrib_id bigint
);


--
-- Name: COLUMN data_request_attrib_history.data_source; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_attrib_history.data_source IS 'Which FPHS study are you requesting data from?';


--
-- Name: data_request_attrib_history_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_request_attrib_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_request_attrib_history_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_request_attrib_history_id_seq OWNED BY data_requests.data_request_attrib_history.id;


--
-- Name: data_request_attribs; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_request_attribs (
    id bigint NOT NULL,
    master_id bigint,
    data_source character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE data_request_attribs; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON TABLE data_requests.data_request_attribs IS 'Dynamicmodel: Requested Data';


--
-- Name: COLUMN data_request_attribs.data_source; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_attribs.data_source IS 'Which FPHS study are you requesting data from?';


--
-- Name: data_request_attribs_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_request_attribs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_request_attribs_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_request_attribs_id_seq OWNED BY data_requests.data_request_attribs.id;


--
-- Name: data_request_history; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_request_history (
    id bigint NOT NULL,
    master_id bigint,
    status character varying,
    project_title character varying,
    select_purpose character varying,
    other_purpose character varying,
    others_handling_data character varying,
    other_pm_contact character varying,
    data_start_date date,
    data_end_date date,
    terms_of_use_yes_no character varying,
    created_by_user_id bigint,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data_request_id bigint,
    request_notes character varying,
    study_analyst_yes_no character varying,
    select_pm_contact character varying
);


--
-- Name: COLUMN data_request_history.project_title; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_history.project_title IS 'Proposal title';


--
-- Name: COLUMN data_request_history.select_purpose; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_history.select_purpose IS 'Purpose of this data request';


--
-- Name: COLUMN data_request_history.other_purpose; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_history.other_purpose IS '*other purpose*: please explain';


--
-- Name: COLUMN data_request_history.others_handling_data; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_history.others_handling_data IS 'Name and title of others who will be handling Project Viva data (one per line)';


--
-- Name: COLUMN data_request_history.other_pm_contact; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_history.other_pm_contact IS 'Project Manager name';


--
-- Name: COLUMN data_request_history.data_start_date; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_history.data_start_date IS 'Planned analysis start date';


--
-- Name: COLUMN data_request_history.data_end_date; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_history.data_end_date IS 'Planned analysis end date';


--
-- Name: COLUMN data_request_history.terms_of_use_yes_no; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_history.terms_of_use_yes_no IS 'I attest that I have read, understood, and accepted the terms of use stated in the data use agreement, or other form of contractual agreement, with the Project Viva.';


--
-- Name: COLUMN data_request_history.request_notes; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_history.request_notes IS '#### Background

Brief description of why this topic is important,
brief summary of literature, and a priori hypothesis

*To include supporting documents or files, complete this form, then
select the Supporting Files section at the end of the form*';


--
-- Name: COLUMN data_request_history.study_analyst_yes_no; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_history.study_analyst_yes_no IS 'Are you an internal Project Viva analyst?';


--
-- Name: COLUMN data_request_history.select_pm_contact; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_history.select_pm_contact IS 'Project Viva Project Manager contact';


--
-- Name: data_request_history_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_request_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_request_history_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_request_history_id_seq OWNED BY data_requests.data_request_history.id;


--
-- Name: data_request_initial_review_history; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_request_initial_review_history (
    id bigint NOT NULL,
    master_id bigint,
    message_notes character varying,
    next_step character varying,
    review_approved_yes_no character varying,
    created_by_user_id bigint,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data_request_initial_review_id bigint,
    review_notes character varying,
    study_analyst_yes_no character varying
);


--
-- Name: COLUMN data_request_initial_review_history.message_notes; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_initial_review_history.message_notes IS 'Message to requester';


--
-- Name: COLUMN data_request_initial_review_history.next_step; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_initial_review_history.next_step IS 'Is the review complete?

*If the original request needs to be updated before you can complete
the initial review, select **update request**. This will notify the requester
that an update is required.*';


--
-- Name: COLUMN data_request_initial_review_history.review_approved_yes_no; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_initial_review_history.review_approved_yes_no IS '**Approve the request?**

- Select **no** to reject the data request and inform the requester.
- Select **yes** if the request is *approved* and to send on for PI notifications and reviews.';


--
-- Name: COLUMN data_request_initial_review_history.review_notes; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_initial_review_history.review_notes IS 'Reviewer''s notes';


--
-- Name: COLUMN data_request_initial_review_history.study_analyst_yes_no; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_initial_review_history.study_analyst_yes_no IS 'Is the requester a Project Viva analyst?';


--
-- Name: data_request_initial_review_history_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_request_initial_review_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_request_initial_review_history_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_request_initial_review_history_id_seq OWNED BY data_requests.data_request_initial_review_history.id;


--
-- Name: data_request_initial_reviews; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_request_initial_reviews (
    id bigint NOT NULL,
    master_id bigint,
    message_notes character varying,
    next_step character varying,
    review_approved_yes_no character varying,
    created_by_user_id bigint,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    review_notes character varying,
    study_analyst_yes_no character varying
);


--
-- Name: TABLE data_request_initial_reviews; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON TABLE data_requests.data_request_initial_reviews IS 'Dynamicmodel: Initial Review';


--
-- Name: COLUMN data_request_initial_reviews.message_notes; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_initial_reviews.message_notes IS 'Message to requester';


--
-- Name: COLUMN data_request_initial_reviews.next_step; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_initial_reviews.next_step IS 'Is the review complete?

*If the original request needs to be updated before you can complete
the initial review, select **update request**. This will notify the requester
that an update is required.*';


--
-- Name: COLUMN data_request_initial_reviews.review_approved_yes_no; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_initial_reviews.review_approved_yes_no IS '**Approve the request?**

- Select **no** to reject the data request and inform the requester.
- Select **yes** if the request is *approved* and to send on for PI notifications and reviews.';


--
-- Name: COLUMN data_request_initial_reviews.review_notes; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_initial_reviews.review_notes IS 'Reviewer''s notes';


--
-- Name: COLUMN data_request_initial_reviews.study_analyst_yes_no; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_initial_reviews.study_analyst_yes_no IS 'Is the requester a Project Viva analyst?';


--
-- Name: data_request_initial_reviews_from_al_data_request_assignments; Type: VIEW; Schema: data_requests; Owner: -
--

CREATE VIEW data_requests.data_request_initial_reviews_from_al_data_request_assignments AS
 SELECT dest.id,
    dest.master_id,
    dest.message_notes,
    dest.next_step,
    dest.review_approved_yes_no,
    dest.created_by_user_id,
    dest.user_id,
    dest.created_at,
    dest.updated_at,
    dest.review_notes,
    dest.study_analyst_yes_no,
    mr.from_record_type,
    mr.from_record_id,
    mr.id AS model_reference_id,
    'data_requests.data_request_initial_reviews'::character varying AS from_table
   FROM (data_requests.data_request_initial_reviews dest
     JOIN ml_app.model_references mr ON (((dest.id = mr.to_record_id) AND (dest.master_id = mr.to_record_master_id) AND (NOT COALESCE(mr.disabled, false)) AND ((mr.from_record_type)::text = 'ActivityLog::DataRequestAssignment'::text) AND ((mr.to_record_type)::text = 'DynamicModel::DataRequestInitialReview'::text))));


--
-- Name: data_request_initial_reviews_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_request_initial_reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_request_initial_reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_request_initial_reviews_id_seq OWNED BY data_requests.data_request_initial_reviews.id;


--
-- Name: data_request_message_history; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_request_message_history (
    id bigint NOT NULL,
    master_id bigint,
    message_notes character varying,
    created_by_user_id bigint,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data_request_message_id bigint
);


--
-- Name: COLUMN data_request_message_history.message_notes; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_message_history.message_notes IS 'Message to requester';


--
-- Name: data_request_message_history_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_request_message_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_request_message_history_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_request_message_history_id_seq OWNED BY data_requests.data_request_message_history.id;


--
-- Name: data_request_messages; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_request_messages (
    id bigint NOT NULL,
    master_id bigint,
    message_notes character varying,
    created_by_user_id bigint,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE data_request_messages; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON TABLE data_requests.data_request_messages IS 'Dynamicmodel: Message';


--
-- Name: COLUMN data_request_messages.message_notes; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_request_messages.message_notes IS 'Message to requester';


--
-- Name: data_request_messages_from_al_data_request_assignments; Type: VIEW; Schema: data_requests; Owner: -
--

CREATE VIEW data_requests.data_request_messages_from_al_data_request_assignments AS
 SELECT dest.id,
    dest.master_id,
    dest.message_notes,
    dest.created_by_user_id,
    dest.user_id,
    dest.created_at,
    dest.updated_at,
    mr.from_record_master_id,
    mr.from_record_type,
    mr.from_record_id,
    mr.id AS model_reference_id,
    'data_requests.data_request_messages'::character varying AS from_table
   FROM (data_requests.data_request_messages dest
     JOIN ml_app.model_references mr ON (((dest.id = mr.to_record_id) AND (dest.master_id = mr.to_record_master_id) AND (NOT COALESCE(mr.disabled, false)) AND ((mr.from_record_type)::text = 'ActivityLog::DataRequestAssignment'::text) AND ((mr.to_record_type)::text = 'DynamicModel::DataRequestMessage'::text))));


--
-- Name: data_request_messages_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_request_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_request_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_request_messages_id_seq OWNED BY data_requests.data_request_messages.id;


--
-- Name: data_requests; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_requests (
    id bigint NOT NULL,
    master_id bigint,
    status character varying,
    project_title character varying,
    select_purpose character varying,
    other_purpose character varying,
    others_handling_data character varying,
    other_pm_contact character varying,
    data_start_date date,
    data_end_date date,
    terms_of_use_yes_no character varying,
    created_by_user_id bigint,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    request_notes character varying,
    study_analyst_yes_no character varying,
    select_pm_contact character varying
);


--
-- Name: TABLE data_requests; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON TABLE data_requests.data_requests IS 'Dynamicmodel: Data Request';


--
-- Name: COLUMN data_requests.project_title; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_requests.project_title IS 'Proposal title';


--
-- Name: COLUMN data_requests.select_purpose; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_requests.select_purpose IS 'Purpose of this data request';


--
-- Name: COLUMN data_requests.other_purpose; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_requests.other_purpose IS '*other purpose*: please explain';


--
-- Name: COLUMN data_requests.others_handling_data; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_requests.others_handling_data IS 'Name and title of others who will be handling Project Viva data (one per line)';


--
-- Name: COLUMN data_requests.other_pm_contact; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_requests.other_pm_contact IS 'Project Manager name';


--
-- Name: COLUMN data_requests.data_start_date; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_requests.data_start_date IS 'Planned analysis start date';


--
-- Name: COLUMN data_requests.data_end_date; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_requests.data_end_date IS 'Planned analysis end date';


--
-- Name: COLUMN data_requests.terms_of_use_yes_no; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_requests.terms_of_use_yes_no IS 'I attest that I have read, understood, and accepted the terms of use stated in the data use agreement, or other form of contractual agreement, with the Project Viva.';


--
-- Name: COLUMN data_requests.request_notes; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_requests.request_notes IS '#### Background

Brief description of why this topic is important,
brief summary of literature, and a priori hypothesis

*To include supporting documents or files, complete this form, then
select the Supporting Files section at the end of the form*';


--
-- Name: COLUMN data_requests.study_analyst_yes_no; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_requests.study_analyst_yes_no IS 'Are you an internal Project Viva analyst?';


--
-- Name: COLUMN data_requests.select_pm_contact; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.data_requests.select_pm_contact IS 'Project Viva Project Manager contact';


--
-- Name: data_requests_from_al_data_request_assignments; Type: VIEW; Schema: data_requests; Owner: -
--

CREATE VIEW data_requests.data_requests_from_al_data_request_assignments AS
 SELECT dest.id,
    dest.master_id,
    dest.status,
    dest.project_title,
    dest.select_purpose,
    dest.other_purpose,
    dest.others_handling_data,
    dest.other_pm_contact,
    dest.data_start_date,
    dest.data_end_date,
    dest.terms_of_use_yes_no,
    dest.created_by_user_id,
    dest.user_id,
    dest.created_at,
    dest.updated_at,
    dest.request_notes,
    dest.study_analyst_yes_no,
    dest.select_pm_contact,
    mr.from_record_master_id,
    mr.from_record_type,
    mr.from_record_id,
    mr.id AS model_reference_id,
    'data_requests.data_requests'::character varying AS from_table
   FROM (data_requests.data_requests dest
     JOIN ml_app.model_references mr ON (((dest.id = mr.to_record_id) AND (dest.master_id = mr.to_record_master_id) AND (NOT COALESCE(mr.disabled, false)) AND ((mr.from_record_type)::text = 'ActivityLog::DataRequestAssignment'::text) AND ((mr.to_record_type)::text = 'DynamicModel::DataRequest'::text))));


--
-- Name: data_requests_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_requests_id_seq OWNED BY data_requests.data_requests.id;


--
-- Name: data_requests_selected_attrib_history; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_requests_selected_attrib_history (
    id bigint NOT NULL,
    master_id bigint,
    record_id bigint,
    data character varying,
    data_request_id bigint,
    disabled boolean DEFAULT false,
    variable_name character varying,
    record_type character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data_requests_selected_attrib_id bigint
);


--
-- Name: data_requests_selected_attrib_history_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_requests_selected_attrib_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_requests_selected_attrib_history_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_requests_selected_attrib_history_id_seq OWNED BY data_requests.data_requests_selected_attrib_history.id;


--
-- Name: data_requests_selected_attribs; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.data_requests_selected_attribs (
    id bigint NOT NULL,
    master_id bigint,
    record_id bigint,
    data character varying,
    data_request_id bigint,
    disabled boolean DEFAULT false,
    variable_name character varying,
    record_type character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE data_requests_selected_attribs; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON TABLE data_requests.data_requests_selected_attribs IS 'Dynamicmodel: Selected Data Attributes';


--
-- Name: data_requests_selected_attribs_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.data_requests_selected_attribs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_requests_selected_attribs_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.data_requests_selected_attribs_id_seq OWNED BY data_requests.data_requests_selected_attribs.id;


--
-- Name: nfs_store_containers; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_containers (
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
-- Name: nfs_store_containers_from_al_data_request_assignments; Type: VIEW; Schema: data_requests; Owner: -
--

CREATE VIEW data_requests.nfs_store_containers_from_al_data_request_assignments AS
 SELECT dest.id,
    dest.name,
    dest.user_id,
    dest.app_type_id,
    dest.nfs_store_container_id,
    dest.master_id,
    dest.created_at,
    dest.updated_at,
    mr.from_record_master_id,
    mr.from_record_type,
    mr.from_record_id,
    mr.id AS model_reference_id,
    'nfs_store_containers'::character varying AS from_table
   FROM (ml_app.nfs_store_containers dest
     JOIN ml_app.model_references mr ON (((dest.id = mr.to_record_id) AND (dest.master_id = mr.to_record_master_id) AND (NOT COALESCE(mr.disabled, false)) AND ((mr.from_record_type)::text = 'ActivityLog::DataRequestAssignment'::text) AND ((mr.to_record_type)::text = 'NfsStore::Manage::Container'::text))));


--
-- Name: q1_datadic; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.q1_datadic (
    id integer NOT NULL,
    variable_name character varying,
    domain text,
    field_type_rc text,
    field_type_sa text,
    field_label text,
    field_attributes text,
    field_note text,
    text_valid_type text,
    text_valid_min text,
    text_valid_max text,
    required_field text,
    field_attr_array text[],
    source text,
    owner text,
    classification text,
    display text
);


--
-- Name: q1_datadic_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.q1_datadic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: q1_datadic_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.q1_datadic_id_seq OWNED BY data_requests.q1_datadic.id;


--
-- Name: q2_datadic; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.q2_datadic (
    id integer NOT NULL,
    variable_name character varying,
    domain text,
    field_type_rc text,
    field_type_sa text,
    field_label text,
    field_attributes text,
    field_note text,
    text_valid_type text,
    text_valid_min text,
    text_valid_max text,
    required_field text,
    field_attr_array text[],
    source text,
    owner text,
    classification text,
    display text
);


--
-- Name: q2_datadic_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.q2_datadic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: q2_datadic_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.q2_datadic_id_seq OWNED BY data_requests.q2_datadic.id;


--
-- Name: user_profiile_detail_history; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.user_profiile_detail_history (
    id bigint NOT NULL,
    notes character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_profiile_detail_id bigint
);


--
-- Name: user_profiile_detail_history_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.user_profiile_detail_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profiile_detail_history_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.user_profiile_detail_history_id_seq OWNED BY data_requests.user_profiile_detail_history.id;


--
-- Name: user_profiile_details; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.user_profiile_details (
    id bigint NOT NULL,
    notes character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE user_profiile_details; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON TABLE data_requests.user_profiile_details IS 'Dynamicmodel: User Details';


--
-- Name: user_profiile_details_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.user_profiile_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profiile_details_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.user_profiile_details_id_seq OWNED BY data_requests.user_profiile_details.id;


--
-- Name: user_profile_academic_detail_history; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.user_profile_academic_detail_history (
    id bigint NOT NULL,
    primary_affiliation character varying,
    position_title character varying,
    start_year character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_profile_academic_detail_id bigint,
    created_by_user_id bigint
);


--
-- Name: COLUMN user_profile_academic_detail_history.primary_affiliation; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.user_profile_academic_detail_history.primary_affiliation IS 'Primary Affiliation';


--
-- Name: COLUMN user_profile_academic_detail_history.position_title; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.user_profile_academic_detail_history.position_title IS 'Position / Title';


--
-- Name: COLUMN user_profile_academic_detail_history.start_year; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.user_profile_academic_detail_history.start_year IS 'Start Year';


--
-- Name: user_profile_academic_detail_history_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.user_profile_academic_detail_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profile_academic_detail_history_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.user_profile_academic_detail_history_id_seq OWNED BY data_requests.user_profile_academic_detail_history.id;


--
-- Name: user_profile_academic_details; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.user_profile_academic_details (
    id bigint NOT NULL,
    primary_affiliation character varying,
    position_title character varying,
    start_year integer,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_by_user_id bigint
);


--
-- Name: TABLE user_profile_academic_details; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON TABLE data_requests.user_profile_academic_details IS 'Dynamicmodel: User Details';


--
-- Name: COLUMN user_profile_academic_details.primary_affiliation; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.user_profile_academic_details.primary_affiliation IS 'Primary Affiliation';


--
-- Name: COLUMN user_profile_academic_details.position_title; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.user_profile_academic_details.position_title IS 'Position / Title';


--
-- Name: COLUMN user_profile_academic_details.start_year; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.user_profile_academic_details.start_year IS 'Start Year';


--
-- Name: user_profile_academic_details_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.user_profile_academic_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profile_academic_details_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.user_profile_academic_details_id_seq OWNED BY data_requests.user_profile_academic_details.id;


--
-- Name: user_profile_detail_history; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.user_profile_detail_history (
    id bigint NOT NULL,
    notes character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_profile_detail_id bigint,
    title character varying,
    created_by_user_id bigint
);


--
-- Name: COLUMN user_profile_detail_history.notes; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.user_profile_detail_history.notes IS 'Describe your job, hobbies and interests';


--
-- Name: COLUMN user_profile_detail_history.title; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.user_profile_detail_history.title IS 'Job Title';


--
-- Name: user_profile_detail_history_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.user_profile_detail_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profile_detail_history_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.user_profile_detail_history_id_seq OWNED BY data_requests.user_profile_detail_history.id;


--
-- Name: user_profile_details; Type: TABLE; Schema: data_requests; Owner: -
--

CREATE TABLE data_requests.user_profile_details (
    id bigint NOT NULL,
    notes character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    title character varying,
    created_by_user_id bigint
);


--
-- Name: TABLE user_profile_details; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON TABLE data_requests.user_profile_details IS 'Dynamicmodel: User Details';


--
-- Name: COLUMN user_profile_details.notes; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.user_profile_details.notes IS 'Describe your job, hobbies and interests';


--
-- Name: COLUMN user_profile_details.title; Type: COMMENT; Schema: data_requests; Owner: -
--

COMMENT ON COLUMN data_requests.user_profile_details.title IS 'Job Title';


--
-- Name: user_profile_details_id_seq; Type: SEQUENCE; Schema: data_requests; Owner: -
--

CREATE SEQUENCE data_requests.user_profile_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profile_details_id_seq; Type: SEQUENCE OWNED BY; Schema: data_requests; Owner: -
--

ALTER SEQUENCE data_requests.user_profile_details_id_seq OWNED BY data_requests.user_profile_details.id;


--
-- Name: grit_assignment_history; Type: TABLE; Schema: extra_app; Owner: -
--

CREATE TABLE extra_app.grit_assignment_history (
    id bigint NOT NULL,
    master_id bigint,
    grit_id bigint,
    user_id bigint,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    grit_assignment_table_id bigint
);


--
-- Name: grit_assignment_history_id_seq; Type: SEQUENCE; Schema: extra_app; Owner: -
--

CREATE SEQUENCE extra_app.grit_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grit_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: extra_app; Owner: -
--

ALTER SEQUENCE extra_app.grit_assignment_history_id_seq OWNED BY extra_app.grit_assignment_history.id;


--
-- Name: grit_assignments; Type: TABLE; Schema: extra_app; Owner: -
--

CREATE TABLE extra_app.grit_assignments (
    id bigint NOT NULL,
    master_id bigint,
    grit_id bigint,
    user_id bigint,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: grit_assignments_id_seq; Type: SEQUENCE; Schema: extra_app; Owner: -
--

CREATE SEQUENCE extra_app.grit_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grit_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: extra_app; Owner: -
--

ALTER SEQUENCE extra_app.grit_assignments_id_seq OWNED BY extra_app.grit_assignments.id;


--
-- Name: pitt_bhi_assignment_history; Type: TABLE; Schema: extra_app; Owner: -
--

CREATE TABLE extra_app.pitt_bhi_assignment_history (
    id bigint NOT NULL,
    master_id bigint,
    pitt_bhi_id bigint,
    user_id bigint,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    pitt_bhi_assignment_table_id bigint
);


--
-- Name: pitt_bhi_assignment_history_id_seq; Type: SEQUENCE; Schema: extra_app; Owner: -
--

CREATE SEQUENCE extra_app.pitt_bhi_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pitt_bhi_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: extra_app; Owner: -
--

ALTER SEQUENCE extra_app.pitt_bhi_assignment_history_id_seq OWNED BY extra_app.pitt_bhi_assignment_history.id;


--
-- Name: pitt_bhi_assignments; Type: TABLE; Schema: extra_app; Owner: -
--

CREATE TABLE extra_app.pitt_bhi_assignments (
    id bigint NOT NULL,
    master_id bigint,
    pitt_bhi_id bigint,
    user_id bigint,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: pitt_bhi_assignments_id_seq; Type: SEQUENCE; Schema: extra_app; Owner: -
--

CREATE SEQUENCE extra_app.pitt_bhi_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pitt_bhi_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: extra_app; Owner: -
--

ALTER SEQUENCE extra_app.pitt_bhi_assignments_id_seq OWNED BY extra_app.pitt_bhi_assignments.id;


--
-- Name: sleep_assignment_history; Type: TABLE; Schema: extra_app; Owner: -
--

CREATE TABLE extra_app.sleep_assignment_history (
    id bigint NOT NULL,
    master_id bigint,
    sleep_id bigint,
    user_id bigint,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sleep_assignment_table_id bigint
);


--
-- Name: sleep_assignment_history_id_seq; Type: SEQUENCE; Schema: extra_app; Owner: -
--

CREATE SEQUENCE extra_app.sleep_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sleep_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: extra_app; Owner: -
--

ALTER SEQUENCE extra_app.sleep_assignment_history_id_seq OWNED BY extra_app.sleep_assignment_history.id;


--
-- Name: sleep_assignments; Type: TABLE; Schema: extra_app; Owner: -
--

CREATE TABLE extra_app.sleep_assignments (
    id bigint NOT NULL,
    master_id bigint,
    sleep_id bigint,
    user_id bigint,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sleep_assignments_id_seq; Type: SEQUENCE; Schema: extra_app; Owner: -
--

CREATE SEQUENCE extra_app.sleep_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sleep_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: extra_app; Owner: -
--

ALTER SEQUENCE extra_app.sleep_assignments_id_seq OWNED BY extra_app.sleep_assignments.id;


--
-- Name: accuracy_score_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.accuracy_score_history (
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

CREATE SEQUENCE ml_app.accuracy_score_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.accuracy_score_history_id_seq OWNED BY ml_app.accuracy_score_history.id;


--
-- Name: accuracy_scores; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.accuracy_scores (
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

CREATE SEQUENCE ml_app.accuracy_scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.accuracy_scores_id_seq OWNED BY ml_app.accuracy_scores.id;


--
-- Name: activity_log_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_history (
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
    blank_log_field_list character varying,
    blank_log_name character varying,
    extra_log_types character varying,
    hide_item_list_panel boolean,
    main_log_name character varying,
    process_name character varying,
    table_name character varying,
    category character varying,
    schema_name character varying
);


--
-- Name: activity_log_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.activity_log_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_history_id_seq OWNED BY ml_app.activity_log_history.id;


--
-- Name: activity_log_player_contact_phone_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_player_contact_phone_history (
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
-- Name: activity_log_player_contact_phone_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.activity_log_player_contact_phone_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_contact_phone_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_player_contact_phone_history_id_seq OWNED BY ml_app.activity_log_player_contact_phone_history.id;


--
-- Name: activity_log_player_contact_phones; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_player_contact_phones (
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
-- Name: activity_log_player_contact_phones_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.activity_log_player_contact_phones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_contact_phones_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_player_contact_phones_id_seq OWNED BY ml_app.activity_log_player_contact_phones.id;


--
-- Name: activity_logs; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_logs (
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
    table_name character varying,
    category character varying,
    schema_name character varying
);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_logs_id_seq OWNED BY ml_app.activity_logs.id;


--
-- Name: address_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.address_history (
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


--
-- Name: address_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.address_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: address_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.address_history_id_seq OWNED BY ml_app.address_history.id;


--
-- Name: addresses; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.addresses (
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


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.addresses_id_seq OWNED BY ml_app.addresses.id;


--
-- Name: admin_action_logs; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.admin_action_logs (
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
-- Name: admin_action_logs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.admin_action_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_action_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.admin_action_logs_id_seq OWNED BY ml_app.admin_action_logs.id;


--
-- Name: admin_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.admin_history (
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
    admin_id integer,
    encrypted_otp_secret character varying,
    encrypted_otp_secret_iv character varying,
    encrypted_otp_secret_salt character varying,
    consumed_timestep integer,
    otp_required_for_login boolean,
    reset_password_sent_at timestamp without time zone,
    password_updated_at timestamp without time zone,
    updated_by_admin_id integer
);


--
-- Name: admin_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.admin_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.admin_history_id_seq OWNED BY ml_app.admin_history.id;


--
-- Name: admins; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.admins (
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
    encrypted_otp_secret character varying,
    encrypted_otp_secret_iv character varying,
    encrypted_otp_secret_salt character varying,
    consumed_timestep integer,
    otp_required_for_login boolean,
    reset_password_sent_at timestamp without time zone,
    password_updated_at timestamp without time zone,
    first_name character varying,
    last_name character varying,
    do_not_email boolean DEFAULT false,
    admin_id bigint
);


--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.admins_id_seq OWNED BY ml_app.admins.id;


--
-- Name: app_configuration_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.app_configuration_history (
    id integer NOT NULL,
    name character varying,
    value character varying,
    app_type_id bigint,
    user_id bigint,
    role_name character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    app_configuration_id integer
);


--
-- Name: app_configuration_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.app_configuration_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_configuration_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.app_configuration_history_id_seq OWNED BY ml_app.app_configuration_history.id;


--
-- Name: app_configurations; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.app_configurations (
    id integer NOT NULL,
    name character varying,
    value character varying,
    disabled boolean,
    admin_id integer,
    user_id integer,
    app_type_id integer,
    role_name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: app_configurations_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.app_configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.app_configurations_id_seq OWNED BY ml_app.app_configurations.id;


--
-- Name: app_type_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.app_type_history (
    id integer NOT NULL,
    name character varying,
    label character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    app_type_id integer
);


--
-- Name: app_type_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.app_type_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_type_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.app_type_history_id_seq OWNED BY ml_app.app_type_history.id;


--
-- Name: app_types; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.app_types (
    id integer NOT NULL,
    name character varying,
    label character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    default_schema_name character varying
);


--
-- Name: app_types_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.app_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_types_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.app_types_id_seq OWNED BY ml_app.app_types.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: college_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.college_history (
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

CREATE SEQUENCE ml_app.college_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: college_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.college_history_id_seq OWNED BY ml_app.college_history.id;


--
-- Name: colleges; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.colleges (
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

CREATE SEQUENCE ml_app.colleges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: colleges_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.colleges_id_seq OWNED BY ml_app.colleges.id;


--
-- Name: config_libraries; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.config_libraries (
    id integer NOT NULL,
    category character varying,
    name character varying,
    options character varying,
    format character varying,
    disabled boolean DEFAULT false,
    admin_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: config_libraries_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.config_libraries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: config_libraries_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.config_libraries_id_seq OWNED BY ml_app.config_libraries.id;


--
-- Name: config_library_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.config_library_history (
    id integer NOT NULL,
    category character varying,
    name character varying,
    options character varying,
    format character varying,
    disabled boolean DEFAULT false,
    admin_id integer,
    config_library_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: config_library_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.config_library_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: config_library_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.config_library_history_id_seq OWNED BY ml_app.config_library_history.id;


--
-- Name: copy_player_infos; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.copy_player_infos (
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
-- Name: delayed_jobs; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.delayed_jobs (
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
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.delayed_jobs_id_seq OWNED BY ml_app.delayed_jobs.id;


--
-- Name: dynamic_model_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.dynamic_model_history (
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
    dynamic_model_id integer,
    options character varying
);


--
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.dynamic_model_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.dynamic_model_history_id_seq OWNED BY ml_app.dynamic_model_history.id;


--
-- Name: dynamic_models; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.dynamic_models (
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
-- Name: dynamic_models_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.dynamic_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dynamic_models_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.dynamic_models_id_seq OWNED BY ml_app.dynamic_models.id;


--
-- Name: exception_logs; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.exception_logs (
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
-- Name: exception_logs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.exception_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exception_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.exception_logs_id_seq OWNED BY ml_app.exception_logs.id;


--
-- Name: external_identifier_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.external_identifier_history (
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
    extra_fields character varying,
    alphanumeric boolean,
    schema_name character varying,
    options character varying
);


--
-- Name: external_identifier_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.external_identifier_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_identifier_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.external_identifier_history_id_seq OWNED BY ml_app.external_identifier_history.id;


--
-- Name: external_identifiers; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.external_identifiers (
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
    extra_fields character varying,
    category character varying,
    schema_name character varying,
    options character varying
);


--
-- Name: external_identifiers_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.external_identifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_identifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.external_identifiers_id_seq OWNED BY ml_app.external_identifiers.id;


--
-- Name: external_link_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.external_link_history (
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

CREATE SEQUENCE ml_app.external_link_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_link_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.external_link_history_id_seq OWNED BY ml_app.external_link_history.id;


--
-- Name: external_links; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.external_links (
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

CREATE SEQUENCE ml_app.external_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_links_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.external_links_id_seq OWNED BY ml_app.external_links.id;


--
-- Name: general_selection_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.general_selection_history (
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

CREATE SEQUENCE ml_app.general_selection_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: general_selection_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.general_selection_history_id_seq OWNED BY ml_app.general_selection_history.id;


--
-- Name: general_selections; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.general_selections (
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

CREATE SEQUENCE ml_app.general_selections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: general_selections_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.general_selections_id_seq OWNED BY ml_app.general_selections.id;


--
-- Name: imports; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.imports (
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

CREATE SEQUENCE ml_app.imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.imports_id_seq OWNED BY ml_app.imports.id;


--
-- Name: imports_model_generators; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.imports_model_generators (
    id bigint NOT NULL,
    name character varying,
    dynamic_model_table character varying,
    options json,
    description character varying,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: imports_model_generators_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.imports_model_generators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_model_generators_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.imports_model_generators_id_seq OWNED BY ml_app.imports_model_generators.id;


--
-- Name: item_flag_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.item_flag_history (
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

CREATE SEQUENCE ml_app.item_flag_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.item_flag_history_id_seq OWNED BY ml_app.item_flag_history.id;


--
-- Name: item_flag_name_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.item_flag_name_history (
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

CREATE SEQUENCE ml_app.item_flag_name_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.item_flag_name_history_id_seq OWNED BY ml_app.item_flag_name_history.id;


--
-- Name: item_flag_names; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.item_flag_names (
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

CREATE SEQUENCE ml_app.item_flag_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_names_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.item_flag_names_id_seq OWNED BY ml_app.item_flag_names.id;


--
-- Name: item_flags; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.item_flags (
    id integer NOT NULL,
    item_id integer,
    item_type character varying,
    item_flag_name_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    disabled boolean
);


--
-- Name: item_flags_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.item_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.item_flags_id_seq OWNED BY ml_app.item_flags.id;


--
-- Name: manage_users; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.manage_users (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: manage_users_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.manage_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manage_users_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.manage_users_id_seq OWNED BY ml_app.manage_users.id;


--
-- Name: masters; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.masters (
    id integer NOT NULL,
    msid integer,
    pro_id integer,
    pro_info_id integer,
    rank integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    contact_id integer,
    created_by_user_id bigint
);


--
-- Name: masters_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.masters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: masters_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.masters_id_seq OWNED BY ml_app.masters.id;


--
-- Name: message_notifications; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.message_notifications (
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
    recipient_data character varying[],
    from_user_email character varying,
    role_name character varying,
    content_template_text character varying,
    importance character varying,
    extra_substitutions character varying,
    content_hash character varying
);


--
-- Name: message_notifications_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.message_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.message_notifications_id_seq OWNED BY ml_app.message_notifications.id;


--
-- Name: message_template_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.message_template_history (
    id integer NOT NULL,
    name character varying,
    template_type character varying,
    template character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    message_template_id integer,
    message_type character varying,
    category character varying
);


--
-- Name: message_template_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.message_template_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_template_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.message_template_history_id_seq OWNED BY ml_app.message_template_history.id;


--
-- Name: message_templates; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.message_templates (
    id integer NOT NULL,
    name character varying,
    message_type character varying,
    template_type character varying,
    template character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    category character varying
);


--
-- Name: message_templates_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.message_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.message_templates_id_seq OWNED BY ml_app.message_templates.id;


--
-- Name: model_references_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.model_references_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: model_references_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.model_references_id_seq OWNED BY ml_app.model_references.id;


--
-- Name: msid_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.msid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_archived_file_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_archived_file_history (
    id integer NOT NULL,
    file_hash character varying,
    file_name character varying,
    content_type character varying,
    archive_file character varying,
    path character varying,
    file_size character varying,
    file_updated_at character varying,
    nfs_store_container_id bigint,
    title character varying,
    description character varying,
    file_metadata character varying,
    nfs_store_stored_file_id bigint,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_archived_file_id integer
);


--
-- Name: nfs_store_archived_file_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_archived_file_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_archived_file_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_archived_file_history_id_seq OWNED BY ml_app.nfs_store_archived_file_history.id;


--
-- Name: nfs_store_archived_files_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_archived_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_archived_files_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_archived_files_id_seq OWNED BY ml_app.nfs_store_archived_files.id;


--
-- Name: nfs_store_container_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_container_history (
    id integer NOT NULL,
    master_id integer,
    name character varying,
    app_type_id bigint,
    orig_nfs_store_container_id bigint,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_container_id integer
);


--
-- Name: nfs_store_container_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_container_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_container_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_container_history_id_seq OWNED BY ml_app.nfs_store_container_history.id;


--
-- Name: nfs_store_containers_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_containers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_containers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_containers_id_seq OWNED BY ml_app.nfs_store_containers.id;


--
-- Name: nfs_store_downloads; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_downloads (
    id integer NOT NULL,
    user_groups integer[] DEFAULT '{}'::integer[],
    path character varying,
    retrieval_path character varying,
    retrieved_items character varying,
    user_id integer NOT NULL,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_container_ids integer[]
);


--
-- Name: nfs_store_downloads_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_downloads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_downloads_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_downloads_id_seq OWNED BY ml_app.nfs_store_downloads.id;


--
-- Name: nfs_store_filter_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_filter_history (
    id integer NOT NULL,
    app_type_id bigint,
    role_name character varying,
    user_id bigint,
    resource_name character varying,
    filter character varying,
    description character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_filter_id integer
);


--
-- Name: nfs_store_filter_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_filter_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_filter_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_filter_history_id_seq OWNED BY ml_app.nfs_store_filter_history.id;


--
-- Name: nfs_store_filters; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_filters (
    id integer NOT NULL,
    app_type_id integer,
    role_name character varying,
    user_id integer,
    resource_name character varying,
    filter character varying,
    description character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: nfs_store_filters_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_filters_id_seq OWNED BY ml_app.nfs_store_filters.id;


--
-- Name: nfs_store_imports; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_imports (
    id integer NOT NULL,
    file_hash character varying,
    file_name character varying,
    user_id integer,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    path character varying
);


--
-- Name: nfs_store_imports_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_imports_id_seq OWNED BY ml_app.nfs_store_imports.id;


--
-- Name: nfs_store_move_actions; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_move_actions (
    id integer NOT NULL,
    user_groups integer[],
    path character varying,
    new_path character varying,
    retrieval_path character varying,
    moved_items character varying,
    nfs_store_container_ids integer[],
    user_id integer NOT NULL,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: nfs_store_move_actions_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_move_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_move_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_move_actions_id_seq OWNED BY ml_app.nfs_store_move_actions.id;


--
-- Name: nfs_store_stored_file_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_stored_file_history (
    id integer NOT NULL,
    file_hash character varying,
    file_name character varying,
    content_type character varying,
    path character varying,
    file_size character varying,
    file_updated_at character varying,
    nfs_store_container_id bigint,
    title character varying,
    description character varying,
    file_metadata character varying,
    last_process_name_run character varying,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_stored_file_id integer
);


--
-- Name: nfs_store_stored_file_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_stored_file_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_stored_file_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_stored_file_history_id_seq OWNED BY ml_app.nfs_store_stored_file_history.id;


--
-- Name: nfs_store_stored_files_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_stored_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_stored_files_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_stored_files_id_seq OWNED BY ml_app.nfs_store_stored_files.id;


--
-- Name: nfs_store_trash_actions; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_trash_actions (
    id integer NOT NULL,
    user_groups integer[] DEFAULT '{}'::integer[],
    path character varying,
    retrieval_path character varying,
    trashed_items character varying,
    nfs_store_container_ids integer[],
    user_id integer NOT NULL,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: nfs_store_trash_actions_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_trash_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_trash_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_trash_actions_id_seq OWNED BY ml_app.nfs_store_trash_actions.id;


--
-- Name: nfs_store_uploads; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_uploads (
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
    nfs_store_stored_file_id integer,
    upload_set character varying
);


--
-- Name: nfs_store_uploads_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_uploads_id_seq OWNED BY ml_app.nfs_store_uploads.id;


--
-- Name: nfs_store_user_file_actions; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_user_file_actions (
    id integer NOT NULL,
    user_groups integer[],
    path character varying,
    new_path character varying,
    action character varying,
    retrieval_path character varying,
    action_items character varying,
    nfs_store_container_ids integer[],
    user_id integer NOT NULL,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: nfs_store_user_file_actions_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.nfs_store_user_file_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfs_store_user_file_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.nfs_store_user_file_actions_id_seq OWNED BY ml_app.nfs_store_user_file_actions.id;


--
-- Name: page_layout_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.page_layout_history (
    id integer NOT NULL,
    layout_name character varying,
    panel_name character varying,
    panel_label character varying,
    panel_position character varying,
    options character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    page_layout_id integer,
    app_type_id character varying,
    description character varying
);


--
-- Name: page_layout_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.page_layout_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_layout_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.page_layout_history_id_seq OWNED BY ml_app.page_layout_history.id;


--
-- Name: page_layouts; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.page_layouts (
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
    updated_at timestamp without time zone NOT NULL,
    description character varying
);


--
-- Name: page_layouts_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.page_layouts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_layouts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.page_layouts_id_seq OWNED BY ml_app.page_layouts.id;


--
-- Name: player_contact_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.player_contact_history (
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


--
-- Name: player_contact_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.player_contact_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_contact_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.player_contact_history_id_seq OWNED BY ml_app.player_contact_history.id;


--
-- Name: player_contacts; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.player_contacts (
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


--
-- Name: player_contacts_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.player_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.player_contacts_id_seq OWNED BY ml_app.player_contacts.id;


--
-- Name: player_info_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.player_info_history (
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


--
-- Name: player_info_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.player_info_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_info_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.player_info_history_id_seq OWNED BY ml_app.player_info_history.id;


--
-- Name: player_infos; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.player_infos (
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


--
-- Name: player_infos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.player_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.player_infos_id_seq OWNED BY ml_app.player_infos.id;


--
-- Name: pro_infos; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.pro_infos (
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


--
-- Name: pro_infos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.pro_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pro_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.pro_infos_id_seq OWNED BY ml_app.pro_infos.id;


--
-- Name: protocol_event_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.protocol_event_history (
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

CREATE SEQUENCE ml_app.protocol_event_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_event_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.protocol_event_history_id_seq OWNED BY ml_app.protocol_event_history.id;


--
-- Name: protocol_events; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.protocol_events (
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

CREATE SEQUENCE ml_app.protocol_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_events_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.protocol_events_id_seq OWNED BY ml_app.protocol_events.id;


--
-- Name: protocol_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.protocol_history (
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

CREATE SEQUENCE ml_app.protocol_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.protocol_history_id_seq OWNED BY ml_app.protocol_history.id;


--
-- Name: protocols; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.protocols (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    "position" integer,
    app_type_id bigint
);


--
-- Name: protocols_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.protocols_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocols_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.protocols_id_seq OWNED BY ml_app.protocols.id;


--
-- Name: rc_cis; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.rc_cis (
    id integer NOT NULL,
    fname character varying,
    lname character varying,
    status character varying,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
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
-- Name: rc_cis2; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.rc_cis2 (
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

CREATE SEQUENCE ml_app.rc_cis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rc_cis_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.rc_cis_id_seq OWNED BY ml_app.rc_cis.id;


--
-- Name: rc_stage_cif_copy; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.rc_stage_cif_copy (
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
    id integer NOT NULL,
    status character varying,
    created_at timestamp without time zone DEFAULT now(),
    user_id integer,
    master_id integer,
    updated_at timestamp without time zone DEFAULT now(),
    added_tracker boolean
);


--
-- Name: rc_stage_cif_copy_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.rc_stage_cif_copy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rc_stage_cif_copy_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.rc_stage_cif_copy_id_seq OWNED BY ml_app.rc_stage_cif_copy.id;


--
-- Name: report_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.report_history (
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
    selection_fields character varying,
    short_name character varying,
    options character varying
);


--
-- Name: report_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.report_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.report_history_id_seq OWNED BY ml_app.report_history.id;


--
-- Name: reports; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.reports (
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
    item_type character varying,
    short_name character varying,
    options character varying
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.reports_id_seq OWNED BY ml_app.reports.id;


--
-- Name: role_description_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.role_description_history (
    id bigint NOT NULL,
    role_description_id bigint,
    app_type_id bigint,
    role_name character varying,
    role_template character varying,
    name character varying,
    description character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: role_description_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.role_description_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_description_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.role_description_history_id_seq OWNED BY ml_app.role_description_history.id;


--
-- Name: role_descriptions; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.role_descriptions (
    id bigint NOT NULL,
    app_type_id bigint,
    role_name character varying,
    role_template character varying,
    name character varying,
    description character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: role_descriptions_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.role_descriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_descriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.role_descriptions_id_seq OWNED BY ml_app.role_descriptions.id;


--
-- Name: sage_assignments; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.sage_assignments (
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

CREATE SEQUENCE ml_app.sage_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sage_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.sage_assignments_id_seq OWNED BY ml_app.sage_assignments.id;


--
-- Name: scantron_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.scantron_history (
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

CREATE SEQUENCE ml_app.scantron_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantron_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.scantron_history_id_seq OWNED BY ml_app.scantron_history.id;


--
-- Name: scantrons; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.scantrons (
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

CREATE SEQUENCE ml_app.scantrons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantrons_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.scantrons_id_seq OWNED BY ml_app.scantrons.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.sessions (
    id bigint NOT NULL,
    session_id character varying NOT NULL,
    data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.sessions_id_seq OWNED BY ml_app.sessions.id;


--
-- Name: smback; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.smback (
    version character varying
);


--
-- Name: sub_process_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.sub_process_history (
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

CREATE SEQUENCE ml_app.sub_process_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_process_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.sub_process_history_id_seq OWNED BY ml_app.sub_process_history.id;


--
-- Name: sub_processes; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.sub_processes (
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

CREATE SEQUENCE ml_app.sub_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.sub_processes_id_seq OWNED BY ml_app.sub_processes.id;


--
-- Name: tracker_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.tracker_history (
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

CREATE SEQUENCE ml_app.tracker_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracker_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.tracker_history_id_seq OWNED BY ml_app.tracker_history.id;


--
-- Name: trackers; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.trackers (
    id integer NOT NULL,
    master_id integer,
    protocol_id integer NOT NULL,
    event_date timestamp without time zone,
    user_id integer DEFAULT ml_app.current_user_id(),
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

CREATE SEQUENCE ml_app.trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.trackers_id_seq OWNED BY ml_app.trackers.id;


--
-- Name: user_access_control_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.user_access_control_history (
    id integer NOT NULL,
    user_id bigint,
    resource_type character varying,
    resource_name character varying,
    options character varying,
    access character varying,
    app_type_id bigint,
    role_name character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_access_control_id integer
);


--
-- Name: user_access_control_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.user_access_control_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_access_control_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.user_access_control_history_id_seq OWNED BY ml_app.user_access_control_history.id;


--
-- Name: user_access_controls; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.user_access_controls (
    id integer NOT NULL,
    user_id integer,
    resource_type character varying,
    resource_name character varying,
    options character varying,
    access character varying,
    disabled boolean,
    admin_id integer,
    app_type_id integer,
    role_name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_access_controls_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.user_access_controls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_access_controls_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.user_access_controls_id_seq OWNED BY ml_app.user_access_controls.id;


--
-- Name: user_action_logs; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.user_action_logs (
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
-- Name: user_action_logs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.user_action_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_action_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.user_action_logs_id_seq OWNED BY ml_app.user_action_logs.id;


--
-- Name: user_authorization_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.user_authorization_history (
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

CREATE SEQUENCE ml_app.user_authorization_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_authorization_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.user_authorization_history_id_seq OWNED BY ml_app.user_authorization_history.id;


--
-- Name: user_authorizations; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.user_authorizations (
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

CREATE SEQUENCE ml_app.user_authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.user_authorizations_id_seq OWNED BY ml_app.user_authorizations.id;


--
-- Name: user_description_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.user_description_history (
    id bigint NOT NULL,
    user_description_id bigint,
    app_type_id bigint,
    role_name character varying,
    role_template character varying,
    name character varying,
    description character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_description_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.user_description_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_description_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.user_description_history_id_seq OWNED BY ml_app.user_description_history.id;


--
-- Name: user_descriptions; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.user_descriptions (
    id bigint NOT NULL,
    app_type_id bigint,
    role_name character varying,
    role_template character varying,
    name character varying,
    description character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_descriptions_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.user_descriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_descriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.user_descriptions_id_seq OWNED BY ml_app.user_descriptions.id;


--
-- Name: user_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.user_history (
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
    app_type_id integer,
    authentication_token character varying,
    encrypted_otp_secret character varying,
    encrypted_otp_secret_iv character varying,
    encrypted_otp_secret_salt character varying,
    consumed_timestep integer,
    otp_required_for_login boolean,
    password_updated_at timestamp without time zone,
    first_name character varying,
    last_name character varying,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone
);


--
-- Name: user_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.user_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.user_history_id_seq OWNED BY ml_app.user_history.id;


--
-- Name: user_preferences; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.user_preferences (
    id bigint NOT NULL,
    user_id bigint,
    date_format character varying,
    date_time_format character varying,
    pattern_for_date_format character varying,
    pattern_for_date_time_format character varying,
    pattern_for_time_format character varying,
    time_format character varying,
    timezone character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_preferences_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.user_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.user_preferences_id_seq OWNED BY ml_app.user_preferences.id;


--
-- Name: user_role_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.user_role_history (
    id integer NOT NULL,
    app_type_id bigint,
    role_name character varying,
    user_id bigint,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_role_id integer
);


--
-- Name: user_role_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.user_role_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_role_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.user_role_history_id_seq OWNED BY ml_app.user_role_history.id;


--
-- Name: user_roles; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.user_roles (
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
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.user_roles_id_seq OWNED BY ml_app.user_roles.id;


--
-- Name: users; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.users (
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
    authentication_token character varying(30),
    encrypted_otp_secret character varying,
    encrypted_otp_secret_iv character varying,
    encrypted_otp_secret_salt character varying,
    consumed_timestep integer,
    otp_required_for_login boolean,
    password_updated_at timestamp without time zone,
    first_name character varying,
    last_name character varying,
    do_not_email boolean DEFAULT false,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone
);


--
-- Name: users_contact_infos; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.users_contact_infos (
    id integer NOT NULL,
    user_id integer,
    sms_number character varying,
    phone_number character varying,
    alt_email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    admin_id integer,
    disabled boolean
);


--
-- Name: users_contact_infos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.users_contact_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_contact_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.users_contact_infos_id_seq OWNED BY ml_app.users_contact_infos.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.users_id_seq OWNED BY ml_app.users.id;


--
-- Name: view_users; Type: VIEW; Schema: ml_app; Owner: -
--

CREATE VIEW ml_app.view_users AS
 SELECT users.email,
    users.first_name,
    users.last_name,
    users.disabled
   FROM ml_app.users;


--
-- Name: viva_meta_variable_history; Type: TABLE; Schema: redcap; Owner: -
--

CREATE TABLE redcap.viva_meta_variable_history (
    id bigint NOT NULL,
    varname character varying,
    var_label character varying,
    var_type character varying,
    restrict_var___0 boolean,
    restrict_var___1 boolean,
    restrict_var___2 boolean,
    restrict_var___3 boolean,
    restrict_var___4 boolean,
    oth_restrict character varying,
    domain_viva character varying,
    subdomain___1 boolean,
    subdomain___2 boolean,
    target_of_q character varying,
    data_source character varying,
    val_instr character varying,
    ext_instrument character varying,
    internal_instrument character varying,
    doc_yn character varying,
    doc_link character varying,
    long_yn character varying,
    long_timepts___1 boolean,
    long_timepts___2 boolean,
    long_timepts___3 boolean,
    long_timepts___4 boolean,
    long_timepts___5 boolean,
    long_timepts___6 boolean,
    long_timepts___7 boolean,
    long_timepts___8 boolean,
    long_timepts___9 boolean,
    long_timepts___10 boolean,
    long_timepts___11 boolean,
    long_timepts___12 boolean,
    long_timepts___13 boolean,
    long_timepts___14 boolean,
    long_timepts___15 boolean,
    long_timepts___16 boolean,
    long_timepts___17 boolean,
    long_timepts___18 boolean,
    long_timepts___19 boolean,
    long_timepts___20 boolean,
    long_timepts___21 boolean,
    long_timepts___22 boolean,
    long_timepts___23 boolean,
    static_variable_information_complete integer,
    static_variable_information_timestamp timestamp without time zone,
    event_type character varying,
    visit_name character varying,
    visit_time character varying,
    assay_specimen character varying,
    assay_type character varying,
    lab_assay_dataset character varying,
    form_label_ep character varying,
    form_version_ep___1 boolean,
    form_version_ep___2 boolean,
    form_version_ep___3 boolean,
    form_version_ep___4 boolean,
    form_version_ep___5 boolean,
    form_version_ep___6 boolean,
    form_version_ep___7 boolean,
    form_version_ep___8 boolean,
    form_label_mp character varying,
    form_version_mp___1 boolean,
    form_version_mp___2 boolean,
    form_version_mp___3 boolean,
    form_version_mp___4 boolean,
    form_label_del character varying,
    form_version_del___1 boolean,
    form_version_del___2 boolean,
    form_version_del___3 boolean,
    form_version_del___4 boolean,
    form_version_del___5 boolean,
    form_version_del___6 boolean,
    form_version_del___7 boolean,
    form_label_6m character varying,
    form_version_6m___1 boolean,
    form_version_6m___2 boolean,
    form_version_6m___3 boolean,
    form_version_6m___4 boolean,
    form_version_6m___5 boolean,
    form_version_6m___6 boolean,
    form_version_6m___7 boolean,
    form_version_6m___8 boolean,
    form_version_6m___9 boolean,
    form_version_6m___10 boolean,
    form_label_1y character varying,
    form_version_1y___1 boolean,
    form_label_2y character varying,
    form_version_2y___1 boolean,
    form_label_3y character varying,
    form_version_3y___1 boolean,
    form_version_3y___2 boolean,
    form_version_3y___3 boolean,
    form_version_3y___4 boolean,
    form_version_3y___5 boolean,
    form_version_3y___6 boolean,
    form_version_3y___7 boolean,
    form_version_3y___8 boolean,
    form_version_3y___9 boolean,
    form_version_3y___10 boolean,
    form_version_3y___11 boolean,
    form_version_3y___12 boolean,
    form_version_3y___13 boolean,
    form_version_3y___14 boolean,
    form_label_4y character varying,
    form_version_4y___1 boolean,
    form_label_5y character varying,
    form_version_5y___1 boolean,
    form_label_6y character varying,
    form_version_6y___1 boolean,
    form_label_7y character varying,
    form_version_7y___1 boolean,
    form_version_7y___2 boolean,
    form_version_7y___3 boolean,
    form_version_7y___4 boolean,
    form_version_7y___5 boolean,
    form_version_7y___6 boolean,
    form_version_7y___7 boolean,
    form_version_7y___8 boolean,
    form_version_7y___9 boolean,
    form_version_7y___10 boolean,
    form_version_7y___11 boolean,
    form_version_7y___12 boolean,
    form_version_7y___13 boolean,
    form_version_7y___14 boolean,
    form_version_7y___15 boolean,
    form_version_7y___16 boolean,
    form_version_7y___17 boolean,
    form_label_8y character varying,
    form_version_8y___1 boolean,
    form_label_9y character varying,
    form_version_9y___1 boolean,
    form_version_9y___2 boolean,
    form_label_10y character varying,
    form_version_10y___1 boolean,
    form_version_10y___2 boolean,
    form_label_11y character varying,
    form_version_11y___1 boolean,
    form_version_11y___2 boolean,
    form_label_12y character varying,
    form_version_12y___1 boolean,
    form_version_12y___2 boolean,
    form_version_12y___3 boolean,
    form_version_12y___4 boolean,
    form_version_12y___5 boolean,
    form_version_12y___6 boolean,
    form_version_12y___7 boolean,
    form_version_12y___8 boolean,
    form_version_12y___9 boolean,
    form_version_12y___10 boolean,
    form_version_12y___11 boolean,
    form_version_12y___12 boolean,
    form_version_12y___13 boolean,
    form_version_12y___14 boolean,
    form_version_12y___15 boolean,
    form_version_12y___16 boolean,
    form_label_14y character varying,
    form_version_14y___1 boolean,
    form_version_14y___2 boolean,
    form_label_15y character varying,
    form_version_15y___1 boolean,
    form_version_15y___2 boolean,
    form_label_16y character varying,
    form_version_16y___1 boolean,
    form_version_16y___2 boolean,
    form_label_mt character varying,
    form_version_mt character varying,
    form_label_19y character varying,
    form_version_19y___1 boolean,
    form_version_19y___2 boolean,
    not_time_specific character varying,
    var_level character varying,
    units character varying,
    model_type character varying,
    response_options character varying,
    elig_sample character varying,
    elig_n character varying,
    actual_n character varying,
    an_var character varying,
    orig_deriv character varying,
    corr_derived_yn___0 boolean,
    corr_derived_yn___1 boolean,
    der_varname character varying,
    dervar_explain character varying,
    orig_varnames character varying,
    visitspecific_information_complete integer,
    visitspecific_information_timestamp timestamp without time zone,
    redcap_survey_identifier character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    viva_meta_variable_id bigint,
    redcap_repeat_instrument character varying,
    redcap_repeat_instance character varying
);


--
-- Name: viva_meta_variable_history_id_seq; Type: SEQUENCE; Schema: redcap; Owner: -
--

CREATE SEQUENCE redcap.viva_meta_variable_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva_meta_variable_history_id_seq; Type: SEQUENCE OWNED BY; Schema: redcap; Owner: -
--

ALTER SEQUENCE redcap.viva_meta_variable_history_id_seq OWNED BY redcap.viva_meta_variable_history.id;


--
-- Name: viva_meta_variables; Type: TABLE; Schema: redcap; Owner: -
--

CREATE TABLE redcap.viva_meta_variables (
    id bigint NOT NULL,
    varname character varying,
    var_label character varying,
    var_type character varying,
    restrict_var___0 boolean,
    restrict_var___1 boolean,
    restrict_var___2 boolean,
    restrict_var___3 boolean,
    restrict_var___4 boolean,
    oth_restrict character varying,
    domain_viva character varying,
    subdomain___1 boolean,
    subdomain___2 boolean,
    target_of_q character varying,
    data_source character varying,
    val_instr character varying,
    ext_instrument character varying,
    internal_instrument character varying,
    doc_yn character varying,
    doc_link character varying,
    long_yn character varying,
    long_timepts___1 boolean,
    long_timepts___2 boolean,
    long_timepts___3 boolean,
    long_timepts___4 boolean,
    long_timepts___5 boolean,
    long_timepts___6 boolean,
    long_timepts___7 boolean,
    long_timepts___8 boolean,
    long_timepts___9 boolean,
    long_timepts___10 boolean,
    long_timepts___11 boolean,
    long_timepts___12 boolean,
    long_timepts___13 boolean,
    long_timepts___14 boolean,
    long_timepts___15 boolean,
    long_timepts___16 boolean,
    long_timepts___17 boolean,
    long_timepts___18 boolean,
    long_timepts___19 boolean,
    long_timepts___20 boolean,
    long_timepts___21 boolean,
    long_timepts___22 boolean,
    long_timepts___23 boolean,
    static_variable_information_complete integer,
    static_variable_information_timestamp timestamp without time zone,
    event_type character varying,
    visit_name character varying,
    visit_time character varying,
    assay_specimen character varying,
    assay_type character varying,
    lab_assay_dataset character varying,
    form_label_ep character varying,
    form_version_ep___1 boolean,
    form_version_ep___2 boolean,
    form_version_ep___3 boolean,
    form_version_ep___4 boolean,
    form_version_ep___5 boolean,
    form_version_ep___6 boolean,
    form_version_ep___7 boolean,
    form_version_ep___8 boolean,
    form_label_mp character varying,
    form_version_mp___1 boolean,
    form_version_mp___2 boolean,
    form_version_mp___3 boolean,
    form_version_mp___4 boolean,
    form_label_del character varying,
    form_version_del___1 boolean,
    form_version_del___2 boolean,
    form_version_del___3 boolean,
    form_version_del___4 boolean,
    form_version_del___5 boolean,
    form_version_del___6 boolean,
    form_version_del___7 boolean,
    form_label_6m character varying,
    form_version_6m___1 boolean,
    form_version_6m___2 boolean,
    form_version_6m___3 boolean,
    form_version_6m___4 boolean,
    form_version_6m___5 boolean,
    form_version_6m___6 boolean,
    form_version_6m___7 boolean,
    form_version_6m___8 boolean,
    form_version_6m___9 boolean,
    form_version_6m___10 boolean,
    form_label_1y character varying,
    form_version_1y___1 boolean,
    form_label_2y character varying,
    form_version_2y___1 boolean,
    form_label_3y character varying,
    form_version_3y___1 boolean,
    form_version_3y___2 boolean,
    form_version_3y___3 boolean,
    form_version_3y___4 boolean,
    form_version_3y___5 boolean,
    form_version_3y___6 boolean,
    form_version_3y___7 boolean,
    form_version_3y___8 boolean,
    form_version_3y___9 boolean,
    form_version_3y___10 boolean,
    form_version_3y___11 boolean,
    form_version_3y___12 boolean,
    form_version_3y___13 boolean,
    form_version_3y___14 boolean,
    form_label_4y character varying,
    form_version_4y___1 boolean,
    form_label_5y character varying,
    form_version_5y___1 boolean,
    form_label_6y character varying,
    form_version_6y___1 boolean,
    form_label_7y character varying,
    form_version_7y___1 boolean,
    form_version_7y___2 boolean,
    form_version_7y___3 boolean,
    form_version_7y___4 boolean,
    form_version_7y___5 boolean,
    form_version_7y___6 boolean,
    form_version_7y___7 boolean,
    form_version_7y___8 boolean,
    form_version_7y___9 boolean,
    form_version_7y___10 boolean,
    form_version_7y___11 boolean,
    form_version_7y___12 boolean,
    form_version_7y___13 boolean,
    form_version_7y___14 boolean,
    form_version_7y___15 boolean,
    form_version_7y___16 boolean,
    form_version_7y___17 boolean,
    form_label_8y character varying,
    form_version_8y___1 boolean,
    form_label_9y character varying,
    form_version_9y___1 boolean,
    form_version_9y___2 boolean,
    form_label_10y character varying,
    form_version_10y___1 boolean,
    form_version_10y___2 boolean,
    form_label_11y character varying,
    form_version_11y___1 boolean,
    form_version_11y___2 boolean,
    form_label_12y character varying,
    form_version_12y___1 boolean,
    form_version_12y___2 boolean,
    form_version_12y___3 boolean,
    form_version_12y___4 boolean,
    form_version_12y___5 boolean,
    form_version_12y___6 boolean,
    form_version_12y___7 boolean,
    form_version_12y___8 boolean,
    form_version_12y___9 boolean,
    form_version_12y___10 boolean,
    form_version_12y___11 boolean,
    form_version_12y___12 boolean,
    form_version_12y___13 boolean,
    form_version_12y___14 boolean,
    form_version_12y___15 boolean,
    form_version_12y___16 boolean,
    form_label_14y character varying,
    form_version_14y___1 boolean,
    form_version_14y___2 boolean,
    form_label_15y character varying,
    form_version_15y___1 boolean,
    form_version_15y___2 boolean,
    form_label_16y character varying,
    form_version_16y___1 boolean,
    form_version_16y___2 boolean,
    form_label_mt character varying,
    form_version_mt character varying,
    form_label_19y character varying,
    form_version_19y___1 boolean,
    form_version_19y___2 boolean,
    not_time_specific character varying,
    var_level character varying,
    units character varying,
    model_type character varying,
    response_options character varying,
    elig_sample character varying,
    elig_n character varying,
    actual_n character varying,
    an_var character varying,
    orig_deriv character varying,
    corr_derived_yn___0 boolean,
    corr_derived_yn___1 boolean,
    der_varname character varying,
    dervar_explain character varying,
    orig_varnames character varying,
    visitspecific_information_complete integer,
    visitspecific_information_timestamp timestamp without time zone,
    redcap_survey_identifier character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    redcap_repeat_instrument character varying,
    redcap_repeat_instance character varying
);


--
-- Name: TABLE viva_meta_variables; Type: COMMENT; Schema: redcap; Owner: -
--

COMMENT ON TABLE redcap.viva_meta_variables IS 'Dynamicmodel: Viva Meta Variable';


--
-- Name: viva_meta_variables_id_seq; Type: SEQUENCE; Schema: redcap; Owner: -
--

CREATE SEQUENCE redcap.viva_meta_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva_meta_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: redcap; Owner: -
--

ALTER SEQUENCE redcap.viva_meta_variables_id_seq OWNED BY redcap.viva_meta_variables.id;


--
-- Name: datadic_choice_history; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.datadic_choice_history (
    id bigint NOT NULL,
    datadic_choice_id bigint,
    source_name character varying,
    source_type character varying,
    form_name character varying,
    field_name character varying,
    value character varying,
    label character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: datadic_choice_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.datadic_choice_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datadic_choice_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.datadic_choice_history_id_seq OWNED BY ref_data.datadic_choice_history.id;


--
-- Name: datadic_choices; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.datadic_choices (
    id bigint NOT NULL,
    source_name character varying,
    source_type character varying,
    form_name character varying,
    field_name character varying,
    value character varying,
    label character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: datadic_choices_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.datadic_choices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datadic_choices_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.datadic_choices_id_seq OWNED BY ref_data.datadic_choices.id;


--
-- Name: datadic_variable_history; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.datadic_variable_history (
    id bigint NOT NULL,
    datadic_variable_id bigint,
    study character varying,
    source_name character varying,
    source_type character varying,
    domain character varying,
    form_name character varying,
    variable_name character varying,
    variable_type character varying,
    presentation_type character varying,
    label character varying,
    label_note character varying,
    annotation character varying,
    is_required boolean,
    valid_type character varying,
    valid_min character varying,
    valid_max character varying,
    multi_valid_choices character varying[],
    is_identifier boolean,
    is_derived_var boolean,
    multi_derived_from_id bigint[],
    doc_url character varying,
    target_type character varying,
    owner_email character varying,
    classification character varying,
    other_classification character varying,
    multi_timepoints character varying[],
    equivalent_to_id bigint,
    storage_type character varying,
    db_or_fs character varying,
    schema_or_path character varying,
    table_or_file character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "position" integer,
    section_id integer,
    sub_section_id integer,
    title character varying,
    storage_varname character varying,
    contributor_type character varying,
    n_for_timepoints jsonb,
    notes character varying,
    user_id bigint
);


--
-- Name: COLUMN datadic_variable_history.study; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.study IS 'Study name';


--
-- Name: COLUMN datadic_variable_history.source_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.source_name IS 'Source of variable';


--
-- Name: COLUMN datadic_variable_history.source_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.source_type IS 'Source type';


--
-- Name: COLUMN datadic_variable_history.domain; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.domain IS 'Domain';


--
-- Name: COLUMN datadic_variable_history.form_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.form_name IS 'Form name (if the source was a type of form)';


--
-- Name: COLUMN datadic_variable_history.variable_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.variable_name IS 'Variable name';


--
-- Name: COLUMN datadic_variable_history.variable_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.variable_type IS 'Variable type';


--
-- Name: COLUMN datadic_variable_history.presentation_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.presentation_type IS 'Data type for presentation purposes';


--
-- Name: COLUMN datadic_variable_history.label; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.label IS 'Primary label or title (if source was a form, the label presented for the field)';


--
-- Name: COLUMN datadic_variable_history.label_note; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.label_note IS 'Description (if source was a form, a note presented for the field)';


--
-- Name: COLUMN datadic_variable_history.annotation; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.annotation IS 'Annotations (if source was a form, annotations not presented to the user)';


--
-- Name: COLUMN datadic_variable_history.is_required; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.is_required IS 'Was required in source';


--
-- Name: COLUMN datadic_variable_history.valid_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.valid_type IS 'Source data type';


--
-- Name: COLUMN datadic_variable_history.valid_min; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.valid_min IS 'Minimum value';


--
-- Name: COLUMN datadic_variable_history.valid_max; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.valid_max IS 'Maximum value';


--
-- Name: COLUMN datadic_variable_history.multi_valid_choices; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.multi_valid_choices IS 'List of valid choices for categorical variables';


--
-- Name: COLUMN datadic_variable_history.is_identifier; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.is_identifier IS 'Represents identifiable information';


--
-- Name: COLUMN datadic_variable_history.is_derived_var; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.is_derived_var IS 'Is a derived variable';


--
-- Name: COLUMN datadic_variable_history.multi_derived_from_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.multi_derived_from_id IS 'If a derived variable, ids of variables used to calculate it';


--
-- Name: COLUMN datadic_variable_history.doc_url; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.doc_url IS 'URL to additional documentation';


--
-- Name: COLUMN datadic_variable_history.target_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.target_type IS 'Type of participant this variable relates to';


--
-- Name: COLUMN datadic_variable_history.owner_email; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.owner_email IS 'Owner, especially for derived variables';


--
-- Name: COLUMN datadic_variable_history.classification; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.classification IS 'Category of sensitivity from a privacy perspective';


--
-- Name: COLUMN datadic_variable_history.other_classification; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.other_classification IS 'Additional information regarding classification';


--
-- Name: COLUMN datadic_variable_history.multi_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.multi_timepoints IS 'Timepoints this data is collected (in longitudinal studies)';


--
-- Name: COLUMN datadic_variable_history.equivalent_to_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.equivalent_to_id IS 'Primary variable id this is equivalent to';


--
-- Name: COLUMN datadic_variable_history.storage_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.storage_type IS 'Type of storage for dataset';


--
-- Name: COLUMN datadic_variable_history.db_or_fs; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.db_or_fs IS 'Database or Filesystem name';


--
-- Name: COLUMN datadic_variable_history.schema_or_path; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.schema_or_path IS 'Database schema or Filesystem directory path';


--
-- Name: COLUMN datadic_variable_history.table_or_file; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.table_or_file IS 'Database table (or view, if derived or equivalent to another variable), or filename in directory';


--
-- Name: COLUMN datadic_variable_history.redcap_data_dictionary_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.redcap_data_dictionary_id IS 'Reference to REDCap data dictionary representation';


--
-- Name: COLUMN datadic_variable_history."position"; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history."position" IS 'Relative position (for source forms or other variables where order of collection matters)';


--
-- Name: COLUMN datadic_variable_history.section_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.section_id IS 'Section this belongs to';


--
-- Name: COLUMN datadic_variable_history.sub_section_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.sub_section_id IS 'Sub-section this belongs to';


--
-- Name: COLUMN datadic_variable_history.title; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.title IS 'Section caption';


--
-- Name: COLUMN datadic_variable_history.storage_varname; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.storage_varname IS 'Database field name, or variable name in data file';


--
-- Name: COLUMN datadic_variable_history.contributor_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.contributor_type IS 'Type of contributor this variable was provided by';


--
-- Name: COLUMN datadic_variable_history.n_for_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.n_for_timepoints IS 'For each named timepoint (name:), the population or count of responses (n:), with notes (notes:)';


--
-- Name: COLUMN datadic_variable_history.notes; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.notes IS 'Notes';


--
-- Name: datadic_variable_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.datadic_variable_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datadic_variable_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.datadic_variable_history_id_seq OWNED BY ref_data.datadic_variable_history.id;


--
-- Name: datadic_variables; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.datadic_variables (
    id bigint NOT NULL,
    study character varying,
    source_name character varying,
    source_type character varying,
    domain character varying,
    form_name character varying,
    variable_name character varying,
    variable_type character varying,
    presentation_type character varying,
    label character varying,
    label_note character varying,
    annotation character varying,
    is_required boolean,
    valid_type character varying,
    valid_min character varying,
    valid_max character varying,
    multi_valid_choices character varying[],
    is_identifier boolean,
    is_derived_var boolean,
    multi_derived_from_id bigint[],
    doc_url character varying,
    target_type character varying,
    owner_email character varying,
    classification character varying,
    other_classification character varying,
    multi_timepoints character varying[],
    equivalent_to_id bigint,
    storage_type character varying,
    db_or_fs character varying,
    schema_or_path character varying,
    table_or_file character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "position" integer,
    section_id integer,
    sub_section_id integer,
    title character varying,
    storage_varname character varying,
    user_id bigint,
    contributor_type character varying,
    n_for_timepoints jsonb,
    notes character varying
);


--
-- Name: TABLE datadic_variables; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON TABLE ref_data.datadic_variables IS 'Dynamicmodel: User Variables';


--
-- Name: COLUMN datadic_variables.study; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.study IS 'Study name';


--
-- Name: COLUMN datadic_variables.source_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.source_name IS 'Source of variable';


--
-- Name: COLUMN datadic_variables.source_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.source_type IS 'Source type';


--
-- Name: COLUMN datadic_variables.domain; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.domain IS 'Domain';


--
-- Name: COLUMN datadic_variables.form_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.form_name IS 'Form name (if the source was a type of form)';


--
-- Name: COLUMN datadic_variables.variable_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.variable_name IS 'Variable name';


--
-- Name: COLUMN datadic_variables.variable_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.variable_type IS 'Variable type';


--
-- Name: COLUMN datadic_variables.presentation_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.presentation_type IS 'Data type for presentation purposes';


--
-- Name: COLUMN datadic_variables.label; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.label IS 'Primary label or title (if source was a form, the label presented for the field)';


--
-- Name: COLUMN datadic_variables.label_note; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.label_note IS 'Description (if source was a form, a note presented for the field)';


--
-- Name: COLUMN datadic_variables.annotation; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.annotation IS 'Annotations (if source was a form, annotations not presented to the user)';


--
-- Name: COLUMN datadic_variables.is_required; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.is_required IS 'Was required in source';


--
-- Name: COLUMN datadic_variables.valid_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.valid_type IS 'Source data type';


--
-- Name: COLUMN datadic_variables.valid_min; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.valid_min IS 'Minimum value';


--
-- Name: COLUMN datadic_variables.valid_max; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.valid_max IS 'Maximum value';


--
-- Name: COLUMN datadic_variables.multi_valid_choices; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.multi_valid_choices IS 'List of valid choices for categorical variables';


--
-- Name: COLUMN datadic_variables.is_identifier; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.is_identifier IS 'Represents identifiable information';


--
-- Name: COLUMN datadic_variables.is_derived_var; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.is_derived_var IS 'Is a derived variable';


--
-- Name: COLUMN datadic_variables.multi_derived_from_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.multi_derived_from_id IS 'If a derived variable, ids of variables used to calculate it';


--
-- Name: COLUMN datadic_variables.doc_url; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.doc_url IS 'URL to additional documentation';


--
-- Name: COLUMN datadic_variables.target_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.target_type IS 'Type of participant this variable relates to';


--
-- Name: COLUMN datadic_variables.owner_email; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.owner_email IS 'Owner, especially for derived variables';


--
-- Name: COLUMN datadic_variables.classification; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.classification IS 'Category of sensitivity from a privacy perspective';


--
-- Name: COLUMN datadic_variables.other_classification; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.other_classification IS 'Additional information regarding classification';


--
-- Name: COLUMN datadic_variables.multi_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.multi_timepoints IS 'Timepoints this data is collected (in longitudinal studies)';


--
-- Name: COLUMN datadic_variables.equivalent_to_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.equivalent_to_id IS 'Primary variable id this is equivalent to';


--
-- Name: COLUMN datadic_variables.storage_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.storage_type IS 'Type of storage for dataset';


--
-- Name: COLUMN datadic_variables.db_or_fs; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.db_or_fs IS 'Database or Filesystem name';


--
-- Name: COLUMN datadic_variables.schema_or_path; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.schema_or_path IS 'Database schema or Filesystem directory path';


--
-- Name: COLUMN datadic_variables.table_or_file; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.table_or_file IS 'Database table (or view, if derived or equivalent to another variable), or filename in directory';


--
-- Name: COLUMN datadic_variables.redcap_data_dictionary_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.redcap_data_dictionary_id IS 'Reference to REDCap data dictionary representation';


--
-- Name: COLUMN datadic_variables."position"; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables."position" IS 'Relative position (for source forms or other variables where order of collection matters)';


--
-- Name: COLUMN datadic_variables.section_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.section_id IS 'Section this belongs to';


--
-- Name: COLUMN datadic_variables.sub_section_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.sub_section_id IS 'Sub-section this belongs to';


--
-- Name: COLUMN datadic_variables.title; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.title IS 'Section caption';


--
-- Name: COLUMN datadic_variables.storage_varname; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.storage_varname IS 'Database field name, or variable name in data file';


--
-- Name: COLUMN datadic_variables.contributor_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.contributor_type IS 'Type of contributor this variable was provided by';


--
-- Name: COLUMN datadic_variables.n_for_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.n_for_timepoints IS 'For each named timepoint (name:), the population or count of responses (n:), with notes (notes:)';


--
-- Name: COLUMN datadic_variables.notes; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.notes IS 'Notes';


--
-- Name: datadic_variables_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.datadic_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datadic_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.datadic_variables_id_seq OWNED BY ref_data.datadic_variables.id;


--
-- Name: redcap_client_requests; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_client_requests (
    id bigint NOT NULL,
    redcap_project_admin_id bigint,
    action character varying,
    name character varying,
    server_url character varying,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    result jsonb
);


--
-- Name: TABLE redcap_client_requests; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON TABLE ref_data.redcap_client_requests IS 'Redcap client requests';


--
-- Name: redcap_client_requests_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_client_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_client_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_client_requests_id_seq OWNED BY ref_data.redcap_client_requests.id;


--
-- Name: redcap_data_collection_instrument_history; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_data_collection_instrument_history (
    id bigint NOT NULL,
    redcap_data_collection_instrument_id bigint,
    redcap_project_admin_id bigint,
    name character varying,
    label character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: redcap_data_collection_instrument_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_data_collection_instrument_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_data_collection_instrument_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_data_collection_instrument_history_id_seq OWNED BY ref_data.redcap_data_collection_instrument_history.id;


--
-- Name: redcap_data_collection_instruments; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_data_collection_instruments (
    id bigint NOT NULL,
    name character varying,
    label character varying,
    disabled boolean,
    redcap_project_admin_id bigint,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: redcap_data_collection_instruments_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_data_collection_instruments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_data_collection_instruments_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_data_collection_instruments_id_seq OWNED BY ref_data.redcap_data_collection_instruments.id;


--
-- Name: redcap_data_dictionaries; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_data_dictionaries (
    id bigint NOT NULL,
    redcap_project_admin_id bigint,
    field_count integer,
    captured_metadata jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE redcap_data_dictionaries; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON TABLE ref_data.redcap_data_dictionaries IS 'Retrieved Redcap Data Dictionaries (metadata)';


--
-- Name: redcap_data_dictionaries_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_data_dictionaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_data_dictionaries_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_data_dictionaries_id_seq OWNED BY ref_data.redcap_data_dictionaries.id;


--
-- Name: redcap_data_dictionary_history; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_data_dictionary_history (
    id bigint NOT NULL,
    redcap_data_dictionary_id bigint,
    redcap_project_admin_id bigint,
    field_count integer,
    captured_metadata jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE redcap_data_dictionary_history; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON TABLE ref_data.redcap_data_dictionary_history IS 'Retrieved Redcap Data Dictionaries (metadata) - history';


--
-- Name: redcap_data_dictionary_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_data_dictionary_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_data_dictionary_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_data_dictionary_history_id_seq OWNED BY ref_data.redcap_data_dictionary_history.id;


--
-- Name: redcap_project_admin_history; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_project_admin_history (
    id bigint NOT NULL,
    redcap_project_admin_id bigint,
    name character varying,
    api_key character varying,
    server_url character varying,
    captured_project_info jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    transfer_mode character varying,
    frequency character varying,
    status character varying,
    post_transfer_pipeline character varying[] DEFAULT '{}'::character varying[],
    notes character varying,
    study character varying,
    dynamic_model_table character varying
);


--
-- Name: TABLE redcap_project_admin_history; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON TABLE ref_data.redcap_project_admin_history IS 'Redcap project administration - history';


--
-- Name: redcap_project_admin_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_project_admin_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_project_admin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_project_admin_history_id_seq OWNED BY ref_data.redcap_project_admin_history.id;


--
-- Name: redcap_project_admins; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_project_admins (
    id bigint NOT NULL,
    name character varying,
    api_key character varying,
    server_url character varying,
    captured_project_info jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    transfer_mode character varying,
    frequency character varying,
    status character varying,
    post_transfer_pipeline character varying[] DEFAULT '{}'::character varying[],
    notes character varying,
    study character varying,
    dynamic_model_table character varying,
    options character varying
);


--
-- Name: TABLE redcap_project_admins; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON TABLE ref_data.redcap_project_admins IS 'Redcap project administration';


--
-- Name: redcap_project_admins_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_project_admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_project_admins_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_project_admins_id_seq OWNED BY ref_data.redcap_project_admins.id;


--
-- Name: redcap_project_user_history; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_project_user_history (
    id bigint NOT NULL,
    redcap_project_user_id bigint,
    redcap_project_admin_id bigint,
    username character varying,
    email character varying,
    expiration character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: redcap_project_user_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_project_user_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_project_user_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_project_user_history_id_seq OWNED BY ref_data.redcap_project_user_history.id;


--
-- Name: redcap_project_users; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_project_users (
    id bigint NOT NULL,
    redcap_project_admin_id bigint,
    username character varying,
    email character varying,
    expiration character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: redcap_project_users_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_project_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_project_users_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_project_users_id_seq OWNED BY ref_data.redcap_project_users.id;


--
-- Name: activity_log_study_info_part_history; Type: TABLE; Schema: study_info; Owner: -
--

CREATE TABLE study_info.activity_log_study_info_part_history (
    id bigint NOT NULL,
    master_id bigint,
    study_info_part_id bigint,
    title character varying,
    description character varying,
    default_layout character varying,
    slug character varying,
    tag_select_allow_roles_access character varying[],
    footer character varying,
    position_number integer,
    extra_classes character varying,
    notes character varying,
    extra_log_type character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_study_info_part_id bigint,
    tag_select_page_tags character varying[],
    disabled boolean DEFAULT false
);


--
-- Name: activity_log_study_info_part_history_id_seq; Type: SEQUENCE; Schema: study_info; Owner: -
--

CREATE SEQUENCE study_info.activity_log_study_info_part_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_study_info_part_history_id_seq; Type: SEQUENCE OWNED BY; Schema: study_info; Owner: -
--

ALTER SEQUENCE study_info.activity_log_study_info_part_history_id_seq OWNED BY study_info.activity_log_study_info_part_history.id;


--
-- Name: activity_log_study_info_parts; Type: TABLE; Schema: study_info; Owner: -
--

CREATE TABLE study_info.activity_log_study_info_parts (
    id bigint NOT NULL,
    master_id bigint,
    study_info_part_id bigint,
    title character varying,
    description character varying,
    default_layout character varying,
    slug character varying,
    tag_select_allow_roles_access character varying[],
    footer character varying,
    position_number integer,
    extra_classes character varying,
    notes character varying,
    extra_log_type character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tag_select_page_tags character varying[],
    disabled boolean DEFAULT false
);


--
-- Name: TABLE activity_log_study_info_parts; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON TABLE study_info.activity_log_study_info_parts IS 'Activitylog: Study Info Page';


--
-- Name: activity_log_study_info_parts_id_seq; Type: SEQUENCE; Schema: study_info; Owner: -
--

CREATE SEQUENCE study_info.activity_log_study_info_parts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_study_info_parts_id_seq; Type: SEQUENCE OWNED BY; Schema: study_info; Owner: -
--

ALTER SEQUENCE study_info.activity_log_study_info_parts_id_seq OWNED BY study_info.activity_log_study_info_parts.id;


--
-- Name: activity_log_view_user_data_user_proc_history; Type: TABLE; Schema: study_info; Owner: -
--

CREATE TABLE study_info.activity_log_view_user_data_user_proc_history (
    id bigint NOT NULL,
    master_id bigint,
    view_user_id integer,
    is_complete boolean,
    confirmed_read_terms_yes_no character varying,
    extra_log_type character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_view_user_data_user_proc_id bigint
);


--
-- Name: activity_log_view_user_data_user_proc_history_id_seq; Type: SEQUENCE; Schema: study_info; Owner: -
--

CREATE SEQUENCE study_info.activity_log_view_user_data_user_proc_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_view_user_data_user_proc_history_id_seq; Type: SEQUENCE OWNED BY; Schema: study_info; Owner: -
--

ALTER SEQUENCE study_info.activity_log_view_user_data_user_proc_history_id_seq OWNED BY study_info.activity_log_view_user_data_user_proc_history.id;


--
-- Name: activity_log_view_user_data_user_procs; Type: TABLE; Schema: study_info; Owner: -
--

CREATE TABLE study_info.activity_log_view_user_data_user_procs (
    id bigint NOT NULL,
    master_id bigint,
    view_user_id integer,
    is_complete boolean,
    confirmed_read_terms_yes_no character varying,
    extra_log_type character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE activity_log_view_user_data_user_procs; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON TABLE study_info.activity_log_view_user_data_user_procs IS 'Activitylog: Data User Process';


--
-- Name: activity_log_view_user_data_user_procs_id_seq; Type: SEQUENCE; Schema: study_info; Owner: -
--

CREATE SEQUENCE study_info.activity_log_view_user_data_user_procs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_view_user_data_user_procs_id_seq; Type: SEQUENCE OWNED BY; Schema: study_info; Owner: -
--

ALTER SEQUENCE study_info.activity_log_view_user_data_user_procs_id_seq OWNED BY study_info.activity_log_view_user_data_user_procs.id;


--
-- Name: al_study_info_parts_from_al_study_info_parts; Type: VIEW; Schema: study_info; Owner: -
--

CREATE VIEW study_info.al_study_info_parts_from_al_study_info_parts AS
 SELECT dest.id,
    dest.master_id,
    dest.study_info_part_id,
    dest.title,
    dest.description,
    dest.default_layout,
    dest.slug,
    dest.tag_select_allow_roles_access,
    dest.footer,
    dest.position_number,
    dest.extra_classes,
    dest.notes,
    dest.extra_log_type,
    dest.user_id,
    dest.created_at,
    dest.updated_at,
    dest.tag_select_page_tags,
    dest.disabled,
    mr.from_record_master_id,
    mr.from_record_type,
    mr.from_record_id,
    mr.id AS model_reference_id,
    'study_info.activity_log_study_info_parts'::character varying AS from_table
   FROM (study_info.activity_log_study_info_parts dest
     JOIN ml_app.model_references mr ON (((dest.id = mr.to_record_id) AND (dest.master_id = mr.to_record_master_id) AND (NOT COALESCE(mr.disabled, false)) AND ((mr.from_record_type)::text = 'ActivityLog::StudyInfoPart'::text) AND ((mr.to_record_type)::text = 'ActivityLog::StudyInfoPart'::text))));


--
-- Name: nfs_store_containers_from_al_study_info_parts; Type: VIEW; Schema: study_info; Owner: -
--

CREATE VIEW study_info.nfs_store_containers_from_al_study_info_parts AS
 SELECT dest.id,
    dest.name,
    dest.user_id,
    dest.app_type_id,
    dest.nfs_store_container_id,
    dest.master_id,
    dest.created_at,
    dest.updated_at,
    mr.from_record_master_id,
    mr.from_record_type,
    mr.from_record_id,
    mr.id AS model_reference_id,
    'nfs_store_containers'::character varying AS from_table
   FROM (ml_app.nfs_store_containers dest
     JOIN ml_app.model_references mr ON (((dest.id = mr.to_record_id) AND (dest.master_id = mr.to_record_master_id) AND (NOT COALESCE(mr.disabled, false)) AND ((mr.from_record_type)::text = 'ActivityLog::StudyInfoPart'::text) AND ((mr.to_record_type)::text = 'NfsStore::Manage::Container'::text))));


--
-- Name: study_common_section_history; Type: TABLE; Schema: study_info; Owner: -
--

CREATE TABLE study_info.study_common_section_history (
    id bigint NOT NULL,
    title character varying,
    content character varying,
    position_number integer,
    block_width character varying,
    extra_classes character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    study_common_section_id bigint
);


--
-- Name: COLUMN study_common_section_history.title; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_common_section_history.title IS 'Title';


--
-- Name: COLUMN study_common_section_history.content; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_common_section_history.content IS 'Content';


--
-- Name: COLUMN study_common_section_history.position_number; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_common_section_history.position_number IS 'Position';


--
-- Name: COLUMN study_common_section_history.block_width; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_common_section_history.block_width IS 'Width';


--
-- Name: COLUMN study_common_section_history.extra_classes; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_common_section_history.extra_classes IS 'Extra CSS classes';


--
-- Name: study_common_section_history_id_seq; Type: SEQUENCE; Schema: study_info; Owner: -
--

CREATE SEQUENCE study_info.study_common_section_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: study_common_section_history_id_seq; Type: SEQUENCE OWNED BY; Schema: study_info; Owner: -
--

ALTER SEQUENCE study_info.study_common_section_history_id_seq OWNED BY study_info.study_common_section_history.id;


--
-- Name: study_common_sections; Type: TABLE; Schema: study_info; Owner: -
--

CREATE TABLE study_info.study_common_sections (
    id bigint NOT NULL,
    title character varying,
    content character varying,
    position_number integer,
    block_width character varying,
    extra_classes character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE study_common_sections; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON TABLE study_info.study_common_sections IS 'Dynamicmodel: Common Section';


--
-- Name: COLUMN study_common_sections.title; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_common_sections.title IS 'Title';


--
-- Name: COLUMN study_common_sections.content; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_common_sections.content IS 'Content';


--
-- Name: COLUMN study_common_sections.position_number; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_common_sections.position_number IS 'Position';


--
-- Name: COLUMN study_common_sections.block_width; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_common_sections.block_width IS 'Width';


--
-- Name: COLUMN study_common_sections.extra_classes; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_common_sections.extra_classes IS 'Extra CSS classes';


--
-- Name: study_common_sections_from_al_study_info_parts; Type: VIEW; Schema: study_info; Owner: -
--

CREATE VIEW study_info.study_common_sections_from_al_study_info_parts AS
 SELECT dest.id,
    dest.title,
    dest.content,
    dest.position_number,
    dest.block_width,
    dest.extra_classes,
    dest.user_id,
    dest.created_at,
    dest.updated_at,
    mr.from_record_master_id,
    mr.from_record_type,
    mr.from_record_id,
    mr.id AS model_reference_id,
    'study_info.study_common_sections'::character varying AS from_table
   FROM (study_info.study_common_sections dest
     JOIN ml_app.model_references mr ON (((dest.id = mr.to_record_id) AND (NOT COALESCE(mr.disabled, false)) AND ((mr.from_record_type)::text = 'ActivityLog::StudyInfoPart'::text) AND ((mr.to_record_type)::text = 'DynamicModel::StudyCommonSection'::text))));


--
-- Name: study_common_sections_id_seq; Type: SEQUENCE; Schema: study_info; Owner: -
--

CREATE SEQUENCE study_info.study_common_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: study_common_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: study_info; Owner: -
--

ALTER SEQUENCE study_info.study_common_sections_id_seq OWNED BY study_info.study_common_sections.id;


--
-- Name: study_info_part_history; Type: TABLE; Schema: study_info; Owner: -
--

CREATE TABLE study_info.study_info_part_history (
    id bigint NOT NULL,
    master_id bigint,
    study_info_id character varying,
    user_id bigint,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    study_info_part_table_id bigint
);


--
-- Name: COLUMN study_info_part_history.study_info_id; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_info_part_history.study_info_id IS 'Part Name';


--
-- Name: study_info_part_history_id_seq; Type: SEQUENCE; Schema: study_info; Owner: -
--

CREATE SEQUENCE study_info.study_info_part_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: study_info_part_history_id_seq; Type: SEQUENCE OWNED BY; Schema: study_info; Owner: -
--

ALTER SEQUENCE study_info.study_info_part_history_id_seq OWNED BY study_info.study_info_part_history.id;


--
-- Name: study_info_parts; Type: TABLE; Schema: study_info; Owner: -
--

CREATE TABLE study_info.study_info_parts (
    id bigint NOT NULL,
    master_id bigint,
    study_info_id character varying,
    user_id bigint,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE study_info_parts; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON TABLE study_info.study_info_parts IS 'Externalidentifier: Study Info Parts';


--
-- Name: COLUMN study_info_parts.study_info_id; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_info_parts.study_info_id IS 'Part Name';


--
-- Name: study_info_parts_id_seq; Type: SEQUENCE; Schema: study_info; Owner: -
--

CREATE SEQUENCE study_info.study_info_parts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: study_info_parts_id_seq; Type: SEQUENCE OWNED BY; Schema: study_info; Owner: -
--

ALTER SEQUENCE study_info.study_info_parts_id_seq OWNED BY study_info.study_info_parts.id;


--
-- Name: study_page_section_history; Type: TABLE; Schema: study_info; Owner: -
--

CREATE TABLE study_info.study_page_section_history (
    id bigint NOT NULL,
    master_id bigint,
    title character varying,
    content character varying,
    position_number integer,
    block_width character varying,
    extra_classes character varying,
    tag_select_allow_roles_access character varying[],
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    study_page_section_id bigint,
    disabled boolean DEFAULT false
);


--
-- Name: COLUMN study_page_section_history.title; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_section_history.title IS 'Title';


--
-- Name: COLUMN study_page_section_history.content; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_section_history.content IS 'Content';


--
-- Name: COLUMN study_page_section_history.position_number; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_section_history.position_number IS 'Position';


--
-- Name: COLUMN study_page_section_history.block_width; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_section_history.block_width IS 'Width';


--
-- Name: COLUMN study_page_section_history.extra_classes; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_section_history.extra_classes IS 'Extra CSS classes';


--
-- Name: COLUMN study_page_section_history.tag_select_allow_roles_access; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_section_history.tag_select_allow_roles_access IS 'Allow Roles Access';


--
-- Name: study_page_section_history_id_seq; Type: SEQUENCE; Schema: study_info; Owner: -
--

CREATE SEQUENCE study_info.study_page_section_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: study_page_section_history_id_seq; Type: SEQUENCE OWNED BY; Schema: study_info; Owner: -
--

ALTER SEQUENCE study_info.study_page_section_history_id_seq OWNED BY study_info.study_page_section_history.id;


--
-- Name: study_page_sections; Type: TABLE; Schema: study_info; Owner: -
--

CREATE TABLE study_info.study_page_sections (
    id bigint NOT NULL,
    master_id bigint,
    title character varying,
    content character varying,
    position_number integer,
    block_width character varying,
    extra_classes character varying,
    tag_select_allow_roles_access character varying[],
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean DEFAULT false
);


--
-- Name: TABLE study_page_sections; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON TABLE study_info.study_page_sections IS 'Dynamicmodel: Page Section';


--
-- Name: COLUMN study_page_sections.title; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_sections.title IS 'Title';


--
-- Name: COLUMN study_page_sections.content; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_sections.content IS 'Content';


--
-- Name: COLUMN study_page_sections.position_number; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_sections.position_number IS 'Position';


--
-- Name: COLUMN study_page_sections.block_width; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_sections.block_width IS 'Width';


--
-- Name: COLUMN study_page_sections.extra_classes; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_sections.extra_classes IS 'Extra CSS classes';


--
-- Name: COLUMN study_page_sections.tag_select_allow_roles_access; Type: COMMENT; Schema: study_info; Owner: -
--

COMMENT ON COLUMN study_info.study_page_sections.tag_select_allow_roles_access IS 'Allow Roles Access';


--
-- Name: study_page_sections_from_al_study_info_parts; Type: VIEW; Schema: study_info; Owner: -
--

CREATE VIEW study_info.study_page_sections_from_al_study_info_parts AS
 SELECT dest.id,
    dest.master_id,
    dest.title,
    dest.content,
    dest.position_number,
    dest.block_width,
    dest.extra_classes,
    dest.tag_select_allow_roles_access,
    dest.user_id,
    dest.created_at,
    dest.updated_at,
    mr.from_record_master_id,
    mr.from_record_type,
    mr.from_record_id,
    mr.id AS model_reference_id,
    'study_info.study_page_sections'::character varying AS from_table
   FROM (study_info.study_page_sections dest
     JOIN ml_app.model_references mr ON (((dest.id = mr.to_record_id) AND (dest.master_id = mr.to_record_master_id) AND (NOT COALESCE(mr.disabled, false)) AND ((mr.from_record_type)::text = 'ActivityLog::StudyInfoPart'::text) AND ((mr.to_record_type)::text = 'DynamicModel::StudyPageSection'::text))));


--
-- Name: study_page_sections_id_seq; Type: SEQUENCE; Schema: study_info; Owner: -
--

CREATE SEQUENCE study_info.study_page_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: study_page_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: study_info; Owner: -
--

ALTER SEQUENCE study_info.study_page_sections_id_seq OWNED BY study_info.study_page_sections.id;


--
-- Name: viva2_rc_history; Type: TABLE; Schema: viva_ref_info; Owner: -
--

CREATE TABLE viva_ref_info.viva2_rc_history (
    id bigint NOT NULL,
    varname character varying,
    var_label character varying,
    var_type character varying,
    restrict_var___0 boolean,
    restrict_var___1 boolean,
    restrict_var___2 boolean,
    restrict_var___3 boolean,
    restrict_var___4 boolean,
    oth_restrict character varying,
    domain_viva character varying,
    subdomain___1 boolean,
    subdomain___2 boolean,
    target_of_q character varying,
    data_source character varying,
    val_instr character varying,
    ext_instrument character varying,
    internal_instrument character varying,
    doc_yn character varying,
    doc_link character varying,
    long_yn character varying,
    long_timepts___1 boolean,
    long_timepts___2 boolean,
    long_timepts___3 boolean,
    long_timepts___4 boolean,
    long_timepts___5 boolean,
    long_timepts___6 boolean,
    long_timepts___7 boolean,
    long_timepts___8 boolean,
    long_timepts___9 boolean,
    long_timepts___10 boolean,
    long_timepts___11 boolean,
    long_timepts___12 boolean,
    long_timepts___13 boolean,
    long_timepts___14 boolean,
    long_timepts___15 boolean,
    long_timepts___16 boolean,
    long_timepts___17 boolean,
    long_timepts___18 boolean,
    long_timepts___19 boolean,
    long_timepts___20 boolean,
    long_timepts___21 boolean,
    long_timepts___22 boolean,
    long_timepts___23 boolean,
    static_variable_information_complete integer,
    event_type character varying,
    visit_name character varying,
    visit_time character varying,
    assay_specimen character varying,
    assay_type character varying,
    lab_assay_dataset character varying,
    form_label_ep character varying,
    form_version_ep___1 boolean,
    form_version_ep___2 boolean,
    form_version_ep___3 boolean,
    form_version_ep___4 boolean,
    form_version_ep___5 boolean,
    form_version_ep___6 boolean,
    form_version_ep___7 boolean,
    form_version_ep___8 boolean,
    form_label_mp character varying,
    form_version_mp___1 boolean,
    form_version_mp___2 boolean,
    form_version_mp___3 boolean,
    form_version_mp___4 boolean,
    form_label_del character varying,
    form_version_del___1 boolean,
    form_version_del___2 boolean,
    form_version_del___3 boolean,
    form_version_del___4 boolean,
    form_version_del___5 boolean,
    form_version_del___6 boolean,
    form_version_del___7 boolean,
    form_label_6m character varying,
    form_version_6m___1 boolean,
    form_version_6m___2 boolean,
    form_version_6m___3 boolean,
    form_version_6m___4 boolean,
    form_version_6m___5 boolean,
    form_version_6m___6 boolean,
    form_version_6m___7 boolean,
    form_version_6m___8 boolean,
    form_version_6m___9 boolean,
    form_version_6m___10 boolean,
    form_label_1y character varying,
    form_version_1y___1 boolean,
    form_label_2y character varying,
    form_version_2y___1 boolean,
    form_label_3y character varying,
    form_version_3y___1 boolean,
    form_version_3y___2 boolean,
    form_version_3y___3 boolean,
    form_version_3y___4 boolean,
    form_version_3y___5 boolean,
    form_version_3y___6 boolean,
    form_version_3y___7 boolean,
    form_version_3y___8 boolean,
    form_version_3y___9 boolean,
    form_version_3y___10 boolean,
    form_version_3y___11 boolean,
    form_version_3y___12 boolean,
    form_version_3y___13 boolean,
    form_version_3y___14 boolean,
    form_label_4y character varying,
    form_version_4y___1 boolean,
    form_label_5y character varying,
    form_version_5y___1 boolean,
    form_label_6y character varying,
    form_version_6y___1 boolean,
    form_label_7y character varying,
    form_version_7y___1 boolean,
    form_version_7y___2 boolean,
    form_version_7y___3 boolean,
    form_version_7y___4 boolean,
    form_version_7y___5 boolean,
    form_version_7y___6 boolean,
    form_version_7y___7 boolean,
    form_version_7y___8 boolean,
    form_version_7y___9 boolean,
    form_version_7y___10 boolean,
    form_version_7y___11 boolean,
    form_version_7y___12 boolean,
    form_version_7y___13 boolean,
    form_version_7y___14 boolean,
    form_version_7y___15 boolean,
    form_version_7y___16 boolean,
    form_version_7y___17 boolean,
    form_label_8y character varying,
    form_version_8y___1 boolean,
    form_label_9y character varying,
    form_version_9y___1 boolean,
    form_version_9y___2 boolean,
    form_label_10y character varying,
    form_version_10y___1 boolean,
    form_version_10y___2 boolean,
    form_label_11y character varying,
    form_version_11y___1 boolean,
    form_version_11y___2 boolean,
    form_label_12y character varying,
    form_version_12y___1 boolean,
    form_version_12y___2 boolean,
    form_version_12y___3 boolean,
    form_version_12y___4 boolean,
    form_version_12y___5 boolean,
    form_version_12y___6 boolean,
    form_version_12y___7 boolean,
    form_version_12y___8 boolean,
    form_version_12y___9 boolean,
    form_version_12y___10 boolean,
    form_version_12y___11 boolean,
    form_version_12y___12 boolean,
    form_version_12y___13 boolean,
    form_version_12y___14 boolean,
    form_version_12y___15 boolean,
    form_version_12y___16 boolean,
    form_label_14y character varying,
    form_version_14y___1 boolean,
    form_version_14y___2 boolean,
    form_label_15y character varying,
    form_version_15y___1 boolean,
    form_version_15y___2 boolean,
    form_label_16y character varying,
    form_version_16y___1 boolean,
    form_version_16y___2 boolean,
    form_label_mt character varying,
    form_version_mt character varying,
    form_label_19y character varying,
    form_version_19y___1 boolean,
    form_version_19y___2 boolean,
    not_time_specific character varying,
    var_level character varying,
    units character varying,
    model_type character varying,
    response_options character varying,
    elig_sample character varying,
    elig_n character varying,
    actual_n character varying,
    an_var character varying,
    orig_deriv character varying,
    corr_derived_yn___0 boolean,
    corr_derived_yn___1 boolean,
    der_varname character varying,
    dervar_explain character varying,
    orig_varnames character varying,
    visitspecific_information_complete integer,
    redcap_repeat_instrument character varying,
    redcap_repeat_instance character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    viva2_rc_id bigint
);


--
-- Name: COLUMN viva2_rc_history.varname; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.varname IS 'Variable name';


--
-- Name: COLUMN viva2_rc_history.var_label; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.var_label IS 'Variable label';


--
-- Name: COLUMN viva2_rc_history.var_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.var_type IS 'Type of variable';


--
-- Name: COLUMN viva2_rc_history.restrict_var___0; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.restrict_var___0 IS 'None';


--
-- Name: COLUMN viva2_rc_history.restrict_var___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.restrict_var___1 IS 'PHI, OK for limited dataset';


--
-- Name: COLUMN viva2_rc_history.restrict_var___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.restrict_var___2 IS 'PHI, restricted use';


--
-- Name: COLUMN viva2_rc_history.restrict_var___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.restrict_var___3 IS 'Sensitive information';


--
-- Name: COLUMN viva2_rc_history.restrict_var___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.restrict_var___4 IS 'Other restriction';


--
-- Name: COLUMN viva2_rc_history.oth_restrict; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.oth_restrict IS 'Specify other restriction';


--
-- Name: COLUMN viva2_rc_history.domain_viva; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.domain_viva IS 'Domain or topic area';


--
-- Name: COLUMN viva2_rc_history.subdomain___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.subdomain___1 IS 'Placeholder';


--
-- Name: COLUMN viva2_rc_history.subdomain___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.subdomain___2 IS 'Placeholder';


--
-- Name: COLUMN viva2_rc_history.target_of_q; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.target_of_q IS 'Target';


--
-- Name: COLUMN viva2_rc_history.data_source; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.data_source IS 'Source of data';


--
-- Name: COLUMN viva2_rc_history.val_instr; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.val_instr IS 'Please indicate whether the question comes from an external, internal, or no instrument.';


--
-- Name: COLUMN viva2_rc_history.ext_instrument; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.ext_instrument IS 'External instrument';


--
-- Name: COLUMN viva2_rc_history.internal_instrument; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.internal_instrument IS 'Internal instrument';


--
-- Name: COLUMN viva2_rc_history.doc_yn; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.doc_yn IS 'Documentation available?';


--
-- Name: COLUMN viva2_rc_history.doc_link; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.doc_link IS 'Documentation link';


--
-- Name: COLUMN viva2_rc_history.long_yn; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_yn IS 'Longitudinal measurement?';


--
-- Name: COLUMN viva2_rc_history.long_timepts___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___1 IS 'Screening';


--
-- Name: COLUMN viva2_rc_history.long_timepts___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___2 IS 'Early pregnancy';


--
-- Name: COLUMN viva2_rc_history.long_timepts___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___3 IS 'Mid-pregnancy';


--
-- Name: COLUMN viva2_rc_history.long_timepts___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___4 IS 'Delivery';


--
-- Name: COLUMN viva2_rc_history.long_timepts___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___5 IS 'Infancy (6 months)';


--
-- Name: COLUMN viva2_rc_history.long_timepts___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___6 IS '1 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___7 IS '2 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___8 IS 'Early childhood (3 year)';


--
-- Name: COLUMN viva2_rc_history.long_timepts___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___9 IS '4 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___10 IS '5 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___11 IS '6 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___12 IS 'Mid childhood (7-8 years)';


--
-- Name: COLUMN viva2_rc_history.long_timepts___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___13 IS '8 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___14 IS '9 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___15 IS '10 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___16 IS '11 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___17; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___17 IS 'Early adolescence (12-13 years)';


--
-- Name: COLUMN viva2_rc_history.long_timepts___18; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___18 IS '14 years';


--
-- Name: COLUMN viva2_rc_history.long_timepts___19; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___19 IS '15 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___20; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___20 IS '16 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___21; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___21 IS 'Mid/late adolescence (17-18 years)';


--
-- Name: COLUMN viva2_rc_history.long_timepts___22; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___22 IS '19 year';


--
-- Name: COLUMN viva2_rc_history.long_timepts___23; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.long_timepts___23 IS 'Not time specific';


--
-- Name: COLUMN viva2_rc_history.event_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.event_type IS 'Type of data collection event';


--
-- Name: COLUMN viva2_rc_history.visit_name; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.visit_name IS 'Visit name';


--
-- Name: COLUMN viva2_rc_history.visit_time; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.visit_time IS 'Visit target time point';


--
-- Name: COLUMN viva2_rc_history.assay_specimen; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.assay_specimen IS 'Lab Assay Specimen Source';


--
-- Name: COLUMN viva2_rc_history.assay_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.assay_type IS 'Laboratory assay type';


--
-- Name: COLUMN viva2_rc_history.lab_assay_dataset; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.lab_assay_dataset IS 'Laboratory Assay \''Form\'' (Dataset)';


--
-- Name: COLUMN viva2_rc_history.form_label_ep; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_ep IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_ep___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_ep___1 IS 'EPQ';


--
-- Name: COLUMN viva2_rc_history.form_version_ep___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_ep___2 IS 'EPQ1';


--
-- Name: COLUMN viva2_rc_history.form_version_ep___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_ep___3 IS 'EPQA';


--
-- Name: COLUMN viva2_rc_history.form_version_ep___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_ep___4 IS 'EPS1';


--
-- Name: COLUMN viva2_rc_history.form_version_ep___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_ep___5 IS 'EPI1';


--
-- Name: COLUMN viva2_rc_history.form_version_ep___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_ep___6 IS 'EPIA';


--
-- Name: COLUMN viva2_rc_history.form_version_ep___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_ep___7 IS 'SCR1';


--
-- Name: COLUMN viva2_rc_history.form_version_ep___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_ep___8 IS 'BLD1';


--
-- Name: COLUMN viva2_rc_history.form_label_mp; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_mp IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_mp___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_mp___1 IS 'MPQ2';


--
-- Name: COLUMN viva2_rc_history.form_version_mp___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_mp___2 IS 'BLD2';


--
-- Name: COLUMN viva2_rc_history.form_version_mp___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_mp___3 IS 'PSQ2';


--
-- Name: COLUMN viva2_rc_history.form_version_mp___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_mp___4 IS 'MPI2';


--
-- Name: COLUMN viva2_rc_history.form_label_del; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_del IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_del___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_del___1 IS 'DES3';


--
-- Name: COLUMN viva2_rc_history.form_version_del___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_del___2 IS 'NAN3';


--
-- Name: COLUMN viva2_rc_history.form_version_del___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_del___3 IS 'NBP3';


--
-- Name: COLUMN viva2_rc_history.form_version_del___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_del___4 IS 'NLG3';


--
-- Name: COLUMN viva2_rc_history.form_version_del___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_del___5 IS 'PSQ3';


--
-- Name: COLUMN viva2_rc_history.form_version_del___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_del___6 IS 'PSS3';


--
-- Name: COLUMN viva2_rc_history.form_version_del___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_del___7 IS 'DEI3';


--
-- Name: COLUMN viva2_rc_history.form_label_6m; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_6m IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_6m___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_6m___1 IS 'PSQ4';


--
-- Name: COLUMN viva2_rc_history.form_version_6m___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_6m___2 IS 'MSC4';


--
-- Name: COLUMN viva2_rc_history.form_version_6m___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_6m___3 IS 'VIS4';


--
-- Name: COLUMN viva2_rc_history.form_version_6m___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_6m___4 IS 'SMIR';


--
-- Name: COLUMN viva2_rc_history.form_version_6m___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_6m___5 IS 'SMSB4';


--
-- Name: COLUMN viva2_rc_history.form_version_6m___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_6m___6 IS 'SMSF4';


--
-- Name: COLUMN viva2_rc_history.form_version_6m___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_6m___7 IS 'SMSW4';


--
-- Name: COLUMN viva2_rc_history.form_version_6m___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_6m___8 IS 'SMSM4';


--
-- Name: COLUMN viva2_rc_history.form_version_6m___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_6m___9 IS 'SMQ4';


--
-- Name: COLUMN viva2_rc_history.form_version_6m___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_6m___10 IS 'MSM4';


--
-- Name: COLUMN viva2_rc_history.form_label_1y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_1y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_1y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_1y___1 IS 'OYQ';


--
-- Name: COLUMN viva2_rc_history.form_label_2y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_2y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_2y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_2y___1 IS 'SYQ/SYQ6';


--
-- Name: COLUMN viva2_rc_history.form_label_3y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_3y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___1 IS 'MAT7';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___2 IS 'CAT7';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___3 IS 'MBP7';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___4 IS 'CBP7';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___5 IS 'MBL7';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___6 IS 'CBL7';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___7 IS 'MCT7';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___8 IS 'CCT7';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___9 IS 'TYI';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___10 IS 'TYQ';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___11 IS 'TYS7';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___12 IS 'IBL7';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___13 IS 'IAC7';


--
-- Name: COLUMN viva2_rc_history.form_version_3y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_3y___14 IS 'IDC7';


--
-- Name: COLUMN viva2_rc_history.form_label_4y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_4y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_4y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_4y___1 IS '4YQ';


--
-- Name: COLUMN viva2_rc_history.form_label_5y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_5y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_5y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_5y___1 IS 'QU5Y';


--
-- Name: COLUMN viva2_rc_history.form_label_6y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_6y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_6y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_6y___1 IS 'QU6Y';


--
-- Name: COLUMN viva2_rc_history.form_label_7y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_7y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___1 IS 'MA7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___2 IS 'CA7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___3 IS 'BL7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___4 IS 'PE7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___5 IS 'HR7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___6 IS 'DX7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___7 IS 'BP7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___8 IS 'MC7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___9 IS 'CC7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___10 IS 'SP7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___11 IS 'BQ7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___12 IS 'TE7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___13 IS 'MI7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___14 IS 'IN7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___15 IS 'HP7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___16 IS 'ST7Y';


--
-- Name: COLUMN viva2_rc_history.form_version_7y___17; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_7y___17 IS 'QU7Y';


--
-- Name: COLUMN viva2_rc_history.form_label_8y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_8y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_8y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_8y___1 IS 'QU8Y';


--
-- Name: COLUMN viva2_rc_history.form_label_9y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_9y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_9y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_9y___1 IS 'QU9Y';


--
-- Name: COLUMN viva2_rc_history.form_version_9y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_9y___2 IS 'CQ9Y';


--
-- Name: COLUMN viva2_rc_history.form_label_10y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_10y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_10y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_10y___1 IS 'QU10';


--
-- Name: COLUMN viva2_rc_history.form_version_10y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_10y___2 IS 'CQ10';


--
-- Name: COLUMN viva2_rc_history.form_label_11y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_11y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_11y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_11y___1 IS 'QU11';


--
-- Name: COLUMN viva2_rc_history.form_version_11y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_11y___2 IS 'CQ11';


--
-- Name: COLUMN viva2_rc_history.form_label_12y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_12y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___1 IS 'MA12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___2 IS 'CA12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___3 IS 'SJ12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___4 IS 'BL12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___5 IS 'PE12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___6 IS 'HR12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___7 IS 'NS12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___8 IS 'BP12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___9 IS 'DX12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___10 IS 'NO12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___11 IS 'SP12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___12 IS 'MI12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___13 IS 'IN12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___14 IS 'ST12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___15 IS 'QU12';


--
-- Name: COLUMN viva2_rc_history.form_version_12y___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_12y___16 IS 'CQ12';


--
-- Name: COLUMN viva2_rc_history.form_label_14y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_14y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_14y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_14y___1 IS 'QU14';


--
-- Name: COLUMN viva2_rc_history.form_version_14y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_14y___2 IS 'CQ14';


--
-- Name: COLUMN viva2_rc_history.form_label_15y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_15y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_15y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_15y___1 IS 'QU15';


--
-- Name: COLUMN viva2_rc_history.form_version_15y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_15y___2 IS 'CQ15';


--
-- Name: COLUMN viva2_rc_history.form_label_16y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_16y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_16y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_16y___1 IS 'QU16';


--
-- Name: COLUMN viva2_rc_history.form_version_16y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_16y___2 IS 'CQ16';


--
-- Name: COLUMN viva2_rc_history.form_label_mt; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_mt IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_mt; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_mt IS 'Form Version';


--
-- Name: COLUMN viva2_rc_history.form_label_19y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_label_19y IS 'Form Label';


--
-- Name: COLUMN viva2_rc_history.form_version_19y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_19y___1 IS 'QU19';


--
-- Name: COLUMN viva2_rc_history.form_version_19y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.form_version_19y___2 IS 'TQ19';


--
-- Name: COLUMN viva2_rc_history.not_time_specific; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.not_time_specific IS 'Not time specific';


--
-- Name: COLUMN viva2_rc_history.var_level; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.var_level IS 'Variable Level';


--
-- Name: COLUMN viva2_rc_history.units; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.units IS 'Units';


--
-- Name: COLUMN viva2_rc_history.model_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.model_type IS 'Model';


--
-- Name: COLUMN viva2_rc_history.response_options; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.response_options IS 'Response Options';


--
-- Name: COLUMN viva2_rc_history.elig_sample; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.elig_sample IS 'Eligible sample description';


--
-- Name: COLUMN viva2_rc_history.elig_n; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.elig_n IS 'Eligible sample N';


--
-- Name: COLUMN viva2_rc_history.actual_n; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.actual_n IS 'Actual sample N';


--
-- Name: COLUMN viva2_rc_history.an_var; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.an_var IS 'Analytic variable name';


--
-- Name: COLUMN viva2_rc_history.orig_deriv; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.orig_deriv IS 'Original or derived variable';


--
-- Name: COLUMN viva2_rc_history.corr_derived_yn___0; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.corr_derived_yn___0 IS 'No';


--
-- Name: COLUMN viva2_rc_history.corr_derived_yn___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.corr_derived_yn___1 IS 'Yes';


--
-- Name: COLUMN viva2_rc_history.der_varname; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.der_varname IS 'Name of corresponding derived variable';


--
-- Name: COLUMN viva2_rc_history.dervar_explain; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.dervar_explain IS 'Derived Variable';


--
-- Name: COLUMN viva2_rc_history.orig_varnames; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rc_history.orig_varnames IS 'Name of corresponding original variable(s)';


--
-- Name: viva2_rc_history_id_seq; Type: SEQUENCE; Schema: viva_ref_info; Owner: -
--

CREATE SEQUENCE viva_ref_info.viva2_rc_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva2_rc_history_id_seq; Type: SEQUENCE OWNED BY; Schema: viva_ref_info; Owner: -
--

ALTER SEQUENCE viva_ref_info.viva2_rc_history_id_seq OWNED BY viva_ref_info.viva2_rc_history.id;


--
-- Name: viva2_rcs; Type: TABLE; Schema: viva_ref_info; Owner: -
--

CREATE TABLE viva_ref_info.viva2_rcs (
    id bigint NOT NULL,
    varname character varying,
    var_label character varying,
    var_type character varying,
    restrict_var___0 boolean,
    restrict_var___1 boolean,
    restrict_var___2 boolean,
    restrict_var___3 boolean,
    restrict_var___4 boolean,
    oth_restrict character varying,
    domain_viva character varying,
    subdomain___1 boolean,
    subdomain___2 boolean,
    target_of_q character varying,
    data_source character varying,
    val_instr character varying,
    ext_instrument character varying,
    internal_instrument character varying,
    doc_yn character varying,
    doc_link character varying,
    long_yn character varying,
    long_timepts___1 boolean,
    long_timepts___2 boolean,
    long_timepts___3 boolean,
    long_timepts___4 boolean,
    long_timepts___5 boolean,
    long_timepts___6 boolean,
    long_timepts___7 boolean,
    long_timepts___8 boolean,
    long_timepts___9 boolean,
    long_timepts___10 boolean,
    long_timepts___11 boolean,
    long_timepts___12 boolean,
    long_timepts___13 boolean,
    long_timepts___14 boolean,
    long_timepts___15 boolean,
    long_timepts___16 boolean,
    long_timepts___17 boolean,
    long_timepts___18 boolean,
    long_timepts___19 boolean,
    long_timepts___20 boolean,
    long_timepts___21 boolean,
    long_timepts___22 boolean,
    long_timepts___23 boolean,
    static_variable_information_complete integer,
    event_type character varying,
    visit_name character varying,
    visit_time character varying,
    assay_specimen character varying,
    assay_type character varying,
    lab_assay_dataset character varying,
    form_label_ep character varying,
    form_version_ep___1 boolean,
    form_version_ep___2 boolean,
    form_version_ep___3 boolean,
    form_version_ep___4 boolean,
    form_version_ep___5 boolean,
    form_version_ep___6 boolean,
    form_version_ep___7 boolean,
    form_version_ep___8 boolean,
    form_label_mp character varying,
    form_version_mp___1 boolean,
    form_version_mp___2 boolean,
    form_version_mp___3 boolean,
    form_version_mp___4 boolean,
    form_label_del character varying,
    form_version_del___1 boolean,
    form_version_del___2 boolean,
    form_version_del___3 boolean,
    form_version_del___4 boolean,
    form_version_del___5 boolean,
    form_version_del___6 boolean,
    form_version_del___7 boolean,
    form_label_6m character varying,
    form_version_6m___1 boolean,
    form_version_6m___2 boolean,
    form_version_6m___3 boolean,
    form_version_6m___4 boolean,
    form_version_6m___5 boolean,
    form_version_6m___6 boolean,
    form_version_6m___7 boolean,
    form_version_6m___8 boolean,
    form_version_6m___9 boolean,
    form_version_6m___10 boolean,
    form_label_1y character varying,
    form_version_1y___1 boolean,
    form_label_2y character varying,
    form_version_2y___1 boolean,
    form_label_3y character varying,
    form_version_3y___1 boolean,
    form_version_3y___2 boolean,
    form_version_3y___3 boolean,
    form_version_3y___4 boolean,
    form_version_3y___5 boolean,
    form_version_3y___6 boolean,
    form_version_3y___7 boolean,
    form_version_3y___8 boolean,
    form_version_3y___9 boolean,
    form_version_3y___10 boolean,
    form_version_3y___11 boolean,
    form_version_3y___12 boolean,
    form_version_3y___13 boolean,
    form_version_3y___14 boolean,
    form_label_4y character varying,
    form_version_4y___1 boolean,
    form_label_5y character varying,
    form_version_5y___1 boolean,
    form_label_6y character varying,
    form_version_6y___1 boolean,
    form_label_7y character varying,
    form_version_7y___1 boolean,
    form_version_7y___2 boolean,
    form_version_7y___3 boolean,
    form_version_7y___4 boolean,
    form_version_7y___5 boolean,
    form_version_7y___6 boolean,
    form_version_7y___7 boolean,
    form_version_7y___8 boolean,
    form_version_7y___9 boolean,
    form_version_7y___10 boolean,
    form_version_7y___11 boolean,
    form_version_7y___12 boolean,
    form_version_7y___13 boolean,
    form_version_7y___14 boolean,
    form_version_7y___15 boolean,
    form_version_7y___16 boolean,
    form_version_7y___17 boolean,
    form_label_8y character varying,
    form_version_8y___1 boolean,
    form_label_9y character varying,
    form_version_9y___1 boolean,
    form_version_9y___2 boolean,
    form_label_10y character varying,
    form_version_10y___1 boolean,
    form_version_10y___2 boolean,
    form_label_11y character varying,
    form_version_11y___1 boolean,
    form_version_11y___2 boolean,
    form_label_12y character varying,
    form_version_12y___1 boolean,
    form_version_12y___2 boolean,
    form_version_12y___3 boolean,
    form_version_12y___4 boolean,
    form_version_12y___5 boolean,
    form_version_12y___6 boolean,
    form_version_12y___7 boolean,
    form_version_12y___8 boolean,
    form_version_12y___9 boolean,
    form_version_12y___10 boolean,
    form_version_12y___11 boolean,
    form_version_12y___12 boolean,
    form_version_12y___13 boolean,
    form_version_12y___14 boolean,
    form_version_12y___15 boolean,
    form_version_12y___16 boolean,
    form_label_14y character varying,
    form_version_14y___1 boolean,
    form_version_14y___2 boolean,
    form_label_15y character varying,
    form_version_15y___1 boolean,
    form_version_15y___2 boolean,
    form_label_16y character varying,
    form_version_16y___1 boolean,
    form_version_16y___2 boolean,
    form_label_mt character varying,
    form_version_mt character varying,
    form_label_19y character varying,
    form_version_19y___1 boolean,
    form_version_19y___2 boolean,
    not_time_specific character varying,
    var_level character varying,
    units character varying,
    model_type character varying,
    response_options character varying,
    elig_sample character varying,
    elig_n character varying,
    actual_n character varying,
    an_var character varying,
    orig_deriv character varying,
    corr_derived_yn___0 boolean,
    corr_derived_yn___1 boolean,
    der_varname character varying,
    dervar_explain character varying,
    orig_varnames character varying,
    visitspecific_information_complete integer,
    redcap_repeat_instrument character varying,
    redcap_repeat_instance character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE viva2_rcs; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON TABLE viva_ref_info.viva2_rcs IS 'Dynamicmodel: Viva2 Rc';


--
-- Name: COLUMN viva2_rcs.varname; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.varname IS 'Variable name';


--
-- Name: COLUMN viva2_rcs.var_label; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.var_label IS 'Variable label';


--
-- Name: COLUMN viva2_rcs.var_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.var_type IS 'Type of variable';


--
-- Name: COLUMN viva2_rcs.restrict_var___0; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.restrict_var___0 IS 'None';


--
-- Name: COLUMN viva2_rcs.restrict_var___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.restrict_var___1 IS 'PHI, OK for limited dataset';


--
-- Name: COLUMN viva2_rcs.restrict_var___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.restrict_var___2 IS 'PHI, restricted use';


--
-- Name: COLUMN viva2_rcs.restrict_var___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.restrict_var___3 IS 'Sensitive information';


--
-- Name: COLUMN viva2_rcs.restrict_var___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.restrict_var___4 IS 'Other restriction';


--
-- Name: COLUMN viva2_rcs.oth_restrict; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.oth_restrict IS 'Specify other restriction';


--
-- Name: COLUMN viva2_rcs.domain_viva; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.domain_viva IS 'Domain or topic area';


--
-- Name: COLUMN viva2_rcs.subdomain___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.subdomain___1 IS 'Placeholder';


--
-- Name: COLUMN viva2_rcs.subdomain___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.subdomain___2 IS 'Placeholder';


--
-- Name: COLUMN viva2_rcs.target_of_q; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.target_of_q IS 'Target';


--
-- Name: COLUMN viva2_rcs.data_source; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.data_source IS 'Source of data';


--
-- Name: COLUMN viva2_rcs.val_instr; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.val_instr IS 'Please indicate whether the question comes from an external, internal, or no instrument.';


--
-- Name: COLUMN viva2_rcs.ext_instrument; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.ext_instrument IS 'External instrument';


--
-- Name: COLUMN viva2_rcs.internal_instrument; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.internal_instrument IS 'Internal instrument';


--
-- Name: COLUMN viva2_rcs.doc_yn; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.doc_yn IS 'Documentation available?';


--
-- Name: COLUMN viva2_rcs.doc_link; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.doc_link IS 'Documentation link';


--
-- Name: COLUMN viva2_rcs.long_yn; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_yn IS 'Longitudinal measurement?';


--
-- Name: COLUMN viva2_rcs.long_timepts___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___1 IS 'Screening';


--
-- Name: COLUMN viva2_rcs.long_timepts___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___2 IS 'Early pregnancy';


--
-- Name: COLUMN viva2_rcs.long_timepts___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___3 IS 'Mid-pregnancy';


--
-- Name: COLUMN viva2_rcs.long_timepts___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___4 IS 'Delivery';


--
-- Name: COLUMN viva2_rcs.long_timepts___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___5 IS 'Infancy (6 months)';


--
-- Name: COLUMN viva2_rcs.long_timepts___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___6 IS '1 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___7 IS '2 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___8 IS 'Early childhood (3 year)';


--
-- Name: COLUMN viva2_rcs.long_timepts___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___9 IS '4 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___10 IS '5 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___11 IS '6 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___12 IS 'Mid childhood (7-8 years)';


--
-- Name: COLUMN viva2_rcs.long_timepts___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___13 IS '8 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___14 IS '9 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___15 IS '10 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___16 IS '11 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___17; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___17 IS 'Early adolescence (12-13 years)';


--
-- Name: COLUMN viva2_rcs.long_timepts___18; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___18 IS '14 years';


--
-- Name: COLUMN viva2_rcs.long_timepts___19; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___19 IS '15 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___20; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___20 IS '16 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___21; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___21 IS 'Mid/late adolescence (17-18 years)';


--
-- Name: COLUMN viva2_rcs.long_timepts___22; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___22 IS '19 year';


--
-- Name: COLUMN viva2_rcs.long_timepts___23; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.long_timepts___23 IS 'Not time specific';


--
-- Name: COLUMN viva2_rcs.event_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.event_type IS 'Type of data collection event';


--
-- Name: COLUMN viva2_rcs.visit_name; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.visit_name IS 'Visit name';


--
-- Name: COLUMN viva2_rcs.visit_time; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.visit_time IS 'Visit target time point';


--
-- Name: COLUMN viva2_rcs.assay_specimen; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.assay_specimen IS 'Lab Assay Specimen Source';


--
-- Name: COLUMN viva2_rcs.assay_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.assay_type IS 'Laboratory assay type';


--
-- Name: COLUMN viva2_rcs.lab_assay_dataset; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.lab_assay_dataset IS 'Laboratory Assay \''Form\'' (Dataset)';


--
-- Name: COLUMN viva2_rcs.form_label_ep; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_ep IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_ep___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_ep___1 IS 'EPQ';


--
-- Name: COLUMN viva2_rcs.form_version_ep___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_ep___2 IS 'EPQ1';


--
-- Name: COLUMN viva2_rcs.form_version_ep___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_ep___3 IS 'EPQA';


--
-- Name: COLUMN viva2_rcs.form_version_ep___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_ep___4 IS 'EPS1';


--
-- Name: COLUMN viva2_rcs.form_version_ep___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_ep___5 IS 'EPI1';


--
-- Name: COLUMN viva2_rcs.form_version_ep___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_ep___6 IS 'EPIA';


--
-- Name: COLUMN viva2_rcs.form_version_ep___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_ep___7 IS 'SCR1';


--
-- Name: COLUMN viva2_rcs.form_version_ep___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_ep___8 IS 'BLD1';


--
-- Name: COLUMN viva2_rcs.form_label_mp; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_mp IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_mp___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_mp___1 IS 'MPQ2';


--
-- Name: COLUMN viva2_rcs.form_version_mp___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_mp___2 IS 'BLD2';


--
-- Name: COLUMN viva2_rcs.form_version_mp___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_mp___3 IS 'PSQ2';


--
-- Name: COLUMN viva2_rcs.form_version_mp___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_mp___4 IS 'MPI2';


--
-- Name: COLUMN viva2_rcs.form_label_del; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_del IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_del___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_del___1 IS 'DES3';


--
-- Name: COLUMN viva2_rcs.form_version_del___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_del___2 IS 'NAN3';


--
-- Name: COLUMN viva2_rcs.form_version_del___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_del___3 IS 'NBP3';


--
-- Name: COLUMN viva2_rcs.form_version_del___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_del___4 IS 'NLG3';


--
-- Name: COLUMN viva2_rcs.form_version_del___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_del___5 IS 'PSQ3';


--
-- Name: COLUMN viva2_rcs.form_version_del___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_del___6 IS 'PSS3';


--
-- Name: COLUMN viva2_rcs.form_version_del___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_del___7 IS 'DEI3';


--
-- Name: COLUMN viva2_rcs.form_label_6m; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_6m IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_6m___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_6m___1 IS 'PSQ4';


--
-- Name: COLUMN viva2_rcs.form_version_6m___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_6m___2 IS 'MSC4';


--
-- Name: COLUMN viva2_rcs.form_version_6m___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_6m___3 IS 'VIS4';


--
-- Name: COLUMN viva2_rcs.form_version_6m___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_6m___4 IS 'SMIR';


--
-- Name: COLUMN viva2_rcs.form_version_6m___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_6m___5 IS 'SMSB4';


--
-- Name: COLUMN viva2_rcs.form_version_6m___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_6m___6 IS 'SMSF4';


--
-- Name: COLUMN viva2_rcs.form_version_6m___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_6m___7 IS 'SMSW4';


--
-- Name: COLUMN viva2_rcs.form_version_6m___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_6m___8 IS 'SMSM4';


--
-- Name: COLUMN viva2_rcs.form_version_6m___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_6m___9 IS 'SMQ4';


--
-- Name: COLUMN viva2_rcs.form_version_6m___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_6m___10 IS 'MSM4';


--
-- Name: COLUMN viva2_rcs.form_label_1y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_1y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_1y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_1y___1 IS 'OYQ';


--
-- Name: COLUMN viva2_rcs.form_label_2y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_2y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_2y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_2y___1 IS 'SYQ/SYQ6';


--
-- Name: COLUMN viva2_rcs.form_label_3y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_3y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_3y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___1 IS 'MAT7';


--
-- Name: COLUMN viva2_rcs.form_version_3y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___2 IS 'CAT7';


--
-- Name: COLUMN viva2_rcs.form_version_3y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___3 IS 'MBP7';


--
-- Name: COLUMN viva2_rcs.form_version_3y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___4 IS 'CBP7';


--
-- Name: COLUMN viva2_rcs.form_version_3y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___5 IS 'MBL7';


--
-- Name: COLUMN viva2_rcs.form_version_3y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___6 IS 'CBL7';


--
-- Name: COLUMN viva2_rcs.form_version_3y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___7 IS 'MCT7';


--
-- Name: COLUMN viva2_rcs.form_version_3y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___8 IS 'CCT7';


--
-- Name: COLUMN viva2_rcs.form_version_3y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___9 IS 'TYI';


--
-- Name: COLUMN viva2_rcs.form_version_3y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___10 IS 'TYQ';


--
-- Name: COLUMN viva2_rcs.form_version_3y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___11 IS 'TYS7';


--
-- Name: COLUMN viva2_rcs.form_version_3y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___12 IS 'IBL7';


--
-- Name: COLUMN viva2_rcs.form_version_3y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___13 IS 'IAC7';


--
-- Name: COLUMN viva2_rcs.form_version_3y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_3y___14 IS 'IDC7';


--
-- Name: COLUMN viva2_rcs.form_label_4y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_4y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_4y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_4y___1 IS '4YQ';


--
-- Name: COLUMN viva2_rcs.form_label_5y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_5y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_5y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_5y___1 IS 'QU5Y';


--
-- Name: COLUMN viva2_rcs.form_label_6y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_6y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_6y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_6y___1 IS 'QU6Y';


--
-- Name: COLUMN viva2_rcs.form_label_7y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_7y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_7y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___1 IS 'MA7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___2 IS 'CA7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___3 IS 'BL7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___4 IS 'PE7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___5 IS 'HR7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___6 IS 'DX7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___7 IS 'BP7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___8 IS 'MC7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___9 IS 'CC7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___10 IS 'SP7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___11 IS 'BQ7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___12 IS 'TE7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___13 IS 'MI7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___14 IS 'IN7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___15 IS 'HP7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___16 IS 'ST7Y';


--
-- Name: COLUMN viva2_rcs.form_version_7y___17; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_7y___17 IS 'QU7Y';


--
-- Name: COLUMN viva2_rcs.form_label_8y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_8y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_8y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_8y___1 IS 'QU8Y';


--
-- Name: COLUMN viva2_rcs.form_label_9y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_9y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_9y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_9y___1 IS 'QU9Y';


--
-- Name: COLUMN viva2_rcs.form_version_9y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_9y___2 IS 'CQ9Y';


--
-- Name: COLUMN viva2_rcs.form_label_10y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_10y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_10y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_10y___1 IS 'QU10';


--
-- Name: COLUMN viva2_rcs.form_version_10y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_10y___2 IS 'CQ10';


--
-- Name: COLUMN viva2_rcs.form_label_11y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_11y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_11y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_11y___1 IS 'QU11';


--
-- Name: COLUMN viva2_rcs.form_version_11y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_11y___2 IS 'CQ11';


--
-- Name: COLUMN viva2_rcs.form_label_12y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_12y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_12y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___1 IS 'MA12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___2 IS 'CA12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___3 IS 'SJ12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___4 IS 'BL12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___5 IS 'PE12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___6 IS 'HR12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___7 IS 'NS12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___8 IS 'BP12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___9 IS 'DX12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___10 IS 'NO12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___11 IS 'SP12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___12 IS 'MI12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___13 IS 'IN12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___14 IS 'ST12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___15 IS 'QU12';


--
-- Name: COLUMN viva2_rcs.form_version_12y___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_12y___16 IS 'CQ12';


--
-- Name: COLUMN viva2_rcs.form_label_14y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_14y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_14y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_14y___1 IS 'QU14';


--
-- Name: COLUMN viva2_rcs.form_version_14y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_14y___2 IS 'CQ14';


--
-- Name: COLUMN viva2_rcs.form_label_15y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_15y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_15y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_15y___1 IS 'QU15';


--
-- Name: COLUMN viva2_rcs.form_version_15y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_15y___2 IS 'CQ15';


--
-- Name: COLUMN viva2_rcs.form_label_16y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_16y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_16y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_16y___1 IS 'QU16';


--
-- Name: COLUMN viva2_rcs.form_version_16y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_16y___2 IS 'CQ16';


--
-- Name: COLUMN viva2_rcs.form_label_mt; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_mt IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_mt; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_mt IS 'Form Version';


--
-- Name: COLUMN viva2_rcs.form_label_19y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_label_19y IS 'Form Label';


--
-- Name: COLUMN viva2_rcs.form_version_19y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_19y___1 IS 'QU19';


--
-- Name: COLUMN viva2_rcs.form_version_19y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.form_version_19y___2 IS 'TQ19';


--
-- Name: COLUMN viva2_rcs.not_time_specific; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.not_time_specific IS 'Not time specific';


--
-- Name: COLUMN viva2_rcs.var_level; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.var_level IS 'Variable Level';


--
-- Name: COLUMN viva2_rcs.units; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.units IS 'Units';


--
-- Name: COLUMN viva2_rcs.model_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.model_type IS 'Model';


--
-- Name: COLUMN viva2_rcs.response_options; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.response_options IS 'Response Options';


--
-- Name: COLUMN viva2_rcs.elig_sample; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.elig_sample IS 'Eligible sample description';


--
-- Name: COLUMN viva2_rcs.elig_n; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.elig_n IS 'Eligible sample N';


--
-- Name: COLUMN viva2_rcs.actual_n; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.actual_n IS 'Actual sample N';


--
-- Name: COLUMN viva2_rcs.an_var; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.an_var IS 'Analytic variable name';


--
-- Name: COLUMN viva2_rcs.orig_deriv; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.orig_deriv IS 'Original or derived variable';


--
-- Name: COLUMN viva2_rcs.corr_derived_yn___0; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.corr_derived_yn___0 IS 'No';


--
-- Name: COLUMN viva2_rcs.corr_derived_yn___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.corr_derived_yn___1 IS 'Yes';


--
-- Name: COLUMN viva2_rcs.der_varname; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.der_varname IS 'Name of corresponding derived variable';


--
-- Name: COLUMN viva2_rcs.dervar_explain; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.dervar_explain IS 'Derived Variable';


--
-- Name: COLUMN viva2_rcs.orig_varnames; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva2_rcs.orig_varnames IS 'Name of corresponding original variable(s)';


--
-- Name: viva2_rcs_id_seq; Type: SEQUENCE; Schema: viva_ref_info; Owner: -
--

CREATE SEQUENCE viva_ref_info.viva2_rcs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva2_rcs_id_seq; Type: SEQUENCE OWNED BY; Schema: viva_ref_info; Owner: -
--

ALTER SEQUENCE viva_ref_info.viva2_rcs_id_seq OWNED BY viva_ref_info.viva2_rcs.id;


--
-- Name: viva3_rc_history; Type: TABLE; Schema: viva_ref_info; Owner: -
--

CREATE TABLE viva_ref_info.viva3_rc_history (
    id bigint NOT NULL,
    varname character varying,
    var_label character varying,
    var_type character varying,
    restrict_var___0 boolean,
    restrict_var___1 boolean,
    restrict_var___2 boolean,
    restrict_var___3 boolean,
    restrict_var___4 boolean,
    oth_restrict character varying,
    domain_viva character varying,
    subdomain___1 boolean,
    subdomain___2 boolean,
    target_of_q character varying,
    data_source character varying,
    val_instr character varying,
    ext_instrument character varying,
    internal_instrument character varying,
    doc_yn character varying,
    doc_link character varying,
    var_level character varying,
    units character varying,
    response_options character varying,
    long_yn character varying,
    long_timepts___1 boolean,
    long_timepts___2 boolean,
    long_timepts___3 boolean,
    long_timepts___4 boolean,
    long_timepts___5 boolean,
    long_timepts___6 boolean,
    long_timepts___7 boolean,
    long_timepts___8 boolean,
    long_timepts___9 boolean,
    long_timepts___10 boolean,
    long_timepts___11 boolean,
    long_timepts___12 boolean,
    long_timepts___13 boolean,
    long_timepts___14 boolean,
    long_timepts___15 boolean,
    long_timepts___16 boolean,
    long_timepts___17 boolean,
    long_timepts___18 boolean,
    long_timepts___19 boolean,
    long_timepts___20 boolean,
    long_timepts___21 boolean,
    long_timepts___22 boolean,
    long_timepts___23 boolean,
    static_variable_information_complete integer,
    event_type character varying,
    visit_name character varying,
    visit_time character varying,
    assay_specimen character varying,
    assay_type character varying,
    lab_assay_dataset character varying,
    form_label_ep character varying,
    form_version_ep___1 boolean,
    form_version_ep___2 boolean,
    form_version_ep___3 boolean,
    form_version_ep___4 boolean,
    form_version_ep___5 boolean,
    form_version_ep___6 boolean,
    form_version_ep___7 boolean,
    form_version_ep___8 boolean,
    form_label_mp character varying,
    form_version_mp___1 boolean,
    form_version_mp___2 boolean,
    form_version_mp___3 boolean,
    form_version_mp___4 boolean,
    form_label_del character varying,
    form_version_del___1 boolean,
    form_version_del___2 boolean,
    form_version_del___3 boolean,
    form_version_del___4 boolean,
    form_version_del___5 boolean,
    form_version_del___6 boolean,
    form_version_del___7 boolean,
    form_label_6m character varying,
    form_version_6m___1 boolean,
    form_version_6m___2 boolean,
    form_version_6m___3 boolean,
    form_version_6m___4 boolean,
    form_version_6m___5 boolean,
    form_version_6m___6 boolean,
    form_version_6m___7 boolean,
    form_version_6m___8 boolean,
    form_version_6m___9 boolean,
    form_version_6m___10 boolean,
    form_label_1y character varying,
    form_version_1y___1 boolean,
    form_label_2y character varying,
    form_version_2y___1 boolean,
    form_label_3y character varying,
    form_version_3y___1 boolean,
    form_version_3y___2 boolean,
    form_version_3y___3 boolean,
    form_version_3y___4 boolean,
    form_version_3y___5 boolean,
    form_version_3y___6 boolean,
    form_version_3y___7 boolean,
    form_version_3y___8 boolean,
    form_version_3y___9 boolean,
    form_version_3y___10 boolean,
    form_version_3y___11 boolean,
    form_version_3y___12 boolean,
    form_version_3y___13 boolean,
    form_version_3y___14 boolean,
    form_label_4y character varying,
    form_version_4y___1 boolean,
    form_label_5y character varying,
    form_version_5y___1 boolean,
    form_label_6y character varying,
    form_version_6y___1 boolean,
    form_label_7y character varying,
    form_version_7y___1 boolean,
    form_version_7y___2 boolean,
    form_version_7y___3 boolean,
    form_version_7y___4 boolean,
    form_version_7y___5 boolean,
    form_version_7y___6 boolean,
    form_version_7y___7 boolean,
    form_version_7y___8 boolean,
    form_version_7y___9 boolean,
    form_version_7y___10 boolean,
    form_version_7y___11 boolean,
    form_version_7y___12 boolean,
    form_version_7y___13 boolean,
    form_version_7y___14 boolean,
    form_version_7y___15 boolean,
    form_version_7y___16 boolean,
    form_version_7y___17 boolean,
    form_label_8y character varying,
    form_version_8y___1 boolean,
    form_label_9y character varying,
    form_version_9y___1 boolean,
    form_version_9y___2 boolean,
    form_label_10y character varying,
    form_version_10y___1 boolean,
    form_version_10y___2 boolean,
    form_label_11y character varying,
    form_version_11y___1 boolean,
    form_version_11y___2 boolean,
    form_label_12y character varying,
    form_version_12y___1 boolean,
    form_version_12y___2 boolean,
    form_version_12y___3 boolean,
    form_version_12y___4 boolean,
    form_version_12y___5 boolean,
    form_version_12y___6 boolean,
    form_version_12y___7 boolean,
    form_version_12y___8 boolean,
    form_version_12y___9 boolean,
    form_version_12y___10 boolean,
    form_version_12y___11 boolean,
    form_version_12y___12 boolean,
    form_version_12y___13 boolean,
    form_version_12y___14 boolean,
    form_version_12y___15 boolean,
    form_version_12y___16 boolean,
    form_label_14y character varying,
    form_version_14y___1 boolean,
    form_version_14y___2 boolean,
    form_label_15y character varying,
    form_version_15y___1 boolean,
    form_version_15y___2 boolean,
    form_label_16y character varying,
    form_version_16y___1 boolean,
    form_version_16y___2 boolean,
    form_label_mt character varying,
    form_version_mt character varying,
    form_label_19y character varying,
    form_version_19y___1 boolean,
    form_version_19y___2 boolean,
    not_time_specific character varying,
    model_type character varying,
    elig_sample character varying,
    elig_n character varying,
    actual_n character varying,
    an_var character varying,
    orig_deriv character varying,
    corr_derived_yn___0 boolean,
    corr_derived_yn___1 boolean,
    der_varname character varying,
    dervar_explain character varying,
    orig_varnames character varying,
    visitspecific_information_complete integer,
    redcap_repeat_instrument character varying,
    redcap_repeat_instance character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    viva3_rc_id bigint
);


--
-- Name: COLUMN viva3_rc_history.varname; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.varname IS 'Variable name';


--
-- Name: COLUMN viva3_rc_history.var_label; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.var_label IS 'Variable label';


--
-- Name: COLUMN viva3_rc_history.var_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.var_type IS 'Type of variable';


--
-- Name: COLUMN viva3_rc_history.restrict_var___0; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.restrict_var___0 IS 'None';


--
-- Name: COLUMN viva3_rc_history.restrict_var___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.restrict_var___1 IS 'PHI, OK for limited dataset';


--
-- Name: COLUMN viva3_rc_history.restrict_var___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.restrict_var___2 IS 'PHI, restricted use';


--
-- Name: COLUMN viva3_rc_history.restrict_var___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.restrict_var___3 IS 'Sensitive information';


--
-- Name: COLUMN viva3_rc_history.restrict_var___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.restrict_var___4 IS 'Other restriction';


--
-- Name: COLUMN viva3_rc_history.oth_restrict; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.oth_restrict IS 'Specify other restriction';


--
-- Name: COLUMN viva3_rc_history.domain_viva; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.domain_viva IS 'Domain or topic area';


--
-- Name: COLUMN viva3_rc_history.subdomain___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.subdomain___1 IS 'Placeholder';


--
-- Name: COLUMN viva3_rc_history.subdomain___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.subdomain___2 IS 'Placeholder';


--
-- Name: COLUMN viva3_rc_history.target_of_q; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.target_of_q IS 'Target';


--
-- Name: COLUMN viva3_rc_history.data_source; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.data_source IS 'Source of data';


--
-- Name: COLUMN viva3_rc_history.val_instr; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.val_instr IS 'Please indicate whether the question comes from an external, internal, or no instrument.';


--
-- Name: COLUMN viva3_rc_history.ext_instrument; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.ext_instrument IS 'External instrument';


--
-- Name: COLUMN viva3_rc_history.internal_instrument; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.internal_instrument IS 'Internal instrument';


--
-- Name: COLUMN viva3_rc_history.doc_yn; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.doc_yn IS 'Documentation available?';


--
-- Name: COLUMN viva3_rc_history.doc_link; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.doc_link IS 'Documentation link';


--
-- Name: COLUMN viva3_rc_history.var_level; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.var_level IS 'Variable Level';


--
-- Name: COLUMN viva3_rc_history.units; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.units IS 'Units';


--
-- Name: COLUMN viva3_rc_history.response_options; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.response_options IS 'Response Options';


--
-- Name: COLUMN viva3_rc_history.long_yn; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_yn IS 'Longitudinal measurement?';


--
-- Name: COLUMN viva3_rc_history.long_timepts___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___1 IS 'Screening';


--
-- Name: COLUMN viva3_rc_history.long_timepts___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___2 IS 'Early pregnancy';


--
-- Name: COLUMN viva3_rc_history.long_timepts___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___3 IS 'Mid-pregnancy';


--
-- Name: COLUMN viva3_rc_history.long_timepts___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___4 IS 'Delivery';


--
-- Name: COLUMN viva3_rc_history.long_timepts___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___5 IS 'Infancy (6 months)';


--
-- Name: COLUMN viva3_rc_history.long_timepts___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___6 IS '1 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___7 IS '2 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___8 IS 'Early childhood (3 year)';


--
-- Name: COLUMN viva3_rc_history.long_timepts___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___9 IS '4 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___10 IS '5 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___11 IS '6 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___12 IS 'Mid childhood (7-8 years)';


--
-- Name: COLUMN viva3_rc_history.long_timepts___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___13 IS '8 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___14 IS '9 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___15 IS '10 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___16 IS '11 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___17; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___17 IS 'Early adolescence (12-13 years)';


--
-- Name: COLUMN viva3_rc_history.long_timepts___18; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___18 IS '14 years';


--
-- Name: COLUMN viva3_rc_history.long_timepts___19; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___19 IS '15 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___20; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___20 IS '16 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___21; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___21 IS 'Mid/late adolescence (17-18 years)';


--
-- Name: COLUMN viva3_rc_history.long_timepts___22; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___22 IS '19 year';


--
-- Name: COLUMN viva3_rc_history.long_timepts___23; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.long_timepts___23 IS 'Not time specific';


--
-- Name: COLUMN viva3_rc_history.event_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.event_type IS 'Type of data collection event';


--
-- Name: COLUMN viva3_rc_history.visit_name; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.visit_name IS 'Visit name';


--
-- Name: COLUMN viva3_rc_history.visit_time; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.visit_time IS 'Visit target time point';


--
-- Name: COLUMN viva3_rc_history.assay_specimen; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.assay_specimen IS 'Lab Assay Specimen Source';


--
-- Name: COLUMN viva3_rc_history.assay_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.assay_type IS 'Laboratory assay type';


--
-- Name: COLUMN viva3_rc_history.lab_assay_dataset; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.lab_assay_dataset IS 'Laboratory Assay \''Form\'' (Dataset)';


--
-- Name: COLUMN viva3_rc_history.form_label_ep; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_ep IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_ep___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_ep___1 IS 'EPQ';


--
-- Name: COLUMN viva3_rc_history.form_version_ep___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_ep___2 IS 'EPQ1';


--
-- Name: COLUMN viva3_rc_history.form_version_ep___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_ep___3 IS 'EPQA';


--
-- Name: COLUMN viva3_rc_history.form_version_ep___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_ep___4 IS 'EPS1';


--
-- Name: COLUMN viva3_rc_history.form_version_ep___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_ep___5 IS 'EPI1';


--
-- Name: COLUMN viva3_rc_history.form_version_ep___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_ep___6 IS 'EPIA';


--
-- Name: COLUMN viva3_rc_history.form_version_ep___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_ep___7 IS 'SCR1';


--
-- Name: COLUMN viva3_rc_history.form_version_ep___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_ep___8 IS 'BLD1';


--
-- Name: COLUMN viva3_rc_history.form_label_mp; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_mp IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_mp___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_mp___1 IS 'MPQ2';


--
-- Name: COLUMN viva3_rc_history.form_version_mp___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_mp___2 IS 'BLD2';


--
-- Name: COLUMN viva3_rc_history.form_version_mp___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_mp___3 IS 'PSQ2';


--
-- Name: COLUMN viva3_rc_history.form_version_mp___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_mp___4 IS 'MPI2';


--
-- Name: COLUMN viva3_rc_history.form_label_del; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_del IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_del___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_del___1 IS 'DES3';


--
-- Name: COLUMN viva3_rc_history.form_version_del___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_del___2 IS 'NAN3';


--
-- Name: COLUMN viva3_rc_history.form_version_del___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_del___3 IS 'NBP3';


--
-- Name: COLUMN viva3_rc_history.form_version_del___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_del___4 IS 'NLG3';


--
-- Name: COLUMN viva3_rc_history.form_version_del___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_del___5 IS 'PSQ3';


--
-- Name: COLUMN viva3_rc_history.form_version_del___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_del___6 IS 'PSS3';


--
-- Name: COLUMN viva3_rc_history.form_version_del___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_del___7 IS 'DEI3';


--
-- Name: COLUMN viva3_rc_history.form_label_6m; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_6m IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_6m___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_6m___1 IS 'PSQ4';


--
-- Name: COLUMN viva3_rc_history.form_version_6m___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_6m___2 IS 'MSC4';


--
-- Name: COLUMN viva3_rc_history.form_version_6m___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_6m___3 IS 'VIS4';


--
-- Name: COLUMN viva3_rc_history.form_version_6m___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_6m___4 IS 'SMIR';


--
-- Name: COLUMN viva3_rc_history.form_version_6m___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_6m___5 IS 'SMSB4';


--
-- Name: COLUMN viva3_rc_history.form_version_6m___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_6m___6 IS 'SMSF4';


--
-- Name: COLUMN viva3_rc_history.form_version_6m___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_6m___7 IS 'SMSW4';


--
-- Name: COLUMN viva3_rc_history.form_version_6m___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_6m___8 IS 'SMSM4';


--
-- Name: COLUMN viva3_rc_history.form_version_6m___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_6m___9 IS 'SMQ4';


--
-- Name: COLUMN viva3_rc_history.form_version_6m___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_6m___10 IS 'MSM4';


--
-- Name: COLUMN viva3_rc_history.form_label_1y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_1y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_1y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_1y___1 IS 'OYQ';


--
-- Name: COLUMN viva3_rc_history.form_label_2y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_2y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_2y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_2y___1 IS 'SYQ/SYQ6';


--
-- Name: COLUMN viva3_rc_history.form_label_3y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_3y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___1 IS 'MAT7';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___2 IS 'CAT7';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___3 IS 'MBP7';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___4 IS 'CBP7';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___5 IS 'MBL7';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___6 IS 'CBL7';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___7 IS 'MCT7';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___8 IS 'CCT7';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___9 IS 'TYI';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___10 IS 'TYQ';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___11 IS 'TYS7';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___12 IS 'IBL7';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___13 IS 'IAC7';


--
-- Name: COLUMN viva3_rc_history.form_version_3y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_3y___14 IS 'IDC7';


--
-- Name: COLUMN viva3_rc_history.form_label_4y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_4y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_4y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_4y___1 IS '4YQ';


--
-- Name: COLUMN viva3_rc_history.form_label_5y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_5y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_5y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_5y___1 IS 'QU5Y';


--
-- Name: COLUMN viva3_rc_history.form_label_6y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_6y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_6y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_6y___1 IS 'QU6Y';


--
-- Name: COLUMN viva3_rc_history.form_label_7y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_7y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___1 IS 'MA7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___2 IS 'CA7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___3 IS 'BL7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___4 IS 'PE7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___5 IS 'HR7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___6 IS 'DX7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___7 IS 'BP7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___8 IS 'MC7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___9 IS 'CC7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___10 IS 'SP7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___11 IS 'BQ7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___12 IS 'TE7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___13 IS 'MI7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___14 IS 'IN7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___15 IS 'HP7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___16 IS 'ST7Y';


--
-- Name: COLUMN viva3_rc_history.form_version_7y___17; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_7y___17 IS 'QU7Y';


--
-- Name: COLUMN viva3_rc_history.form_label_8y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_8y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_8y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_8y___1 IS 'QU8Y';


--
-- Name: COLUMN viva3_rc_history.form_label_9y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_9y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_9y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_9y___1 IS 'QU9Y';


--
-- Name: COLUMN viva3_rc_history.form_version_9y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_9y___2 IS 'CQ9Y';


--
-- Name: COLUMN viva3_rc_history.form_label_10y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_10y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_10y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_10y___1 IS 'QU10';


--
-- Name: COLUMN viva3_rc_history.form_version_10y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_10y___2 IS 'CQ10';


--
-- Name: COLUMN viva3_rc_history.form_label_11y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_11y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_11y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_11y___1 IS 'QU11';


--
-- Name: COLUMN viva3_rc_history.form_version_11y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_11y___2 IS 'CQ11';


--
-- Name: COLUMN viva3_rc_history.form_label_12y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_12y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___1 IS 'MA12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___2 IS 'CA12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___3 IS 'SJ12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___4 IS 'BL12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___5 IS 'PE12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___6 IS 'HR12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___7 IS 'NS12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___8 IS 'BP12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___9 IS 'DX12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___10 IS 'NO12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___11 IS 'SP12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___12 IS 'MI12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___13 IS 'IN12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___14 IS 'ST12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___15 IS 'QU12';


--
-- Name: COLUMN viva3_rc_history.form_version_12y___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_12y___16 IS 'CQ12';


--
-- Name: COLUMN viva3_rc_history.form_label_14y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_14y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_14y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_14y___1 IS 'QU14';


--
-- Name: COLUMN viva3_rc_history.form_version_14y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_14y___2 IS 'CQ14';


--
-- Name: COLUMN viva3_rc_history.form_label_15y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_15y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_15y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_15y___1 IS 'QU15';


--
-- Name: COLUMN viva3_rc_history.form_version_15y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_15y___2 IS 'CQ15';


--
-- Name: COLUMN viva3_rc_history.form_label_16y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_16y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_16y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_16y___1 IS 'QU16';


--
-- Name: COLUMN viva3_rc_history.form_version_16y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_16y___2 IS 'CQ16';


--
-- Name: COLUMN viva3_rc_history.form_label_mt; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_mt IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_mt; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_mt IS 'Form Version';


--
-- Name: COLUMN viva3_rc_history.form_label_19y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_label_19y IS 'Form Label';


--
-- Name: COLUMN viva3_rc_history.form_version_19y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_19y___1 IS 'QU19';


--
-- Name: COLUMN viva3_rc_history.form_version_19y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.form_version_19y___2 IS 'TQ19';


--
-- Name: COLUMN viva3_rc_history.not_time_specific; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.not_time_specific IS 'Not time specific';


--
-- Name: COLUMN viva3_rc_history.model_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.model_type IS 'Model';


--
-- Name: COLUMN viva3_rc_history.elig_sample; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.elig_sample IS 'Eligible sample description';


--
-- Name: COLUMN viva3_rc_history.elig_n; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.elig_n IS 'Eligible sample N';


--
-- Name: COLUMN viva3_rc_history.actual_n; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.actual_n IS 'Actual sample N';


--
-- Name: COLUMN viva3_rc_history.an_var; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.an_var IS 'Analytic variable name';


--
-- Name: COLUMN viva3_rc_history.orig_deriv; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.orig_deriv IS 'Original or derived variable';


--
-- Name: COLUMN viva3_rc_history.corr_derived_yn___0; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.corr_derived_yn___0 IS 'No';


--
-- Name: COLUMN viva3_rc_history.corr_derived_yn___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.corr_derived_yn___1 IS 'Yes';


--
-- Name: COLUMN viva3_rc_history.der_varname; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.der_varname IS 'Name of corresponding derived variable';


--
-- Name: COLUMN viva3_rc_history.dervar_explain; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.dervar_explain IS 'Derived Variable Explanation';


--
-- Name: COLUMN viva3_rc_history.orig_varnames; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rc_history.orig_varnames IS 'Name of corresponding original variable(s)';


--
-- Name: viva3_rc_history_id_seq; Type: SEQUENCE; Schema: viva_ref_info; Owner: -
--

CREATE SEQUENCE viva_ref_info.viva3_rc_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva3_rc_history_id_seq; Type: SEQUENCE OWNED BY; Schema: viva_ref_info; Owner: -
--

ALTER SEQUENCE viva_ref_info.viva3_rc_history_id_seq OWNED BY viva_ref_info.viva3_rc_history.id;


--
-- Name: viva3_rcs; Type: TABLE; Schema: viva_ref_info; Owner: -
--

CREATE TABLE viva_ref_info.viva3_rcs (
    id bigint NOT NULL,
    varname character varying,
    var_label character varying,
    var_type character varying,
    restrict_var___0 boolean,
    restrict_var___1 boolean,
    restrict_var___2 boolean,
    restrict_var___3 boolean,
    restrict_var___4 boolean,
    oth_restrict character varying,
    domain_viva character varying,
    subdomain___1 boolean,
    subdomain___2 boolean,
    target_of_q character varying,
    data_source character varying,
    val_instr character varying,
    ext_instrument character varying,
    internal_instrument character varying,
    doc_yn character varying,
    doc_link character varying,
    var_level character varying,
    units character varying,
    response_options character varying,
    long_yn character varying,
    long_timepts___1 boolean,
    long_timepts___2 boolean,
    long_timepts___3 boolean,
    long_timepts___4 boolean,
    long_timepts___5 boolean,
    long_timepts___6 boolean,
    long_timepts___7 boolean,
    long_timepts___8 boolean,
    long_timepts___9 boolean,
    long_timepts___10 boolean,
    long_timepts___11 boolean,
    long_timepts___12 boolean,
    long_timepts___13 boolean,
    long_timepts___14 boolean,
    long_timepts___15 boolean,
    long_timepts___16 boolean,
    long_timepts___17 boolean,
    long_timepts___18 boolean,
    long_timepts___19 boolean,
    long_timepts___20 boolean,
    long_timepts___21 boolean,
    long_timepts___22 boolean,
    long_timepts___23 boolean,
    static_variable_information_complete integer,
    event_type character varying,
    visit_name character varying,
    visit_time character varying,
    assay_specimen character varying,
    assay_type character varying,
    lab_assay_dataset character varying,
    form_label_ep character varying,
    form_version_ep___1 boolean,
    form_version_ep___2 boolean,
    form_version_ep___3 boolean,
    form_version_ep___4 boolean,
    form_version_ep___5 boolean,
    form_version_ep___6 boolean,
    form_version_ep___7 boolean,
    form_version_ep___8 boolean,
    form_label_mp character varying,
    form_version_mp___1 boolean,
    form_version_mp___2 boolean,
    form_version_mp___3 boolean,
    form_version_mp___4 boolean,
    form_label_del character varying,
    form_version_del___1 boolean,
    form_version_del___2 boolean,
    form_version_del___3 boolean,
    form_version_del___4 boolean,
    form_version_del___5 boolean,
    form_version_del___6 boolean,
    form_version_del___7 boolean,
    form_label_6m character varying,
    form_version_6m___1 boolean,
    form_version_6m___2 boolean,
    form_version_6m___3 boolean,
    form_version_6m___4 boolean,
    form_version_6m___5 boolean,
    form_version_6m___6 boolean,
    form_version_6m___7 boolean,
    form_version_6m___8 boolean,
    form_version_6m___9 boolean,
    form_version_6m___10 boolean,
    form_label_1y character varying,
    form_version_1y___1 boolean,
    form_label_2y character varying,
    form_version_2y___1 boolean,
    form_label_3y character varying,
    form_version_3y___1 boolean,
    form_version_3y___2 boolean,
    form_version_3y___3 boolean,
    form_version_3y___4 boolean,
    form_version_3y___5 boolean,
    form_version_3y___6 boolean,
    form_version_3y___7 boolean,
    form_version_3y___8 boolean,
    form_version_3y___9 boolean,
    form_version_3y___10 boolean,
    form_version_3y___11 boolean,
    form_version_3y___12 boolean,
    form_version_3y___13 boolean,
    form_version_3y___14 boolean,
    form_label_4y character varying,
    form_version_4y___1 boolean,
    form_label_5y character varying,
    form_version_5y___1 boolean,
    form_label_6y character varying,
    form_version_6y___1 boolean,
    form_label_7y character varying,
    form_version_7y___1 boolean,
    form_version_7y___2 boolean,
    form_version_7y___3 boolean,
    form_version_7y___4 boolean,
    form_version_7y___5 boolean,
    form_version_7y___6 boolean,
    form_version_7y___7 boolean,
    form_version_7y___8 boolean,
    form_version_7y___9 boolean,
    form_version_7y___10 boolean,
    form_version_7y___11 boolean,
    form_version_7y___12 boolean,
    form_version_7y___13 boolean,
    form_version_7y___14 boolean,
    form_version_7y___15 boolean,
    form_version_7y___16 boolean,
    form_version_7y___17 boolean,
    form_label_8y character varying,
    form_version_8y___1 boolean,
    form_label_9y character varying,
    form_version_9y___1 boolean,
    form_version_9y___2 boolean,
    form_label_10y character varying,
    form_version_10y___1 boolean,
    form_version_10y___2 boolean,
    form_label_11y character varying,
    form_version_11y___1 boolean,
    form_version_11y___2 boolean,
    form_label_12y character varying,
    form_version_12y___1 boolean,
    form_version_12y___2 boolean,
    form_version_12y___3 boolean,
    form_version_12y___4 boolean,
    form_version_12y___5 boolean,
    form_version_12y___6 boolean,
    form_version_12y___7 boolean,
    form_version_12y___8 boolean,
    form_version_12y___9 boolean,
    form_version_12y___10 boolean,
    form_version_12y___11 boolean,
    form_version_12y___12 boolean,
    form_version_12y___13 boolean,
    form_version_12y___14 boolean,
    form_version_12y___15 boolean,
    form_version_12y___16 boolean,
    form_label_14y character varying,
    form_version_14y___1 boolean,
    form_version_14y___2 boolean,
    form_label_15y character varying,
    form_version_15y___1 boolean,
    form_version_15y___2 boolean,
    form_label_16y character varying,
    form_version_16y___1 boolean,
    form_version_16y___2 boolean,
    form_label_mt character varying,
    form_version_mt character varying,
    form_label_19y character varying,
    form_version_19y___1 boolean,
    form_version_19y___2 boolean,
    not_time_specific character varying,
    model_type character varying,
    elig_sample character varying,
    elig_n character varying,
    actual_n character varying,
    an_var character varying,
    orig_deriv character varying,
    corr_derived_yn___0 boolean,
    corr_derived_yn___1 boolean,
    der_varname character varying,
    dervar_explain character varying,
    orig_varnames character varying,
    visitspecific_information_complete integer,
    redcap_repeat_instrument character varying,
    redcap_repeat_instance character varying,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE viva3_rcs; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON TABLE viva_ref_info.viva3_rcs IS 'Dynamicmodel: Viva Data Variable';


--
-- Name: COLUMN viva3_rcs.varname; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.varname IS 'Variable name';


--
-- Name: COLUMN viva3_rcs.var_label; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.var_label IS 'Variable label';


--
-- Name: COLUMN viva3_rcs.var_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.var_type IS 'Type of variable';


--
-- Name: COLUMN viva3_rcs.restrict_var___0; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.restrict_var___0 IS 'None';


--
-- Name: COLUMN viva3_rcs.restrict_var___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.restrict_var___1 IS 'PHI, OK for limited dataset';


--
-- Name: COLUMN viva3_rcs.restrict_var___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.restrict_var___2 IS 'PHI, restricted use';


--
-- Name: COLUMN viva3_rcs.restrict_var___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.restrict_var___3 IS 'Sensitive information';


--
-- Name: COLUMN viva3_rcs.restrict_var___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.restrict_var___4 IS 'Other restriction';


--
-- Name: COLUMN viva3_rcs.oth_restrict; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.oth_restrict IS 'Specify other restriction';


--
-- Name: COLUMN viva3_rcs.domain_viva; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.domain_viva IS 'Domain or topic area';


--
-- Name: COLUMN viva3_rcs.subdomain___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.subdomain___1 IS 'Placeholder';


--
-- Name: COLUMN viva3_rcs.subdomain___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.subdomain___2 IS 'Placeholder';


--
-- Name: COLUMN viva3_rcs.target_of_q; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.target_of_q IS 'Target';


--
-- Name: COLUMN viva3_rcs.data_source; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.data_source IS 'Source of data';


--
-- Name: COLUMN viva3_rcs.val_instr; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.val_instr IS 'Please indicate whether the question comes from an external, internal, or no instrument.';


--
-- Name: COLUMN viva3_rcs.ext_instrument; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.ext_instrument IS 'External instrument';


--
-- Name: COLUMN viva3_rcs.internal_instrument; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.internal_instrument IS 'Internal instrument';


--
-- Name: COLUMN viva3_rcs.doc_yn; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.doc_yn IS 'Documentation available?';


--
-- Name: COLUMN viva3_rcs.doc_link; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.doc_link IS 'Documentation link';


--
-- Name: COLUMN viva3_rcs.var_level; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.var_level IS 'Variable Level';


--
-- Name: COLUMN viva3_rcs.units; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.units IS 'Units';


--
-- Name: COLUMN viva3_rcs.response_options; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.response_options IS 'Response Options';


--
-- Name: COLUMN viva3_rcs.long_yn; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_yn IS 'Longitudinal measurement?';


--
-- Name: COLUMN viva3_rcs.long_timepts___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___1 IS 'Screening';


--
-- Name: COLUMN viva3_rcs.long_timepts___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___2 IS 'Early pregnancy';


--
-- Name: COLUMN viva3_rcs.long_timepts___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___3 IS 'Mid-pregnancy';


--
-- Name: COLUMN viva3_rcs.long_timepts___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___4 IS 'Delivery';


--
-- Name: COLUMN viva3_rcs.long_timepts___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___5 IS 'Infancy (6 months)';


--
-- Name: COLUMN viva3_rcs.long_timepts___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___6 IS '1 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___7 IS '2 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___8 IS 'Early childhood (3 year)';


--
-- Name: COLUMN viva3_rcs.long_timepts___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___9 IS '4 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___10 IS '5 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___11 IS '6 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___12 IS 'Mid childhood (7-8 years)';


--
-- Name: COLUMN viva3_rcs.long_timepts___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___13 IS '8 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___14 IS '9 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___15 IS '10 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___16 IS '11 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___17; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___17 IS 'Early adolescence (12-13 years)';


--
-- Name: COLUMN viva3_rcs.long_timepts___18; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___18 IS '14 years';


--
-- Name: COLUMN viva3_rcs.long_timepts___19; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___19 IS '15 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___20; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___20 IS '16 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___21; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___21 IS 'Mid/late adolescence (17-18 years)';


--
-- Name: COLUMN viva3_rcs.long_timepts___22; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___22 IS '19 year';


--
-- Name: COLUMN viva3_rcs.long_timepts___23; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.long_timepts___23 IS 'Not time specific';


--
-- Name: COLUMN viva3_rcs.event_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.event_type IS 'Type of data collection event';


--
-- Name: COLUMN viva3_rcs.visit_name; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.visit_name IS 'Visit name';


--
-- Name: COLUMN viva3_rcs.visit_time; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.visit_time IS 'Visit target time point';


--
-- Name: COLUMN viva3_rcs.assay_specimen; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.assay_specimen IS 'Lab Assay Specimen Source';


--
-- Name: COLUMN viva3_rcs.assay_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.assay_type IS 'Laboratory assay type';


--
-- Name: COLUMN viva3_rcs.lab_assay_dataset; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.lab_assay_dataset IS 'Laboratory Assay \''Form\'' (Dataset)';


--
-- Name: COLUMN viva3_rcs.form_label_ep; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_ep IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_ep___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_ep___1 IS 'EPQ';


--
-- Name: COLUMN viva3_rcs.form_version_ep___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_ep___2 IS 'EPQ1';


--
-- Name: COLUMN viva3_rcs.form_version_ep___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_ep___3 IS 'EPQA';


--
-- Name: COLUMN viva3_rcs.form_version_ep___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_ep___4 IS 'EPS1';


--
-- Name: COLUMN viva3_rcs.form_version_ep___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_ep___5 IS 'EPI1';


--
-- Name: COLUMN viva3_rcs.form_version_ep___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_ep___6 IS 'EPIA';


--
-- Name: COLUMN viva3_rcs.form_version_ep___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_ep___7 IS 'SCR1';


--
-- Name: COLUMN viva3_rcs.form_version_ep___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_ep___8 IS 'BLD1';


--
-- Name: COLUMN viva3_rcs.form_label_mp; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_mp IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_mp___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_mp___1 IS 'MPQ2';


--
-- Name: COLUMN viva3_rcs.form_version_mp___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_mp___2 IS 'BLD2';


--
-- Name: COLUMN viva3_rcs.form_version_mp___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_mp___3 IS 'PSQ2';


--
-- Name: COLUMN viva3_rcs.form_version_mp___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_mp___4 IS 'MPI2';


--
-- Name: COLUMN viva3_rcs.form_label_del; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_del IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_del___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_del___1 IS 'DES3';


--
-- Name: COLUMN viva3_rcs.form_version_del___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_del___2 IS 'NAN3';


--
-- Name: COLUMN viva3_rcs.form_version_del___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_del___3 IS 'NBP3';


--
-- Name: COLUMN viva3_rcs.form_version_del___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_del___4 IS 'NLG3';


--
-- Name: COLUMN viva3_rcs.form_version_del___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_del___5 IS 'PSQ3';


--
-- Name: COLUMN viva3_rcs.form_version_del___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_del___6 IS 'PSS3';


--
-- Name: COLUMN viva3_rcs.form_version_del___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_del___7 IS 'DEI3';


--
-- Name: COLUMN viva3_rcs.form_label_6m; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_6m IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_6m___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_6m___1 IS 'PSQ4';


--
-- Name: COLUMN viva3_rcs.form_version_6m___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_6m___2 IS 'MSC4';


--
-- Name: COLUMN viva3_rcs.form_version_6m___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_6m___3 IS 'VIS4';


--
-- Name: COLUMN viva3_rcs.form_version_6m___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_6m___4 IS 'SMIR';


--
-- Name: COLUMN viva3_rcs.form_version_6m___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_6m___5 IS 'SMSB4';


--
-- Name: COLUMN viva3_rcs.form_version_6m___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_6m___6 IS 'SMSF4';


--
-- Name: COLUMN viva3_rcs.form_version_6m___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_6m___7 IS 'SMSW4';


--
-- Name: COLUMN viva3_rcs.form_version_6m___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_6m___8 IS 'SMSM4';


--
-- Name: COLUMN viva3_rcs.form_version_6m___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_6m___9 IS 'SMQ4';


--
-- Name: COLUMN viva3_rcs.form_version_6m___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_6m___10 IS 'MSM4';


--
-- Name: COLUMN viva3_rcs.form_label_1y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_1y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_1y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_1y___1 IS 'OYQ';


--
-- Name: COLUMN viva3_rcs.form_label_2y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_2y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_2y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_2y___1 IS 'SYQ/SYQ6';


--
-- Name: COLUMN viva3_rcs.form_label_3y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_3y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_3y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___1 IS 'MAT7';


--
-- Name: COLUMN viva3_rcs.form_version_3y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___2 IS 'CAT7';


--
-- Name: COLUMN viva3_rcs.form_version_3y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___3 IS 'MBP7';


--
-- Name: COLUMN viva3_rcs.form_version_3y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___4 IS 'CBP7';


--
-- Name: COLUMN viva3_rcs.form_version_3y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___5 IS 'MBL7';


--
-- Name: COLUMN viva3_rcs.form_version_3y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___6 IS 'CBL7';


--
-- Name: COLUMN viva3_rcs.form_version_3y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___7 IS 'MCT7';


--
-- Name: COLUMN viva3_rcs.form_version_3y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___8 IS 'CCT7';


--
-- Name: COLUMN viva3_rcs.form_version_3y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___9 IS 'TYI';


--
-- Name: COLUMN viva3_rcs.form_version_3y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___10 IS 'TYQ';


--
-- Name: COLUMN viva3_rcs.form_version_3y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___11 IS 'TYS7';


--
-- Name: COLUMN viva3_rcs.form_version_3y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___12 IS 'IBL7';


--
-- Name: COLUMN viva3_rcs.form_version_3y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___13 IS 'IAC7';


--
-- Name: COLUMN viva3_rcs.form_version_3y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_3y___14 IS 'IDC7';


--
-- Name: COLUMN viva3_rcs.form_label_4y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_4y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_4y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_4y___1 IS '4YQ';


--
-- Name: COLUMN viva3_rcs.form_label_5y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_5y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_5y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_5y___1 IS 'QU5Y';


--
-- Name: COLUMN viva3_rcs.form_label_6y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_6y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_6y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_6y___1 IS 'QU6Y';


--
-- Name: COLUMN viva3_rcs.form_label_7y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_7y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_7y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___1 IS 'MA7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___2 IS 'CA7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___3 IS 'BL7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___4 IS 'PE7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___5 IS 'HR7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___6 IS 'DX7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___7 IS 'BP7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___8 IS 'MC7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___9 IS 'CC7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___10 IS 'SP7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___11 IS 'BQ7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___12 IS 'TE7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___13 IS 'MI7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___14 IS 'IN7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___15 IS 'HP7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___16 IS 'ST7Y';


--
-- Name: COLUMN viva3_rcs.form_version_7y___17; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_7y___17 IS 'QU7Y';


--
-- Name: COLUMN viva3_rcs.form_label_8y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_8y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_8y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_8y___1 IS 'QU8Y';


--
-- Name: COLUMN viva3_rcs.form_label_9y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_9y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_9y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_9y___1 IS 'QU9Y';


--
-- Name: COLUMN viva3_rcs.form_version_9y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_9y___2 IS 'CQ9Y';


--
-- Name: COLUMN viva3_rcs.form_label_10y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_10y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_10y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_10y___1 IS 'QU10';


--
-- Name: COLUMN viva3_rcs.form_version_10y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_10y___2 IS 'CQ10';


--
-- Name: COLUMN viva3_rcs.form_label_11y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_11y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_11y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_11y___1 IS 'QU11';


--
-- Name: COLUMN viva3_rcs.form_version_11y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_11y___2 IS 'CQ11';


--
-- Name: COLUMN viva3_rcs.form_label_12y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_12y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_12y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___1 IS 'MA12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___2 IS 'CA12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___3; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___3 IS 'SJ12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___4; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___4 IS 'BL12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___5; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___5 IS 'PE12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___6; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___6 IS 'HR12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___7; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___7 IS 'NS12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___8; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___8 IS 'BP12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___9; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___9 IS 'DX12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___10; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___10 IS 'NO12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___11; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___11 IS 'SP12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___12; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___12 IS 'MI12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___13; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___13 IS 'IN12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___14; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___14 IS 'ST12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___15; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___15 IS 'QU12';


--
-- Name: COLUMN viva3_rcs.form_version_12y___16; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_12y___16 IS 'CQ12';


--
-- Name: COLUMN viva3_rcs.form_label_14y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_14y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_14y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_14y___1 IS 'QU14';


--
-- Name: COLUMN viva3_rcs.form_version_14y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_14y___2 IS 'CQ14';


--
-- Name: COLUMN viva3_rcs.form_label_15y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_15y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_15y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_15y___1 IS 'QU15';


--
-- Name: COLUMN viva3_rcs.form_version_15y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_15y___2 IS 'CQ15';


--
-- Name: COLUMN viva3_rcs.form_label_16y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_16y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_16y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_16y___1 IS 'QU16';


--
-- Name: COLUMN viva3_rcs.form_version_16y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_16y___2 IS 'CQ16';


--
-- Name: COLUMN viva3_rcs.form_label_mt; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_mt IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_mt; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_mt IS 'Form Version';


--
-- Name: COLUMN viva3_rcs.form_label_19y; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_label_19y IS 'Form Label';


--
-- Name: COLUMN viva3_rcs.form_version_19y___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_19y___1 IS 'QU19';


--
-- Name: COLUMN viva3_rcs.form_version_19y___2; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.form_version_19y___2 IS 'TQ19';


--
-- Name: COLUMN viva3_rcs.not_time_specific; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.not_time_specific IS 'Not time specific';


--
-- Name: COLUMN viva3_rcs.model_type; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.model_type IS 'Model';


--
-- Name: COLUMN viva3_rcs.elig_sample; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.elig_sample IS 'Eligible sample description';


--
-- Name: COLUMN viva3_rcs.elig_n; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.elig_n IS 'Eligible sample N';


--
-- Name: COLUMN viva3_rcs.actual_n; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.actual_n IS 'Actual sample N';


--
-- Name: COLUMN viva3_rcs.an_var; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.an_var IS 'Analytic variable name';


--
-- Name: COLUMN viva3_rcs.orig_deriv; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.orig_deriv IS 'Original or derived variable';


--
-- Name: COLUMN viva3_rcs.corr_derived_yn___0; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.corr_derived_yn___0 IS 'No';


--
-- Name: COLUMN viva3_rcs.corr_derived_yn___1; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.corr_derived_yn___1 IS 'Yes';


--
-- Name: COLUMN viva3_rcs.der_varname; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.der_varname IS 'Name of corresponding derived variable';


--
-- Name: COLUMN viva3_rcs.dervar_explain; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.dervar_explain IS 'Derived Variable Explanation';


--
-- Name: COLUMN viva3_rcs.orig_varnames; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva3_rcs.orig_varnames IS 'Name of corresponding original variable(s)';


--
-- Name: viva3_rcs_id_seq; Type: SEQUENCE; Schema: viva_ref_info; Owner: -
--

CREATE SEQUENCE viva_ref_info.viva3_rcs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva3_rcs_id_seq; Type: SEQUENCE OWNED BY; Schema: viva_ref_info; Owner: -
--

ALTER SEQUENCE viva_ref_info.viva3_rcs_id_seq OWNED BY viva_ref_info.viva3_rcs.id;


--
-- Name: viva_collection_instrument_history; Type: TABLE; Schema: viva_ref_info; Owner: -
--

CREATE TABLE viva_ref_info.viva_collection_instrument_history (
    id bigint NOT NULL,
    name character varying,
    select_data_source character varying,
    select_data_target character varying,
    select_record_id_from_viva_domains integer[],
    select_record_id_from_viva_timepoints integer,
    sample_file character varying,
    disabled boolean DEFAULT false,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    viva_collection_instrument_id bigint
);


--
-- Name: COLUMN viva_collection_instrument_history.name; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instrument_history.name IS 'Instrument Name';


--
-- Name: COLUMN viva_collection_instrument_history.select_data_source; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instrument_history.select_data_source IS 'Data Source';


--
-- Name: COLUMN viva_collection_instrument_history.select_data_target; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instrument_history.select_data_target IS 'Data Target';


--
-- Name: COLUMN viva_collection_instrument_history.select_record_id_from_viva_domains; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instrument_history.select_record_id_from_viva_domains IS 'Domain';


--
-- Name: COLUMN viva_collection_instrument_history.select_record_id_from_viva_timepoints; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instrument_history.select_record_id_from_viva_timepoints IS 'Timepoint or Visit';


--
-- Name: COLUMN viva_collection_instrument_history.sample_file; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instrument_history.sample_file IS 'Sample Form File';


--
-- Name: viva_collection_instrument_history_id_seq; Type: SEQUENCE; Schema: viva_ref_info; Owner: -
--

CREATE SEQUENCE viva_ref_info.viva_collection_instrument_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva_collection_instrument_history_id_seq; Type: SEQUENCE OWNED BY; Schema: viva_ref_info; Owner: -
--

ALTER SEQUENCE viva_ref_info.viva_collection_instrument_history_id_seq OWNED BY viva_ref_info.viva_collection_instrument_history.id;


--
-- Name: viva_collection_instruments; Type: TABLE; Schema: viva_ref_info; Owner: -
--

CREATE TABLE viva_ref_info.viva_collection_instruments (
    id bigint NOT NULL,
    name character varying,
    select_data_source character varying,
    select_data_target character varying,
    select_record_id_from_viva_domains integer[],
    select_record_id_from_viva_timepoints integer,
    sample_file character varying,
    disabled boolean DEFAULT false,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE viva_collection_instruments; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON TABLE viva_ref_info.viva_collection_instruments IS 'Viva Collection Instruments';


--
-- Name: COLUMN viva_collection_instruments.name; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instruments.name IS 'Instrument Name';


--
-- Name: COLUMN viva_collection_instruments.select_data_source; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instruments.select_data_source IS 'Data Source';


--
-- Name: COLUMN viva_collection_instruments.select_data_target; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instruments.select_data_target IS 'Data Target';


--
-- Name: COLUMN viva_collection_instruments.select_record_id_from_viva_domains; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instruments.select_record_id_from_viva_domains IS 'Domain';


--
-- Name: COLUMN viva_collection_instruments.select_record_id_from_viva_timepoints; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instruments.select_record_id_from_viva_timepoints IS 'Timepoint or Visit';


--
-- Name: COLUMN viva_collection_instruments.sample_file; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_collection_instruments.sample_file IS 'Sample Form File';


--
-- Name: viva_collection_instruments_id_seq; Type: SEQUENCE; Schema: viva_ref_info; Owner: -
--

CREATE SEQUENCE viva_ref_info.viva_collection_instruments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva_collection_instruments_id_seq; Type: SEQUENCE OWNED BY; Schema: viva_ref_info; Owner: -
--

ALTER SEQUENCE viva_ref_info.viva_collection_instruments_id_seq OWNED BY viva_ref_info.viva_collection_instruments.id;


--
-- Name: viva_domain_history; Type: TABLE; Schema: viva_ref_info; Owner: -
--

CREATE TABLE viva_ref_info.viva_domain_history (
    id bigint NOT NULL,
    select_topic character varying,
    domain character varying,
    sub_domain character varying,
    disabled boolean DEFAULT false,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    viva_domain_id bigint
);


--
-- Name: COLUMN viva_domain_history.select_topic; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_domain_history.select_topic IS 'Primary Domain Topic';


--
-- Name: COLUMN viva_domain_history.domain; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_domain_history.domain IS 'Domain';


--
-- Name: COLUMN viva_domain_history.sub_domain; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_domain_history.sub_domain IS 'Sub Domain';


--
-- Name: viva_domain_history_id_seq; Type: SEQUENCE; Schema: viva_ref_info; Owner: -
--

CREATE SEQUENCE viva_ref_info.viva_domain_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva_domain_history_id_seq; Type: SEQUENCE OWNED BY; Schema: viva_ref_info; Owner: -
--

ALTER SEQUENCE viva_ref_info.viva_domain_history_id_seq OWNED BY viva_ref_info.viva_domain_history.id;


--
-- Name: viva_domains; Type: TABLE; Schema: viva_ref_info; Owner: -
--

CREATE TABLE viva_ref_info.viva_domains (
    id bigint NOT NULL,
    select_topic character varying,
    domain character varying,
    sub_domain character varying,
    disabled boolean DEFAULT false,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE viva_domains; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON TABLE viva_ref_info.viva_domains IS 'Viva Domains';


--
-- Name: COLUMN viva_domains.select_topic; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_domains.select_topic IS 'Primary Domain Topic';


--
-- Name: COLUMN viva_domains.domain; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_domains.domain IS 'Domain';


--
-- Name: COLUMN viva_domains.sub_domain; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON COLUMN viva_ref_info.viva_domains.sub_domain IS 'Sub Domain';


--
-- Name: viva_domains_id_seq; Type: SEQUENCE; Schema: viva_ref_info; Owner: -
--

CREATE SEQUENCE viva_ref_info.viva_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva_domains_id_seq; Type: SEQUENCE OWNED BY; Schema: viva_ref_info; Owner: -
--

ALTER SEQUENCE viva_ref_info.viva_domains_id_seq OWNED BY viva_ref_info.viva_domains.id;


--
-- Name: viva_rc_domains; Type: VIEW; Schema: viva_ref_info; Owner: -
--

CREATE VIEW viva_ref_info.viva_rc_domains AS
 SELECT (datadic_choices.value)::integer AS id,
    datadic_choices.label
   FROM ref_data.datadic_choices
  WHERE (((datadic_choices.field_name)::text = 'domain_viva'::text) AND (datadic_choices.redcap_data_dictionary_id = 51))
  ORDER BY (datadic_choices.value)::integer;


--
-- Name: viva_timepoint_history; Type: TABLE; Schema: viva_ref_info; Owner: -
--

CREATE TABLE viva_ref_info.viva_timepoint_history (
    id bigint NOT NULL,
    name character varying,
    disabled boolean DEFAULT false,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    viva_timepoint_id bigint
);


--
-- Name: viva_timepoint_history_id_seq; Type: SEQUENCE; Schema: viva_ref_info; Owner: -
--

CREATE SEQUENCE viva_ref_info.viva_timepoint_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva_timepoint_history_id_seq; Type: SEQUENCE OWNED BY; Schema: viva_ref_info; Owner: -
--

ALTER SEQUENCE viva_ref_info.viva_timepoint_history_id_seq OWNED BY viva_ref_info.viva_timepoint_history.id;


--
-- Name: viva_timepoints; Type: TABLE; Schema: viva_ref_info; Owner: -
--

CREATE TABLE viva_ref_info.viva_timepoints (
    id bigint NOT NULL,
    name character varying,
    disabled boolean DEFAULT false,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE viva_timepoints; Type: COMMENT; Schema: viva_ref_info; Owner: -
--

COMMENT ON TABLE viva_ref_info.viva_timepoints IS 'Dynamicmodel: Viva Timepoints';


--
-- Name: viva_timepoints_id_seq; Type: SEQUENCE; Schema: viva_ref_info; Owner: -
--

CREATE SEQUENCE viva_ref_info.viva_timepoints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viva_timepoints_id_seq; Type: SEQUENCE OWNED BY; Schema: viva_ref_info; Owner: -
--

ALTER SEQUENCE viva_ref_info.viva_timepoints_id_seq OWNED BY viva_ref_info.viva_timepoints.id;


--
-- Name: viva_view_variables; Type: VIEW; Schema: viva_ref_info; Owner: -
--

CREATE VIEW viva_ref_info.viva_view_variables AS
 SELECT vars.id,
    dc_varuse.label AS study,
    (COALESCE(NULLIF((dc_extin.label)::text, ''::text), (vars.internal_instrument)::text))::character varying AS source_name,
    dc_intype.label AS source_type,
    (lower((COALESCE(dom.label, '(not set)'::character varying))::text))::character varying AS domain,
    ''::text AS form_name,
    vars.varname AS variable_name,
    lower((dc_vtype.label)::text) AS variable_type,
    NULL::text AS presentation_type,
    vars.var_label AS label,
    dc_vistime.label AS visit_time
   FROM ((((((viva_ref_info.viva3_rcs vars
     LEFT JOIN ref_data.datadic_choices dc_varuse ON ((((vars.var_type)::text <> ''::text) AND ((vars.var_type)::text = (dc_varuse.value)::text) AND (dc_varuse.redcap_data_dictionary_id = 52) AND ((dc_varuse.field_name)::text = 'var_type'::text))))
     LEFT JOIN ref_data.datadic_choices dc_extin ON ((((vars.ext_instrument)::text <> ''::text) AND ((vars.ext_instrument)::text = (dc_extin.value)::text) AND (dc_extin.redcap_data_dictionary_id = 52) AND ((dc_extin.field_name)::text = 'ext_instrument'::text))))
     LEFT JOIN ref_data.datadic_choices dc_intype ON ((((vars.val_instr)::text <> ''::text) AND ((vars.val_instr)::text = (dc_intype.value)::text) AND (dc_intype.redcap_data_dictionary_id = 52) AND ((dc_intype.field_name)::text = 'val_instr'::text))))
     LEFT JOIN ref_data.datadic_choices dc_vtype ON ((((vars.var_level)::text <> ''::text) AND ((vars.var_level)::text = (dc_vtype.value)::text) AND (dc_vtype.redcap_data_dictionary_id = 52) AND ((dc_vtype.field_name)::text = 'var_level'::text))))
     LEFT JOIN viva_ref_info.viva_rc_domains dom ON (((vars.domain_viva)::text = ((dom.id)::character varying)::text)))
     LEFT JOIN ref_data.datadic_choices dc_vistime ON ((((vars.visit_time)::text <> ''::text) AND ((vars.visit_time)::text = (dc_vistime.value)::text) AND (dc_vistime.redcap_data_dictionary_id = 52) AND ((dc_vistime.field_name)::text = 'visit_time'::text))));


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignment_history ALTER COLUMN id SET DEFAULT nextval('data_requests.activity_log_data_request_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignments ALTER COLUMN id SET DEFAULT nextval('data_requests.activity_log_data_request_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_assignment_history ALTER COLUMN id SET DEFAULT nextval('data_requests.data_request_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_assignments ALTER COLUMN id SET DEFAULT nextval('data_requests.data_request_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_attrib_history ALTER COLUMN id SET DEFAULT nextval('data_requests.data_request_attrib_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_attribs ALTER COLUMN id SET DEFAULT nextval('data_requests.data_request_attribs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_history ALTER COLUMN id SET DEFAULT nextval('data_requests.data_request_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_initial_review_history ALTER COLUMN id SET DEFAULT nextval('data_requests.data_request_initial_review_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_initial_reviews ALTER COLUMN id SET DEFAULT nextval('data_requests.data_request_initial_reviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_message_history ALTER COLUMN id SET DEFAULT nextval('data_requests.data_request_message_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_messages ALTER COLUMN id SET DEFAULT nextval('data_requests.data_request_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests ALTER COLUMN id SET DEFAULT nextval('data_requests.data_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests_selected_attrib_history ALTER COLUMN id SET DEFAULT nextval('data_requests.data_requests_selected_attrib_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests_selected_attribs ALTER COLUMN id SET DEFAULT nextval('data_requests.data_requests_selected_attribs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.q1_datadic ALTER COLUMN id SET DEFAULT nextval('data_requests.q1_datadic_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.q2_datadic ALTER COLUMN id SET DEFAULT nextval('data_requests.q2_datadic_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profiile_detail_history ALTER COLUMN id SET DEFAULT nextval('data_requests.user_profiile_detail_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profiile_details ALTER COLUMN id SET DEFAULT nextval('data_requests.user_profiile_details_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_academic_detail_history ALTER COLUMN id SET DEFAULT nextval('data_requests.user_profile_academic_detail_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_academic_details ALTER COLUMN id SET DEFAULT nextval('data_requests.user_profile_academic_details_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_detail_history ALTER COLUMN id SET DEFAULT nextval('data_requests.user_profile_detail_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_details ALTER COLUMN id SET DEFAULT nextval('data_requests.user_profile_details_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.grit_assignment_history ALTER COLUMN id SET DEFAULT nextval('extra_app.grit_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.grit_assignments ALTER COLUMN id SET DEFAULT nextval('extra_app.grit_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.pitt_bhi_assignment_history ALTER COLUMN id SET DEFAULT nextval('extra_app.pitt_bhi_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.pitt_bhi_assignments ALTER COLUMN id SET DEFAULT nextval('extra_app.pitt_bhi_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.sleep_assignment_history ALTER COLUMN id SET DEFAULT nextval('extra_app.sleep_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.sleep_assignments ALTER COLUMN id SET DEFAULT nextval('extra_app.sleep_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.accuracy_score_history ALTER COLUMN id SET DEFAULT nextval('ml_app.accuracy_score_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.accuracy_scores ALTER COLUMN id SET DEFAULT nextval('ml_app.accuracy_scores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_history ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phone_history ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_player_contact_phone_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phones ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_player_contact_phones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_logs ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.address_history ALTER COLUMN id SET DEFAULT nextval('ml_app.address_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.addresses ALTER COLUMN id SET DEFAULT nextval('ml_app.addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.admin_action_logs ALTER COLUMN id SET DEFAULT nextval('ml_app.admin_action_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.admin_history ALTER COLUMN id SET DEFAULT nextval('ml_app.admin_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.admins ALTER COLUMN id SET DEFAULT nextval('ml_app.admins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_configuration_history ALTER COLUMN id SET DEFAULT nextval('ml_app.app_configuration_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_configurations ALTER COLUMN id SET DEFAULT nextval('ml_app.app_configurations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_type_history ALTER COLUMN id SET DEFAULT nextval('ml_app.app_type_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_types ALTER COLUMN id SET DEFAULT nextval('ml_app.app_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.college_history ALTER COLUMN id SET DEFAULT nextval('ml_app.college_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.colleges ALTER COLUMN id SET DEFAULT nextval('ml_app.colleges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.config_libraries ALTER COLUMN id SET DEFAULT nextval('ml_app.config_libraries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.config_library_history ALTER COLUMN id SET DEFAULT nextval('ml_app.config_library_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('ml_app.delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.dynamic_model_history ALTER COLUMN id SET DEFAULT nextval('ml_app.dynamic_model_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.dynamic_models ALTER COLUMN id SET DEFAULT nextval('ml_app.dynamic_models_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.exception_logs ALTER COLUMN id SET DEFAULT nextval('ml_app.exception_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_identifier_history ALTER COLUMN id SET DEFAULT nextval('ml_app.external_identifier_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_identifiers ALTER COLUMN id SET DEFAULT nextval('ml_app.external_identifiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_link_history ALTER COLUMN id SET DEFAULT nextval('ml_app.external_link_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_links ALTER COLUMN id SET DEFAULT nextval('ml_app.external_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.general_selection_history ALTER COLUMN id SET DEFAULT nextval('ml_app.general_selection_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.general_selections ALTER COLUMN id SET DEFAULT nextval('ml_app.general_selections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.imports ALTER COLUMN id SET DEFAULT nextval('ml_app.imports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.imports_model_generators ALTER COLUMN id SET DEFAULT nextval('ml_app.imports_model_generators_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flag_history ALTER COLUMN id SET DEFAULT nextval('ml_app.item_flag_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flag_name_history ALTER COLUMN id SET DEFAULT nextval('ml_app.item_flag_name_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flag_names ALTER COLUMN id SET DEFAULT nextval('ml_app.item_flag_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flags ALTER COLUMN id SET DEFAULT nextval('ml_app.item_flags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.manage_users ALTER COLUMN id SET DEFAULT nextval('ml_app.manage_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.masters ALTER COLUMN id SET DEFAULT nextval('ml_app.masters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_notifications ALTER COLUMN id SET DEFAULT nextval('ml_app.message_notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_template_history ALTER COLUMN id SET DEFAULT nextval('ml_app.message_template_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_templates ALTER COLUMN id SET DEFAULT nextval('ml_app.message_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.model_references ALTER COLUMN id SET DEFAULT nextval('ml_app.model_references_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_file_history ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_archived_file_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_files ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_archived_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_container_history ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_container_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_containers ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_containers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_downloads ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_downloads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_filter_history ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_filter_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_filters ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_filters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_imports ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_imports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_move_actions ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_move_actions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_stored_file_history ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_stored_file_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_stored_files ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_stored_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_trash_actions ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_trash_actions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_uploads ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_uploads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_user_file_actions ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_user_file_actions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.page_layout_history ALTER COLUMN id SET DEFAULT nextval('ml_app.page_layout_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.page_layouts ALTER COLUMN id SET DEFAULT nextval('ml_app.page_layouts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_contact_history ALTER COLUMN id SET DEFAULT nextval('ml_app.player_contact_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_contacts ALTER COLUMN id SET DEFAULT nextval('ml_app.player_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_info_history ALTER COLUMN id SET DEFAULT nextval('ml_app.player_info_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_infos ALTER COLUMN id SET DEFAULT nextval('ml_app.player_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.pro_infos ALTER COLUMN id SET DEFAULT nextval('ml_app.pro_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_event_history ALTER COLUMN id SET DEFAULT nextval('ml_app.protocol_event_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_events ALTER COLUMN id SET DEFAULT nextval('ml_app.protocol_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_history ALTER COLUMN id SET DEFAULT nextval('ml_app.protocol_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocols ALTER COLUMN id SET DEFAULT nextval('ml_app.protocols_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.rc_cis ALTER COLUMN id SET DEFAULT nextval('ml_app.rc_cis_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.rc_stage_cif_copy ALTER COLUMN id SET DEFAULT nextval('ml_app.rc_stage_cif_copy_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.report_history ALTER COLUMN id SET DEFAULT nextval('ml_app.report_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.reports ALTER COLUMN id SET DEFAULT nextval('ml_app.reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.role_description_history ALTER COLUMN id SET DEFAULT nextval('ml_app.role_description_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.role_descriptions ALTER COLUMN id SET DEFAULT nextval('ml_app.role_descriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sage_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app.sage_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantron_history ALTER COLUMN id SET DEFAULT nextval('ml_app.scantron_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantrons ALTER COLUMN id SET DEFAULT nextval('ml_app.scantrons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sessions ALTER COLUMN id SET DEFAULT nextval('ml_app.sessions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sub_process_history ALTER COLUMN id SET DEFAULT nextval('ml_app.sub_process_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sub_processes ALTER COLUMN id SET DEFAULT nextval('ml_app.sub_processes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.tracker_history ALTER COLUMN id SET DEFAULT nextval('ml_app.tracker_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers ALTER COLUMN id SET DEFAULT nextval('ml_app.trackers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_access_control_history ALTER COLUMN id SET DEFAULT nextval('ml_app.user_access_control_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_access_controls ALTER COLUMN id SET DEFAULT nextval('ml_app.user_access_controls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_action_logs ALTER COLUMN id SET DEFAULT nextval('ml_app.user_action_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_authorization_history ALTER COLUMN id SET DEFAULT nextval('ml_app.user_authorization_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_authorizations ALTER COLUMN id SET DEFAULT nextval('ml_app.user_authorizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_description_history ALTER COLUMN id SET DEFAULT nextval('ml_app.user_description_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_descriptions ALTER COLUMN id SET DEFAULT nextval('ml_app.user_descriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_history ALTER COLUMN id SET DEFAULT nextval('ml_app.user_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_preferences ALTER COLUMN id SET DEFAULT nextval('ml_app.user_preferences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_role_history ALTER COLUMN id SET DEFAULT nextval('ml_app.user_role_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_roles ALTER COLUMN id SET DEFAULT nextval('ml_app.user_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.users ALTER COLUMN id SET DEFAULT nextval('ml_app.users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.users_contact_infos ALTER COLUMN id SET DEFAULT nextval('ml_app.users_contact_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: redcap; Owner: -
--

ALTER TABLE ONLY redcap.viva_meta_variable_history ALTER COLUMN id SET DEFAULT nextval('redcap.viva_meta_variable_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: redcap; Owner: -
--

ALTER TABLE ONLY redcap.viva_meta_variables ALTER COLUMN id SET DEFAULT nextval('redcap.viva_meta_variables_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choice_history ALTER COLUMN id SET DEFAULT nextval('ref_data.datadic_choice_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choices ALTER COLUMN id SET DEFAULT nextval('ref_data.datadic_choices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history ALTER COLUMN id SET DEFAULT nextval('ref_data.datadic_variable_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variables ALTER COLUMN id SET DEFAULT nextval('ref_data.datadic_variables_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_client_requests ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_client_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_collection_instrument_history ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_data_collection_instrument_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_collection_instruments ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_data_collection_instruments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionaries ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_data_dictionaries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionary_history ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_data_dictionary_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_admin_history ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_project_admin_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_admins ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_project_admins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_user_history ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_project_user_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_users ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_project_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_study_info_part_history ALTER COLUMN id SET DEFAULT nextval('study_info.activity_log_study_info_part_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_study_info_parts ALTER COLUMN id SET DEFAULT nextval('study_info.activity_log_study_info_parts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_view_user_data_user_proc_history ALTER COLUMN id SET DEFAULT nextval('study_info.activity_log_view_user_data_user_proc_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_view_user_data_user_procs ALTER COLUMN id SET DEFAULT nextval('study_info.activity_log_view_user_data_user_procs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_common_section_history ALTER COLUMN id SET DEFAULT nextval('study_info.study_common_section_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_common_sections ALTER COLUMN id SET DEFAULT nextval('study_info.study_common_sections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_info_part_history ALTER COLUMN id SET DEFAULT nextval('study_info.study_info_part_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_info_parts ALTER COLUMN id SET DEFAULT nextval('study_info.study_info_parts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_page_section_history ALTER COLUMN id SET DEFAULT nextval('study_info.study_page_section_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_page_sections ALTER COLUMN id SET DEFAULT nextval('study_info.study_page_sections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva2_rc_history ALTER COLUMN id SET DEFAULT nextval('viva_ref_info.viva2_rc_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva2_rcs ALTER COLUMN id SET DEFAULT nextval('viva_ref_info.viva2_rcs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva3_rc_history ALTER COLUMN id SET DEFAULT nextval('viva_ref_info.viva3_rc_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva3_rcs ALTER COLUMN id SET DEFAULT nextval('viva_ref_info.viva3_rcs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_collection_instrument_history ALTER COLUMN id SET DEFAULT nextval('viva_ref_info.viva_collection_instrument_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_collection_instruments ALTER COLUMN id SET DEFAULT nextval('viva_ref_info.viva_collection_instruments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_domain_history ALTER COLUMN id SET DEFAULT nextval('viva_ref_info.viva_domain_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_domains ALTER COLUMN id SET DEFAULT nextval('viva_ref_info.viva_domains_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_timepoint_history ALTER COLUMN id SET DEFAULT nextval('viva_ref_info.viva_timepoint_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_timepoints ALTER COLUMN id SET DEFAULT nextval('viva_ref_info.viva_timepoints_id_seq'::regclass);


--
-- Name: activity_log_data_request_assignment_history_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignment_history
    ADD CONSTRAINT activity_log_data_request_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_data_request_assignments_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignments
    ADD CONSTRAINT activity_log_data_request_assignments_pkey PRIMARY KEY (id);


--
-- Name: data_request_assignment_history_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_assignment_history
    ADD CONSTRAINT data_request_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: data_request_assignments_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_assignments
    ADD CONSTRAINT data_request_assignments_pkey PRIMARY KEY (id);


--
-- Name: data_request_attrib_history_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_attrib_history
    ADD CONSTRAINT data_request_attrib_history_pkey PRIMARY KEY (id);


--
-- Name: data_request_attribs_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_attribs
    ADD CONSTRAINT data_request_attribs_pkey PRIMARY KEY (id);


--
-- Name: data_request_history_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_history
    ADD CONSTRAINT data_request_history_pkey PRIMARY KEY (id);


--
-- Name: data_request_initial_review_history_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_initial_review_history
    ADD CONSTRAINT data_request_initial_review_history_pkey PRIMARY KEY (id);


--
-- Name: data_request_initial_reviews_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_initial_reviews
    ADD CONSTRAINT data_request_initial_reviews_pkey PRIMARY KEY (id);


--
-- Name: data_request_message_history_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_message_history
    ADD CONSTRAINT data_request_message_history_pkey PRIMARY KEY (id);


--
-- Name: data_request_messages_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_messages
    ADD CONSTRAINT data_request_messages_pkey PRIMARY KEY (id);


--
-- Name: data_requests_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests
    ADD CONSTRAINT data_requests_pkey PRIMARY KEY (id);


--
-- Name: data_requests_selected_attrib_history_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests_selected_attrib_history
    ADD CONSTRAINT data_requests_selected_attrib_history_pkey PRIMARY KEY (id);


--
-- Name: data_requests_selected_attribs_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests_selected_attribs
    ADD CONSTRAINT data_requests_selected_attribs_pkey PRIMARY KEY (id);


--
-- Name: user_profiile_detail_history_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profiile_detail_history
    ADD CONSTRAINT user_profiile_detail_history_pkey PRIMARY KEY (id);


--
-- Name: user_profiile_details_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profiile_details
    ADD CONSTRAINT user_profiile_details_pkey PRIMARY KEY (id);


--
-- Name: user_profile_academic_detail_history_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_academic_detail_history
    ADD CONSTRAINT user_profile_academic_detail_history_pkey PRIMARY KEY (id);


--
-- Name: user_profile_academic_details_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_academic_details
    ADD CONSTRAINT user_profile_academic_details_pkey PRIMARY KEY (id);


--
-- Name: user_profile_detail_history_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_detail_history
    ADD CONSTRAINT user_profile_detail_history_pkey PRIMARY KEY (id);


--
-- Name: user_profile_details_pkey; Type: CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_details
    ADD CONSTRAINT user_profile_details_pkey PRIMARY KEY (id);


--
-- Name: grit_assignment_history_pkey; Type: CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.grit_assignment_history
    ADD CONSTRAINT grit_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: grit_assignments_pkey; Type: CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.grit_assignments
    ADD CONSTRAINT grit_assignments_pkey PRIMARY KEY (id);


--
-- Name: pitt_bhi_assignment_history_pkey; Type: CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.pitt_bhi_assignment_history
    ADD CONSTRAINT pitt_bhi_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: pitt_bhi_assignments_pkey; Type: CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.pitt_bhi_assignments
    ADD CONSTRAINT pitt_bhi_assignments_pkey PRIMARY KEY (id);


--
-- Name: sleep_assignment_history_pkey; Type: CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.sleep_assignment_history
    ADD CONSTRAINT sleep_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: sleep_assignments_pkey; Type: CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.sleep_assignments
    ADD CONSTRAINT sleep_assignments_pkey PRIMARY KEY (id);


--
-- Name: accuracy_score_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.accuracy_score_history
    ADD CONSTRAINT accuracy_score_history_pkey PRIMARY KEY (id);


--
-- Name: accuracy_scores_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.accuracy_scores
    ADD CONSTRAINT accuracy_scores_pkey PRIMARY KEY (id);


--
-- Name: activity_log_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_history
    ADD CONSTRAINT activity_log_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_contact_phone_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phone_history
    ADD CONSTRAINT activity_log_player_contact_phone_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_contact_phones_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phones
    ADD CONSTRAINT activity_log_player_contact_phones_pkey PRIMARY KEY (id);


--
-- Name: activity_logs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: address_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.address_history
    ADD CONSTRAINT address_history_pkey PRIMARY KEY (id);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: admin_action_logs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.admin_action_logs
    ADD CONSTRAINT admin_action_logs_pkey PRIMARY KEY (id);


--
-- Name: admin_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.admin_history
    ADD CONSTRAINT admin_history_pkey PRIMARY KEY (id);


--
-- Name: admins_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: app_configuration_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_configuration_history
    ADD CONSTRAINT app_configuration_history_pkey PRIMARY KEY (id);


--
-- Name: app_configurations_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_configurations
    ADD CONSTRAINT app_configurations_pkey PRIMARY KEY (id);


--
-- Name: app_type_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_type_history
    ADD CONSTRAINT app_type_history_pkey PRIMARY KEY (id);


--
-- Name: app_types_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_types
    ADD CONSTRAINT app_types_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: college_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.college_history
    ADD CONSTRAINT college_history_pkey PRIMARY KEY (id);


--
-- Name: colleges_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.colleges
    ADD CONSTRAINT colleges_pkey PRIMARY KEY (id);


--
-- Name: config_libraries_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.config_libraries
    ADD CONSTRAINT config_libraries_pkey PRIMARY KEY (id);


--
-- Name: config_library_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.config_library_history
    ADD CONSTRAINT config_library_history_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: dynamic_model_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.dynamic_model_history
    ADD CONSTRAINT dynamic_model_history_pkey PRIMARY KEY (id);


--
-- Name: dynamic_models_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.dynamic_models
    ADD CONSTRAINT dynamic_models_pkey PRIMARY KEY (id);


--
-- Name: exception_logs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.exception_logs
    ADD CONSTRAINT exception_logs_pkey PRIMARY KEY (id);


--
-- Name: external_identifier_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_identifier_history
    ADD CONSTRAINT external_identifier_history_pkey PRIMARY KEY (id);


--
-- Name: external_identifiers_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_identifiers
    ADD CONSTRAINT external_identifiers_pkey PRIMARY KEY (id);


--
-- Name: external_link_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_link_history
    ADD CONSTRAINT external_link_history_pkey PRIMARY KEY (id);


--
-- Name: external_links_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_links
    ADD CONSTRAINT external_links_pkey PRIMARY KEY (id);


--
-- Name: general_selection_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.general_selection_history
    ADD CONSTRAINT general_selection_history_pkey PRIMARY KEY (id);


--
-- Name: general_selections_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.general_selections
    ADD CONSTRAINT general_selections_pkey PRIMARY KEY (id);


--
-- Name: imports_model_generators_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.imports_model_generators
    ADD CONSTRAINT imports_model_generators_pkey PRIMARY KEY (id);


--
-- Name: imports_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: item_flag_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flag_history
    ADD CONSTRAINT item_flag_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_name_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flag_name_history
    ADD CONSTRAINT item_flag_name_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_names_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flag_names
    ADD CONSTRAINT item_flag_names_pkey PRIMARY KEY (id);


--
-- Name: item_flags_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flags
    ADD CONSTRAINT item_flags_pkey PRIMARY KEY (id);


--
-- Name: manage_users_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.manage_users
    ADD CONSTRAINT manage_users_pkey PRIMARY KEY (id);


--
-- Name: masters_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.masters
    ADD CONSTRAINT masters_pkey PRIMARY KEY (id);


--
-- Name: message_notifications_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_notifications
    ADD CONSTRAINT message_notifications_pkey PRIMARY KEY (id);


--
-- Name: message_template_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_template_history
    ADD CONSTRAINT message_template_history_pkey PRIMARY KEY (id);


--
-- Name: message_templates_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_templates
    ADD CONSTRAINT message_templates_pkey PRIMARY KEY (id);


--
-- Name: model_references_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.model_references
    ADD CONSTRAINT model_references_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_archived_file_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_file_history
    ADD CONSTRAINT nfs_store_archived_file_history_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_archived_files_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_files
    ADD CONSTRAINT nfs_store_archived_files_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_container_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_container_history
    ADD CONSTRAINT nfs_store_container_history_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_containers_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_containers
    ADD CONSTRAINT nfs_store_containers_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_downloads_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_downloads
    ADD CONSTRAINT nfs_store_downloads_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_filter_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_filter_history
    ADD CONSTRAINT nfs_store_filter_history_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_filters_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_filters
    ADD CONSTRAINT nfs_store_filters_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_imports_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_imports
    ADD CONSTRAINT nfs_store_imports_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_move_actions_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_move_actions
    ADD CONSTRAINT nfs_store_move_actions_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_stored_file_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_stored_file_history
    ADD CONSTRAINT nfs_store_stored_file_history_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_stored_files_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_stored_files
    ADD CONSTRAINT nfs_store_stored_files_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_trash_actions_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_trash_actions
    ADD CONSTRAINT nfs_store_trash_actions_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_uploads_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_uploads
    ADD CONSTRAINT nfs_store_uploads_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_user_file_actions_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_user_file_actions
    ADD CONSTRAINT nfs_store_user_file_actions_pkey PRIMARY KEY (id);


--
-- Name: page_layout_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.page_layout_history
    ADD CONSTRAINT page_layout_history_pkey PRIMARY KEY (id);


--
-- Name: page_layouts_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.page_layouts
    ADD CONSTRAINT page_layouts_pkey PRIMARY KEY (id);


--
-- Name: player_contact_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_contact_history
    ADD CONSTRAINT player_contact_history_pkey PRIMARY KEY (id);


--
-- Name: player_contacts_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_contacts
    ADD CONSTRAINT player_contacts_pkey PRIMARY KEY (id);


--
-- Name: player_info_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_info_history
    ADD CONSTRAINT player_info_history_pkey PRIMARY KEY (id);


--
-- Name: player_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_infos
    ADD CONSTRAINT player_infos_pkey PRIMARY KEY (id);


--
-- Name: pro_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.pro_infos
    ADD CONSTRAINT pro_infos_pkey PRIMARY KEY (id);


--
-- Name: protocol_event_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_event_history
    ADD CONSTRAINT protocol_event_history_pkey PRIMARY KEY (id);


--
-- Name: protocol_events_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_events
    ADD CONSTRAINT protocol_events_pkey PRIMARY KEY (id);


--
-- Name: protocol_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_history
    ADD CONSTRAINT protocol_history_pkey PRIMARY KEY (id);


--
-- Name: protocols_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- Name: rc_cis_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.rc_cis
    ADD CONSTRAINT rc_cis_pkey PRIMARY KEY (id);


--
-- Name: rc_stage_cif_copy_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.rc_stage_cif_copy
    ADD CONSTRAINT rc_stage_cif_copy_pkey PRIMARY KEY (id);


--
-- Name: report_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.report_history
    ADD CONSTRAINT report_history_pkey PRIMARY KEY (id);


--
-- Name: reports_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: role_description_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.role_description_history
    ADD CONSTRAINT role_description_history_pkey PRIMARY KEY (id);


--
-- Name: role_descriptions_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.role_descriptions
    ADD CONSTRAINT role_descriptions_pkey PRIMARY KEY (id);


--
-- Name: sage_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sage_assignments
    ADD CONSTRAINT sage_assignments_pkey PRIMARY KEY (id);


--
-- Name: scantron_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantron_history
    ADD CONSTRAINT scantron_history_pkey PRIMARY KEY (id);


--
-- Name: scantrons_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantrons
    ADD CONSTRAINT scantrons_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sub_process_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sub_process_history
    ADD CONSTRAINT sub_process_history_pkey PRIMARY KEY (id);


--
-- Name: sub_processes_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sub_processes
    ADD CONSTRAINT sub_processes_pkey PRIMARY KEY (id);


--
-- Name: tracker_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.tracker_history
    ADD CONSTRAINT tracker_history_pkey PRIMARY KEY (id);


--
-- Name: trackers_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers
    ADD CONSTRAINT trackers_pkey PRIMARY KEY (id);


--
-- Name: unique_master_protocol; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers
    ADD CONSTRAINT unique_master_protocol UNIQUE (master_id, protocol_id);


--
-- Name: unique_master_protocol_id; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers
    ADD CONSTRAINT unique_master_protocol_id UNIQUE (master_id, protocol_id, id);


--
-- Name: unique_protocol_and_id; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sub_processes
    ADD CONSTRAINT unique_protocol_and_id UNIQUE (protocol_id, id);


--
-- Name: unique_sub_process_and_id; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_events
    ADD CONSTRAINT unique_sub_process_and_id UNIQUE (sub_process_id, id);


--
-- Name: user_access_control_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_access_control_history
    ADD CONSTRAINT user_access_control_history_pkey PRIMARY KEY (id);


--
-- Name: user_access_controls_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_access_controls
    ADD CONSTRAINT user_access_controls_pkey PRIMARY KEY (id);


--
-- Name: user_action_logs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_action_logs
    ADD CONSTRAINT user_action_logs_pkey PRIMARY KEY (id);


--
-- Name: user_authorization_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_authorization_history
    ADD CONSTRAINT user_authorization_history_pkey PRIMARY KEY (id);


--
-- Name: user_authorizations_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_authorizations
    ADD CONSTRAINT user_authorizations_pkey PRIMARY KEY (id);


--
-- Name: user_description_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_description_history
    ADD CONSTRAINT user_description_history_pkey PRIMARY KEY (id);


--
-- Name: user_descriptions_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_descriptions
    ADD CONSTRAINT user_descriptions_pkey PRIMARY KEY (id);


--
-- Name: user_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_history
    ADD CONSTRAINT user_history_pkey PRIMARY KEY (id);


--
-- Name: user_preferences_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_role_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_role_history
    ADD CONSTRAINT user_role_history_pkey PRIMARY KEY (id);


--
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: users_contact_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.users_contact_infos
    ADD CONSTRAINT users_contact_infos_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: viva_meta_variable_history_pkey; Type: CONSTRAINT; Schema: redcap; Owner: -
--

ALTER TABLE ONLY redcap.viva_meta_variable_history
    ADD CONSTRAINT viva_meta_variable_history_pkey PRIMARY KEY (id);


--
-- Name: viva_meta_variables_pkey; Type: CONSTRAINT; Schema: redcap; Owner: -
--

ALTER TABLE ONLY redcap.viva_meta_variables
    ADD CONSTRAINT viva_meta_variables_pkey PRIMARY KEY (id);


--
-- Name: datadic_choice_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choice_history
    ADD CONSTRAINT datadic_choice_history_pkey PRIMARY KEY (id);


--
-- Name: datadic_choices_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choices
    ADD CONSTRAINT datadic_choices_pkey PRIMARY KEY (id);


--
-- Name: datadic_variable_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history
    ADD CONSTRAINT datadic_variable_history_pkey PRIMARY KEY (id);


--
-- Name: datadic_variables_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variables
    ADD CONSTRAINT datadic_variables_pkey PRIMARY KEY (id);


--
-- Name: redcap_client_requests_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_client_requests
    ADD CONSTRAINT redcap_client_requests_pkey PRIMARY KEY (id);


--
-- Name: redcap_data_collection_instrument_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_collection_instrument_history
    ADD CONSTRAINT redcap_data_collection_instrument_history_pkey PRIMARY KEY (id);


--
-- Name: redcap_data_collection_instruments_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_collection_instruments
    ADD CONSTRAINT redcap_data_collection_instruments_pkey PRIMARY KEY (id);


--
-- Name: redcap_data_dictionaries_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionaries
    ADD CONSTRAINT redcap_data_dictionaries_pkey PRIMARY KEY (id);


--
-- Name: redcap_data_dictionary_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionary_history
    ADD CONSTRAINT redcap_data_dictionary_history_pkey PRIMARY KEY (id);


--
-- Name: redcap_project_admin_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_admin_history
    ADD CONSTRAINT redcap_project_admin_history_pkey PRIMARY KEY (id);


--
-- Name: redcap_project_admins_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_admins
    ADD CONSTRAINT redcap_project_admins_pkey PRIMARY KEY (id);


--
-- Name: redcap_project_user_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_user_history
    ADD CONSTRAINT redcap_project_user_history_pkey PRIMARY KEY (id);


--
-- Name: redcap_project_users_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_users
    ADD CONSTRAINT redcap_project_users_pkey PRIMARY KEY (id);


--
-- Name: activity_log_study_info_part_history_pkey; Type: CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_study_info_part_history
    ADD CONSTRAINT activity_log_study_info_part_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_study_info_parts_pkey; Type: CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_study_info_parts
    ADD CONSTRAINT activity_log_study_info_parts_pkey PRIMARY KEY (id);


--
-- Name: activity_log_view_user_data_user_proc_history_pkey; Type: CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_view_user_data_user_proc_history
    ADD CONSTRAINT activity_log_view_user_data_user_proc_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_view_user_data_user_procs_pkey; Type: CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_view_user_data_user_procs
    ADD CONSTRAINT activity_log_view_user_data_user_procs_pkey PRIMARY KEY (id);


--
-- Name: study_common_section_history_pkey; Type: CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_common_section_history
    ADD CONSTRAINT study_common_section_history_pkey PRIMARY KEY (id);


--
-- Name: study_common_sections_pkey; Type: CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_common_sections
    ADD CONSTRAINT study_common_sections_pkey PRIMARY KEY (id);


--
-- Name: study_info_part_history_pkey; Type: CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_info_part_history
    ADD CONSTRAINT study_info_part_history_pkey PRIMARY KEY (id);


--
-- Name: study_info_parts_pkey; Type: CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_info_parts
    ADD CONSTRAINT study_info_parts_pkey PRIMARY KEY (id);


--
-- Name: study_page_section_history_pkey; Type: CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_page_section_history
    ADD CONSTRAINT study_page_section_history_pkey PRIMARY KEY (id);


--
-- Name: study_page_sections_pkey; Type: CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_page_sections
    ADD CONSTRAINT study_page_sections_pkey PRIMARY KEY (id);


--
-- Name: viva2_rc_history_pkey; Type: CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva2_rc_history
    ADD CONSTRAINT viva2_rc_history_pkey PRIMARY KEY (id);


--
-- Name: viva2_rcs_pkey; Type: CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva2_rcs
    ADD CONSTRAINT viva2_rcs_pkey PRIMARY KEY (id);


--
-- Name: viva3_rc_history_pkey; Type: CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva3_rc_history
    ADD CONSTRAINT viva3_rc_history_pkey PRIMARY KEY (id);


--
-- Name: viva3_rcs_pkey; Type: CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva3_rcs
    ADD CONSTRAINT viva3_rcs_pkey PRIMARY KEY (id);


--
-- Name: viva_collection_instrument_history_pkey; Type: CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_collection_instrument_history
    ADD CONSTRAINT viva_collection_instrument_history_pkey PRIMARY KEY (id);


--
-- Name: viva_collection_instruments_pkey; Type: CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_collection_instruments
    ADD CONSTRAINT viva_collection_instruments_pkey PRIMARY KEY (id);


--
-- Name: viva_domain_history_pkey; Type: CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_domain_history
    ADD CONSTRAINT viva_domain_history_pkey PRIMARY KEY (id);


--
-- Name: viva_domains_pkey; Type: CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_domains
    ADD CONSTRAINT viva_domains_pkey PRIMARY KEY (id);


--
-- Name: viva_timepoint_history_pkey; Type: CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_timepoint_history
    ADD CONSTRAINT viva_timepoint_history_pkey PRIMARY KEY (id);


--
-- Name: viva_timepoints_pkey; Type: CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_timepoints
    ADD CONSTRAINT viva_timepoints_pkey PRIMARY KEY (id);


--
-- Name: 36bd4ead_b_id_h_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "36bd4ead_b_id_h_idx" ON data_requests.activity_log_data_request_assignment_history USING btree (activity_log_data_request_assignment_id);


--
-- Name: 36bd4ead_id_h_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "36bd4ead_id_h_idx" ON data_requests.activity_log_data_request_assignment_history USING btree (data_request_assignment_id);


--
-- Name: 36bd4ead_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "36bd4ead_id_idx" ON data_requests.activity_log_data_request_assignments USING btree (data_request_assignment_id);


--
-- Name: 36bd4ead_master_id_h_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "36bd4ead_master_id_h_idx" ON data_requests.activity_log_data_request_assignment_history USING btree (master_id);


--
-- Name: 36bd4ead_master_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "36bd4ead_master_id_idx" ON data_requests.activity_log_data_request_assignments USING btree (master_id);


--
-- Name: 36bd4ead_ref_cb_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "36bd4ead_ref_cb_user_idx" ON data_requests.activity_log_data_request_assignments USING btree (created_by_user_id);


--
-- Name: 36bd4ead_ref_cb_user_idx_hist; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "36bd4ead_ref_cb_user_idx_hist" ON data_requests.activity_log_data_request_assignment_history USING btree (created_by_user_id);


--
-- Name: 36bd4ead_user_id_h_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "36bd4ead_user_id_h_idx" ON data_requests.activity_log_data_request_assignment_history USING btree (user_id);


--
-- Name: 36bd4ead_user_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "36bd4ead_user_id_idx" ON data_requests.activity_log_data_request_assignments USING btree (user_id);


--
-- Name: 56fce463_history_master_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "56fce463_history_master_id" ON data_requests.data_request_attrib_history USING btree (master_id);


--
-- Name: 56fce463_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "56fce463_id_idx" ON data_requests.data_request_attrib_history USING btree (data_request_attrib_id);


--
-- Name: 56fce463_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "56fce463_user_idx" ON data_requests.data_request_attrib_history USING btree (user_id);


--
-- Name: 5becac92_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "5becac92_id_idx" ON data_requests.user_profiile_detail_history USING btree (user_profiile_detail_id);


--
-- Name: 5becac92_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "5becac92_user_idx" ON data_requests.user_profiile_detail_history USING btree (user_id);


--
-- Name: 6e54d54e_history_master_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "6e54d54e_history_master_id" ON data_requests.data_request_history USING btree (master_id);


--
-- Name: 6e54d54e_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "6e54d54e_id_idx" ON data_requests.data_request_history USING btree (data_request_id);


--
-- Name: 6e54d54e_ref_cb_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "6e54d54e_ref_cb_user_idx" ON data_requests.data_requests USING btree (created_by_user_id);


--
-- Name: 6e54d54e_ref_cb_user_idx_hist; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "6e54d54e_ref_cb_user_idx_hist" ON data_requests.data_request_history USING btree (created_by_user_id);


--
-- Name: 6e54d54e_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "6e54d54e_user_idx" ON data_requests.data_request_history USING btree (user_id);


--
-- Name: 76842e8d_history_master_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "76842e8d_history_master_id" ON data_requests.data_requests_selected_attrib_history USING btree (master_id);


--
-- Name: 76842e8d_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "76842e8d_id_idx" ON data_requests.data_requests_selected_attrib_history USING btree (data_requests_selected_attrib_id);


--
-- Name: 76842e8d_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "76842e8d_user_idx" ON data_requests.data_requests_selected_attrib_history USING btree (user_id);


--
-- Name: 952319f7_history_master_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "952319f7_history_master_id" ON data_requests.data_request_initial_review_history USING btree (master_id);


--
-- Name: 952319f7_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "952319f7_id_idx" ON data_requests.data_request_initial_review_history USING btree (data_request_initial_review_id);


--
-- Name: 952319f7_ref_cb_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "952319f7_ref_cb_user_idx" ON data_requests.data_request_initial_reviews USING btree (created_by_user_id);


--
-- Name: 952319f7_ref_cb_user_idx_hist; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "952319f7_ref_cb_user_idx_hist" ON data_requests.data_request_initial_review_history USING btree (created_by_user_id);


--
-- Name: 952319f7_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "952319f7_user_idx" ON data_requests.data_request_initial_review_history USING btree (user_id);


--
-- Name: bf6b3e59_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX bf6b3e59_id_idx ON data_requests.user_profile_detail_history USING btree (user_profile_detail_id);


--
-- Name: bf6b3e59_ref_cb_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX bf6b3e59_ref_cb_user_idx ON data_requests.user_profile_details USING btree (created_by_user_id);


--
-- Name: bf6b3e59_ref_cb_user_idx_hist; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX bf6b3e59_ref_cb_user_idx_hist ON data_requests.user_profile_detail_history USING btree (created_by_user_id);


--
-- Name: bf6b3e59_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX bf6b3e59_user_idx ON data_requests.user_profile_detail_history USING btree (user_id);


--
-- Name: c303bcbb_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX c303bcbb_id_idx ON data_requests.user_profile_academic_detail_history USING btree (user_profile_academic_detail_id);


--
-- Name: c303bcbb_ref_cb_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX c303bcbb_ref_cb_user_idx ON data_requests.user_profile_academic_details USING btree (created_by_user_id);


--
-- Name: c303bcbb_ref_cb_user_idx_hist; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX c303bcbb_ref_cb_user_idx_hist ON data_requests.user_profile_academic_detail_history USING btree (created_by_user_id);


--
-- Name: c303bcbb_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX c303bcbb_user_idx ON data_requests.user_profile_academic_detail_history USING btree (user_id);


--
-- Name: data_request_assignment_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX data_request_assignment_id_idx ON data_requests.data_request_assignment_history USING btree (data_request_assignment_table_id);


--
-- Name: dmbt_56fce463_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX dmbt_56fce463_id_idx ON data_requests.data_request_attribs USING btree (master_id);


--
-- Name: dmbt_6e54d54e_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX dmbt_6e54d54e_id_idx ON data_requests.data_requests USING btree (master_id);


--
-- Name: dmbt_76842e8d_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX dmbt_76842e8d_id_idx ON data_requests.data_requests_selected_attribs USING btree (master_id);


--
-- Name: dmbt_952319f7_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX dmbt_952319f7_id_idx ON data_requests.data_request_initial_reviews USING btree (master_id);


--
-- Name: dmbt_f84064ee_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX dmbt_f84064ee_id_idx ON data_requests.data_request_messages USING btree (master_id);


--
-- Name: ei7348f152_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX ei7348f152_id_idx ON data_requests.data_request_assignments USING btree (master_id);


--
-- Name: eih7348f152_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX eih7348f152_id_idx ON data_requests.data_request_assignment_history USING btree (master_id);


--
-- Name: f84064ee_history_master_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX f84064ee_history_master_id ON data_requests.data_request_message_history USING btree (master_id);


--
-- Name: f84064ee_id_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX f84064ee_id_idx ON data_requests.data_request_message_history USING btree (data_request_message_id);


--
-- Name: f84064ee_ref_cb_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX f84064ee_ref_cb_user_idx ON data_requests.data_request_messages USING btree (created_by_user_id);


--
-- Name: f84064ee_ref_cb_user_idx_hist; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX f84064ee_ref_cb_user_idx_hist ON data_requests.data_request_message_history USING btree (created_by_user_id);


--
-- Name: f84064ee_user_idx; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX f84064ee_user_idx ON data_requests.data_request_message_history USING btree (user_id);


--
-- Name: index_data_requests.data_request_assignment_history_on_admin_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.data_request_assignment_history_on_admin_id" ON data_requests.data_request_assignment_history USING btree (admin_id);


--
-- Name: index_data_requests.data_request_assignment_history_on_user_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.data_request_assignment_history_on_user_id" ON data_requests.data_request_assignment_history USING btree (user_id);


--
-- Name: index_data_requests.data_request_assignments_on_admin_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.data_request_assignments_on_admin_id" ON data_requests.data_request_assignments USING btree (admin_id);


--
-- Name: index_data_requests.data_request_assignments_on_user_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.data_request_assignments_on_user_id" ON data_requests.data_request_assignments USING btree (user_id);


--
-- Name: index_data_requests.data_request_attribs_on_user_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.data_request_attribs_on_user_id" ON data_requests.data_request_attribs USING btree (user_id);


--
-- Name: index_data_requests.data_request_initial_reviews_on_user_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.data_request_initial_reviews_on_user_id" ON data_requests.data_request_initial_reviews USING btree (user_id);


--
-- Name: index_data_requests.data_request_messages_on_user_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.data_request_messages_on_user_id" ON data_requests.data_request_messages USING btree (user_id);


--
-- Name: index_data_requests.data_requests_on_user_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.data_requests_on_user_id" ON data_requests.data_requests USING btree (user_id);


--
-- Name: index_data_requests.data_requests_selected_attribs_on_user_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.data_requests_selected_attribs_on_user_id" ON data_requests.data_requests_selected_attribs USING btree (user_id);


--
-- Name: index_data_requests.user_profiile_details_on_user_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.user_profiile_details_on_user_id" ON data_requests.user_profiile_details USING btree (user_id);


--
-- Name: index_data_requests.user_profile_academic_details_on_user_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.user_profile_academic_details_on_user_id" ON data_requests.user_profile_academic_details USING btree (user_id);


--
-- Name: index_data_requests.user_profile_details_on_user_id; Type: INDEX; Schema: data_requests; Owner: -
--

CREATE INDEX "index_data_requests.user_profile_details_on_user_id" ON data_requests.user_profile_details USING btree (user_id);


--
-- Name: grit_assignment_id_idx; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX grit_assignment_id_idx ON extra_app.grit_assignment_history USING btree (grit_assignment_table_id);


--
-- Name: index_extra_app.grit_assignment_history_on_admin_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.grit_assignment_history_on_admin_id" ON extra_app.grit_assignment_history USING btree (admin_id);


--
-- Name: index_extra_app.grit_assignment_history_on_master_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.grit_assignment_history_on_master_id" ON extra_app.grit_assignment_history USING btree (master_id);


--
-- Name: index_extra_app.grit_assignment_history_on_user_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.grit_assignment_history_on_user_id" ON extra_app.grit_assignment_history USING btree (user_id);


--
-- Name: index_extra_app.grit_assignments_on_admin_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.grit_assignments_on_admin_id" ON extra_app.grit_assignments USING btree (admin_id);


--
-- Name: index_extra_app.grit_assignments_on_master_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.grit_assignments_on_master_id" ON extra_app.grit_assignments USING btree (master_id);


--
-- Name: index_extra_app.grit_assignments_on_user_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.grit_assignments_on_user_id" ON extra_app.grit_assignments USING btree (user_id);


--
-- Name: index_extra_app.pitt_bhi_assignment_history_on_admin_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.pitt_bhi_assignment_history_on_admin_id" ON extra_app.pitt_bhi_assignment_history USING btree (admin_id);


--
-- Name: index_extra_app.pitt_bhi_assignment_history_on_master_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.pitt_bhi_assignment_history_on_master_id" ON extra_app.pitt_bhi_assignment_history USING btree (master_id);


--
-- Name: index_extra_app.pitt_bhi_assignment_history_on_user_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.pitt_bhi_assignment_history_on_user_id" ON extra_app.pitt_bhi_assignment_history USING btree (user_id);


--
-- Name: index_extra_app.pitt_bhi_assignments_on_admin_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.pitt_bhi_assignments_on_admin_id" ON extra_app.pitt_bhi_assignments USING btree (admin_id);


--
-- Name: index_extra_app.pitt_bhi_assignments_on_master_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.pitt_bhi_assignments_on_master_id" ON extra_app.pitt_bhi_assignments USING btree (master_id);


--
-- Name: index_extra_app.pitt_bhi_assignments_on_user_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.pitt_bhi_assignments_on_user_id" ON extra_app.pitt_bhi_assignments USING btree (user_id);


--
-- Name: index_extra_app.sleep_assignment_history_on_admin_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.sleep_assignment_history_on_admin_id" ON extra_app.sleep_assignment_history USING btree (admin_id);


--
-- Name: index_extra_app.sleep_assignment_history_on_master_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.sleep_assignment_history_on_master_id" ON extra_app.sleep_assignment_history USING btree (master_id);


--
-- Name: index_extra_app.sleep_assignment_history_on_user_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.sleep_assignment_history_on_user_id" ON extra_app.sleep_assignment_history USING btree (user_id);


--
-- Name: index_extra_app.sleep_assignments_on_admin_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.sleep_assignments_on_admin_id" ON extra_app.sleep_assignments USING btree (admin_id);


--
-- Name: index_extra_app.sleep_assignments_on_master_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.sleep_assignments_on_master_id" ON extra_app.sleep_assignments USING btree (master_id);


--
-- Name: index_extra_app.sleep_assignments_on_user_id; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX "index_extra_app.sleep_assignments_on_user_id" ON extra_app.sleep_assignments USING btree (user_id);


--
-- Name: pitt_bhi_assignment_id_idx; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX pitt_bhi_assignment_id_idx ON extra_app.pitt_bhi_assignment_history USING btree (pitt_bhi_assignment_table_id);


--
-- Name: sleep_assignment_id_idx; Type: INDEX; Schema: extra_app; Owner: -
--

CREATE INDEX sleep_assignment_id_idx ON extra_app.sleep_assignment_history USING btree (sleep_assignment_table_id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX delayed_jobs_priority ON ml_app.delayed_jobs USING btree (priority, run_at);


--
-- Name: idx_h_on_role_descriptions_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX idx_h_on_role_descriptions_id ON ml_app.role_description_history USING btree (role_description_id);


--
-- Name: idx_h_on_user_descriptions_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX idx_h_on_user_descriptions_id ON ml_app.user_description_history USING btree (user_description_id);


--
-- Name: index_accuracy_score_history_on_accuracy_score_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_accuracy_score_history_on_accuracy_score_id ON ml_app.accuracy_score_history USING btree (accuracy_score_id);


--
-- Name: index_accuracy_scores_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_accuracy_scores_on_admin_id ON ml_app.accuracy_scores USING btree (admin_id);


--
-- Name: index_activity_log_history_on_activity_log_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_history_on_activity_log_id ON ml_app.activity_log_history USING btree (activity_log_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_activity_log; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_activity_log ON ml_app.activity_log_player_contact_phone_history USING btree (activity_log_player_contact_phone_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_master_id ON ml_app.activity_log_player_contact_phone_history USING btree (master_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_player_conta; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_player_conta ON ml_app.activity_log_player_contact_phone_history USING btree (player_contact_id);


--
-- Name: index_activity_log_player_contact_phone_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phone_history_on_user_id ON ml_app.activity_log_player_contact_phone_history USING btree (user_id);


--
-- Name: index_activity_log_player_contact_phones_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phones_on_master_id ON ml_app.activity_log_player_contact_phones USING btree (master_id);


--
-- Name: index_activity_log_player_contact_phones_on_player_contact_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phones_on_player_contact_id ON ml_app.activity_log_player_contact_phones USING btree (player_contact_id);


--
-- Name: index_activity_log_player_contact_phones_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phones_on_protocol_id ON ml_app.activity_log_player_contact_phones USING btree (protocol_id);


--
-- Name: index_activity_log_player_contact_phones_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_phones_on_user_id ON ml_app.activity_log_player_contact_phones USING btree (user_id);


--
-- Name: index_address_history_on_address_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_address_history_on_address_id ON ml_app.address_history USING btree (address_id);


--
-- Name: index_address_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_address_history_on_master_id ON ml_app.address_history USING btree (master_id);


--
-- Name: index_address_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_address_history_on_user_id ON ml_app.address_history USING btree (user_id);


--
-- Name: index_addresses_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_addresses_on_master_id ON ml_app.addresses USING btree (master_id);


--
-- Name: index_addresses_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_addresses_on_user_id ON ml_app.addresses USING btree (user_id);


--
-- Name: index_admin_action_logs_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_admin_action_logs_on_admin_id ON ml_app.admin_action_logs USING btree (admin_id);


--
-- Name: index_admin_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_admin_history_on_admin_id ON ml_app.admin_history USING btree (admin_id);


--
-- Name: index_admin_history_on_upd_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_admin_history_on_upd_admin_id ON ml_app.admin_history USING btree (updated_by_admin_id);


--
-- Name: index_admins_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_admins_on_admin_id ON ml_app.admins USING btree (admin_id);


--
-- Name: index_app_configuration_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_app_configuration_history_on_admin_id ON ml_app.app_configuration_history USING btree (admin_id);


--
-- Name: index_app_configuration_history_on_app_configuration_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_app_configuration_history_on_app_configuration_id ON ml_app.app_configuration_history USING btree (app_configuration_id);


--
-- Name: index_app_configurations_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_app_configurations_on_admin_id ON ml_app.app_configurations USING btree (admin_id);


--
-- Name: index_app_configurations_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_app_configurations_on_app_type_id ON ml_app.app_configurations USING btree (app_type_id);


--
-- Name: index_app_configurations_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_app_configurations_on_user_id ON ml_app.app_configurations USING btree (user_id);


--
-- Name: index_app_type_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_app_type_history_on_admin_id ON ml_app.app_type_history USING btree (admin_id);


--
-- Name: index_app_type_history_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_app_type_history_on_app_type_id ON ml_app.app_type_history USING btree (app_type_id);


--
-- Name: index_app_types_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_app_types_on_admin_id ON ml_app.app_types USING btree (admin_id);


--
-- Name: index_college_history_on_college_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_college_history_on_college_id ON ml_app.college_history USING btree (college_id);


--
-- Name: index_colleges_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_colleges_on_admin_id ON ml_app.colleges USING btree (admin_id);


--
-- Name: index_colleges_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_colleges_on_user_id ON ml_app.colleges USING btree (user_id);


--
-- Name: index_config_libraries_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_config_libraries_on_admin_id ON ml_app.config_libraries USING btree (admin_id);


--
-- Name: index_config_library_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_config_library_history_on_admin_id ON ml_app.config_library_history USING btree (admin_id);


--
-- Name: index_config_library_history_on_config_library_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_config_library_history_on_config_library_id ON ml_app.config_library_history USING btree (config_library_id);


--
-- Name: index_dynamic_model_history_on_dynamic_model_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_dynamic_model_history_on_dynamic_model_id ON ml_app.dynamic_model_history USING btree (dynamic_model_id);


--
-- Name: index_dynamic_models_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_dynamic_models_on_admin_id ON ml_app.dynamic_models USING btree (admin_id);


--
-- Name: index_exception_logs_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_exception_logs_on_admin_id ON ml_app.exception_logs USING btree (admin_id);


--
-- Name: index_exception_logs_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_exception_logs_on_user_id ON ml_app.exception_logs USING btree (user_id);


--
-- Name: index_external_identifier_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_external_identifier_history_on_admin_id ON ml_app.external_identifier_history USING btree (admin_id);


--
-- Name: index_external_identifier_history_on_external_identifier_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_external_identifier_history_on_external_identifier_id ON ml_app.external_identifier_history USING btree (external_identifier_id);


--
-- Name: index_external_identifiers_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_external_identifiers_on_admin_id ON ml_app.external_identifiers USING btree (admin_id);


--
-- Name: index_external_link_history_on_external_link_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_external_link_history_on_external_link_id ON ml_app.external_link_history USING btree (external_link_id);


--
-- Name: index_external_links_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_external_links_on_admin_id ON ml_app.external_links USING btree (admin_id);


--
-- Name: index_general_selection_history_on_general_selection_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_general_selection_history_on_general_selection_id ON ml_app.general_selection_history USING btree (general_selection_id);


--
-- Name: index_general_selections_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_general_selections_on_admin_id ON ml_app.general_selections USING btree (admin_id);


--
-- Name: index_imports_model_generators_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_imports_model_generators_on_admin_id ON ml_app.imports_model_generators USING btree (admin_id);


--
-- Name: index_imports_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_imports_on_user_id ON ml_app.imports USING btree (user_id);


--
-- Name: index_item_flag_history_on_item_flag_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_item_flag_history_on_item_flag_id ON ml_app.item_flag_history USING btree (item_flag_id);


--
-- Name: index_item_flag_name_history_on_item_flag_name_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_item_flag_name_history_on_item_flag_name_id ON ml_app.item_flag_name_history USING btree (item_flag_name_id);


--
-- Name: index_item_flag_names_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_item_flag_names_on_admin_id ON ml_app.item_flag_names USING btree (admin_id);


--
-- Name: index_item_flags_on_item_flag_name_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_item_flags_on_item_flag_name_id ON ml_app.item_flags USING btree (item_flag_name_id);


--
-- Name: index_item_flags_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_item_flags_on_user_id ON ml_app.item_flags USING btree (user_id);


--
-- Name: index_masters_on_created_by_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_masters_on_created_by_user_id ON ml_app.masters USING btree (created_by_user_id);


--
-- Name: index_masters_on_msid; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_masters_on_msid ON ml_app.masters USING btree (msid);


--
-- Name: index_masters_on_pro_info_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_masters_on_pro_info_id ON ml_app.masters USING btree (pro_info_id);


--
-- Name: index_masters_on_proid; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_masters_on_proid ON ml_app.masters USING btree (pro_id);


--
-- Name: index_masters_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_masters_on_user_id ON ml_app.masters USING btree (user_id);


--
-- Name: index_message_notifications_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_message_notifications_on_app_type_id ON ml_app.message_notifications USING btree (app_type_id);


--
-- Name: index_message_notifications_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_message_notifications_on_master_id ON ml_app.message_notifications USING btree (master_id);


--
-- Name: index_message_notifications_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_message_notifications_on_user_id ON ml_app.message_notifications USING btree (user_id);


--
-- Name: index_message_notifications_status; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_message_notifications_status ON ml_app.message_notifications USING btree (status);


--
-- Name: index_message_template_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_message_template_history_on_admin_id ON ml_app.message_template_history USING btree (admin_id);


--
-- Name: index_message_template_history_on_message_template_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_message_template_history_on_message_template_id ON ml_app.message_template_history USING btree (message_template_id);


--
-- Name: index_message_templates_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_message_templates_on_admin_id ON ml_app.message_templates USING btree (admin_id);


--
-- Name: index_model_references_on_from_record_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_model_references_on_from_record_master_id ON ml_app.model_references USING btree (from_record_master_id);


--
-- Name: index_model_references_on_from_record_type_and_from_record_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_model_references_on_from_record_type_and_from_record_id ON ml_app.model_references USING btree (from_record_type, from_record_id);


--
-- Name: index_model_references_on_to_record_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_model_references_on_to_record_master_id ON ml_app.model_references USING btree (to_record_master_id);


--
-- Name: index_model_references_on_to_record_type_and_to_record_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_model_references_on_to_record_type_and_to_record_id ON ml_app.model_references USING btree (to_record_type, to_record_id);


--
-- Name: index_model_references_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_model_references_on_user_id ON ml_app.model_references USING btree (user_id);


--
-- Name: index_nfs_store_archived_file_history_on_nfs_store_archived_fil; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_archived_file_history_on_nfs_store_archived_fil ON ml_app.nfs_store_archived_file_history USING btree (nfs_store_archived_file_id);


--
-- Name: index_nfs_store_archived_file_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_archived_file_history_on_user_id ON ml_app.nfs_store_archived_file_history USING btree (user_id);


--
-- Name: index_nfs_store_archived_files_on_nfs_store_container_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_archived_files_on_nfs_store_container_id ON ml_app.nfs_store_archived_files USING btree (nfs_store_container_id);


--
-- Name: index_nfs_store_archived_files_on_nfs_store_stored_file_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_archived_files_on_nfs_store_stored_file_id ON ml_app.nfs_store_archived_files USING btree (nfs_store_stored_file_id);


--
-- Name: index_nfs_store_container_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_container_history_on_master_id ON ml_app.nfs_store_container_history USING btree (master_id);


--
-- Name: index_nfs_store_container_history_on_nfs_store_container_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_container_history_on_nfs_store_container_id ON ml_app.nfs_store_container_history USING btree (nfs_store_container_id);


--
-- Name: index_nfs_store_container_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_container_history_on_user_id ON ml_app.nfs_store_container_history USING btree (user_id);


--
-- Name: index_nfs_store_containers_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_containers_on_master_id ON ml_app.nfs_store_containers USING btree (master_id);


--
-- Name: index_nfs_store_containers_on_nfs_store_container_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_containers_on_nfs_store_container_id ON ml_app.nfs_store_containers USING btree (nfs_store_container_id);


--
-- Name: index_nfs_store_filter_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_filter_history_on_admin_id ON ml_app.nfs_store_filter_history USING btree (admin_id);


--
-- Name: index_nfs_store_filter_history_on_nfs_store_filter_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_filter_history_on_nfs_store_filter_id ON ml_app.nfs_store_filter_history USING btree (nfs_store_filter_id);


--
-- Name: index_nfs_store_filters_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_filters_on_admin_id ON ml_app.nfs_store_filters USING btree (admin_id);


--
-- Name: index_nfs_store_filters_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_filters_on_app_type_id ON ml_app.nfs_store_filters USING btree (app_type_id);


--
-- Name: index_nfs_store_filters_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_filters_on_user_id ON ml_app.nfs_store_filters USING btree (user_id);


--
-- Name: index_nfs_store_stored_file_history_on_nfs_store_stored_file_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_stored_file_history_on_nfs_store_stored_file_id ON ml_app.nfs_store_stored_file_history USING btree (nfs_store_stored_file_id);


--
-- Name: index_nfs_store_stored_file_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_stored_file_history_on_user_id ON ml_app.nfs_store_stored_file_history USING btree (user_id);


--
-- Name: index_nfs_store_stored_files_on_nfs_store_container_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_stored_files_on_nfs_store_container_id ON ml_app.nfs_store_stored_files USING btree (nfs_store_container_id);


--
-- Name: index_nfs_store_uploads_on_nfs_store_stored_file_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_uploads_on_nfs_store_stored_file_id ON ml_app.nfs_store_uploads USING btree (nfs_store_stored_file_id);


--
-- Name: index_nfs_store_uploads_on_upload_set; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_uploads_on_upload_set ON ml_app.nfs_store_uploads USING btree (upload_set);


--
-- Name: index_page_layout_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_page_layout_history_on_admin_id ON ml_app.page_layout_history USING btree (admin_id);


--
-- Name: index_page_layout_history_on_page_layout_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_page_layout_history_on_page_layout_id ON ml_app.page_layout_history USING btree (page_layout_id);


--
-- Name: index_page_layouts_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_page_layouts_on_admin_id ON ml_app.page_layouts USING btree (admin_id);


--
-- Name: index_page_layouts_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_page_layouts_on_app_type_id ON ml_app.page_layouts USING btree (app_type_id);


--
-- Name: index_player_contact_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_player_contact_history_on_master_id ON ml_app.player_contact_history USING btree (master_id);


--
-- Name: index_player_contact_history_on_player_contact_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_player_contact_history_on_player_contact_id ON ml_app.player_contact_history USING btree (player_contact_id);


--
-- Name: index_player_contact_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_player_contact_history_on_user_id ON ml_app.player_contact_history USING btree (user_id);


--
-- Name: index_player_contacts_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_player_contacts_on_master_id ON ml_app.player_contacts USING btree (master_id);


--
-- Name: index_player_contacts_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_player_contacts_on_user_id ON ml_app.player_contacts USING btree (user_id);


--
-- Name: index_player_info_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_player_info_history_on_master_id ON ml_app.player_info_history USING btree (master_id);


--
-- Name: index_player_info_history_on_player_info_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_player_info_history_on_player_info_id ON ml_app.player_info_history USING btree (player_info_id);


--
-- Name: index_player_info_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_player_info_history_on_user_id ON ml_app.player_info_history USING btree (user_id);


--
-- Name: index_player_infos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_player_infos_on_master_id ON ml_app.player_infos USING btree (master_id);


--
-- Name: index_player_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_player_infos_on_user_id ON ml_app.player_infos USING btree (user_id);


--
-- Name: index_pro_infos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_pro_infos_on_master_id ON ml_app.pro_infos USING btree (master_id);


--
-- Name: index_pro_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_pro_infos_on_user_id ON ml_app.pro_infos USING btree (user_id);


--
-- Name: index_protocol_event_history_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_protocol_event_history_on_protocol_event_id ON ml_app.protocol_event_history USING btree (protocol_event_id);


--
-- Name: index_protocol_events_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_protocol_events_on_admin_id ON ml_app.protocol_events USING btree (admin_id);


--
-- Name: index_protocol_events_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_protocol_events_on_sub_process_id ON ml_app.protocol_events USING btree (sub_process_id);


--
-- Name: index_protocol_history_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_protocol_history_on_protocol_id ON ml_app.protocol_history USING btree (protocol_id);


--
-- Name: index_protocols_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_protocols_on_admin_id ON ml_app.protocols USING btree (admin_id);


--
-- Name: index_protocols_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_protocols_on_app_type_id ON ml_app.protocols USING btree (app_type_id);


--
-- Name: index_report_history_on_report_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_report_history_on_report_id ON ml_app.report_history USING btree (report_id);


--
-- Name: index_reports_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_reports_on_admin_id ON ml_app.reports USING btree (admin_id);


--
-- Name: index_role_description_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_role_description_history_on_admin_id ON ml_app.role_description_history USING btree (admin_id);


--
-- Name: index_role_description_history_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_role_description_history_on_app_type_id ON ml_app.role_description_history USING btree (app_type_id);


--
-- Name: index_role_descriptions_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_role_descriptions_on_admin_id ON ml_app.role_descriptions USING btree (admin_id);


--
-- Name: index_role_descriptions_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_role_descriptions_on_app_type_id ON ml_app.role_descriptions USING btree (app_type_id);


--
-- Name: index_sage_assignments_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sage_assignments_on_admin_id ON ml_app.sage_assignments USING btree (admin_id);


--
-- Name: index_sage_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sage_assignments_on_master_id ON ml_app.sage_assignments USING btree (master_id);


--
-- Name: index_sage_assignments_on_sage_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX index_sage_assignments_on_sage_id ON ml_app.sage_assignments USING btree (sage_id);


--
-- Name: index_sage_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sage_assignments_on_user_id ON ml_app.sage_assignments USING btree (user_id);


--
-- Name: index_scantron_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantron_history_on_master_id ON ml_app.scantron_history USING btree (master_id);


--
-- Name: index_scantron_history_on_scantron_table_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantron_history_on_scantron_table_id ON ml_app.scantron_history USING btree (scantron_table_id);


--
-- Name: index_scantron_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantron_history_on_user_id ON ml_app.scantron_history USING btree (user_id);


--
-- Name: index_scantrons_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantrons_on_master_id ON ml_app.scantrons USING btree (master_id);


--
-- Name: index_scantrons_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantrons_on_user_id ON ml_app.scantrons USING btree (user_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_session_id ON ml_app.sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sessions_on_updated_at ON ml_app.sessions USING btree (updated_at);


--
-- Name: index_sub_process_history_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sub_process_history_on_sub_process_id ON ml_app.sub_process_history USING btree (sub_process_id);


--
-- Name: index_sub_processes_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sub_processes_on_admin_id ON ml_app.sub_processes USING btree (admin_id);


--
-- Name: index_sub_processes_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sub_processes_on_protocol_id ON ml_app.sub_processes USING btree (protocol_id);


--
-- Name: index_tracker_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_tracker_history_on_master_id ON ml_app.tracker_history USING btree (master_id);


--
-- Name: index_tracker_history_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_tracker_history_on_protocol_event_id ON ml_app.tracker_history USING btree (protocol_event_id);


--
-- Name: index_tracker_history_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_tracker_history_on_protocol_id ON ml_app.tracker_history USING btree (protocol_id);


--
-- Name: index_tracker_history_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_tracker_history_on_sub_process_id ON ml_app.tracker_history USING btree (sub_process_id);


--
-- Name: index_tracker_history_on_tracker_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_tracker_history_on_tracker_id ON ml_app.tracker_history USING btree (tracker_id);


--
-- Name: index_tracker_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_tracker_history_on_user_id ON ml_app.tracker_history USING btree (user_id);


--
-- Name: index_trackers_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_trackers_on_master_id ON ml_app.trackers USING btree (master_id);


--
-- Name: index_trackers_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_trackers_on_protocol_event_id ON ml_app.trackers USING btree (protocol_event_id);


--
-- Name: index_trackers_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_trackers_on_protocol_id ON ml_app.trackers USING btree (protocol_id);


--
-- Name: index_trackers_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_trackers_on_sub_process_id ON ml_app.trackers USING btree (sub_process_id);


--
-- Name: index_trackers_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_trackers_on_user_id ON ml_app.trackers USING btree (user_id);


--
-- Name: index_user_access_control_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_access_control_history_on_admin_id ON ml_app.user_access_control_history USING btree (admin_id);


--
-- Name: index_user_access_control_history_on_user_access_control_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_access_control_history_on_user_access_control_id ON ml_app.user_access_control_history USING btree (user_access_control_id);


--
-- Name: index_user_access_controls_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_access_controls_on_app_type_id ON ml_app.user_access_controls USING btree (app_type_id);


--
-- Name: index_user_action_logs_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_action_logs_on_app_type_id ON ml_app.user_action_logs USING btree (app_type_id);


--
-- Name: index_user_action_logs_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_action_logs_on_master_id ON ml_app.user_action_logs USING btree (master_id);


--
-- Name: index_user_action_logs_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_action_logs_on_user_id ON ml_app.user_action_logs USING btree (user_id);


--
-- Name: index_user_authorization_history_on_user_authorization_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_authorization_history_on_user_authorization_id ON ml_app.user_authorization_history USING btree (user_authorization_id);


--
-- Name: index_user_description_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_description_history_on_admin_id ON ml_app.user_description_history USING btree (admin_id);


--
-- Name: index_user_description_history_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_description_history_on_app_type_id ON ml_app.user_description_history USING btree (app_type_id);


--
-- Name: index_user_descriptions_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_descriptions_on_admin_id ON ml_app.user_descriptions USING btree (admin_id);


--
-- Name: index_user_descriptions_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_descriptions_on_app_type_id ON ml_app.user_descriptions USING btree (app_type_id);


--
-- Name: index_user_history_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_history_on_app_type_id ON ml_app.user_history USING btree (app_type_id);


--
-- Name: index_user_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_history_on_user_id ON ml_app.user_history USING btree (user_id);


--
-- Name: index_user_preferences_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX index_user_preferences_on_user_id ON ml_app.user_preferences USING btree (user_id);


--
-- Name: index_user_role_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_role_history_on_admin_id ON ml_app.user_role_history USING btree (admin_id);


--
-- Name: index_user_role_history_on_user_role_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_role_history_on_user_role_id ON ml_app.user_role_history USING btree (user_role_id);


--
-- Name: index_user_roles_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_roles_on_admin_id ON ml_app.user_roles USING btree (admin_id);


--
-- Name: index_user_roles_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_roles_on_app_type_id ON ml_app.user_roles USING btree (app_type_id);


--
-- Name: index_user_roles_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_roles_on_user_id ON ml_app.user_roles USING btree (user_id);


--
-- Name: index_users_contact_infos_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_users_contact_infos_on_admin_id ON ml_app.users_contact_infos USING btree (admin_id);


--
-- Name: index_users_contact_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_users_contact_infos_on_user_id ON ml_app.users_contact_infos USING btree (user_id);


--
-- Name: index_users_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_users_on_admin_id ON ml_app.users USING btree (admin_id);


--
-- Name: index_users_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_users_on_app_type_id ON ml_app.users USING btree (app_type_id);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX index_users_on_authentication_token ON ml_app.users USING btree (authentication_token);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON ml_app.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON ml_app.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON ml_app.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON ml_app.users USING btree (unlock_token);


--
-- Name: nfs_store_stored_files_unique_file; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX nfs_store_stored_files_unique_file ON ml_app.nfs_store_stored_files USING btree (nfs_store_container_id, file_hash, file_name, path);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON ml_app.schema_migrations USING btree (version);


--
-- Name: 13f4f74e_id_idx; Type: INDEX; Schema: redcap; Owner: -
--

CREATE INDEX "13f4f74e_id_idx" ON redcap.viva_meta_variable_history USING btree (viva_meta_variable_id);


--
-- Name: 13f4f74e_user_idx; Type: INDEX; Schema: redcap; Owner: -
--

CREATE INDEX "13f4f74e_user_idx" ON redcap.viva_meta_variable_history USING btree (user_id);


--
-- Name: index_redcap.viva_meta_variables_on_user_id; Type: INDEX; Schema: redcap; Owner: -
--

CREATE INDEX "index_redcap.viva_meta_variables_on_user_id" ON redcap.viva_meta_variables USING btree (user_id);


--
-- Name: idx_dch_on_redcap_dd_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_dch_on_redcap_dd_id ON ref_data.datadic_choice_history USING btree (redcap_data_dictionary_id);


--
-- Name: idx_dv_equiv; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_dv_equiv ON ref_data.datadic_variables USING btree (equivalent_to_id);


--
-- Name: idx_dvh_equiv; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_dvh_equiv ON ref_data.datadic_variable_history USING btree (equivalent_to_id);


--
-- Name: idx_dvh_on_redcap_dd_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_dvh_on_redcap_dd_id ON ref_data.datadic_variable_history USING btree (redcap_data_dictionary_id);


--
-- Name: idx_h_on_datadic_variable_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_h_on_datadic_variable_id ON ref_data.datadic_variable_history USING btree (datadic_variable_id);


--
-- Name: idx_h_on_proj_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_h_on_proj_admin_id ON ref_data.redcap_project_user_history USING btree (redcap_project_admin_id);


--
-- Name: idx_h_on_rdci_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_h_on_rdci_id ON ref_data.redcap_data_collection_instrument_history USING btree (redcap_data_collection_instrument_id);


--
-- Name: idx_h_on_redcap_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_h_on_redcap_admin_id ON ref_data.redcap_data_dictionary_history USING btree (redcap_project_admin_id);


--
-- Name: idx_h_on_redcap_project_user_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_h_on_redcap_project_user_id ON ref_data.redcap_project_user_history USING btree (redcap_project_user_id);


--
-- Name: idx_history_on_datadic_choice_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_history_on_datadic_choice_id ON ref_data.datadic_choice_history USING btree (datadic_choice_id);


--
-- Name: idx_history_on_redcap_data_dictionary_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_history_on_redcap_data_dictionary_id ON ref_data.redcap_data_dictionary_history USING btree (redcap_data_dictionary_id);


--
-- Name: idx_history_on_redcap_project_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_history_on_redcap_project_admin_id ON ref_data.redcap_project_admin_history USING btree (redcap_project_admin_id);


--
-- Name: idx_on_redcap_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_on_redcap_admin_id ON ref_data.redcap_data_dictionaries USING btree (redcap_project_admin_id);


--
-- Name: idx_rcr_on_redcap_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_rcr_on_redcap_admin_id ON ref_data.redcap_client_requests USING btree (redcap_project_admin_id);


--
-- Name: idx_rdci_pa; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_rdci_pa ON ref_data.redcap_data_collection_instruments USING btree (redcap_project_admin_id);


--
-- Name: idx_rdcih_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_rdcih_on_admin_id ON ref_data.redcap_data_collection_instrument_history USING btree (admin_id);


--
-- Name: idx_rdcih_on_proj_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_rdcih_on_proj_admin_id ON ref_data.redcap_data_collection_instrument_history USING btree (redcap_project_admin_id);


--
-- Name: index_datadic_variable_history_on_user_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX index_datadic_variable_history_on_user_id ON ref_data.datadic_variable_history USING btree (user_id);


--
-- Name: index_datadic_variables_on_user_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX index_datadic_variables_on_user_id ON ref_data.datadic_variables USING btree (user_id);


--
-- Name: index_ref_data.datadic_choice_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_choice_history_on_admin_id" ON ref_data.datadic_choice_history USING btree (admin_id);


--
-- Name: index_ref_data.datadic_choices_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_choices_on_admin_id" ON ref_data.datadic_choices USING btree (admin_id);


--
-- Name: index_ref_data.datadic_choices_on_redcap_data_dictionary_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_choices_on_redcap_data_dictionary_id" ON ref_data.datadic_choices USING btree (redcap_data_dictionary_id);


--
-- Name: index_ref_data.datadic_variable_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_variable_history_on_admin_id" ON ref_data.datadic_variable_history USING btree (admin_id);


--
-- Name: index_ref_data.datadic_variables_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_variables_on_admin_id" ON ref_data.datadic_variables USING btree (admin_id);


--
-- Name: index_ref_data.datadic_variables_on_redcap_data_dictionary_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_variables_on_redcap_data_dictionary_id" ON ref_data.datadic_variables USING btree (redcap_data_dictionary_id);


--
-- Name: index_ref_data.redcap_client_requests_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_client_requests_on_admin_id" ON ref_data.redcap_client_requests USING btree (admin_id);


--
-- Name: index_ref_data.redcap_data_collection_instruments_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_data_collection_instruments_on_admin_id" ON ref_data.redcap_data_collection_instruments USING btree (admin_id);


--
-- Name: index_ref_data.redcap_data_dictionaries_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_data_dictionaries_on_admin_id" ON ref_data.redcap_data_dictionaries USING btree (admin_id);


--
-- Name: index_ref_data.redcap_data_dictionary_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_data_dictionary_history_on_admin_id" ON ref_data.redcap_data_dictionary_history USING btree (admin_id);


--
-- Name: index_ref_data.redcap_project_admin_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_project_admin_history_on_admin_id" ON ref_data.redcap_project_admin_history USING btree (admin_id);


--
-- Name: index_ref_data.redcap_project_admins_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_project_admins_on_admin_id" ON ref_data.redcap_project_admins USING btree (admin_id);


--
-- Name: index_ref_data.redcap_project_user_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_project_user_history_on_admin_id" ON ref_data.redcap_project_user_history USING btree (admin_id);


--
-- Name: index_ref_data.redcap_project_users_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_project_users_on_admin_id" ON ref_data.redcap_project_users USING btree (admin_id);


--
-- Name: index_ref_data.redcap_project_users_on_redcap_project_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_project_users_on_redcap_project_admin_id" ON ref_data.redcap_project_users USING btree (redcap_project_admin_id);


--
-- Name: 5865aead_history_master_id; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "5865aead_history_master_id" ON study_info.study_page_section_history USING btree (master_id);


--
-- Name: 5865aead_id_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "5865aead_id_idx" ON study_info.study_page_section_history USING btree (study_page_section_id);


--
-- Name: 5865aead_user_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "5865aead_user_idx" ON study_info.study_page_section_history USING btree (user_id);


--
-- Name: 7934da9b_b_id_h_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "7934da9b_b_id_h_idx" ON study_info.activity_log_view_user_data_user_proc_history USING btree (activity_log_view_user_data_user_proc_id);


--
-- Name: 7934da9b_master_id_h_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "7934da9b_master_id_h_idx" ON study_info.activity_log_view_user_data_user_proc_history USING btree (master_id);


--
-- Name: 7934da9b_master_id_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "7934da9b_master_id_idx" ON study_info.activity_log_view_user_data_user_procs USING btree (master_id);


--
-- Name: 7934da9b_user_id_h_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "7934da9b_user_id_h_idx" ON study_info.activity_log_view_user_data_user_proc_history USING btree (user_id);


--
-- Name: 7934da9b_user_id_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "7934da9b_user_id_idx" ON study_info.activity_log_view_user_data_user_procs USING btree (user_id);


--
-- Name: a01c1fd4_b_id_h_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX a01c1fd4_b_id_h_idx ON study_info.activity_log_study_info_part_history USING btree (activity_log_study_info_part_id);


--
-- Name: a01c1fd4_id_h_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX a01c1fd4_id_h_idx ON study_info.activity_log_study_info_part_history USING btree (study_info_part_id);


--
-- Name: a01c1fd4_id_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX a01c1fd4_id_idx ON study_info.activity_log_study_info_parts USING btree (study_info_part_id);


--
-- Name: a01c1fd4_master_id_h_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX a01c1fd4_master_id_h_idx ON study_info.activity_log_study_info_part_history USING btree (master_id);


--
-- Name: a01c1fd4_master_id_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX a01c1fd4_master_id_idx ON study_info.activity_log_study_info_parts USING btree (master_id);


--
-- Name: a01c1fd4_user_id_h_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX a01c1fd4_user_id_h_idx ON study_info.activity_log_study_info_part_history USING btree (user_id);


--
-- Name: a01c1fd4_user_id_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX a01c1fd4_user_id_idx ON study_info.activity_log_study_info_parts USING btree (user_id);


--
-- Name: c5dbb08b_id_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX c5dbb08b_id_idx ON study_info.study_common_section_history USING btree (study_common_section_id);


--
-- Name: c5dbb08b_user_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX c5dbb08b_user_idx ON study_info.study_common_section_history USING btree (user_id);


--
-- Name: dmbt_5865aead_id_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX dmbt_5865aead_id_idx ON study_info.study_page_sections USING btree (master_id);


--
-- Name: ei836094b5_id_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX ei836094b5_id_idx ON study_info.study_info_parts USING btree (master_id);


--
-- Name: eih836094b5_id_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX eih836094b5_id_idx ON study_info.study_info_part_history USING btree (master_id);


--
-- Name: index_study_info.study_common_sections_on_user_id; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "index_study_info.study_common_sections_on_user_id" ON study_info.study_common_sections USING btree (user_id);


--
-- Name: index_study_info.study_info_part_history_on_admin_id; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "index_study_info.study_info_part_history_on_admin_id" ON study_info.study_info_part_history USING btree (admin_id);


--
-- Name: index_study_info.study_info_part_history_on_user_id; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "index_study_info.study_info_part_history_on_user_id" ON study_info.study_info_part_history USING btree (user_id);


--
-- Name: index_study_info.study_info_parts_on_admin_id; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "index_study_info.study_info_parts_on_admin_id" ON study_info.study_info_parts USING btree (admin_id);


--
-- Name: index_study_info.study_info_parts_on_user_id; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "index_study_info.study_info_parts_on_user_id" ON study_info.study_info_parts USING btree (user_id);


--
-- Name: index_study_info.study_page_sections_on_user_id; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX "index_study_info.study_page_sections_on_user_id" ON study_info.study_page_sections USING btree (user_id);


--
-- Name: study_info_part_id_idx; Type: INDEX; Schema: study_info; Owner: -
--

CREATE INDEX study_info_part_id_idx ON study_info.study_info_part_history USING btree (study_info_part_table_id);


--
-- Name: 1bd41136_id_idx; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX "1bd41136_id_idx" ON viva_ref_info.viva_collection_instrument_history USING btree (viva_collection_instrument_id);


--
-- Name: 1bd41136_user_idx; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX "1bd41136_user_idx" ON viva_ref_info.viva_collection_instrument_history USING btree (user_id);


--
-- Name: 1c993248_id_idx; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX "1c993248_id_idx" ON viva_ref_info.viva3_rc_history USING btree (viva3_rc_id);


--
-- Name: 1c993248_user_idx; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX "1c993248_user_idx" ON viva_ref_info.viva3_rc_history USING btree (user_id);


--
-- Name: 538ddd51_id_idx; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX "538ddd51_id_idx" ON viva_ref_info.viva_timepoint_history USING btree (viva_timepoint_id);


--
-- Name: 538ddd51_user_idx; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX "538ddd51_user_idx" ON viva_ref_info.viva_timepoint_history USING btree (user_id);


--
-- Name: b453deef_id_idx; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX b453deef_id_idx ON viva_ref_info.viva2_rc_history USING btree (viva2_rc_id);


--
-- Name: b453deef_user_idx; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX b453deef_user_idx ON viva_ref_info.viva2_rc_history USING btree (user_id);


--
-- Name: c50790f0_id_idx; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX c50790f0_id_idx ON viva_ref_info.viva_domain_history USING btree (viva_domain_id);


--
-- Name: c50790f0_user_idx; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX c50790f0_user_idx ON viva_ref_info.viva_domain_history USING btree (user_id);


--
-- Name: index_viva_ref_info.viva2_rcs_on_user_id; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX "index_viva_ref_info.viva2_rcs_on_user_id" ON viva_ref_info.viva2_rcs USING btree (user_id);


--
-- Name: index_viva_ref_info.viva3_rcs_on_user_id; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX "index_viva_ref_info.viva3_rcs_on_user_id" ON viva_ref_info.viva3_rcs USING btree (user_id);


--
-- Name: index_viva_ref_info.viva_collection_instruments_on_user_id; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX "index_viva_ref_info.viva_collection_instruments_on_user_id" ON viva_ref_info.viva_collection_instruments USING btree (user_id);


--
-- Name: index_viva_ref_info.viva_domains_on_user_id; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX "index_viva_ref_info.viva_domains_on_user_id" ON viva_ref_info.viva_domains USING btree (user_id);


--
-- Name: index_viva_ref_info.viva_timepoints_on_user_id; Type: INDEX; Schema: viva_ref_info; Owner: -
--

CREATE INDEX "index_viva_ref_info.viva_timepoints_on_user_id" ON viva_ref_info.viva_timepoints USING btree (user_id);


--
-- Name: log_activity_log_data_request_assignment_history_insert; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_activity_log_data_request_assignment_history_insert AFTER INSERT ON data_requests.activity_log_data_request_assignments FOR EACH ROW EXECUTE PROCEDURE data_requests.log_activity_log_data_request_assignments_update();


--
-- Name: log_activity_log_data_request_assignment_history_update; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_activity_log_data_request_assignment_history_update AFTER UPDATE ON data_requests.activity_log_data_request_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE data_requests.log_activity_log_data_request_assignments_update();


--
-- Name: log_data_request_attrib_history_insert; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_data_request_attrib_history_insert AFTER INSERT ON data_requests.data_request_attribs FOR EACH ROW EXECUTE PROCEDURE data_requests.log_data_request_attribs_update();


--
-- Name: log_data_request_attrib_history_update; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_data_request_attrib_history_update AFTER UPDATE ON data_requests.data_request_attribs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE data_requests.log_data_request_attribs_update();


--
-- Name: log_data_request_history_insert; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_data_request_history_insert AFTER INSERT ON data_requests.data_requests FOR EACH ROW EXECUTE PROCEDURE data_requests.log_data_requests_update();


--
-- Name: log_data_request_history_update; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_data_request_history_update AFTER UPDATE ON data_requests.data_requests FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE data_requests.log_data_requests_update();


--
-- Name: log_data_request_initial_review_history_insert; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_data_request_initial_review_history_insert AFTER INSERT ON data_requests.data_request_initial_reviews FOR EACH ROW EXECUTE PROCEDURE data_requests.log_data_request_initial_reviews_update();


--
-- Name: log_data_request_initial_review_history_update; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_data_request_initial_review_history_update AFTER UPDATE ON data_requests.data_request_initial_reviews FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE data_requests.log_data_request_initial_reviews_update();


--
-- Name: log_data_request_message_history_insert; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_data_request_message_history_insert AFTER INSERT ON data_requests.data_request_messages FOR EACH ROW EXECUTE PROCEDURE data_requests.log_data_request_messages_update();


--
-- Name: log_data_request_message_history_update; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_data_request_message_history_update AFTER UPDATE ON data_requests.data_request_messages FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE data_requests.log_data_request_messages_update();


--
-- Name: log_data_requests_selected_attrib_history_insert; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_data_requests_selected_attrib_history_insert AFTER INSERT ON data_requests.data_requests_selected_attribs FOR EACH ROW EXECUTE PROCEDURE data_requests.log_data_requests_selected_attribs_update();


--
-- Name: log_data_requests_selected_attrib_history_update; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_data_requests_selected_attrib_history_update AFTER UPDATE ON data_requests.data_requests_selected_attribs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE data_requests.log_data_requests_selected_attribs_update();


--
-- Name: log_user_profiile_detail_history_insert; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_user_profiile_detail_history_insert AFTER INSERT ON data_requests.user_profiile_details FOR EACH ROW EXECUTE PROCEDURE data_requests.log_user_profiile_details_update();


--
-- Name: log_user_profiile_detail_history_update; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_user_profiile_detail_history_update AFTER UPDATE ON data_requests.user_profiile_details FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE data_requests.log_user_profiile_details_update();


--
-- Name: log_user_profile_academic_detail_history_insert; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_user_profile_academic_detail_history_insert AFTER INSERT ON data_requests.user_profile_academic_details FOR EACH ROW EXECUTE PROCEDURE data_requests.log_user_profile_academic_details_update();


--
-- Name: log_user_profile_academic_detail_history_update; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_user_profile_academic_detail_history_update AFTER UPDATE ON data_requests.user_profile_academic_details FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE data_requests.log_user_profile_academic_details_update();


--
-- Name: log_user_profile_detail_history_insert; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_user_profile_detail_history_insert AFTER INSERT ON data_requests.user_profile_details FOR EACH ROW EXECUTE PROCEDURE data_requests.log_user_profile_details_update();


--
-- Name: log_user_profile_detail_history_update; Type: TRIGGER; Schema: data_requests; Owner: -
--

CREATE TRIGGER log_user_profile_detail_history_update AFTER UPDATE ON data_requests.user_profile_details FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE data_requests.log_user_profile_details_update();


--
-- Name: log_grit_assignment_history_insert; Type: TRIGGER; Schema: extra_app; Owner: -
--

CREATE TRIGGER log_grit_assignment_history_insert AFTER INSERT ON extra_app.grit_assignments FOR EACH ROW EXECUTE PROCEDURE extra_app.log_grit_assignments_update();


--
-- Name: log_grit_assignment_history_update; Type: TRIGGER; Schema: extra_app; Owner: -
--

CREATE TRIGGER log_grit_assignment_history_update AFTER UPDATE ON extra_app.grit_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE extra_app.log_grit_assignments_update();


--
-- Name: log_pitt_bhi_assignment_history_insert; Type: TRIGGER; Schema: extra_app; Owner: -
--

CREATE TRIGGER log_pitt_bhi_assignment_history_insert AFTER INSERT ON extra_app.pitt_bhi_assignments FOR EACH ROW EXECUTE PROCEDURE extra_app.log_pitt_bhi_assignments_update();


--
-- Name: log_pitt_bhi_assignment_history_update; Type: TRIGGER; Schema: extra_app; Owner: -
--

CREATE TRIGGER log_pitt_bhi_assignment_history_update AFTER UPDATE ON extra_app.pitt_bhi_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE extra_app.log_pitt_bhi_assignments_update();


--
-- Name: log_sleep_assignment_history_insert; Type: TRIGGER; Schema: extra_app; Owner: -
--

CREATE TRIGGER log_sleep_assignment_history_insert AFTER INSERT ON extra_app.sleep_assignments FOR EACH ROW EXECUTE PROCEDURE extra_app.log_sleep_assignments_update();


--
-- Name: log_sleep_assignment_history_update; Type: TRIGGER; Schema: extra_app; Owner: -
--

CREATE TRIGGER log_sleep_assignment_history_update AFTER UPDATE ON extra_app.sleep_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE extra_app.log_sleep_assignments_update();


--
-- Name: accuracy_score_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER accuracy_score_history_insert AFTER INSERT ON ml_app.accuracy_scores FOR EACH ROW EXECUTE PROCEDURE ml_app.log_accuracy_score_update();


--
-- Name: accuracy_score_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER accuracy_score_history_update AFTER UPDATE ON ml_app.accuracy_scores FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_accuracy_score_update();


--
-- Name: activity_log_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_history_insert AFTER INSERT ON ml_app.activity_logs FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_update();


--
-- Name: activity_log_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_history_update AFTER UPDATE ON ml_app.activity_logs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_update();


--
-- Name: activity_log_player_contact_phone_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_player_contact_phone_history_insert AFTER INSERT ON ml_app.activity_log_player_contact_phones FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_player_contact_phone_update();


--
-- Name: activity_log_player_contact_phone_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_player_contact_phone_history_update AFTER UPDATE ON ml_app.activity_log_player_contact_phones FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_player_contact_phone_update();


--
-- Name: address_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER address_history_insert AFTER INSERT ON ml_app.addresses FOR EACH ROW EXECUTE PROCEDURE ml_app.log_address_update();


--
-- Name: address_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER address_history_update AFTER UPDATE ON ml_app.addresses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_address_update();


--
-- Name: address_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER address_insert BEFORE INSERT ON ml_app.addresses FOR EACH ROW EXECUTE PROCEDURE ml_app.handle_address_update();


--
-- Name: address_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER address_update BEFORE UPDATE ON ml_app.addresses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.handle_address_update();


--
-- Name: admin_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER admin_history_insert AFTER INSERT ON ml_app.admins FOR EACH ROW EXECUTE PROCEDURE ml_app.log_admin_update();


--
-- Name: admin_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER admin_history_update AFTER UPDATE ON ml_app.admins FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_admin_update();


--
-- Name: app_configuration_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER app_configuration_history_insert AFTER INSERT ON ml_app.app_configurations FOR EACH ROW EXECUTE PROCEDURE ml_app.log_app_configuration_update();


--
-- Name: app_configuration_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER app_configuration_history_update AFTER UPDATE ON ml_app.app_configurations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_app_configuration_update();


--
-- Name: app_type_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER app_type_history_insert AFTER INSERT ON ml_app.app_types FOR EACH ROW EXECUTE PROCEDURE ml_app.log_app_type_update();


--
-- Name: app_type_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER app_type_history_update AFTER UPDATE ON ml_app.app_types FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_app_type_update();


--
-- Name: college_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER college_history_insert AFTER INSERT ON ml_app.colleges FOR EACH ROW EXECUTE PROCEDURE ml_app.log_college_update();


--
-- Name: college_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER college_history_update AFTER UPDATE ON ml_app.colleges FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_college_update();


--
-- Name: config_library_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER config_library_history_insert AFTER INSERT ON ml_app.config_libraries FOR EACH ROW EXECUTE PROCEDURE ml_app.log_config_library_update();


--
-- Name: config_library_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER config_library_history_update AFTER UPDATE ON ml_app.config_libraries FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_config_library_update();


--
-- Name: dynamic_model_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER dynamic_model_history_insert AFTER INSERT ON ml_app.dynamic_models FOR EACH ROW EXECUTE PROCEDURE ml_app.log_dynamic_model_update();


--
-- Name: dynamic_model_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER dynamic_model_history_update AFTER UPDATE ON ml_app.dynamic_models FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_dynamic_model_update();


--
-- Name: external_identifier_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER external_identifier_history_insert AFTER INSERT ON ml_app.external_identifiers FOR EACH ROW EXECUTE PROCEDURE ml_app.log_external_identifier_update();


--
-- Name: external_identifier_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER external_identifier_history_update AFTER UPDATE ON ml_app.external_identifiers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_external_identifier_update();


--
-- Name: external_link_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER external_link_history_insert AFTER INSERT ON ml_app.external_links FOR EACH ROW EXECUTE PROCEDURE ml_app.log_external_link_update();


--
-- Name: external_link_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER external_link_history_update AFTER UPDATE ON ml_app.external_links FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_external_link_update();


--
-- Name: general_selection_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER general_selection_history_insert AFTER INSERT ON ml_app.general_selections FOR EACH ROW EXECUTE PROCEDURE ml_app.log_general_selection_update();


--
-- Name: general_selection_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER general_selection_history_update AFTER UPDATE ON ml_app.general_selections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_general_selection_update();


--
-- Name: item_flag_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER item_flag_history_insert AFTER INSERT ON ml_app.item_flags FOR EACH ROW EXECUTE PROCEDURE ml_app.log_item_flag_update();


--
-- Name: item_flag_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER item_flag_history_update AFTER UPDATE ON ml_app.item_flags FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_item_flag_update();


--
-- Name: item_flag_name_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER item_flag_name_history_insert AFTER INSERT ON ml_app.item_flag_names FOR EACH ROW EXECUTE PROCEDURE ml_app.log_item_flag_name_update();


--
-- Name: item_flag_name_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER item_flag_name_history_update AFTER UPDATE ON ml_app.item_flag_names FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_item_flag_name_update();


--
-- Name: log_role_description_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER log_role_description_history_insert AFTER INSERT ON ml_app.role_descriptions FOR EACH ROW EXECUTE PROCEDURE ml_app.role_description_history_upd();


--
-- Name: log_role_description_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER log_role_description_history_update AFTER UPDATE ON ml_app.role_descriptions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.role_description_history_upd();


--
-- Name: log_user_description_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER log_user_description_history_insert AFTER INSERT ON ml_app.user_descriptions FOR EACH ROW EXECUTE PROCEDURE ml_app.user_description_history_upd();


--
-- Name: log_user_description_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER log_user_description_history_update AFTER UPDATE ON ml_app.user_descriptions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.user_description_history_upd();


--
-- Name: message_template_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER message_template_history_insert AFTER INSERT ON ml_app.message_templates FOR EACH ROW EXECUTE PROCEDURE ml_app.log_message_template_update();


--
-- Name: message_template_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER message_template_history_update AFTER UPDATE ON ml_app.message_templates FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_message_template_update();


--
-- Name: nfs_store_archived_file_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER nfs_store_archived_file_history_insert AFTER INSERT ON ml_app.nfs_store_archived_files FOR EACH ROW EXECUTE PROCEDURE ml_app.log_nfs_store_archived_file_update();


--
-- Name: nfs_store_archived_file_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER nfs_store_archived_file_history_update AFTER UPDATE ON ml_app.nfs_store_archived_files FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_nfs_store_archived_file_update();


--
-- Name: nfs_store_container_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER nfs_store_container_history_insert AFTER INSERT ON ml_app.nfs_store_containers FOR EACH ROW EXECUTE PROCEDURE ml_app.log_nfs_store_container_update();


--
-- Name: nfs_store_container_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER nfs_store_container_history_update AFTER UPDATE ON ml_app.nfs_store_containers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_nfs_store_container_update();


--
-- Name: nfs_store_filter_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER nfs_store_filter_history_insert AFTER INSERT ON ml_app.nfs_store_filters FOR EACH ROW EXECUTE PROCEDURE ml_app.log_nfs_store_filter_update();


--
-- Name: nfs_store_filter_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER nfs_store_filter_history_update AFTER UPDATE ON ml_app.nfs_store_filters FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_nfs_store_filter_update();


--
-- Name: nfs_store_stored_file_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER nfs_store_stored_file_history_insert AFTER INSERT ON ml_app.nfs_store_stored_files FOR EACH ROW EXECUTE PROCEDURE ml_app.log_nfs_store_stored_file_update();


--
-- Name: nfs_store_stored_file_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER nfs_store_stored_file_history_update AFTER UPDATE ON ml_app.nfs_store_stored_files FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_nfs_store_stored_file_update();


--
-- Name: page_layout_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER page_layout_history_insert AFTER INSERT ON ml_app.page_layouts FOR EACH ROW EXECUTE PROCEDURE ml_app.log_page_layout_update();


--
-- Name: page_layout_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER page_layout_history_update AFTER UPDATE ON ml_app.page_layouts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_page_layout_update();


--
-- Name: player_contact_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_contact_history_insert AFTER INSERT ON ml_app.player_contacts FOR EACH ROW EXECUTE PROCEDURE ml_app.log_player_contact_update();


--
-- Name: player_contact_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_contact_history_update AFTER UPDATE ON ml_app.player_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_player_contact_update();


--
-- Name: player_contact_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_contact_insert BEFORE INSERT ON ml_app.player_contacts FOR EACH ROW EXECUTE PROCEDURE ml_app.handle_player_contact_update();


--
-- Name: player_contact_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_contact_update BEFORE UPDATE ON ml_app.player_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.handle_player_contact_update();


--
-- Name: player_info_before_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_info_before_update BEFORE UPDATE ON ml_app.player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.handle_player_info_before_update();


--
-- Name: player_info_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_info_history_insert AFTER INSERT ON ml_app.player_infos FOR EACH ROW EXECUTE PROCEDURE ml_app.log_player_info_update();


--
-- Name: player_info_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_info_history_update AFTER UPDATE ON ml_app.player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_player_info_update();


--
-- Name: player_info_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_info_insert AFTER INSERT ON ml_app.player_infos FOR EACH ROW EXECUTE PROCEDURE ml_app.update_master_with_player_info();


--
-- Name: player_info_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER player_info_update AFTER UPDATE ON ml_app.player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.update_master_with_player_info();


--
-- Name: pro_info_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER pro_info_insert AFTER INSERT ON ml_app.pro_infos FOR EACH ROW EXECUTE PROCEDURE ml_app.update_master_with_pro_info();


--
-- Name: pro_info_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER pro_info_update AFTER UPDATE ON ml_app.pro_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.update_master_with_pro_info();


--
-- Name: protocol_event_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER protocol_event_history_insert AFTER INSERT ON ml_app.protocol_events FOR EACH ROW EXECUTE PROCEDURE ml_app.log_protocol_event_update();


--
-- Name: protocol_event_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER protocol_event_history_update AFTER UPDATE ON ml_app.protocol_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_protocol_event_update();


--
-- Name: protocol_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER protocol_history_insert AFTER INSERT ON ml_app.protocols FOR EACH ROW EXECUTE PROCEDURE ml_app.log_protocol_update();


--
-- Name: protocol_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER protocol_history_update AFTER UPDATE ON ml_app.protocols FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_protocol_update();


--
-- Name: rc_cis_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER rc_cis_update BEFORE UPDATE ON ml_app.rc_stage_cif_copy FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.handle_rc_cis_update();


--
-- Name: report_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER report_history_insert AFTER INSERT ON ml_app.reports FOR EACH ROW EXECUTE PROCEDURE ml_app.log_report_update();


--
-- Name: report_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER report_history_update AFTER UPDATE ON ml_app.reports FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_report_update();


--
-- Name: scantron_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER scantron_history_insert AFTER INSERT ON ml_app.scantrons FOR EACH ROW EXECUTE PROCEDURE ml_app.log_scantron_update();


--
-- Name: scantron_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER scantron_history_update AFTER UPDATE ON ml_app.scantrons FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_scantron_update();


--
-- Name: sub_process_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER sub_process_history_insert AFTER INSERT ON ml_app.sub_processes FOR EACH ROW EXECUTE PROCEDURE ml_app.log_sub_process_update();


--
-- Name: sub_process_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER sub_process_history_update AFTER UPDATE ON ml_app.sub_processes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_sub_process_update();


--
-- Name: tracker_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_history_insert AFTER INSERT ON ml_app.trackers FOR EACH ROW EXECUTE PROCEDURE ml_app.log_tracker_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_history_update BEFORE UPDATE ON ml_app.tracker_history FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.handle_tracker_history_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_history_update AFTER UPDATE ON ml_app.trackers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_tracker_update();


--
-- Name: tracker_record_delete; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_record_delete AFTER DELETE ON ml_app.tracker_history FOR EACH ROW EXECUTE PROCEDURE ml_app.handle_delete();


--
-- Name: tracker_upsert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_upsert BEFORE INSERT ON ml_app.trackers FOR EACH ROW EXECUTE PROCEDURE ml_app.tracker_upsert();


--
-- Name: user_access_control_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_access_control_history_insert AFTER INSERT ON ml_app.user_access_controls FOR EACH ROW EXECUTE PROCEDURE ml_app.log_user_access_control_update();


--
-- Name: user_access_control_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_access_control_history_update AFTER UPDATE ON ml_app.user_access_controls FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_user_access_control_update();


--
-- Name: user_authorization_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_authorization_history_insert AFTER INSERT ON ml_app.user_authorizations FOR EACH ROW EXECUTE PROCEDURE ml_app.log_user_authorization_update();


--
-- Name: user_authorization_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_authorization_history_update AFTER UPDATE ON ml_app.user_authorizations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_user_authorization_update();


--
-- Name: user_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_history_insert AFTER INSERT ON ml_app.users FOR EACH ROW EXECUTE PROCEDURE ml_app.log_user_update();


--
-- Name: user_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_history_update AFTER UPDATE ON ml_app.users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_user_update();


--
-- Name: user_role_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_role_history_insert AFTER INSERT ON ml_app.user_roles FOR EACH ROW EXECUTE PROCEDURE ml_app.log_user_role_update();


--
-- Name: user_role_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER user_role_history_update AFTER UPDATE ON ml_app.user_roles FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_user_role_update();


--
-- Name: log_datadic_choice_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_datadic_choice_history_insert AFTER INSERT ON ref_data.datadic_choices FOR EACH ROW EXECUTE PROCEDURE ml_app.datadic_choice_history_upd();


--
-- Name: log_datadic_choice_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_datadic_choice_history_update AFTER UPDATE ON ref_data.datadic_choices FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.datadic_choice_history_upd();


--
-- Name: log_datadic_variable_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_datadic_variable_history_insert AFTER INSERT ON ref_data.datadic_variables FOR EACH ROW EXECUTE PROCEDURE ref_data.log_datadic_variables_update();


--
-- Name: log_datadic_variable_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_datadic_variable_history_update AFTER UPDATE ON ref_data.datadic_variables FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ref_data.log_datadic_variables_update();


--
-- Name: log_redcap_data_collection_instrument_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_data_collection_instrument_history_insert AFTER INSERT ON ref_data.redcap_data_collection_instruments FOR EACH ROW EXECUTE PROCEDURE ref_data.redcap_data_collection_instrument_history_upd();


--
-- Name: log_redcap_data_collection_instrument_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_data_collection_instrument_history_update AFTER UPDATE ON ref_data.redcap_data_collection_instruments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ref_data.redcap_data_collection_instrument_history_upd();


--
-- Name: log_redcap_data_dictionary_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_data_dictionary_history_insert AFTER INSERT ON ref_data.redcap_data_dictionaries FOR EACH ROW EXECUTE PROCEDURE ml_app.redcap_data_dictionary_history_upd();


--
-- Name: log_redcap_data_dictionary_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_data_dictionary_history_update AFTER UPDATE ON ref_data.redcap_data_dictionaries FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.redcap_data_dictionary_history_upd();


--
-- Name: log_redcap_project_admin_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_project_admin_history_insert AFTER INSERT ON ref_data.redcap_project_admins FOR EACH ROW EXECUTE PROCEDURE ml_app.redcap_project_admin_history_upd();


--
-- Name: log_redcap_project_admin_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_project_admin_history_update AFTER UPDATE ON ref_data.redcap_project_admins FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.redcap_project_admin_history_upd();


--
-- Name: log_redcap_project_user_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_project_user_history_insert AFTER INSERT ON ref_data.redcap_project_users FOR EACH ROW EXECUTE PROCEDURE ref_data.redcap_project_user_history_upd();


--
-- Name: log_redcap_project_user_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_project_user_history_update AFTER UPDATE ON ref_data.redcap_project_users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ref_data.redcap_project_user_history_upd();


--
-- Name: log_activity_log_study_info_part_history_insert; Type: TRIGGER; Schema: study_info; Owner: -
--

CREATE TRIGGER log_activity_log_study_info_part_history_insert AFTER INSERT ON study_info.activity_log_study_info_parts FOR EACH ROW EXECUTE PROCEDURE study_info.log_activity_log_study_info_parts_update();


--
-- Name: log_activity_log_study_info_part_history_update; Type: TRIGGER; Schema: study_info; Owner: -
--

CREATE TRIGGER log_activity_log_study_info_part_history_update AFTER UPDATE ON study_info.activity_log_study_info_parts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE study_info.log_activity_log_study_info_parts_update();


--
-- Name: log_activity_log_view_user_data_user_proc_history_insert; Type: TRIGGER; Schema: study_info; Owner: -
--

CREATE TRIGGER log_activity_log_view_user_data_user_proc_history_insert AFTER INSERT ON study_info.activity_log_view_user_data_user_procs FOR EACH ROW EXECUTE PROCEDURE study_info.log_activity_log_view_user_data_user_procs_update();


--
-- Name: log_activity_log_view_user_data_user_proc_history_update; Type: TRIGGER; Schema: study_info; Owner: -
--

CREATE TRIGGER log_activity_log_view_user_data_user_proc_history_update AFTER UPDATE ON study_info.activity_log_view_user_data_user_procs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE study_info.log_activity_log_view_user_data_user_procs_update();


--
-- Name: log_study_common_section_history_insert; Type: TRIGGER; Schema: study_info; Owner: -
--

CREATE TRIGGER log_study_common_section_history_insert AFTER INSERT ON study_info.study_common_sections FOR EACH ROW EXECUTE PROCEDURE study_info.log_study_common_sections_update();


--
-- Name: log_study_common_section_history_update; Type: TRIGGER; Schema: study_info; Owner: -
--

CREATE TRIGGER log_study_common_section_history_update AFTER UPDATE ON study_info.study_common_sections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE study_info.log_study_common_sections_update();


--
-- Name: log_study_page_section_history_insert; Type: TRIGGER; Schema: study_info; Owner: -
--

CREATE TRIGGER log_study_page_section_history_insert AFTER INSERT ON study_info.study_page_sections FOR EACH ROW EXECUTE PROCEDURE study_info.log_study_page_sections_update();


--
-- Name: log_study_page_section_history_update; Type: TRIGGER; Schema: study_info; Owner: -
--

CREATE TRIGGER log_study_page_section_history_update AFTER UPDATE ON study_info.study_page_sections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE study_info.log_study_page_sections_update();


--
-- Name: log_viva2_rc_history_insert; Type: TRIGGER; Schema: viva_ref_info; Owner: -
--

CREATE TRIGGER log_viva2_rc_history_insert AFTER INSERT ON viva_ref_info.viva2_rcs FOR EACH ROW EXECUTE PROCEDURE viva_ref_info.log_viva2_rcs_update();


--
-- Name: log_viva2_rc_history_update; Type: TRIGGER; Schema: viva_ref_info; Owner: -
--

CREATE TRIGGER log_viva2_rc_history_update AFTER UPDATE ON viva_ref_info.viva2_rcs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE viva_ref_info.log_viva2_rcs_update();


--
-- Name: log_viva3_rc_history_insert; Type: TRIGGER; Schema: viva_ref_info; Owner: -
--

CREATE TRIGGER log_viva3_rc_history_insert AFTER INSERT ON viva_ref_info.viva3_rcs FOR EACH ROW EXECUTE PROCEDURE viva_ref_info.log_viva3_rcs_update();


--
-- Name: log_viva3_rc_history_update; Type: TRIGGER; Schema: viva_ref_info; Owner: -
--

CREATE TRIGGER log_viva3_rc_history_update AFTER UPDATE ON viva_ref_info.viva3_rcs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE viva_ref_info.log_viva3_rcs_update();


--
-- Name: log_viva_collection_instrument_history_insert; Type: TRIGGER; Schema: viva_ref_info; Owner: -
--

CREATE TRIGGER log_viva_collection_instrument_history_insert AFTER INSERT ON viva_ref_info.viva_collection_instruments FOR EACH ROW EXECUTE PROCEDURE viva_ref_info.log_viva_collection_instruments_update();


--
-- Name: log_viva_collection_instrument_history_update; Type: TRIGGER; Schema: viva_ref_info; Owner: -
--

CREATE TRIGGER log_viva_collection_instrument_history_update AFTER UPDATE ON viva_ref_info.viva_collection_instruments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE viva_ref_info.log_viva_collection_instruments_update();


--
-- Name: log_viva_domain_history_insert; Type: TRIGGER; Schema: viva_ref_info; Owner: -
--

CREATE TRIGGER log_viva_domain_history_insert AFTER INSERT ON viva_ref_info.viva_domains FOR EACH ROW EXECUTE PROCEDURE viva_ref_info.log_viva_domains_update();


--
-- Name: log_viva_domain_history_update; Type: TRIGGER; Schema: viva_ref_info; Owner: -
--

CREATE TRIGGER log_viva_domain_history_update AFTER UPDATE ON viva_ref_info.viva_domains FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE viva_ref_info.log_viva_domains_update();


--
-- Name: log_viva_timepoint_history_insert; Type: TRIGGER; Schema: viva_ref_info; Owner: -
--

CREATE TRIGGER log_viva_timepoint_history_insert AFTER INSERT ON viva_ref_info.viva_timepoints FOR EACH ROW EXECUTE PROCEDURE viva_ref_info.log_viva_timepoints_update();


--
-- Name: log_viva_timepoint_history_update; Type: TRIGGER; Schema: viva_ref_info; Owner: -
--

CREATE TRIGGER log_viva_timepoint_history_update AFTER UPDATE ON viva_ref_info.viva_timepoints FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE viva_ref_info.log_viva_timepoints_update();


--
-- Name: fk_rails_018f25e797; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_message_history
    ADD CONSTRAINT fk_rails_018f25e797 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_09244bb3dc; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests_selected_attrib_history
    ADD CONSTRAINT fk_rails_09244bb3dc FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_0aeeec6876; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_attrib_history
    ADD CONSTRAINT fk_rails_0aeeec6876 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_0b2f1b7819; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profiile_details
    ADD CONSTRAINT fk_rails_0b2f1b7819 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_0bc905968a; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_initial_review_history
    ADD CONSTRAINT fk_rails_0bc905968a FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_0f9a65942f; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_detail_history
    ADD CONSTRAINT fk_rails_0f9a65942f FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1257de9827; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignment_history
    ADD CONSTRAINT fk_rails_1257de9827 FOREIGN KEY (activity_log_data_request_assignment_id) REFERENCES data_requests.activity_log_data_request_assignments(id);


--
-- Name: fk_rails_21c43e2d3f; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_messages
    ADD CONSTRAINT fk_rails_21c43e2d3f FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_21e6e0496d; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_assignments
    ADD CONSTRAINT fk_rails_21e6e0496d FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_23475adebc; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests_selected_attrib_history
    ADD CONSTRAINT fk_rails_23475adebc FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_23edb1d63b; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignment_history
    ADD CONSTRAINT fk_rails_23edb1d63b FOREIGN KEY (data_request_assignment_id) REFERENCES data_requests.data_request_assignments(id);


--
-- Name: fk_rails_2b3876e80b; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profiile_detail_history
    ADD CONSTRAINT fk_rails_2b3876e80b FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_2eb6563795; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignments
    ADD CONSTRAINT fk_rails_2eb6563795 FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_31e0691a21; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_assignment_history
    ADD CONSTRAINT fk_rails_31e0691a21 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_3697b84df2; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_history
    ADD CONSTRAINT fk_rails_3697b84df2 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_3760832f71; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_academic_details
    ADD CONSTRAINT fk_rails_3760832f71 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_3b5bcce9fb; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_initial_reviews
    ADD CONSTRAINT fk_rails_3b5bcce9fb FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_3ea24a65fd; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests
    ADD CONSTRAINT fk_rails_3ea24a65fd FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_3fed9dc95f; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_message_history
    ADD CONSTRAINT fk_rails_3fed9dc95f FOREIGN KEY (data_request_message_id) REFERENCES data_requests.data_request_messages(id);


--
-- Name: fk_rails_44faf7af40; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignments
    ADD CONSTRAINT fk_rails_44faf7af40 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_4d465b6e85; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignments
    ADD CONSTRAINT fk_rails_4d465b6e85 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_4e6078aae5; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_detail_history
    ADD CONSTRAINT fk_rails_4e6078aae5 FOREIGN KEY (user_profile_detail_id) REFERENCES data_requests.user_profile_details(id);


--
-- Name: fk_rails_59cf667728; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_history
    ADD CONSTRAINT fk_rails_59cf667728 FOREIGN KEY (data_request_id) REFERENCES data_requests.data_requests(id);


--
-- Name: fk_rails_5dc9dc25de; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_details
    ADD CONSTRAINT fk_rails_5dc9dc25de FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_6c73bce4e5; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_history
    ADD CONSTRAINT fk_rails_6c73bce4e5 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_7004dc15e9; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_assignments
    ADD CONSTRAINT fk_rails_7004dc15e9 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_72b82fa91b; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_message_history
    ADD CONSTRAINT fk_rails_72b82fa91b FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_782e11a7b8; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests
    ADD CONSTRAINT fk_rails_782e11a7b8 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_7c8353b1b1; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_academic_detail_history
    ADD CONSTRAINT fk_rails_7c8353b1b1 FOREIGN KEY (user_profile_academic_detail_id) REFERENCES data_requests.user_profile_academic_details(id);


--
-- Name: fk_rails_8193f411a4; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_academic_detail_history
    ADD CONSTRAINT fk_rails_8193f411a4 FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_84d6bfc68b; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_attribs
    ADD CONSTRAINT fk_rails_84d6bfc68b FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_8e0ef86d46; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests_selected_attrib_history
    ADD CONSTRAINT fk_rails_8e0ef86d46 FOREIGN KEY (data_requests_selected_attrib_id) REFERENCES data_requests.data_requests_selected_attribs(id);


--
-- Name: fk_rails_8f01eb43fa; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_messages
    ADD CONSTRAINT fk_rails_8f01eb43fa FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_91a44fcfc7; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profiile_detail_history
    ADD CONSTRAINT fk_rails_91a44fcfc7 FOREIGN KEY (user_profiile_detail_id) REFERENCES data_requests.user_profiile_details(id);


--
-- Name: fk_rails_947505797a; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_detail_history
    ADD CONSTRAINT fk_rails_947505797a FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_9581557259; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignment_history
    ADD CONSTRAINT fk_rails_9581557259 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_9ab5b92f74; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignment_history
    ADD CONSTRAINT fk_rails_9ab5b92f74 FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_9d83f07142; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_academic_detail_history
    ADD CONSTRAINT fk_rails_9d83f07142 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_9fcbe0574d; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_assignment_history
    ADD CONSTRAINT fk_rails_9fcbe0574d FOREIGN KEY (data_request_assignment_table_id) REFERENCES data_requests.data_request_assignments(id);


--
-- Name: fk_rails_b184b7ce1b; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests_selected_attribs
    ADD CONSTRAINT fk_rails_b184b7ce1b FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_b339299708; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_attrib_history
    ADD CONSTRAINT fk_rails_b339299708 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_b6fd89ee5b; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_messages
    ADD CONSTRAINT fk_rails_b6fd89ee5b FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_b97a24587b; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_assignments
    ADD CONSTRAINT fk_rails_b97a24587b FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_c10fc3daf5; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_initial_review_history
    ADD CONSTRAINT fk_rails_c10fc3daf5 FOREIGN KEY (data_request_initial_review_id) REFERENCES data_requests.data_request_initial_reviews(id);


--
-- Name: fk_rails_d0f41b523a; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_initial_reviews
    ADD CONSTRAINT fk_rails_d0f41b523a FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_d0fa5dfe8e; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_details
    ADD CONSTRAINT fk_rails_d0fa5dfe8e FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_d1479234ac; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_assignment_history
    ADD CONSTRAINT fk_rails_d1479234ac FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_d73d7870a9; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_message_history
    ADD CONSTRAINT fk_rails_d73d7870a9 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_da6612b225; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests_selected_attribs
    ADD CONSTRAINT fk_rails_da6612b225 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_e4a6e38e6f; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_history
    ADD CONSTRAINT fk_rails_e4a6e38e6f FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_e89bc05f2a; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_attrib_history
    ADD CONSTRAINT fk_rails_e89bc05f2a FOREIGN KEY (data_request_attrib_id) REFERENCES data_requests.data_request_attribs(id);


--
-- Name: fk_rails_ead3ce3763; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_requests
    ADD CONSTRAINT fk_rails_ead3ce3763 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_eb22a58fff; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_attribs
    ADD CONSTRAINT fk_rails_eb22a58fff FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_ec4718ef45; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignments
    ADD CONSTRAINT fk_rails_ec4718ef45 FOREIGN KEY (data_request_assignment_id) REFERENCES data_requests.data_request_assignments(id);


--
-- Name: fk_rails_f1e305eb37; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_initial_reviews
    ADD CONSTRAINT fk_rails_f1e305eb37 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_f37d802307; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_initial_review_history
    ADD CONSTRAINT fk_rails_f37d802307 FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_f5715f3225; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.user_profile_academic_details
    ADD CONSTRAINT fk_rails_f5715f3225 FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_fac2c6fac3; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.activity_log_data_request_assignment_history
    ADD CONSTRAINT fk_rails_fac2c6fac3 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_fddf5fc543; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_initial_review_history
    ADD CONSTRAINT fk_rails_fddf5fc543 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_fea4d0d8c9; Type: FK CONSTRAINT; Schema: data_requests; Owner: -
--

ALTER TABLE ONLY data_requests.data_request_assignment_history
    ADD CONSTRAINT fk_rails_fea4d0d8c9 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_081ee3469f; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.grit_assignments
    ADD CONSTRAINT fk_rails_081ee3469f FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_15a9d2b53b; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.grit_assignment_history
    ADD CONSTRAINT fk_rails_15a9d2b53b FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_3657d6c5a5; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.pitt_bhi_assignment_history
    ADD CONSTRAINT fk_rails_3657d6c5a5 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_3e2d90b6a7; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.pitt_bhi_assignments
    ADD CONSTRAINT fk_rails_3e2d90b6a7 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_4498353cb8; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.sleep_assignment_history
    ADD CONSTRAINT fk_rails_4498353cb8 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_5948cd2e04; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.sleep_assignment_history
    ADD CONSTRAINT fk_rails_5948cd2e04 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_5953540cf4; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.grit_assignments
    ADD CONSTRAINT fk_rails_5953540cf4 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_675c55afb1; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.pitt_bhi_assignments
    ADD CONSTRAINT fk_rails_675c55afb1 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_6fb9cf3716; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.grit_assignment_history
    ADD CONSTRAINT fk_rails_6fb9cf3716 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_8075a87e8f; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.pitt_bhi_assignment_history
    ADD CONSTRAINT fk_rails_8075a87e8f FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_821973c8c6; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.sleep_assignments
    ADD CONSTRAINT fk_rails_821973c8c6 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_838684f7e8; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.sleep_assignment_history
    ADD CONSTRAINT fk_rails_838684f7e8 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_8b41db7451; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.sleep_assignments
    ADD CONSTRAINT fk_rails_8b41db7451 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_8fcf1391e1; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.sleep_assignment_history
    ADD CONSTRAINT fk_rails_8fcf1391e1 FOREIGN KEY (sleep_assignment_table_id) REFERENCES extra_app.sleep_assignments(id);


--
-- Name: fk_rails_ab8e683d49; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.sleep_assignments
    ADD CONSTRAINT fk_rails_ab8e683d49 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_cbc00f914a; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.pitt_bhi_assignments
    ADD CONSTRAINT fk_rails_cbc00f914a FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_cbe030ce55; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.grit_assignment_history
    ADD CONSTRAINT fk_rails_cbe030ce55 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_db9353d15f; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.grit_assignments
    ADD CONSTRAINT fk_rails_db9353d15f FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_dc3803548c; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.pitt_bhi_assignment_history
    ADD CONSTRAINT fk_rails_dc3803548c FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_de5807ee5f; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.grit_assignment_history
    ADD CONSTRAINT fk_rails_de5807ee5f FOREIGN KEY (grit_assignment_table_id) REFERENCES extra_app.grit_assignments(id);


--
-- Name: fk_rails_fdd5a80000; Type: FK CONSTRAINT; Schema: extra_app; Owner: -
--

ALTER TABLE ONLY extra_app.pitt_bhi_assignment_history
    ADD CONSTRAINT fk_rails_fdd5a80000 FOREIGN KEY (pitt_bhi_assignment_table_id) REFERENCES extra_app.pitt_bhi_assignments(id);


--
-- Name: fk_accuracy_score_history_accuracy_scores; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.accuracy_score_history
    ADD CONSTRAINT fk_accuracy_score_history_accuracy_scores FOREIGN KEY (accuracy_score_id) REFERENCES ml_app.accuracy_scores(id);


--
-- Name: fk_activity_log_player_contact_phone_history_activity_log_playe; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_activity_log_playe FOREIGN KEY (activity_log_player_contact_phone_id) REFERENCES ml_app.activity_log_player_contact_phones(id);


--
-- Name: fk_activity_log_player_contact_phone_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_player_contact_phone_history_player_contact_pho; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_player_contact_pho FOREIGN KEY (player_contact_id) REFERENCES ml_app.player_contacts(id);


--
-- Name: fk_activity_log_player_contact_phone_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phone_history
    ADD CONSTRAINT fk_activity_log_player_contact_phone_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_address_history_addresses; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.address_history
    ADD CONSTRAINT fk_address_history_addresses FOREIGN KEY (address_id) REFERENCES ml_app.addresses(id);


--
-- Name: fk_address_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.address_history
    ADD CONSTRAINT fk_address_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_address_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.address_history
    ADD CONSTRAINT fk_address_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_admin_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.admin_history
    ADD CONSTRAINT fk_admin_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_admin_history_upd_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.admin_history
    ADD CONSTRAINT fk_admin_history_upd_admins FOREIGN KEY (updated_by_admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_app_configuration_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_configuration_history
    ADD CONSTRAINT fk_app_configuration_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_app_configuration_history_app_configurations; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_configuration_history
    ADD CONSTRAINT fk_app_configuration_history_app_configurations FOREIGN KEY (app_configuration_id) REFERENCES ml_app.app_configurations(id);


--
-- Name: fk_app_type_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_type_history
    ADD CONSTRAINT fk_app_type_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_app_type_history_app_types; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_type_history
    ADD CONSTRAINT fk_app_type_history_app_types FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_college_history_colleges; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.college_history
    ADD CONSTRAINT fk_college_history_colleges FOREIGN KEY (college_id) REFERENCES ml_app.colleges(id);


--
-- Name: fk_dynamic_model_history_dynamic_models; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.dynamic_model_history
    ADD CONSTRAINT fk_dynamic_model_history_dynamic_models FOREIGN KEY (dynamic_model_id) REFERENCES ml_app.dynamic_models(id);


--
-- Name: fk_external_link_history_external_links; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_link_history
    ADD CONSTRAINT fk_external_link_history_external_links FOREIGN KEY (external_link_id) REFERENCES ml_app.external_links(id);


--
-- Name: fk_general_selection_history_general_selections; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.general_selection_history
    ADD CONSTRAINT fk_general_selection_history_general_selections FOREIGN KEY (general_selection_id) REFERENCES ml_app.general_selections(id);


--
-- Name: fk_item_flag_history_item_flags; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flag_history
    ADD CONSTRAINT fk_item_flag_history_item_flags FOREIGN KEY (item_flag_id) REFERENCES ml_app.item_flags(id);


--
-- Name: fk_item_flag_name_history_item_flag_names; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flag_name_history
    ADD CONSTRAINT fk_item_flag_name_history_item_flag_names FOREIGN KEY (item_flag_name_id) REFERENCES ml_app.item_flag_names(id);


--
-- Name: fk_message_template_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_template_history
    ADD CONSTRAINT fk_message_template_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_message_template_history_message_templates; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_template_history
    ADD CONSTRAINT fk_message_template_history_message_templates FOREIGN KEY (message_template_id) REFERENCES ml_app.message_templates(id);


--
-- Name: fk_nfs_store_archived_file_history_nfs_store_archived_files; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_file_history
    ADD CONSTRAINT fk_nfs_store_archived_file_history_nfs_store_archived_files FOREIGN KEY (nfs_store_archived_file_id) REFERENCES ml_app.nfs_store_archived_files(id);


--
-- Name: fk_nfs_store_archived_file_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_file_history
    ADD CONSTRAINT fk_nfs_store_archived_file_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_nfs_store_container_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_container_history
    ADD CONSTRAINT fk_nfs_store_container_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_nfs_store_container_history_nfs_store_containers; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_container_history
    ADD CONSTRAINT fk_nfs_store_container_history_nfs_store_containers FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


--
-- Name: fk_nfs_store_container_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_container_history
    ADD CONSTRAINT fk_nfs_store_container_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_nfs_store_filter_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_filter_history
    ADD CONSTRAINT fk_nfs_store_filter_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_nfs_store_filter_history_nfs_store_filters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_filter_history
    ADD CONSTRAINT fk_nfs_store_filter_history_nfs_store_filters FOREIGN KEY (nfs_store_filter_id) REFERENCES ml_app.nfs_store_filters(id);


--
-- Name: fk_nfs_store_stored_file_history_nfs_store_stored_files; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_stored_file_history
    ADD CONSTRAINT fk_nfs_store_stored_file_history_nfs_store_stored_files FOREIGN KEY (nfs_store_stored_file_id) REFERENCES ml_app.nfs_store_stored_files(id);


--
-- Name: fk_nfs_store_stored_file_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_stored_file_history
    ADD CONSTRAINT fk_nfs_store_stored_file_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_page_layout_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.page_layout_history
    ADD CONSTRAINT fk_page_layout_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_page_layout_history_page_layouts; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.page_layout_history
    ADD CONSTRAINT fk_page_layout_history_page_layouts FOREIGN KEY (page_layout_id) REFERENCES ml_app.page_layouts(id);


--
-- Name: fk_player_contact_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_contact_history
    ADD CONSTRAINT fk_player_contact_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_player_contact_history_player_contacts; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_contact_history
    ADD CONSTRAINT fk_player_contact_history_player_contacts FOREIGN KEY (player_contact_id) REFERENCES ml_app.player_contacts(id);


--
-- Name: fk_player_contact_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_contact_history
    ADD CONSTRAINT fk_player_contact_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_player_info_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_info_history
    ADD CONSTRAINT fk_player_info_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_player_info_history_player_infos; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_info_history
    ADD CONSTRAINT fk_player_info_history_player_infos FOREIGN KEY (player_info_id) REFERENCES ml_app.player_infos(id);


--
-- Name: fk_player_info_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_info_history
    ADD CONSTRAINT fk_player_info_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_protocol_event_history_protocol_events; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_event_history
    ADD CONSTRAINT fk_protocol_event_history_protocol_events FOREIGN KEY (protocol_event_id) REFERENCES ml_app.protocol_events(id);


--
-- Name: fk_protocol_history_protocols; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_history
    ADD CONSTRAINT fk_protocol_history_protocols FOREIGN KEY (protocol_id) REFERENCES ml_app.protocols(id);


--
-- Name: fk_rails_00b234154d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.masters
    ADD CONSTRAINT fk_rails_00b234154d FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_00f31a00c4; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_configurations
    ADD CONSTRAINT fk_rails_00f31a00c4 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_0208c3b54d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_filters
    ADD CONSTRAINT fk_rails_0208c3b54d FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_0210618434; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_identifier_history
    ADD CONSTRAINT fk_rails_0210618434 FOREIGN KEY (external_identifier_id) REFERENCES ml_app.external_identifiers(id);


--
-- Name: fk_rails_08e7f66647; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_infos
    ADD CONSTRAINT fk_rails_08e7f66647 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_08eec3f089; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_action_logs
    ADD CONSTRAINT fk_rails_08eec3f089 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_0910ca20ea; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.role_description_history
    ADD CONSTRAINT fk_rails_0910ca20ea FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_0a64e1160a; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_events
    ADD CONSTRAINT fk_rails_0a64e1160a FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_0ad81c489c; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_imports
    ADD CONSTRAINT fk_rails_0ad81c489c FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_0c84487284; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_containers
    ADD CONSTRAINT fk_rails_0c84487284 FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


--
-- Name: fk_rails_0d30944d1b; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_imports
    ADD CONSTRAINT fk_rails_0d30944d1b FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


--
-- Name: fk_rails_0de144234e; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_stored_files
    ADD CONSTRAINT fk_rails_0de144234e FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


--
-- Name: fk_rails_0e2ecd8d43; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_trash_actions
    ADD CONSTRAINT fk_rails_0e2ecd8d43 FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


--
-- Name: fk_rails_10869244dc; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.masters
    ADD CONSTRAINT fk_rails_10869244dc FOREIGN KEY (created_by_user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1694bfe639; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.users
    ADD CONSTRAINT fk_rails_1694bfe639 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_16d57266f7; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_history
    ADD CONSTRAINT fk_rails_16d57266f7 FOREIGN KEY (activity_log_id) REFERENCES ml_app.activity_logs(id);


--
-- Name: fk_rails_174e058eb3; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_roles
    ADD CONSTRAINT fk_rails_174e058eb3 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantrons
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1cc4562569; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_stored_files
    ADD CONSTRAINT fk_rails_1cc4562569 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1d67a3e7f2; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phones
    ADD CONSTRAINT fk_rails_1d67a3e7f2 FOREIGN KEY (protocol_id) REFERENCES ml_app.protocols(id);


--
-- Name: fk_rails_1ec40f248c; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.config_library_history
    ADD CONSTRAINT fk_rails_1ec40f248c FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_1fc7475261; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sub_processes
    ADD CONSTRAINT fk_rails_1fc7475261 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_20667815e3; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.pro_infos
    ADD CONSTRAINT fk_rails_20667815e3 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_22ccfd95e1; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flag_names
    ADD CONSTRAINT fk_rails_22ccfd95e1 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_23cd255bc6; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_infos
    ADD CONSTRAINT fk_rails_23cd255bc6 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_2708bd6a94; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_containers
    ADD CONSTRAINT fk_rails_2708bd6a94 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_272f69e6af; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_downloads
    ADD CONSTRAINT fk_rails_272f69e6af FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


--
-- Name: fk_rails_291bbea3bc; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.role_descriptions
    ADD CONSTRAINT fk_rails_291bbea3bc FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_2b59e23148; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_files
    ADD CONSTRAINT fk_rails_2b59e23148 FOREIGN KEY (nfs_store_stored_file_id) REFERENCES ml_app.nfs_store_stored_files(id);


--
-- Name: fk_rails_2cf2ce330f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_description_history
    ADD CONSTRAINT fk_rails_2cf2ce330f FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_2d8072edea; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.model_references
    ADD CONSTRAINT fk_rails_2d8072edea FOREIGN KEY (to_record_master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_2de1cadfad; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phones
    ADD CONSTRAINT fk_rails_2de1cadfad FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_2eab578259; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_files
    ADD CONSTRAINT fk_rails_2eab578259 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_318345354e; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_roles
    ADD CONSTRAINT fk_rails_318345354e FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_3389f178f6; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.admin_action_logs
    ADD CONSTRAINT fk_rails_3389f178f6 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_37a2f11066; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.page_layouts
    ADD CONSTRAINT fk_rails_37a2f11066 FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_3a3553e146; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_notifications
    ADD CONSTRAINT fk_rails_3a3553e146 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_3f5167a964; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_uploads
    ADD CONSTRAINT fk_rails_3f5167a964 FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


--
-- Name: fk_rails_447d125f63; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers
    ADD CONSTRAINT fk_rails_447d125f63 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantrons
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_47581bba71; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.role_description_history
    ADD CONSTRAINT fk_rails_47581bba71 FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_47b051d356; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers
    ADD CONSTRAINT fk_rails_47b051d356 FOREIGN KEY (sub_process_id) REFERENCES ml_app.sub_processes(id);


--
-- Name: fk_rails_48c9e0c5a2; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.addresses
    ADD CONSTRAINT fk_rails_48c9e0c5a2 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_49306e4f49; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.colleges
    ADD CONSTRAINT fk_rails_49306e4f49 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_4bbf83b940; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.model_references
    ADD CONSTRAINT fk_rails_4bbf83b940 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_4decdf690b; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.users_contact_infos
    ADD CONSTRAINT fk_rails_4decdf690b FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_4fe5122ed4; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_templates
    ADD CONSTRAINT fk_rails_4fe5122ed4 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_4ff6d28f98; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_uploads
    ADD CONSTRAINT fk_rails_4ff6d28f98 FOREIGN KEY (nfs_store_stored_file_id) REFERENCES ml_app.nfs_store_stored_files(id);


--
-- Name: fk_rails_51ae125c4f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.exception_logs
    ADD CONSTRAINT fk_rails_51ae125c4f FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_564af80fb6; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_events
    ADD CONSTRAINT fk_rails_564af80fb6 FOREIGN KEY (sub_process_id) REFERENCES ml_app.sub_processes(id);


--
-- Name: fk_rails_5a9926bbe8; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_descriptions
    ADD CONSTRAINT fk_rails_5a9926bbe8 FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_5b0628cf42; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_identifier_history
    ADD CONSTRAINT fk_rails_5b0628cf42 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_5ce1857310; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phones
    ADD CONSTRAINT fk_rails_5ce1857310 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_623e0ca5ac; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers
    ADD CONSTRAINT fk_rails_623e0ca5ac FOREIGN KEY (protocol_id) REFERENCES ml_app.protocols(id);


--
-- Name: fk_rails_639da31037; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_user_file_actions
    ADD CONSTRAINT fk_rails_639da31037 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_647c63b069; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_configurations
    ADD CONSTRAINT fk_rails_647c63b069 FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_6a3d7bf39f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_containers
    ADD CONSTRAINT fk_rails_6a3d7bf39f FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_6a971dc818; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.users
    ADD CONSTRAINT fk_rails_6a971dc818 FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_6de4fd560d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocols
    ADD CONSTRAINT fk_rails_6de4fd560d FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_6e050927c2; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.tracker_history
    ADD CONSTRAINT fk_rails_6e050927c2 FOREIGN KEY (tracker_id) REFERENCES ml_app.trackers(id);


--
-- Name: fk_rails_70c17e88fd; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.accuracy_scores
    ADD CONSTRAINT fk_rails_70c17e88fd FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_7218113eac; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_identifiers
    ADD CONSTRAINT fk_rails_7218113eac FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_72b1afe72f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_contacts
    ADD CONSTRAINT fk_rails_72b1afe72f FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_75138f1972; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_move_actions
    ADD CONSTRAINT fk_rails_75138f1972 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_776e17eafd; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_filters
    ADD CONSTRAINT fk_rails_776e17eafd FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_7808f5fdb3; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.users_contact_infos
    ADD CONSTRAINT fk_rails_7808f5fdb3 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_7c10a99849; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sub_processes
    ADD CONSTRAINT fk_rails_7c10a99849 FOREIGN KEY (protocol_id) REFERENCES ml_app.protocols(id);


--
-- Name: fk_rails_8108e25f83; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_access_controls
    ADD CONSTRAINT fk_rails_8108e25f83 FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_83aa075398; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.tracker_history
    ADD CONSTRAINT fk_rails_83aa075398 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_864938f733; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_description_history
    ADD CONSTRAINT fk_rails_864938f733 FOREIGN KEY (user_description_id) REFERENCES ml_app.user_descriptions(id);


--
-- Name: fk_rails_86cecb1e36; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.pro_infos
    ADD CONSTRAINT fk_rails_86cecb1e36 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_88664b466b; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.config_library_history
    ADD CONSTRAINT fk_rails_88664b466b FOREIGN KEY (config_library_id) REFERENCES ml_app.config_libraries(id);


--
-- Name: fk_rails_8be93bcf4b; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_types
    ADD CONSTRAINT fk_rails_8be93bcf4b FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_8f99de6d81; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_description_history
    ADD CONSTRAINT fk_rails_8f99de6d81 FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_9513fd1c35; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.tracker_history
    ADD CONSTRAINT fk_rails_9513fd1c35 FOREIGN KEY (sub_process_id) REFERENCES ml_app.sub_processes(id);


--
-- Name: fk_rails_971255ec2c; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sage_assignments
    ADD CONSTRAINT fk_rails_971255ec2c FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_990daa5f76; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocols
    ADD CONSTRAINT fk_rails_990daa5f76 FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_9d88430088; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.role_description_history
    ADD CONSTRAINT fk_rails_9d88430088 FOREIGN KEY (role_description_id) REFERENCES ml_app.role_descriptions(id);


--
-- Name: fk_rails_9e92bdfe65; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.tracker_history
    ADD CONSTRAINT fk_rails_9e92bdfe65 FOREIGN KEY (protocol_event_id) REFERENCES ml_app.protocol_events(id);


--
-- Name: fk_rails_9f5797d684; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.tracker_history
    ADD CONSTRAINT fk_rails_9f5797d684 FOREIGN KEY (protocol_id) REFERENCES ml_app.protocols(id);


--
-- Name: fk_rails_a44670b00a; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.addresses
    ADD CONSTRAINT fk_rails_a44670b00a FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_a4eb981c4a; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.model_references
    ADD CONSTRAINT fk_rails_a4eb981c4a FOREIGN KEY (from_record_master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_a69bfcfd81; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_preferences
    ADD CONSTRAINT fk_rails_a69bfcfd81 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_af2f6ffc55; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_history
    ADD CONSTRAINT fk_rails_af2f6ffc55 FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_b071294797; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_phones
    ADD CONSTRAINT fk_rails_b071294797 FOREIGN KEY (player_contact_id) REFERENCES ml_app.player_contacts(id);


--
-- Name: fk_rails_b0a6220067; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.colleges
    ADD CONSTRAINT fk_rails_b0a6220067 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_b138baacff; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.reports
    ADD CONSTRAINT fk_rails_b138baacff FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_b1e2154c26; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.imports
    ADD CONSTRAINT fk_rails_b1e2154c26 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_b345649dfe; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_roles
    ADD CONSTRAINT fk_rails_b345649dfe FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_b822840dc1; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers
    ADD CONSTRAINT fk_rails_b822840dc1 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_bb6af37155; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers
    ADD CONSTRAINT fk_rails_bb6af37155 FOREIGN KEY (protocol_event_id) REFERENCES ml_app.protocol_events(id);


--
-- Name: fk_rails_bd9f10d2c7; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.imports_model_generators
    ADD CONSTRAINT fk_rails_bd9f10d2c7 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_bdb308087e; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_uploads
    ADD CONSTRAINT fk_rails_bdb308087e FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_c05d151591; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.admins
    ADD CONSTRAINT fk_rails_c05d151591 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_c1ea9a5fd9; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_move_actions
    ADD CONSTRAINT fk_rails_c1ea9a5fd9 FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


--
-- Name: fk_rails_c2d5bb8930; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flags
    ADD CONSTRAINT fk_rails_c2d5bb8930 FOREIGN KEY (item_flag_name_id) REFERENCES ml_app.item_flag_names(id);


--
-- Name: fk_rails_c423dc1802; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_user_file_actions
    ADD CONSTRAINT fk_rails_c423dc1802 FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


--
-- Name: fk_rails_c55341c576; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.tracker_history
    ADD CONSTRAINT fk_rails_c55341c576 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_c720bf523c; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.exception_logs
    ADD CONSTRAINT fk_rails_c720bf523c FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_c94bae872a; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_action_logs
    ADD CONSTRAINT fk_rails_c94bae872a FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_cd756b42dd; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_downloads
    ADD CONSTRAINT fk_rails_cd756b42dd FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_cfc9dc539f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_action_logs
    ADD CONSTRAINT fk_rails_cfc9dc539f FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_d15f63d454; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_descriptions
    ADD CONSTRAINT fk_rails_d15f63d454 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_d3566ee56d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_notifications
    ADD CONSTRAINT fk_rails_d3566ee56d FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_d3c0ddde90; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.player_contacts
    ADD CONSTRAINT fk_rails_d3c0ddde90 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_da3ba4f850; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.config_libraries
    ADD CONSTRAINT fk_rails_da3ba4f850 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_dce5169cfd; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flags
    ADD CONSTRAINT fk_rails_dce5169cfd FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_de41d50f67; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_trash_actions
    ADD CONSTRAINT fk_rails_de41d50f67 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_deec8fcb38; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.dynamic_models
    ADD CONSTRAINT fk_rails_deec8fcb38 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_e01d928507; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_containers
    ADD CONSTRAINT fk_rails_e01d928507 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_e3c559b547; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sage_assignments
    ADD CONSTRAINT fk_rails_e3c559b547 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_e410af4010; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.page_layouts
    ADD CONSTRAINT fk_rails_e410af4010 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_ebab73db27; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sage_assignments
    ADD CONSTRAINT fk_rails_ebab73db27 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_ebf3863277; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_links
    ADD CONSTRAINT fk_rails_ebf3863277 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_ecfa3cb151; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_files
    ADD CONSTRAINT fk_rails_ecfa3cb151 FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


--
-- Name: fk_rails_f0ac516fff; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_configurations
    ADD CONSTRAINT fk_rails_f0ac516fff FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_f547361daa; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_filters
    ADD CONSTRAINT fk_rails_f547361daa FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


--
-- Name: fk_rails_f62500107f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.general_selections
    ADD CONSTRAINT fk_rails_f62500107f FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_f646dbe30d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.role_descriptions
    ADD CONSTRAINT fk_rails_f646dbe30d FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_fa6dbd15de; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_notifications
    ADD CONSTRAINT fk_rails_fa6dbd15de FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_report_history_reports; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.report_history
    ADD CONSTRAINT fk_report_history_reports FOREIGN KEY (report_id) REFERENCES ml_app.reports(id);


--
-- Name: fk_scantron_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantron_history
    ADD CONSTRAINT fk_scantron_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_scantron_history_scantrons; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantron_history
    ADD CONSTRAINT fk_scantron_history_scantrons FOREIGN KEY (scantron_table_id) REFERENCES ml_app.scantrons(id);


--
-- Name: fk_scantron_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantron_history
    ADD CONSTRAINT fk_scantron_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_sub_process_history_sub_processes; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sub_process_history
    ADD CONSTRAINT fk_sub_process_history_sub_processes FOREIGN KEY (sub_process_id) REFERENCES ml_app.sub_processes(id);


--
-- Name: fk_user_access_control_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_access_control_history
    ADD CONSTRAINT fk_user_access_control_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_user_access_control_history_user_access_controls; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_access_control_history
    ADD CONSTRAINT fk_user_access_control_history_user_access_controls FOREIGN KEY (user_access_control_id) REFERENCES ml_app.user_access_controls(id);


--
-- Name: fk_user_authorization_history_user_authorizations; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_authorization_history
    ADD CONSTRAINT fk_user_authorization_history_user_authorizations FOREIGN KEY (user_authorization_id) REFERENCES ml_app.user_authorizations(id);


--
-- Name: fk_user_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_history
    ADD CONSTRAINT fk_user_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_user_role_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_role_history
    ADD CONSTRAINT fk_user_role_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_user_role_history_user_roles; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_role_history
    ADD CONSTRAINT fk_user_role_history_user_roles FOREIGN KEY (user_role_id) REFERENCES ml_app.user_roles(id);


--
-- Name: rc_cis_master_id_fkey; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.rc_cis
    ADD CONSTRAINT rc_cis_master_id_fkey FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: unique_master_protocol_tracker_id; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.tracker_history
    ADD CONSTRAINT unique_master_protocol_tracker_id FOREIGN KEY (master_id, protocol_id, tracker_id) REFERENCES ml_app.trackers(master_id, protocol_id, id);


--
-- Name: valid_protocol_sub_process; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers
    ADD CONSTRAINT valid_protocol_sub_process FOREIGN KEY (protocol_id, sub_process_id) REFERENCES ml_app.sub_processes(protocol_id, id) MATCH FULL;


--
-- Name: valid_protocol_sub_process; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.tracker_history
    ADD CONSTRAINT valid_protocol_sub_process FOREIGN KEY (protocol_id, sub_process_id) REFERENCES ml_app.sub_processes(protocol_id, id) MATCH FULL;


--
-- Name: valid_sub_process_event; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers
    ADD CONSTRAINT valid_sub_process_event FOREIGN KEY (sub_process_id, protocol_event_id) REFERENCES ml_app.protocol_events(sub_process_id, id);


--
-- Name: valid_sub_process_event; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.tracker_history
    ADD CONSTRAINT valid_sub_process_event FOREIGN KEY (sub_process_id, protocol_event_id) REFERENCES ml_app.protocol_events(sub_process_id, id);


--
-- Name: fk_rails_22773d2230; Type: FK CONSTRAINT; Schema: redcap; Owner: -
--

ALTER TABLE ONLY redcap.viva_meta_variables
    ADD CONSTRAINT fk_rails_22773d2230 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_c53c5126b5; Type: FK CONSTRAINT; Schema: redcap; Owner: -
--

ALTER TABLE ONLY redcap.viva_meta_variable_history
    ADD CONSTRAINT fk_rails_c53c5126b5 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_e5b7c1d45d; Type: FK CONSTRAINT; Schema: redcap; Owner: -
--

ALTER TABLE ONLY redcap.viva_meta_variable_history
    ADD CONSTRAINT fk_rails_e5b7c1d45d FOREIGN KEY (viva_meta_variable_id) REFERENCES redcap.viva_meta_variables(id);


--
-- Name: fk_rails_029902d3e3; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variables
    ADD CONSTRAINT fk_rails_029902d3e3 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_143e8a7c25; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history
    ADD CONSTRAINT fk_rails_143e8a7c25 FOREIGN KEY (equivalent_to_id) REFERENCES ref_data.datadic_variables(id);


--
-- Name: fk_rails_16cfa46407; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionaries
    ADD CONSTRAINT fk_rails_16cfa46407 FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: fk_rails_25f366a78c; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionary_history
    ADD CONSTRAINT fk_rails_25f366a78c FOREIGN KEY (redcap_data_dictionary_id) REFERENCES ref_data.redcap_data_dictionaries(id);


--
-- Name: fk_rails_2aa7bf926a; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_collection_instruments
    ADD CONSTRAINT fk_rails_2aa7bf926a FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_32285f308d; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_client_requests
    ADD CONSTRAINT fk_rails_32285f308d FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: fk_rails_34eadb0aee; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variables
    ADD CONSTRAINT fk_rails_34eadb0aee FOREIGN KEY (equivalent_to_id) REFERENCES ref_data.datadic_variables(id);


--
-- Name: fk_rails_38d0954914; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_users
    ADD CONSTRAINT fk_rails_38d0954914 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_42389740a0; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choice_history
    ADD CONSTRAINT fk_rails_42389740a0 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_4766ebe50f; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionaries
    ADD CONSTRAINT fk_rails_4766ebe50f FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_5302a77293; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history
    ADD CONSTRAINT fk_rails_5302a77293 FOREIGN KEY (datadic_variable_id) REFERENCES ref_data.datadic_variables(id);


--
-- Name: fk_rails_63103b7cf7; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choice_history
    ADD CONSTRAINT fk_rails_63103b7cf7 FOREIGN KEY (datadic_choice_id) REFERENCES ref_data.datadic_choices(id);


--
-- Name: fk_rails_67ca4d7e1f; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choices
    ADD CONSTRAINT fk_rails_67ca4d7e1f FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_6c93846f69; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_collection_instrument_history
    ADD CONSTRAINT fk_rails_6c93846f69 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_7ba2e90d7d; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_user_history
    ADD CONSTRAINT fk_rails_7ba2e90d7d FOREIGN KEY (redcap_project_user_id) REFERENCES ref_data.redcap_project_users(id);


--
-- Name: fk_rails_89af917107; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_user_history
    ADD CONSTRAINT fk_rails_89af917107 FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: fk_rails_8dc5a059ee; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variables
    ADD CONSTRAINT fk_rails_8dc5a059ee FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_9a6eca0fe7; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionary_history
    ADD CONSTRAINT fk_rails_9a6eca0fe7 FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: fk_rails_a0bf0fdddb; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_user_history
    ADD CONSTRAINT fk_rails_a0bf0fdddb FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_a6952cc0e8; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_users
    ADD CONSTRAINT fk_rails_a6952cc0e8 FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: fk_rails_a7610f4fec; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_admin_history
    ADD CONSTRAINT fk_rails_a7610f4fec FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: fk_rails_cb0b57b6c1; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_collection_instrument_history
    ADD CONSTRAINT fk_rails_cb0b57b6c1 FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: fk_rails_ce6075441d; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_collection_instrument_history
    ADD CONSTRAINT fk_rails_ce6075441d FOREIGN KEY (redcap_data_collection_instrument_id) REFERENCES ref_data.redcap_data_collection_instruments(id);


--
-- Name: fk_rails_d7e89fcbde; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history
    ADD CONSTRAINT fk_rails_d7e89fcbde FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_ef47f37820; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history
    ADD CONSTRAINT fk_rails_ef47f37820 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_fffede9aa7; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionary_history
    ADD CONSTRAINT fk_rails_fffede9aa7 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_06dfdfd6c9; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_study_info_parts
    ADD CONSTRAINT fk_rails_06dfdfd6c9 FOREIGN KEY (study_info_part_id) REFERENCES study_info.study_info_parts(id);


--
-- Name: fk_rails_08cd20e5a1; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_info_part_history
    ADD CONSTRAINT fk_rails_08cd20e5a1 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_1b9bf2c3f4; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_info_parts
    ADD CONSTRAINT fk_rails_1b9bf2c3f4 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_2413b23df5; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_view_user_data_user_procs
    ADD CONSTRAINT fk_rails_2413b23df5 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_250d3c47df; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_study_info_part_history
    ADD CONSTRAINT fk_rails_250d3c47df FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_29a92b2130; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_page_section_history
    ADD CONSTRAINT fk_rails_29a92b2130 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_2bc9842a42; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_page_section_history
    ADD CONSTRAINT fk_rails_2bc9842a42 FOREIGN KEY (study_page_section_id) REFERENCES study_info.study_page_sections(id);


--
-- Name: fk_rails_352288763a; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_page_sections
    ADD CONSTRAINT fk_rails_352288763a FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45586cadb5; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_info_part_history
    ADD CONSTRAINT fk_rails_45586cadb5 FOREIGN KEY (study_info_part_table_id) REFERENCES study_info.study_info_parts(id);


--
-- Name: fk_rails_5149b96561; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_info_parts
    ADD CONSTRAINT fk_rails_5149b96561 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_52e18fc4bc; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_study_info_part_history
    ADD CONSTRAINT fk_rails_52e18fc4bc FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_5b8f25de61; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_common_section_history
    ADD CONSTRAINT fk_rails_5b8f25de61 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_6933ff5fa1; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_study_info_parts
    ADD CONSTRAINT fk_rails_6933ff5fa1 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_76d82b513c; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_view_user_data_user_proc_history
    ADD CONSTRAINT fk_rails_76d82b513c FOREIGN KEY (activity_log_view_user_data_user_proc_id) REFERENCES study_info.activity_log_view_user_data_user_procs(id);


--
-- Name: fk_rails_7d034f2136; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_study_info_part_history
    ADD CONSTRAINT fk_rails_7d034f2136 FOREIGN KEY (activity_log_study_info_part_id) REFERENCES study_info.activity_log_study_info_parts(id);


--
-- Name: fk_rails_92a60ed071; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_info_part_history
    ADD CONSTRAINT fk_rails_92a60ed071 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_9bb36ec3b6; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_study_info_part_history
    ADD CONSTRAINT fk_rails_9bb36ec3b6 FOREIGN KEY (study_info_part_id) REFERENCES study_info.study_info_parts(id);


--
-- Name: fk_rails_a2e4da626b; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_common_sections
    ADD CONSTRAINT fk_rails_a2e4da626b FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_a7fbd3d381; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_study_info_parts
    ADD CONSTRAINT fk_rails_a7fbd3d381 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_aa6a32c045; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_view_user_data_user_procs
    ADD CONSTRAINT fk_rails_aa6a32c045 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_aa824d721e; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_common_section_history
    ADD CONSTRAINT fk_rails_aa824d721e FOREIGN KEY (study_common_section_id) REFERENCES study_info.study_common_sections(id);


--
-- Name: fk_rails_b616300198; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_info_part_history
    ADD CONSTRAINT fk_rails_b616300198 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_bf99059606; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_view_user_data_user_proc_history
    ADD CONSTRAINT fk_rails_bf99059606 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_d50f946e2e; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.activity_log_view_user_data_user_proc_history
    ADD CONSTRAINT fk_rails_d50f946e2e FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_e7f9c535a2; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_page_sections
    ADD CONSTRAINT fk_rails_e7f9c535a2 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_ec7910979d; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_page_section_history
    ADD CONSTRAINT fk_rails_ec7910979d FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_f6598a33d5; Type: FK CONSTRAINT; Schema: study_info; Owner: -
--

ALTER TABLE ONLY study_info.study_info_parts
    ADD CONSTRAINT fk_rails_f6598a33d5 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_0be6c15b4e; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_collection_instrument_history
    ADD CONSTRAINT fk_rails_0be6c15b4e FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_24d94bed61; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva2_rcs
    ADD CONSTRAINT fk_rails_24d94bed61 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_35fbe181e3; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva2_rc_history
    ADD CONSTRAINT fk_rails_35fbe181e3 FOREIGN KEY (viva2_rc_id) REFERENCES viva_ref_info.viva2_rcs(id);


--
-- Name: fk_rails_36f3819789; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva2_rc_history
    ADD CONSTRAINT fk_rails_36f3819789 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_5b706322ce; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_domain_history
    ADD CONSTRAINT fk_rails_5b706322ce FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_6b956971be; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_timepoint_history
    ADD CONSTRAINT fk_rails_6b956971be FOREIGN KEY (viva_timepoint_id) REFERENCES viva_ref_info.viva_timepoints(id);


--
-- Name: fk_rails_6e89a89675; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_domain_history
    ADD CONSTRAINT fk_rails_6e89a89675 FOREIGN KEY (viva_domain_id) REFERENCES viva_ref_info.viva_domains(id);


--
-- Name: fk_rails_957d77bbd5; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva3_rcs
    ADD CONSTRAINT fk_rails_957d77bbd5 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_a38cdf9046; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_collection_instruments
    ADD CONSTRAINT fk_rails_a38cdf9046 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_a643d228bf; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva3_rc_history
    ADD CONSTRAINT fk_rails_a643d228bf FOREIGN KEY (viva3_rc_id) REFERENCES viva_ref_info.viva3_rcs(id);


--
-- Name: fk_rails_af05637c2f; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_timepoint_history
    ADD CONSTRAINT fk_rails_af05637c2f FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_b03f78180e; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_domains
    ADD CONSTRAINT fk_rails_b03f78180e FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_b4def23148; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_timepoints
    ADD CONSTRAINT fk_rails_b4def23148 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_e4f1330dc9; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva3_rc_history
    ADD CONSTRAINT fk_rails_e4f1330dc9 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_f3ca18e8a5; Type: FK CONSTRAINT; Schema: viva_ref_info; Owner: -
--

ALTER TABLE ONLY viva_ref_info.viva_collection_instrument_history
    ADD CONSTRAINT fk_rails_f3ca18e8a5 FOREIGN KEY (viva_collection_instrument_id) REFERENCES viva_ref_info.viva_collection_instruments(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO ml_app,extra_app,fem,data_requests,study_info,sleep,ref_data,redcap,dynamic,viva_ref_info,projects;

INSERT INTO "schema_migrations" (version) VALUES
('20150602181200'),
('20150602181229'),
('20150602181400'),
('20150602181925'),
('20150602205642'),
('20150603135202'),
('20150603153758'),
('20150603170429'),
('20150604160659'),
('20150609140033'),
('20150609150931'),
('20150609160545'),
('20150609161656'),
('20150609185229'),
('20150609185749'),
('20150609190556'),
('20150610142403'),
('20150610143629'),
('20150610155810'),
('20150610160257'),
('20150610183502'),
('20150610220253'),
('20150610220320'),
('20150610220451'),
('20150611144834'),
('20150611145259'),
('20150611180303'),
('20150611202453'),
('20150616202753'),
('20150616202829'),
('20150618143506'),
('20150618161857'),
('20150618161945'),
('20150619165405'),
('20150622144725'),
('20150623191520'),
('20150623194212'),
('20150625213040'),
('20150626190344'),
('20150629210656'),
('20150630202829'),
('20150702200308'),
('20150707142702'),
('20150707143233'),
('20150707150524'),
('20150707150615'),
('20150707150921'),
('20150707151004'),
('20150707151010'),
('20150707151032'),
('20150707151129'),
('20150707153720'),
('20150707222630'),
('20150710135307'),
('20150710135959'),
('20150710160209'),
('20150710160215'),
('20150715181110'),
('20150720141845'),
('20150720173900'),
('20150720175827'),
('20150721204937'),
('20150724165441'),
('20150727164955'),
('20150728133359'),
('20150728203820'),
('20150728213254'),
('20150728213551'),
('20150729182424'),
('20150730174055'),
('20150730181206'),
('20150730202422'),
('20150803181029'),
('20150803194546'),
('20150803194551'),
('20150804160523'),
('20150804203710'),
('20150805132950'),
('20150805161302'),
('20150805200932'),
('20150811174323'),
('20150812194032'),
('20150820151214'),
('20150820151728'),
('20150820152721'),
('20150820155555'),
('20150826145029'),
('20150826145125'),
('20150924163412'),
('20150924183936'),
('20151005143945'),
('20151009191559'),
('20151013191910'),
('20151015142035'),
('20151015150733'),
('20151015183136'),
('20151016160248'),
('20151019203248'),
('20151019204910'),
('20151020145339'),
('20151021162145'),
('20151021171534'),
('20151022142507'),
('20151022191658'),
('20151023171217'),
('20151026181305'),
('20151028145802'),
('20151028155426'),
('20151109223309'),
('20151120150828'),
('20151120151912'),
('20151123203524'),
('20151124151501'),
('20151125192206'),
('20151202180745'),
('20151208144918'),
('20151208200918'),
('20151208200919'),
('20151208200920'),
('20151208244916'),
('20151208244917'),
('20151208244918'),
('20151216102328'),
('20151218203119'),
('20160210200918'),
('20160210200919'),
('20170823145313'),
('20170901152707'),
('20170908074038'),
('20170922182052'),
('20170926144234'),
('20171002120537'),
('20171013141835'),
('20171013141837'),
('20171025095942'),
('20171031145807'),
('20171207163040'),
('20171207170748'),
('20180119173411'),
('20180123111956'),
('20180123154108'),
('20180126120818'),
('20180206173516'),
('20180209145336'),
('20180209152723'),
('20180209152747'),
('20180209171641'),
('20180228145731'),
('20180301114206'),
('20180302144109'),
('20180313091440'),
('20180319133539'),
('20180319133540'),
('20180319175721'),
('20180320105954'),
('20180320113757'),
('20180320154951'),
('20180320183512'),
('20180321082612'),
('20180321095805'),
('20180404150536'),
('20180405141059'),
('20180416145033'),
('20180426091838'),
('20180502082334'),
('20180504080300'),
('20180531091440'),
('20180723165621'),
('20180725140502'),
('20180814142112'),
('20180814142559'),
('20180814142560'),
('20180814142561'),
('20180814142562'),
('20180814142924'),
('20180814180843'),
('20180815104221'),
('20180817114138'),
('20180817114157'),
('20180818133205'),
('20180821123717'),
('20180822085118'),
('20180822093147'),
('20180830144523'),
('20180831132605'),
('20180911153518'),
('20180913142103'),
('20180924153547'),
('20181002142656'),
('20181002165822'),
('20181003182428'),
('20181004113953'),
('20181008104204'),
('20181030185123'),
('20181108115216'),
('20181113143210'),
('20181113143327'),
('20181113150331'),
('20181113150713'),
('20181113152652'),
('20181113154525'),
('20181113154855'),
('20181113154920'),
('20181113154942'),
('20181113165948'),
('20181113170144'),
('20181113172429'),
('20181113175031'),
('20181113180608'),
('20181113183446'),
('20181113184022'),
('20181113184516'),
('20181113184920'),
('20181113185315'),
('20181205103333'),
('20181206123849'),
('20181220131156'),
('20181220160047'),
('20190130152053'),
('20190130152208'),
('20190131130024'),
('20190201160559'),
('20190201160606'),
('20190225094021'),
('20190226165932'),
('20190226165938'),
('20190226173917'),
('20190312160404'),
('20190312163119'),
('20190416181222'),
('20190502142561'),
('20190517135351'),
('20190523115611'),
('20190528152006'),
('20190612140618'),
('20190614162317'),
('20190624082535'),
('20190628131713'),
('20190709174613'),
('20190709174638'),
('20190711074003'),
('20190711084434'),
('20190902123518'),
('20190906172361'),
('20191115124723'),
('20191115124732'),
('20200313160640'),
('20200403172361'),
('20200611123849'),
('20200723153130'),
('20200727081305'),
('20200727081306'),
('20200727122116'),
('20200727122117'),
('20200731121100'),
('20200731121144'),
('20201109114833'),
('20201111160935'),
('20201111161035'),
('20201111164800'),
('20201111165107'),
('20201111165109'),
('20201111165110'),
('20201112163129'),
('20210108085826'),
('20210110191022'),
('20210110191023'),
('20210110191024'),
('20210110191026'),
('20210110191028'),
('20210110191029'),
('20210110191030'),
('20210110191031'),
('20210110191033'),
('20210124185731'),
('20210124185733'),
('20210124185959'),
('20210124190000'),
('20210124190034'),
('20210124190035'),
('20210124190150'),
('20210124190152'),
('20210124190153'),
('20210124190155'),
('20210124190905'),
('20210124190907'),
('20210124190908'),
('20210124190909'),
('20210124190911'),
('20210124190912'),
('20210128180947'),
('20210129150044'),
('20210129154600'),
('20210201124324'),
('20210204205746'),
('20210209095546'),
('20210209154901'),
('20210215153201'),
('20210216132458'),
('20210216133011'),
('20210303164631'),
('20210303164632'),
('20210305113828'),
('20210308143952'),
('20210312143952'),
('20210318150132'),
('20210318150446'),
('20210330085617'),
('20210406154800'),
('20210428102016'),
('20210526183942'),
('20210712152134'),
('20210809151207'),
('20210816170804'),
('20211031152538'),
('20211031183210'),
('20211031183429'),
('20211041105001'),
('20211115141001'),
('20211117180701'),
('20211124120038'),
('20211126152918'),
('20211206102025'),
('20211206102028'),
('20211206102030'),
('20211206102244'),
('20211206102249'),
('20211206160502'),
('20211220122834'),
('20211220122835'),
('20211220122837'),
('20211220122840'),
('20211220123345'),
('20211220123347'),
('20211220123348'),
('20211220123518'),
('20211220123519'),
('20211220124525'),
('20211220124527'),
('20211220124611'),
('20211220124612'),
('20211220125302'),
('20211220125303'),
('20211220125327'),
('20211220125329'),
('20211220125410'),
('20211220125411'),
('20211220125452'),
('20211220125454'),
('20211220125821'),
('20211220125823'),
('20211220130316'),
('20211220130318'),
('20211220130532'),
('20211220130534'),
('20211220130655'),
('20211220130656'),
('20211220130659'),
('20211222111016'),
('20211222111721'),
('20211222134557'),
('20211222134602'),
('20211222135634'),
('20211222135957'),
('20211222140008'),
('20211222140019'),
('20211231113457'),
('20220121143719'),
('20220131111232'),
('20220131121830'),
('20220131121831'),
('20220131121833'),
('20220131121834'),
('20220131121835'),
('20220131123017'),
('20220131123100'),
('20220131131244'),
('20220131132533'),
('20220131135242'),
('20220131135349'),
('20220131135547'),
('20220131135600'),
('20220131140353'),
('20220131140521'),
('20220131143324'),
('20220131155227'),
('20220131155229'),
('20220131171632'),
('20220131172554'),
('20220131172618'),
('20220131182607'),
('20220131184011'),
('20220131184041'),
('20220131184511'),
('20220201102247'),
('20220201102549'),
('20220201173928'),
('20220202175848'),
('20220202190849'),
('20220202190931');


