--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.14
-- Dumped by pg_dump version 9.5.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ipa_ops; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ipa_ops;


--
-- Name: ml_app; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ml_app;


--
-- Name: testmybrain; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA testmybrain;


--
-- Name: find_new_local_ipa_records(integer); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.find_new_local_ipa_records(sel_sub_process_id integer) RETURNS TABLE(master_id integer, ipa_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
 RETURN QUERY
  SELECT distinct m.id, ipa.ipa_id
  FROM masters m
  INNER JOIN ipa_assignments ipa
   ON m.id = ipa.master_id
  INNER JOIN tracker_history th
     ON m.id = th.master_id
  LEFT JOIN sync_statuses s
   ON from_db = 'fphs-db'
     AND to_db = 'athena-db'
   AND m.id = s.from_master_id
  WHERE
   ipa.ipa_id is not null
     AND th.sub_process_id = sel_sub_process_id
   AND s.select_status IS NULL
  ;
END;
$$;


--
-- Name: log_activity_log_ipa_assignment_session_filestore_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_session_filestore_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_session_filestore_history
                  (
                      master_id,
                      ipa_assignment_id,
                      select_scanner,
                      operator,
                      notes,
                      session_date,
                      session_time,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_session_filestore_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.select_scanner,
                      NEW.operator,
                      NEW.notes,
                      NEW.session_date,
                      NEW.session_time,
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
-- Name: activity_log_bhs_assignment_info_request_notification(integer); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.activity_log_bhs_assignment_info_request_notification(activity_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
        dl_users INTEGER[];
        activity_record RECORD;
        message_id INTEGER;
        current_app_type_id INTEGER;
    BEGIN

        current_app_type_id := get_app_type_id_by_name('bhs');

        dl_users := get_user_ids_for_app_type_role(current_app_type_id, 'pi');

        SELECT * INTO activity_record FROM activity_log_bhs_assignments WHERE id = activity_id;

        IF activity_record.bhs_assignment_id IS NOT NULL AND activity_record.extra_log_type = 'primary'
        THEN

          SELECT
          INTO message_id
            create_message_notification_email(
              current_app_type_id,
              activity_record.master_id,
              activity_record.id,
              'ActivityLog::BhsAssignment'::VARCHAR,
              activity_record.user_id,
              dl_users,
              'bhs notification layout'::VARCHAR,
              'bhs pi notification content'::VARCHAR,
              'New Brain Health Study Info Request'::VARCHAR,
              now()::TIMESTAMP
            )
          ;

        END IF;
        RETURN message_id;
    END;
$$;


--
-- Name: activity_log_bhs_assignment_insert_defaults(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.activity_log_bhs_assignment_insert_defaults() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
          found_bhs RECORD;
          found_phone RECORD;
        BEGIN

            -- if there is no player contact phone set, try and set it
            -- in case the sync from Zeus to Elaine happened between the time the
            -- user opened the new form (with an empty drop down) and now.
            -- This avoids missing the population of this field
            IF NEW.select_record_from_player_contact_phones IS NULL THEN
              SELECT * FROM player_contacts
              INTO found_phone
              WHERE master_id = NEW.master_id AND rec_type = 'phone'
              ORDER BY rank desc
              LIMIT 1;

              IF found_phone.data is not null THEN
                NEW.select_record_from_player_contact_phones := found_phone.data;
              END IF;

            END IF;


            -- Generate the testmybrain URL from the BHS ID
            select * from bhs_assignments
            into found_bhs
            where master_id = NEW.master_id
            limit 1;


            IF found_bhs.bhs_id is not null THEN
              NEW.results_link := ('https://testmybrain.org?demotestid=' || found_bhs.bhs_id::varchar);
            END IF;
            RETURN NEW;
        END;
    $$;


--
-- Name: activity_log_bhs_assignment_insert_notification(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.activity_log_bhs_assignment_insert_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      message_id INTEGER;
      to_user_ids INTEGER[];
      num_primary_logs INTEGER;
      current_app_type_id INTEGER;
  BEGIN

        current_app_type_id := get_app_type_id_by_name('bhs');

        IF NEW.extra_log_type = 'contact_initiator' THEN

            -- Get the most recent info request from the activity log records for this master_id
            -- This gives us the user_id of the initiator of the request
            select array_agg(user_id)
            into to_user_ids
            from
            (select user_id
            from activity_log_bhs_assignments
            where
              master_id = NEW.master_id
              and extra_log_type = 'primary'
            order by id desc
            limit 1) t;

            -- If nobody was set, send to all users in the RA role
            IF to_user_ids IS NULL THEN
              to_user_ids := get_user_ids_for_app_type_role(current_app_type_id, 'ra');
            END IF;

            SELECT
            INTO message_id
              create_message_notification_email(
                current_app_type_id,
                NEW.master_id,
                NEW.id,
                'ActivityLog::BhsAssignment'::VARCHAR,
                NEW.user_id,
                to_user_ids,
                'bhs notification layout'::VARCHAR,
                'bhs message notification content'::VARCHAR,
                'Brain Health Study contact from PI'::VARCHAR,
                now()::TIMESTAMP
              )
            ;

            RETURN NEW;
        END IF;

        IF NEW.extra_log_type = 'respond_to_pi' THEN

            -- Get the most recent contact_initiator from the activity log records for this master_id
            -- This gives us the user_id of the PI making the Contact RA request
            select array_agg(user_id)
            into to_user_ids
            from
            (select user_id
            from activity_log_bhs_assignments
            where
              master_id = NEW.master_id
              and extra_log_type = 'contact_initiator'
            order by id desc
            limit 1) t;

            -- If nobody was set, send to all users in the PI role
            IF to_user_ids IS NULL THEN
              to_user_ids := get_user_ids_for_app_type_role(current_app_type_id, 'pi');
            END IF;


            SELECT
            INTO message_id
              create_message_notification_email(
                current_app_type_id,
                NEW.master_id,
                NEW.id,
                'ActivityLog::BhsAssignment'::VARCHAR,
                NEW.user_id,
                to_user_ids,
                'bhs notification layout'::VARCHAR,
                'bhs message notification content'::VARCHAR,
                'Brain Health Study contact from RA'::VARCHAR,
                now()::TIMESTAMP
              );

            RETURN NEW;
        END IF;

        -- If this is a primary type (info request), and there are already
        -- info request activities for this master
        -- then send another info request notification
        -- Don't do this otherwise, since the sync process is responsible for notifications
        -- related to the initial info request only when the sync has completed
        IF NEW.extra_log_type = 'primary' THEN
          SELECT count(id)
          INTO num_primary_logs
          FROM activity_log_bhs_assignments
          WHERE master_id = NEW.master_id AND id <> NEW.id AND extra_log_type = 'primary';

          IF num_primary_logs > 0 THEN
            PERFORM activity_log_bhs_assignment_info_request_notification(NEW.id);
          END IF;
        END IF;


        RETURN NEW;
    END;
$$;


--
-- Name: activity_log_ipa_assignment_new_ps_schedule(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.activity_log_ipa_assignment_new_ps_schedule() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    res RECORD;
    prev_sched RECORD;
    act_id INTEGER;
  BEGIN

  -- Get the references dynamic model record data
  SELECT *
  INTO res
  FROM model_references mr
  INNER JOIN ipa_ps_initial_screenings psis ON psis.id = mr.to_record_id
  INNER JOIN activity_log_ipa_assignment_phone_screens alps ON alps.id = mr.from_record_id
  WHERE mr.id=NEW.id;


  IF res.extra_log_type = 'start_phone_screen' THEN

    -- If a follow up was set, generate a new record in the IPA tracker log
    IF res.select_is_good_time_to_speak = 'not appropriate time'
      OR res.select_may_i_begin = 'not appropriate time'
      OR res.select_still_interested = 'yes - call back' THEN

      -- Get the previous schedule, so we can reuse caller and phone number
      SELECT * FROM activity_log_ipa_assignments
      INTO prev_sched
      WHERE
      master_id = res.master_id
      AND extra_log_type = 'schedule_screening'
      ORDER BY id DESC
      LIMIT 1;


      INSERT INTO activity_log_ipa_assignments (
        extra_log_type,
        master_id,
        user_id,
        created_at,
        updated_at,
        activity_date,
        select_record_from_player_contacts,
        select_who,
        follow_up_when,
        follow_up_time,
        notes
      )
      VALUES (
        'schedule_screening',
        res.master_id,
        res.user_id,
        now(),
        now(),
        now(),
        prev_sched.select_record_from_player_contacts,
        prev_sched.select_who,
        res.follow_up_date,
        res.follow_up_time,
        'Participant requested a call back during the initial stages of phone screening'
      )
      RETURNING id INTO act_id
      ;

    END IF;


  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: activity_log_ipa_assignment_perform_screening_callback(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.activity_log_ipa_assignment_perform_screening_callback() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    res RECORD;
    prev_sched RECORD;
    act_id INTEGER;
  BEGIN

  -- Get the references dynamic model record data
  SELECT *
  INTO res
  FROM model_references mr
  INNER JOIN ipa_screenings psis ON psis.id = mr.to_record_id
  INNER JOIN activity_log_ipa_assignments al ON al.id = mr.from_record_id
  WHERE mr.id=NEW.id;


  IF res.extra_log_type = 'perform_screening_follow_up' THEN

    -- If a follow up was set, generate a new record in the IPA tracker log
    IF res.good_time_to_speak_blank_yes_no = 'no' THEN

      -- Get the previous schedule, so we can reuse caller and phone number
      SELECT * FROM activity_log_ipa_assignments
      INTO prev_sched
      WHERE
      master_id = res.master_id
      AND extra_log_type = 'schedule_screening'
      ORDER BY id DESC
      LIMIT 1;


      INSERT INTO activity_log_ipa_assignments (
        extra_log_type,
        master_id,
        user_id,
        created_at,
        updated_at,
        activity_date,
        select_record_from_player_contacts,
        select_who,
        follow_up_when,
        follow_up_time,
        notes
      )
      VALUES (
        'schedule_screening',
        res.master_id,
        res.user_id,
        now(),
        now(),
        now(),
        prev_sched.select_record_from_player_contacts,
        prev_sched.select_who,
        res.callback_date,
        res.callback_time,
        'Participant requested a call back during the when performing a scheduled screening follow up'
      )
      RETURNING id INTO act_id
      ;

    END IF;


  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: activity_log_ipa_assignment_phone_screens_callback_set(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.activity_log_ipa_assignment_phone_screens_callback_set() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      initial_screening RECORD;
      football_experience RECORD;
      subject_size RECORD;
      tms RECORD;
      mri RECORD;
      sleep RECORD;
      health RECORD;
      tmoca RECORD;
      inex_id INTEGER;
      act_id INTEGER;
  BEGIN

  IF NEW.extra_log_type = 'finalize' THEN

    -- Get the latest football experience record
    SELECT *
    INTO initial_screening
    FROM ipa_ps_initial_screenings
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;


    -- Get the latest football experience record
    SELECT *
    INTO football_experience
    FROM ipa_ps_football_experiences
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest subject size record
    SELECT *
    INTO subject_size
    FROM ipa_ps_sizes
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest MRI record
    SELECT *
    INTO mri
    FROM ipa_ps_mris
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest TMS record
    SELECT *
    INTO tms
    FROM ipa_ps_tms_tests
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest sleep record
    SELECT *
    INTO sleep
    FROM ipa_ps_sleeps
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest health record
    SELECT *
    INTO health
    FROM ipa_ps_healths
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest tmoca record
    SELECT *
    INTO tmoca
    FROM ipa_ps_tmocas
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    INSERT INTO ipa_inex_checklists
    (
      master_id,
      created_at,
      updated_at,
      user_id,
      fixed_checklist_type,

      ix_consent_blank_yes_no,
      ix_consent_details,
      ix_not_pro_blank_yes_no,
      ix_not_pro_details,
      ix_age_range_blank_yes_no,
      ix_age_range_details,
      ix_weight_ok_blank_yes_no,
      ix_weight_ok_details,
      ix_no_seizure_blank_yes_no,
      ix_no_seizure_details,
      ix_no_device_impl_blank_yes_no,
      ix_no_device_impl_details,
      ix_no_ferromagnetic_impl_blank_yes_no,
      ix_no_ferromagnetic_impl_details,
      ix_diagnosed_sleep_apnea_blank_yes_no,
      ix_diagnosed_sleep_apnea_details,
      ix_diagnosed_heart_stroke_or_meds_blank_yes_no,
      ix_diagnosed_heart_stroke_or_meds_details,
      ix_chronic_pain_and_meds_blank_yes_no,
      ix_chronic_pain_and_meds_details,
      ix_tmoca_score_blank_yes_no,
      ix_tmoca_score_details,
      ix_no_hemophilia_blank_yes_no,
      ix_no_hemophilia_details,
      ix_raynauds_ok_blank_yes_no,
      ix_raynauds_ok_details,
      ix_mi_ok_blank_yes_no,
      ix_mi_ok_details,
      ix_bicycle_ok_blank_yes_no,
      ix_bicycle_ok_details

    )
    VALUES
    (
      NEW.master_id,
      NOW(),
      NOW(),
      NEW.user_id,

      'phone screen review',

      --ix_consent_blank_yes_no
      initial_screening.select_still_interested,
      -- ix_consent_details
'Responded "yes" to all questions including the final confirmation to continue in Start Phone Screening form',

      --ix_not_pro_blank_yes_no
      CASE WHEN football_experience.played_in_nfl_blank_yes_no = 'no' THEN 'yes' ELSE 'no' END,
      --ix_not_pro_details
'Responded "' || football_experience.played_in_nfl_blank_yes_no || '" to question "Have you ever played in the National Football League (NFL)?" in Football Experience form.',

      --ix_age_range_blank_yes_no
      CASE WHEN football_experience.age >= 24
        AND football_experience.age <= 55
        THEN 'yes' ELSE 'no' END,
      --ix_age_range_details
'Stated age ' || football_experience.age || ' in Football Experience form',

      --ix_weight_ok_blank_yes_no
      CASE WHEN subject_size.weight <= 450 THEN 'yes' ELSE 'no' END,
      --ix_weight_ok_details
'Stated weight ' || subject_size.weight || ' lbs in Size form.',

      --ix_no_seizure_blank_yes_no
      CASE WHEN tms.convulsion_or_seizue_blank_yes_no_dont_know = 'no' THEN 'yes' ELSE 'no' END,
      --ix_no_seizure_details
'Responded "' || tms.convulsion_or_seizue_blank_yes_no_dont_know || '" to question "Have you ever had a convulsion or a seizure?" in TMS form.',

      --ix_no_device_impl_blank_yes_no
      CASE WHEN mri.electrical_implants_blank_yes_no_dont_know = 'no' AND tms.pacemaker_blank_yes_no_dont_know = 'no' THEN 'yes' ELSE 'no' END,
      --ix_no_device_impl_details
'Responded "' || mri.electrical_implants_blank_yes_no_dont_know || '" to question "Do you have any electrical or battery-powered implants such as a cardiac pacemaker or a perfusion pump?" in MRI form.
Responded "' || tms.pacemaker_blank_yes_no_dont_know || '" to question "Do you have a cardiac pacemaker or intracardiac lines?" in TMS form.',

      --ix_no_ferromagnetic_impl_blank_yes_no
      CASE WHEN tms.metal_blank_yes_no_dont_know = 'no'
        AND mri.metal_implants_blank_yes_no_dont_know = 'no'
        AND mri.metal_jewelry_blank_yes_no = 'no'
        THEN 'yes' ELSE 'no' END,
      --ix_no_ferromagnetic_impl_details
'Responded "' || tms.metal_blank_yes_no_dont_know || '" to question "Do you have any metal in the brain, skull or elsewhere in the body?" in TMS form.
Responded "' || mri.metal_implants_blank_yes_no_dont_know || '" to question "Do you have any metal implants such as surgical clips, heart valves with steel parts, metal fragments, shrapnel or steel implants?" in MRI form.
Responded "' || mri.metal_jewelry_blank_yes_no || '" to question "Do you have any piercings or other metal jewelry that would not be able to be easily removed before an MRI scan?" in MRI form.',


      --ix_diagnosed_sleep_apnea_blank_yes_no
      CASE WHEN sleep.sleep_disorder_blank_yes_no_dont_know = 'yes' THEN 'yes' ELSE 'no' END,
      --ix_diagnosed_sleep_apnea_details
'Responded "' || sleep.sleep_disorder_blank_yes_no_dont_know || '" to question "Have you ever been diagnosed with sleep apnea or any other sleep disorders (e.g. narcolepsy)" in Sleep form.',

      --ix_diagnosed_heart_stroke_or_meds_blank_yes_no
      CASE WHEN health.other_heart_conditions_blank_yes_no_dont_know = 'yes'
      THEN 'yes' ELSE '' END,

      --ix_diagnosed_heart_stroke_or_meds_details
'Responded "' || health.other_heart_conditions_blank_yes_no_dont_know || '" to question "Have you been diagnosed with any other heart conditions or problems (e.g. heart attack, stroke, irregular heart rhythms, heart failure)?" in Health form.
Responded "' || health.hypertension_diagnosis_blank_yes_no_dont_know || '" to question "Have you been diagnosed with high blood pressure (hypertension), diabetes or high cholesterol?" in Health form.
To the follow up question "IF YES Have you ever or are you currently taking medications to manage these? Please describe." responded "' || health.hypertension_diagnosis_details || '"',

      --ix_chronic_pain_and_meds_blank_yes_no
      CASE WHEN health.chronic_pain_blank_yes_no = 'yes'
        AND health.chronic_pain_meds_blank_yes_no_dont_know = 'yes'
        THEN 'yes' ELSE 'no' END,
      --ix_chronic_pain_and_meds_details
'Responded "' || health.chronic_pain_blank_yes_no || '" to question "Do you have chronic pain?" in Health form.
Responded "' || health.chronic_pain_meds_blank_yes_no_dont_know || '" to question "IF YES - Do you currently take any medication (prescription or over the counter) or utilize alternative therapies to manage your chronic pain?" in Health form.',

      --ix_tmoca_score_blank_yes_no
      CASE WHEN tmoca.tmoca_score <= 19 THEN 'yes' ELSE 'no' END,
      --ix_tmoca_score_details
'Scored "' || tmoca.tmoca_score || ' in T-MoCA.',

      --ix_no_hemophilia_blank_yes_no
      CASE WHEN health.hemophilia_blank_yes_no_dont_know = 'no' THEN 'yes' ELSE 'no' END,
      --ix_no_hemophilia_details
'Responded "' || health.hemophilia_blank_yes_no_dont_know || '" to question "Do you suffer from hemophilia?" in Health form.',

      --ix_raynauds_ok_blank_yes_no
      CASE WHEN health.raynauds_syndrome_severity_selection = 'moderate' OR
        health.raynauds_syndrome_severity_selection = 'severe'
        THEN 'no'
        ELSE 'yes' END,

      --ix_raynauds_ok_details
'Responded "' || health.raynauds_syndrome_blank_yes_no_dont_know || '" to question "Do you suffer from Raynaud''s syndrome?" in Health form.
Responded "' || health.raynauds_syndrome_severity_selection || '" to follow up question "Would you say that it is mild, moderate or severe?".',

      --ix_mi_ok_blank_yes_no
      NULL,
      --ix_mi_ok_details
'',

      --ix_bicycle_ok_blank_yes_no
      CASE WHEN health.cycle_blank_yes_no = 'yes' THEN 'yes' ELSE 'no' END,
      --ix_bicycle_ok_details
'Responded "' || health.cycle_blank_yes_no || '" to question "Are you able to sit on and pedal a bicycle?" in Health form.'

    )
    RETURNING id INTO inex_id;

    INSERT INTO activity_log_ipa_assignment_inex_checklists
    (
      master_id,
      created_at,
      updated_at,
      user_id,
      extra_log_type
    )
    VALUES
    (
      NEW.master_id,
      NOW(),
      NOW(),
      NEW.user_id,
      'phone_screen_review'
    )
    RETURNING id INTO act_id;

    INSERT INTO model_references
    (
      created_at,
      updated_at,
      user_id,
      from_record_type,
      from_record_id,
      from_record_master_id,
      to_record_type,
      to_record_id,
      to_record_master_id
    )
    VALUES
    (
      NOW(),
      NOW(),
      NEW.user_id,
      'ActivityLog::IpaAssignmentInexChecklist',
      act_id,
      NEW.master_id,
      'DynamicModel::IpaInexChecklist',
      inex_id,
      NEW.master_id
    );


  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: activity_log_ipa_assignment_ps_follow_up(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.activity_log_ipa_assignment_ps_follow_up() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    res RECORD;
    prev_sched RECORD;
    act_id INTEGER;
  BEGIN

  res := NEW;

  IF res.extra_log_type = 'schedule_callback' THEN

    -- Get the previous schedule, so we can reuse caller and phone number
    SELECT * FROM activity_log_ipa_assignments
    INTO prev_sched
    WHERE
    master_id = res.master_id
    AND extra_log_type = 'schedule_screening'
    ORDER BY id DESC
    LIMIT 1;


    INSERT INTO activity_log_ipa_assignments (
      extra_log_type,
      master_id,
      user_id,
      created_at,
      updated_at,
      activity_date,
      select_record_from_player_contacts,
      select_who,
      follow_up_when,
      follow_up_time,
      notes
    )
    VALUES (
      'screening_follow_up',
      res.master_id,
      res.user_id,
      now(),
      now(),
      now(),
      prev_sched.select_record_from_player_contacts,
      prev_sched.select_who,
      res.callback_date,
      res.callback_time,
      'Participant phone screening completed. Follow up scheduled.'
    )
    RETURNING id INTO act_id
    ;


  END IF;

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
-- Name: create_all_remote_bhs_records(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_all_remote_bhs_records() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
bhs_record RECORD;
BEGIN

FOR bhs_record IN
  SELECT * from temp_bhs_assignments
LOOP

PERFORM create_remote_bhs_record(
bhs_record.bhs_id,
(SELECT (pi::varchar)::player_infos FROM temp_player_infos pi WHERE master_id = bhs_record.master_id LIMIT 1),
ARRAY(SELECT distinct (pc::varchar)::player_contacts FROM temp_player_contacts pc WHERE master_id = bhs_record.master_id)
);

END LOOP;

return 1;

END;
$$;


--
-- Name: create_all_remote_ipa_records(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_all_remote_ipa_records() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
 ipa_record RECORD;
BEGIN

 FOR ipa_record IN
   SELECT * from temp_ipa_assignments
 LOOP

  PERFORM create_remote_ipa_record(
   ipa_record.ipa_id::BIGINT,
   (SELECT (pi::varchar)::player_infos FROM temp_player_infos pi WHERE master_id = ipa_record.master_id LIMIT 1),
   ARRAY(SELECT distinct (pc::varchar)::player_contacts FROM temp_player_contacts pc WHERE master_id = ipa_record.master_id),
   ARRAY(SELECT distinct (a::varchar)::addresses FROM temp_addresses a WHERE master_id = ipa_record.master_id)
  );

 END LOOP;

 return 1;

END;
$$;


--
-- Name: create_message_notification_email(character varying, character varying, character varying, json, character varying[], character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_message_notification_email(layout_template_name character varying, content_template_name character varying, subject character varying, data json, recipient_emails character varying[], from_user_email character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  last_id INTEGER;
BEGIN

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

  SELECT create_message_notification_job(last_id)
  INTO last_id
  ;

  RETURN last_id;
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
-- Name: create_message_notification_job(integer); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_message_notification_job(message_notification_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  last_id INTEGER;
BEGIN

  INSERT INTO delayed_jobs
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
    now(),
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


SET default_tablespace = '';

SET default_with_oids = false;

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
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:36.922871'::timestamp without time zone
);


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
-- Name: create_remote_bhs_record(integer, ml_app.player_infos, ml_app.player_contacts[]); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_remote_bhs_record(match_bhs_id integer, new_player_info_record ml_app.player_infos, new_player_contact_records ml_app.player_contacts[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	found_bhs record;
	player_contact record;
BEGIN

-- Find the bhs_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_bhs
FROM bhs_assignments bhs
WHERE bhs.bhs_id = match_bhs_id
LIMIT 1;

-- At this point, if we found the above record, then the master record can be referred to with found_bhs.master_id
-- We also create the new records setting the user_id to match that of the found_bhs record, rather than the original
-- value from the source database, which probably would not match the user IDs in the remote database. The user_id of the
-- found_bhs record is conceptually valid, since it is that user that has effectively kicked off the synchronization process
-- and requested the new player_infos and player_contacts records be created.

IF NOT FOUND THEN
	RAISE EXCEPTION 'No BHS ID found for master_id --> %', (new_player_info_record.master_id);
ELSE


	-- Create the player info record
  INSERT INTO player_infos
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
    source
  )
  SELECT
    found_bhs.master_id,
    new_player_info_record.first_name,
    new_player_info_record.last_name,
    new_player_info_record.middle_name,
    new_player_info_record.nick_name,
    new_player_info_record.birth_date,
    new_player_info_record.death_date,
    found_bhs.user_id,
    new_player_info_record.created_at,
    new_player_info_record.updated_at,
    new_player_info_record.contact_pref,
    new_player_info_record.start_year,
    new_player_info_record.rank,
    new_player_info_record.notes,
    new_player_info_record.contact_id,
    new_player_info_record.college,
    new_player_info_record.end_year,
    new_player_info_record.source
  ;

	FOREACH player_contact IN ARRAY new_player_contact_records LOOP
	  INSERT INTO player_contacts
		(
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
				found_bhs.master_id,
				player_contact.rec_type,
				player_contact.data,
				player_contact.source,
				player_contact.rank,
				found_bhs.user_id,
				player_contact.created_at,
				player_contact.updated_at
		;

	END LOOP;


  -- Now update the activity log record.
	UPDATE activity_log_bhs_assignments
	SET select_record_from_player_contact_phones = (
		SELECT data FROM player_contacts
		WHERE rec_type='phone' AND rank is not null AND master_id = found_bhs.master_id
		ORDER BY rank desc
		LIMIT 1
	), results_link = ('https://testmybrain.org?demotestid=' || found_bhs.bhs_id::varchar)
	WHERE bhs_assignment_id is not null AND (select_record_from_player_contact_phones is null OR select_record_from_player_contact_phones = '');


	return found_bhs.master_id;
END IF;

END;
$$;


--
-- Name: create_remote_bhs_record(bigint, ml_app.player_infos, ml_app.player_contacts[]); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_remote_bhs_record(match_bhs_id bigint, new_player_info_record ml_app.player_infos, new_player_contact_records ml_app.player_contacts[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
found_bhs record;
player_contact record;
pc_length INTEGER;
found_pc record;
last_id INTEGER;
phone VARCHAR;
BEGIN

-- Find the bhs_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_bhs
FROM bhs_assignments bhs
WHERE bhs.bhs_id = match_bhs_id
LIMIT 1;

-- At this point, if we found the above record, then the master record can be referred to with found_bhs.master_id
-- We also create the new records setting the user_id to match that of the found_bhs record, rather than the original
-- value from the source database, which probably would not match the user IDs in the remote database. The user_id of the
-- found_bhs record is conceptually valid, since it is that user that has effectively kicked off the synchronization process
-- and requested the new player_infos and player_contacts records be created.

IF NOT FOUND THEN
RAISE EXCEPTION 'No bhs_assigments record found for BHS_ID --> %', (match_bhs_id);
END IF;




IF new_player_info_record.master_id IS NULL THEN
RAISE NOTICE 'No new_player_info_record found for BHS_ID --> %', (match_bhs_id);
RETURN NULL;
ELSE

RAISE NOTICE 'Syncing player info record %', (new_player_info_record::varchar);

-- Create the player info record
  INSERT INTO player_infos
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
    source
  )
  SELECT
    found_bhs.master_id,
    new_player_info_record.first_name,
    new_player_info_record.last_name,
    new_player_info_record.middle_name,
    new_player_info_record.nick_name,
    new_player_info_record.birth_date,
    new_player_info_record.death_date,
    found_bhs.user_id,
    new_player_info_record.created_at,
    new_player_info_record.updated_at,
    new_player_info_record.contact_pref,
    new_player_info_record.start_year,
    new_player_info_record.rank,
    new_player_info_record.notes,
    new_player_info_record.contact_id,
    new_player_info_record.college,
    new_player_info_record.end_year,
    new_player_info_record.source

RETURNING id
  INTO last_id
  ;


END IF;



SELECT array_length(new_player_contact_records, 1)
INTO pc_length;


IF pc_length IS NULL THEN
RAISE NOTICE 'No new_player_contact_records found for BHS_ID --> %', (match_bhs_id);
ELSE

RAISE NOTICE 'player contacts length %', (pc_length);

FOREACH player_contact IN ARRAY new_player_contact_records LOOP

SELECT * from player_contacts
INTO found_pc
WHERE
master_id = found_bhs.master_id AND
rec_type = player_contact.rec_type AND
data = player_contact.data
LIMIT 1;

IF found_pc.id IS NULL THEN

  INSERT INTO player_contacts
(
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
found_bhs.master_id,
player_contact.rec_type,
player_contact.data,
player_contact.source,
player_contact.rank,
found_bhs.user_id,
player_contact.created_at,
player_contact.updated_at
;
END IF;

END LOOP;


SELECT id
INTO last_id
FROM activity_log_bhs_assignments
WHERE
bhs_assignment_id IS NOT NULL
AND (select_record_from_player_contact_phones is null OR select_record_from_player_contact_phones = '')
AND master_id = found_bhs.master_id
AND extra_log_type = 'primary'
ORDER BY id ASC
LIMIT 1;


-- Get the best phone number
SELECT data FROM player_contacts
INTO phone
WHERE rec_type='phone' AND rank is not null AND master_id = found_bhs.master_id
ORDER BY rank desc
LIMIT 1;

RAISE NOTICE 'best phone number %', (phone);
  RAISE NOTICE 'AL ID %', (last_id);

  -- Now update the activity log record.
UPDATE activity_log_bhs_assignments
SET
  select_record_from_player_contact_phones = phone,
results_link = ('https://testmybrain.org?demotestid=' || found_bhs.bhs_id::varchar),
updated_at = now()
WHERE
id = last_id;


-- Now send a notification to the PI
PERFORM activity_log_bhs_assignment_info_request_notification(last_id);


END IF;

return found_bhs.master_id;

END;
$$;


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
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:35.929228'::timestamp without time zone,
    country character varying(3),
    postal_code character varying,
    region character varying
);


--
-- Name: create_remote_ipa_record(bigint, ml_app.player_infos, ml_app.player_contacts[], ml_app.addresses[]); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_remote_ipa_record(match_ipa_id bigint, new_player_info_record ml_app.player_infos, new_player_contact_records ml_app.player_contacts[], new_address_records ml_app.addresses[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
 found_ipa record;
 etl_user_id INTEGER;
 new_master_id INTEGER;
 player_contact record;
 address record;
 pc_length INTEGER;
 found_pc record;
 a_length INTEGER;
 found_a record;
 last_id INTEGER;
BEGIN

-- Find the ipa_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_ipa
FROM ipa_assignments ipa
WHERE ipa.ipa_id = match_ipa_id
LIMIT 1;

-- If the IPA external identifier already exists then the sync should fail.

IF FOUND THEN
 RAISE NOTICE 'Already transferred: ipa_assigments record found for IPA_ID --> %', (match_ipa_id);
 UPDATE temp_ipa_assignments SET status='already transferred', to_master_id=new_master_id WHERE ipa_id = match_ipa_id;
  RETURN found_ipa.master_id;
END IF;

-- We create new records setting user_id for the user with email fphsetl@hms.harvard.edu, rather than the original
-- value from the source database, which probably would not match the user IDs in the remote database.
SELECT id
INTO etl_user_id
FROM users u
WHERE u.email = 'fphsetl@hms.harvard.edu'
LIMIT 1;

IF NOT FOUND THEN
 RAISE EXCEPTION 'No user with email fphsetl@hms.harvard.edu was found. Can not continue.';
END IF;

UPDATE temp_ipa_assignments SET status='started sync' WHERE ipa_id = match_ipa_id;


RAISE NOTICE 'Creating master record with user_id %', (etl_user_id::varchar);

INSERT INTO masters
(user_id, created_at, updated_at) VALUES (etl_user_id, now(), now())
RETURNING id
INTO new_master_id;

RAISE NOTICE 'Creating external identifier record %', (match_ipa_id::varchar);

INSERT INTO ipa_assignments
(ipa_id, master_id, user_id, created_at, updated_at)
VALUES (match_ipa_id, new_master_id, etl_user_id, now(), now());



IF new_player_info_record.master_id IS NULL THEN
 RAISE NOTICE 'No new_player_info_record found for IPA_ID --> %', (match_ipa_id);
 UPDATE temp_ipa_assignments SET status='failed - no player info provided' WHERE ipa_id = match_ipa_id;
 RETURN NULL;
ELSE

 RAISE NOTICE 'Syncing player info record %', (new_player_info_record::varchar);

 -- Create the player info record
  INSERT INTO player_infos
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
    source
  )
  SELECT
    new_master_id,
    new_player_info_record.first_name,
    new_player_info_record.last_name,
    new_player_info_record.middle_name,
    new_player_info_record.nick_name,
    new_player_info_record.birth_date,
    new_player_info_record.death_date,
    etl_user_id,
    new_player_info_record.created_at,
    new_player_info_record.updated_at,
    new_player_info_record.contact_pref,
    new_player_info_record.start_year,
    new_player_info_record.rank,
    new_player_info_record.notes,
    new_player_info_record.contact_id,
    new_player_info_record.college,
    new_player_info_record.end_year,
    new_player_info_record.source

  RETURNING id
   INTO last_id
   ;


END IF;



SELECT array_length(new_player_contact_records, 1)
INTO pc_length;


IF pc_length IS NULL THEN
 RAISE NOTICE 'No new_player_contact_records found for IPA_ID --> %', (match_ipa_id);
ELSE

 RAISE NOTICE 'player contacts length %', (pc_length);

 FOREACH player_contact IN ARRAY new_player_contact_records LOOP

  SELECT * from player_contacts
  INTO found_pc
  WHERE
   master_id = new_master_id AND
   rec_type = player_contact.rec_type AND
   data = player_contact.data
  LIMIT 1;

  IF found_pc.id IS NULL THEN

    INSERT INTO player_contacts
(
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
     new_master_id,
     player_contact.rec_type,
     player_contact.data,
     player_contact.source,
     player_contact.rank,
     etl_user_id,
     player_contact.created_at,
     player_contact.updated_at
   ;
  END IF;

 END LOOP;

END IF;




SELECT array_length(new_address_records, 1)
INTO a_length;


IF a_length IS NULL THEN
 RAISE NOTICE 'No new_address_records found for IPA_ID --> %', (match_ipa_id);
ELSE

 RAISE NOTICE 'addresses length %', (a_length);

 FOREACH address IN ARRAY new_address_records LOOP

  SELECT * from addresses
  INTO found_a
  WHERE
   master_id = new_master_id AND
   street = address.street AND
   zip = address.zip
  LIMIT 1;

  IF found_a.id IS NULL THEN

    INSERT INTO addresses
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
       updated_at
   )
SELECT
     new_master_id,
     address.street,
     address.street2,
     address.street3,
     address.city,
     address.state,
     address.zip,
     address.source,
     address.rank,
     address.rec_type,
     etl_user_id,
     address.created_at,
     address.updated_at
   ;
  END IF;

 END LOOP;

END IF;

RAISE NOTICE 'Setting results for master_id %', (new_master_id);

UPDATE temp_ipa_assignments SET status='completed', to_master_id=new_master_id WHERE ipa_id = match_ipa_id;

return new_master_id;

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
-- Name: find_new_local_ipa_records(integer); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.find_new_local_ipa_records(sel_sub_process_id integer) RETURNS TABLE(master_id integer, ipa_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
 RETURN QUERY
  SELECT distinct m.id, ipa.ipa_id
  FROM masters m
  INNER JOIN ipa_assignments ipa
   ON m.id = ipa.master_id
  INNER JOIN tracker_history th
     ON m.id = th.master_id
  LEFT JOIN sync_statuses s
   ON from_db = 'fphs-db'
     AND to_db = 'athena-db'
   AND m.id = s.from_master_id
  WHERE
   ipa.ipa_id is not null
     AND th.sub_process_id = sel_sub_process_id
   AND s.select_status IS NULL
  ;
END;
$$;


--
-- Name: find_new_remote_bhs_records(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.find_new_remote_bhs_records() RETURNS TABLE(master_id integer, bhs_id bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN QUERY
SELECT distinct bhs.master_id, bhs.bhs_id
FROM masters m
LEFT JOIN player_infos pi
ON pi.master_id = m.id
INNER JOIN bhs_assignments bhs
ON m.id = bhs.master_id
INNER JOIN activity_log_bhs_assignments al
ON m.id = al.master_id AND al.extra_log_type = 'primary'
WHERE
  pi.id IS NULL
AND bhs.bhs_id is not null
AND bhs.bhs_id <> 100000000
;
END;
$$;


--
-- Name: find_new_remote_ipa_records(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.find_new_remote_ipa_records() RETURNS TABLE(master_id integer, ipa_id bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
 RETURN QUERY
  SELECT distinct ipa.master_id, ipa.ipa_id
  FROM masters m
  LEFT JOIN player_infos pi
  ON pi.master_id = m.id
  INNER JOIN ipa_assignments ipa
  ON m.id = ipa.master_id
  -- INNER JOIN activity_log_ipa_assignments al
  -- ON m.id = al.master_id AND al.extra_log_type = 'primary'
  WHERE
    pi.id IS NULL
   AND ipa.ipa_id is not null
   ;
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
-- Name: get_app_type_id_by_name(character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.get_app_type_id_by_name(app_type_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  DECLARE
    app_type_id INTEGER;
  BEGIN

    select id from app_types
    into app_type_id
    where name = app_type_name and (disabled is null or disabled = false)
    order by id asc
    limit 1;

    RETURN app_type_id;

  END;
$$;


--
-- Name: get_user_ids_for_app_type_role(integer, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.get_user_ids_for_app_type_role(for_app_type_id integer, with_role_name character varying) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$
  DECLARE
    user_ids INTEGER[];
  BEGIN

    select array_agg(ur.user_id)
    from user_roles ur
    inner join users u on ur.user_id = u.id
    into user_ids
    where
      role_name = with_role_name AND
      ur.app_type_id = for_app_type_id AND
      (ur.disabled is null or ur.disabled = false) AND
      (ur.disabled is null or u.disabled = false)
    ;

    RETURN user_ids;

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
-- Name: lock_transfer_records(character varying, character varying, integer[]); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.lock_transfer_records(from_db character varying, to_db character varying, master_ids integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
 INSERT into sync_statuses
( from_master_id, from_db, to_db, select_status, created_at, updated_at )
(
  SELECT unnest(master_ids), from_db, to_db, 'new', now(), now()
 );

 RETURN 1;

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
-- Name: log_activity_log_bhs_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_bhs_assignment_update() RETURNS trigger
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
                      pi_return_call_notes,
                      completed_q1_no_yes,
                      completed_teamstudy_no_yes,
                      previous_contact_with_team_no_yes,
                      previous_contact_with_team_notes,
                      notes,
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
                      NEW.pi_return_call_notes,
                      NEW.completed_q1_no_yes,
                      NEW.completed_teamstudy_no_yes,
                      NEW.previous_contact_with_team_no_yes,
                      NEW.previous_contact_with_team_notes,
                      NEW.notes,
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
-- Name: log_activity_log_ext_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_ext_assignment_update() RETURNS trigger
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
-- Name: log_activity_log_ipa_assignment_adverse_event_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_ipa_assignment_adverse_event_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_adverse_event_history
                  (
                      master_id,
                      ipa_assignment_id,
                      
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_adverse_event_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      
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
-- Name: log_activity_log_ipa_assignment_inex_checklist_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_ipa_assignment_inex_checklist_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_inex_checklist_history
                  (
                      master_id,
                      ipa_assignment_id,
                      signed_no_yes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_inex_checklist_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.signed_no_yes,
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
-- Name: log_activity_log_ipa_assignment_minor_deviation_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_ipa_assignment_minor_deviation_update() RETURNS trigger
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
-- Name: log_activity_log_ipa_assignment_navigation_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_ipa_assignment_navigation_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO activity_log_ipa_assignment_navigation_history
            (
                master_id,
                ipa_assignment_id,
                event_date,
                select_station,
                arrival_time,
                start_time,
                event_notes,
                completion_time,
                participant_feedback_notes,
                other_navigator_notes,
                add_protocol_deviation_record_no_yes,
                add_adverse_event_record_no_yes,
                select_event_type,
                other_event_type,
                select_status,
                extra_log_type,
                user_id,
                created_at,
                updated_at,
                activity_log_ipa_assignment_navigation_id
                )
            SELECT
                NEW.master_id,
                NEW.ipa_assignment_id,
                NEW.event_date,
                NEW.select_station,
                NEW.arrival_time,
                NEW.start_time,
                NEW.event_notes,
                NEW.completion_time,
                NEW.participant_feedback_notes,
                NEW.other_navigator_notes,
                NEW.add_protocol_deviation_record_no_yes,
                NEW.add_adverse_event_record_no_yes,
                NEW.select_event_type,
                NEW.other_event_type,
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
-- Name: log_activity_log_ipa_assignment_phone_screen_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_ipa_assignment_phone_screen_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_phone_screen_history
                  (
                      master_id,
                      ipa_assignment_id,
                      callback_date,
                      callback_time,
                      notes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_phone_screen_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.callback_date,
                      NEW.callback_time,
                      NEW.notes,
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
-- Name: log_activity_log_ipa_assignment_protocol_deviation_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_ipa_assignment_protocol_deviation_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_protocol_deviation_history
                  (
                      master_id,
                      ipa_assignment_id,
                      
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_protocol_deviation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      
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
-- Name: log_activity_log_ipa_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_ipa_assignment_update() RETURNS trigger
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
                      follow_up_time,
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
                      NEW.follow_up_time,
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
-- Name: log_activity_log_ipa_screening_phone_screen_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_ipa_screening_phone_screen_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_screening_phone_screen_history
                  (
                      master_id,
                      ipa_assignment_id,
                      age,
                      played_in_nfl_blank_yes_no,
                      played_before_nfl_blank_yes_no,
                      football_experience,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_screening_phone_screen_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.age,
                      NEW.played_in_nfl_blank_yes_no,
                      NEW.played_before_nfl_blank_yes_no,
                      NEW.football_experience,
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
-- Name: log_activity_log_ipa_survey_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_ipa_survey_update() RETURNS trigger
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
-- Name: log_activity_log_new_test_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_new_test_update() RETURNS trigger
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
-- Name: log_activity_log_player_info_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_activity_log_player_info_update() RETURNS trigger
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
-- Name: log_bhs_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_bhs_assignment_update() RETURNS trigger
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
-- Name: log_dynamic_model_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_dynamic_model_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_ext_assignment_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_ext_gen_assignment_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_external_identifier_update() RETURNS trigger
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
-- Name: log_ipa_adl_informant_screener_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_adl_informant_screener_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_adl_informant_screener_history
                  (
                      master_id,
                      select_regarding_eating,
                      select_regarding_walking,
                      select_regarding_bowel_and_bladder,
                      select_regarding_bathing,
                      select_regarding_grooming,
                      select_regarding_dressing,
                      select_regarding_dressing_performance,
                      select_regarding_getting_dressed,
                      used_telephone_yes_no_dont_know,
                      select_telephone_performance,
                      watched_tv_yes_no_dont_know,
                      selected_programs_yes_no_dont_know,
                      talk_about_content_during_yes_no_dont_know,
                      talk_about_content_after_yes_no_dont_know,
                      pay_attention_to_conversation_yes_no_dont_know,
                      select_degree_of_participation,
                      clear_dishes_yes_no_dont_know,
                      select_clear_dishes_performance,
                      find_personal_belongings_yes_no_dont_know,
                      select_find_personal_belongings_performance,
                      obtain_beverage_yes_no_dont_know,
                      select_obtain_beverage_performance,
                      make_meal_yes_no_dont_know,
                      select_make_meal_performance,
                      dispose_of_garbage_yes_no_dont_know,
                      select_dispose_of_garbage_performance,
                      get_around_outside_yes_no_dont_know,
                      select_get_around_outside_performance,
                      go_shopping_yes_no_dont_know,
                      select_go_shopping_performance,
                      pay_for_items_yes_no_dont_know,
                      keep_appointments_yes_no_dont_know,
                      select_keep_appointments_performance,
                      left_on_own_yes_no_dont_know,
                      away_from_home_yes_no_dont_know,
                      at_home_more_than_hour_yes_no_dont_know,
                      at_home_less_than_hour_yes_no_dont_know,
                      talk_about_current_events_yes_no_dont_know,
                      did_not_take_part_in_yes_no_dont_know,
                      took_part_in_outside_home_yes_no_dont_know,
                      took_part_in_at_home_yes_no_dont_know,
                      read_yes_no_dont_know,
                      talk_about_reading_shortly_after_yes_no_dont_know,
                      talk_about_reading_later_yes_no_dont_know,
                      write_yes_no_dont_know,
                      select_write_performance,
                      pastime_yes_no_dont_know,
                      multi_select_pastimes,
                      pastime_other,
                      pastimes_only_at_daycare_no_yes,
                      select_pastimes_only_at_daycare_performance,
                      use_household_appliance_yes_no_dont_know,
                      multi_select_household_appliances,
                      household_appliance_other,
                      select_household_appliance_performance,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_adl_informant_screener_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_regarding_eating,
                      NEW.select_regarding_walking,
                      NEW.select_regarding_bowel_and_bladder,
                      NEW.select_regarding_bathing,
                      NEW.select_regarding_grooming,
                      NEW.select_regarding_dressing,
                      NEW.select_regarding_dressing_performance,
                      NEW.select_regarding_getting_dressed,
                      NEW.used_telephone_yes_no_dont_know,
                      NEW.select_telephone_performance,
                      NEW.watched_tv_yes_no_dont_know,
                      NEW.selected_programs_yes_no_dont_know,
                      NEW.talk_about_content_during_yes_no_dont_know,
                      NEW.talk_about_content_after_yes_no_dont_know,
                      NEW.pay_attention_to_conversation_yes_no_dont_know,
                      NEW.select_degree_of_participation,
                      NEW.clear_dishes_yes_no_dont_know,
                      NEW.select_clear_dishes_performance,
                      NEW.find_personal_belongings_yes_no_dont_know,
                      NEW.select_find_personal_belongings_performance,
                      NEW.obtain_beverage_yes_no_dont_know,
                      NEW.select_obtain_beverage_performance,
                      NEW.make_meal_yes_no_dont_know,
                      NEW.select_make_meal_performance,
                      NEW.dispose_of_garbage_yes_no_dont_know,
                      NEW.select_dispose_of_garbage_performance,
                      NEW.get_around_outside_yes_no_dont_know,
                      NEW.select_get_around_outside_performance,
                      NEW.go_shopping_yes_no_dont_know,
                      NEW.select_go_shopping_performance,
                      NEW.pay_for_items_yes_no_dont_know,
                      NEW.keep_appointments_yes_no_dont_know,
                      NEW.select_keep_appointments_performance,
                      NEW.left_on_own_yes_no_dont_know,
                      NEW.away_from_home_yes_no_dont_know,
                      NEW.at_home_more_than_hour_yes_no_dont_know,
                      NEW.at_home_less_than_hour_yes_no_dont_know,
                      NEW.talk_about_current_events_yes_no_dont_know,
                      NEW.did_not_take_part_in_yes_no_dont_know,
                      NEW.took_part_in_outside_home_yes_no_dont_know,
                      NEW.took_part_in_at_home_yes_no_dont_know,
                      NEW.read_yes_no_dont_know,
                      NEW.talk_about_reading_shortly_after_yes_no_dont_know,
                      NEW.talk_about_reading_later_yes_no_dont_know,
                      NEW.write_yes_no_dont_know,
                      NEW.select_write_performance,
                      NEW.pastime_yes_no_dont_know,
                      NEW.multi_select_pastimes,
                      NEW.pastime_other,
                      NEW.pastimes_only_at_daycare_no_yes,
                      NEW.select_pastimes_only_at_daycare_performance,
                      NEW.use_household_appliance_yes_no_dont_know,
                      NEW.multi_select_household_appliances,
                      NEW.household_appliance_other,
                      NEW.select_household_appliance_performance,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_adverse_event_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_adverse_event_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_adverse_event_history
                  (
                      master_id,
                      select_problem_type,
                      event_occurred_when,
                      event_discovered_when,
                      select_severity,
                      select_location,
                      select_expectedness,
                      select_relatedness,
                      event_description,
                      corrective_action_description,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_adverse_event_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_problem_type,
                      NEW.event_occurred_when,
                      NEW.event_discovered_when,
                      NEW.select_severity,
                      NEW.select_location,
                      NEW.select_expectedness,
                      NEW.select_relatedness,
                      NEW.event_description,
                      NEW.corrective_action_description,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_appointment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_appointment_update() RETURNS trigger
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
-- Name: log_ipa_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_assignment_update() RETURNS trigger
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
-- Name: log_ipa_consent_mailing_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_consent_mailing_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_consent_mailing_history
                  (
                      master_id,
                      select_record_from_player_contact_email,
                      select_record_from_addresses,
                      sent_when,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_consent_mailing_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_record_from_player_contact_email,
                      NEW.select_record_from_addresses,
                      NEW.sent_when,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_hotel_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_hotel_update() RETURNS trigger
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
-- Name: log_ipa_inex_checklist_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_inex_checklist_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_inex_checklist_history
                  (
                      master_id,
                      fixed_checklist_type,
                      ix_consent_blank_yes_no,
                      ix_consent_details,
                      ix_not_pro_blank_yes_no,
                      ix_not_pro_details,
                      ix_age_range_blank_yes_no,
                      ix_age_range_details,
                      ix_weight_ok_blank_yes_no,
                      ix_weight_ok_details,
                      ix_no_seizure_blank_yes_no,
                      ix_no_seizure_details,
                      ix_no_device_impl_blank_yes_no,
                      ix_no_device_impl_details,
                      ix_no_ferromagnetic_impl_blank_yes_no,
                      ix_no_ferromagnetic_impl_details,
                      ix_diagnosed_sleep_apnea_blank_yes_no,
                      ix_diagnosed_sleep_apnea_details,
                      ix_diagnosed_heart_stroke_or_meds_blank_yes_no,
                      ix_diagnosed_heart_stroke_or_meds_details,
                      ix_chronic_pain_and_meds_blank_yes_no,
                      ix_chronic_pain_and_meds_details,
                      ix_tmoca_score_blank_yes_no,
                      ix_tmoca_score_details,
                      ix_no_hemophilia_blank_yes_no,
                      ix_no_hemophilia_details,
                      ix_raynauds_ok_blank_yes_no,
                      ix_raynauds_ok_details,
                      ix_mi_ok_blank_yes_no,
                      ix_mi_ok_details,
                      ix_bicycle_ok_blank_yes_no,
                      ix_bicycle_ok_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_inex_checklist_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.fixed_checklist_type,
                      NEW.ix_consent_blank_yes_no,
                      NEW.ix_consent_details,
                      NEW.ix_not_pro_blank_yes_no,
                      NEW.ix_not_pro_details,
                      NEW.ix_age_range_blank_yes_no,
                      NEW.ix_age_range_details,
                      NEW.ix_weight_ok_blank_yes_no,
                      NEW.ix_weight_ok_details,
                      NEW.ix_no_seizure_blank_yes_no,
                      NEW.ix_no_seizure_details,
                      NEW.ix_no_device_impl_blank_yes_no,
                      NEW.ix_no_device_impl_details,
                      NEW.ix_no_ferromagnetic_impl_blank_yes_no,
                      NEW.ix_no_ferromagnetic_impl_details,
                      NEW.ix_diagnosed_sleep_apnea_blank_yes_no,
                      NEW.ix_diagnosed_sleep_apnea_details,
                      NEW.ix_diagnosed_heart_stroke_or_meds_blank_yes_no,
                      NEW.ix_diagnosed_heart_stroke_or_meds_details,
                      NEW.ix_chronic_pain_and_meds_blank_yes_no,
                      NEW.ix_chronic_pain_and_meds_details,
                      NEW.ix_tmoca_score_blank_yes_no,
                      NEW.ix_tmoca_score_details,
                      NEW.ix_no_hemophilia_blank_yes_no,
                      NEW.ix_no_hemophilia_details,
                      NEW.ix_raynauds_ok_blank_yes_no,
                      NEW.ix_raynauds_ok_details,
                      NEW.ix_mi_ok_blank_yes_no,
                      NEW.ix_mi_ok_details,
                      NEW.ix_bicycle_ok_blank_yes_no,
                      NEW.ix_bicycle_ok_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_initial_screening_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_initial_screening_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_initial_screening_history
                  (
                      master_id,
                      select_is_good_time_to_speak,
                      select_may_i_begin,
                      any_questions_blank_yes_no,
                      select_still_interested,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_initial_screening_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_is_good_time_to_speak,
                      NEW.select_may_i_begin,
                      NEW.any_questions_blank_yes_no,
                      NEW.select_still_interested,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_payment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_payment_update() RETURNS trigger
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
-- Name: log_ipa_protocol_deviation_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_protocol_deviation_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_protocol_deviation_history
                  (
                      master_id,
                      deviation_occurred_when,
                      deviation_discovered_when,
                      select_severity,
                      deviation_description,
                      corrective_action_description,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_protocol_deviation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.deviation_occurred_when,
                      NEW.deviation_discovered_when,
                      NEW.select_severity,
                      NEW.deviation_description,
                      NEW.corrective_action_description,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_ps_football_experience_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_ps_football_experience_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_football_experience_history
                  (
                      master_id,
                      age,
                      played_in_nfl_blank_yes_no,
                      played_before_nfl_blank_yes_no,
                      football_experience_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_football_experience_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.age,
                      NEW.played_in_nfl_blank_yes_no,
                      NEW.played_before_nfl_blank_yes_no,
                      NEW.football_experience_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_ps_health_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_ps_health_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_health_history
                  (
                      master_id,
                      physical_limitations_blank_yes_no,
                      physical_limitations_details,
                      sit_back_blank_yes_no,
                      sit_back_details,
                      cycle_blank_yes_no,
                      cycle_details,
                      chronic_pain_blank_yes_no,
                      chronic_pain_details,
                      chronic_pain_meds_blank_yes_no_dont_know,
                      chronic_pain_meds_details,
                      hemophilia_blank_yes_no_dont_know,
                      hemophilia_details,
                      raynauds_syndrome_blank_yes_no_dont_know,
                      raynauds_syndrome_severity_selection,
                      raynauds_syndrome_details,
                      other_conditions_blank_yes_no_dont_know,
                      other_conditions_details,
                      hypertension_diagnosis_blank_yes_no_dont_know,
                      hypertension_diagnosis_details,
                      other_heart_conditions_blank_yes_no_dont_know,
                      other_heart_conditions_details,
                      memory_problems_blank_yes_no_dont_know,
                      memory_problems_details,
                      mental_health_conditions_blank_yes_no_dont_know,
                      mental_health_conditions_details,
                      neurological_problems_blank_yes_no_dont_know,
                      neurological_problems_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_health_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.physical_limitations_blank_yes_no,
                      NEW.physical_limitations_details,
                      NEW.sit_back_blank_yes_no,
                      NEW.sit_back_details,
                      NEW.cycle_blank_yes_no,
                      NEW.cycle_details,
                      NEW.chronic_pain_blank_yes_no,
                      NEW.chronic_pain_details,
                      NEW.chronic_pain_meds_blank_yes_no_dont_know,
                      NEW.chronic_pain_meds_details,
                      NEW.hemophilia_blank_yes_no_dont_know,
                      NEW.hemophilia_details,
                      NEW.raynauds_syndrome_blank_yes_no_dont_know,
                      NEW.raynauds_syndrome_severity_selection,
                      NEW.raynauds_syndrome_details,
                      NEW.other_conditions_blank_yes_no_dont_know,
                      NEW.other_conditions_details,
                      NEW.hypertension_diagnosis_blank_yes_no_dont_know,
                      NEW.hypertension_diagnosis_details,
                      NEW.other_heart_conditions_blank_yes_no_dont_know,
                      NEW.other_heart_conditions_details,
                      NEW.memory_problems_blank_yes_no_dont_know,
                      NEW.memory_problems_details,
                      NEW.mental_health_conditions_blank_yes_no_dont_know,
                      NEW.mental_health_conditions_details,
                      NEW.neurological_problems_blank_yes_no_dont_know,
                      NEW.neurological_problems_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_ps_initial_screening_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_ps_initial_screening_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_initial_screening_history
                  (
                      master_id,
                      select_is_good_time_to_speak,
                      select_may_i_begin,
                      any_questions_blank_yes_no,
                      select_still_interested,
                      follow_up_date,
                      follow_up_time,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_initial_screening_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_is_good_time_to_speak,
                      NEW.select_may_i_begin,
                      NEW.any_questions_blank_yes_no,
                      NEW.select_still_interested,
                      NEW.follow_up_date,
                      NEW.follow_up_time,
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
-- Name: log_ipa_ps_mri_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_ps_mri_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_mri_history
                  (
                      master_id,
                      electrical_implants_blank_yes_no_dont_know,
                      electrical_implants_details,
                      metal_implants_blank_yes_no_dont_know,
                      metal_implants_details,
                      metal_jewelry_blank_yes_no,
                      hearing_aid_blank_yes_no,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_mri_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.electrical_implants_blank_yes_no_dont_know,
                      NEW.electrical_implants_details,
                      NEW.metal_implants_blank_yes_no_dont_know,
                      NEW.metal_implants_details,
                      NEW.metal_jewelry_blank_yes_no,
                      NEW.hearing_aid_blank_yes_no,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_ps_size_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_ps_size_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_size_history
                  (
                      master_id,
                      weight,
                      height,
                      hat_size,
                      shirt_size,
                      jacket_size,
                      waist_size,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_size_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.weight,
                      NEW.height,
                      NEW.hat_size,
                      NEW.shirt_size,
                      NEW.jacket_size,
                      NEW.waist_size,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_ps_sleep_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_ps_sleep_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_sleep_history
                  (
                      master_id,
                      sleep_disorder_blank_yes_no_dont_know,
                      sleep_disorder_details,
                      sleep_apnea_device_no_yes,
                      sleep_apnea_device_details,
                      bed_and_wake_time_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_sleep_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.sleep_disorder_blank_yes_no_dont_know,
                      NEW.sleep_disorder_details,
                      NEW.sleep_apnea_device_no_yes,
                      NEW.sleep_apnea_device_details,
                      NEW.bed_and_wake_time_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_ps_tmoca_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_ps_tmoca_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_tmoca_history
                  (
                      master_id,
                      tmoca_score,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_tmoca_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.tmoca_score,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_ps_tms_test_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_ps_tms_test_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_tms_test_history
                  (
                      master_id,
                      convulsion_or_seizue_blank_yes_no_dont_know,
                      epilepsy_blank_yes_no_dont_know,
                      fainting_blank_yes_no_dont_know,
                      concussion_blank_yes_no_dont_know,
                      hearing_problems_blank_yes_no_dont_know,
                      cochlear_implants_blank_yes_no_dont_know,
                      metal_blank_yes_no_dont_know,
                      metal_details,
                      neurostimulator_blank_yes_no_dont_know,
                      neurostimulator_details,
                      pacemaker_blank_yes_no_dont_know,
                      med_infusion_device_blank_yes_no_dont_know,
                      past_tms_blank_yes_no_dont_know,
                      past_tms_details,
                      past_mri_blank_yes_no_dont_know,
                      past_mri_details,
                      current_meds_blank_yes_no_dont_know,
                      current_meds_details,
                      neuro_history_details,
                      other_chronic_problems_blank_yes_no_dont_know,
                      other_chronic_problems_details,
                      hospital_visits_blank_yes_no_dont_know,
                      hospital_visits_details,
                      dietary_restrictions_blank_yes_no_dont_know,
                      dietary_restrictions_details,
                      anything_else_blank_yes_no,
                      anything_else_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_tms_test_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.convulsion_or_seizue_blank_yes_no_dont_know,
                      NEW.epilepsy_blank_yes_no_dont_know,
                      NEW.fainting_blank_yes_no_dont_know,
                      NEW.concussion_blank_yes_no_dont_know,
                      NEW.hearing_problems_blank_yes_no_dont_know,
                      NEW.cochlear_implants_blank_yes_no_dont_know,
                      NEW.metal_blank_yes_no_dont_know,
                      NEW.metal_details,
                      NEW.neurostimulator_blank_yes_no_dont_know,
                      NEW.neurostimulator_details,
                      NEW.pacemaker_blank_yes_no_dont_know,
                      NEW.med_infusion_device_blank_yes_no_dont_know,
                      NEW.past_tms_blank_yes_no_dont_know,
                      NEW.past_tms_details,
                      NEW.past_mri_blank_yes_no_dont_know,
                      NEW.past_mri_details,
                      NEW.current_meds_blank_yes_no_dont_know,
                      NEW.current_meds_details,
                      NEW.neuro_history_details,
                      NEW.other_chronic_problems_blank_yes_no_dont_know,
                      NEW.other_chronic_problems_details,
                      NEW.hospital_visits_blank_yes_no_dont_know,
                      NEW.hospital_visits_details,
                      NEW.dietary_restrictions_blank_yes_no_dont_know,
                      NEW.dietary_restrictions_details,
                      NEW.anything_else_blank_yes_no,
                      NEW.anything_else_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_recruitment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_recruitment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_recruitment_history
                  (
                      master_id,
                      rank,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_recruitment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.rank,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_screening_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_screening_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
              INSERT INTO ipa_screening_history
              (
                  master_id,
                  eligible_for_study_blank_yes_no,
                  good_time_to_speak_blank_yes_no,
                  callback_date,
                  callback_time,
                  still_interested_blank_yes_no,
                  ineligible_notes,
                  eligible_notes,
                  not_interested_notes,
                  notes,
                  user_id,
                  created_at,
                  updated_at,
                  ipa_screening_id
                  )
              SELECT
                  NEW.master_id,
                  NEW.eligible_for_study_blank_yes_no,
                  NEW.good_time_to_speak_blank_yes_no,
                  NEW.callback_date,
                  NEW.callback_time,
                  NEW.still_interested_blank_yes_no,
                  NEW.ineligible_notes,
                  NEW.eligible_notes,
                  NEW.not_interested_notes,
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
-- Name: log_ipa_station_contact_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_station_contact_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_station_contact_history
                  (
                      master_id,
                      first_name,
                      last_name,
                      role,
                      select_availability,
                      phone,
                      alt_phone,
                      email,
                      alt_email,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_station_contact_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.first_name,
                      NEW.last_name,
                      NEW.role,
                      NEW.phone,
                      NEW.select_availability,
                      NEW.alt_phone,
                      NEW.email,
                      NEW.alt_email,
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
-- Name: log_ipa_survey_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_survey_update() RETURNS trigger
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
-- Name: log_ipa_transportation_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_transportation_update() RETURNS trigger
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
-- Name: log_ipa_withdrawal_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_ipa_withdrawal_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO ipa_withdrawal_history
            (
                master_id,
                select_subject_withdrew_reason,
                select_investigator_terminated,
                lost_to_follow_up_no_yes,
                no_longer_participating_no_yes,
                notes,
                user_id,
                created_at,
                updated_at,
                ipa_withdrawal_id
                )
            SELECT
                NEW.master_id,
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
-- Name: log_json_doc_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_json_doc_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO json_doc_history
                  (
                      master_id,
                      responses,
                      user_id,
                      created_at,
                      updated_at,
                      json_doc_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.responses,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_mrn_number_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_mrn_number_update() RETURNS trigger
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
-- Name: log_new_test_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_new_test_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_sage_two_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_scantron_series_two_update() RETURNS trigger
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
-- Name: log_social_security_number_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_social_security_number_update() RETURNS trigger
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
-- Name: log_test1_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_test1_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_test2_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_test_2_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_test_ext2_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_test_ext_update() RETURNS trigger
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

CREATE FUNCTION ml_app.log_test_item_update() RETURNS trigger
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
-- Name: log_testing_dl_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.log_testing_dl_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO testing_dl_history
                  (
                      master_id,
                      name,
                      select_yes_no,
                      select_record_from_table_dl_addresses,
                      user_id,
                      created_at,
                      updated_at,
                      testing_dl_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.name,
                      NEW.select_yes_no,
                      NEW.select_record_from_table_dl_addresses,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
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
-- Name: activity_log_ipa_assignment_adverse_event_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_adverse_event_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_adverse_event_id integer
);


--
-- Name: activity_log_ipa_assignment_adverse_event_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_adverse_event_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_adverse_event_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_adverse_event_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_adverse_event_history.id;


--
-- Name: activity_log_ipa_assignment_adverse_events; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_adverse_events (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_assignment_adverse_events_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_adverse_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_adverse_events_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_adverse_events_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_adverse_events.id;


--
-- Name: activity_log_ipa_assignment_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_history (
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
    activity_log_ipa_assignment_id integer,
    follow_up_time time without time zone
);


--
-- Name: activity_log_ipa_assignment_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_history.id;


--
-- Name: activity_log_ipa_assignment_inex_checklist_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_inex_checklist_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    signed_no_yes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_inex_checklist_id integer,
    ready_for_review_no_yes character varying
);


--
-- Name: activity_log_ipa_assignment_inex_checklist_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_inex_checklist_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_inex_checklist_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_inex_checklist_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_inex_checklist_history.id;


--
-- Name: activity_log_ipa_assignment_inex_checklists; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_inex_checklists (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    signed_no_yes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ready_for_review_no_yes character varying
);


--
-- Name: activity_log_ipa_assignment_inex_checklists_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_inex_checklists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_inex_checklists_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_inex_checklists_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_inex_checklists.id;


--
-- Name: activity_log_ipa_assignment_minor_deviation_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_minor_deviation_history (
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
-- Name: activity_log_ipa_assignment_minor_deviation_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_minor_deviation_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_minor_deviation_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_minor_deviation_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_minor_deviation_history.id;


--
-- Name: activity_log_ipa_assignment_minor_deviations; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_minor_deviations (
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
-- Name: activity_log_ipa_assignment_minor_deviations_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_minor_deviations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_minor_deviations_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_minor_deviations_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_minor_deviations.id;


--
-- Name: activity_log_ipa_assignment_navigation_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_navigation_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    event_date date,
    select_station character varying,
    arrival_time time without time zone,
    start_time time without time zone,
    event_notes character varying,
    completion_time time without time zone,
    participant_feedback_notes character varying,
    other_navigator_notes character varying,
    add_protocol_deviation_record_no_yes character varying,
    add_adverse_event_record_no_yes character varying,
    select_event_type character varying,
    other_event_type character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_navigation_id integer,
    select_status character varying
);


--
-- Name: activity_log_ipa_assignment_navigation_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_navigation_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_navigation_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_navigation_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_navigation_history.id;


--
-- Name: activity_log_ipa_assignment_navigations; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_navigations (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    event_date date,
    select_station character varying,
    arrival_time time without time zone,
    start_time time without time zone,
    event_notes character varying,
    completion_time time without time zone,
    participant_feedback_notes character varying,
    other_navigator_notes character varying,
    add_protocol_deviation_record_no_yes character varying,
    add_adverse_event_record_no_yes character varying,
    select_event_type character varying,
    other_event_type character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    select_status character varying
);


--
-- Name: activity_log_ipa_assignment_navigations_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_navigations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_navigations_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_navigations_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_navigations.id;


--
-- Name: activity_log_ipa_assignment_phone_screen_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_phone_screen_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    callback_date date,
    callback_time time without time zone,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_phone_screen_id integer
);


--
-- Name: activity_log_ipa_assignment_phone_screen_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_phone_screen_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_phone_screen_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_phone_screen_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_phone_screen_history.id;


--
-- Name: activity_log_ipa_assignment_phone_screens; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_phone_screens (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    callback_date date,
    callback_time time without time zone,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_assignment_phone_screens_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_phone_screens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_phone_screens_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_phone_screens_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_phone_screens.id;


--
-- Name: activity_log_ipa_assignment_protocol_deviation_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_protocol_deviation_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_protocol_deviation_id integer
);


--
-- Name: activity_log_ipa_assignment_protocol_deviation_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_protocol_deviation_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_protocol_deviation_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_protocol_deviation_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_protocol_deviation_history.id;


--
-- Name: activity_log_ipa_assignment_protocol_deviations; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_protocol_deviations (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_assignment_protocol_deviations_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_protocol_deviations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_protocol_deviations_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_protocol_deviations_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_protocol_deviations.id;


--
-- Name: activity_log_ipa_assignment_session_filestore_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_session_filestore_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    select_scanner character varying,
    operator character varying,
    notes character varying,
    session_date date,
    session_time time without time zone,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_session_filestore_id integer
);


--
-- Name: activity_log_ipa_assignment_session_filestore_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_session_filestore_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_session_filestore_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_session_filestore_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_session_filestore_history.id;


--
-- Name: activity_log_ipa_assignment_session_filestores; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_session_filestores (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    select_scanner character varying,
    operator character varying,
    notes character varying,
    session_date date,
    session_time time without time zone,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_assignment_session_filestores_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_session_filestores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_session_filestores_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_session_filestores_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_session_filestores.id;


--
-- Name: activity_log_ipa_assignments; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignments (
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
    follow_up_time time without time zone
);


--
-- Name: activity_log_ipa_assignments_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignments_id_seq OWNED BY ipa_ops.activity_log_ipa_assignments.id;


--
-- Name: activity_log_ipa_screening_phone_screen_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_screening_phone_screen_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    age character varying,
    played_in_nfl_blank_yes_no character varying,
    played_before_nfl_blank_yes_no character varying,
    football_experience character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_screening_phone_screen_id integer
);


--
-- Name: activity_log_ipa_screening_phone_screen_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_screening_phone_screen_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_screening_phone_screen_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_screening_phone_screen_history_id_seq OWNED BY ipa_ops.activity_log_ipa_screening_phone_screen_history.id;


--
-- Name: activity_log_ipa_screening_phone_screens; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_screening_phone_screens (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    age character varying,
    played_in_nfl_blank_yes_no character varying,
    played_before_nfl_blank_yes_no character varying,
    football_experience character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_screening_phone_screens_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_screening_phone_screens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_screening_phone_screens_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_screening_phone_screens_id_seq OWNED BY ipa_ops.activity_log_ipa_screening_phone_screens.id;


--
-- Name: activity_log_ipa_survey_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_survey_history (
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
-- Name: activity_log_ipa_survey_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_survey_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_survey_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_survey_history_id_seq OWNED BY ipa_ops.activity_log_ipa_survey_history.id;


--
-- Name: activity_log_ipa_surveys; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_surveys (
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
-- Name: activity_log_ipa_surveys_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_surveys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_surveys_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_surveys_id_seq OWNED BY ipa_ops.activity_log_ipa_surveys.id;


--
-- Name: emergency_contacts; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.emergency_contacts (
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
-- Name: emergency_contacts_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.emergency_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emergency_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.emergency_contacts_id_seq OWNED BY ipa_ops.emergency_contacts.id;


--
-- Name: ipa_adl_informant_screener_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_adl_informant_screener_history (
    id integer NOT NULL,
    master_id integer,
    select_regarding_eating character varying,
    select_regarding_walking character varying,
    select_regarding_bowel_and_bladder character varying,
    select_regarding_bathing character varying,
    select_regarding_grooming character varying,
    select_regarding_dressing character varying,
    select_regarding_dressing_performance character varying,
    select_regarding_getting_dressed character varying,
    used_telephone_yes_no_dont_know character varying,
    select_telephone_performance character varying,
    watched_tv_yes_no_dont_know character varying,
    selected_programs_yes_no_dont_know character varying,
    talk_about_content_during_yes_no_dont_know character varying,
    talk_about_content_after_yes_no_dont_know character varying,
    pay_attention_to_conversation_yes_no_dont_know character varying,
    select_degree_of_participation character varying,
    clear_dishes_yes_no_dont_know character varying,
    select_clear_dishes_performance character varying,
    find_personal_belongings_yes_no_dont_know character varying,
    select_find_personal_belongings_performance character varying,
    obtain_beverage_yes_no_dont_know character varying,
    select_obtain_beverage_performance character varying,
    make_meal_yes_no_dont_know character varying,
    select_make_meal_performance character varying,
    dispose_of_garbage_yes_no_dont_know character varying,
    select_dispose_of_garbage_performance character varying,
    get_around_outside_yes_no_dont_know character varying,
    select_get_around_outside_performance character varying,
    go_shopping_yes_no_dont_know character varying,
    select_go_shopping_performance character varying,
    pay_for_items_yes_no_dont_know character varying,
    keep_appointments_yes_no_dont_know character varying,
    select_keep_appointments_performance character varying,
    left_on_own_yes_no_dont_know character varying,
    away_from_home_yes_no_dont_know character varying,
    at_home_more_than_hour_yes_no_dont_know character varying,
    at_home_less_than_hour_yes_no_dont_know character varying,
    talk_about_current_events_yes_no_dont_know character varying,
    did_not_take_part_in_yes_no_dont_know character varying,
    took_part_in_outside_home_yes_no_dont_know character varying,
    took_part_in_at_home_yes_no_dont_know character varying,
    read_yes_no_dont_know character varying,
    talk_about_reading_shortly_after_yes_no_dont_know character varying,
    talk_about_reading_later_yes_no_dont_know character varying,
    write_yes_no_dont_know character varying,
    select_write_performance character varying,
    pastime_yes_no_dont_know character varying,
    multi_select_pastimes character varying,
    pastime_other character varying,
    pastimes_only_at_daycare_no_yes character varying,
    select_pastimes_only_at_daycare_performance character varying,
    use_household_appliance_yes_no_dont_know character varying,
    multi_select_household_appliances character varying,
    household_appliance_other character varying,
    select_household_appliance_performance character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_adl_informant_screener_id integer
);


--
-- Name: ipa_adl_informant_screener_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_adl_informant_screener_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_adl_informant_screener_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_adl_informant_screener_history_id_seq OWNED BY ipa_ops.ipa_adl_informant_screener_history.id;


--
-- Name: ipa_adl_informant_screeners; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_adl_informant_screeners (
    id integer NOT NULL,
    master_id integer,
    select_regarding_eating character varying,
    select_regarding_walking character varying,
    select_regarding_bowel_and_bladder character varying,
    select_regarding_bathing character varying,
    select_regarding_grooming character varying,
    select_regarding_dressing character varying,
    select_regarding_dressing_performance character varying,
    select_regarding_getting_dressed character varying,
    used_telephone_yes_no_dont_know character varying,
    select_telephone_performance character varying,
    watched_tv_yes_no_dont_know character varying,
    selected_programs_yes_no_dont_know character varying,
    talk_about_content_during_yes_no_dont_know character varying,
    talk_about_content_after_yes_no_dont_know character varying,
    pay_attention_to_conversation_yes_no_dont_know character varying,
    select_degree_of_participation character varying,
    clear_dishes_yes_no_dont_know character varying,
    select_clear_dishes_performance character varying,
    find_personal_belongings_yes_no_dont_know character varying,
    select_find_personal_belongings_performance character varying,
    obtain_beverage_yes_no_dont_know character varying,
    select_obtain_beverage_performance character varying,
    make_meal_yes_no_dont_know character varying,
    select_make_meal_performance character varying,
    dispose_of_garbage_yes_no_dont_know character varying,
    select_dispose_of_garbage_performance character varying,
    get_around_outside_yes_no_dont_know character varying,
    select_get_around_outside_performance character varying,
    go_shopping_yes_no_dont_know character varying,
    select_go_shopping_performance character varying,
    pay_for_items_yes_no_dont_know character varying,
    keep_appointments_yes_no_dont_know character varying,
    select_keep_appointments_performance character varying,
    left_on_own_yes_no_dont_know character varying,
    away_from_home_yes_no_dont_know character varying,
    at_home_more_than_hour_yes_no_dont_know character varying,
    at_home_less_than_hour_yes_no_dont_know character varying,
    talk_about_current_events_yes_no_dont_know character varying,
    did_not_take_part_in_yes_no_dont_know character varying,
    took_part_in_outside_home_yes_no_dont_know character varying,
    took_part_in_at_home_yes_no_dont_know character varying,
    read_yes_no_dont_know character varying,
    talk_about_reading_shortly_after_yes_no_dont_know character varying,
    talk_about_reading_later_yes_no_dont_know character varying,
    write_yes_no_dont_know character varying,
    select_write_performance character varying,
    pastime_yes_no_dont_know character varying,
    multi_select_pastimes character varying,
    pastime_other character varying,
    pastimes_only_at_daycare_no_yes character varying,
    select_pastimes_only_at_daycare_performance character varying,
    use_household_appliance_yes_no_dont_know character varying,
    multi_select_household_appliances character varying,
    household_appliance_other character varying,
    select_household_appliance_performance character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_adl_informant_screeners_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_adl_informant_screeners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_adl_informant_screeners_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_adl_informant_screeners_id_seq OWNED BY ipa_ops.ipa_adl_informant_screeners.id;


--
-- Name: ipa_adverse_event_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_adverse_event_history (
    id integer NOT NULL,
    master_id integer,
    select_problem_type character varying,
    event_occurred_when date,
    event_discovered_when date,
    select_severity character varying,
    select_location character varying,
    select_expectedness character varying,
    select_relatedness character varying,
    event_description character varying,
    corrective_action_description character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_adverse_event_id integer
);


--
-- Name: ipa_adverse_event_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_adverse_event_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_adverse_event_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_adverse_event_history_id_seq OWNED BY ipa_ops.ipa_adverse_event_history.id;


--
-- Name: ipa_adverse_events; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_adverse_events (
    id integer NOT NULL,
    master_id integer,
    select_problem_type character varying,
    event_occurred_when date,
    event_discovered_when date,
    select_severity character varying,
    select_location character varying,
    select_expectedness character varying,
    select_relatedness character varying,
    event_description character varying,
    corrective_action_description character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_adverse_events_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_adverse_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_adverse_events_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_adverse_events_id_seq OWNED BY ipa_ops.ipa_adverse_events.id;


--
-- Name: ipa_appointment_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_appointment_history (
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
-- Name: ipa_appointment_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_appointment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_appointment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_appointment_history_id_seq OWNED BY ipa_ops.ipa_appointment_history.id;


--
-- Name: ipa_appointments; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_appointments (
    id integer NOT NULL,
    master_id integer,
    visit_start_date date,
    select_navigator character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_appointments_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_appointments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_appointments_id_seq OWNED BY ipa_ops.ipa_appointments.id;


--
-- Name: ipa_assignment_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_assignment_history (
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
-- Name: ipa_assignment_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_assignment_history_id_seq OWNED BY ipa_ops.ipa_assignment_history.id;


--
-- Name: ipa_consent_mailing_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_consent_mailing_history (
    id integer NOT NULL,
    master_id integer,
    select_record_from_player_contact_email character varying,
    select_record_from_addresses character varying,
    sent_when date,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_consent_mailing_id integer
);


--
-- Name: ipa_consent_mailing_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_consent_mailing_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_consent_mailing_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_consent_mailing_history_id_seq OWNED BY ipa_ops.ipa_consent_mailing_history.id;


--
-- Name: ipa_consent_mailings; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_consent_mailings (
    id integer NOT NULL,
    master_id integer,
    select_record_from_player_contact_email character varying,
    select_record_from_addresses character varying,
    sent_when date,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_consent_mailings_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_consent_mailings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_consent_mailings_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_consent_mailings_id_seq OWNED BY ipa_ops.ipa_consent_mailings.id;


--
-- Name: ipa_hotel_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_hotel_history (
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
-- Name: ipa_hotel_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_hotel_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_hotel_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_hotel_history_id_seq OWNED BY ipa_ops.ipa_hotel_history.id;


--
-- Name: ipa_hotels; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_hotels (
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
-- Name: ipa_hotels_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_hotels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_hotels_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_hotels_id_seq OWNED BY ipa_ops.ipa_hotels.id;


--
-- Name: ipa_inex_checklist_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_inex_checklist_history (
    id integer NOT NULL,
    master_id integer,
    fixed_checklist_type character varying,
    ix_consent_blank_yes_no character varying,
    ix_consent_details character varying,
    ix_not_pro_blank_yes_no character varying,
    ix_not_pro_details character varying,
    ix_age_range_blank_yes_no character varying,
    ix_age_range_details character varying,
    ix_weight_ok_blank_yes_no character varying,
    ix_weight_ok_details character varying,
    ix_no_seizure_blank_yes_no character varying,
    ix_no_seizure_details character varying,
    ix_no_device_impl_blank_yes_no character varying,
    ix_no_device_impl_details character varying,
    ix_no_ferromagnetic_impl_blank_yes_no character varying,
    ix_no_ferromagnetic_impl_details character varying,
    ix_diagnosed_sleep_apnea_blank_yes_no character varying,
    ix_diagnosed_sleep_apnea_details character varying,
    ix_diagnosed_heart_stroke_or_meds_blank_yes_no character varying,
    ix_diagnosed_heart_stroke_or_meds_details character varying,
    ix_chronic_pain_and_meds_blank_yes_no character varying,
    ix_chronic_pain_and_meds_details character varying,
    ix_tmoca_score_blank_yes_no character varying,
    ix_tmoca_score_details character varying,
    ix_no_hemophilia_blank_yes_no character varying,
    ix_no_hemophilia_details character varying,
    ix_raynauds_ok_blank_yes_no character varying,
    ix_raynauds_ok_details character varying,
    ix_mi_ok_blank_yes_no character varying,
    ix_mi_ok_details character varying,
    ix_bicycle_ok_blank_yes_no character varying,
    ix_bicycle_ok_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_inex_checklist_id integer
);


--
-- Name: ipa_inex_checklist_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_inex_checklist_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_inex_checklist_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_inex_checklist_history_id_seq OWNED BY ipa_ops.ipa_inex_checklist_history.id;


--
-- Name: ipa_inex_checklists; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_inex_checklists (
    id integer NOT NULL,
    master_id integer,
    fixed_checklist_type character varying,
    ix_consent_blank_yes_no character varying,
    ix_consent_details character varying,
    ix_not_pro_blank_yes_no character varying,
    ix_not_pro_details character varying,
    ix_age_range_blank_yes_no character varying,
    ix_age_range_details character varying,
    ix_weight_ok_blank_yes_no character varying,
    ix_weight_ok_details character varying,
    ix_no_seizure_blank_yes_no character varying,
    ix_no_seizure_details character varying,
    ix_no_device_impl_blank_yes_no character varying,
    ix_no_device_impl_details character varying,
    ix_no_ferromagnetic_impl_blank_yes_no character varying,
    ix_no_ferromagnetic_impl_details character varying,
    ix_diagnosed_sleep_apnea_blank_yes_no character varying,
    ix_diagnosed_sleep_apnea_details character varying,
    ix_diagnosed_heart_stroke_or_meds_blank_yes_no character varying,
    ix_diagnosed_heart_stroke_or_meds_details character varying,
    ix_chronic_pain_and_meds_blank_yes_no character varying,
    ix_chronic_pain_and_meds_details character varying,
    ix_tmoca_score_blank_yes_no character varying,
    ix_tmoca_score_details character varying,
    ix_no_hemophilia_blank_yes_no character varying,
    ix_no_hemophilia_details character varying,
    ix_raynauds_ok_blank_yes_no character varying,
    ix_raynauds_ok_details character varying,
    ix_mi_ok_blank_yes_no character varying,
    ix_mi_ok_details character varying,
    ix_bicycle_ok_blank_yes_no character varying,
    ix_bicycle_ok_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_inex_checklists_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_inex_checklists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_inex_checklists_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_inex_checklists_id_seq OWNED BY ipa_ops.ipa_inex_checklists.id;


--
-- Name: ipa_initial_screening_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_initial_screening_history (
    id integer NOT NULL,
    master_id integer,
    select_is_good_time_to_speak character varying,
    select_may_i_begin character varying,
    any_questions_blank_yes_no character varying,
    select_still_interested character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_initial_screening_id integer
);


--
-- Name: ipa_initial_screening_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_initial_screening_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_initial_screening_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_initial_screening_history_id_seq OWNED BY ipa_ops.ipa_initial_screening_history.id;


--
-- Name: ipa_initial_screenings; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_initial_screenings (
    id integer NOT NULL,
    master_id integer,
    select_is_good_time_to_speak character varying,
    select_may_i_begin character varying,
    any_questions_blank_yes_no character varying,
    select_still_interested character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_initial_screenings_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_initial_screenings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_initial_screenings_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_initial_screenings_id_seq OWNED BY ipa_ops.ipa_initial_screenings.id;


--
-- Name: ipa_payment_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_payment_history (
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
-- Name: ipa_payment_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_payment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_payment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_payment_history_id_seq OWNED BY ipa_ops.ipa_payment_history.id;


--
-- Name: ipa_payments; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_payments (
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
-- Name: ipa_payments_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_payments_id_seq OWNED BY ipa_ops.ipa_payments.id;


--
-- Name: ipa_protocol_deviation_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_protocol_deviation_history (
    id integer NOT NULL,
    master_id integer,
    deviation_occurred_when date,
    deviation_discovered_when date,
    select_severity character varying,
    deviation_description character varying,
    corrective_action_description character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_protocol_deviation_id integer
);


--
-- Name: ipa_protocol_deviation_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_protocol_deviation_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_protocol_deviation_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_protocol_deviation_history_id_seq OWNED BY ipa_ops.ipa_protocol_deviation_history.id;


--
-- Name: ipa_protocol_deviations; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_protocol_deviations (
    id integer NOT NULL,
    master_id integer,
    deviation_occurred_when date,
    deviation_discovered_when date,
    select_severity character varying,
    deviation_description character varying,
    corrective_action_description character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_protocol_deviations_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_protocol_deviations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_protocol_deviations_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_protocol_deviations_id_seq OWNED BY ipa_ops.ipa_protocol_deviations.id;


--
-- Name: ipa_ps_football_experience_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_football_experience_history (
    id integer NOT NULL,
    master_id integer,
    age integer,
    played_in_nfl_blank_yes_no character varying,
    played_before_nfl_blank_yes_no character varying,
    football_experience_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_football_experience_id integer
);


--
-- Name: ipa_ps_football_experience_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_football_experience_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_football_experience_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_football_experience_history_id_seq OWNED BY ipa_ops.ipa_ps_football_experience_history.id;


--
-- Name: ipa_ps_football_experiences; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_football_experiences (
    id integer NOT NULL,
    master_id integer,
    age integer,
    played_in_nfl_blank_yes_no character varying,
    played_before_nfl_blank_yes_no character varying,
    football_experience_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_ps_football_experiences_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_football_experiences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_football_experiences_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_football_experiences_id_seq OWNED BY ipa_ops.ipa_ps_football_experiences.id;


--
-- Name: ipa_ps_health_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_health_history (
    id integer NOT NULL,
    master_id integer,
    physical_limitations_blank_yes_no character varying,
    physical_limitations_details character varying,
    sit_back_blank_yes_no character varying,
    sit_back_details character varying,
    cycle_blank_yes_no character varying,
    cycle_details character varying,
    chronic_pain_blank_yes_no character varying,
    chronic_pain_details character varying,
    chronic_pain_meds_blank_yes_no_dont_know character varying,
    chronic_pain_meds_details character varying,
    hemophilia_blank_yes_no_dont_know character varying,
    hemophilia_details character varying,
    raynauds_syndrome_blank_yes_no_dont_know character varying,
    raynauds_syndrome_severity_selection character varying,
    raynauds_syndrome_details character varying,
    other_conditions_blank_yes_no_dont_know character varying,
    other_conditions_details character varying,
    hypertension_diagnosis_blank_yes_no_dont_know character varying,
    hypertension_diagnosis_details character varying,
    other_heart_conditions_blank_yes_no_dont_know character varying,
    other_heart_conditions_details character varying,
    memory_problems_blank_yes_no_dont_know character varying,
    memory_problems_details character varying,
    mental_health_conditions_blank_yes_no_dont_know character varying,
    mental_health_conditions_details character varying,
    neurological_problems_blank_yes_no_dont_know character varying,
    neurological_problems_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_health_id integer
);


--
-- Name: ipa_ps_health_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_health_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_health_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_health_history_id_seq OWNED BY ipa_ops.ipa_ps_health_history.id;


--
-- Name: ipa_ps_healths; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_healths (
    id integer NOT NULL,
    master_id integer,
    physical_limitations_blank_yes_no character varying,
    physical_limitations_details character varying,
    sit_back_blank_yes_no character varying,
    sit_back_details character varying,
    cycle_blank_yes_no character varying,
    cycle_details character varying,
    chronic_pain_blank_yes_no character varying,
    chronic_pain_details character varying,
    chronic_pain_meds_blank_yes_no_dont_know character varying,
    chronic_pain_meds_details character varying,
    hemophilia_blank_yes_no_dont_know character varying,
    hemophilia_details character varying,
    raynauds_syndrome_blank_yes_no_dont_know character varying,
    raynauds_syndrome_severity_selection character varying,
    raynauds_syndrome_details character varying,
    other_conditions_blank_yes_no_dont_know character varying,
    other_conditions_details character varying,
    hypertension_diagnosis_blank_yes_no_dont_know character varying,
    hypertension_diagnosis_details character varying,
    other_heart_conditions_blank_yes_no_dont_know character varying,
    other_heart_conditions_details character varying,
    memory_problems_blank_yes_no_dont_know character varying,
    memory_problems_details character varying,
    mental_health_conditions_blank_yes_no_dont_know character varying,
    mental_health_conditions_details character varying,
    neurological_problems_blank_yes_no_dont_know character varying,
    neurological_problems_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_ps_healths_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_healths_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_healths_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_healths_id_seq OWNED BY ipa_ops.ipa_ps_healths.id;


--
-- Name: ipa_ps_initial_screening_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_initial_screening_history (
    id integer NOT NULL,
    master_id integer,
    select_is_good_time_to_speak character varying,
    select_may_i_begin character varying,
    any_questions_blank_yes_no character varying,
    select_still_interested character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_initial_screening_id integer,
    follow_up_date date,
    follow_up_time time without time zone,
    notes character varying
);


--
-- Name: ipa_ps_initial_screening_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_initial_screening_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_initial_screening_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_initial_screening_history_id_seq OWNED BY ipa_ops.ipa_ps_initial_screening_history.id;


--
-- Name: ipa_ps_initial_screenings; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_initial_screenings (
    id integer NOT NULL,
    master_id integer,
    select_is_good_time_to_speak character varying,
    select_may_i_begin character varying,
    any_questions_blank_yes_no character varying,
    select_still_interested character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    follow_up_date date,
    follow_up_time time without time zone,
    notes character varying
);


--
-- Name: ipa_ps_initial_screenings_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_initial_screenings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_initial_screenings_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_initial_screenings_id_seq OWNED BY ipa_ops.ipa_ps_initial_screenings.id;


--
-- Name: ipa_ps_mri_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_mri_history (
    id integer NOT NULL,
    master_id integer,
    electrical_implants_blank_yes_no_dont_know character varying,
    electrical_implants_details character varying,
    metal_implants_blank_yes_no_dont_know character varying,
    metal_implants_details character varying,
    metal_jewelry_blank_yes_no character varying,
    hearing_aid_blank_yes_no character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_mri_id integer
);


--
-- Name: ipa_ps_mri_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_mri_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_mri_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_mri_history_id_seq OWNED BY ipa_ops.ipa_ps_mri_history.id;


--
-- Name: ipa_ps_mris; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_mris (
    id integer NOT NULL,
    master_id integer,
    electrical_implants_blank_yes_no_dont_know character varying,
    electrical_implants_details character varying,
    metal_implants_blank_yes_no_dont_know character varying,
    metal_implants_details character varying,
    metal_jewelry_blank_yes_no character varying,
    hearing_aid_blank_yes_no character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_ps_mris_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_mris_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_mris_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_mris_id_seq OWNED BY ipa_ops.ipa_ps_mris.id;


--
-- Name: ipa_ps_size_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_size_history (
    id integer NOT NULL,
    master_id integer,
    weight integer,
    height character varying,
    hat_size character varying,
    shirt_size character varying,
    jacket_size character varying,
    waist_size character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_size_id integer
);


--
-- Name: ipa_ps_size_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_size_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_size_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_size_history_id_seq OWNED BY ipa_ops.ipa_ps_size_history.id;


--
-- Name: ipa_ps_sizes; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_sizes (
    id integer NOT NULL,
    master_id integer,
    weight integer,
    height character varying,
    hat_size character varying,
    shirt_size character varying,
    jacket_size character varying,
    waist_size character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_ps_sizes_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_sizes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_sizes_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_sizes_id_seq OWNED BY ipa_ops.ipa_ps_sizes.id;


--
-- Name: ipa_ps_sleep_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_sleep_history (
    id integer NOT NULL,
    master_id integer,
    sleep_disorder_blank_yes_no_dont_know character varying,
    sleep_disorder_details character varying,
    sleep_apnea_device_no_yes character varying,
    sleep_apnea_device_details character varying,
    bed_and_wake_time_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_sleep_id integer
);


--
-- Name: ipa_ps_sleep_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_sleep_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_sleep_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_sleep_history_id_seq OWNED BY ipa_ops.ipa_ps_sleep_history.id;


--
-- Name: ipa_ps_sleeps; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_sleeps (
    id integer NOT NULL,
    master_id integer,
    sleep_disorder_blank_yes_no_dont_know character varying,
    sleep_disorder_details character varying,
    sleep_apnea_device_no_yes character varying,
    sleep_apnea_device_details character varying,
    bed_and_wake_time_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_ps_sleeps_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_sleeps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_sleeps_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_sleeps_id_seq OWNED BY ipa_ops.ipa_ps_sleeps.id;


--
-- Name: ipa_ps_tmoca_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_tmoca_history (
    id integer NOT NULL,
    master_id integer,
    tmoca_score integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_tmoca_id integer
);


--
-- Name: ipa_ps_tmoca_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_tmoca_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_tmoca_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_tmoca_history_id_seq OWNED BY ipa_ops.ipa_ps_tmoca_history.id;


--
-- Name: ipa_ps_tmocas; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_tmocas (
    id integer NOT NULL,
    master_id integer,
    tmoca_score integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_ps_tmocas_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_tmocas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_tmocas_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_tmocas_id_seq OWNED BY ipa_ops.ipa_ps_tmocas.id;


--
-- Name: ipa_ps_tms_test_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_tms_test_history (
    id integer NOT NULL,
    master_id integer,
    convulsion_or_seizue_blank_yes_no_dont_know character varying,
    epilepsy_blank_yes_no_dont_know character varying,
    fainting_blank_yes_no_dont_know character varying,
    concussion_blank_yes_no_dont_know character varying,
    hearing_problems_blank_yes_no_dont_know character varying,
    cochlear_implants_blank_yes_no_dont_know character varying,
    metal_blank_yes_no_dont_know character varying,
    metal_details character varying,
    neurostimulator_blank_yes_no_dont_know character varying,
    neurostimulator_details character varying,
    pacemaker_blank_yes_no_dont_know character varying,
    med_infusion_device_blank_yes_no_dont_know character varying,
    past_tms_blank_yes_no_dont_know character varying,
    past_tms_details character varying,
    past_mri_blank_yes_no_dont_know character varying,
    past_mri_details character varying,
    current_meds_blank_yes_no_dont_know character varying,
    current_meds_details character varying,
    neuro_history_details character varying,
    other_chronic_problems_blank_yes_no_dont_know character varying,
    other_chronic_problems_details character varying,
    hospital_visits_blank_yes_no_dont_know character varying,
    hospital_visits_details character varying,
    dietary_restrictions_blank_yes_no_dont_know character varying,
    dietary_restrictions_details character varying,
    anything_else_blank_yes_no character varying,
    anything_else_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_tms_test_id integer
);


--
-- Name: ipa_ps_tms_test_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_tms_test_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_tms_test_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_tms_test_history_id_seq OWNED BY ipa_ops.ipa_ps_tms_test_history.id;


--
-- Name: ipa_ps_tms_tests; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_tms_tests (
    id integer NOT NULL,
    master_id integer,
    convulsion_or_seizue_blank_yes_no_dont_know character varying,
    epilepsy_blank_yes_no_dont_know character varying,
    fainting_blank_yes_no_dont_know character varying,
    concussion_blank_yes_no_dont_know character varying,
    hearing_problems_blank_yes_no_dont_know character varying,
    cochlear_implants_blank_yes_no_dont_know character varying,
    metal_blank_yes_no_dont_know character varying,
    metal_details character varying,
    neurostimulator_blank_yes_no_dont_know character varying,
    neurostimulator_details character varying,
    pacemaker_blank_yes_no_dont_know character varying,
    med_infusion_device_blank_yes_no_dont_know character varying,
    past_tms_blank_yes_no_dont_know character varying,
    past_tms_details character varying,
    past_mri_blank_yes_no_dont_know character varying,
    past_mri_details character varying,
    current_meds_blank_yes_no_dont_know character varying,
    current_meds_details character varying,
    neuro_history_details character varying,
    other_chronic_problems_blank_yes_no_dont_know character varying,
    other_chronic_problems_details character varying,
    hospital_visits_blank_yes_no_dont_know character varying,
    hospital_visits_details character varying,
    dietary_restrictions_blank_yes_no_dont_know character varying,
    dietary_restrictions_details character varying,
    anything_else_blank_yes_no character varying,
    anything_else_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_ps_tms_tests_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_tms_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_tms_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_tms_tests_id_seq OWNED BY ipa_ops.ipa_ps_tms_tests.id;


--
-- Name: ipa_recruitment_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_recruitment_history (
    id integer NOT NULL,
    master_id integer,
    rank character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_recruitment_id integer
);


--
-- Name: ipa_recruitment_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_recruitment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_recruitment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_recruitment_history_id_seq OWNED BY ipa_ops.ipa_recruitment_history.id;


--
-- Name: ipa_recruitment_ranks; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_recruitment_ranks (
    id integer NOT NULL,
    master_id integer,
    rank integer
);


--
-- Name: ipa_recruitment_ranks_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_recruitment_ranks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_recruitment_ranks_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_recruitment_ranks_id_seq OWNED BY ipa_ops.ipa_recruitment_ranks.id;


--
-- Name: ipa_screening_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_screening_history (
    id integer NOT NULL,
    master_id integer,
    eligible_for_study_blank_yes_no character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_screening_id integer,
    good_time_to_speak_blank_yes_no character varying,
    callback_date date,
    callback_time time without time zone,
    still_interested_blank_yes_no character varying,
    ineligible_notes character varying,
    eligible_notes character varying,
    not_interested_notes character varying
);


--
-- Name: ipa_screening_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_screening_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_screening_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_screening_history_id_seq OWNED BY ipa_ops.ipa_screening_history.id;


--
-- Name: ipa_screenings; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_screenings (
    id integer NOT NULL,
    master_id integer,
    eligible_for_study_blank_yes_no character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    good_time_to_speak_blank_yes_no character varying,
    callback_date date,
    callback_time time without time zone,
    still_interested_blank_yes_no character varying,
    ineligible_notes character varying,
    eligible_notes character varying,
    not_interested_notes character varying
);


--
-- Name: ipa_screenings_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_screenings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_screenings_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_screenings_id_seq OWNED BY ipa_ops.ipa_screenings.id;


--
-- Name: ipa_station_contact_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_station_contact_history (
    id integer NOT NULL,
    master_id integer,
    first_name character varying,
    last_name character varying,
    role character varying,
    select_availability character varying,
    phone character varying,
    alt_phone character varying,
    email character varying,
    alt_email character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_station_contact_id integer
);


--
-- Name: ipa_station_contact_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_station_contact_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_station_contact_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_station_contact_history_id_seq OWNED BY ipa_ops.ipa_station_contact_history.id;


--
-- Name: ipa_station_contacts; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_station_contacts (
    id integer NOT NULL,
    master_id integer,
    first_name character varying,
    last_name character varying,
    role character varying,
    select_availability character varying,
    phone character varying,
    alt_phone character varying,
    email character varying,
    alt_email character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_station_contacts_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_station_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_station_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_station_contacts_id_seq OWNED BY ipa_ops.ipa_station_contacts.id;


--
-- Name: ipa_survey_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_survey_history (
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
-- Name: ipa_survey_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_survey_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_survey_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_survey_history_id_seq OWNED BY ipa_ops.ipa_survey_history.id;


--
-- Name: ipa_surveys; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_surveys (
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
-- Name: ipa_surveys_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_surveys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_surveys_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_surveys_id_seq OWNED BY ipa_ops.ipa_surveys.id;


--
-- Name: ipa_transportation_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_transportation_history (
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
-- Name: ipa_transportation_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_transportation_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_transportation_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_transportation_history_id_seq OWNED BY ipa_ops.ipa_transportation_history.id;


--
-- Name: ipa_transportations; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_transportations (
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
-- Name: ipa_transportations_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_transportations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_transportations_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_transportations_id_seq OWNED BY ipa_ops.ipa_transportations.id;


--
-- Name: ipa_withdrawal_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_withdrawal_history (
    id integer NOT NULL,
    master_id integer,
    select_subject_withdrew_reason character varying,
    select_investigator_terminated character varying,
    lost_to_follow_up_no_yes character varying,
    no_longer_participating_no_yes character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_withdrawal_id integer
);


--
-- Name: ipa_withdrawal_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_withdrawal_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_withdrawal_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_withdrawal_history_id_seq OWNED BY ipa_ops.ipa_withdrawal_history.id;


--
-- Name: ipa_withdrawals; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_withdrawals (
    id integer NOT NULL,
    master_id integer,
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
-- Name: ipa_withdrawals_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_withdrawals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_withdrawals_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_withdrawals_id_seq OWNED BY ipa_ops.ipa_withdrawals.id;


--
-- Name: mrn_number_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.mrn_number_history (
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
-- Name: mrn_number_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.mrn_number_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mrn_number_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.mrn_number_history_id_seq OWNED BY ipa_ops.mrn_number_history.id;


--
-- Name: mrn_numbers; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.mrn_numbers (
    id integer NOT NULL,
    master_id integer,
    mrn_id character varying,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: mrn_numbers_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.mrn_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mrn_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.mrn_numbers_id_seq OWNED BY ipa_ops.mrn_numbers.id;


--
-- Name: subjects; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.subjects (
    id integer NOT NULL,
    master_id integer,
    pilot_id integer
);


--
-- Name: subjects_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.subjects_id_seq OWNED BY ipa_ops.subjects.id;


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
-- Name: activity_log_bhs_assignment_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_bhs_assignment_history (
    id integer NOT NULL,
    master_id integer,
    bhs_assignment_id integer,
    select_record_from_player_contact_phones character varying,
    return_call_availability_notes character varying,
    questions_from_call_notes character varying,
    results_link character varying,
    select_result character varying,
    pi_return_call_notes character varying,
    completed_q1_no_yes character varying,
    completed_teamstudy_no_yes character varying,
    previous_contact_with_team_no_yes character varying,
    previous_contact_with_team_notes character varying,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_bhs_assignment_id integer
);


--
-- Name: activity_log_bhs_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.activity_log_bhs_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_bhs_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_bhs_assignment_history_id_seq OWNED BY ml_app.activity_log_bhs_assignment_history.id;


--
-- Name: activity_log_bhs_assignments; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_bhs_assignments (
    id integer NOT NULL,
    master_id integer,
    bhs_assignment_id integer,
    select_record_from_player_contact_phones character varying,
    return_call_availability_notes character varying,
    questions_from_call_notes character varying,
    results_link character varying,
    select_result character varying,
    pi_return_call_notes character varying,
    completed_q1_no_yes character varying,
    completed_teamstudy_no_yes character varying,
    previous_contact_with_team_no_yes character varying,
    previous_contact_with_team_notes character varying,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_bhs_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.activity_log_bhs_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_bhs_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_bhs_assignments_id_seq OWNED BY ml_app.activity_log_bhs_assignments.id;


--
-- Name: activity_log_ext_assignment_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_ext_assignment_history (
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

CREATE SEQUENCE ml_app.activity_log_ext_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ext_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_ext_assignment_history_id_seq OWNED BY ml_app.activity_log_ext_assignment_history.id;


--
-- Name: activity_log_ext_assignments; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_ext_assignments (
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

CREATE SEQUENCE ml_app.activity_log_ext_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ext_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_ext_assignments_id_seq OWNED BY ml_app.activity_log_ext_assignments.id;


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
    blank_log_field_list character varying
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
-- Name: activity_log_new_test_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_new_test_history (
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

CREATE SEQUENCE ml_app.activity_log_new_test_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_new_test_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_new_test_history_id_seq OWNED BY ml_app.activity_log_new_test_history.id;


--
-- Name: activity_log_new_tests; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_new_tests (
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

CREATE SEQUENCE ml_app.activity_log_new_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_new_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_new_tests_id_seq OWNED BY ml_app.activity_log_new_tests.id;


--
-- Name: activity_log_player_contact_emails; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_player_contact_emails (
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

CREATE SEQUENCE ml_app.activity_log_player_contact_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_contact_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_player_contact_emails_id_seq OWNED BY ml_app.activity_log_player_contact_emails.id;


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
-- Name: activity_log_player_info_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_player_info_history (
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

CREATE SEQUENCE ml_app.activity_log_player_info_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_info_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_player_info_history_id_seq OWNED BY ml_app.activity_log_player_info_history.id;


--
-- Name: activity_log_player_infos; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.activity_log_player_infos (
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

CREATE SEQUENCE ml_app.activity_log_player_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_player_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.activity_log_player_infos_id_seq OWNED BY ml_app.activity_log_player_infos.id;


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
    table_name character varying
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
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:35.841791'::timestamp without time zone,
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
    admin_id integer
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
    disabled boolean
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
-- Name: app_configurations; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.app_configurations (
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
-- Name: app_types; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.app_types (
    id integer NOT NULL,
    name character varying,
    label character varying,
    disabled boolean,
    admin_id integer
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
-- Name: bhs_assignment_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.bhs_assignment_history (
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
-- Name: bhs_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.bhs_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bhs_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.bhs_assignment_history_id_seq OWNED BY ml_app.bhs_assignment_history.id;


--
-- Name: bhs_assignments; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.bhs_assignments (
    id integer NOT NULL,
    master_id integer,
    bhs_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bhs_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.bhs_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bhs_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.bhs_assignments_id_seq OWNED BY ml_app.bhs_assignments.id;


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
-- Name: dl_addresses; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.dl_addresses (
    id integer NOT NULL,
    email character varying,
    name character varying
);


--
-- Name: dl_addresses_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.dl_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dl_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.dl_addresses_id_seq OWNED BY ml_app.dl_addresses.id;


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
    dynamic_model_id integer
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
-- Name: ext_assignment_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.ext_assignment_history (
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

CREATE SEQUENCE ml_app.ext_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.ext_assignment_history_id_seq OWNED BY ml_app.ext_assignment_history.id;


--
-- Name: ext_assignments; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.ext_assignments (
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

CREATE SEQUENCE ml_app.ext_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.ext_assignments_id_seq OWNED BY ml_app.ext_assignments.id;


--
-- Name: ext_gen_assignment_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.ext_gen_assignment_history (
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

CREATE SEQUENCE ml_app.ext_gen_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_gen_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.ext_gen_assignment_history_id_seq OWNED BY ml_app.ext_gen_assignment_history.id;


--
-- Name: ext_gen_assignments; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.ext_gen_assignments (
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

CREATE SEQUENCE ml_app.ext_gen_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ext_gen_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.ext_gen_assignments_id_seq OWNED BY ml_app.ext_gen_assignments.id;


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
    external_identifier_id integer
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
    alphanumeric boolean
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
-- Name: found_bhs_id; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.found_bhs_id (
    bhs_id bigint
);


--
-- Name: found_bhs_ids; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.found_bhs_ids (
    bhs_id bigint
);


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
-- Name: ipa_assignment_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.ipa_assignment_history (
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

CREATE SEQUENCE ml_app.ipa_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.ipa_assignment_history_id_seq OWNED BY ml_app.ipa_assignment_history.id;


--
-- Name: ipa_assignments; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.ipa_assignments (
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

CREATE SEQUENCE ml_app.ipa_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.ipa_assignments_id_seq OWNED BY ml_app.ipa_assignments.id;


--
-- Name: ipa_recruitment_ranks; Type: VIEW; Schema: ml_app; Owner: -
--

CREATE VIEW ml_app.ipa_recruitment_ranks AS
 SELECT ipa_recruitment_ranks.id,
    ipa_recruitment_ranks.master_id,
    ipa_recruitment_ranks.rank,
    now() AS created_at,
    now() AS updated_at
   FROM ipa_ops.ipa_recruitment_ranks;


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
    item_flag_name_id integer,
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
-- Name: json_doc_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.json_doc_history (
    id integer NOT NULL,
    master_id integer,
    responses jsonb,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    json_doc_id integer
);


--
-- Name: json_doc_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.json_doc_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: json_doc_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.json_doc_history_id_seq OWNED BY ml_app.json_doc_history.id;


--
-- Name: json_docs; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.json_docs (
    id integer NOT NULL,
    master_id integer,
    responses jsonb,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: json_docs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.json_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: json_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.json_docs_id_seq OWNED BY ml_app.json_docs.id;


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
    contact_id integer
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
    recipient_emails character varying[],
    from_user_email character varying
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
    updated_at timestamp without time zone NOT NULL
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
-- Name: ml_copy; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.ml_copy (
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
    updated_at timestamp without time zone NOT NULL
);


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
-- Name: new_test_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.new_test_history (
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

CREATE SEQUENCE ml_app.new_test_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_test_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.new_test_history_id_seq OWNED BY ml_app.new_test_history.id;


--
-- Name: new_tests; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.new_tests (
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

CREATE SEQUENCE ml_app.new_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.new_tests_id_seq OWNED BY ml_app.new_tests.id;


--
-- Name: nfs_store_archived_files; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_archived_files (
    id integer NOT NULL,
    file_hash character varying NOT NULL,
    file_name character varying NOT NULL,
    content_type character varying NOT NULL,
    archive_file character varying NOT NULL,
    path character varying NOT NULL,
    file_size integer NOT NULL,
    file_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    nfs_store_container_id integer,
    user_id integer
);


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
    nfs_store_container_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
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
-- Name: nfs_store_stored_files; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_stored_files (
    id integer NOT NULL,
    file_hash character varying NOT NULL,
    file_name character varying NOT NULL,
    content_type character varying NOT NULL,
    file_size integer NOT NULL,
    path character varying,
    file_updated_at timestamp without time zone,
    user_id integer,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


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
-- Name: nfs_store_uploads; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.nfs_store_uploads (
    id integer NOT NULL,
    file_hash character varying NOT NULL,
    file_name character varying NOT NULL,
    content_type character varying NOT NULL,
    file_size integer NOT NULL,
    chunk_count integer,
    completed boolean,
    file_updated_at timestamp without time zone,
    user_id integer,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
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
    updated_at timestamp without time zone NOT NULL
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
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:36.835851'::timestamp without time zone,
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
    updated_at timestamp without time zone DEFAULT '2017-09-25 15:43:37.165247'::timestamp without time zone
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
    "position" integer
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
    selection_fields character varying
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
    item_type character varying
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
-- Name: sage_two_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.sage_two_history (
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

CREATE SEQUENCE ml_app.sage_two_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sage_two_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.sage_two_history_id_seq OWNED BY ml_app.sage_two_history.id;


--
-- Name: sage_twos; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.sage_twos (
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

CREATE SEQUENCE ml_app.sage_twos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sage_twos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.sage_twos_id_seq OWNED BY ml_app.sage_twos.id;


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
-- Name: scantron_series_two_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.scantron_series_two_history (
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

CREATE SEQUENCE ml_app.scantron_series_two_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantron_series_two_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.scantron_series_two_history_id_seq OWNED BY ml_app.scantron_series_two_history.id;


--
-- Name: scantron_series_twos; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.scantron_series_twos (
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

CREATE SEQUENCE ml_app.scantron_series_twos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantron_series_twos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.scantron_series_twos_id_seq OWNED BY ml_app.scantron_series_twos.id;


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
-- Name: smback; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.smback (
    version character varying
);


--
-- Name: social_security_number_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.social_security_number_history (
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
-- Name: social_security_number_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.social_security_number_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_security_number_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.social_security_number_history_id_seq OWNED BY ml_app.social_security_number_history.id;


--
-- Name: social_security_numbers; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.social_security_numbers (
    id integer NOT NULL,
    master_id integer,
    ssn_id character varying,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: social_security_numbers_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.social_security_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_security_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.social_security_numbers_id_seq OWNED BY ml_app.social_security_numbers.id;


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
-- Name: sync_statuses; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.sync_statuses (
    id integer NOT NULL,
    from_db character varying,
    from_master_id integer,
    to_db character varying,
    to_master_id integer,
    select_status character varying DEFAULT 'new'::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sync_statuses_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.sync_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sync_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.sync_statuses_id_seq OWNED BY ml_app.sync_statuses.id;


--
-- Name: test1_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test1_history (
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

CREATE SEQUENCE ml_app.test1_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test1_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test1_history_id_seq OWNED BY ml_app.test1_history.id;


--
-- Name: test1s; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test1s (
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

CREATE SEQUENCE ml_app.test1s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test1s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test1s_id_seq OWNED BY ml_app.test1s.id;


--
-- Name: test2_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test2_history (
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

CREATE SEQUENCE ml_app.test2_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test2_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test2_history_id_seq OWNED BY ml_app.test2_history.id;


--
-- Name: test2s; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test2s (
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

CREATE SEQUENCE ml_app.test2s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test2s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test2s_id_seq OWNED BY ml_app.test2s.id;


--
-- Name: test_2_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test_2_history (
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

CREATE SEQUENCE ml_app.test_2_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_2_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test_2_history_id_seq OWNED BY ml_app.test_2_history.id;


--
-- Name: test_2s; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test_2s (
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

CREATE SEQUENCE ml_app.test_2s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_2s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test_2s_id_seq OWNED BY ml_app.test_2s.id;


--
-- Name: test_ext2_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test_ext2_history (
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

CREATE SEQUENCE ml_app.test_ext2_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_ext2_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test_ext2_history_id_seq OWNED BY ml_app.test_ext2_history.id;


--
-- Name: test_ext2s; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test_ext2s (
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

CREATE SEQUENCE ml_app.test_ext2s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_ext2s_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test_ext2s_id_seq OWNED BY ml_app.test_ext2s.id;


--
-- Name: test_ext_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test_ext_history (
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

CREATE SEQUENCE ml_app.test_ext_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_ext_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test_ext_history_id_seq OWNED BY ml_app.test_ext_history.id;


--
-- Name: test_exts; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test_exts (
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

CREATE SEQUENCE ml_app.test_exts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_exts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test_exts_id_seq OWNED BY ml_app.test_exts.id;


--
-- Name: test_item_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test_item_history (
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

CREATE SEQUENCE ml_app.test_item_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_item_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test_item_history_id_seq OWNED BY ml_app.test_item_history.id;


--
-- Name: test_items; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.test_items (
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

CREATE SEQUENCE ml_app.test_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_items_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.test_items_id_seq OWNED BY ml_app.test_items.id;


--
-- Name: testing_dl_history; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.testing_dl_history (
    id integer NOT NULL,
    master_id integer,
    name character varying,
    select_yes_no character varying,
    select_record_from_table_dl_addresses character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    testing_dl_id integer
);


--
-- Name: testing_dl_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.testing_dl_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: testing_dl_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.testing_dl_history_id_seq OWNED BY ml_app.testing_dl_history.id;


--
-- Name: testing_dls; Type: TABLE; Schema: ml_app; Owner: -
--

CREATE TABLE ml_app.testing_dls (
    id integer NOT NULL,
    master_id integer,
    name character varying,
    select_yes_no character varying,
    select_record_from_table_dl_addresses character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: testing_dls_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--

CREATE SEQUENCE ml_app.testing_dls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: testing_dls_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--

ALTER SEQUENCE ml_app.testing_dls_id_seq OWNED BY ml_app.testing_dls.id;


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
    role_name character varying
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
    app_type_id integer
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
    app_type_id integer
);


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
-- Name: tmbs; Type: TABLE; Schema: testmybrain; Owner: -
--

CREATE TABLE testmybrain.tmbs (
    id integer NOT NULL,
    master_id integer
);


--
-- Name: tmbs_id_seq; Type: SEQUENCE; Schema: testmybrain; Owner: -
--

CREATE SEQUENCE testmybrain.tmbs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tmbs_id_seq; Type: SEQUENCE OWNED BY; Schema: testmybrain; Owner: -
--

ALTER SEQUENCE testmybrain.tmbs_id_seq OWNED BY testmybrain.tmbs.id;


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_event_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_adverse_event_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_events ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_adverse_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklist_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_inex_checklist_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklists ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_inex_checklists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviation_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_minor_deviation_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviations ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_minor_deviations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigation_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_navigation_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigations ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_navigations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screen_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_phone_screen_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screens ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_phone_screens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviation_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_protocol_deviation_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviations ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_protocol_deviations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_session_filestore_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_session_filestore_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_session_filestores ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_session_filestores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignments ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_screening_phone_screen_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_screening_phone_screen_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_screening_phone_screens ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_screening_phone_screens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_survey_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_survey_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_surveys ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_surveys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.emergency_contacts ALTER COLUMN id SET DEFAULT nextval('ipa_ops.emergency_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adl_informant_screener_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_adl_informant_screener_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adl_informant_screeners ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_adl_informant_screeners_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adverse_event_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_adverse_event_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adverse_events ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_adverse_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointment_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_appointment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointments ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_appointments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_assignment_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_consent_mailing_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_consent_mailing_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_consent_mailings ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_consent_mailings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_hotel_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_hotel_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_hotels ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_hotels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_inex_checklist_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_inex_checklist_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_inex_checklists ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_inex_checklists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_initial_screening_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_initial_screening_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_initial_screenings ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_initial_screenings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_payment_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_payment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_payments ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_payments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_deviation_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_protocol_deviation_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_deviations ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_protocol_deviations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_football_experience_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_football_experience_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_football_experiences ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_football_experiences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_health_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_health_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_healths ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_healths_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_initial_screening_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_initial_screening_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_initial_screenings ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_initial_screenings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_mri_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_mri_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_mris ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_mris_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_size_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_size_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sizes ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_sizes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sleep_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_sleep_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sleeps ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_sleeps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tmoca_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_tmoca_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tmocas ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_tmocas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tms_test_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_tms_test_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tms_tests ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_tms_tests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_recruitment_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_recruitment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_recruitment_ranks ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_recruitment_ranks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_screening_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_screening_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_screenings ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_screenings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_station_contact_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_station_contact_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_station_contacts ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_station_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_survey_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_survey_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_surveys ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_surveys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_transportation_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_transportation_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_transportations ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_transportations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_withdrawal_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_withdrawal_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_withdrawals ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_withdrawals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_number_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.mrn_number_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_numbers ALTER COLUMN id SET DEFAULT nextval('ipa_ops.mrn_numbers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.subjects ALTER COLUMN id SET DEFAULT nextval('ipa_ops.subjects_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.activity_log_bhs_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_bhs_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_bhs_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_ext_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_ext_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_ext_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_ext_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_history ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_new_test_history ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_new_test_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_new_tests ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_new_tests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_emails ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_player_contact_emails_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.activity_log_player_info_history ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_player_info_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_infos ALTER COLUMN id SET DEFAULT nextval('ml_app.activity_log_player_infos_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.app_configurations ALTER COLUMN id SET DEFAULT nextval('ml_app.app_configurations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_types ALTER COLUMN id SET DEFAULT nextval('ml_app.app_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app.bhs_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app.bhs_assignments_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('ml_app.delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.dl_addresses ALTER COLUMN id SET DEFAULT nextval('ml_app.dl_addresses_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.ext_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app.ext_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app.ext_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_gen_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app.ext_gen_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_gen_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app.ext_gen_assignments_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.ipa_assignment_history ALTER COLUMN id SET DEFAULT nextval('ml_app.ipa_assignment_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ipa_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app.ipa_assignments_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.json_doc_history ALTER COLUMN id SET DEFAULT nextval('ml_app.json_doc_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.json_docs ALTER COLUMN id SET DEFAULT nextval('ml_app.json_docs_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.message_templates ALTER COLUMN id SET DEFAULT nextval('ml_app.message_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.model_references ALTER COLUMN id SET DEFAULT nextval('ml_app.model_references_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.new_test_history ALTER COLUMN id SET DEFAULT nextval('ml_app.new_test_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.new_tests ALTER COLUMN id SET DEFAULT nextval('ml_app.new_tests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_files ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_archived_files_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.nfs_store_stored_files ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_stored_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_uploads ALTER COLUMN id SET DEFAULT nextval('ml_app.nfs_store_uploads_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.sage_assignments ALTER COLUMN id SET DEFAULT nextval('ml_app.sage_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sage_two_history ALTER COLUMN id SET DEFAULT nextval('ml_app.sage_two_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sage_twos ALTER COLUMN id SET DEFAULT nextval('ml_app.sage_twos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantron_history ALTER COLUMN id SET DEFAULT nextval('ml_app.scantron_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantron_series_two_history ALTER COLUMN id SET DEFAULT nextval('ml_app.scantron_series_two_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantron_series_twos ALTER COLUMN id SET DEFAULT nextval('ml_app.scantron_series_twos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantrons ALTER COLUMN id SET DEFAULT nextval('ml_app.scantrons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.social_security_number_history ALTER COLUMN id SET DEFAULT nextval('ml_app.social_security_number_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.social_security_numbers ALTER COLUMN id SET DEFAULT nextval('ml_app.social_security_numbers_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.sync_statuses ALTER COLUMN id SET DEFAULT nextval('ml_app.sync_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test1_history ALTER COLUMN id SET DEFAULT nextval('ml_app.test1_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test1s ALTER COLUMN id SET DEFAULT nextval('ml_app.test1s_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test2_history ALTER COLUMN id SET DEFAULT nextval('ml_app.test2_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test2s ALTER COLUMN id SET DEFAULT nextval('ml_app.test2s_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_2_history ALTER COLUMN id SET DEFAULT nextval('ml_app.test_2_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_2s ALTER COLUMN id SET DEFAULT nextval('ml_app.test_2s_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext2_history ALTER COLUMN id SET DEFAULT nextval('ml_app.test_ext2_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext2s ALTER COLUMN id SET DEFAULT nextval('ml_app.test_ext2s_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext_history ALTER COLUMN id SET DEFAULT nextval('ml_app.test_ext_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_exts ALTER COLUMN id SET DEFAULT nextval('ml_app.test_exts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_item_history ALTER COLUMN id SET DEFAULT nextval('ml_app.test_item_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_items ALTER COLUMN id SET DEFAULT nextval('ml_app.test_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.testing_dl_history ALTER COLUMN id SET DEFAULT nextval('ml_app.testing_dl_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.testing_dls ALTER COLUMN id SET DEFAULT nextval('ml_app.testing_dls_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.user_history ALTER COLUMN id SET DEFAULT nextval('ml_app.user_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_roles ALTER COLUMN id SET DEFAULT nextval('ml_app.user_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.users ALTER COLUMN id SET DEFAULT nextval('ml_app.users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: testmybrain; Owner: -
--

ALTER TABLE ONLY testmybrain.tmbs ALTER COLUMN id SET DEFAULT nextval('testmybrain.tmbs_id_seq'::regclass);


--
-- Name: activity_log_ipa_assignment_adverse_event_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_event_history
    ADD CONSTRAINT activity_log_ipa_assignment_adverse_event_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_adverse_events_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_events
    ADD CONSTRAINT activity_log_ipa_assignment_adverse_events_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_history
    ADD CONSTRAINT activity_log_ipa_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_inex_checklist_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklist_history
    ADD CONSTRAINT activity_log_ipa_assignment_inex_checklist_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_inex_checklists_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklists
    ADD CONSTRAINT activity_log_ipa_assignment_inex_checklists_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_minor_deviation_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviation_history
    ADD CONSTRAINT activity_log_ipa_assignment_minor_deviation_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_minor_deviations_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviations
    ADD CONSTRAINT activity_log_ipa_assignment_minor_deviations_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_navigation_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigation_history
    ADD CONSTRAINT activity_log_ipa_assignment_navigation_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_navigations_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigations
    ADD CONSTRAINT activity_log_ipa_assignment_navigations_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_phone_screen_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screen_history
    ADD CONSTRAINT activity_log_ipa_assignment_phone_screen_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_phone_screens_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screens
    ADD CONSTRAINT activity_log_ipa_assignment_phone_screens_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_protocol_deviation_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviation_history
    ADD CONSTRAINT activity_log_ipa_assignment_protocol_deviation_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_protocol_deviations_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviations
    ADD CONSTRAINT activity_log_ipa_assignment_protocol_deviations_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_session_filestore_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_session_filestore_history
    ADD CONSTRAINT activity_log_ipa_assignment_session_filestore_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_session_filestores_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_session_filestores
    ADD CONSTRAINT activity_log_ipa_assignment_session_filestores_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignments_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignments
    ADD CONSTRAINT activity_log_ipa_assignments_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_screening_phone_screen_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_screening_phone_screen_history
    ADD CONSTRAINT activity_log_ipa_screening_phone_screen_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_screening_phone_screens_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_screening_phone_screens
    ADD CONSTRAINT activity_log_ipa_screening_phone_screens_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_survey_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_survey_history
    ADD CONSTRAINT activity_log_ipa_survey_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_surveys_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_surveys
    ADD CONSTRAINT activity_log_ipa_surveys_pkey PRIMARY KEY (id);


--
-- Name: emergency_contacts_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.emergency_contacts
    ADD CONSTRAINT emergency_contacts_pkey PRIMARY KEY (id);


--
-- Name: ipa_adl_informant_screener_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adl_informant_screener_history
    ADD CONSTRAINT ipa_adl_informant_screener_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_adl_informant_screeners_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adl_informant_screeners
    ADD CONSTRAINT ipa_adl_informant_screeners_pkey PRIMARY KEY (id);


--
-- Name: ipa_adverse_event_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adverse_event_history
    ADD CONSTRAINT ipa_adverse_event_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_adverse_events_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adverse_events
    ADD CONSTRAINT ipa_adverse_events_pkey PRIMARY KEY (id);


--
-- Name: ipa_appointment_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointment_history
    ADD CONSTRAINT ipa_appointment_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_appointments_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointments
    ADD CONSTRAINT ipa_appointments_pkey PRIMARY KEY (id);


--
-- Name: ipa_appointments_visit_start_date_key; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointments
    ADD CONSTRAINT ipa_appointments_visit_start_date_key UNIQUE (visit_start_date);


--
-- Name: ipa_assignment_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_assignment_history
    ADD CONSTRAINT ipa_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_consent_mailing_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_consent_mailing_history
    ADD CONSTRAINT ipa_consent_mailing_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_consent_mailings_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_consent_mailings
    ADD CONSTRAINT ipa_consent_mailings_pkey PRIMARY KEY (id);


--
-- Name: ipa_hotel_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_hotel_history
    ADD CONSTRAINT ipa_hotel_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_hotels_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_hotels
    ADD CONSTRAINT ipa_hotels_pkey PRIMARY KEY (id);


--
-- Name: ipa_inex_checklist_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_inex_checklist_history
    ADD CONSTRAINT ipa_inex_checklist_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_inex_checklists_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_inex_checklists
    ADD CONSTRAINT ipa_inex_checklists_pkey PRIMARY KEY (id);


--
-- Name: ipa_initial_screening_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_initial_screening_history
    ADD CONSTRAINT ipa_initial_screening_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_initial_screenings_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_initial_screenings
    ADD CONSTRAINT ipa_initial_screenings_pkey PRIMARY KEY (id);


--
-- Name: ipa_payment_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_payment_history
    ADD CONSTRAINT ipa_payment_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_payments_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_payments
    ADD CONSTRAINT ipa_payments_pkey PRIMARY KEY (id);


--
-- Name: ipa_protocol_deviation_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_deviation_history
    ADD CONSTRAINT ipa_protocol_deviation_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_protocol_deviations_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_deviations
    ADD CONSTRAINT ipa_protocol_deviations_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_football_experience_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_football_experience_history
    ADD CONSTRAINT ipa_ps_football_experience_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_football_experiences_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_football_experiences
    ADD CONSTRAINT ipa_ps_football_experiences_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_health_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_health_history
    ADD CONSTRAINT ipa_ps_health_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_healths_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_healths
    ADD CONSTRAINT ipa_ps_healths_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_initial_screening_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_initial_screening_history
    ADD CONSTRAINT ipa_ps_initial_screening_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_initial_screenings_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_initial_screenings
    ADD CONSTRAINT ipa_ps_initial_screenings_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_mri_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_mri_history
    ADD CONSTRAINT ipa_ps_mri_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_mris_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_mris
    ADD CONSTRAINT ipa_ps_mris_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_size_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_size_history
    ADD CONSTRAINT ipa_ps_size_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_sizes_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sizes
    ADD CONSTRAINT ipa_ps_sizes_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_sleep_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sleep_history
    ADD CONSTRAINT ipa_ps_sleep_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_sleeps_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sleeps
    ADD CONSTRAINT ipa_ps_sleeps_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_tmoca_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tmoca_history
    ADD CONSTRAINT ipa_ps_tmoca_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_tmocas_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tmocas
    ADD CONSTRAINT ipa_ps_tmocas_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_tms_test_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tms_test_history
    ADD CONSTRAINT ipa_ps_tms_test_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_tms_tests_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tms_tests
    ADD CONSTRAINT ipa_ps_tms_tests_pkey PRIMARY KEY (id);


--
-- Name: ipa_recruitment_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_recruitment_history
    ADD CONSTRAINT ipa_recruitment_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_screening_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_screening_history
    ADD CONSTRAINT ipa_screening_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_screenings_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_screenings
    ADD CONSTRAINT ipa_screenings_pkey PRIMARY KEY (id);


--
-- Name: ipa_station_contact_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_station_contact_history
    ADD CONSTRAINT ipa_station_contact_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_station_contacts_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_station_contacts
    ADD CONSTRAINT ipa_station_contacts_pkey PRIMARY KEY (id);


--
-- Name: ipa_survey_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_survey_history
    ADD CONSTRAINT ipa_survey_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_surveys_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_surveys
    ADD CONSTRAINT ipa_surveys_pkey PRIMARY KEY (id);


--
-- Name: ipa_transportation_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_transportation_history
    ADD CONSTRAINT ipa_transportation_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_transportations_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_transportations
    ADD CONSTRAINT ipa_transportations_pkey PRIMARY KEY (id);


--
-- Name: ipa_withdrawal_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_withdrawal_history
    ADD CONSTRAINT ipa_withdrawal_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_withdrawals_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_withdrawals
    ADD CONSTRAINT ipa_withdrawals_pkey PRIMARY KEY (id);


--
-- Name: mrn_number_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_number_history
    ADD CONSTRAINT mrn_number_history_pkey PRIMARY KEY (id);


--
-- Name: mrn_numbers_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_numbers
    ADD CONSTRAINT mrn_numbers_pkey PRIMARY KEY (id);


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
-- Name: activity_log_bhs_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignment_history
    ADD CONSTRAINT activity_log_bhs_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_bhs_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignments
    ADD CONSTRAINT activity_log_bhs_assignments_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ext_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_ext_assignment_history
    ADD CONSTRAINT activity_log_ext_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ext_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_ext_assignments
    ADD CONSTRAINT activity_log_ext_assignments_pkey PRIMARY KEY (id);


--
-- Name: activity_log_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_history
    ADD CONSTRAINT activity_log_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_new_test_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_new_test_history
    ADD CONSTRAINT activity_log_new_test_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_new_tests_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_new_tests
    ADD CONSTRAINT activity_log_new_tests_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_contact_emails_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_contact_emails
    ADD CONSTRAINT activity_log_player_contact_emails_pkey PRIMARY KEY (id);


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
-- Name: activity_log_player_info_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_info_history
    ADD CONSTRAINT activity_log_player_info_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_player_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_infos
    ADD CONSTRAINT activity_log_player_infos_pkey PRIMARY KEY (id);


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
-- Name: app_configurations_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_configurations
    ADD CONSTRAINT app_configurations_pkey PRIMARY KEY (id);


--
-- Name: app_types_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_types
    ADD CONSTRAINT app_types_pkey PRIMARY KEY (id);


--
-- Name: bhs_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignment_history
    ADD CONSTRAINT bhs_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: bhs_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignments
    ADD CONSTRAINT bhs_assignments_pkey PRIMARY KEY (id);


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
-- Name: ext_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_assignment_history
    ADD CONSTRAINT ext_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: ext_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_assignments
    ADD CONSTRAINT ext_assignments_pkey PRIMARY KEY (id);


--
-- Name: ext_gen_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_gen_assignment_history
    ADD CONSTRAINT ext_gen_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: ext_gen_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_gen_assignments
    ADD CONSTRAINT ext_gen_assignments_pkey PRIMARY KEY (id);


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
-- Name: imports_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: ipa_assignment_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ipa_assignment_history
    ADD CONSTRAINT ipa_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ipa_assignments
    ADD CONSTRAINT ipa_assignments_pkey PRIMARY KEY (id);


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
-- Name: json_doc_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.json_doc_history
    ADD CONSTRAINT json_doc_history_pkey PRIMARY KEY (id);


--
-- Name: json_docs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.json_docs
    ADD CONSTRAINT json_docs_pkey PRIMARY KEY (id);


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
-- Name: new_test_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.new_test_history
    ADD CONSTRAINT new_test_history_pkey PRIMARY KEY (id);


--
-- Name: new_tests_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.new_tests
    ADD CONSTRAINT new_tests_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_archived_files_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_files
    ADD CONSTRAINT nfs_store_archived_files_pkey PRIMARY KEY (id);


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
-- Name: nfs_store_stored_files_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_stored_files
    ADD CONSTRAINT nfs_store_stored_files_pkey PRIMARY KEY (id);


--
-- Name: nfs_store_uploads_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_uploads
    ADD CONSTRAINT nfs_store_uploads_pkey PRIMARY KEY (id);


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
-- Name: sage_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sage_assignments
    ADD CONSTRAINT sage_assignments_pkey PRIMARY KEY (id);


--
-- Name: sage_two_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sage_two_history
    ADD CONSTRAINT sage_two_history_pkey PRIMARY KEY (id);


--
-- Name: sage_twos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sage_twos
    ADD CONSTRAINT sage_twos_pkey PRIMARY KEY (id);


--
-- Name: scantron_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantron_history
    ADD CONSTRAINT scantron_history_pkey PRIMARY KEY (id);


--
-- Name: scantron_series_two_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantron_series_two_history
    ADD CONSTRAINT scantron_series_two_history_pkey PRIMARY KEY (id);


--
-- Name: scantron_series_twos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantron_series_twos
    ADD CONSTRAINT scantron_series_twos_pkey PRIMARY KEY (id);


--
-- Name: scantrons_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantrons
    ADD CONSTRAINT scantrons_pkey PRIMARY KEY (id);


--
-- Name: social_security_number_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.social_security_number_history
    ADD CONSTRAINT social_security_number_history_pkey PRIMARY KEY (id);


--
-- Name: social_security_numbers_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.social_security_numbers
    ADD CONSTRAINT social_security_numbers_pkey PRIMARY KEY (id);


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
-- Name: test1_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test1_history
    ADD CONSTRAINT test1_history_pkey PRIMARY KEY (id);


--
-- Name: test1s_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test1s
    ADD CONSTRAINT test1s_pkey PRIMARY KEY (id);


--
-- Name: test2_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test2_history
    ADD CONSTRAINT test2_history_pkey PRIMARY KEY (id);


--
-- Name: test2s_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test2s
    ADD CONSTRAINT test2s_pkey PRIMARY KEY (id);


--
-- Name: test_2_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_2_history
    ADD CONSTRAINT test_2_history_pkey PRIMARY KEY (id);


--
-- Name: test_2s_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_2s
    ADD CONSTRAINT test_2s_pkey PRIMARY KEY (id);


--
-- Name: test_ext2_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext2_history
    ADD CONSTRAINT test_ext2_history_pkey PRIMARY KEY (id);


--
-- Name: test_ext2s_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext2s
    ADD CONSTRAINT test_ext2s_pkey PRIMARY KEY (id);


--
-- Name: test_ext_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext_history
    ADD CONSTRAINT test_ext_history_pkey PRIMARY KEY (id);


--
-- Name: test_exts_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_exts
    ADD CONSTRAINT test_exts_pkey PRIMARY KEY (id);


--
-- Name: test_item_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_item_history
    ADD CONSTRAINT test_item_history_pkey PRIMARY KEY (id);


--
-- Name: test_items_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_items
    ADD CONSTRAINT test_items_pkey PRIMARY KEY (id);


--
-- Name: testing_dl_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.testing_dl_history
    ADD CONSTRAINT testing_dl_history_pkey PRIMARY KEY (id);


--
-- Name: testing_dls_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.testing_dls
    ADD CONSTRAINT testing_dls_pkey PRIMARY KEY (id);


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
-- Name: user_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_history
    ADD CONSTRAINT user_history_pkey PRIMARY KEY (id);


--
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_activity_log_ipa_assignment_adverse_events_on_ipa_assignm; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_adverse_events_on_ipa_assignm ON ipa_ops.activity_log_ipa_assignment_adverse_events USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_adverse_events_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_adverse_events_on_master_id ON ipa_ops.activity_log_ipa_assignment_adverse_events USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_adverse_events_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_adverse_events_on_user_id ON ipa_ops.activity_log_ipa_assignment_adverse_events USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_activity_log_ipa_a; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_activity_log_ipa_a ON ipa_ops.activity_log_ipa_assignment_history USING btree (activity_log_ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_ipa_assignment_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_ipa_assignment_id ON ipa_ops.activity_log_ipa_assignment_history USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_master_id ON ipa_ops.activity_log_ipa_assignment_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_history_on_user_id ON ipa_ops.activity_log_ipa_assignment_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_inex_checklist_history_on_act; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_inex_checklist_history_on_act ON ipa_ops.activity_log_ipa_assignment_inex_checklist_history USING btree (activity_log_ipa_assignment_inex_checklist_id);


--
-- Name: index_activity_log_ipa_assignment_inex_checklist_history_on_ipa; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_inex_checklist_history_on_ipa ON ipa_ops.activity_log_ipa_assignment_inex_checklist_history USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_inex_checklist_history_on_mas; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_inex_checklist_history_on_mas ON ipa_ops.activity_log_ipa_assignment_inex_checklist_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_inex_checklist_history_on_use; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_inex_checklist_history_on_use ON ipa_ops.activity_log_ipa_assignment_inex_checklist_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_inex_checklists_on_ipa_assign; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_inex_checklists_on_ipa_assign ON ipa_ops.activity_log_ipa_assignment_inex_checklists USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_inex_checklists_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_inex_checklists_on_master_id ON ipa_ops.activity_log_ipa_assignment_inex_checklists USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_inex_checklists_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_inex_checklists_on_user_id ON ipa_ops.activity_log_ipa_assignment_inex_checklists USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviation_history_on_ac; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_ac ON ipa_ops.activity_log_ipa_assignment_minor_deviation_history USING btree (activity_log_ipa_assignment_minor_deviation_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviation_history_on_ip; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_ip ON ipa_ops.activity_log_ipa_assignment_minor_deviation_history USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviation_history_on_ma; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_ma ON ipa_ops.activity_log_ipa_assignment_minor_deviation_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviation_history_on_us; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_us ON ipa_ops.activity_log_ipa_assignment_minor_deviation_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviations_on_ipa_assig; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviations_on_ipa_assig ON ipa_ops.activity_log_ipa_assignment_minor_deviations USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviations_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviations_on_master_id ON ipa_ops.activity_log_ipa_assignment_minor_deviations USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_minor_deviations_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_minor_deviations_on_user_id ON ipa_ops.activity_log_ipa_assignment_minor_deviations USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_navigation_history_on_activit; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_navigation_history_on_activit ON ipa_ops.activity_log_ipa_assignment_navigation_history USING btree (activity_log_ipa_assignment_navigation_id);


--
-- Name: index_activity_log_ipa_assignment_navigation_history_on_ipa_ass; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_navigation_history_on_ipa_ass ON ipa_ops.activity_log_ipa_assignment_navigation_history USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_navigation_history_on_master_; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_navigation_history_on_master_ ON ipa_ops.activity_log_ipa_assignment_navigation_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_navigation_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_navigation_history_on_user_id ON ipa_ops.activity_log_ipa_assignment_navigation_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_navigations_on_ipa_assignment; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_navigations_on_ipa_assignment ON ipa_ops.activity_log_ipa_assignment_navigations USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_navigations_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_navigations_on_master_id ON ipa_ops.activity_log_ipa_assignment_navigations USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_navigations_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_navigations_on_user_id ON ipa_ops.activity_log_ipa_assignment_navigations USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_phone_screen_history_on_activ; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_phone_screen_history_on_activ ON ipa_ops.activity_log_ipa_assignment_phone_screen_history USING btree (activity_log_ipa_assignment_phone_screen_id);


--
-- Name: index_activity_log_ipa_assignment_phone_screen_history_on_ipa_a; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_phone_screen_history_on_ipa_a ON ipa_ops.activity_log_ipa_assignment_phone_screen_history USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_phone_screen_history_on_maste; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_phone_screen_history_on_maste ON ipa_ops.activity_log_ipa_assignment_phone_screen_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_phone_screen_history_on_user_; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_phone_screen_history_on_user_ ON ipa_ops.activity_log_ipa_assignment_phone_screen_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_phone_screens_on_ipa_assignme; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_phone_screens_on_ipa_assignme ON ipa_ops.activity_log_ipa_assignment_phone_screens USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_phone_screens_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_phone_screens_on_master_id ON ipa_ops.activity_log_ipa_assignment_phone_screens USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_phone_screens_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_phone_screens_on_user_id ON ipa_ops.activity_log_ipa_assignment_phone_screens USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_protocol_deviations_on_ipa_as; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_protocol_deviations_on_ipa_as ON ipa_ops.activity_log_ipa_assignment_protocol_deviations USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_protocol_deviations_on_master; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_protocol_deviations_on_master ON ipa_ops.activity_log_ipa_assignment_protocol_deviations USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_protocol_deviations_on_user_i; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_protocol_deviations_on_user_i ON ipa_ops.activity_log_ipa_assignment_protocol_deviations USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_session_filestores_on_ipa_ass; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_session_filestores_on_ipa_ass ON ipa_ops.activity_log_ipa_assignment_session_filestores USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_session_filestores_on_master_; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_session_filestores_on_master_ ON ipa_ops.activity_log_ipa_assignment_session_filestores USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_session_filestores_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_session_filestores_on_user_id ON ipa_ops.activity_log_ipa_assignment_session_filestores USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignments_on_ipa_assignment_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignments_on_ipa_assignment_id ON ipa_ops.activity_log_ipa_assignments USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignments_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignments_on_master_id ON ipa_ops.activity_log_ipa_assignments USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignments_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignments_on_user_id ON ipa_ops.activity_log_ipa_assignments USING btree (user_id);


--
-- Name: index_activity_log_ipa_screening_phone_screen_history_on_activi; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_screening_phone_screen_history_on_activi ON ipa_ops.activity_log_ipa_screening_phone_screen_history USING btree (activity_log_ipa_screening_phone_screen_id);


--
-- Name: index_activity_log_ipa_screening_phone_screen_history_on_ipa_sc; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_screening_phone_screen_history_on_ipa_sc ON ipa_ops.activity_log_ipa_screening_phone_screen_history USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_screening_phone_screen_history_on_master; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_screening_phone_screen_history_on_master ON ipa_ops.activity_log_ipa_screening_phone_screen_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_screening_phone_screen_history_on_user_i; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_screening_phone_screen_history_on_user_i ON ipa_ops.activity_log_ipa_screening_phone_screen_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_screening_phone_screens_on_ipa_screening; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_screening_phone_screens_on_ipa_screening ON ipa_ops.activity_log_ipa_screening_phone_screens USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_screening_phone_screens_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_screening_phone_screens_on_master_id ON ipa_ops.activity_log_ipa_screening_phone_screens USING btree (master_id);


--
-- Name: index_activity_log_ipa_screening_phone_screens_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_screening_phone_screens_on_user_id ON ipa_ops.activity_log_ipa_screening_phone_screens USING btree (user_id);


--
-- Name: index_activity_log_ipa_survey_history_on_activity_log_ipa_surve; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_survey_history_on_activity_log_ipa_surve ON ipa_ops.activity_log_ipa_survey_history USING btree (activity_log_ipa_survey_id);


--
-- Name: index_activity_log_ipa_survey_history_on_ipa_survey_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_survey_history_on_ipa_survey_id ON ipa_ops.activity_log_ipa_survey_history USING btree (ipa_survey_id);


--
-- Name: index_activity_log_ipa_survey_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_survey_history_on_master_id ON ipa_ops.activity_log_ipa_survey_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_survey_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_survey_history_on_user_id ON ipa_ops.activity_log_ipa_survey_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_surveys_on_ipa_survey_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_surveys_on_ipa_survey_id ON ipa_ops.activity_log_ipa_surveys USING btree (ipa_survey_id);


--
-- Name: index_activity_log_ipa_surveys_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_surveys_on_master_id ON ipa_ops.activity_log_ipa_surveys USING btree (master_id);


--
-- Name: index_activity_log_ipa_surveys_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_surveys_on_user_id ON ipa_ops.activity_log_ipa_surveys USING btree (user_id);


--
-- Name: index_al_ipa_assignment_adverse_event_history_on_activity_log_i; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_adverse_event_history_on_activity_log_i ON ipa_ops.activity_log_ipa_assignment_adverse_event_history USING btree (activity_log_ipa_assignment_adverse_event_id);


--
-- Name: index_al_ipa_assignment_adverse_event_history_on_ipa_assignment; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_adverse_event_history_on_ipa_assignment ON ipa_ops.activity_log_ipa_assignment_adverse_event_history USING btree (ipa_assignment_id);


--
-- Name: index_al_ipa_assignment_adverse_event_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_adverse_event_history_on_master_id ON ipa_ops.activity_log_ipa_assignment_adverse_event_history USING btree (master_id);


--
-- Name: index_al_ipa_assignment_adverse_event_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_adverse_event_history_on_user_id ON ipa_ops.activity_log_ipa_assignment_adverse_event_history USING btree (user_id);


--
-- Name: index_al_ipa_assignment_protocol_deviation_history_on_activity_; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_protocol_deviation_history_on_activity_ ON ipa_ops.activity_log_ipa_assignment_protocol_deviation_history USING btree (activity_log_ipa_assignment_protocol_deviation_id);


--
-- Name: index_al_ipa_assignment_protocol_deviation_history_on_ipa_assig; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_protocol_deviation_history_on_ipa_assig ON ipa_ops.activity_log_ipa_assignment_protocol_deviation_history USING btree (ipa_assignment_id);


--
-- Name: index_al_ipa_assignment_protocol_deviation_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_protocol_deviation_history_on_master_id ON ipa_ops.activity_log_ipa_assignment_protocol_deviation_history USING btree (master_id);


--
-- Name: index_al_ipa_assignment_protocol_deviation_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_protocol_deviation_history_on_user_id ON ipa_ops.activity_log_ipa_assignment_protocol_deviation_history USING btree (user_id);


--
-- Name: index_al_ipa_assignment_session_filestore_history_on_activity_l; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_session_filestore_history_on_activity_l ON ipa_ops.activity_log_ipa_assignment_session_filestore_history USING btree (activity_log_ipa_assignment_session_filestore_id);


--
-- Name: index_al_ipa_assignment_session_filestore_history_on_ipa_assign; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_session_filestore_history_on_ipa_assign ON ipa_ops.activity_log_ipa_assignment_session_filestore_history USING btree (ipa_assignment_id);


--
-- Name: index_al_ipa_assignment_session_filestore_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_session_filestore_history_on_master_id ON ipa_ops.activity_log_ipa_assignment_session_filestore_history USING btree (master_id);


--
-- Name: index_al_ipa_assignment_session_filestore_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_session_filestore_history_on_user_id ON ipa_ops.activity_log_ipa_assignment_session_filestore_history USING btree (user_id);


--
-- Name: index_emergency_contacts_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_emergency_contacts_on_master_id ON ipa_ops.emergency_contacts USING btree (master_id);


--
-- Name: index_emergency_contacts_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_emergency_contacts_on_user_id ON ipa_ops.emergency_contacts USING btree (user_id);


--
-- Name: index_ipa_adl_informant_screener_history_on_ipa_adl_informant_s; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_adl_informant_screener_history_on_ipa_adl_informant_s ON ipa_ops.ipa_adl_informant_screener_history USING btree (ipa_adl_informant_screener_id);


--
-- Name: index_ipa_adl_informant_screener_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_adl_informant_screener_history_on_master_id ON ipa_ops.ipa_adl_informant_screener_history USING btree (master_id);


--
-- Name: index_ipa_adl_informant_screener_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_adl_informant_screener_history_on_user_id ON ipa_ops.ipa_adl_informant_screener_history USING btree (user_id);


--
-- Name: index_ipa_adl_informant_screeners_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_adl_informant_screeners_on_master_id ON ipa_ops.ipa_adl_informant_screeners USING btree (master_id);


--
-- Name: index_ipa_adl_informant_screeners_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_adl_informant_screeners_on_user_id ON ipa_ops.ipa_adl_informant_screeners USING btree (user_id);


--
-- Name: index_ipa_adverse_event_history_on_ipa_adverse_event_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_adverse_event_history_on_ipa_adverse_event_id ON ipa_ops.ipa_adverse_event_history USING btree (ipa_adverse_event_id);


--
-- Name: index_ipa_adverse_event_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_adverse_event_history_on_master_id ON ipa_ops.ipa_adverse_event_history USING btree (master_id);


--
-- Name: index_ipa_adverse_event_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_adverse_event_history_on_user_id ON ipa_ops.ipa_adverse_event_history USING btree (user_id);


--
-- Name: index_ipa_adverse_events_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_adverse_events_on_master_id ON ipa_ops.ipa_adverse_events USING btree (master_id);


--
-- Name: index_ipa_adverse_events_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_adverse_events_on_user_id ON ipa_ops.ipa_adverse_events USING btree (user_id);


--
-- Name: index_ipa_appointment_history_on_ipa_appointment_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_appointment_history_on_ipa_appointment_id ON ipa_ops.ipa_appointment_history USING btree (ipa_appointment_id);


--
-- Name: index_ipa_appointment_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_appointment_history_on_master_id ON ipa_ops.ipa_appointment_history USING btree (master_id);


--
-- Name: index_ipa_appointment_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_appointment_history_on_user_id ON ipa_ops.ipa_appointment_history USING btree (user_id);


--
-- Name: index_ipa_appointments_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_appointments_on_master_id ON ipa_ops.ipa_appointments USING btree (master_id);


--
-- Name: index_ipa_appointments_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_appointments_on_user_id ON ipa_ops.ipa_appointments USING btree (user_id);


--
-- Name: index_ipa_assignment_history_on_admin_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_admin_id ON ipa_ops.ipa_assignment_history USING btree (admin_id);


--
-- Name: index_ipa_assignment_history_on_ipa_assignment_table_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_ipa_assignment_table_id ON ipa_ops.ipa_assignment_history USING btree (ipa_assignment_table_id);


--
-- Name: index_ipa_assignment_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_master_id ON ipa_ops.ipa_assignment_history USING btree (master_id);


--
-- Name: index_ipa_assignment_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_user_id ON ipa_ops.ipa_assignment_history USING btree (user_id);


--
-- Name: index_ipa_consent_mailing_history_on_ipa_consent_mailing_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_consent_mailing_history_on_ipa_consent_mailing_id ON ipa_ops.ipa_consent_mailing_history USING btree (ipa_consent_mailing_id);


--
-- Name: index_ipa_consent_mailing_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_consent_mailing_history_on_master_id ON ipa_ops.ipa_consent_mailing_history USING btree (master_id);


--
-- Name: index_ipa_consent_mailing_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_consent_mailing_history_on_user_id ON ipa_ops.ipa_consent_mailing_history USING btree (user_id);


--
-- Name: index_ipa_consent_mailings_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_consent_mailings_on_master_id ON ipa_ops.ipa_consent_mailings USING btree (master_id);


--
-- Name: index_ipa_consent_mailings_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_consent_mailings_on_user_id ON ipa_ops.ipa_consent_mailings USING btree (user_id);


--
-- Name: index_ipa_hotel_history_on_ipa_hotel_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_hotel_history_on_ipa_hotel_id ON ipa_ops.ipa_hotel_history USING btree (ipa_hotel_id);


--
-- Name: index_ipa_hotel_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_hotel_history_on_master_id ON ipa_ops.ipa_hotel_history USING btree (master_id);


--
-- Name: index_ipa_hotel_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_hotel_history_on_user_id ON ipa_ops.ipa_hotel_history USING btree (user_id);


--
-- Name: index_ipa_hotels_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_hotels_on_master_id ON ipa_ops.ipa_hotels USING btree (master_id);


--
-- Name: index_ipa_hotels_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_hotels_on_user_id ON ipa_ops.ipa_hotels USING btree (user_id);


--
-- Name: index_ipa_inex_checklist_history_on_ipa_inex_checklist_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_inex_checklist_history_on_ipa_inex_checklist_id ON ipa_ops.ipa_inex_checklist_history USING btree (ipa_inex_checklist_id);


--
-- Name: index_ipa_inex_checklist_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_inex_checklist_history_on_master_id ON ipa_ops.ipa_inex_checklist_history USING btree (master_id);


--
-- Name: index_ipa_inex_checklist_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_inex_checklist_history_on_user_id ON ipa_ops.ipa_inex_checklist_history USING btree (user_id);


--
-- Name: index_ipa_inex_checklists_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_inex_checklists_on_master_id ON ipa_ops.ipa_inex_checklists USING btree (master_id);


--
-- Name: index_ipa_inex_checklists_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_inex_checklists_on_user_id ON ipa_ops.ipa_inex_checklists USING btree (user_id);


--
-- Name: index_ipa_initial_screening_history_on_ipa_initial_screening_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_initial_screening_history_on_ipa_initial_screening_id ON ipa_ops.ipa_initial_screening_history USING btree (ipa_initial_screening_id);


--
-- Name: index_ipa_initial_screening_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_initial_screening_history_on_master_id ON ipa_ops.ipa_initial_screening_history USING btree (master_id);


--
-- Name: index_ipa_initial_screening_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_initial_screening_history_on_user_id ON ipa_ops.ipa_initial_screening_history USING btree (user_id);


--
-- Name: index_ipa_initial_screenings_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_initial_screenings_on_master_id ON ipa_ops.ipa_initial_screenings USING btree (master_id);


--
-- Name: index_ipa_initial_screenings_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_initial_screenings_on_user_id ON ipa_ops.ipa_initial_screenings USING btree (user_id);


--
-- Name: index_ipa_payment_history_on_ipa_payment_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_payment_history_on_ipa_payment_id ON ipa_ops.ipa_payment_history USING btree (ipa_payment_id);


--
-- Name: index_ipa_payment_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_payment_history_on_master_id ON ipa_ops.ipa_payment_history USING btree (master_id);


--
-- Name: index_ipa_payment_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_payment_history_on_user_id ON ipa_ops.ipa_payment_history USING btree (user_id);


--
-- Name: index_ipa_payments_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_payments_on_master_id ON ipa_ops.ipa_payments USING btree (master_id);


--
-- Name: index_ipa_payments_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_payments_on_user_id ON ipa_ops.ipa_payments USING btree (user_id);


--
-- Name: index_ipa_protocol_deviation_history_on_ipa_protocol_deviation_; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_protocol_deviation_history_on_ipa_protocol_deviation_ ON ipa_ops.ipa_protocol_deviation_history USING btree (ipa_protocol_deviation_id);


--
-- Name: index_ipa_protocol_deviation_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_protocol_deviation_history_on_master_id ON ipa_ops.ipa_protocol_deviation_history USING btree (master_id);


--
-- Name: index_ipa_protocol_deviation_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_protocol_deviation_history_on_user_id ON ipa_ops.ipa_protocol_deviation_history USING btree (user_id);


--
-- Name: index_ipa_protocol_deviations_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_protocol_deviations_on_master_id ON ipa_ops.ipa_protocol_deviations USING btree (master_id);


--
-- Name: index_ipa_protocol_deviations_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_protocol_deviations_on_user_id ON ipa_ops.ipa_protocol_deviations USING btree (user_id);


--
-- Name: index_ipa_ps_football_experience_history_on_ipa_ps_football_exp; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_football_experience_history_on_ipa_ps_football_exp ON ipa_ops.ipa_ps_football_experience_history USING btree (ipa_ps_football_experience_id);


--
-- Name: index_ipa_ps_football_experience_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_football_experience_history_on_master_id ON ipa_ops.ipa_ps_football_experience_history USING btree (master_id);


--
-- Name: index_ipa_ps_football_experience_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_football_experience_history_on_user_id ON ipa_ops.ipa_ps_football_experience_history USING btree (user_id);


--
-- Name: index_ipa_ps_football_experiences_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_football_experiences_on_master_id ON ipa_ops.ipa_ps_football_experiences USING btree (master_id);


--
-- Name: index_ipa_ps_football_experiences_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_football_experiences_on_user_id ON ipa_ops.ipa_ps_football_experiences USING btree (user_id);


--
-- Name: index_ipa_ps_health_history_on_ipa_ps_health_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_health_history_on_ipa_ps_health_id ON ipa_ops.ipa_ps_health_history USING btree (ipa_ps_health_id);


--
-- Name: index_ipa_ps_health_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_health_history_on_master_id ON ipa_ops.ipa_ps_health_history USING btree (master_id);


--
-- Name: index_ipa_ps_health_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_health_history_on_user_id ON ipa_ops.ipa_ps_health_history USING btree (user_id);


--
-- Name: index_ipa_ps_healths_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_healths_on_master_id ON ipa_ops.ipa_ps_healths USING btree (master_id);


--
-- Name: index_ipa_ps_healths_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_healths_on_user_id ON ipa_ops.ipa_ps_healths USING btree (user_id);


--
-- Name: index_ipa_ps_initial_screening_history_on_ipa_ps_initial_screen; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_initial_screening_history_on_ipa_ps_initial_screen ON ipa_ops.ipa_ps_initial_screening_history USING btree (ipa_ps_initial_screening_id);


--
-- Name: index_ipa_ps_initial_screening_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_initial_screening_history_on_master_id ON ipa_ops.ipa_ps_initial_screening_history USING btree (master_id);


--
-- Name: index_ipa_ps_initial_screening_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_initial_screening_history_on_user_id ON ipa_ops.ipa_ps_initial_screening_history USING btree (user_id);


--
-- Name: index_ipa_ps_initial_screenings_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_initial_screenings_on_master_id ON ipa_ops.ipa_ps_initial_screenings USING btree (master_id);


--
-- Name: index_ipa_ps_initial_screenings_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_initial_screenings_on_user_id ON ipa_ops.ipa_ps_initial_screenings USING btree (user_id);


--
-- Name: index_ipa_ps_mri_history_on_ipa_ps_mri_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_mri_history_on_ipa_ps_mri_id ON ipa_ops.ipa_ps_mri_history USING btree (ipa_ps_mri_id);


--
-- Name: index_ipa_ps_mri_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_mri_history_on_master_id ON ipa_ops.ipa_ps_mri_history USING btree (master_id);


--
-- Name: index_ipa_ps_mri_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_mri_history_on_user_id ON ipa_ops.ipa_ps_mri_history USING btree (user_id);


--
-- Name: index_ipa_ps_mris_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_mris_on_master_id ON ipa_ops.ipa_ps_mris USING btree (master_id);


--
-- Name: index_ipa_ps_mris_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_mris_on_user_id ON ipa_ops.ipa_ps_mris USING btree (user_id);


--
-- Name: index_ipa_ps_size_history_on_ipa_ps_size_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_size_history_on_ipa_ps_size_id ON ipa_ops.ipa_ps_size_history USING btree (ipa_ps_size_id);


--
-- Name: index_ipa_ps_size_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_size_history_on_master_id ON ipa_ops.ipa_ps_size_history USING btree (master_id);


--
-- Name: index_ipa_ps_size_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_size_history_on_user_id ON ipa_ops.ipa_ps_size_history USING btree (user_id);


--
-- Name: index_ipa_ps_sizes_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_sizes_on_master_id ON ipa_ops.ipa_ps_sizes USING btree (master_id);


--
-- Name: index_ipa_ps_sizes_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_sizes_on_user_id ON ipa_ops.ipa_ps_sizes USING btree (user_id);


--
-- Name: index_ipa_ps_sleep_history_on_ipa_ps_sleep_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_sleep_history_on_ipa_ps_sleep_id ON ipa_ops.ipa_ps_sleep_history USING btree (ipa_ps_sleep_id);


--
-- Name: index_ipa_ps_sleep_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_sleep_history_on_master_id ON ipa_ops.ipa_ps_sleep_history USING btree (master_id);


--
-- Name: index_ipa_ps_sleep_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_sleep_history_on_user_id ON ipa_ops.ipa_ps_sleep_history USING btree (user_id);


--
-- Name: index_ipa_ps_sleeps_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_sleeps_on_master_id ON ipa_ops.ipa_ps_sleeps USING btree (master_id);


--
-- Name: index_ipa_ps_sleeps_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_sleeps_on_user_id ON ipa_ops.ipa_ps_sleeps USING btree (user_id);


--
-- Name: index_ipa_ps_tmoca_history_on_ipa_ps_tmoca_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_tmoca_history_on_ipa_ps_tmoca_id ON ipa_ops.ipa_ps_tmoca_history USING btree (ipa_ps_tmoca_id);


--
-- Name: index_ipa_ps_tmoca_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_tmoca_history_on_master_id ON ipa_ops.ipa_ps_tmoca_history USING btree (master_id);


--
-- Name: index_ipa_ps_tmoca_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_tmoca_history_on_user_id ON ipa_ops.ipa_ps_tmoca_history USING btree (user_id);


--
-- Name: index_ipa_ps_tmocas_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_tmocas_on_master_id ON ipa_ops.ipa_ps_tmocas USING btree (master_id);


--
-- Name: index_ipa_ps_tmocas_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_tmocas_on_user_id ON ipa_ops.ipa_ps_tmocas USING btree (user_id);


--
-- Name: index_ipa_ps_tms_test_history_on_ipa_ps_tms_test_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_tms_test_history_on_ipa_ps_tms_test_id ON ipa_ops.ipa_ps_tms_test_history USING btree (ipa_ps_tms_test_id);


--
-- Name: index_ipa_ps_tms_test_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_tms_test_history_on_master_id ON ipa_ops.ipa_ps_tms_test_history USING btree (master_id);


--
-- Name: index_ipa_ps_tms_test_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_tms_test_history_on_user_id ON ipa_ops.ipa_ps_tms_test_history USING btree (user_id);


--
-- Name: index_ipa_ps_tms_tests_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_tms_tests_on_master_id ON ipa_ops.ipa_ps_tms_tests USING btree (master_id);


--
-- Name: index_ipa_ps_tms_tests_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_tms_tests_on_user_id ON ipa_ops.ipa_ps_tms_tests USING btree (user_id);


--
-- Name: index_ipa_recruitment_history_on_ipa_recruitment_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_recruitment_history_on_ipa_recruitment_id ON ipa_ops.ipa_recruitment_history USING btree (ipa_recruitment_id);


--
-- Name: index_ipa_recruitment_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_recruitment_history_on_master_id ON ipa_ops.ipa_recruitment_history USING btree (master_id);


--
-- Name: index_ipa_recruitment_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_recruitment_history_on_user_id ON ipa_ops.ipa_recruitment_history USING btree (user_id);


--
-- Name: index_ipa_screening_history_on_ipa_screening_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_screening_history_on_ipa_screening_id ON ipa_ops.ipa_screening_history USING btree (ipa_screening_id);


--
-- Name: index_ipa_screening_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_screening_history_on_master_id ON ipa_ops.ipa_screening_history USING btree (master_id);


--
-- Name: index_ipa_screening_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_screening_history_on_user_id ON ipa_ops.ipa_screening_history USING btree (user_id);


--
-- Name: index_ipa_screenings_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_screenings_on_master_id ON ipa_ops.ipa_screenings USING btree (master_id);


--
-- Name: index_ipa_screenings_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_screenings_on_user_id ON ipa_ops.ipa_screenings USING btree (user_id);


--
-- Name: index_ipa_station_contact_history_on_ipa_station_contact_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_station_contact_history_on_ipa_station_contact_id ON ipa_ops.ipa_station_contact_history USING btree (ipa_station_contact_id);


--
-- Name: index_ipa_station_contact_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_station_contact_history_on_master_id ON ipa_ops.ipa_station_contact_history USING btree (master_id);


--
-- Name: index_ipa_station_contact_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_station_contact_history_on_user_id ON ipa_ops.ipa_station_contact_history USING btree (user_id);


--
-- Name: index_ipa_station_contacts_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_station_contacts_on_master_id ON ipa_ops.ipa_station_contacts USING btree (master_id);


--
-- Name: index_ipa_station_contacts_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_station_contacts_on_user_id ON ipa_ops.ipa_station_contacts USING btree (user_id);


--
-- Name: index_ipa_survey_history_on_ipa_survey_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_survey_history_on_ipa_survey_id ON ipa_ops.ipa_survey_history USING btree (ipa_survey_id);


--
-- Name: index_ipa_survey_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_survey_history_on_master_id ON ipa_ops.ipa_survey_history USING btree (master_id);


--
-- Name: index_ipa_survey_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_survey_history_on_user_id ON ipa_ops.ipa_survey_history USING btree (user_id);


--
-- Name: index_ipa_surveys_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_surveys_on_master_id ON ipa_ops.ipa_surveys USING btree (master_id);


--
-- Name: index_ipa_surveys_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_surveys_on_user_id ON ipa_ops.ipa_surveys USING btree (user_id);


--
-- Name: index_ipa_transportation_history_on_ipa_transportation_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_transportation_history_on_ipa_transportation_id ON ipa_ops.ipa_transportation_history USING btree (ipa_transportation_id);


--
-- Name: index_ipa_transportation_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_transportation_history_on_master_id ON ipa_ops.ipa_transportation_history USING btree (master_id);


--
-- Name: index_ipa_transportation_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_transportation_history_on_user_id ON ipa_ops.ipa_transportation_history USING btree (user_id);


--
-- Name: index_ipa_transportations_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_transportations_on_master_id ON ipa_ops.ipa_transportations USING btree (master_id);


--
-- Name: index_ipa_transportations_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_transportations_on_user_id ON ipa_ops.ipa_transportations USING btree (user_id);


--
-- Name: index_ipa_withdrawal_history_on_ipa_withdrawal_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_withdrawal_history_on_ipa_withdrawal_id ON ipa_ops.ipa_withdrawal_history USING btree (ipa_withdrawal_id);


--
-- Name: index_ipa_withdrawal_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_withdrawal_history_on_master_id ON ipa_ops.ipa_withdrawal_history USING btree (master_id);


--
-- Name: index_ipa_withdrawal_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_withdrawal_history_on_user_id ON ipa_ops.ipa_withdrawal_history USING btree (user_id);


--
-- Name: index_ipa_withdrawals_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_withdrawals_on_master_id ON ipa_ops.ipa_withdrawals USING btree (master_id);


--
-- Name: index_ipa_withdrawals_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_withdrawals_on_user_id ON ipa_ops.ipa_withdrawals USING btree (user_id);


--
-- Name: index_mrn_number_history_on_admin_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_mrn_number_history_on_admin_id ON ipa_ops.mrn_number_history USING btree (admin_id);


--
-- Name: index_mrn_number_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_mrn_number_history_on_master_id ON ipa_ops.mrn_number_history USING btree (master_id);


--
-- Name: index_mrn_number_history_on_mrn_number_table_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_mrn_number_history_on_mrn_number_table_id ON ipa_ops.mrn_number_history USING btree (mrn_number_table_id);


--
-- Name: index_mrn_number_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_mrn_number_history_on_user_id ON ipa_ops.mrn_number_history USING btree (user_id);


--
-- Name: index_mrn_numbers_on_admin_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_mrn_numbers_on_admin_id ON ipa_ops.mrn_numbers USING btree (admin_id);


--
-- Name: index_mrn_numbers_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_mrn_numbers_on_master_id ON ipa_ops.mrn_numbers USING btree (master_id);


--
-- Name: index_mrn_numbers_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_mrn_numbers_on_user_id ON ipa_ops.mrn_numbers USING btree (user_id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX delayed_jobs_priority ON ml_app.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_accuracy_score_history_on_accuracy_score_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_accuracy_score_history_on_accuracy_score_id ON ml_app.accuracy_score_history USING btree (accuracy_score_id);


--
-- Name: index_accuracy_scores_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_accuracy_scores_on_admin_id ON ml_app.accuracy_scores USING btree (admin_id);


--
-- Name: index_activity_log_bhs_assignment_history_on_activity_log_bhs_a; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignment_history_on_activity_log_bhs_a ON ml_app.activity_log_bhs_assignment_history USING btree (activity_log_bhs_assignment_id);


--
-- Name: index_activity_log_bhs_assignment_history_on_bhs_assignment_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignment_history_on_bhs_assignment_id ON ml_app.activity_log_bhs_assignment_history USING btree (bhs_assignment_id);


--
-- Name: index_activity_log_bhs_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignment_history_on_master_id ON ml_app.activity_log_bhs_assignment_history USING btree (master_id);


--
-- Name: index_activity_log_bhs_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignment_history_on_user_id ON ml_app.activity_log_bhs_assignment_history USING btree (user_id);


--
-- Name: index_activity_log_bhs_assignments_on_bhs_assignment_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignments_on_bhs_assignment_id ON ml_app.activity_log_bhs_assignments USING btree (bhs_assignment_id);


--
-- Name: index_activity_log_bhs_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignments_on_master_id ON ml_app.activity_log_bhs_assignments USING btree (master_id);


--
-- Name: index_activity_log_bhs_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_bhs_assignments_on_user_id ON ml_app.activity_log_bhs_assignments USING btree (user_id);


--
-- Name: index_activity_log_ext_assignment_history_on_activity_log_ext_a; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_ext_assignment_history_on_activity_log_ext_a ON ml_app.activity_log_ext_assignment_history USING btree (activity_log_ext_assignment_id);


--
-- Name: index_activity_log_ext_assignment_history_on_ext_assignment_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_ext_assignment_history_on_ext_assignment_id ON ml_app.activity_log_ext_assignment_history USING btree (ext_assignment_id);


--
-- Name: index_activity_log_ext_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_ext_assignment_history_on_master_id ON ml_app.activity_log_ext_assignment_history USING btree (master_id);


--
-- Name: index_activity_log_ext_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_ext_assignment_history_on_user_id ON ml_app.activity_log_ext_assignment_history USING btree (user_id);


--
-- Name: index_activity_log_ext_assignments_on_ext_assignment_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_ext_assignments_on_ext_assignment_id ON ml_app.activity_log_ext_assignments USING btree (ext_assignment_id);


--
-- Name: index_activity_log_ext_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_ext_assignments_on_master_id ON ml_app.activity_log_ext_assignments USING btree (master_id);


--
-- Name: index_activity_log_ext_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_ext_assignments_on_user_id ON ml_app.activity_log_ext_assignments USING btree (user_id);


--
-- Name: index_activity_log_history_on_activity_log_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_history_on_activity_log_id ON ml_app.activity_log_history USING btree (activity_log_id);


--
-- Name: index_activity_log_new_test_history_on_activity_log_new_test_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_new_test_history_on_activity_log_new_test_id ON ml_app.activity_log_new_test_history USING btree (activity_log_new_test_id);


--
-- Name: index_activity_log_new_test_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_new_test_history_on_master_id ON ml_app.activity_log_new_test_history USING btree (master_id);


--
-- Name: index_activity_log_new_test_history_on_new_test_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_new_test_history_on_new_test_id ON ml_app.activity_log_new_test_history USING btree (new_test_id);


--
-- Name: index_activity_log_new_test_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_new_test_history_on_user_id ON ml_app.activity_log_new_test_history USING btree (user_id);


--
-- Name: index_activity_log_new_tests_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_new_tests_on_master_id ON ml_app.activity_log_new_tests USING btree (master_id);


--
-- Name: index_activity_log_new_tests_on_new_test_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_new_tests_on_new_test_id ON ml_app.activity_log_new_tests USING btree (new_test_id);


--
-- Name: index_activity_log_new_tests_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_new_tests_on_user_id ON ml_app.activity_log_new_tests USING btree (user_id);


--
-- Name: index_activity_log_player_contact_emails_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_emails_on_master_id ON ml_app.activity_log_player_contact_emails USING btree (master_id);


--
-- Name: index_activity_log_player_contact_emails_on_player_contact_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_emails_on_player_contact_id ON ml_app.activity_log_player_contact_emails USING btree (player_contact_id);


--
-- Name: index_activity_log_player_contact_emails_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_emails_on_protocol_id ON ml_app.activity_log_player_contact_emails USING btree (protocol_id);


--
-- Name: index_activity_log_player_contact_emails_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_contact_emails_on_user_id ON ml_app.activity_log_player_contact_emails USING btree (user_id);


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
-- Name: index_activity_log_player_info_history_on_activity_log_player_i; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_info_history_on_activity_log_player_i ON ml_app.activity_log_player_info_history USING btree (activity_log_player_info_id);


--
-- Name: index_activity_log_player_info_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_info_history_on_master_id ON ml_app.activity_log_player_info_history USING btree (master_id);


--
-- Name: index_activity_log_player_info_history_on_player_info_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_info_history_on_player_info_id ON ml_app.activity_log_player_info_history USING btree (player_info_id);


--
-- Name: index_activity_log_player_info_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_info_history_on_user_id ON ml_app.activity_log_player_info_history USING btree (user_id);


--
-- Name: index_activity_log_player_infos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_infos_on_master_id ON ml_app.activity_log_player_infos USING btree (master_id);


--
-- Name: index_activity_log_player_infos_on_player_info_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_infos_on_player_info_id ON ml_app.activity_log_player_infos USING btree (player_info_id);


--
-- Name: index_activity_log_player_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_activity_log_player_infos_on_user_id ON ml_app.activity_log_player_infos USING btree (user_id);


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
-- Name: index_app_types_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_app_types_on_admin_id ON ml_app.app_types USING btree (admin_id);


--
-- Name: index_bhs_assignment_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_bhs_assignment_history_on_admin_id ON ml_app.bhs_assignment_history USING btree (admin_id);


--
-- Name: index_bhs_assignment_history_on_bhs_assignment_table_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_bhs_assignment_history_on_bhs_assignment_table_id ON ml_app.bhs_assignment_history USING btree (bhs_assignment_table_id);


--
-- Name: index_bhs_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_bhs_assignment_history_on_master_id ON ml_app.bhs_assignment_history USING btree (master_id);


--
-- Name: index_bhs_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_bhs_assignment_history_on_user_id ON ml_app.bhs_assignment_history USING btree (user_id);


--
-- Name: index_bhs_assignments_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_bhs_assignments_on_admin_id ON ml_app.bhs_assignments USING btree (admin_id);


--
-- Name: index_bhs_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_bhs_assignments_on_master_id ON ml_app.bhs_assignments USING btree (master_id);


--
-- Name: index_bhs_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_bhs_assignments_on_user_id ON ml_app.bhs_assignments USING btree (user_id);


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
-- Name: index_ext_assignment_history_on_ext_assignment_table_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_assignment_history_on_ext_assignment_table_id ON ml_app.ext_assignment_history USING btree (ext_assignment_table_id);


--
-- Name: index_ext_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_assignment_history_on_master_id ON ml_app.ext_assignment_history USING btree (master_id);


--
-- Name: index_ext_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_assignment_history_on_user_id ON ml_app.ext_assignment_history USING btree (user_id);


--
-- Name: index_ext_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_assignments_on_master_id ON ml_app.ext_assignments USING btree (master_id);


--
-- Name: index_ext_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_assignments_on_user_id ON ml_app.ext_assignments USING btree (user_id);


--
-- Name: index_ext_gen_assignment_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_gen_assignment_history_on_admin_id ON ml_app.ext_gen_assignment_history USING btree (admin_id);


--
-- Name: index_ext_gen_assignment_history_on_ext_gen_assignment_table_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_gen_assignment_history_on_ext_gen_assignment_table_id ON ml_app.ext_gen_assignment_history USING btree (ext_gen_assignment_table_id);


--
-- Name: index_ext_gen_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_gen_assignment_history_on_master_id ON ml_app.ext_gen_assignment_history USING btree (master_id);


--
-- Name: index_ext_gen_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_gen_assignment_history_on_user_id ON ml_app.ext_gen_assignment_history USING btree (user_id);


--
-- Name: index_ext_gen_assignments_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_gen_assignments_on_admin_id ON ml_app.ext_gen_assignments USING btree (admin_id);


--
-- Name: index_ext_gen_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_gen_assignments_on_master_id ON ml_app.ext_gen_assignments USING btree (master_id);


--
-- Name: index_ext_gen_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ext_gen_assignments_on_user_id ON ml_app.ext_gen_assignments USING btree (user_id);


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
-- Name: index_imports_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_imports_on_user_id ON ml_app.imports USING btree (user_id);


--
-- Name: index_ipa_assignment_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_admin_id ON ml_app.ipa_assignment_history USING btree (admin_id);


--
-- Name: index_ipa_assignment_history_on_ipa_assignment_table_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_ipa_assignment_table_id ON ml_app.ipa_assignment_history USING btree (ipa_assignment_table_id);


--
-- Name: index_ipa_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_master_id ON ml_app.ipa_assignment_history USING btree (master_id);


--
-- Name: index_ipa_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ipa_assignment_history_on_user_id ON ml_app.ipa_assignment_history USING btree (user_id);


--
-- Name: index_ipa_assignments_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ipa_assignments_on_admin_id ON ml_app.ipa_assignments USING btree (admin_id);


--
-- Name: index_ipa_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ipa_assignments_on_master_id ON ml_app.ipa_assignments USING btree (master_id);


--
-- Name: index_ipa_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_ipa_assignments_on_user_id ON ml_app.ipa_assignments USING btree (user_id);


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
-- Name: index_json_doc_history_on_json_doc_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_json_doc_history_on_json_doc_id ON ml_app.json_doc_history USING btree (json_doc_id);


--
-- Name: index_json_doc_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_json_doc_history_on_master_id ON ml_app.json_doc_history USING btree (master_id);


--
-- Name: index_json_doc_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_json_doc_history_on_user_id ON ml_app.json_doc_history USING btree (user_id);


--
-- Name: index_json_docs_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_json_docs_on_master_id ON ml_app.json_docs USING btree (master_id);


--
-- Name: index_json_docs_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_json_docs_on_user_id ON ml_app.json_docs USING btree (user_id);


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
-- Name: index_new_test_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_new_test_history_on_admin_id ON ml_app.new_test_history USING btree (admin_id);


--
-- Name: index_new_test_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_new_test_history_on_master_id ON ml_app.new_test_history USING btree (master_id);


--
-- Name: index_new_test_history_on_new_test_table_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_new_test_history_on_new_test_table_id ON ml_app.new_test_history USING btree (new_test_table_id);


--
-- Name: index_new_test_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_new_test_history_on_user_id ON ml_app.new_test_history USING btree (user_id);


--
-- Name: index_new_tests_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_new_tests_on_admin_id ON ml_app.new_tests USING btree (admin_id);


--
-- Name: index_new_tests_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_new_tests_on_master_id ON ml_app.new_tests USING btree (master_id);


--
-- Name: index_new_tests_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_new_tests_on_user_id ON ml_app.new_tests USING btree (user_id);


--
-- Name: index_nfs_store_archived_files_on_nfs_store_container_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_archived_files_on_nfs_store_container_id ON ml_app.nfs_store_archived_files USING btree (nfs_store_container_id);


--
-- Name: index_nfs_store_containers_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_containers_on_master_id ON ml_app.nfs_store_containers USING btree (master_id);


--
-- Name: index_nfs_store_containers_on_nfs_store_container_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_containers_on_nfs_store_container_id ON ml_app.nfs_store_containers USING btree (nfs_store_container_id);


--
-- Name: index_nfs_store_stored_files_on_nfs_store_container_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_nfs_store_stored_files_on_nfs_store_container_id ON ml_app.nfs_store_stored_files USING btree (nfs_store_container_id);


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
-- Name: index_report_history_on_report_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_report_history_on_report_id ON ml_app.report_history USING btree (report_id);


--
-- Name: index_reports_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_reports_on_admin_id ON ml_app.reports USING btree (admin_id);


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
-- Name: index_sage_two_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sage_two_history_on_master_id ON ml_app.sage_two_history USING btree (master_id);


--
-- Name: index_sage_two_history_on_sage_two_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sage_two_history_on_sage_two_id ON ml_app.sage_two_history USING btree (sage_two_id);


--
-- Name: index_sage_two_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sage_two_history_on_user_id ON ml_app.sage_two_history USING btree (user_id);


--
-- Name: index_sage_twos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sage_twos_on_master_id ON ml_app.sage_twos USING btree (master_id);


--
-- Name: index_sage_twos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_sage_twos_on_user_id ON ml_app.sage_twos USING btree (user_id);


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
-- Name: index_scantron_series_two_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantron_series_two_history_on_master_id ON ml_app.scantron_series_two_history USING btree (master_id);


--
-- Name: index_scantron_series_two_history_on_scantron_series_two_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantron_series_two_history_on_scantron_series_two_id ON ml_app.scantron_series_two_history USING btree (scantron_series_two_id);


--
-- Name: index_scantron_series_two_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantron_series_two_history_on_user_id ON ml_app.scantron_series_two_history USING btree (user_id);


--
-- Name: index_scantron_series_twos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantron_series_twos_on_master_id ON ml_app.scantron_series_twos USING btree (master_id);


--
-- Name: index_scantron_series_twos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantron_series_twos_on_user_id ON ml_app.scantron_series_twos USING btree (user_id);


--
-- Name: index_scantrons_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantrons_on_master_id ON ml_app.scantrons USING btree (master_id);


--
-- Name: index_scantrons_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_scantrons_on_user_id ON ml_app.scantrons USING btree (user_id);


--
-- Name: index_social_security_number_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_social_security_number_history_on_admin_id ON ml_app.social_security_number_history USING btree (admin_id);


--
-- Name: index_social_security_number_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_social_security_number_history_on_master_id ON ml_app.social_security_number_history USING btree (master_id);


--
-- Name: index_social_security_number_history_on_social_security_number_; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_social_security_number_history_on_social_security_number_ ON ml_app.social_security_number_history USING btree (social_security_number_table_id);


--
-- Name: index_social_security_number_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_social_security_number_history_on_user_id ON ml_app.social_security_number_history USING btree (user_id);


--
-- Name: index_social_security_numbers_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_social_security_numbers_on_admin_id ON ml_app.social_security_numbers USING btree (admin_id);


--
-- Name: index_social_security_numbers_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_social_security_numbers_on_master_id ON ml_app.social_security_numbers USING btree (master_id);


--
-- Name: index_social_security_numbers_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_social_security_numbers_on_user_id ON ml_app.social_security_numbers USING btree (user_id);


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
-- Name: index_test1_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test1_history_on_admin_id ON ml_app.test1_history USING btree (admin_id);


--
-- Name: index_test1_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test1_history_on_master_id ON ml_app.test1_history USING btree (master_id);


--
-- Name: index_test1_history_on_test1_table_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test1_history_on_test1_table_id ON ml_app.test1_history USING btree (test1_table_id);


--
-- Name: index_test1_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test1_history_on_user_id ON ml_app.test1_history USING btree (user_id);


--
-- Name: index_test1s_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test1s_on_admin_id ON ml_app.test1s USING btree (admin_id);


--
-- Name: index_test1s_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test1s_on_master_id ON ml_app.test1s USING btree (master_id);


--
-- Name: index_test1s_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test1s_on_user_id ON ml_app.test1s USING btree (user_id);


--
-- Name: index_test2_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test2_history_on_admin_id ON ml_app.test2_history USING btree (admin_id);


--
-- Name: index_test2_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test2_history_on_master_id ON ml_app.test2_history USING btree (master_id);


--
-- Name: index_test2_history_on_test2_table_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test2_history_on_test2_table_id ON ml_app.test2_history USING btree (test2_table_id);


--
-- Name: index_test2_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test2_history_on_user_id ON ml_app.test2_history USING btree (user_id);


--
-- Name: index_test2s_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test2s_on_admin_id ON ml_app.test2s USING btree (admin_id);


--
-- Name: index_test2s_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test2s_on_master_id ON ml_app.test2s USING btree (master_id);


--
-- Name: index_test2s_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test2s_on_user_id ON ml_app.test2s USING btree (user_id);


--
-- Name: index_test_2_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_2_history_on_admin_id ON ml_app.test_2_history USING btree (admin_id);


--
-- Name: index_test_2_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_2_history_on_master_id ON ml_app.test_2_history USING btree (master_id);


--
-- Name: index_test_2_history_on_test_2_table_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_2_history_on_test_2_table_id ON ml_app.test_2_history USING btree (test_2_table_id);


--
-- Name: index_test_2_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_2_history_on_user_id ON ml_app.test_2_history USING btree (user_id);


--
-- Name: index_test_2s_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_2s_on_admin_id ON ml_app.test_2s USING btree (admin_id);


--
-- Name: index_test_2s_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_2s_on_master_id ON ml_app.test_2s USING btree (master_id);


--
-- Name: index_test_2s_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_2s_on_user_id ON ml_app.test_2s USING btree (user_id);


--
-- Name: index_test_ext2_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_ext2_history_on_master_id ON ml_app.test_ext2_history USING btree (master_id);


--
-- Name: index_test_ext2_history_on_test_ext2_table_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_ext2_history_on_test_ext2_table_id ON ml_app.test_ext2_history USING btree (test_ext2_table_id);


--
-- Name: index_test_ext2_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_ext2_history_on_user_id ON ml_app.test_ext2_history USING btree (user_id);


--
-- Name: index_test_ext2s_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_ext2s_on_master_id ON ml_app.test_ext2s USING btree (master_id);


--
-- Name: index_test_ext2s_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_ext2s_on_user_id ON ml_app.test_ext2s USING btree (user_id);


--
-- Name: index_test_ext_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_ext_history_on_master_id ON ml_app.test_ext_history USING btree (master_id);


--
-- Name: index_test_ext_history_on_test_ext_table_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_ext_history_on_test_ext_table_id ON ml_app.test_ext_history USING btree (test_ext_table_id);


--
-- Name: index_test_ext_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_ext_history_on_user_id ON ml_app.test_ext_history USING btree (user_id);


--
-- Name: index_test_exts_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_exts_on_master_id ON ml_app.test_exts USING btree (master_id);


--
-- Name: index_test_exts_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_exts_on_user_id ON ml_app.test_exts USING btree (user_id);


--
-- Name: index_test_item_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_item_history_on_master_id ON ml_app.test_item_history USING btree (master_id);


--
-- Name: index_test_item_history_on_test_item_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_item_history_on_test_item_id ON ml_app.test_item_history USING btree (test_item_id);


--
-- Name: index_test_item_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_item_history_on_user_id ON ml_app.test_item_history USING btree (user_id);


--
-- Name: index_test_items_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_items_on_master_id ON ml_app.test_items USING btree (master_id);


--
-- Name: index_test_items_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_test_items_on_user_id ON ml_app.test_items USING btree (user_id);


--
-- Name: index_testing_dl_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_testing_dl_history_on_master_id ON ml_app.testing_dl_history USING btree (master_id);


--
-- Name: index_testing_dl_history_on_testing_dl_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_testing_dl_history_on_testing_dl_id ON ml_app.testing_dl_history USING btree (testing_dl_id);


--
-- Name: index_testing_dl_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_testing_dl_history_on_user_id ON ml_app.testing_dl_history USING btree (user_id);


--
-- Name: index_testing_dls_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_testing_dls_on_master_id ON ml_app.testing_dls USING btree (master_id);


--
-- Name: index_testing_dls_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_testing_dls_on_user_id ON ml_app.testing_dls USING btree (user_id);


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
-- Name: index_user_history_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_history_on_app_type_id ON ml_app.user_history USING btree (app_type_id);


--
-- Name: index_user_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_history_on_user_id ON ml_app.user_history USING btree (user_id);


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
-- Name: index_users_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_users_on_admin_id ON ml_app.users USING btree (admin_id);


--
-- Name: index_users_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_users_on_app_type_id ON ml_app.users USING btree (app_type_id);


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

CREATE UNIQUE INDEX nfs_store_stored_files_unique_file ON ml_app.nfs_store_stored_files USING btree (nfs_store_container_id, file_hash, file_name);


--
-- Name: nfs_store_uploads_unique_file; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX nfs_store_uploads_unique_file ON ml_app.nfs_store_uploads USING btree (nfs_store_container_id, file_hash, file_name);


--
-- Name: unique_master_protocol; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX unique_master_protocol ON ml_app.trackers USING btree (master_id, protocol_id);


--
-- Name: unique_master_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX unique_master_protocol_id ON ml_app.trackers USING btree (master_id, protocol_id, id);


--
-- Name: unique_protocol_and_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX unique_protocol_and_id ON ml_app.sub_processes USING btree (protocol_id, id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON ml_app.schema_migrations USING btree (version);


--
-- Name: unique_sub_process_and_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE UNIQUE INDEX unique_sub_process_and_id ON ml_app.protocol_events USING btree (sub_process_id, id);


--
-- Name: activity_log_ipa_assignment_adverse_event_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_adverse_event_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_adverse_events FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_adverse_event_update();


--
-- Name: activity_log_ipa_assignment_adverse_event_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_adverse_event_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_adverse_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_adverse_event_update();


--
-- Name: activity_log_ipa_assignment_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_update();


--
-- Name: activity_log_ipa_assignment_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_update();


--
-- Name: activity_log_ipa_assignment_inex_checklist_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_inex_checklist_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_inex_checklists FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_inex_checklist_update();


--
-- Name: activity_log_ipa_assignment_inex_checklist_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_inex_checklist_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_inex_checklists FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_inex_checklist_update();


--
-- Name: activity_log_ipa_assignment_minor_deviation_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_minor_deviation_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_minor_deviations FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_minor_deviation_update();


--
-- Name: activity_log_ipa_assignment_minor_deviation_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_minor_deviation_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_minor_deviations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_minor_deviation_update();


--
-- Name: activity_log_ipa_assignment_navigation_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_navigation_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_navigations FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_navigation_update();


--
-- Name: activity_log_ipa_assignment_navigation_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_navigation_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_navigations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_navigation_update();


--
-- Name: activity_log_ipa_assignment_phone_screen_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_phone_screen_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_phone_screens FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_phone_screen_update();


--
-- Name: activity_log_ipa_assignment_phone_screen_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_phone_screen_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_phone_screens FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_phone_screen_update();


--
-- Name: activity_log_ipa_assignment_protocol_deviation_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_protocol_deviation_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_protocol_deviations FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_protocol_deviation_update();


--
-- Name: activity_log_ipa_assignment_protocol_deviation_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_protocol_deviation_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_protocol_deviations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_ipa_assignment_protocol_deviation_update();


--
-- Name: activity_log_ipa_assignment_session_filestore_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_session_filestore_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_session_filestores FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_session_filestore_update();


--
-- Name: activity_log_ipa_assignment_session_filestore_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_session_filestore_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_session_filestores FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_session_filestore_update();


--
-- Name: activity_log_ipa_screening_phone_screen_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_screening_phone_screen_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_screening_phone_screens FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_ipa_screening_phone_screen_update();


--
-- Name: activity_log_ipa_screening_phone_screen_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_screening_phone_screen_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_screening_phone_screens FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_ipa_screening_phone_screen_update();


--
-- Name: activity_log_ipa_survey_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_survey_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_surveys FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_ipa_survey_update();


--
-- Name: activity_log_ipa_survey_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_survey_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_surveys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_ipa_survey_update();


--
-- Name: ipa_adl_informant_screener_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_adl_informant_screener_history_insert AFTER INSERT ON ipa_ops.ipa_adl_informant_screeners FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_adl_informant_screener_update();


--
-- Name: ipa_adl_informant_screener_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_adl_informant_screener_history_update AFTER UPDATE ON ipa_ops.ipa_adl_informant_screeners FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_adl_informant_screener_update();


--
-- Name: ipa_adverse_event_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_adverse_event_history_insert AFTER INSERT ON ipa_ops.ipa_adverse_events FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_adverse_event_update();


--
-- Name: ipa_adverse_event_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_adverse_event_history_update AFTER UPDATE ON ipa_ops.ipa_adverse_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_adverse_event_update();


--
-- Name: ipa_appointment_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_appointment_history_insert AFTER INSERT ON ipa_ops.ipa_appointments FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_appointment_update();


--
-- Name: ipa_appointment_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_appointment_history_update AFTER UPDATE ON ipa_ops.ipa_appointments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_appointment_update();


--
-- Name: ipa_consent_mailing_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_consent_mailing_history_insert AFTER INSERT ON ipa_ops.ipa_consent_mailings FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_consent_mailing_update();


--
-- Name: ipa_consent_mailing_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_consent_mailing_history_update AFTER UPDATE ON ipa_ops.ipa_consent_mailings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_consent_mailing_update();


--
-- Name: ipa_hotel_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_hotel_history_insert AFTER INSERT ON ipa_ops.ipa_hotels FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_hotel_update();


--
-- Name: ipa_hotel_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_hotel_history_update AFTER UPDATE ON ipa_ops.ipa_hotels FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_hotel_update();


--
-- Name: ipa_inex_checklist_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_inex_checklist_history_insert AFTER INSERT ON ipa_ops.ipa_inex_checklists FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_inex_checklist_update();


--
-- Name: ipa_inex_checklist_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_inex_checklist_history_update AFTER UPDATE ON ipa_ops.ipa_inex_checklists FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_inex_checklist_update();


--
-- Name: ipa_initial_screening_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_initial_screening_history_insert AFTER INSERT ON ipa_ops.ipa_initial_screenings FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_initial_screening_update();


--
-- Name: ipa_initial_screening_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_initial_screening_history_update AFTER UPDATE ON ipa_ops.ipa_initial_screenings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_initial_screening_update();


--
-- Name: ipa_payment_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_payment_history_insert AFTER INSERT ON ipa_ops.ipa_payments FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_payment_update();


--
-- Name: ipa_payment_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_payment_history_update AFTER UPDATE ON ipa_ops.ipa_payments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_payment_update();


--
-- Name: ipa_protocol_deviation_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_protocol_deviation_history_insert AFTER INSERT ON ipa_ops.ipa_protocol_deviations FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_protocol_deviation_update();


--
-- Name: ipa_protocol_deviation_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_protocol_deviation_history_update AFTER UPDATE ON ipa_ops.ipa_protocol_deviations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_protocol_deviation_update();


--
-- Name: ipa_ps_football_experience_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_football_experience_history_insert AFTER INSERT ON ipa_ops.ipa_ps_football_experiences FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_ps_football_experience_update();


--
-- Name: ipa_ps_football_experience_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_football_experience_history_update AFTER UPDATE ON ipa_ops.ipa_ps_football_experiences FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_ps_football_experience_update();


--
-- Name: ipa_ps_health_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_health_history_insert AFTER INSERT ON ipa_ops.ipa_ps_healths FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_ps_health_update();


--
-- Name: ipa_ps_health_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_health_history_update AFTER UPDATE ON ipa_ops.ipa_ps_healths FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_ps_health_update();


--
-- Name: ipa_ps_initial_screening_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_initial_screening_history_insert AFTER INSERT ON ipa_ops.ipa_ps_initial_screenings FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_ps_initial_screening_update();


--
-- Name: ipa_ps_initial_screening_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_initial_screening_history_update AFTER UPDATE ON ipa_ops.ipa_ps_initial_screenings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_ps_initial_screening_update();


--
-- Name: ipa_ps_mri_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_mri_history_insert AFTER INSERT ON ipa_ops.ipa_ps_mris FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_ps_mri_update();


--
-- Name: ipa_ps_mri_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_mri_history_update AFTER UPDATE ON ipa_ops.ipa_ps_mris FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_ps_mri_update();


--
-- Name: ipa_ps_ps_follow_up; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_ps_follow_up AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_phone_screens FOR EACH ROW EXECUTE PROCEDURE ml_app.activity_log_ipa_assignment_ps_follow_up();


--
-- Name: ipa_ps_size_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_size_history_insert AFTER INSERT ON ipa_ops.ipa_ps_sizes FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_ps_size_update();


--
-- Name: ipa_ps_size_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_size_history_update AFTER UPDATE ON ipa_ops.ipa_ps_sizes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_ps_size_update();


--
-- Name: ipa_ps_sleep_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_sleep_history_insert AFTER INSERT ON ipa_ops.ipa_ps_sleeps FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_ps_sleep_update();


--
-- Name: ipa_ps_sleep_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_sleep_history_update AFTER UPDATE ON ipa_ops.ipa_ps_sleeps FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_ps_sleep_update();


--
-- Name: ipa_ps_tmoca_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_tmoca_history_insert AFTER INSERT ON ipa_ops.ipa_ps_tmocas FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_ps_tmoca_update();


--
-- Name: ipa_ps_tmoca_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_tmoca_history_update AFTER UPDATE ON ipa_ops.ipa_ps_tmocas FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_ps_tmoca_update();


--
-- Name: ipa_ps_tms_test_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_tms_test_history_insert AFTER INSERT ON ipa_ops.ipa_ps_tms_tests FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_ps_tms_test_update();


--
-- Name: ipa_ps_tms_test_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_tms_test_history_update AFTER UPDATE ON ipa_ops.ipa_ps_tms_tests FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_ps_tms_test_update();


--
-- Name: ipa_ps_to_inex; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_to_inex AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_phone_screens FOR EACH ROW EXECUTE PROCEDURE ml_app.activity_log_ipa_assignment_phone_screens_callback_set();


--
-- Name: ipa_screening_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_screening_history_insert AFTER INSERT ON ipa_ops.ipa_screenings FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_screening_update();


--
-- Name: ipa_screening_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_screening_history_update AFTER UPDATE ON ipa_ops.ipa_screenings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_screening_update();


--
-- Name: ipa_station_contact_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_station_contact_history_insert AFTER INSERT ON ipa_ops.ipa_station_contacts FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_station_contact_update();


--
-- Name: ipa_station_contact_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_station_contact_history_update AFTER UPDATE ON ipa_ops.ipa_station_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_station_contact_update();


--
-- Name: ipa_survey_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_survey_history_insert AFTER INSERT ON ipa_ops.ipa_surveys FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_survey_update();


--
-- Name: ipa_survey_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_survey_history_update AFTER UPDATE ON ipa_ops.ipa_surveys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_survey_update();


--
-- Name: ipa_transportation_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_transportation_history_insert AFTER INSERT ON ipa_ops.ipa_transportations FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_transportation_update();


--
-- Name: ipa_transportation_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_transportation_history_update AFTER UPDATE ON ipa_ops.ipa_transportations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_transportation_update();


--
-- Name: ipa_withdrawal_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_withdrawal_history_insert AFTER INSERT ON ipa_ops.ipa_withdrawals FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_withdrawal_update();


--
-- Name: ipa_withdrawal_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_withdrawal_history_update AFTER UPDATE ON ipa_ops.ipa_withdrawals FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_withdrawal_update();


--
-- Name: mrn_number_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER mrn_number_history_insert AFTER INSERT ON ipa_ops.mrn_numbers FOR EACH ROW EXECUTE PROCEDURE ml_app.log_mrn_number_update();


--
-- Name: mrn_number_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER mrn_number_history_update AFTER UPDATE ON ipa_ops.mrn_numbers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_mrn_number_update();


--
-- Name: accuracy_score_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER accuracy_score_history_insert AFTER INSERT ON ml_app.accuracy_scores FOR EACH ROW EXECUTE PROCEDURE ml_app.log_accuracy_score_update();


--
-- Name: accuracy_score_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER accuracy_score_history_update AFTER UPDATE ON ml_app.accuracy_scores FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_accuracy_score_update();


--
-- Name: activity_log_bhs_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_bhs_assignment_history_insert AFTER INSERT ON ml_app.activity_log_bhs_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_bhs_assignment_update();


--
-- Name: activity_log_bhs_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_bhs_assignment_history_update AFTER UPDATE ON ml_app.activity_log_bhs_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_bhs_assignment_update();


--
-- Name: activity_log_ext_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_ext_assignment_history_insert AFTER INSERT ON ml_app.activity_log_ext_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_ext_assignment_update();


--
-- Name: activity_log_ext_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_ext_assignment_history_update AFTER UPDATE ON ml_app.activity_log_ext_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_ext_assignment_update();


--
-- Name: activity_log_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_history_insert AFTER INSERT ON ml_app.activity_logs FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_update();


--
-- Name: activity_log_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_history_update AFTER UPDATE ON ml_app.activity_logs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_update();


--
-- Name: activity_log_new_test_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_new_test_history_insert AFTER INSERT ON ml_app.activity_log_new_tests FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_new_test_update();


--
-- Name: activity_log_new_test_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_new_test_history_update AFTER UPDATE ON ml_app.activity_log_new_tests FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_new_test_update();


--
-- Name: activity_log_player_contact_phone_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_player_contact_phone_history_insert AFTER INSERT ON ml_app.activity_log_player_contact_phones FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_player_contact_phone_update();


--
-- Name: activity_log_player_contact_phone_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_player_contact_phone_history_update AFTER UPDATE ON ml_app.activity_log_player_contact_phones FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_player_contact_phone_update();


--
-- Name: activity_log_player_info_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_player_info_history_insert AFTER INSERT ON ml_app.activity_log_player_infos FOR EACH ROW EXECUTE PROCEDURE ml_app.log_activity_log_player_info_update();


--
-- Name: activity_log_player_info_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_player_info_history_update AFTER UPDATE ON ml_app.activity_log_player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_activity_log_player_info_update();


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
-- Name: bhs_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER bhs_assignment_history_insert AFTER INSERT ON ml_app.bhs_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app.log_bhs_assignment_update();


--
-- Name: bhs_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER bhs_assignment_history_update AFTER UPDATE ON ml_app.bhs_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_bhs_assignment_update();


--
-- Name: college_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER college_history_insert AFTER INSERT ON ml_app.colleges FOR EACH ROW EXECUTE PROCEDURE ml_app.log_college_update();


--
-- Name: college_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER college_history_update AFTER UPDATE ON ml_app.colleges FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_college_update();


--
-- Name: dynamic_model_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER dynamic_model_history_insert AFTER INSERT ON ml_app.dynamic_models FOR EACH ROW EXECUTE PROCEDURE ml_app.log_dynamic_model_update();


--
-- Name: dynamic_model_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER dynamic_model_history_update AFTER UPDATE ON ml_app.dynamic_models FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_dynamic_model_update();


--
-- Name: ext_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ext_assignment_history_insert AFTER INSERT ON ml_app.ext_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ext_assignment_update();


--
-- Name: ext_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ext_assignment_history_update AFTER UPDATE ON ml_app.ext_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ext_assignment_update();


--
-- Name: ext_gen_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ext_gen_assignment_history_insert AFTER INSERT ON ml_app.ext_gen_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ext_gen_assignment_update();


--
-- Name: ext_gen_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ext_gen_assignment_history_update AFTER UPDATE ON ml_app.ext_gen_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ext_gen_assignment_update();


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
-- Name: ipa_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ipa_assignment_history_insert AFTER INSERT ON ml_app.ipa_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app.log_ipa_assignment_update();


--
-- Name: ipa_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ipa_assignment_history_update AFTER UPDATE ON ml_app.ipa_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_ipa_assignment_update();


--
-- Name: ipa_perform_screening_callback; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ipa_perform_screening_callback AFTER INSERT ON ml_app.model_references FOR EACH ROW EXECUTE PROCEDURE ml_app.activity_log_ipa_assignment_perform_screening_callback();


--
-- Name: ipa_ps_new_ps_schedule; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER ipa_ps_new_ps_schedule AFTER INSERT ON ml_app.model_references FOR EACH ROW EXECUTE PROCEDURE ml_app.activity_log_ipa_assignment_new_ps_schedule();


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
-- Name: json_doc_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER json_doc_history_insert AFTER INSERT ON ml_app.json_docs FOR EACH ROW EXECUTE PROCEDURE ml_app.log_json_doc_update();


--
-- Name: json_doc_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER json_doc_history_update AFTER UPDATE ON ml_app.json_docs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_json_doc_update();


--
-- Name: new_test_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER new_test_history_insert AFTER INSERT ON ml_app.new_tests FOR EACH ROW EXECUTE PROCEDURE ml_app.log_new_test_update();


--
-- Name: new_test_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER new_test_history_update AFTER UPDATE ON ml_app.new_tests FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_new_test_update();


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
-- Name: social_security_number_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER social_security_number_history_insert AFTER INSERT ON ml_app.social_security_numbers FOR EACH ROW EXECUTE PROCEDURE ml_app.log_social_security_number_update();


--
-- Name: social_security_number_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER social_security_number_history_update AFTER UPDATE ON ml_app.social_security_numbers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_social_security_number_update();


--
-- Name: sub_process_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER sub_process_history_insert AFTER INSERT ON ml_app.sub_processes FOR EACH ROW EXECUTE PROCEDURE ml_app.log_sub_process_update();


--
-- Name: sub_process_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER sub_process_history_update AFTER UPDATE ON ml_app.sub_processes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_sub_process_update();


--
-- Name: test1_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test1_history_insert AFTER INSERT ON ml_app.test1s FOR EACH ROW EXECUTE PROCEDURE ml_app.log_test1_update();


--
-- Name: test1_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test1_history_update AFTER UPDATE ON ml_app.test1s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_test1_update();


--
-- Name: test2_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test2_history_insert AFTER INSERT ON ml_app.test2s FOR EACH ROW EXECUTE PROCEDURE ml_app.log_test2_update();


--
-- Name: test2_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test2_history_update AFTER UPDATE ON ml_app.test2s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_test2_update();


--
-- Name: test_2_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_2_history_insert AFTER INSERT ON ml_app.test_2s FOR EACH ROW EXECUTE PROCEDURE ml_app.log_test_2_update();


--
-- Name: test_2_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_2_history_update AFTER UPDATE ON ml_app.test_2s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_test_2_update();


--
-- Name: test_ext2_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_ext2_history_insert AFTER INSERT ON ml_app.test_ext2s FOR EACH ROW EXECUTE PROCEDURE ml_app.log_test_ext2_update();


--
-- Name: test_ext2_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_ext2_history_update AFTER UPDATE ON ml_app.test_ext2s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_test_ext2_update();


--
-- Name: test_ext_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_ext_history_insert AFTER INSERT ON ml_app.test_exts FOR EACH ROW EXECUTE PROCEDURE ml_app.log_test_ext_update();


--
-- Name: test_ext_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER test_ext_history_update AFTER UPDATE ON ml_app.test_exts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_test_ext_update();


--
-- Name: testing_dl_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER testing_dl_history_insert AFTER INSERT ON ml_app.testing_dls FOR EACH ROW EXECUTE PROCEDURE ml_app.log_testing_dl_update();


--
-- Name: testing_dl_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER testing_dl_history_update AFTER UPDATE ON ml_app.testing_dls FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_testing_dl_update();


--
-- Name: tracker_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_history_insert AFTER INSERT ON ml_app.trackers FOR EACH ROW EXECUTE PROCEDURE ml_app.log_tracker_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_history_update AFTER UPDATE ON ml_app.trackers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_tracker_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_history_update BEFORE UPDATE ON ml_app.tracker_history FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.handle_tracker_history_update();


--
-- Name: tracker_record_delete; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_record_delete AFTER DELETE ON ml_app.tracker_history FOR EACH ROW EXECUTE PROCEDURE ml_app.handle_delete();


--
-- Name: tracker_upsert; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER tracker_upsert BEFORE INSERT ON ml_app.trackers FOR EACH ROW EXECUTE PROCEDURE ml_app.tracker_upsert();


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
-- Name: fk_activity_log_ipa_assignment_adverse_event_history_activity_l; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_event_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_adverse_event_history_activity_l FOREIGN KEY (activity_log_ipa_assignment_adverse_event_id) REFERENCES ipa_ops.activity_log_ipa_assignment_adverse_events(id);


--
-- Name: fk_activity_log_ipa_assignment_adverse_event_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_event_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_adverse_event_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_adverse_event_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_event_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_adverse_event_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_assignment_history_activity_log_ipa_assignm; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_activity_log_ipa_assignm FOREIGN KEY (activity_log_ipa_assignment_id) REFERENCES ipa_ops.activity_log_ipa_assignments(id);


--
-- Name: fk_activity_log_ipa_assignment_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_assignment_inex_checklist_history_activity_; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklist_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_inex_checklist_history_activity_ FOREIGN KEY (activity_log_ipa_assignment_inex_checklist_id) REFERENCES ipa_ops.activity_log_ipa_assignment_inex_checklists(id);


--
-- Name: fk_activity_log_ipa_assignment_inex_checklist_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklist_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_inex_checklist_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_inex_checklist_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklist_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_inex_checklist_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_assignment_minor_deviation_history_activity; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_activity FOREIGN KEY (activity_log_ipa_assignment_minor_deviation_id) REFERENCES ipa_ops.activity_log_ipa_assignment_minor_deviations(id);


--
-- Name: fk_activity_log_ipa_assignment_minor_deviation_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_minor_deviation_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_assignment_navigation_history_activity_log_; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_navigation_history_activity_log_ FOREIGN KEY (activity_log_ipa_assignment_navigation_id) REFERENCES ipa_ops.activity_log_ipa_assignment_navigations(id);


--
-- Name: fk_activity_log_ipa_assignment_navigation_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_navigation_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_navigation_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_navigation_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_assignment_phone_screen_history_activity_lo; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screen_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_phone_screen_history_activity_lo FOREIGN KEY (activity_log_ipa_assignment_phone_screen_id) REFERENCES ipa_ops.activity_log_ipa_assignment_phone_screens(id);


--
-- Name: fk_activity_log_ipa_assignment_phone_screen_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screen_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_phone_screen_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_phone_screen_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screen_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_phone_screen_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_assignment_protocol_deviation_history_activ; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_protocol_deviation_history_activ FOREIGN KEY (activity_log_ipa_assignment_protocol_deviation_id) REFERENCES ipa_ops.activity_log_ipa_assignment_protocol_deviations(id);


--
-- Name: fk_activity_log_ipa_assignment_protocol_deviation_history_maste; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_protocol_deviation_history_maste FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_protocol_deviation_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_protocol_deviation_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_assignment_session_filestore_history_activi; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_session_filestore_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_session_filestore_history_activi FOREIGN KEY (activity_log_ipa_assignment_session_filestore_id) REFERENCES ipa_ops.activity_log_ipa_assignment_session_filestores(id);


--
-- Name: fk_activity_log_ipa_assignment_session_filestore_history_ipa_as; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_session_filestore_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_session_filestore_history_ipa_as FOREIGN KEY (ipa_assignment_id) REFERENCES ml_app.ipa_assignments(id);


--
-- Name: fk_activity_log_ipa_assignment_session_filestore_history_master; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_session_filestore_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_session_filestore_history_master FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_session_filestore_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_session_filestore_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_session_filestore_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_screening_phone_screen_history_activity_log; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_screening_phone_screen_history
    ADD CONSTRAINT fk_activity_log_ipa_screening_phone_screen_history_activity_log FOREIGN KEY (activity_log_ipa_screening_phone_screen_id) REFERENCES ipa_ops.activity_log_ipa_screening_phone_screens(id);


--
-- Name: fk_activity_log_ipa_screening_phone_screen_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_screening_phone_screen_history
    ADD CONSTRAINT fk_activity_log_ipa_screening_phone_screen_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_screening_phone_screen_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_screening_phone_screen_history
    ADD CONSTRAINT fk_activity_log_ipa_screening_phone_screen_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_survey_history_activity_log_ipa_surveys; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_survey_history
    ADD CONSTRAINT fk_activity_log_ipa_survey_history_activity_log_ipa_surveys FOREIGN KEY (activity_log_ipa_survey_id) REFERENCES ipa_ops.activity_log_ipa_surveys(id);


--
-- Name: fk_activity_log_ipa_survey_history_ipa_survey_id; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_survey_history
    ADD CONSTRAINT fk_activity_log_ipa_survey_history_ipa_survey_id FOREIGN KEY (ipa_survey_id) REFERENCES ipa_ops.ipa_surveys(id);


--
-- Name: fk_activity_log_ipa_survey_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_survey_history
    ADD CONSTRAINT fk_activity_log_ipa_survey_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_survey_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_survey_history
    ADD CONSTRAINT fk_activity_log_ipa_survey_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_adl_informant_screener_history_ipa_adl_informant_screene; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adl_informant_screener_history
    ADD CONSTRAINT fk_ipa_adl_informant_screener_history_ipa_adl_informant_screene FOREIGN KEY (ipa_adl_informant_screener_id) REFERENCES ipa_ops.ipa_adl_informant_screeners(id);


--
-- Name: fk_ipa_adl_informant_screener_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adl_informant_screener_history
    ADD CONSTRAINT fk_ipa_adl_informant_screener_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_adl_informant_screener_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adl_informant_screener_history
    ADD CONSTRAINT fk_ipa_adl_informant_screener_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_adverse_event_history_ipa_adverse_events; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adverse_event_history
    ADD CONSTRAINT fk_ipa_adverse_event_history_ipa_adverse_events FOREIGN KEY (ipa_adverse_event_id) REFERENCES ipa_ops.ipa_adverse_events(id);


--
-- Name: fk_ipa_adverse_event_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adverse_event_history
    ADD CONSTRAINT fk_ipa_adverse_event_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_adverse_event_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adverse_event_history
    ADD CONSTRAINT fk_ipa_adverse_event_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_appointment_history_ipa_appointments; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointment_history
    ADD CONSTRAINT fk_ipa_appointment_history_ipa_appointments FOREIGN KEY (ipa_appointment_id) REFERENCES ipa_ops.ipa_appointments(id);


--
-- Name: fk_ipa_appointment_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointment_history
    ADD CONSTRAINT fk_ipa_appointment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_appointment_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointment_history
    ADD CONSTRAINT fk_ipa_appointment_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_assignment_history_admins; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_ipa_assignment_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_assignment_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_consent_mailing_history_ipa_consent_mailings; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_consent_mailing_history
    ADD CONSTRAINT fk_ipa_consent_mailing_history_ipa_consent_mailings FOREIGN KEY (ipa_consent_mailing_id) REFERENCES ipa_ops.ipa_consent_mailings(id);


--
-- Name: fk_ipa_consent_mailing_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_consent_mailing_history
    ADD CONSTRAINT fk_ipa_consent_mailing_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_consent_mailing_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_consent_mailing_history
    ADD CONSTRAINT fk_ipa_consent_mailing_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_hotel_history_ipa_hotels; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_hotel_history
    ADD CONSTRAINT fk_ipa_hotel_history_ipa_hotels FOREIGN KEY (ipa_hotel_id) REFERENCES ipa_ops.ipa_hotels(id);


--
-- Name: fk_ipa_hotel_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_hotel_history
    ADD CONSTRAINT fk_ipa_hotel_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_hotel_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_hotel_history
    ADD CONSTRAINT fk_ipa_hotel_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_inex_checklist_history_ipa_inex_checklists; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_inex_checklist_history
    ADD CONSTRAINT fk_ipa_inex_checklist_history_ipa_inex_checklists FOREIGN KEY (ipa_inex_checklist_id) REFERENCES ipa_ops.ipa_inex_checklists(id);


--
-- Name: fk_ipa_inex_checklist_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_inex_checklist_history
    ADD CONSTRAINT fk_ipa_inex_checklist_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_inex_checklist_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_inex_checklist_history
    ADD CONSTRAINT fk_ipa_inex_checklist_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_initial_screening_history_ipa_initial_screenings; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_initial_screening_history
    ADD CONSTRAINT fk_ipa_initial_screening_history_ipa_initial_screenings FOREIGN KEY (ipa_initial_screening_id) REFERENCES ipa_ops.ipa_initial_screenings(id);


--
-- Name: fk_ipa_initial_screening_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_initial_screening_history
    ADD CONSTRAINT fk_ipa_initial_screening_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_initial_screening_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_initial_screening_history
    ADD CONSTRAINT fk_ipa_initial_screening_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_payment_history_ipa_payments; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_payment_history
    ADD CONSTRAINT fk_ipa_payment_history_ipa_payments FOREIGN KEY (ipa_payment_id) REFERENCES ipa_ops.ipa_payments(id);


--
-- Name: fk_ipa_payment_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_payment_history
    ADD CONSTRAINT fk_ipa_payment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_payment_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_payment_history
    ADD CONSTRAINT fk_ipa_payment_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_protocol_deviation_history_ipa_protocol_deviations; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_deviation_history
    ADD CONSTRAINT fk_ipa_protocol_deviation_history_ipa_protocol_deviations FOREIGN KEY (ipa_protocol_deviation_id) REFERENCES ipa_ops.ipa_protocol_deviations(id);


--
-- Name: fk_ipa_protocol_deviation_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_deviation_history
    ADD CONSTRAINT fk_ipa_protocol_deviation_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_protocol_deviation_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_deviation_history
    ADD CONSTRAINT fk_ipa_protocol_deviation_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_ps_football_experience_history_ipa_ps_football_experienc; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_football_experience_history
    ADD CONSTRAINT fk_ipa_ps_football_experience_history_ipa_ps_football_experienc FOREIGN KEY (ipa_ps_football_experience_id) REFERENCES ipa_ops.ipa_ps_football_experiences(id);


--
-- Name: fk_ipa_ps_football_experience_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_football_experience_history
    ADD CONSTRAINT fk_ipa_ps_football_experience_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_ps_football_experience_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_football_experience_history
    ADD CONSTRAINT fk_ipa_ps_football_experience_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_ps_health_history_ipa_ps_healths; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_health_history
    ADD CONSTRAINT fk_ipa_ps_health_history_ipa_ps_healths FOREIGN KEY (ipa_ps_health_id) REFERENCES ipa_ops.ipa_ps_healths(id);


--
-- Name: fk_ipa_ps_health_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_health_history
    ADD CONSTRAINT fk_ipa_ps_health_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_ps_health_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_health_history
    ADD CONSTRAINT fk_ipa_ps_health_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_ps_initial_screening_history_ipa_ps_initial_screenings; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_initial_screening_history
    ADD CONSTRAINT fk_ipa_ps_initial_screening_history_ipa_ps_initial_screenings FOREIGN KEY (ipa_ps_initial_screening_id) REFERENCES ipa_ops.ipa_ps_initial_screenings(id);


--
-- Name: fk_ipa_ps_initial_screening_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_initial_screening_history
    ADD CONSTRAINT fk_ipa_ps_initial_screening_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_ps_initial_screening_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_initial_screening_history
    ADD CONSTRAINT fk_ipa_ps_initial_screening_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_ps_mri_history_ipa_ps_mris; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_mri_history
    ADD CONSTRAINT fk_ipa_ps_mri_history_ipa_ps_mris FOREIGN KEY (ipa_ps_mri_id) REFERENCES ipa_ops.ipa_ps_mris(id);


--
-- Name: fk_ipa_ps_mri_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_mri_history
    ADD CONSTRAINT fk_ipa_ps_mri_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_ps_mri_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_mri_history
    ADD CONSTRAINT fk_ipa_ps_mri_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_ps_size_history_ipa_ps_sizes; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_size_history
    ADD CONSTRAINT fk_ipa_ps_size_history_ipa_ps_sizes FOREIGN KEY (ipa_ps_size_id) REFERENCES ipa_ops.ipa_ps_sizes(id);


--
-- Name: fk_ipa_ps_size_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_size_history
    ADD CONSTRAINT fk_ipa_ps_size_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_ps_size_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_size_history
    ADD CONSTRAINT fk_ipa_ps_size_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_ps_sleep_history_ipa_ps_sleeps; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sleep_history
    ADD CONSTRAINT fk_ipa_ps_sleep_history_ipa_ps_sleeps FOREIGN KEY (ipa_ps_sleep_id) REFERENCES ipa_ops.ipa_ps_sleeps(id);


--
-- Name: fk_ipa_ps_sleep_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sleep_history
    ADD CONSTRAINT fk_ipa_ps_sleep_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_ps_sleep_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sleep_history
    ADD CONSTRAINT fk_ipa_ps_sleep_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_ps_tmoca_history_ipa_ps_tmocas; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tmoca_history
    ADD CONSTRAINT fk_ipa_ps_tmoca_history_ipa_ps_tmocas FOREIGN KEY (ipa_ps_tmoca_id) REFERENCES ipa_ops.ipa_ps_tmocas(id);


--
-- Name: fk_ipa_ps_tmoca_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tmoca_history
    ADD CONSTRAINT fk_ipa_ps_tmoca_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_ps_tmoca_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tmoca_history
    ADD CONSTRAINT fk_ipa_ps_tmoca_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_ps_tms_test_history_ipa_ps_tms_tests; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tms_test_history
    ADD CONSTRAINT fk_ipa_ps_tms_test_history_ipa_ps_tms_tests FOREIGN KEY (ipa_ps_tms_test_id) REFERENCES ipa_ops.ipa_ps_tms_tests(id);


--
-- Name: fk_ipa_ps_tms_test_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tms_test_history
    ADD CONSTRAINT fk_ipa_ps_tms_test_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_ps_tms_test_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tms_test_history
    ADD CONSTRAINT fk_ipa_ps_tms_test_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_recruitment_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_recruitment_history
    ADD CONSTRAINT fk_ipa_recruitment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_recruitment_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_recruitment_history
    ADD CONSTRAINT fk_ipa_recruitment_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_screening_history_ipa_screenings; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_screening_history
    ADD CONSTRAINT fk_ipa_screening_history_ipa_screenings FOREIGN KEY (ipa_screening_id) REFERENCES ipa_ops.ipa_screenings(id);


--
-- Name: fk_ipa_screening_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_screening_history
    ADD CONSTRAINT fk_ipa_screening_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_screening_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_screening_history
    ADD CONSTRAINT fk_ipa_screening_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_station_contact_history_ipa_station_contacts; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_station_contact_history
    ADD CONSTRAINT fk_ipa_station_contact_history_ipa_station_contacts FOREIGN KEY (ipa_station_contact_id) REFERENCES ipa_ops.ipa_station_contacts(id);


--
-- Name: fk_ipa_station_contact_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_station_contact_history
    ADD CONSTRAINT fk_ipa_station_contact_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_station_contact_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_station_contact_history
    ADD CONSTRAINT fk_ipa_station_contact_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_survey_history_ipa_surveys; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_survey_history
    ADD CONSTRAINT fk_ipa_survey_history_ipa_surveys FOREIGN KEY (ipa_survey_id) REFERENCES ipa_ops.ipa_surveys(id);


--
-- Name: fk_ipa_survey_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_survey_history
    ADD CONSTRAINT fk_ipa_survey_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_survey_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_survey_history
    ADD CONSTRAINT fk_ipa_survey_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_transportation_history_ipa_transportations; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_transportation_history
    ADD CONSTRAINT fk_ipa_transportation_history_ipa_transportations FOREIGN KEY (ipa_transportation_id) REFERENCES ipa_ops.ipa_transportations(id);


--
-- Name: fk_ipa_transportation_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_transportation_history
    ADD CONSTRAINT fk_ipa_transportation_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_transportation_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_transportation_history
    ADD CONSTRAINT fk_ipa_transportation_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_withdrawal_history_ipa_withdrawals; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_withdrawal_history
    ADD CONSTRAINT fk_ipa_withdrawal_history_ipa_withdrawals FOREIGN KEY (ipa_withdrawal_id) REFERENCES ipa_ops.ipa_withdrawals(id);


--
-- Name: fk_ipa_withdrawal_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_withdrawal_history
    ADD CONSTRAINT fk_ipa_withdrawal_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_withdrawal_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_withdrawal_history
    ADD CONSTRAINT fk_ipa_withdrawal_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_mrn_number_history_admins; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_number_history
    ADD CONSTRAINT fk_mrn_number_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_mrn_number_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_number_history
    ADD CONSTRAINT fk_mrn_number_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_mrn_number_history_mrn_numbers; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_number_history
    ADD CONSTRAINT fk_mrn_number_history_mrn_numbers FOREIGN KEY (mrn_number_table_id) REFERENCES ipa_ops.mrn_numbers(id);


--
-- Name: fk_mrn_number_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_number_history
    ADD CONSTRAINT fk_mrn_number_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_numbers
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_hotels
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_transportations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_payments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_surveys
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_surveys
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_screening_phone_screens
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_football_experiences
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_healths
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sleeps
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_mris
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tms_tests
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_inex_checklists
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklists
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_withdrawals
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screens
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tmocas
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sizes
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_initial_screenings
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_initial_screenings
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_consent_mailings
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_screenings
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_deviations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adverse_events
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_events
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_station_contacts
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adl_informant_screeners
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_session_filestores
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_numbers
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_numbers
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_hotels
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_transportations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_payments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_surveys
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_surveys
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_screening_phone_screens
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_football_experiences
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_healths
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sleeps
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_mris
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tms_tests
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_inex_checklists
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklists
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_withdrawals
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screens
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tmocas
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sizes
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_initial_screenings
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_initial_screenings
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_consent_mailings
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_screenings
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_deviations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adverse_events
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_events
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_station_contacts
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adl_informant_screeners
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_session_filestores
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_surveys
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_survey_id) REFERENCES ipa_ops.ipa_surveys(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_session_filestores
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ml_app.ipa_assignments(id);


--
-- Name: fk_rails_8104b3f11d; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.emergency_contacts
    ADD CONSTRAINT fk_rails_8104b3f11d FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_f5033c91ed; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.emergency_contacts
    ADD CONSTRAINT fk_rails_f5033c91ed FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_accuracy_score_history_accuracy_scores; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.accuracy_score_history
    ADD CONSTRAINT fk_accuracy_score_history_accuracy_scores FOREIGN KEY (accuracy_score_id) REFERENCES ml_app.accuracy_scores(id);


--
-- Name: fk_activity_log_bhs_assignment_history_activity_log_bhs_assignm; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignment_history
    ADD CONSTRAINT fk_activity_log_bhs_assignment_history_activity_log_bhs_assignm FOREIGN KEY (activity_log_bhs_assignment_id) REFERENCES ml_app.activity_log_bhs_assignments(id);


--
-- Name: fk_activity_log_bhs_assignment_history_bhs_assignment_id; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignment_history
    ADD CONSTRAINT fk_activity_log_bhs_assignment_history_bhs_assignment_id FOREIGN KEY (bhs_assignment_id) REFERENCES ml_app.bhs_assignments(id);


--
-- Name: fk_activity_log_bhs_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignment_history
    ADD CONSTRAINT fk_activity_log_bhs_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_bhs_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignment_history
    ADD CONSTRAINT fk_activity_log_bhs_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ext_assignment_history_activity_log_ext_assignm; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_activity_log_ext_assignm FOREIGN KEY (activity_log_ext_assignment_id) REFERENCES ml_app.activity_log_ext_assignments(id);


--
-- Name: fk_activity_log_ext_assignment_history_ext_assignment_id; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_ext_assignment_id FOREIGN KEY (ext_assignment_id) REFERENCES ml_app.ext_assignments(id);


--
-- Name: fk_activity_log_ext_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ext_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_ext_assignment_history
    ADD CONSTRAINT fk_activity_log_ext_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_new_test_history_activity_log_new_tests; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_activity_log_new_tests FOREIGN KEY (activity_log_new_test_id) REFERENCES ml_app.activity_log_new_tests(id);


--
-- Name: fk_activity_log_new_test_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_new_test_history_new_test_id; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_new_test_id FOREIGN KEY (new_test_id) REFERENCES ml_app.new_tests(id);


--
-- Name: fk_activity_log_new_test_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_new_test_history
    ADD CONSTRAINT fk_activity_log_new_test_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_activity_log_player_info_history_activity_log_player_infos; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_activity_log_player_infos FOREIGN KEY (activity_log_player_info_id) REFERENCES ml_app.activity_log_player_infos(id);


--
-- Name: fk_activity_log_player_info_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_player_info_history_player_info_id; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_player_info_id FOREIGN KEY (player_info_id) REFERENCES ml_app.player_infos(id);


--
-- Name: fk_activity_log_player_info_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_info_history
    ADD CONSTRAINT fk_activity_log_player_info_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_bhs_assignment_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignment_history
    ADD CONSTRAINT fk_bhs_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_bhs_assignment_history_bhs_assignments; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignment_history
    ADD CONSTRAINT fk_bhs_assignment_history_bhs_assignments FOREIGN KEY (bhs_assignment_table_id) REFERENCES ml_app.bhs_assignments(id);


--
-- Name: fk_bhs_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignment_history
    ADD CONSTRAINT fk_bhs_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_bhs_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignment_history
    ADD CONSTRAINT fk_bhs_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_ext_assignment_history_ext_assignments; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_assignment_history
    ADD CONSTRAINT fk_ext_assignment_history_ext_assignments FOREIGN KEY (ext_assignment_table_id) REFERENCES ml_app.ext_assignments(id);


--
-- Name: fk_ext_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_assignment_history
    ADD CONSTRAINT fk_ext_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ext_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_assignment_history
    ADD CONSTRAINT fk_ext_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ext_gen_assignment_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_ext_gen_assignment_history_ext_gen_assignments; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_ext_gen_assignments FOREIGN KEY (ext_gen_assignment_table_id) REFERENCES ml_app.ext_gen_assignments(id);


--
-- Name: fk_ext_gen_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ext_gen_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_gen_assignment_history
    ADD CONSTRAINT fk_ext_gen_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_ipa_assignment_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_ipa_assignment_history_ipa_assignments; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_ipa_assignments FOREIGN KEY (ipa_assignment_table_id) REFERENCES ml_app.ipa_assignments(id);


--
-- Name: fk_ipa_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_json_doc_history_json_docs; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.json_doc_history
    ADD CONSTRAINT fk_json_doc_history_json_docs FOREIGN KEY (json_doc_id) REFERENCES ml_app.json_docs(id);


--
-- Name: fk_json_doc_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.json_doc_history
    ADD CONSTRAINT fk_json_doc_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_json_doc_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.json_doc_history
    ADD CONSTRAINT fk_json_doc_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_new_test_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.new_test_history
    ADD CONSTRAINT fk_new_test_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_new_test_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.new_test_history
    ADD CONSTRAINT fk_new_test_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_new_test_history_new_tests; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.new_test_history
    ADD CONSTRAINT fk_new_test_history_new_tests FOREIGN KEY (new_test_table_id) REFERENCES ml_app.new_tests(id);


--
-- Name: fk_new_test_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.new_test_history
    ADD CONSTRAINT fk_new_test_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_rails_0a64e1160a; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.protocol_events
    ADD CONSTRAINT fk_rails_0a64e1160a FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_0c84487284; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_containers
    ADD CONSTRAINT fk_rails_0c84487284 FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


--
-- Name: fk_rails_0de144234e; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_stored_files
    ADD CONSTRAINT fk_rails_0de144234e FOREIGN KEY (nfs_store_container_id) REFERENCES ml_app.nfs_store_containers(id);


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
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_exts
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_ext_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_gen_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test1s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_infos
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.new_tests
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_new_tests
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.social_security_numbers
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.testing_dls
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.json_docs
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test1s
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test2s
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.new_tests
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.social_security_numbers
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_1cc4562569; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_stored_files
    ADD CONSTRAINT fk_rails_1cc4562569 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_rails_2d8072edea; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.model_references
    ADD CONSTRAINT fk_rails_2d8072edea FOREIGN KEY (to_record_master_id) REFERENCES ml_app.masters(id);


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
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_exts
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext2s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_ext_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ext_gen_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test1s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_2s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test2s
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_infos
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.new_tests
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_new_tests
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.social_security_numbers
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.testing_dls
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.json_docs
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.ipa_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


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
-- Name: fk_rails_4fe5122ed4; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.message_templates
    ADD CONSTRAINT fk_rails_4fe5122ed4 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


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
-- Name: fk_rails_5b0628cf42; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.external_identifier_history
    ADD CONSTRAINT fk_rails_5b0628cf42 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_623e0ca5ac; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.trackers
    ADD CONSTRAINT fk_rails_623e0ca5ac FOREIGN KEY (protocol_id) REFERENCES ml_app.protocols(id);


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
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_ext_assignments
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ext_assignment_id) REFERENCES ml_app.ext_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_player_infos
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (player_info_id) REFERENCES ml_app.player_infos(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_new_tests
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (new_test_id) REFERENCES ml_app.new_tests(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignments
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (bhs_assignment_id) REFERENCES ml_app.bhs_assignments(id);


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
-- Name: fk_rails_86cecb1e36; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.pro_infos
    ADD CONSTRAINT fk_rails_86cecb1e36 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_8be93bcf4b; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.app_types
    ADD CONSTRAINT fk_rails_8be93bcf4b FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


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
-- Name: fk_rails_af2f6ffc55; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_history
    ADD CONSTRAINT fk_rails_af2f6ffc55 FOREIGN KEY (app_type_id) REFERENCES ml_app.app_types(id);


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
-- Name: fk_rails_bdb308087e; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_uploads
    ADD CONSTRAINT fk_rails_bdb308087e FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_c2d5bb8930; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flags
    ADD CONSTRAINT fk_rails_c2d5bb8930 FOREIGN KEY (item_flag_name_id) REFERENCES ml_app.item_flag_names(id);


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
-- Name: fk_rails_c9d7977c0c; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.masters
    ADD CONSTRAINT fk_rails_c9d7977c0c FOREIGN KEY (pro_info_id) REFERENCES ml_app.pro_infos(id);


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
-- Name: fk_rails_dce5169cfd; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.item_flags
    ADD CONSTRAINT fk_rails_dce5169cfd FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_rails_f62500107f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.general_selections
    ADD CONSTRAINT fk_rails_f62500107f FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


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
-- Name: fk_social_security_number_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.social_security_number_history
    ADD CONSTRAINT fk_social_security_number_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_social_security_number_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.social_security_number_history
    ADD CONSTRAINT fk_social_security_number_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_social_security_number_history_social_security_numbers; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.social_security_number_history
    ADD CONSTRAINT fk_social_security_number_history_social_security_numbers FOREIGN KEY (social_security_number_table_id) REFERENCES ml_app.social_security_numbers(id);


--
-- Name: fk_social_security_number_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.social_security_number_history
    ADD CONSTRAINT fk_social_security_number_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_sub_process_history_sub_processes; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.sub_process_history
    ADD CONSTRAINT fk_sub_process_history_sub_processes FOREIGN KEY (sub_process_id) REFERENCES ml_app.sub_processes(id);


--
-- Name: fk_test1_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test1_history
    ADD CONSTRAINT fk_test1_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_test1_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test1_history
    ADD CONSTRAINT fk_test1_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_test1_history_test1s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test1_history
    ADD CONSTRAINT fk_test1_history_test1s FOREIGN KEY (test1_table_id) REFERENCES ml_app.test1s(id);


--
-- Name: fk_test1_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test1_history
    ADD CONSTRAINT fk_test1_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_test2_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test2_history
    ADD CONSTRAINT fk_test2_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_test2_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test2_history
    ADD CONSTRAINT fk_test2_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_test2_history_test2s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test2_history
    ADD CONSTRAINT fk_test2_history_test2s FOREIGN KEY (test2_table_id) REFERENCES ml_app.test2s(id);


--
-- Name: fk_test2_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test2_history
    ADD CONSTRAINT fk_test2_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_test_2_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_2_history
    ADD CONSTRAINT fk_test_2_history_admins FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_test_2_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_2_history
    ADD CONSTRAINT fk_test_2_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_test_2_history_test_2s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_2_history
    ADD CONSTRAINT fk_test_2_history_test_2s FOREIGN KEY (test_2_table_id) REFERENCES ml_app.test_2s(id);


--
-- Name: fk_test_2_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_2_history
    ADD CONSTRAINT fk_test_2_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_test_ext2_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext2_history
    ADD CONSTRAINT fk_test_ext2_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_test_ext2_history_test_ext2s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext2_history
    ADD CONSTRAINT fk_test_ext2_history_test_ext2s FOREIGN KEY (test_ext2_table_id) REFERENCES ml_app.test_ext2s(id);


--
-- Name: fk_test_ext2_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext2_history
    ADD CONSTRAINT fk_test_ext2_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_test_ext_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext_history
    ADD CONSTRAINT fk_test_ext_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_test_ext_history_test_exts; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext_history
    ADD CONSTRAINT fk_test_ext_history_test_exts FOREIGN KEY (test_ext_table_id) REFERENCES ml_app.test_exts(id);


--
-- Name: fk_test_ext_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.test_ext_history
    ADD CONSTRAINT fk_test_ext_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_testing_dl_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.testing_dl_history
    ADD CONSTRAINT fk_testing_dl_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_testing_dl_history_testing_dls; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.testing_dl_history
    ADD CONSTRAINT fk_testing_dl_history_testing_dls FOREIGN KEY (testing_dl_id) REFERENCES ml_app.testing_dls(id);


--
-- Name: fk_testing_dl_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.testing_dl_history
    ADD CONSTRAINT fk_testing_dl_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- PostgreSQL database dump complete
--

SET search_path TO ml_app,ipa_ops,testmybrain;

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

INSERT INTO schema_migrations (version) VALUES ('20180711150145');

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

