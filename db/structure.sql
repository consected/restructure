--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.20
-- Dumped by pg_dump version 9.5.20

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
-- Name: ipa_ops; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ipa_ops;


--
-- Name: ml_app; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ml_app;


--
-- Name: activity_log_ipa_assignment_phone_screens_callback_set(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.activity_log_ipa_assignment_phone_screens_callback_set() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      initial_screening RECORD;
      -- football_experience RECORD;
      subject_size RECORD;
      tms RECORD;
      mri RECORD;
      sleep RECORD;
      health RECORD;
      tmoca RECORD;
      player_info RECORD;
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


    -- -- Get the latest football experience record
    -- SELECT *
    -- INTO football_experience
    -- FROM ipa_ps_football_experiences
    -- WHERE master_id = NEW.master_id
    -- ORDER BY id DESC
    -- LIMIT 1;

    -- Get the latest subject size record
    SELECT *,
    extract(YEAR from age(birth_date)) age
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

    -- Get the Player Info record
    SELECT *
    INTO player_info
    FROM player_infos
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
      -- ix_not_pro_blank_yes_no,
      -- ix_not_pro_details,
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
      -- if the participant scores <= 19 on TMoCA, the ability to give informed consent should not be set
      CASE WHEN tmoca.tmoca_score <= 19 THEN 'no' ELSE initial_screening.select_still_interested END,

      -- ix_consent_details
      'Responded "yes" to all questions including the final confirmation to continue in Start Phone Screening form. Scored "' || tmoca.tmoca_score || '" in T-MoCA.',

--       --ix_not_pro_blank_yes_no
--       CASE WHEN football_experience.played_in_nfl_blank_yes_no = 'no' THEN 'yes' ELSE 'no' END,
--       --ix_not_pro_details
-- 'Responded "' || football_experience.played_in_nfl_blank_yes_no || '" to question "Have you ever played in the National Football League (NFL)?" in Football Experience form.',
--
      --ix_age_range_blank_yes_no
      CASE WHEN subject_size.age >= 24
        AND subject_size.age <= 59
        THEN 'yes' ELSE 'no' END,
      --ix_age_range_details
'Stated date of birth ' || to_char(subject_size.birth_date, 'Mon dd, YYYY') || ' (age ' || subject_size.age || ' years old) in General Info form.
This ' || CASE WHEN subject_size.birth_date = player_info.birth_date THEN 'matches' ELSE 'does NOT match' END || ' the date of birth in the Participant Details / Person record
(originally from Zeus, although may have been updated locally)',

      --ix_weight_ok_blank_yes_no
      CASE WHEN subject_size.weight <= 450 THEN 'yes' ELSE 'no' END,
      --ix_weight_ok_details
'Stated weight ' || subject_size.weight || ' lbs in General Info form.',

      --ix_no_seizure_blank_yes_no
      CASE WHEN tms.convulsion_or_seizure_blank_yes_no_dont_know = 'no' THEN 'no' ELSE 'yes' END,
      --ix_no_seizure_details
'Responded "' || tms.convulsion_or_seizure_blank_yes_no_dont_know || '" to question "Have you ever had a convulsion or a seizure?" in TMS form.',

      --ix_no_device_impl_blank_yes_no
      CASE WHEN mri.electrical_implants_blank_yes_no_dont_know = 'no' AND health.caridiac_pacemaker_blank_yes_no_dont_know = 'no' THEN 'no' ELSE 'yes' END,
      --ix_no_device_impl_details
'Responded "' || mri.electrical_implants_blank_yes_no_dont_know || '" to question "Do you have any electrical or battery-powered implants such as a cardiac pacemaker or a perfusion pump?" in MRI form.
Responded "' || health.caridiac_pacemaker_blank_yes_no_dont_know || '" to question "Do you have a cardiac pacemaker or intracardiac lines?" in Health form.',

      --ix_no_ferromagnetic_impl_blank_yes_no
      CASE WHEN tms.metal_blank_yes_no_dont_know = 'no'
        AND mri.metal_implants_blank_yes_no_dont_know = 'no'
        AND mri.metal_jewelry_blank_yes_no = 'no'
        THEN 'no' ELSE 'yes' END,
      --ix_no_ferromagnetic_impl_details
'Responded "' || tms.metal_blank_yes_no_dont_know || '" to question "Do you have any metal in the brain, skull or elsewhere in the body?" in TMS form.
Responded "' || mri.metal_implants_blank_yes_no_dont_know || '" to question "Do you have any metal implants such as surgical clips, heart valves with steel parts, metal fragments, shrapnel or steel implants?" in MRI form.
Responded "' || mri.metal_jewelry_blank_yes_no || '" to question "Do you have any piercings or other metal jewelry that would not be able to be easily removed before an MRI scan?" in MRI form.',


      --ix_diagnosed_sleep_apnea_blank_yes_no
      CASE WHEN sleep.sleep_disorder_blank_yes_no_dont_know = 'yes' THEN 'yes' ELSE 'no' END,
      --ix_diagnosed_sleep_apnea_details
'Responded "' || sleep.sleep_disorder_blank_yes_no_dont_know || '" to question "Have you ever been diagnosed with sleep apnea or any other sleep disorders (e.g. narcolepsy)" in Sleep form.',

      --ix_diagnosed_heart_stroke_or_meds_blank_yes_no
      CASE WHEN health.other_heart_conditions_blank_yes_no_dont_know = 'yes' THEN 'yes'
      WHEN health.hypertension_medications_blank_yes_no = 'yes' AND health.diabetes_medications_blank_yes_no = 'yes' THEN 'yes'
      WHEN health.hypertension_medications_blank_yes_no = 'yes' AND health.high_cholesterol_medications_blank_yes_no = 'yes' THEN 'yes'
      WHEN health.diabetes_medications_blank_yes_no = 'yes' AND health.high_cholesterol_medications_blank_yes_no = 'yes' THEN 'yes'
      ELSE 'no' END,

      --ix_diagnosed_heart_stroke_or_meds_details
'Responded "' || health.other_heart_conditions_blank_yes_no_dont_know || '" to question "Have you been diagnosed with any other heart conditions or problems (e.g. heart attack, stroke, irregular heart rhythms, heart failure)?" in Health form.
Responded "' || health.hypertension_medications_blank_yes_no || '" to question "Have you been diagnosed with high blood pressure (hypertension)? + IF YES Have you ever or are you currently taking medications to manage these?" in Health form.
Responded "' || health.diabetes_medications_blank_yes_no || '" to question "Have you been diagnosed with diabetes?? + IF YES Have you ever or are you currently taking medications to manage these?" in Health form.
Responded "' || health.high_cholesterol_medications_blank_yes_no || '" to question "Have you been diagnosed with high cholesterol? + IF YES Have you ever or are you currently taking medications to manage these?" in Health form.',

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
'Scored "' || tmoca.tmoca_score || '" in T-MoCA.',

      --ix_no_hemophilia_blank_yes_no
      CASE WHEN health.hemophilia_blank_yes_no_dont_know = 'no' THEN 'no' ELSE 'yes' END,
      --ix_no_hemophilia_details
'Responded "' || health.hemophilia_blank_yes_no_dont_know || '" to question "Do you suffer from hemophilia?" in Health form.',

      --ix_raynauds_ok_blank_yes_no
      CASE WHEN health.raynauds_syndrome_severity_selection = 'moderate' OR
        health.raynauds_syndrome_severity_selection = 'severe'
        THEN 'yes'
        ELSE 'no' END,

      --ix_raynauds_ok_details
'Responded "' || health.raynauds_syndrome_blank_yes_no_dont_know || '" to question "Do you suffer from Raynaud''s syndrome?" in Health form.
Responded "' || health.raynauds_syndrome_severity_selection || '" to follow up question "Would you say that it is mild, moderate or severe?".',

      --ix_mi_ok_blank_yes_no
      CASE WHEN health.other_heart_conditions_blank_yes_no_dont_know = 'no' THEN 'no' ELSE 'yes' END,
      --ix_mi_ok_details
'Responded "' || health.other_heart_conditions_blank_yes_no_dont_know || '" to question "Have you been diagnosed with any other heart conditions or problems (e.g. heart attack, stroke, irregular heart rhythms, heart failure)?" in Health form',

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
      'adl_informant_screener'
    );


  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: adl_screener_one_dk(integer); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.adl_screener_one_dk(response integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF response = 9 THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  END;
$$;


--
-- Name: adl_screener_score_calc(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.adl_screener_score_calc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    score INTEGER;
    dk INTEGER;
  BEGIN

    score :=
      COALESCE(NEW.adl_eat, 0) +
      COALESCE(NEW.adl_walk, 0) +
      COALESCE(NEW.adl_toilet, 0) +
      COALESCE(NEW.adl_bath, 0) +
      COALESCE(NEW.adl_groom, 0) +
      adl_screener_score_dont_know(NEW.adl_dress_a, NEW.adl_dress_aperf, NEW.adl_dress_b) +
      adl_screener_score_dont_know(NEW.adl_phone, NEW.adl_phone_perf) +
      adl_screener_score_dont_know(NEW.adl_tv,
        adl_screener_score_dont_know(NEW.adl_tva, 1),
        adl_screener_score_dont_know(NEW.adl_tvb, 1),
        adl_screener_score_dont_know(NEW.adl_tvc, 1)
      ) +
      adl_screener_score_dont_know(NEW.adl_attnconvo, NEW.adl_attnconvo_part) +
      adl_screener_score_dont_know(NEW.adl_dishes, NEW.adl_dishes_perf) +
      adl_screener_score_dont_know(NEW.adl_belong, NEW.adl_belong_perf) +
      adl_screener_score_dont_know(NEW.adl_beverage, NEW.adl_beverage_perf) +
      adl_screener_score_dont_know(NEW.adl_snack, NEW.adl_snack_prep) +
      adl_screener_score_dont_know(NEW.adl_garbage, NEW.adl_garbage_perf) +
      adl_screener_score_dont_know(NEW.adl_travel, NEW.adl_travel_perf) +
      -- Shopping payment is a second yes/no/don't-know response dependent on the top level shopping response
      adl_screener_score_dont_know(NEW.adl_shop,
        NEW.adl_shop_select,
        adl_screener_score_dont_know(NEW.adl_shop_pay, 1)
      ) +
      adl_screener_score_dont_know(NEW.adl_appt, NEW.adl_appt_aware) +
      -- Make the institutionalized question (originally 1=yes, 0=no) return 0=yes, 1=no, allowing
      -- it to simply multiply the result of the following question to return the score or not
      -- If institutionalized, the following score should be 0
      ABS(COALESCE(NEW.institutionalized___1, 0) - 1) *
        adl_screener_score_dont_know(NEW.adl_alone,
          adl_screener_score_dont_know(NEW.adl_alone_15m, 1),
          adl_screener_score_dont_know(NEW.adl_alone_gt1hr, 1),
          adl_screener_score_dont_know(NEW.adl_alone_lt1hr, 1)
        ) +
      adl_screener_score_dont_know(NEW.adl_currev,
        adl_screener_score_dont_know(NEW.adl_currev_tv, 1),
        adl_screener_score_dont_know(NEW.adl_currev_outhome, 1),
        adl_screener_score_dont_know(NEW.adl_currev_inhome, 1)
      ) +
      adl_screener_score_dont_know(NEW.adl_read,
        adl_screener_score_dont_know(NEW.adl_read_lt1hr, 1),
        adl_screener_score_dont_know(NEW.adl_read_gt1hr, 1)
      ) +
      adl_screener_score_dont_know(NEW.adl_write, NEW.adl_write_complex) +
      adl_screener_score_dont_know(NEW.adl_hob, NEW.adl_hob_perf) +
      adl_screener_score_dont_know(NEW.adl_appl, NEW.adl_appl_perf)
    ;

    dk :=
      adl_screener_one_dk(NEW.adl_dress_a) +
      adl_screener_one_dk(NEW.adl_phone) +
      adl_screener_one_dk(NEW.adl_tv) +
      adl_screener_score_dont_know(NEW.adl_tv,
        adl_screener_one_dk(NEW.adl_tva),
        adl_screener_one_dk(NEW.adl_tvb),
        adl_screener_one_dk(NEW.adl_tvc)
      ) +

      adl_screener_one_dk(NEW.adl_attnconvo) +
      adl_screener_one_dk(NEW.adl_dishes) +
      adl_screener_one_dk(NEW.adl_belong) +
      adl_screener_one_dk(NEW.adl_beverage) +
      adl_screener_one_dk(NEW.adl_snack) +
      adl_screener_one_dk(NEW.adl_garbage) +
      adl_screener_one_dk(NEW.adl_travel) +
      -- Shopping payment is a second yes/no/don't-know response dependent on the top level shopping response
      adl_screener_one_dk(NEW.adl_shop) +
      adl_screener_score_dont_know(NEW.adl_shop,
        adl_screener_one_dk(NEW.adl_shop_pay)
      )+
      adl_screener_one_dk(NEW.adl_appt) +

      ABS(COALESCE(NEW.institutionalized___1, 0) - 1) *
      (
        adl_screener_one_dk(NEW.adl_alone) +
        adl_screener_score_dont_know(NEW.adl_alone,
          adl_screener_one_dk(NEW.adl_alone_15m),
          adl_screener_one_dk(NEW.adl_alone_gt1hr),
          adl_screener_one_dk(NEW.adl_alone_lt1hr)
        )
      ) +

      adl_screener_one_dk(NEW.adl_currev) +

      adl_screener_score_dont_know(NEW.adl_currev,
        adl_screener_one_dk(NEW.adl_currev_tv),
        adl_screener_one_dk(NEW.adl_currev_outhome),
        adl_screener_one_dk(NEW.adl_currev_inhome)
      ) +

      adl_screener_one_dk(NEW.adl_read) +
      adl_screener_score_dont_know(NEW.adl_read,
        adl_screener_one_dk(NEW.adl_read_lt1hr),
        adl_screener_one_dk(NEW.adl_read_gt1hr)
      ) +

      adl_screener_one_dk(NEW.adl_write) +
      adl_screener_one_dk(NEW.adl_hob) +
      adl_screener_one_dk(NEW.adl_appl)
    ;


    NEW.score := score;
    NEW.dk_count := dk;
    raise notice 'Value: %', NEW.score;

    RETURN NEW;
END;
$$;


--
-- Name: adl_screener_score_dont_know(integer, integer[]); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.adl_screener_score_dont_know(init_q integer, VARIADIC scores integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  DECLARE
    l INTEGER;
    i INTEGER;
    total INTEGER;
  BEGIN

    l := array_upper(scores, 1);

    init_q := COALESCE(init_q, 0);


    total := 0;
    FOR i in 1 .. l LOOP
      total := total +  COALESCE(scores[i], 0);
    END LOOP;

    IF init_q = 9 THEN
      RETURN 0;
    ELSE
      RETURN init_q * total;
    END IF;

    END;
$$;


--
-- Name: get_adl_screener_master_id(integer); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.get_adl_screener_master_id(subject_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  matched_master_id INTEGER;
BEGIN


		SELECT ipa.master_id
    INTO matched_master_id
		FROM ml_app.masters m
		INNER JOIN ipa_ops.ipa_assignments ipa
			ON m.id = ipa.master_id
		WHERE
      ipa.ipa_id = subject_id
    LIMIT 1
		;

    RETURN matched_master_id;
END;
$$;


--
-- Name: get_adl_screener_master_id(numeric); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.get_adl_screener_master_id(subject_id numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  matched_master_id INTEGER;
BEGIN


		SELECT ipa.master_id
    INTO matched_master_id
		FROM ml_app.masters m
		INNER JOIN ipa_ops.ipa_assignments ipa
			ON m.id = ipa.master_id
		WHERE
      ipa.ipa_id = subject_id
    LIMIT 1
		;

    RETURN matched_master_id;
END;
$$;


--
-- Name: ipa_ps_tmoca_score_calc(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.ipa_ps_tmoca_score_calc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN


    NEW.tmoca_score :=
      NEW.attn_digit_span +
      NEW.attn_digit_vigilance +
      NEW.attn_digit_calculation +
      NEW.language_repeat +
      NEW.language_fluency +
      NEW.abstraction +
      NEW.delayed_recall +
      NEW.orientation;

    RETURN NEW;
    
  END;
$$;


--
-- Name: log_activity_log_ipa_assignment_adverse_event_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_adverse_event_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_adverse_event_history
                  (
                      master_id,
                      ipa_assignment_id,

                      extra_log_type,
                      select_who,
                      done_when,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_adverse_event_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,

                      NEW.extra_log_type,
                      NEW.select_who,
                      NEW.done_when,
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
-- Name: log_activity_log_ipa_assignment_discussion_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_discussion_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_discussion_history
                  (
                      master_id,
                      ipa_assignment_id,
                      tag_select_contact_role,
                      notes,
                      prev_activity_type,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_discussion_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.tag_select_contact_role,
                      NEW.notes,
                      NEW.prev_activity_type,
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
-- Name: log_activity_log_ipa_assignment_inex_checklist_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_inex_checklist_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                        INSERT INTO activity_log_ipa_assignment_inex_checklist_history
                        (
                            master_id,
                            ipa_assignment_id,
                            prev_activity_type,
                            select_subject_eligibility,
                            signed_no_yes,
                            notes,
                            contact_role,
                            e_signed_document,
                            e_signed_how,
                            e_signed_at,
                            e_signed_by,
                            e_signed_code,
                            e_signed_status,
                            extra_log_type,
                            user_id,
                            created_at,
                            updated_at,
                            activity_log_ipa_assignment_inex_checklist_id
                            )
                        SELECT
                            NEW.master_id,
                            NEW.ipa_assignment_id,
                            NEW.prev_activity_type,
                            NEW.select_subject_eligibility,
                            NEW.signed_no_yes,
                            NEW.notes,
                            NEW.contact_role,
                            NEW.e_signed_document,
                            NEW.e_signed_how,
                            NEW.e_signed_at,
                            NEW.e_signed_by,
                            NEW.e_signed_code,
                            NEW.e_signed_status,
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
-- Name: log_activity_log_ipa_assignment_med_nav_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_med_nav_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_med_nav_history
                  (
                      master_id,
                      ipa_assignment_id,
                      select_activity,
                      activity_date,
                      select_contact,
                      select_direction,
                      select_result,
                      select_next_step,
                      follow_up_when,
                      follow_up_time,
                      notes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_med_nav_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.select_activity,
                      NEW.activity_date,
                      NEW.select_contact,
                      NEW.select_direction,
                      NEW.select_result,
                      NEW.select_next_step,
                      NEW.follow_up_when,
                      NEW.follow_up_time,
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
-- Name: log_activity_log_ipa_assignment_minor_deviation_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_minor_deviation_update() RETURNS trigger
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
-- Name: log_activity_log_ipa_assignment_navigation_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_navigation_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO activity_log_ipa_assignment_navigation_history
            (
                master_id,
                ipa_assignment_id,
                event_date,
                select_station,
                select_navigator,
                select_pi,
                location,
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
                NEW.select_navigator,
                NEW.select_pi,
                NEW.location,
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
-- Name: log_activity_log_ipa_assignment_phone_screen_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_phone_screen_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_phone_screen_history
                  (
                      master_id,
                      ipa_assignment_id,
                      callback_required,
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
                      NEW.callback_required,
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
-- Name: log_activity_log_ipa_assignment_post_visit_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_post_visit_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_post_visit_history
                  (
                      master_id,
                      ipa_assignment_id,
                      select_activity,
                      activity_date,
                      select_record_from_player_contacts,
                      select_record_from_addresses,
                      select_direction,
                      select_who,
                      select_result,
                      select_next_step,
                      follow_up_when,
                      follow_up_time,
                      notes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_post_visit_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.select_activity,
                      NEW.activity_date,
                      NEW.select_record_from_player_contacts,
                      NEW.select_record_from_addresses,
                      NEW.select_direction,
                      NEW.select_who,
                      NEW.select_result,
                      NEW.select_next_step,
                      NEW.follow_up_when,
                      NEW.follow_up_time,
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
-- Name: log_activity_log_ipa_assignment_protocol_deviation_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_protocol_deviation_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_protocol_deviation_history
                  (
                      master_id,
                      ipa_assignment_id,

                      extra_log_type,
                      select_who,
                      done_when,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_protocol_deviation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,

                      NEW.extra_log_type,
                      NEW.select_who,
                      NEW.done_when,
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
-- Name: log_activity_log_ipa_assignment_summary_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_summary_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_summary_history
                  (
                      master_id,
                      ipa_assignment_id,
                      notes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_summary_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
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
-- Name: log_activity_log_ipa_assignment_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_activity_log_ipa_assignment_update() RETURNS trigger
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
-- Name: log_emergency_contact_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_emergency_contact_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO emergency_contact_history
            (
                master_id,
                rec_type,
                data,
                first_name,
                last_name,
                select_relationship,
                rank,
                user_id,
                created_at,
                updated_at,
                emergency_contact_id
                )
            SELECT
                NEW.master_id,
                NEW.rec_type,
                NEW.data,
                NEW.first_name,
                NEW.last_name,
                NEW.select_relationship,
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
-- Name: log_ipa_adl_informant_screener_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_adl_informant_screener_update() RETURNS trigger
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
                      institutionalized_no_yes,
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

                      npi_infor,
                      npi_inforsp,
                      npi_delus,
                      npi_delussev,
                      npi_hallu,
                      npi_hallusev,
                      npi_agita,
                      npi_agitasev,
                      npi_depre,
                      npi_depresev,
                      npi_anxie,
                      npi_anxiesev,
                      npi_elati,
                      npi_elatisev,
                      npi_apath,
                      npi_apathsev,
                      npi_disin,
                      npi_disinsev,
                      npi_irrit,
                      npi_irritsev,
                      npi_motor,
                      npi_motorsev,
                      npi_night,
                      npi_nightsev,
                      npi_appet,
                      npi_appetsev,

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
                      NEW.institutionalized_no_yes,
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

                      NEW.npi_infor,
                      NEW.npi_inforsp,
                      NEW.npi_delus,
                      NEW.npi_delussev,
                      NEW.npi_hallu,
                      NEW.npi_hallusev,
                      NEW.npi_agita,
                      NEW.npi_agitasev,
                      NEW.npi_depre,
                      NEW.npi_depresev,
                      NEW.npi_anxie,
                      NEW.npi_anxiesev,
                      NEW.npi_elati,
                      NEW.npi_elatisev,
                      NEW.npi_apath,
                      NEW.npi_apathsev,
                      NEW.npi_disin,
                      NEW.npi_disinsev,
                      NEW.npi_irrit,
                      NEW.npi_irritsev,
                      NEW.npi_motor,
                      NEW.npi_motorsev,
                      NEW.npi_night,
                      NEW.npi_nightsev,
                      NEW.npi_appet,
                      NEW.npi_appetsev,



                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_adverse_event_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_adverse_event_update() RETURNS trigger
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
-- Name: log_ipa_appointment_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_appointment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO ipa_appointment_history
            (
                master_id,
                visit_start_date,
                visit_end_date,
                select_status,
                select_schedule,
                notes,
                user_id,
                created_at,
                updated_at,
                ipa_appointment_id
                )
            SELECT
                NEW.master_id,
                NEW.visit_start_date,
                NEW.visit_end_date,
                NEW.select_status,
                NEW.select_schedule,
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
-- Name: log_ipa_assignment_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_assignment_update() RETURNS trigger
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
-- Name: log_ipa_consent_mailing_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_consent_mailing_update() RETURNS trigger
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
-- Name: log_ipa_exit_interview_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_exit_interview_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_exit_interview_history
                  (
                      master_id,
                      select_all_results_returned,
                      notes,
                      labs_returned_yes_no,
                      labs_notes,
                      dexa_returned_yes_no,
                      dexa_notes,
                      brain_mri_returned_yes_no,
                      brain_mri_notes,
                      neuro_psych_returned_yes_no,
                      neuro_psych_notes,
                      assisted_finding_provider_yes_no,
                      assistance_notes,
                      other_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_exit_interview_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_all_results_returned,
                      NEW.notes,
                      NEW.labs_returned_yes_no,
                      NEW.labs_notes,
                      NEW.dexa_returned_yes_no,
                      NEW.dexa_notes,
                      NEW.brain_mri_returned_yes_no,
                      NEW.brain_mri_notes,
                      NEW.neuro_psych_returned_yes_no,
                      NEW.neuro_psych_notes,
                      NEW.assisted_finding_provider_yes_no,
                      NEW.assistance_notes,
                      NEW.other_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_four_wk_followup_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_four_wk_followup_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_four_wk_followup_history
                  (
                      master_id,
                      select_all_results_returned,
                      select_sensory_testing_returned,
                      sensory_testing_notes,
                      select_liver_mri_returned,
                      liver_mri_notes,
                      select_physical_function_returned,
                      physical_function_notes,
                      select_eeg_returned,
                      eeg_notes,
                      select_sleep_returned,
                      sleep_notes,
                      select_cardiology_returned,
                      cardiology_notes,
                      select_xray_returned,
                      xray_notes,
                      assisted_finding_provider_yes_no,
                      assistance_notes,
                      other_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_four_wk_followup_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_all_results_returned,
                      NEW.select_sensory_testing_returned,
                      NEW.sensory_testing_notes,
                      NEW.select_liver_mri_returned,
                      NEW.liver_mri_notes,
                      NEW.select_physical_function_returned,
                      NEW.physical_function_notes,
                      NEW.select_eeg_returned,
                      NEW.eeg_notes,
                      NEW.select_sleep_returned,
                      NEW.sleep_notes,
                      NEW.select_cardiology_returned,
                      NEW.cardiology_notes,
                      NEW.select_xray_returned,
                      NEW.xray_notes,
                      NEW.assisted_finding_provider_yes_no,
                      NEW.assistance_notes,
                      NEW.other_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_hotel_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_hotel_update() RETURNS trigger
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
                      ipa_hotel_id,
                      check_in_date,
                      check_in_time,
                      check_out_date,
                      check_out_time
                      )
                  SELECT
                      NEW.master_id,
                      NEW.hotel,
                      NEW.room_number,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id,
                      NEW.check_in_date,
                      NEW.check_in_time,
                      NEW.check_out_date,
                      NEW.check_out_time
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_incidental_finding_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_incidental_finding_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_incidental_finding_history
                  (
                      master_id,
                      anthropometrics_check,
                      anthropometrics_date,
                      anthropometrics_notes,
                      lab_results_check,
                      lab_results_date,
                      lab_results_notes,
                      dexa_check,
                      dexa_date,
                      dexa_notes,
                      brain_mri_check,
                      brain_mri_date,
                      brain_mri_notes,
                      neuro_psych_check,
                      neuro_psych_date,
                      neuro_psych_notes,
                      sensory_testing_check,
                      sensory_testing_date,
                      sensory_testing_notes,
                      liver_mri_check,
                      liver_mri_date,
                      liver_mri_notes,
                      physical_function_check,
                      physical_function_date,
                      physical_function_notes,
                      eeg_check,
                      eeg_date,
                      eeg_notes,
                      sleep_check,
                      sleep_date,
                      sleep_notes,
                      cardiac_check,
                      cardiac_date,
                      cardiac_notes,
                      xray_check,
                      xray_date,
                      xray_notes,
                      other_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_incidental_finding_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.anthropometrics_check,
                      NEW.anthropometrics_date,
                      NEW.anthropometrics_notes,
                      NEW.lab_results_check,
                      NEW.lab_results_date,
                      NEW.lab_results_notes,
                      NEW.dexa_check,
                      NEW.dexa_date,
                      NEW.dexa_notes,
                      NEW.brain_mri_check,
                      NEW.brain_mri_date,
                      NEW.brain_mri_notes,
                      NEW.neuro_psych_check,
                      NEW.neuro_psych_date,
                      NEW.neuro_psych_notes,
                      NEW.sensory_testing_check,
                      NEW.sensory_testing_date,
                      NEW.sensory_testing_notes,
                      NEW.liver_mri_check,
                      NEW.liver_mri_date,
                      NEW.liver_mri_notes,
                      NEW.physical_function_check,
                      NEW.physical_function_date,
                      NEW.physical_function_notes,
                      NEW.eeg_check,
                      NEW.eeg_date,
                      NEW.eeg_notes,
                      NEW.sleep_check,
                      NEW.sleep_date,
                      NEW.sleep_notes,
                      NEW.cardiac_check,
                      NEW.cardiac_date,
                      NEW.cardiac_notes,
                      NEW.xray_check,
                      NEW.xray_date,
                      NEW.xray_notes,
                      NEW.other_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_inex_checklist_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_inex_checklist_update() RETURNS trigger
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
                select_subject_eligibility,
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
                NEW.select_subject_eligibility,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_ipa_initial_screening_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_initial_screening_update() RETURNS trigger
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
                      follow_up_date,
                      follow_up_time,
                      notes,
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
-- Name: log_ipa_medical_detail_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_medical_detail_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_medical_detail_history
                  (
                      master_id,
                      convulsion_or_seizure_blank_yes_no_dont_know,
                      convulsion_or_seizure_details,
                      sleep_disorder_blank_yes_no_dont_know,
                      sleep_disorder_details,
                      sleep_apnea_device_no_yes,
                      sleep_apnea_device_details,
                      chronic_pain_blank_yes_no,
                      chronic_pain_details,
                      chronic_pain_meds_blank_yes_no_dont_know,
                      chronic_pain_meds_details,
                      hypertension_diagnosis_blank_yes_no_dont_know,
                      hypertension_medications_blank_yes_no,
                      hypertension_diagnosis_details,
                      diabetes_diagnosis_blank_yes_no_dont_know,
                      diabetes_medications_blank_yes_no,
                      diabetes_diagnosis_details,
                      hemophilia_blank_yes_no_dont_know,
                      hemophilia_details,
                      high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      high_cholesterol_medications_blank_yes_no,
                      high_cholesterol_diagnosis_details,
                      caridiac_pacemaker_blank_yes_no_dont_know,
                      caridiac_pacemaker_details,
                      other_heart_conditions_blank_yes_no_dont_know,
                      other_heart_conditions_details,
                      memory_problems_blank_yes_no_dont_know,
                      memory_problems_details,
                      mental_health_conditions_blank_yes_no_dont_know,
                      mental_health_conditions_details,
                      mental_health_help_blank_yes_no_dont_know,
                      mental_health_help_details,
                      neurological_problems_blank_yes_no_dont_know,
                      neurological_problems_details,
                      past_mri_yes_no_dont_know,
                      past_mri_details,
                      metal_implants_blank_yes_no_dont_know,
                      metal_implants_details,
                      metal_implants_mri_approval_details,
                      dietary_restrictions_blank_yes_no_dont_know,
                      dietary_restrictions_details,
                      radiation_blank_yes_no,
                      radiation_details,                      
                      user_id,
                      created_at,
                      updated_at,
                      ipa_medical_detail_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.convulsion_or_seizure_blank_yes_no_dont_know,
                      NEW.convulsion_or_seizure_details,
                      NEW.sleep_disorder_blank_yes_no_dont_know,
                      NEW.sleep_disorder_details,
                      NEW.sleep_apnea_device_no_yes,
                      NEW.sleep_apnea_device_details,
                      NEW.chronic_pain_blank_yes_no,
                      NEW.chronic_pain_details,
                      NEW.chronic_pain_meds_blank_yes_no_dont_know,
                      NEW.chronic_pain_meds_details,
                      NEW.hypertension_diagnosis_blank_yes_no_dont_know,
                      NEW.hypertension_medications_blank_yes_no,
                      NEW.hypertension_diagnosis_details,
                      NEW.diabetes_diagnosis_blank_yes_no_dont_know,
                      NEW.diabetes_medications_blank_yes_no,
                      NEW.diabetes_diagnosis_details,
                      NEW.hemophilia_blank_yes_no_dont_know,
                      NEW.hemophilia_details,
                      NEW.high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      NEW.high_cholesterol_medications_blank_yes_no,
                      NEW.high_cholesterol_diagnosis_details,
                      NEW.caridiac_pacemaker_blank_yes_no_dont_know,
                      NEW.caridiac_pacemaker_details,
                      NEW.other_heart_conditions_blank_yes_no_dont_know,
                      NEW.other_heart_conditions_details,
                      NEW.memory_problems_blank_yes_no_dont_know,
                      NEW.memory_problems_details,
                      NEW.mental_health_conditions_blank_yes_no_dont_know,
                      NEW.mental_health_conditions_details,
                      NEW.mental_health_help_blank_yes_no_dont_know,
                      NEW.mental_health_help_details,
                      NEW.neurological_problems_blank_yes_no_dont_know,
                      NEW.neurological_problems_details,
                      NEW.past_mri_yes_no_dont_know,
                      NEW.past_mri_details,
                      NEW.metal_implants_blank_yes_no_dont_know,
                      NEW.metal_implants_details,
                      NEW.metal_implants_mri_approval_details,
                      NEW.dietary_restrictions_blank_yes_no_dont_know,
                      NEW.dietary_restrictions_details,
                      NEW.radiation_blank_yes_no,
                      NEW.radiation_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_medication_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_medication_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_medication_history
                  (
                      master_id,
                      current_meds_blank_yes_no_dont_know,
                      current_meds_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_medication_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.current_meds_blank_yes_no_dont_know,
                      NEW.current_meds_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_mednav_followup_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_mednav_followup_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_mednav_followup_history
                  (
                      master_id,
                      anthropometrics_check,
                      anthropometrics_notes,
                      lab_results_check,
                      lab_results_notes,
                      dexa_check,
                      dexa_notes,
                      brain_mri_check,
                      brain_mri_notes,
                      neuro_psych_check,
                      neuro_psych_notes,
                      sensory_testing_check,
                      sensory_testing_notes,
                      liver_mri_check,
                      liver_mri_notes,
                      physical_function_check,
                      physical_function_notes,
                      eeg_check,
                      eeg_notes,
                      sleep_check,
                      sleep_notes,
                      cardiac_check,
                      cardiac_notes,
                      xray_check,
                      xray_notes,
                      assisted_finding_provider_yes_no,
                      assistance_notes,
                      other_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_mednav_followup_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.anthropometrics_check,
                      NEW.anthropometrics_notes,
                      NEW.lab_results_check,
                      NEW.lab_results_notes,
                      NEW.dexa_check,
                      NEW.dexa_notes,
                      NEW.brain_mri_check,
                      NEW.brain_mri_notes,
                      NEW.neuro_psych_check,
                      NEW.neuro_psych_notes,
                      NEW.sensory_testing_check,
                      NEW.sensory_testing_notes,
                      NEW.liver_mri_check,
                      NEW.liver_mri_notes,
                      NEW.physical_function_check,
                      NEW.physical_function_notes,
                      NEW.eeg_check,
                      NEW.eeg_notes,
                      NEW.sleep_check,
                      NEW.sleep_notes,
                      NEW.cardiac_check,
                      NEW.cardiac_notes,
                      NEW.xray_check,
                      NEW.xray_notes,
                      NEW.assisted_finding_provider_yes_no,
                      NEW.assistance_notes,
                      NEW.other_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_mednav_provider_comm_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_mednav_provider_comm_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_mednav_provider_comm_history
                  (
                      master_id,
                      anthropometrics_check,
                      anthropometrics_notes,
                      lab_results_check,
                      lab_results_notes,
                      dexa_check,
                      dexa_notes,
                      brain_mri_check,
                      brain_mri_notes,
                      neuro_psych_check,
                      neuro_psych_notes,
                      sensory_testing_check,
                      sensory_testing_notes,
                      liver_mri_check,
                      liver_mri_notes,
                      physical_function_check,
                      physical_function_notes,
                      eeg_check,
                      eeg_notes,
                      sleep_check,
                      sleep_notes,
                      cardiac_check,
                      cardiac_notes,
                      xray_check,
                      xray_notes,
                      other_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_mednav_provider_comm_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.anthropometrics_check,
                      NEW.anthropometrics_notes,
                      NEW.lab_results_check,
                      NEW.lab_results_notes,
                      NEW.dexa_check,
                      NEW.dexa_notes,
                      NEW.brain_mri_check,
                      NEW.brain_mri_notes,
                      NEW.neuro_psych_check,
                      NEW.neuro_psych_notes,
                      NEW.sensory_testing_check,
                      NEW.sensory_testing_notes,
                      NEW.liver_mri_check,
                      NEW.liver_mri_notes,
                      NEW.physical_function_check,
                      NEW.physical_function_notes,
                      NEW.eeg_check,
                      NEW.eeg_notes,
                      NEW.sleep_check,
                      NEW.sleep_notes,
                      NEW.cardiac_check,
                      NEW.cardiac_notes,
                      NEW.xray_check,
                      NEW.xray_notes,
                      NEW.other_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_mednav_provider_report_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_mednav_provider_report_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_mednav_provider_report_history
                  (
                      master_id,
                      report_delivery_date,
                      anthropometrics_check,
                      anthropometrics_notes,
                      lab_results_check,
                      lab_results_notes,
                      dexa_check,
                      dexa_notes,
                      brain_mri_check,
                      brain_mri_notes,
                      neuro_psych_check,
                      neuro_psych_notes,
                      sensory_testing_check,
                      sensory_testing_notes,
                      liver_mri_check,
                      liver_mri_notes,
                      physical_function_check,
                      physical_function_notes,
                      eeg_check,
                      eeg_notes,
                      sleep_check,
                      sleep_notes,
                      cardiac_check,
                      cardiac_notes,
                      xray_check,
                      xray_notes,
                      other_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_mednav_provider_report_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.report_delivery_date,
                      NEW.anthropometrics_check,
                      NEW.anthropometrics_notes,
                      NEW.lab_results_check,
                      NEW.lab_results_notes,
                      NEW.dexa_check,
                      NEW.dexa_notes,
                      NEW.brain_mri_check,
                      NEW.brain_mri_notes,
                      NEW.neuro_psych_check,
                      NEW.neuro_psych_notes,
                      NEW.sensory_testing_check,
                      NEW.sensory_testing_notes,
                      NEW.liver_mri_check,
                      NEW.liver_mri_notes,
                      NEW.physical_function_check,
                      NEW.physical_function_notes,
                      NEW.eeg_check,
                      NEW.eeg_notes,
                      NEW.sleep_check,
                      NEW.sleep_notes,
                      NEW.cardiac_check,
                      NEW.cardiac_notes,
                      NEW.xray_check,
                      NEW.xray_notes,
                      NEW.other_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_payment_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_payment_update() RETURNS trigger
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
-- Name: log_ipa_protocol_deviation_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_protocol_deviation_update() RETURNS trigger
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
-- Name: log_ipa_protocol_exception_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_protocol_exception_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_protocol_exception_history
                  (
                      master_id,
                      exception_date,
                      exception_description,
                      risks_and_benefits_notes,
                      informed_consent_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_protocol_exception_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.exception_date,
                      NEW.exception_description,
                      NEW.risks_and_benefits_notes,
                      NEW.informed_consent_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_ps_comp_review_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_ps_comp_review_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_comp_review_history
                  (
                      master_id,
                      how_long_notes,
                      clinical_care_or_research_notes,
                      two_assessments_notes,
                      risks_notes,
                      study_drugs_notes,
                      compensation_notes,
                      location_notes,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_comp_review_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.how_long_notes,
                      NEW.clinical_care_or_research_notes,
                      NEW.two_assessments_notes,
                      NEW.risks_notes,
                      NEW.study_drugs_notes,
                      NEW.compensation_notes,
                      NEW.location_notes,
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
-- Name: log_ipa_ps_football_experience_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_ps_football_experience_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_football_experience_history
                  (
                      master_id,
                      age,
                      played_in_nfl_blank_yes_no,
--                      played_before_nfl_blank_yes_no,
--                      football_experience_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_football_experience_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.age,
                      NEW.played_in_nfl_blank_yes_no,
--                      NEW.played_before_nfl_blank_yes_no,
--                      NEW.football_experience_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_ps_health_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_ps_health_update() RETURNS trigger
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

                      hypertension_diagnosis_blank_yes_no_dont_know,
                      hypertension_medications_blank_yes_no,
                      hypertension_diagnosis_details,

                      diabetes_diagnosis_blank_yes_no_dont_know,
                      diabetes_medications_blank_yes_no,
                      diabetes_diagnosis_details,

                      high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      high_cholesterol_medications_blank_yes_no,
                      high_cholesterol_diagnosis_details,

                      other_heart_conditions_blank_yes_no_dont_know,
                      other_heart_conditions_details,

                      heart_surgeries_blank_yes_no_dont_know,
                      heart_surgeries_details,
                      caridiac_pacemaker_blank_yes_no_dont_know,
                      caridiac_pacemaker_details,

                      memory_problems_blank_yes_no_dont_know,
                      memory_problems_details,
                      mental_health_conditions_blank_yes_no_dont_know,
                      mental_health_conditions_details,

                      mental_health_help_blank_yes_no_dont_know,
                      mental_health_help_details,

                      neurological_problems_blank_yes_no_dont_know,
                      neurological_problems_details,

                      neurological_surgeries_blank_yes_no_dont_know,
                      neurological_surgeries_details,

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

                      NEW.hypertension_diagnosis_blank_yes_no_dont_know,
                      NEW.hypertension_medications_blank_yes_no,
                      NEW.hypertension_diagnosis_details,

                      NEW.diabetes_diagnosis_blank_yes_no_dont_know,
                      NEW.diabetes_medications_blank_yes_no,
                      NEW.diabetes_diagnosis_details,

                      NEW.high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      NEW.high_cholesterol_medications_blank_yes_no,
                      NEW.high_cholesterol_diagnosis_details,

                      NEW.other_heart_conditions_blank_yes_no_dont_know,
                      NEW.other_heart_conditions_details,

                      NEW.heart_surgeries_blank_yes_no_dont_know,
                      NEW.heart_surgeries_details,
                      NEW.caridiac_pacemaker_blank_yes_no_dont_know,
                      NEW.caridiac_pacemaker_details,

                      NEW.memory_problems_blank_yes_no_dont_know,
                      NEW.memory_problems_details,
                      NEW.mental_health_conditions_blank_yes_no_dont_know,
                      NEW.mental_health_conditions_details,

                      NEW.mental_health_help_blank_yes_no_dont_know,
                      NEW.mental_health_help_details,

                      NEW.neurological_problems_blank_yes_no_dont_know,
                      NEW.neurological_problems_details,

                      NEW.neurological_surgeries_blank_yes_no_dont_know,
                      NEW.neurological_surgeries_details,

                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_ps_informant_detail_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_ps_informant_detail_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_informant_detail_history
                  (
                      master_id,
                      first_name,
                      last_name,
                      email,
                      phone,
                      relationship_to_participant,
                      contact_information_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_informant_detail_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.first_name,
                      NEW.last_name,
                      NEW.email,
                      NEW.phone,
                      NEW.relationship_to_participant,
                      NEW.contact_information_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_ps_initial_screening_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_ps_initial_screening_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_initial_screening_history
                  (
                      master_id,
                      select_is_good_time_to_speak,
                      looked_at_website_yes_no,
                      select_may_i_begin,
                      any_questions_blank_yes_no,
                      --- Note we retain select_still_interested since it is used in the withdrawal logic
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
                      NEW.looked_at_website_yes_no,
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
-- Name: log_ipa_ps_mri_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_ps_mri_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO ipa_ps_mri_history
            (
                master_id,
                past_mri_yes_no_dont_know,
                past_mri_details,
                electrical_implants_blank_yes_no_dont_know,
                electrical_implants_details,
                metal_implants_blank_yes_no_dont_know,
                metal_implants_details,
                metal_jewelry_blank_yes_no,
                hearing_aid_blank_yes_no,
                radiation_blank_yes_no,
                radiation_details,
                user_id,
                created_at,
                updated_at,
                ipa_ps_mri_id
                )
            SELECT
                NEW.master_id,
                NEW.past_mri_yes_no_dont_know,
                NEW.past_mri_details,
                NEW.electrical_implants_blank_yes_no_dont_know,
                NEW.electrical_implants_details,
                NEW.metal_implants_blank_yes_no_dont_know,
                NEW.metal_implants_details,
                NEW.metal_jewelry_blank_yes_no,
                NEW.hearing_aid_blank_yes_no,
                NEW.radiation_blank_yes_no,
                NEW.radiation_details,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_ipa_ps_size_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_ps_size_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_size_history
                  (
                      master_id,
                      birth_date,
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
                      NEW.birth_date,
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
-- Name: log_ipa_ps_sleep_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_ps_sleep_update() RETURNS trigger
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
-- Name: log_ipa_ps_tmoca_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_ps_tmoca_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_ps_tmoca_history
                  (
                      master_id,
                      tmoca_version,
                      attn_digit_span,
                      attn_digit_vigilance,
                      attn_digit_calculation,
                      language_repeat,
                      language_fluency,
                      abstraction,
                      delayed_recall,
                      orientation,
                      tmoca_score,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_tmoca_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.tmoca_version,
                      NEW.attn_digit_span,
                      NEW.attn_digit_vigilance,
                      NEW.attn_digit_calculation,
                      NEW.language_repeat,
                      NEW.language_fluency,
                      NEW.abstraction,
                      NEW.delayed_recall,
                      NEW.orientation,
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
-- Name: log_ipa_ps_tms_test_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_ps_tms_test_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
          INSERT INTO ipa_ps_tms_test_history
          (
              master_id,
              convulsion_or_seizure_blank_yes_no_dont_know,
              convulsion_or_seizure_details,
              epilepsy_blank_yes_no_dont_know,
              epilepsy_details,
              fainting_blank_yes_no_dont_know,
              fainting_details,
              concussion_blank_yes_no_dont_know,
              loss_of_conciousness_details,
              hairstyle_scalp_blank_yes_no_dont_know,
              hairstyle_scalp_details,
              hearing_problems_blank_yes_no_dont_know,
              cochlear_implants_blank_yes_no_dont_know,
              metal_blank_yes_no_dont_know,
              metal_details,
              neurostimulator_blank_yes_no_dont_know,
              neurostimulator_details,
              med_infusion_device_blank_yes_no_dont_know,
              med_infusion_device_details,
              past_tms_blank_yes_no_dont_know,
              past_tms_details,
              current_meds_blank_yes_no_dont_know,
              current_meds_details,
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
              NEW.convulsion_or_seizure_blank_yes_no_dont_know,
              NEW.convulsion_or_seizure_details,
              NEW.epilepsy_blank_yes_no_dont_know,
              NEW.epilepsy_details,
              NEW.fainting_blank_yes_no_dont_know,
              NEW.fainting_details,
              NEW.concussion_blank_yes_no_dont_know,
              NEW.loss_of_conciousness_details,
              NEW.hairstyle_scalp_blank_yes_no_dont_know,
              NEW.hairstyle_scalp_details,
              NEW.hearing_problems_blank_yes_no_dont_know,
              NEW.cochlear_implants_blank_yes_no_dont_know,
              NEW.metal_blank_yes_no_dont_know,
              NEW.metal_details,
              NEW.neurostimulator_blank_yes_no_dont_know,
              NEW.neurostimulator_details,
              NEW.med_infusion_device_blank_yes_no_dont_know,
              NEW.med_infusion_device_details,
              NEW.past_tms_blank_yes_no_dont_know,
              NEW.past_tms_details,
              NEW.current_meds_blank_yes_no_dont_know,
              NEW.current_meds_details,
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
-- Name: log_ipa_reimbursement_req_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_reimbursement_req_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_reimbursement_req_history
                  (
                      master_id,
                      participant_requested_yes_no,
                      submission_date,
                      additional_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_reimbursement_req_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.participant_requested_yes_no,
                      NEW.submission_date,
                      NEW.additional_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_screening_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_screening_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_screening_history
                  (
                      master_id,
                      eligible_for_study_blank_yes_no,
                      requires_study_partner_blank_yes_no,
                      notes,
                      good_time_to_speak_blank_yes_no,
                      callback_date,
                      callback_time,
                      still_interested_blank_yes_no,
                      not_interested_notes,
                      ineligible_notes,
                      eligible_notes,
                      contact_in_future_yes_no,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_screening_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.eligible_for_study_blank_yes_no,
                      NEW.requires_study_partner_blank_yes_no,
                      NEW.notes,
                      NEW.good_time_to_speak_blank_yes_no,
                      NEW.callback_date,
                      NEW.callback_time,
                      NEW.still_interested_blank_yes_no,
                      NEW.not_interested_notes,
                      NEW.ineligible_notes,
                      NEW.eligible_notes,
                      NEW.contact_in_future_yes_no,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_special_consideration_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_special_consideration_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_special_consideration_history
                  (
                      master_id,
                      travel_with_wife_yes_no,
                      travel_with_wife_details,
                      mmse_yes_no,
                      tmoca_score,
                      mmse_details,
                      bringing_cpap_yes_no,
                      tms_exempt_yes_no,
                      taking_med_for_mri_pet_yes_no,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_special_consideration_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.travel_with_wife_yes_no,
                      NEW.travel_with_wife_details,
                      NEW.mmse_yes_no,
                      NEW.tmoca_score,
                      NEW.mmse_details,
                      NEW.bringing_cpap_yes_no,
                      NEW.tms_exempt_yes_no,
                      NEW.taking_med_for_mri_pet_yes_no,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_station_contact_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_station_contact_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_station_contact_history
                  (
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
-- Name: log_ipa_survey_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_survey_update() RETURNS trigger
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
-- Name: log_ipa_transportation_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_transportation_update() RETURNS trigger
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
-- Name: log_ipa_two_wk_followup_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_two_wk_followup_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO ipa_two_wk_followup_history
                  (
                      master_id,
                      participant_had_qs_yes_no,
                      participant_qs_notes,
                      assisted_finding_provider_yes_no,
                      assistance_notes,
                      other_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_two_wk_followup_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.participant_had_qs_yes_no,
                      NEW.participant_qs_notes,
                      NEW.assisted_finding_provider_yes_no,
                      NEW.assistance_notes,
                      NEW.other_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


--
-- Name: log_ipa_withdrawal_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_ipa_withdrawal_update() RETURNS trigger
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
-- Name: log_mrn_number_update(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.log_mrn_number_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              BEGIN
                  INSERT INTO mrn_number_history
                  (
                      master_id,
                      mrn_id,
                      select_organization,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      mrn_number_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.mrn_id,
                      NEW.select_organization,
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
-- Name: sync_new_adl_screener(); Type: FUNCTION; Schema: ipa_ops; Owner: -
--

CREATE FUNCTION ipa_ops.sync_new_adl_screener() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    matched_master_id INTEGER;
    new_id INTEGER;
  BEGIN

    matched_master_id :=  get_adl_screener_master_id(new.redcap_survey_identifier);


    insert into ipa_adl_informant_screeners
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
        institutionalized_no_yes,
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
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
        multi_select_pastimes,

        pastime_other,
        pastimes_only_at_daycare_no_yes,
        select_pastimes_only_at_daycare_performance,
        use_household_appliance_yes_no_dont_know,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
        multi_select_household_appliances,
        household_appliance_other,
        select_household_appliance_performance,


        npi_infor,
        npi_inforsp,
        npi_delus,
        npi_delussev,
        npi_hallu,
        npi_hallusev,
        npi_agita,
        npi_agitasev,
        npi_depre,
        npi_depresev,
        npi_anxie,
        npi_anxiesev,
        npi_elati,
        npi_elatisev,
        npi_apath,
        npi_apathsev,
        npi_disin,
        npi_disinsev,
        npi_irrit,
        npi_irritsev,
        npi_motor,
        npi_motorsev,
        npi_night,
        npi_nightsev,
        npi_appet,
        npi_appetsev,

      --
        created_at,
        updated_at
      )
      values
      (
        matched_master_id,
        NEW.adl_eat,
        NEW.adl_walk,
        NEW.adl_toilet,
        NEW.adl_bath,
        NEW.adl_groom,
        NEW.adl_dressa,
        NEW.adl_dressa_perf,
        NEW.adl_dressb,
        CASE WHEN NEW.adl_phone = 0 THEN 'no' WHEN NEW.adl_phone = 1 THEN 'yes' WHEN NEW.adl_phone = 9 THEN 'don''t know' ELSE NEW.adl_phone::varchar END,
        NEW.adl_phone_perf,
        CASE WHEN NEW.adl_tv = 0 THEN 'no' WHEN NEW.adl_tv = 1 THEN 'yes' WHEN NEW.adl_tv = 9 THEN 'don''t know' ELSE NEW.adl_tv::varchar END,
        CASE WHEN NEW.adl_tva = 0 THEN 'no' WHEN NEW.adl_tva = 1 THEN 'yes' WHEN NEW.adl_tva = 9 THEN 'don''t know' ELSE NEW.adl_tva::varchar END,
        CASE WHEN NEW.adl_tvb = 0 THEN 'no' WHEN NEW.adl_tvb = 1 THEN 'yes' WHEN NEW.adl_tvb = 9 THEN 'don''t know' ELSE NEW.adl_tvb::varchar END,
        CASE WHEN NEW.adl_tvc = 0 THEN 'no' WHEN NEW.adl_tvc = 1 THEN 'yes' WHEN NEW.adl_tvc = 9 THEN 'don''t know' ELSE NEW.adl_tvc::varchar END,
        CASE WHEN NEW.adl_attnconvo = 0 THEN 'no' WHEN NEW.adl_attnconvo = 1 THEN 'yes' WHEN NEW.adl_attnconvo = 9 THEN 'don''t know' ELSE NEW.adl_attnconvo::varchar END,
        NEW.adl_attnconvo_part,
        CASE WHEN NEW.adl_dishes = 0 THEN 'no' WHEN NEW.adl_dishes = 1 THEN 'yes' WHEN NEW.adl_dishes = 9 THEN 'don''t know' ELSE NEW.adl_dishes::varchar END,
        NEW.adl_dishes_perf,
        CASE WHEN NEW.adl_belong = 0 THEN 'no' WHEN NEW.adl_belong = 1 THEN 'yes' WHEN NEW.adl_belong = 9 THEN 'don''t know' ELSE NEW.adl_belong::varchar END,
        NEW.adl_belong_perf,
        CASE WHEN NEW.adl_beverage = 0 THEN 'no' WHEN NEW.adl_beverage = 1 THEN 'yes' WHEN NEW.adl_beverage = 9 THEN 'don''t know' ELSE NEW.adl_beverage::varchar END,
        NEW.adl_beverage_perf,
        CASE WHEN NEW.adl_snack = 0 THEN 'no' WHEN NEW.adl_snack = 1 THEN 'yes' WHEN NEW.adl_snack = 9 THEN 'don''t know' ELSE NEW.adl_snack::varchar END,
        NEW.adl_snack_prep,
        CASE WHEN NEW.adl_garbage = 0 THEN 'no' WHEN NEW.adl_garbage = 1 THEN 'yes' WHEN NEW.adl_garbage = 9 THEN 'don''t know' ELSE NEW.adl_garbage::varchar END,
        NEW.adl_garbage_perf,
        CASE WHEN NEW.adl_travel = 0 THEN 'no' WHEN NEW.adl_travel = 1 THEN 'yes' WHEN NEW.adl_travel = 9 THEN 'don''t know' ELSE NEW.adl_travel::varchar END,
        NEW.adl_travel_perf,
        CASE WHEN NEW.adl_shop = 0 THEN 'no' WHEN NEW.adl_shop = 1 THEN 'yes' WHEN NEW.adl_shop = 9 THEN 'don''t know' ELSE NEW.adl_shop::varchar END,
        NEW.adl_shop_select,
        CASE WHEN NEW.adl_shop_pay = 0 THEN 'no' WHEN NEW.adl_shop_pay = 1 THEN 'yes' WHEN NEW.adl_shop_pay = 9 THEN 'don''t know' ELSE NEW.adl_shop_pay::varchar END,
        CASE WHEN NEW.adl_appt = 0 THEN 'no' WHEN NEW.adl_appt = 1 THEN 'yes' WHEN NEW.adl_appt = 9 THEN 'don''t know' ELSE NEW.adl_appt::varchar END,
        NEW.adl_appt_aware,
        CASE WHEN NEW.institutionalized___1 = 0 THEN 'no' WHEN NEW.institutionalized___1 = 1 THEN 'yes' WHEN NEW.institutionalized___1 = 9 THEN 'don''t know' ELSE NEW.institutionalized___1::varchar END,
        CASE WHEN NEW.adl_alone = 0 THEN 'no' WHEN NEW.adl_alone = 1 THEN 'yes' WHEN NEW.adl_alone = 9 THEN 'don''t know' ELSE NEW.adl_alone::varchar END,
        CASE WHEN NEW.adl_alone_15m = 0 THEN 'no' WHEN NEW.adl_alone_15m = 1 THEN 'yes' WHEN NEW.adl_alone_15m = 9 THEN 'don''t know' ELSE NEW.adl_alone_15m::varchar END,
        CASE WHEN NEW.adl_alone_gt1hr = 0 THEN 'no' WHEN NEW.adl_alone_gt1hr = 1 THEN 'yes' WHEN NEW.adl_alone_gt1hr = 9 THEN 'don''t know' ELSE NEW.adl_alone_gt1hr::varchar END,
        CASE WHEN NEW.adl_alone_lt1hr = 0 THEN 'no' WHEN NEW.adl_alone_lt1hr = 1 THEN 'yes' WHEN NEW.adl_alone_lt1hr = 9 THEN 'don''t know' ELSE NEW.adl_alone_lt1hr::varchar END,
        CASE WHEN NEW.adl_currev = 0 THEN 'no' WHEN NEW.adl_currev = 1 THEN 'yes' WHEN NEW.adl_currev = 9 THEN 'don''t know' ELSE NEW.adl_currev::varchar END,
        CASE WHEN NEW.adl_currev_tv = 0 THEN 'no' WHEN NEW.adl_currev_tv = 1 THEN 'yes' WHEN NEW.adl_currev_tv = 9 THEN 'don''t know' ELSE NEW.adl_currev_tv::varchar END,
        CASE WHEN NEW.adl_currev_outhome = 0 THEN 'no' WHEN NEW.adl_currev_outhome = 1 THEN 'yes' WHEN NEW.adl_currev_outhome = 9 THEN 'don''t know' ELSE NEW.adl_currev_outhome::varchar END,
        CASE WHEN NEW.adl_currev_inhome = 0 THEN 'no' WHEN NEW.adl_currev_inhome = 1 THEN 'yes' WHEN NEW.adl_currev_inhome = 9 THEN 'don''t know' ELSE NEW.adl_currev_inhome::varchar END,
        CASE WHEN NEW.adl_read = 0 THEN 'no' WHEN NEW.adl_read = 1 THEN 'yes' WHEN NEW.adl_read = 9 THEN 'don''t know' ELSE NEW.adl_read::varchar END,
        CASE WHEN NEW.adl_read_lt1hr = 0 THEN 'no' WHEN NEW.adl_read_lt1hr = 1 THEN 'yes' WHEN NEW.adl_read_lt1hr = 9 THEN 'don''t know' ELSE NEW.adl_read_lt1hr::varchar END,
        CASE WHEN NEW.adl_read_gt1hr = 0 THEN 'no' WHEN NEW.adl_read_gt1hr = 1 THEN 'yes' WHEN NEW.adl_read_gt1hr = 9 THEN 'don''t know' ELSE NEW.adl_read_gt1hr::varchar END,
        CASE WHEN NEW.adl_write = 0 THEN 'no' WHEN NEW.adl_write = 1 THEN 'yes' WHEN NEW.adl_write = 9 THEN 'don''t know' ELSE NEW.adl_write::varchar END,
        NEW.adl_write_complex,
        CASE WHEN NEW.adl_hob = 0 THEN 'no' WHEN NEW.adl_hob = 1 THEN 'yes' WHEN NEW.adl_hob = 9 THEN 'don''t know' ELSE NEW.adl_hob::varchar END,
        --  adl_hobls___gam,
        --  adl_hobls___bing,
        --  adl_hobls___instr,
        --  adl_hobls___read,
        --  adl_hobls___tenn,
        --  adl_hobls___cword,
        --  adl_hobls___knit,
        --  adl_hobls___gard,
        --  adl_hobls___wshop,
        --  adl_hobls___art,
        --  adl_hobls___sew,
        --  adl_hobls___golf,
        --  adl_hobls___fish,
        --  adl_hobls___oth,
        array[NEW.adl_hobls___gam , NEW.adl_hobls___bing, NEW.adl_hobls___instr, NEW.adl_hobls___read, NEW.adl_hobls___tenn, NEW.adl_hobls___cword, NEW.adl_hobls___knit, NEW.adl_hobls___gard, NEW.adl_hobls___wshop, NEW.adl_hobls___art, NEW.adl_hobls___sew, NEW.adl_hobls___golf, NEW.adl_hobls___fish, NEW.adl_hobls___oth ],

        NEW.adl_hobls_oth,
        CASE WHEN NEW.adl_hobdc___1 = 0 THEN 'no' WHEN NEW.adl_hobdc___1 = 1 THEN 'yes' WHEN NEW.adl_hobdc___1 = 9 THEN 'don''t know' ELSE NEW.adl_hobdc___1::varchar END,
        NEW.adl_hob_perf,
        CASE WHEN NEW.adl_appl = 0 THEN 'no' WHEN NEW.adl_appl = 1 THEN 'yes' WHEN NEW.adl_appl = 9 THEN 'don''t know' ELSE NEW.adl_appl::varchar END,
        array[NEW.adl_applls___wash,  NEW.adl_applls___dish, NEW.adl_applls___range, NEW.adl_applls___dry, NEW.adl_applls___toast, NEW.adl_applls___micro, NEW.adl_applls___vac, NEW.adl_applls___toven, NEW.adl_applls___fproc, NEW.adl_applls___oth],
        --  adl_applls___wash,
        --  adl_applls___dish,
        --  adl_applls___range,
        --  adl_applls___dry,
        --  adl_applls___toast,
        --  adl_applls___micro,
        --  adl_applls___vac,
        --  adl_applls___toven,
        --  adl_applls___fproc,
        --  adl_applls___oth,
        NEW.adl_applls_oth,
        NEW.adl_appl_perf,
        --  adl_comm,

        NEW.npi_infor,
        NEW.npi_inforsp,
        NEW.npi_delus,
        NEW.npi_delussev,
        NEW.npi_hallu,
        NEW.npi_hallusev,
        NEW.npi_agita,
        NEW.npi_agitasev,
        NEW.npi_depre,
        NEW.npi_depresev,
        NEW.npi_anxie,
        NEW.npi_anxiesev,
        NEW.npi_elati,
        NEW.npi_elatisev,
        NEW.npi_apath,
        NEW.npi_apathsev,
        NEW.npi_disin,
        NEW.npi_disinsev,
        NEW.npi_irrit,
        NEW.npi_irritsev,
        NEW.npi_motor,
        NEW.npi_motorsev,
        NEW.npi_night,
        NEW.npi_nightsev,
        NEW.npi_appet,
        NEW.npi_appetsev,



        NEW.adcs_npiq_timestamp,
        now()
      )
      RETURNING id INTO new_id;

    -- insert into activity_log_ipa_assignment_inex_checklists
    -- (master_id, extra_log_type, created_at, updated_at)
    -- values
    -- (
    --   matched_master_id, 'adl_informant_screener', now(), now()
    -- );
    --
    insert into ml_app.model_references
    (from_record_master_id, to_record_type, to_record_id, to_record_master_id, created_at, updated_at)
    values
    (
      matched_master_id, 'DynamicModel::IpaAdlInformantScreener', new_id, matched_master_id, now(), now()
    );


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
              NEW.results_link := ('https://testmybrain.org/fphs/get_id.php?id=' || found_bhs.bhs_id::varchar);
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
-- Name: create_all_remote_grit_records(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_all_remote_grit_records() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	grit_record RECORD;
BEGIN

	FOR grit_record IN
	  SELECT * from temp_grit_assignments
	LOOP

		PERFORM create_remote_grit_record(
			grit_record.grit_id::BIGINT,
			(SELECT (pi::varchar)::player_infos FROM temp_player_infos pi WHERE master_id = grit_record.master_id LIMIT 1),
			ARRAY(SELECT distinct (pc::varchar)::player_contacts FROM temp_player_contacts pc WHERE master_id = grit_record.master_id),
			ARRAY(SELECT distinct (a::varchar)::addresses FROM temp_addresses a WHERE master_id = grit_record.master_id)
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
-- Name: create_all_remote_sleep_records(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_all_remote_sleep_records() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	sleep_record RECORD;
BEGIN

	FOR sleep_record IN
	  SELECT * from temp_sleep_assignments
	LOOP

		PERFORM create_remote_sleep_record(
			sleep_record.sleep_id::BIGINT,
			(SELECT (pi::varchar)::player_infos FROM temp_player_infos pi WHERE master_id = sleep_record.master_id LIMIT 1),
			ARRAY(SELECT distinct (pc::varchar)::player_contacts FROM temp_player_contacts pc WHERE master_id = sleep_record.master_id),
			ARRAY(SELECT distinct (a::varchar)::addresses FROM temp_addresses a WHERE master_id = sleep_record.master_id)
		);

	END LOOP;

	return 1;

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
    updated_at timestamp without time zone DEFAULT now()
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
    updated_at timestamp without time zone DEFAULT now(),
    country character varying(3),
    postal_code character varying,
    region character varying
);


--
-- Name: create_remote_grit_record(bigint, ml_app.player_infos, ml_app.player_contacts[], ml_app.addresses[]); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_remote_grit_record(match_grit_id bigint, new_player_info_record ml_app.player_infos, new_player_contact_records ml_app.player_contacts[], new_address_records ml_app.addresses[]) RETURNS integer
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

-- Find the grit_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_ipa
FROM grit.grit_assignments ipa
WHERE ipa.grit_id = match_grit_id
LIMIT 1;

-- If the IPA external identifier already exists then the sync should fail.

IF FOUND THEN
	RAISE NOTICE 'Already transferred: grit_assigments record found for IPA_ID --> %', (match_grit_id);
	UPDATE temp_grit_assignments SET status='already transferred', to_master_id=new_master_id WHERE grit_id = match_grit_id;
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

UPDATE temp_grit_assignments SET status='started sync' WHERE grit_id = match_grit_id;


RAISE NOTICE 'Creating master record with user_id %', (etl_user_id::varchar);

INSERT INTO masters
(user_id, created_at, updated_at) VALUES (etl_user_id, now(), now())
RETURNING id
INTO new_master_id;

RAISE NOTICE 'Creating external identifier record %', (match_grit_id::varchar);

INSERT INTO grit.grit_assignments
(grit_id, master_id, user_id, created_at, updated_at)
VALUES (match_grit_id, new_master_id, etl_user_id, now(), now());



IF new_player_info_record.master_id IS NULL THEN
	RAISE NOTICE 'No new_player_info_record found for IPA_ID --> %', (match_grit_id);
	UPDATE temp_grit_assignments SET status='failed - no player info provided' WHERE grit_id = match_grit_id;
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
	RAISE NOTICE 'No new_player_contact_records found for IPA_ID --> %', (match_grit_id);
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
	RAISE NOTICE 'No new_address_records found for IPA_ID --> %', (match_grit_id);
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

UPDATE temp_grit_assignments SET status='completed', to_master_id=new_master_id WHERE grit_id = match_grit_id;

return new_master_id;

END;
$$;


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
FROM ipa_ops.ipa_assignments ipa
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

INSERT INTO ipa_ops.ipa_assignments
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
-- Name: create_remote_sleep_record(bigint, ml_app.player_infos, ml_app.player_contacts[], ml_app.addresses[]); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.create_remote_sleep_record(match_sleep_id bigint, new_player_info_record ml_app.player_infos, new_player_contact_records ml_app.player_contacts[], new_address_records ml_app.addresses[]) RETURNS integer
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

-- Find the sleep_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_ipa
FROM sleep.sleep_assignments ipa
WHERE ipa.sleep_id = match_sleep_id
LIMIT 1;

-- If the IPA external identifier already exists then the sync should fail.

IF FOUND THEN
	RAISE NOTICE 'Already transferred: sleep_assigments record found for IPA_ID --> %', (match_sleep_id);
	UPDATE temp_sleep_assignments SET status='already transferred', to_master_id=new_master_id WHERE sleep_id = match_sleep_id;
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

UPDATE temp_sleep_assignments SET status='started sync' WHERE sleep_id = match_sleep_id;


RAISE NOTICE 'Creating master record with user_id %', (etl_user_id::varchar);

INSERT INTO masters
(user_id, created_at, updated_at) VALUES (etl_user_id, now(), now())
RETURNING id
INTO new_master_id;

RAISE NOTICE 'Creating external identifier record %', (match_sleep_id::varchar);

INSERT INTO sleep.sleep_assignments
(sleep_id, master_id, user_id, created_at, updated_at)
VALUES (match_sleep_id, new_master_id, etl_user_id, now(), now());



IF new_player_info_record.master_id IS NULL THEN
	RAISE NOTICE 'No new_player_info_record found for IPA_ID --> %', (match_sleep_id);
	UPDATE temp_sleep_assignments SET status='failed - no player info provided' WHERE sleep_id = match_sleep_id;
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
	RAISE NOTICE 'No new_player_contact_records found for IPA_ID --> %', (match_sleep_id);
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
	RAISE NOTICE 'No new_address_records found for IPA_ID --> %', (match_sleep_id);
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

UPDATE temp_sleep_assignments SET status='completed', to_master_id=new_master_id WHERE sleep_id = match_sleep_id;

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
-- Name: find_new_athena_grit_records(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.find_new_athena_grit_records() RETURNS TABLE(master_id integer, grit_id bigint, event_name character varying, record_updated_at timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY

    -- Get all the Athena activities and make them into meaningful events

    WITH temp_events AS (
      SELECT * FROM (
        SELECT distinct
          dt.master_id,
          grit.grit_id,
          CASE
            WHEN extra_log_type = 'exit_opt_out' THEN 'exit (opt out)'
            WHEN extra_log_type = 'exit_ps' THEN 'exit during hms phone screen'
            WHEN extra_log_type = 'exit_ps_msm' THEN 'exit during msm phone screen'
            WHEN extra_log_type = 'exit_not_consented' THEN 'exit during informed consent review'
            WHEN extra_log_type = 'exit_l2fu' THEN 'lost to follow up'
            WHEN extra_log_type = 'hms screening finalized' THEN 'hms screened'
            WHEN extra_log_type = 'ineligible' THEN 'hms or msm ineligible'
            WHEN extra_log_type = 'enrolled' THEN 'enrolled'
            WHEN extra_log_type = 'completed' THEN 'completed'
            WHEN extra_log_type = 'withdraw' THEN 'withdrawn'
            WHEN extra_log_type = 'pi follow up before enrollment' THEN 'pi follow up before enrollment'
            WHEN extra_log_type = 'general' THEN 'general communication'
            ELSE NULL
          END "event",
          dt.created_at
        FROM (
            SELECT
              al.master_id,
              al.created_at,
              al.extra_log_type
            FROM activity_log_grit_assignments al
            WHERE
              al.extra_log_type in ('exit_opt_out', 'exit_ps', 'exit_ps_msm', 'exit_not_consented', 'exit_l2fu', 'ineligible',  'enrolled',  'appointment', 'completed', 'withdraw')
              OR (
                al.extra_log_type  = 'general'
                AND al.created_at < coalesce( (
                  SELECT alsa.created_at FROM activity_log_grit_assignments alsa
                  WHERE alsa.extra_log_type = 'enrolled'
                  AND alsa.master_id = al.master_id
                  LIMIT 1
                ), now())
              )

            UNION

            SELECT
              al.master_id,
              al.created_at,
              'hms screening finalized' "extra_log_type"
            FROM activity_log_grit_assignment_phone_screens al
            WHERE
              al.extra_log_type =  'finalize'

            UNION

            SELECT
              al.master_id,
              al.created_at,
              'pi follow up before enrollment' "extra_log_type"
            FROM activity_log_grit_assignment_followups al
            WHERE
              al.extra_log_type IN ('participant_follow_up', 'participant_communication')
              AND al.created_at < coalesce( (
                SELECT created_at FROM activity_log_grit_assignments alsa
                WHERE alsa.extra_log_type = 'enrolled'
                AND alsa.master_id = al.master_id
                LIMIT 1
              ), now())



        ) dt
        INNER JOIN grit_assignments grit
          ON dt.master_id = grit.master_id
      ) e1
      WHERE event IS NOT NULL
      ORDER by master_id, created_at asc
    )

    SELECT distinct on (m.id) m.id "master_id", grit.grit_id, null::varchar "event", coalesce(t2.record_updated_at, grit.created_at) "record_updated_at"
    FROM masters m
    INNER JOIN grit.grit_assignments grit ON m.id = grit.master_id

    LEFT JOIN (
      SELECT t1.master_id, max(t1.record_updated_at) "record_updated_at" FROM (
        SELECT pi.master_id, GREATEST(updated_at, created_at) "record_updated_at"
        FROM player_infos pi
        UNION
        SELECT pc.master_id, GREATEST(updated_at, created_at) "record_updated_at"
        FROM player_contacts pc
        UNION
        SELECT a.master_id, GREATEST(updated_at, created_at) "record_updated_at"
        FROM addresses a


      ) t1
      GROUP BY t1.master_id
    ) t2
        ON t2.master_id = m.id


    LEFT JOIN sync_statuses s
      ON from_db = 'athena-db'
      AND to_db = 'fphs-db'
      AND m.id = s.from_master_id
      AND grit.grit_id::varchar = s.external_id
      AND s.external_type = 'grit_assignments'
      AND s.event IS NULL
      AND s.record_updated_at = coalesce(t2.record_updated_at, grit.created_at)
    WHERE
      (
        s.id IS NULL
        OR coalesce(s.select_status, '') NOT IN ('completed', 'already transferred', 'invalid sync-back', 'invalid tracker sync-back', 'failed - no player info provided')
        AND s.created_at < now() - interval '2 hours'
      )

    UNION

    SELECT distinct
      m.id "master_id",
      grit.grit_id,
      events.event,
      events.created_at "record_updated_at"
    FROM masters m
    INNER JOIN grit.grit_assignments grit
      ON m.id = grit.master_id
    INNER JOIN temp_events events
      ON m.id = events.master_id
    LEFT JOIN sync_statuses s
      ON from_db = 'athena-db'
      AND to_db = 'fphs-db'
      AND m.id = s.from_master_id
      AND grit.grit_id::varchar = s.external_id
      AND s.external_type = 'grit_assignments'
      AND s.event = events.event
      AND s.record_updated_at = events.created_at
    WHERE
      (
        s.id IS NULL
        OR coalesce(s.select_status, '') NOT IN ('completed', 'already transferred', 'invalid sync-back', 'invalid tracker sync-back', 'failed - no player info provided')
        AND s.created_at < now() - interval '2 hours'
      )
    ;
END;
$$;


--
-- Name: find_new_athena_ipa_records(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.find_new_athena_ipa_records() RETURNS TABLE(master_id integer, ipa_id bigint, event character varying, record_updated_at timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY

    SELECT distinct on (m.id) m.id "master_id", ipa.ipa_id, null::varchar "event", coalesce(t2.record_updated_at, ipa.created_at) "record_updated_at"
    FROM masters m
    INNER JOIN ipa_ops.ipa_assignments ipa ON m.id = ipa.master_id

    LEFT JOIN (
      SELECT t1.master_id, max(t1.record_updated_at) "record_updated_at" FROM (
        SELECT pi.master_id, GREATEST(updated_at, created_at) "record_updated_at"
        FROM player_infos pi
        UNION
        SELECT pc.master_id, GREATEST(updated_at, created_at) "record_updated_at"
        FROM player_contacts pc
        UNION
        SELECT a.master_id, GREATEST(updated_at, created_at) "record_updated_at"
        FROM addresses a


      ) t1
      GROUP BY t1.master_id
    ) t2
        ON t2.master_id = m.id


    LEFT JOIN sync_statuses s
      ON from_db = 'athena-db'
      AND to_db = 'fphs-db'
      AND m.id = s.from_master_id
      AND ipa.ipa_id::varchar = s.external_id
      AND s.external_type = 'ipa_assignments'
      AND s.event IS NULL
      AND s.record_updated_at = coalesce(t2.record_updated_at, ipa.created_at)
    WHERE
      (
        s.id IS NULL
        OR coalesce(s.select_status, '') NOT IN ('completed', 'already transferred', 'invalid sync-back', 'invalid tracker sync-back', 'failed - no player info provided')
        AND s.created_at < now() - interval '2 hours'
      )

    UNION

    SELECT distinct
      m.id "master_id",
      ipa.ipa_id,
      events.event,
      events.created_at "record_updated_at"
    FROM masters m
    INNER JOIN ipa_ops.ipa_assignments ipa
      ON m.id = ipa.master_id
    INNER JOIN temp_events events
      ON m.id = events.master_id
    LEFT JOIN sync_statuses s
      ON from_db = 'athena-db'
      AND to_db = 'fphs-db'
      AND m.id = s.from_master_id
      AND ipa.ipa_id::varchar = s.external_id
      AND s.external_type = 'ipa_assignments'
      AND s.event = events.event
      AND s.record_updated_at = events.created_at
    WHERE
      (
        s.id IS NULL
        OR coalesce(s.select_status, '') NOT IN ('completed', 'already transferred', 'invalid sync-back', 'invalid tracker sync-back', 'failed - no player info provided')
        AND s.created_at < now() - interval '2 hours'
      )
    ;
END;
$$;


--
-- Name: find_new_athena_sleep_records(); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.find_new_athena_sleep_records() RETURNS TABLE(master_id integer, sleep_id bigint, event_name character varying, record_updated_at timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY

    -- Get all the Athena activities and make them into meaningful events

    WITH temp_events AS (
      SELECT * FROM (
        SELECT distinct
          dt.master_id,
          sleep.sleep_id,
          CASE
            WHEN extra_log_type = 'exit_opt_out' THEN 'exit (opt out)'
            WHEN extra_log_type = 'exit_ps' THEN 'exit during hms phone screen'
            WHEN extra_log_type = 'exit_ps_bwh' THEN 'exit during bwh phone screen'
            WHEN extra_log_type = 'exit_not_consented' THEN 'exit during informed consent review'
            WHEN extra_log_type = 'exit_l2fu' THEN 'lost to follow up'
            WHEN extra_log_type = 'hms screening finalized' THEN 'hms screened'
            WHEN extra_log_type = 'bwh_ps_eligible' THEN 'bwh eligible'
            WHEN extra_log_type = 'ineligible' THEN 'hms or bwh ineligible'
            WHEN extra_log_type = 'appointment' THEN 'enrolled'
            WHEN extra_log_type = 'completed' THEN 'completed'
            WHEN extra_log_type = 'withdraw' THEN 'withdrawn'
            WHEN extra_log_type = 'pi follow up before enrollment' THEN 'pi follow up before enrollment'
            WHEN extra_log_type = 'general' THEN 'general communication'
            ELSE NULL
          END "event",
          dt.created_at
        FROM (
            SELECT
              al.master_id,
              al.created_at,
              al.extra_log_type
            FROM activity_log_sleep_assignments al
            WHERE
              al.extra_log_type in ('exit_opt_out', 'exit_ps', 'exit_ps_bwh', 'exit_not_consented', 'exit_l2fu', 'bwh_ps_eligible', 'ineligible',  'appointment', 'completed', 'withdraw')
              OR (
                al.extra_log_type  = 'general'
                AND al.created_at < coalesce( (
                  SELECT alsa.created_at FROM activity_log_sleep_assignments alsa
                  WHERE alsa.extra_log_type = 'appointment'
                  AND alsa.master_id = al.master_id
                  LIMIT 1
                ), now())
              )

            UNION

            SELECT
              al.master_id,
              al.created_at,
              'hms screening finalized' "extra_log_type"
            FROM activity_log_sleep_assignment_phone_screens al
            WHERE
              al.extra_log_type =  'finalize'

            UNION

            SELECT
              al.master_id,
              al.created_at,
              'pi follow up before enrollment' "extra_log_type"
            FROM activity_log_sleep_assignment_med_navs al
            WHERE
              al.extra_log_type IN ('participant_follow_up', 'participant_communication')
              AND al.created_at < coalesce( (
                SELECT created_at FROM activity_log_sleep_assignments alsa
                WHERE alsa.extra_log_type = 'appointment'
                AND alsa.master_id = al.master_id
                LIMIT 1
              ), now())



        ) dt
        INNER JOIN sleep_assignments sleep
          ON dt.master_id = sleep.master_id
      ) e1
      WHERE event IS NOT NULL
      ORDER by master_id, created_at asc
    )

    SELECT distinct on (m.id) m.id "master_id", sleep.sleep_id, null::varchar "event", coalesce(t2.record_updated_at, sleep.created_at) "record_updated_at"
    FROM masters m
    INNER JOIN sleep.sleep_assignments sleep ON m.id = sleep.master_id

    LEFT JOIN (
      SELECT t1.master_id, max(t1.record_updated_at) "record_updated_at" FROM (
        SELECT pi.master_id, GREATEST(updated_at, created_at) "record_updated_at"
        FROM player_infos pi
        UNION
        SELECT pc.master_id, GREATEST(updated_at, created_at) "record_updated_at"
        FROM player_contacts pc
        UNION
        SELECT a.master_id, GREATEST(updated_at, created_at) "record_updated_at"
        FROM addresses a


      ) t1
      GROUP BY t1.master_id
    ) t2
        ON t2.master_id = m.id


    LEFT JOIN sync_statuses s
      ON from_db = 'athena-db'
      AND to_db = 'fphs-db'
      AND m.id = s.from_master_id
      AND sleep.sleep_id::varchar = s.external_id
      AND s.external_type = 'sleep_assignments'
      AND s.event IS NULL
      AND s.record_updated_at = coalesce(t2.record_updated_at, sleep.created_at)
    WHERE
      (
        s.id IS NULL
        OR coalesce(s.select_status, '') NOT IN ('completed', 'already transferred', 'invalid sync-back', 'invalid tracker sync-back', 'failed - no player info provided')
        AND s.created_at < now() - interval '2 hours'
      )

    UNION

    SELECT distinct
      m.id "master_id",
      sleep.sleep_id,
      events.event,
      events.created_at "record_updated_at"
    FROM masters m
    INNER JOIN sleep.sleep_assignments sleep
      ON m.id = sleep.master_id
    INNER JOIN temp_events events
      ON m.id = events.master_id
    LEFT JOIN sync_statuses s
      ON from_db = 'athena-db'
      AND to_db = 'fphs-db'
      AND m.id = s.from_master_id
      AND sleep.sleep_id::varchar = s.external_id
      AND s.external_type = 'sleep_assignments'
      AND s.event = events.event
      AND s.record_updated_at = events.created_at
    WHERE
      (
        s.id IS NULL
        OR coalesce(s.select_status, '') NOT IN ('completed', 'already transferred', 'invalid sync-back', 'invalid tracker sync-back', 'failed - no player info provided')
        AND s.created_at < now() - interval '2 hours'
      )
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
-- Name: lock_transfer_records_with_external_ids_and_events(character varying, character varying, integer[], integer[], character varying, character varying[], timestamp without time zone[]); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.lock_transfer_records_with_external_ids_and_events(from_db character varying, to_db character varying, master_ids integer[], external_ids integer[], external_type character varying, events character varying[], rec_updates timestamp without time zone[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT into ml_app.sync_statuses
  ( from_master_id, external_id, external_type, from_db, to_db, event, select_status, created_at, updated_at, record_updated_at )
  (
    SELECT unnest(master_ids), unnest(external_ids), external_type, from_db, to_db, unnest(events), 'new', now(), now(), unnest(rec_updates)
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
                      category
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
                      NEW.category
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
        password_updated_at

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
        NEW.password_updated_at
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
                external_identifier_id
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
                NEW.id
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
            last_name
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
            NEW.last_name
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
-- Name: update_grit_transfer_record_results(character varying, character varying, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.update_grit_transfer_record_results(new_from_db character varying, new_to_db character varying, for_external_type character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN

  UPDATE ml_app.sync_statuses sync
  SET
    select_status = t.status,
    to_master_id = t.to_master_id,
    updated_at = now()
  FROM (
    SELECT * FROM temp_grit_assignments_results
  ) AS t
  WHERE
    from_master_id = t.master_id
    AND from_db = new_from_db
    AND to_db = new_to_db
    AND external_id = t.grit_id::varchar
    AND external_type = for_external_type
    AND (t.event IS NULL and sync.event IS NULL OR sync.event = t.event)
    AND sync.record_updated_at = t.record_updated_at
    AND coalesce(select_status, '') NOT IN ('completed', 'already transferred');

    RETURN 1;

END;
$$;


--
-- Name: update_ipa_transfer_record_results(character varying, character varying, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.update_ipa_transfer_record_results(new_from_db character varying, new_to_db character varying, for_external_type character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN

  UPDATE ml_app.sync_statuses sync
  SET
    select_status = t.status,
    to_master_id = t.to_master_id,
    updated_at = now()
  FROM (
    SELECT * FROM temp_ipa_assignments_results
  ) AS t
  WHERE
    from_master_id = t.master_id
    AND from_db = new_from_db
    AND to_db = new_to_db
    AND external_id = t.ipa_id::varchar
    AND external_type = for_external_type
    AND (t.event IS NULL and sync.event IS NULL OR sync.event = t.event)
    AND sync.record_updated_at = t.record_updated_at
    AND coalesce(select_status, '') NOT IN ('completed', 'already transferred');

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
-- Name: update_sleep_transfer_record_results(character varying, character varying, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--

CREATE FUNCTION ml_app.update_sleep_transfer_record_results(new_from_db character varying, new_to_db character varying, for_external_type character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN

  UPDATE ml_app.sync_statuses sync
  SET
    select_status = t.status,
    to_master_id = t.to_master_id,
    updated_at = now()
  FROM (
    SELECT * FROM temp_sleep_assignments_results
  ) AS t
  WHERE
    from_master_id = t.master_id
    AND from_db = new_from_db
    AND to_db = new_to_db
    AND external_id = t.sleep_id::varchar
    AND external_type = for_external_type
    AND (t.event IS NULL and sync.event IS NULL OR sync.event = t.event)
    AND sync.record_updated_at = t.record_updated_at
    AND coalesce(select_status, '') NOT IN ('completed', 'already transferred');

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
    select_who character varying,
    done_when date,
    notes character varying,
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
    select_who character varying,
    done_when date,
    notes character varying,
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
-- Name: activity_log_ipa_assignment_discussion_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_discussion_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    tag_select_contact_role character varying[],
    notes character varying,
    prev_activity_type character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_discussion_id integer
);


--
-- Name: activity_log_ipa_assignment_discussion_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_discussion_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_discussion_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_discussion_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_discussion_history.id;


--
-- Name: activity_log_ipa_assignment_discussions; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_discussions (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    tag_select_contact_role character varying[],
    notes character varying,
    prev_activity_type character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_assignment_discussions_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_discussions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_discussions_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_discussions_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_discussions.id;


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
    follow_up_time time without time zone,
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
    prev_activity_type character varying,
    contact_role character varying,
    select_subject_eligibility character varying,
    signed_no_yes character varying,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_inex_checklist_id integer,
    e_signed_document character varying,
    e_signed_how character varying,
    e_signed_at character varying,
    e_signed_by character varying,
    e_signed_code character varying,
    e_signed_status character varying
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
    prev_activity_type character varying,
    contact_role character varying,
    select_subject_eligibility character varying,
    signed_no_yes character varying,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    e_signed_document character varying,
    e_signed_how character varying,
    e_signed_at character varying,
    e_signed_by character varying,
    e_signed_code character varying,
    e_signed_status character varying
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
-- Name: activity_log_ipa_assignment_med_nav_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_med_nav_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    select_activity character varying,
    activity_date date,
    select_contact character varying,
    select_direction character varying,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    follow_up_time time without time zone,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_med_nav_id integer
);


--
-- Name: activity_log_ipa_assignment_med_nav_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_med_nav_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_med_nav_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_med_nav_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_med_nav_history.id;


--
-- Name: activity_log_ipa_assignment_med_navs; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_med_navs (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    select_activity character varying,
    activity_date date,
    select_contact character varying,
    select_direction character varying,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    follow_up_time time without time zone,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_assignment_med_navs_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_med_navs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_med_navs_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_med_navs_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_med_navs.id;


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
    select_navigator character varying,
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
    select_status character varying,
    select_pi character varying,
    location character varying
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
    select_navigator character varying,
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
    select_status character varying,
    select_pi character varying,
    location character varying
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
    callback_required character varying,
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
    callback_required character varying,
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
-- Name: activity_log_ipa_assignment_post_visit_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_post_visit_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    select_activity character varying,
    activity_date date,
    select_record_from_player_contacts character varying,
    select_record_from_addresses character varying,
    select_direction character varying,
    select_who character varying,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    follow_up_time time without time zone,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_post_visit_id integer
);


--
-- Name: activity_log_ipa_assignment_post_visit_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_post_visit_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_post_visit_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_post_visit_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_post_visit_history.id;


--
-- Name: activity_log_ipa_assignment_post_visits; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_post_visits (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    select_activity character varying,
    activity_date date,
    select_record_from_player_contacts character varying,
    select_record_from_addresses character varying,
    select_direction character varying,
    select_who character varying,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    follow_up_time time without time zone,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_assignment_post_visits_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_post_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_post_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_post_visits_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_post_visits.id;


--
-- Name: activity_log_ipa_assignment_protocol_deviation_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_protocol_deviation_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    extra_log_type character varying,
    select_who character varying,
    done_when date,
    notes character varying,
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
    select_who character varying,
    done_when date,
    notes character varying,
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
-- Name: activity_log_ipa_assignment_summaries; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_summaries (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_log_ipa_assignment_summaries_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_summaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_summaries_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_summaries_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_summaries.id;


--
-- Name: activity_log_ipa_assignment_summary_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.activity_log_ipa_assignment_summary_history (
    id integer NOT NULL,
    master_id integer,
    ipa_assignment_id integer,
    notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_log_ipa_assignment_summary_id integer
);


--
-- Name: activity_log_ipa_assignment_summary_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.activity_log_ipa_assignment_summary_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_log_ipa_assignment_summary_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.activity_log_ipa_assignment_summary_history_id_seq OWNED BY ipa_ops.activity_log_ipa_assignment_summary_history.id;


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
    follow_up_time time without time zone,
    notes character varying,
    protocol_id bigint,
    select_record_from_addresses character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: adl_screener_data; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.adl_screener_data (
    id integer NOT NULL,
    record_id numeric,
    redcap_survey_identifier numeric,
    adcs_npiq_timestamp timestamp without time zone,
    adlnpi_consent___agree numeric,
    informant numeric,
    adl_eat numeric,
    adl_walk numeric,
    adl_toilet numeric,
    adl_bath numeric,
    adl_groom numeric,
    adl_dressa numeric,
    adl_dressa_perf numeric,
    adl_dressb numeric,
    adl_phone numeric,
    adl_phone_perf numeric,
    adl_tv numeric,
    adl_tva numeric,
    adl_tvb numeric,
    adl_tvc numeric,
    adl_attnconvo numeric,
    adl_attnconvo_part numeric,
    adl_dishes numeric,
    adl_dishes_perf numeric,
    adl_belong numeric,
    adl_belong_perf numeric,
    adl_beverage numeric,
    adl_beverage_perf numeric,
    adl_snack numeric,
    adl_snack_prep numeric,
    adl_garbage numeric,
    adl_garbage_perf numeric,
    adl_travel numeric,
    adl_travel_perf numeric,
    adl_shop numeric,
    adl_shop_select numeric,
    adl_shop_pay numeric,
    adl_appt numeric,
    adl_appt_aware numeric,
    institutionalized___1 numeric,
    adl_alone numeric,
    adl_alone_15m numeric,
    adl_alone_gt1hr numeric,
    adl_alone_lt1hr numeric,
    adl_currev numeric,
    adl_currev_tv numeric,
    adl_currev_outhome numeric,
    adl_currev_inhome numeric,
    adl_read numeric,
    adl_read_lt1hr numeric,
    adl_read_gt1hr numeric,
    adl_write numeric,
    adl_write_complex numeric,
    adl_hob numeric,
    adl_hobls___gam numeric,
    adl_hobls___bing numeric,
    adl_hobls___instr numeric,
    adl_hobls___read numeric,
    adl_hobls___tenn numeric,
    adl_hobls___cword numeric,
    adl_hobls___knit numeric,
    adl_hobls___gard numeric,
    adl_hobls___wshop numeric,
    adl_hobls___art numeric,
    adl_hobls___sew numeric,
    adl_hobls___golf numeric,
    adl_hobls___fish numeric,
    adl_hobls___oth numeric,
    adl_hobls_oth text,
    adl_hobdc___1 numeric,
    adl_hob_perf numeric,
    adl_appl numeric,
    adl_applls___wash numeric,
    adl_applls___dish numeric,
    adl_applls___range numeric,
    adl_applls___dry numeric,
    adl_applls___toast numeric,
    adl_applls___micro numeric,
    adl_applls___vac numeric,
    adl_applls___toven numeric,
    adl_applls___fproc numeric,
    adl_applls___oth numeric,
    adl_applls_oth text,
    adl_appl_perf numeric,
    adl_comm text,
    npi_infor numeric,
    npi_inforsp text,
    npi_delus numeric,
    npi_delussev numeric,
    npi_hallu numeric,
    npi_hallusev numeric,
    npi_agita numeric,
    npi_agitasev numeric,
    npi_depre numeric,
    npi_depresev numeric,
    npi_anxie numeric,
    npi_anxiesev numeric,
    npi_elati numeric,
    npi_elatisev numeric,
    npi_apath numeric,
    npi_apathsev numeric,
    npi_disin numeric,
    npi_disinsev numeric,
    npi_irrit numeric,
    npi_irritsev numeric,
    npi_motor numeric,
    npi_motorsev numeric,
    npi_night numeric,
    npi_nightsev numeric,
    npi_appet numeric,
    npi_appetsev numeric,
    adcs_npiq_complete numeric,
    score numeric,
    dk_count numeric
);


--
-- Name: adl_screener_data_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.adl_screener_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: adl_screener_data_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.adl_screener_data_id_seq OWNED BY ipa_ops.adl_screener_data.id;


--
-- Name: emergency_contact_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.emergency_contact_history (
    id integer NOT NULL,
    master_id integer,
    rec_type character varying,
    data character varying,
    first_name character varying,
    last_name character varying,
    select_relationship character varying,
    rank character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    emergency_contact_id integer
);


--
-- Name: emergency_contact_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.emergency_contact_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emergency_contact_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.emergency_contact_history_id_seq OWNED BY ipa_ops.emergency_contact_history.id;


--
-- Name: emergency_contacts; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.emergency_contacts (
    id integer NOT NULL,
    master_id integer,
    rec_type character varying,
    data character varying,
    first_name character varying,
    last_name character varying,
    select_relationship character varying,
    rank character varying,
    user_id integer,
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
    institutionalized_no_yes character varying,
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
    multi_select_pastimes character varying[],
    pastime_other character varying,
    pastimes_only_at_daycare_no_yes character varying,
    select_pastimes_only_at_daycare_performance character varying,
    use_household_appliance_yes_no_dont_know character varying,
    multi_select_household_appliances character varying[],
    household_appliance_other character varying,
    select_household_appliance_performance character varying,
    npi_infor integer,
    npi_inforsp character varying,
    npi_delus integer,
    npi_delussev integer,
    npi_hallu integer,
    npi_hallusev integer,
    npi_agita integer,
    npi_agitasev integer,
    npi_depre integer,
    npi_depresev integer,
    npi_anxie integer,
    npi_anxiesev integer,
    npi_elati integer,
    npi_elatisev integer,
    npi_apath integer,
    npi_apathsev integer,
    npi_disin integer,
    npi_disinsev integer,
    npi_irrit integer,
    npi_irritsev integer,
    npi_motor integer,
    npi_motorsev integer,
    npi_night integer,
    npi_nightsev integer,
    npi_appet integer,
    npi_appetsev integer,
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
    institutionalized_no_yes character varying,
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
    multi_select_pastimes character varying[],
    pastime_other character varying,
    pastimes_only_at_daycare_no_yes character varying,
    select_pastimes_only_at_daycare_performance character varying,
    use_household_appliance_yes_no_dont_know character varying,
    multi_select_household_appliances character varying[],
    household_appliance_other character varying,
    select_household_appliance_performance character varying,
    npi_infor integer,
    npi_inforsp character varying,
    npi_delus integer,
    npi_delussev integer,
    npi_hallu integer,
    npi_hallusev integer,
    npi_agita integer,
    npi_agitasev integer,
    npi_depre integer,
    npi_depresev integer,
    npi_anxie integer,
    npi_anxiesev integer,
    npi_elati integer,
    npi_elatisev integer,
    npi_apath integer,
    npi_apathsev integer,
    npi_disin integer,
    npi_disinsev integer,
    npi_irrit integer,
    npi_irritsev integer,
    npi_motor integer,
    npi_motorsev integer,
    npi_night integer,
    npi_nightsev integer,
    npi_appet integer,
    npi_appetsev integer,
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
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_appointment_id integer,
    visit_end_date date,
    select_status character varying,
    notes character varying,
    select_schedule character varying
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
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    visit_end_date date,
    select_status character varying,
    notes character varying,
    select_schedule character varying
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
-- Name: ipa_assignments; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_assignments (
    id integer NOT NULL,
    master_id integer,
    ipa_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_assignments_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_assignments_id_seq OWNED BY ipa_ops.ipa_assignments.id;


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
-- Name: ipa_exit_interview_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_exit_interview_history (
    id integer NOT NULL,
    master_id integer,
    select_all_results_returned character varying,
    notes character varying,
    labs_returned_yes_no character varying,
    labs_notes character varying,
    dexa_returned_yes_no character varying,
    dexa_notes character varying,
    brain_mri_returned_yes_no character varying,
    brain_mri_notes character varying,
    neuro_psych_returned_yes_no character varying,
    neuro_psych_notes character varying,
    assisted_finding_provider_yes_no character varying,
    assistance_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_exit_interview_id integer
);


--
-- Name: ipa_exit_interview_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_exit_interview_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_exit_interview_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_exit_interview_history_id_seq OWNED BY ipa_ops.ipa_exit_interview_history.id;


--
-- Name: ipa_exit_interviews; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_exit_interviews (
    id integer NOT NULL,
    master_id integer,
    select_all_results_returned character varying,
    notes character varying,
    labs_returned_yes_no character varying,
    labs_notes character varying,
    dexa_returned_yes_no character varying,
    dexa_notes character varying,
    brain_mri_returned_yes_no character varying,
    brain_mri_notes character varying,
    neuro_psych_returned_yes_no character varying,
    neuro_psych_notes character varying,
    assisted_finding_provider_yes_no character varying,
    assistance_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_exit_interviews_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_exit_interviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_exit_interviews_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_exit_interviews_id_seq OWNED BY ipa_ops.ipa_exit_interviews.id;


--
-- Name: ipa_four_wk_followup_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_four_wk_followup_history (
    id integer NOT NULL,
    master_id integer,
    select_all_results_returned character varying,
    select_sensory_testing_returned character varying,
    sensory_testing_notes character varying,
    select_liver_mri_returned character varying,
    liver_mri_notes character varying,
    select_physical_function_returned character varying,
    physical_function_notes character varying,
    select_eeg_returned character varying,
    eeg_notes character varying,
    select_sleep_returned character varying,
    sleep_notes character varying,
    select_cardiology_returned character varying,
    cardiology_notes character varying,
    select_xray_returned character varying,
    xray_notes character varying,
    assisted_finding_provider_yes_no character varying,
    assistance_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_four_wk_followup_id integer
);


--
-- Name: ipa_four_wk_followup_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_four_wk_followup_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_four_wk_followup_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_four_wk_followup_history_id_seq OWNED BY ipa_ops.ipa_four_wk_followup_history.id;


--
-- Name: ipa_four_wk_followups; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_four_wk_followups (
    id integer NOT NULL,
    master_id integer,
    select_all_results_returned character varying,
    select_sensory_testing_returned character varying,
    sensory_testing_notes character varying,
    select_liver_mri_returned character varying,
    liver_mri_notes character varying,
    select_physical_function_returned character varying,
    physical_function_notes character varying,
    select_eeg_returned character varying,
    eeg_notes character varying,
    select_sleep_returned character varying,
    sleep_notes character varying,
    select_cardiology_returned character varying,
    cardiology_notes character varying,
    select_xray_returned character varying,
    xray_notes character varying,
    assisted_finding_provider_yes_no character varying,
    assistance_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_four_wk_followups_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_four_wk_followups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_four_wk_followups_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_four_wk_followups_id_seq OWNED BY ipa_ops.ipa_four_wk_followups.id;


--
-- Name: ipa_hotel_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_hotel_history (
    id integer NOT NULL,
    master_id integer,
    hotel character varying,
    check_in_date date,
    check_in_time time without time zone,
    room_number character varying,
    check_out_date date,
    check_out_time time without time zone,
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
    check_in_date date,
    check_in_time time without time zone,
    room_number character varying,
    check_out_date date,
    check_out_time time without time zone,
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
-- Name: ipa_incidental_finding_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_incidental_finding_history (
    id integer NOT NULL,
    master_id integer,
    anthropometrics_check boolean,
    anthropometrics_date date,
    anthropometrics_notes character varying,
    lab_results_check boolean,
    lab_results_date date,
    lab_results_notes character varying,
    dexa_check boolean,
    dexa_date date,
    dexa_notes character varying,
    brain_mri_check boolean,
    brain_mri_date date,
    brain_mri_notes character varying,
    neuro_psych_check boolean,
    neuro_psych_date date,
    neuro_psych_notes character varying,
    sensory_testing_check boolean,
    sensory_testing_date date,
    sensory_testing_notes character varying,
    liver_mri_check boolean,
    liver_mri_date date,
    liver_mri_notes character varying,
    physical_function_check boolean,
    physical_function_date date,
    physical_function_notes character varying,
    eeg_check boolean,
    eeg_date date,
    eeg_notes character varying,
    sleep_check boolean,
    sleep_date date,
    sleep_notes character varying,
    cardiac_check boolean,
    cardiac_date date,
    cardiac_notes character varying,
    xray_check boolean,
    xray_date date,
    xray_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_incidental_finding_id integer
);


--
-- Name: ipa_incidental_finding_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_incidental_finding_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_incidental_finding_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_incidental_finding_history_id_seq OWNED BY ipa_ops.ipa_incidental_finding_history.id;


--
-- Name: ipa_incidental_findings; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_incidental_findings (
    id integer NOT NULL,
    master_id integer,
    anthropometrics_check boolean,
    anthropometrics_date date,
    anthropometrics_notes character varying,
    lab_results_check boolean,
    lab_results_date date,
    lab_results_notes character varying,
    dexa_check boolean,
    dexa_date date,
    dexa_notes character varying,
    brain_mri_check boolean,
    brain_mri_date date,
    brain_mri_notes character varying,
    neuro_psych_check boolean,
    neuro_psych_date date,
    neuro_psych_notes character varying,
    sensory_testing_check boolean,
    sensory_testing_date date,
    sensory_testing_notes character varying,
    liver_mri_check boolean,
    liver_mri_date date,
    liver_mri_notes character varying,
    physical_function_check boolean,
    physical_function_date date,
    physical_function_notes character varying,
    eeg_check boolean,
    eeg_date date,
    eeg_notes character varying,
    sleep_check boolean,
    sleep_date date,
    sleep_notes character varying,
    cardiac_check boolean,
    cardiac_date date,
    cardiac_notes character varying,
    xray_check boolean,
    xray_date date,
    xray_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_incidental_findings_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_incidental_findings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_incidental_findings_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_incidental_findings_id_seq OWNED BY ipa_ops.ipa_incidental_findings.id;


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
    ipa_inex_checklist_id integer,
    select_subject_eligibility character varying
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
    updated_at timestamp without time zone NOT NULL,
    select_subject_eligibility character varying
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
    follow_up_date date,
    follow_up_time time without time zone,
    notes character varying,
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
    follow_up_date date,
    follow_up_time time without time zone,
    notes character varying,
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
-- Name: ipa_medical_detail_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_medical_detail_history (
    id integer NOT NULL,
    master_id integer,
    convulsion_or_seizure_blank_yes_no_dont_know character varying,
    convulsion_or_seizure_details character varying,
    sleep_disorder_blank_yes_no_dont_know character varying,
    sleep_disorder_details character varying,
    sleep_apnea_device_no_yes character varying,
    sleep_apnea_device_details character varying,
    chronic_pain_blank_yes_no character varying,
    chronic_pain_details character varying,
    chronic_pain_meds_blank_yes_no_dont_know character varying,
    chronic_pain_meds_details character varying,
    hypertension_diagnosis_blank_yes_no_dont_know character varying,
    hypertension_medications_blank_yes_no character varying,
    hypertension_diagnosis_details character varying,
    diabetes_diagnosis_blank_yes_no_dont_know character varying,
    diabetes_medications_blank_yes_no character varying,
    diabetes_diagnosis_details character varying,
    hemophilia_blank_yes_no_dont_know character varying,
    hemophilia_details character varying,
    high_cholesterol_diagnosis_blank_yes_no_dont_know character varying,
    high_cholesterol_medications_blank_yes_no character varying,
    high_cholesterol_diagnosis_details character varying,
    caridiac_pacemaker_blank_yes_no_dont_know character varying,
    caridiac_pacemaker_details character varying,
    other_heart_conditions_blank_yes_no_dont_know character varying,
    other_heart_conditions_details character varying,
    memory_problems_blank_yes_no_dont_know character varying,
    memory_problems_details character varying,
    mental_health_conditions_blank_yes_no_dont_know character varying,
    mental_health_conditions_details character varying,
    mental_health_help_blank_yes_no_dont_know character varying,
    mental_health_help_details character varying,
    neurological_problems_blank_yes_no_dont_know character varying,
    neurological_problems_details character varying,
    past_mri_yes_no_dont_know character varying,
    past_mri_details character varying,
    metal_implants_blank_yes_no_dont_know character varying,
    metal_implants_details character varying,
    metal_implants_mri_approval_details character varying,
    dietary_restrictions_blank_yes_no_dont_know character varying,
    dietary_restrictions_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_medical_detail_id integer,
    radiation_details character varying,
    radiation_blank_yes_no character varying
);


--
-- Name: ipa_medical_detail_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_medical_detail_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_medical_detail_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_medical_detail_history_id_seq OWNED BY ipa_ops.ipa_medical_detail_history.id;


--
-- Name: ipa_medical_details; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_medical_details (
    id integer NOT NULL,
    master_id integer,
    convulsion_or_seizure_blank_yes_no_dont_know character varying,
    convulsion_or_seizure_details character varying,
    sleep_disorder_blank_yes_no_dont_know character varying,
    sleep_disorder_details character varying,
    sleep_apnea_device_no_yes character varying,
    sleep_apnea_device_details character varying,
    chronic_pain_blank_yes_no character varying,
    chronic_pain_details character varying,
    chronic_pain_meds_blank_yes_no_dont_know character varying,
    chronic_pain_meds_details character varying,
    hypertension_diagnosis_blank_yes_no_dont_know character varying,
    hypertension_medications_blank_yes_no character varying,
    hypertension_diagnosis_details character varying,
    diabetes_diagnosis_blank_yes_no_dont_know character varying,
    diabetes_medications_blank_yes_no character varying,
    diabetes_diagnosis_details character varying,
    hemophilia_blank_yes_no_dont_know character varying,
    hemophilia_details character varying,
    high_cholesterol_diagnosis_blank_yes_no_dont_know character varying,
    high_cholesterol_medications_blank_yes_no character varying,
    high_cholesterol_diagnosis_details character varying,
    caridiac_pacemaker_blank_yes_no_dont_know character varying,
    caridiac_pacemaker_details character varying,
    other_heart_conditions_blank_yes_no_dont_know character varying,
    other_heart_conditions_details character varying,
    memory_problems_blank_yes_no_dont_know character varying,
    memory_problems_details character varying,
    mental_health_conditions_blank_yes_no_dont_know character varying,
    mental_health_conditions_details character varying,
    mental_health_help_blank_yes_no_dont_know character varying,
    mental_health_help_details character varying,
    neurological_problems_blank_yes_no_dont_know character varying,
    neurological_problems_details character varying,
    past_mri_yes_no_dont_know character varying,
    past_mri_details character varying,
    metal_implants_blank_yes_no_dont_know character varying,
    metal_implants_details character varying,
    metal_implants_mri_approval_details character varying,
    dietary_restrictions_blank_yes_no_dont_know character varying,
    dietary_restrictions_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    radiation_details character varying,
    radiation_blank_yes_no character varying
);


--
-- Name: ipa_medical_details_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_medical_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_medical_details_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_medical_details_id_seq OWNED BY ipa_ops.ipa_medical_details.id;


--
-- Name: ipa_medication_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_medication_history (
    id integer NOT NULL,
    master_id integer,
    current_meds_blank_yes_no_dont_know character varying,
    current_meds_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_medication_id integer
);


--
-- Name: ipa_medication_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_medication_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_medication_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_medication_history_id_seq OWNED BY ipa_ops.ipa_medication_history.id;


--
-- Name: ipa_medications; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_medications (
    id integer NOT NULL,
    master_id integer,
    current_meds_blank_yes_no_dont_know character varying,
    current_meds_details character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_medications_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_medications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_medications_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_medications_id_seq OWNED BY ipa_ops.ipa_medications.id;


--
-- Name: ipa_mednav_followup_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_mednav_followup_history (
    id integer NOT NULL,
    master_id integer,
    anthropometrics_check boolean,
    anthropometrics_notes character varying,
    lab_results_check boolean,
    lab_results_notes character varying,
    dexa_check boolean,
    dexa_notes character varying,
    brain_mri_check boolean,
    brain_mri_notes character varying,
    neuro_psych_check boolean,
    neuro_psych_notes character varying,
    sensory_testing_check boolean,
    sensory_testing_notes character varying,
    liver_mri_check boolean,
    liver_mri_notes character varying,
    physical_function_check boolean,
    physical_function_notes character varying,
    eeg_check boolean,
    eeg_notes character varying,
    sleep_check boolean,
    sleep_notes character varying,
    cardiac_check boolean,
    cardiac_notes character varying,
    xray_check boolean,
    xray_notes character varying,
    assisted_finding_provider_yes_no character varying,
    assistance_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_mednav_followup_id integer
);


--
-- Name: ipa_mednav_followup_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_mednav_followup_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_mednav_followup_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_mednav_followup_history_id_seq OWNED BY ipa_ops.ipa_mednav_followup_history.id;


--
-- Name: ipa_mednav_followups; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_mednav_followups (
    id integer NOT NULL,
    master_id integer,
    anthropometrics_check boolean,
    anthropometrics_notes character varying,
    lab_results_check boolean,
    lab_results_notes character varying,
    dexa_check boolean,
    dexa_notes character varying,
    brain_mri_check boolean,
    brain_mri_notes character varying,
    neuro_psych_check boolean,
    neuro_psych_notes character varying,
    sensory_testing_check boolean,
    sensory_testing_notes character varying,
    liver_mri_check boolean,
    liver_mri_notes character varying,
    physical_function_check boolean,
    physical_function_notes character varying,
    eeg_check boolean,
    eeg_notes character varying,
    sleep_check boolean,
    sleep_notes character varying,
    cardiac_check boolean,
    cardiac_notes character varying,
    xray_check boolean,
    xray_notes character varying,
    assisted_finding_provider_yes_no character varying,
    assistance_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_mednav_followups_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_mednav_followups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_mednav_followups_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_mednav_followups_id_seq OWNED BY ipa_ops.ipa_mednav_followups.id;


--
-- Name: ipa_mednav_provider_comm_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_mednav_provider_comm_history (
    id integer NOT NULL,
    master_id integer,
    anthropometrics_check boolean,
    anthropometrics_notes character varying,
    lab_results_check boolean,
    lab_results_notes character varying,
    dexa_check boolean,
    dexa_notes character varying,
    brain_mri_check boolean,
    brain_mri_notes character varying,
    neuro_psych_check boolean,
    neuro_psych_notes character varying,
    sensory_testing_check boolean,
    sensory_testing_notes character varying,
    liver_mri_check boolean,
    liver_mri_notes character varying,
    physical_function_check boolean,
    physical_function_notes character varying,
    eeg_check boolean,
    eeg_notes character varying,
    sleep_check boolean,
    sleep_notes character varying,
    cardiac_check boolean,
    cardiac_notes character varying,
    xray_check boolean,
    xray_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_mednav_provider_comm_id integer
);


--
-- Name: ipa_mednav_provider_comm_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_mednav_provider_comm_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_mednav_provider_comm_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_mednav_provider_comm_history_id_seq OWNED BY ipa_ops.ipa_mednav_provider_comm_history.id;


--
-- Name: ipa_mednav_provider_comms; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_mednav_provider_comms (
    id integer NOT NULL,
    master_id integer,
    anthropometrics_check boolean,
    anthropometrics_notes character varying,
    lab_results_check boolean,
    lab_results_notes character varying,
    dexa_check boolean,
    dexa_notes character varying,
    brain_mri_check boolean,
    brain_mri_notes character varying,
    neuro_psych_check boolean,
    neuro_psych_notes character varying,
    sensory_testing_check boolean,
    sensory_testing_notes character varying,
    liver_mri_check boolean,
    liver_mri_notes character varying,
    physical_function_check boolean,
    physical_function_notes character varying,
    eeg_check boolean,
    eeg_notes character varying,
    sleep_check boolean,
    sleep_notes character varying,
    cardiac_check boolean,
    cardiac_notes character varying,
    xray_check boolean,
    xray_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_mednav_provider_comms_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_mednav_provider_comms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_mednav_provider_comms_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_mednav_provider_comms_id_seq OWNED BY ipa_ops.ipa_mednav_provider_comms.id;


--
-- Name: ipa_mednav_provider_report_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_mednav_provider_report_history (
    id integer NOT NULL,
    master_id integer,
    report_delivery_date date,
    anthropometrics_check boolean,
    anthropometrics_notes character varying,
    lab_results_check boolean,
    lab_results_notes character varying,
    dexa_check boolean,
    dexa_notes character varying,
    brain_mri_check boolean,
    brain_mri_notes character varying,
    neuro_psych_check boolean,
    neuro_psych_notes character varying,
    sensory_testing_check boolean,
    sensory_testing_notes character varying,
    liver_mri_check boolean,
    liver_mri_notes character varying,
    physical_function_check boolean,
    physical_function_notes character varying,
    eeg_check boolean,
    eeg_notes character varying,
    sleep_check boolean,
    sleep_notes character varying,
    cardiac_check boolean,
    cardiac_notes character varying,
    xray_check boolean,
    xray_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_mednav_provider_report_id integer
);


--
-- Name: ipa_mednav_provider_report_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_mednav_provider_report_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_mednav_provider_report_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_mednav_provider_report_history_id_seq OWNED BY ipa_ops.ipa_mednav_provider_report_history.id;


--
-- Name: ipa_mednav_provider_reports; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_mednav_provider_reports (
    id integer NOT NULL,
    master_id integer,
    report_delivery_date date,
    anthropometrics_check boolean,
    anthropometrics_notes character varying,
    lab_results_check boolean,
    lab_results_notes character varying,
    dexa_check boolean,
    dexa_notes character varying,
    brain_mri_check boolean,
    brain_mri_notes character varying,
    neuro_psych_check boolean,
    neuro_psych_notes character varying,
    sensory_testing_check boolean,
    sensory_testing_notes character varying,
    liver_mri_check boolean,
    liver_mri_notes character varying,
    physical_function_check boolean,
    physical_function_notes character varying,
    eeg_check boolean,
    eeg_notes character varying,
    sleep_check boolean,
    sleep_notes character varying,
    cardiac_check boolean,
    cardiac_notes character varying,
    xray_check boolean,
    xray_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_mednav_provider_reports_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_mednav_provider_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_mednav_provider_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_mednav_provider_reports_id_seq OWNED BY ipa_ops.ipa_mednav_provider_reports.id;


--
-- Name: ipa_ps_initial_screenings; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_initial_screenings (
    id integer NOT NULL,
    master_id integer,
    select_is_good_time_to_speak character varying,
    looked_at_website_yes_no character varying,
    select_may_i_begin character varying,
    any_questions_blank_yes_no character varying,
    select_still_interested character varying,
    follow_up_date date,
    follow_up_time time without time zone,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_screenings; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_screenings (
    id integer NOT NULL,
    master_id integer,
    eligible_for_study_blank_yes_no character varying,
    requires_study_partner_blank_yes_no character varying,
    notes character varying,
    good_time_to_speak_blank_yes_no character varying,
    callback_date date,
    callback_time character varying,
    still_interested_blank_yes_no character varying,
    not_interested_notes character varying,
    contact_in_future_yes_no character varying,
    ineligible_notes character varying,
    eligible_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_participant_exits; Type: VIEW; Schema: ipa_ops; Owner: -
--

CREATE VIEW ipa_ops.ipa_participant_exits AS
 SELECT dt2.master_id,
    dt2.ipa_id,
    dt2.status,
    dt2."when"
   FROM ( SELECT DISTINCT dt.master_id,
            ipa.ipa_id,
                CASE
                    WHEN ((dt.extra_log_type)::text = 'completed'::text) THEN 'completed'::character varying
                    WHEN ((dt.extra_log_type)::text = 'withdraw'::text) THEN 'withdrawn'::character varying
                    WHEN (((dt.ps_interested1)::text = 'not interested'::text) OR ((dt.ps_interested2)::text = 'not interested'::text) OR ((dt.ps_still_interested)::text = 'no'::text)) THEN 'not interest during phone screening'::character varying
                    WHEN (((dt.extra_log_type)::text = 'perform_screening_follow_up'::text) AND ((dt.eligible_for_study_blank_yes_no)::text = 'no'::text)) THEN 'ineligible'::character varying
                    WHEN (((dt.extra_log_type)::text = 'perform_screening_follow_up'::text) AND ((dt.follow_up_still_interested)::text = 'no'::text)) THEN 'not interest during screening follow-up'::character varying
                    WHEN ((dt.extra_log_type)::text = 'schedule_screening'::text) THEN 'in process'::character varying
                    WHEN ((dt.extra_log_type)::text = 'exit_opt_out'::text) THEN 'opted out'::character varying
                    WHEN ((dt.extra_log_type)::text = 'exit_l2fu'::text) THEN 'lost to follow-up (before scheduling)'::character varying
                    ELSE dt.extra_log_type
                END AS status,
            dt.created_at AS "when"
           FROM (( SELECT al.master_id,
                    al.created_at,
                    al.extra_log_type,
                    ipa_screenings.eligible_for_study_blank_yes_no,
                    ipa_screenings.still_interested_blank_yes_no AS follow_up_still_interested,
                    ipa_ps_initial_screenings.select_is_good_time_to_speak AS ps_interested1,
                    ipa_ps_initial_screenings.select_may_i_begin AS ps_interested2,
                    ipa_ps_initial_screenings.select_still_interested AS ps_still_interested,
                    rank() OVER (PARTITION BY al.master_id ORDER BY al.created_at DESC) AS r
                   FROM ((ipa_ops.activity_log_ipa_assignments al
                     LEFT JOIN ipa_ops.ipa_screenings ON ((al.master_id = ipa_screenings.master_id)))
                     LEFT JOIN ipa_ops.ipa_ps_initial_screenings ON ((al.master_id = ipa_ps_initial_screenings.master_id)))
                  WHERE (((ipa_ps_initial_screenings.select_is_good_time_to_speak)::text = 'not interested'::text) OR ((ipa_ps_initial_screenings.select_may_i_begin)::text = 'not interested'::text) OR ((ipa_ps_initial_screenings.select_still_interested)::text = 'no'::text) OR (((al.extra_log_type)::text = 'perform_screening_follow_up'::text) AND (((ipa_screenings.eligible_for_study_blank_yes_no)::text = 'no'::text) OR ((ipa_screenings.still_interested_blank_yes_no)::text = 'no'::text))) OR ((al.extra_log_type)::text = ANY (ARRAY[('completed'::character varying)::text, ('exit_opt_out'::character varying)::text, ('exit_l2fu'::character varying)::text])) OR ((al.extra_log_type)::text = 'withdraw'::text) OR ((al.extra_log_type)::text = 'schedule_screening'::text))) dt
             JOIN ipa_ops.ipa_assignments ipa ON ((dt.master_id = ipa.master_id)))
          WHERE (dt.r = 1)) dt2
  ORDER BY dt2.status, dt2."when" DESC;


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
-- Name: ipa_protocol_exception_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_protocol_exception_history (
    id integer NOT NULL,
    master_id integer,
    exception_date date,
    exception_description character varying,
    risks_and_benefits_notes character varying,
    informed_consent_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_protocol_exception_id integer
);


--
-- Name: ipa_protocol_exception_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_protocol_exception_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_protocol_exception_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_protocol_exception_history_id_seq OWNED BY ipa_ops.ipa_protocol_exception_history.id;


--
-- Name: ipa_protocol_exceptions; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_protocol_exceptions (
    id integer NOT NULL,
    master_id integer,
    exception_date date,
    exception_description character varying,
    risks_and_benefits_notes character varying,
    informed_consent_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_protocol_exceptions_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_protocol_exceptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_protocol_exceptions_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_protocol_exceptions_id_seq OWNED BY ipa_ops.ipa_protocol_exceptions.id;


--
-- Name: ipa_ps_comp_review_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_comp_review_history (
    id integer NOT NULL,
    master_id integer,
    how_long_notes character varying,
    clinical_care_or_research_notes character varying,
    two_assessments_notes character varying,
    risks_notes character varying,
    study_drugs_notes character varying,
    compensation_notes character varying,
    location_notes character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_comp_review_id integer
);


--
-- Name: ipa_ps_comp_review_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_comp_review_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_comp_review_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_comp_review_history_id_seq OWNED BY ipa_ops.ipa_ps_comp_review_history.id;


--
-- Name: ipa_ps_comp_reviews; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_comp_reviews (
    id integer NOT NULL,
    master_id integer,
    how_long_notes character varying,
    clinical_care_or_research_notes character varying,
    two_assessments_notes character varying,
    risks_notes character varying,
    study_drugs_notes character varying,
    compensation_notes character varying,
    location_notes character varying,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_ps_comp_reviews_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_comp_reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_comp_reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_comp_reviews_id_seq OWNED BY ipa_ops.ipa_ps_comp_reviews.id;


--
-- Name: ipa_ps_football_experience_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_football_experience_history (
    id integer NOT NULL,
    master_id integer,
    age integer,
    played_in_nfl_blank_yes_no character varying,
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
    hypertension_diagnosis_blank_yes_no_dont_know character varying,
    hypertension_medications_blank_yes_no character varying,
    hypertension_diagnosis_details character varying,
    diabetes_diagnosis_blank_yes_no_dont_know character varying,
    diabetes_medications_blank_yes_no character varying,
    diabetes_diagnosis_details character varying,
    high_cholesterol_diagnosis_blank_yes_no_dont_know character varying,
    high_cholesterol_medications_blank_yes_no character varying,
    high_cholesterol_diagnosis_details character varying,
    other_heart_conditions_blank_yes_no_dont_know character varying,
    other_heart_conditions_details character varying,
    heart_surgeries_blank_yes_no_dont_know character varying,
    heart_surgeries_details character varying,
    caridiac_pacemaker_blank_yes_no_dont_know character varying,
    caridiac_pacemaker_details character varying,
    memory_problems_blank_yes_no_dont_know character varying,
    memory_problems_details character varying,
    mental_health_conditions_blank_yes_no_dont_know character varying,
    mental_health_conditions_details character varying,
    mental_health_help_blank_yes_no_dont_know character varying,
    mental_health_help_details character varying,
    neurological_problems_blank_yes_no_dont_know character varying,
    neurological_problems_details character varying,
    neurological_surgeries_blank_yes_no_dont_know character varying,
    neurological_surgeries_details character varying,
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
    hypertension_diagnosis_blank_yes_no_dont_know character varying,
    hypertension_medications_blank_yes_no character varying,
    hypertension_diagnosis_details character varying,
    diabetes_diagnosis_blank_yes_no_dont_know character varying,
    diabetes_medications_blank_yes_no character varying,
    diabetes_diagnosis_details character varying,
    high_cholesterol_diagnosis_blank_yes_no_dont_know character varying,
    high_cholesterol_medications_blank_yes_no character varying,
    high_cholesterol_diagnosis_details character varying,
    other_heart_conditions_blank_yes_no_dont_know character varying,
    other_heart_conditions_details character varying,
    heart_surgeries_blank_yes_no_dont_know character varying,
    heart_surgeries_details character varying,
    caridiac_pacemaker_blank_yes_no_dont_know character varying,
    caridiac_pacemaker_details character varying,
    memory_problems_blank_yes_no_dont_know character varying,
    memory_problems_details character varying,
    mental_health_conditions_blank_yes_no_dont_know character varying,
    mental_health_conditions_details character varying,
    mental_health_help_blank_yes_no_dont_know character varying,
    mental_health_help_details character varying,
    neurological_problems_blank_yes_no_dont_know character varying,
    neurological_problems_details character varying,
    neurological_surgeries_blank_yes_no_dont_know character varying,
    neurological_surgeries_details character varying,
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
-- Name: ipa_ps_informant_detail_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_informant_detail_history (
    id integer NOT NULL,
    master_id integer,
    first_name character varying,
    last_name character varying,
    email character varying,
    phone character varying,
    relationship_to_participant character varying,
    contact_information_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_informant_detail_id integer
);


--
-- Name: ipa_ps_informant_detail_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_informant_detail_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_informant_detail_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_informant_detail_history_id_seq OWNED BY ipa_ops.ipa_ps_informant_detail_history.id;


--
-- Name: ipa_ps_informant_details; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_informant_details (
    id integer NOT NULL,
    master_id integer,
    first_name character varying,
    last_name character varying,
    email character varying,
    phone character varying,
    relationship_to_participant character varying,
    contact_information_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_ps_informant_details_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_ps_informant_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_ps_informant_details_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_ps_informant_details_id_seq OWNED BY ipa_ops.ipa_ps_informant_details.id;


--
-- Name: ipa_ps_initial_screening_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_ps_initial_screening_history (
    id integer NOT NULL,
    master_id integer,
    select_is_good_time_to_speak character varying,
    looked_at_website_yes_no character varying,
    select_may_i_begin character varying,
    any_questions_blank_yes_no character varying,
    select_still_interested character varying,
    follow_up_date date,
    follow_up_time time without time zone,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_initial_screening_id integer
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
    past_mri_yes_no_dont_know character varying,
    past_mri_details character varying,
    electrical_implants_blank_yes_no_dont_know character varying,
    electrical_implants_details character varying,
    metal_implants_blank_yes_no_dont_know character varying,
    metal_implants_details character varying,
    metal_jewelry_blank_yes_no character varying,
    hearing_aid_blank_yes_no character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_ps_mri_id integer,
    radiation_blank_yes_no character varying,
    radiation_details character varying
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
    past_mri_yes_no_dont_know character varying,
    past_mri_details character varying,
    electrical_implants_blank_yes_no_dont_know character varying,
    electrical_implants_details character varying,
    metal_implants_blank_yes_no_dont_know character varying,
    metal_implants_details character varying,
    metal_jewelry_blank_yes_no character varying,
    hearing_aid_blank_yes_no character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    radiation_blank_yes_no character varying,
    radiation_details character varying
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
    birth_date date,
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
    birth_date date,
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
    tmoca_version character varying,
    attn_digit_span integer,
    attn_digit_vigilance integer,
    attn_digit_calculation integer,
    language_repeat integer,
    language_fluency integer,
    abstraction integer,
    delayed_recall integer,
    orientation integer,
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
    tmoca_version character varying,
    attn_digit_span integer,
    attn_digit_vigilance integer,
    attn_digit_calculation integer,
    language_repeat integer,
    language_fluency integer,
    abstraction integer,
    delayed_recall integer,
    orientation integer,
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
    convulsion_or_seizure_blank_yes_no_dont_know character varying,
    epilepsy_blank_yes_no_dont_know character varying,
    fainting_blank_yes_no_dont_know character varying,
    concussion_blank_yes_no_dont_know character varying,
    loss_of_conciousness_details character varying,
    hearing_problems_blank_yes_no_dont_know character varying,
    cochlear_implants_blank_yes_no_dont_know character varying,
    metal_blank_yes_no_dont_know character varying,
    metal_details character varying,
    neurostimulator_blank_yes_no_dont_know character varying,
    neurostimulator_details character varying,
    med_infusion_device_blank_yes_no_dont_know character varying,
    med_infusion_device_details character varying,
    past_tms_blank_yes_no_dont_know character varying,
    past_tms_details character varying,
    current_meds_blank_yes_no_dont_know character varying,
    current_meds_details character varying,
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
    ipa_ps_tms_test_id integer,
    convulsion_or_seizure_details character varying,
    epilepsy_details character varying,
    fainting_details character varying,
    hairstyle_scalp_blank_yes_no_dont_know character varying,
    hairstyle_scalp_details character varying
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
    convulsion_or_seizure_blank_yes_no_dont_know character varying,
    epilepsy_blank_yes_no_dont_know character varying,
    fainting_blank_yes_no_dont_know character varying,
    concussion_blank_yes_no_dont_know character varying,
    loss_of_conciousness_details character varying,
    hearing_problems_blank_yes_no_dont_know character varying,
    cochlear_implants_blank_yes_no_dont_know character varying,
    metal_blank_yes_no_dont_know character varying,
    metal_details character varying,
    neurostimulator_blank_yes_no_dont_know character varying,
    neurostimulator_details character varying,
    med_infusion_device_blank_yes_no_dont_know character varying,
    med_infusion_device_details character varying,
    past_tms_blank_yes_no_dont_know character varying,
    past_tms_details character varying,
    current_meds_blank_yes_no_dont_know character varying,
    current_meds_details character varying,
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
    convulsion_or_seizure_details character varying,
    epilepsy_details character varying,
    fainting_details character varying,
    hairstyle_scalp_blank_yes_no_dont_know character varying,
    hairstyle_scalp_details character varying
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
-- Name: ipa_reimbursement_req_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_reimbursement_req_history (
    id integer NOT NULL,
    master_id integer,
    participant_requested_yes_no character varying,
    submission_date date,
    additional_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_reimbursement_req_id integer
);


--
-- Name: ipa_reimbursement_req_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_reimbursement_req_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_reimbursement_req_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_reimbursement_req_history_id_seq OWNED BY ipa_ops.ipa_reimbursement_req_history.id;


--
-- Name: ipa_reimbursement_reqs; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_reimbursement_reqs (
    id integer NOT NULL,
    master_id integer,
    participant_requested_yes_no character varying,
    submission_date date,
    additional_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_reimbursement_reqs_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_reimbursement_reqs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_reimbursement_reqs_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_reimbursement_reqs_id_seq OWNED BY ipa_ops.ipa_reimbursement_reqs.id;


--
-- Name: ipa_screening_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_screening_history (
    id integer NOT NULL,
    master_id integer,
    eligible_for_study_blank_yes_no character varying,
    requires_study_partner_blank_yes_no character varying,
    notes character varying,
    good_time_to_speak_blank_yes_no character varying,
    callback_date date,
    callback_time character varying,
    still_interested_blank_yes_no character varying,
    not_interested_notes character varying,
    contact_in_future_yes_no character varying,
    ineligible_notes character varying,
    eligible_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_screening_id integer
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
-- Name: ipa_special_consideration_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_special_consideration_history (
    id integer NOT NULL,
    master_id integer,
    travel_with_wife_yes_no character varying,
    travel_with_wife_details character varying,
    mmse_yes_no character varying,
    tmoca_score character varying,
    mmse_details character varying,
    bringing_cpap_yes_no character varying,
    tms_exempt_yes_no character varying,
    taking_med_for_mri_pet_yes_no character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_special_consideration_id integer
);


--
-- Name: ipa_special_consideration_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_special_consideration_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_special_consideration_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_special_consideration_history_id_seq OWNED BY ipa_ops.ipa_special_consideration_history.id;


--
-- Name: ipa_special_considerations; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_special_considerations (
    id integer NOT NULL,
    master_id integer,
    travel_with_wife_yes_no character varying,
    travel_with_wife_details character varying,
    mmse_yes_no character varying,
    tmoca_score character varying,
    mmse_details character varying,
    bringing_cpap_yes_no character varying,
    tms_exempt_yes_no character varying,
    taking_med_for_mri_pet_yes_no character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_special_considerations_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_special_considerations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_special_considerations_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_special_considerations_id_seq OWNED BY ipa_ops.ipa_special_considerations.id;


--
-- Name: ipa_station_contact_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_station_contact_history (
    id integer NOT NULL,
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
-- Name: ipa_tms_reviews; Type: VIEW; Schema: ipa_ops; Owner: -
--

CREATE VIEW ipa_ops.ipa_tms_reviews AS
 WITH tms AS (
         SELECT rank() OVER (PARTITION BY ipa_ps_tms_tests.master_id ORDER BY ipa_ps_tms_tests.id DESC) AS r,
            ipa_ps_tms_tests.id,
            ipa_ps_tms_tests.master_id,
            ipa_ps_tms_tests.convulsion_or_seizure_blank_yes_no_dont_know,
            ipa_ps_tms_tests.epilepsy_blank_yes_no_dont_know,
            ipa_ps_tms_tests.fainting_blank_yes_no_dont_know,
            ipa_ps_tms_tests.concussion_blank_yes_no_dont_know,
            ipa_ps_tms_tests.loss_of_conciousness_details,
            ipa_ps_tms_tests.hearing_problems_blank_yes_no_dont_know,
            ipa_ps_tms_tests.cochlear_implants_blank_yes_no_dont_know,
            ipa_ps_tms_tests.metal_blank_yes_no_dont_know,
            ipa_ps_tms_tests.metal_details,
            ipa_ps_tms_tests.neurostimulator_blank_yes_no_dont_know,
            ipa_ps_tms_tests.neurostimulator_details,
            ipa_ps_tms_tests.med_infusion_device_blank_yes_no_dont_know,
            ipa_ps_tms_tests.med_infusion_device_details,
            ipa_ps_tms_tests.past_tms_blank_yes_no_dont_know,
            ipa_ps_tms_tests.past_tms_details,
            ipa_ps_tms_tests.current_meds_blank_yes_no_dont_know,
            ipa_ps_tms_tests.current_meds_details,
            ipa_ps_tms_tests.other_chronic_problems_blank_yes_no_dont_know,
            ipa_ps_tms_tests.other_chronic_problems_details,
            ipa_ps_tms_tests.hospital_visits_blank_yes_no_dont_know,
            ipa_ps_tms_tests.hospital_visits_details,
            ipa_ps_tms_tests.dietary_restrictions_blank_yes_no_dont_know,
            ipa_ps_tms_tests.dietary_restrictions_details,
            ipa_ps_tms_tests.anything_else_blank_yes_no,
            ipa_ps_tms_tests.anything_else_details,
            ipa_ps_tms_tests.user_id,
            ipa_ps_tms_tests.created_at,
            ipa_ps_tms_tests.updated_at,
            ipa_ps_tms_tests.convulsion_or_seizure_details,
            ipa_ps_tms_tests.epilepsy_details,
            ipa_ps_tms_tests.fainting_details,
            ipa_ps_tms_tests.hairstyle_scalp_blank_yes_no_dont_know,
            ipa_ps_tms_tests.hairstyle_scalp_details
           FROM ipa_ops.ipa_ps_tms_tests
        ), mri AS (
         SELECT rank() OVER (PARTITION BY ipa_ps_mris.master_id ORDER BY ipa_ps_mris.id DESC) AS r,
            ipa_ps_mris.id,
            ipa_ps_mris.master_id,
            ipa_ps_mris.past_mri_yes_no_dont_know,
            ipa_ps_mris.past_mri_details,
            ipa_ps_mris.electrical_implants_blank_yes_no_dont_know,
            ipa_ps_mris.electrical_implants_details,
            ipa_ps_mris.metal_implants_blank_yes_no_dont_know,
            ipa_ps_mris.metal_implants_details,
            ipa_ps_mris.metal_jewelry_blank_yes_no,
            ipa_ps_mris.hearing_aid_blank_yes_no,
            ipa_ps_mris.user_id,
            ipa_ps_mris.created_at,
            ipa_ps_mris.updated_at,
            ipa_ps_mris.radiation_blank_yes_no,
            ipa_ps_mris.radiation_details
           FROM ipa_ops.ipa_ps_mris
        ), health AS (
         SELECT rank() OVER (PARTITION BY ipa_ps_healths.master_id ORDER BY ipa_ps_healths.id DESC) AS r,
            ipa_ps_healths.id,
            ipa_ps_healths.master_id,
            ipa_ps_healths.physical_limitations_blank_yes_no,
            ipa_ps_healths.physical_limitations_details,
            ipa_ps_healths.sit_back_blank_yes_no,
            ipa_ps_healths.sit_back_details,
            ipa_ps_healths.cycle_blank_yes_no,
            ipa_ps_healths.cycle_details,
            ipa_ps_healths.chronic_pain_blank_yes_no,
            ipa_ps_healths.chronic_pain_details,
            ipa_ps_healths.chronic_pain_meds_blank_yes_no_dont_know,
            ipa_ps_healths.chronic_pain_meds_details,
            ipa_ps_healths.hemophilia_blank_yes_no_dont_know,
            ipa_ps_healths.hemophilia_details,
            ipa_ps_healths.raynauds_syndrome_blank_yes_no_dont_know,
            ipa_ps_healths.raynauds_syndrome_severity_selection,
            ipa_ps_healths.raynauds_syndrome_details,
            ipa_ps_healths.hypertension_diagnosis_blank_yes_no_dont_know,
            ipa_ps_healths.hypertension_medications_blank_yes_no,
            ipa_ps_healths.hypertension_diagnosis_details,
            ipa_ps_healths.diabetes_diagnosis_blank_yes_no_dont_know,
            ipa_ps_healths.diabetes_medications_blank_yes_no,
            ipa_ps_healths.diabetes_diagnosis_details,
            ipa_ps_healths.high_cholesterol_diagnosis_blank_yes_no_dont_know,
            ipa_ps_healths.high_cholesterol_medications_blank_yes_no,
            ipa_ps_healths.high_cholesterol_diagnosis_details,
            ipa_ps_healths.other_heart_conditions_blank_yes_no_dont_know,
            ipa_ps_healths.other_heart_conditions_details,
            ipa_ps_healths.heart_surgeries_blank_yes_no_dont_know,
            ipa_ps_healths.heart_surgeries_details,
            ipa_ps_healths.caridiac_pacemaker_blank_yes_no_dont_know,
            ipa_ps_healths.caridiac_pacemaker_details,
            ipa_ps_healths.memory_problems_blank_yes_no_dont_know,
            ipa_ps_healths.memory_problems_details,
            ipa_ps_healths.mental_health_conditions_blank_yes_no_dont_know,
            ipa_ps_healths.mental_health_conditions_details,
            ipa_ps_healths.mental_health_help_blank_yes_no_dont_know,
            ipa_ps_healths.mental_health_help_details,
            ipa_ps_healths.neurological_problems_blank_yes_no_dont_know,
            ipa_ps_healths.neurological_problems_details,
            ipa_ps_healths.neurological_surgeries_blank_yes_no_dont_know,
            ipa_ps_healths.neurological_surgeries_details,
            ipa_ps_healths.user_id,
            ipa_ps_healths.created_at,
            ipa_ps_healths.updated_at
           FROM ipa_ops.ipa_ps_healths
        )
 SELECT tms.id,
    tms.master_id,
    tms.user_id,
    tms.created_at,
    tms.updated_at,
    tms.past_tms_blank_yes_no_dont_know,
    tms.past_tms_details,
    tms.convulsion_or_seizure_blank_yes_no_dont_know,
    tms.convulsion_or_seizure_details,
    tms.epilepsy_blank_yes_no_dont_know,
    tms.epilepsy_details,
    tms.fainting_blank_yes_no_dont_know,
    tms.fainting_details,
    tms.concussion_blank_yes_no_dont_know,
    tms.loss_of_conciousness_details,
    tms.hairstyle_scalp_blank_yes_no_dont_know,
    tms.hairstyle_scalp_details,
    tms.hearing_problems_blank_yes_no_dont_know,
    tms.cochlear_implants_blank_yes_no_dont_know,
    tms.neurostimulator_blank_yes_no_dont_know,
    tms.neurostimulator_details,
    tms.med_infusion_device_blank_yes_no_dont_know,
    tms.med_infusion_device_details,
    tms.metal_blank_yes_no_dont_know,
    tms.metal_details,
    tms.current_meds_blank_yes_no_dont_know,
    tms.current_meds_details,
    mri.past_mri_yes_no_dont_know,
    mri.past_mri_details,
    mri.metal_implants_blank_yes_no_dont_know,
    mri.metal_implants_details,
    mri.electrical_implants_blank_yes_no_dont_know,
    mri.electrical_implants_details,
    mri.metal_jewelry_blank_yes_no,
    mri.hearing_aid_blank_yes_no,
    health.caridiac_pacemaker_blank_yes_no_dont_know,
    health.caridiac_pacemaker_details
   FROM ((tms
     JOIN mri ON ((tms.master_id = mri.master_id)))
     JOIN health ON ((tms.master_id = health.master_id)))
  WHERE ((tms.r = 1) AND (health.r = 1) AND (mri.r = 1));


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
-- Name: ipa_two_wk_followup_history; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_two_wk_followup_history (
    id integer NOT NULL,
    master_id integer,
    participant_had_qs_yes_no character varying,
    participant_qs_notes character varying,
    assisted_finding_provider_yes_no character varying,
    assistance_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ipa_two_wk_followup_id integer
);


--
-- Name: ipa_two_wk_followup_history_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_two_wk_followup_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_two_wk_followup_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_two_wk_followup_history_id_seq OWNED BY ipa_ops.ipa_two_wk_followup_history.id;


--
-- Name: ipa_two_wk_followups; Type: TABLE; Schema: ipa_ops; Owner: -
--

CREATE TABLE ipa_ops.ipa_two_wk_followups (
    id integer NOT NULL,
    master_id integer,
    participant_had_qs_yes_no character varying,
    participant_qs_notes character varying,
    assisted_finding_provider_yes_no character varying,
    assistance_notes character varying,
    other_notes character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ipa_two_wk_followups_id_seq; Type: SEQUENCE; Schema: ipa_ops; Owner: -
--

CREATE SEQUENCE ipa_ops.ipa_two_wk_followups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipa_two_wk_followups_id_seq; Type: SEQUENCE OWNED BY; Schema: ipa_ops; Owner: -
--

ALTER SEQUENCE ipa_ops.ipa_two_wk_followups_id_seq OWNED BY ipa_ops.ipa_two_wk_followups.id;


--
-- Name: ipa_view_subject_statuses; Type: VIEW; Schema: ipa_ops; Owner: -
--

CREATE VIEW ipa_ops.ipa_view_subject_statuses AS
 SELECT dt2.master_id,
    dt2.status,
    dt2.first_name,
    dt2.last_name,
    dt2."when",
    dt2.ipa_id
   FROM ( SELECT DISTINCT dt.master_id,
                CASE
                    WHEN ((dt.extra_log_type)::text = 'follow_up_surveys'::text) THEN 'completed'::character varying
                    WHEN ((dt.extra_log_type)::text = 'withdraw'::text) THEN 'withdrawn'::character varying
                    WHEN (((dt.ps_interested1)::text = 'not interested'::text) OR ((dt.ps_interested2)::text = 'not interested'::text) OR ((dt.ps_still_interested)::text = 'no'::text)) THEN 'not interest during phone screening'::character varying
                    WHEN (((dt.extra_log_type)::text = 'perform_screening_follow_up'::text) AND ((dt.eligible_for_study_blank_yes_no)::text = 'no'::text)) THEN 'ineligible'::character varying
                    WHEN (((dt.extra_log_type)::text = 'perform_screening_follow_up'::text) AND ((dt.follow_up_still_interested)::text = 'no'::text)) THEN 'not interest during screening follow-up'::character varying
                    WHEN ((dt.extra_log_type)::text = 'schedule_screening'::text) THEN 'in process'::character varying
                    ELSE dt.extra_log_type
                END AS status,
            pi.first_name,
            pi.last_name,
            dt.created_at AS "when",
            ipa.ipa_id
           FROM ((( SELECT al.master_id,
                    al.created_at,
                    al.extra_log_type,
                    ipa_screenings.eligible_for_study_blank_yes_no,
                    ipa_screenings.still_interested_blank_yes_no AS follow_up_still_interested,
                    ipa_ps_initial_screenings.select_is_good_time_to_speak AS ps_interested1,
                    ipa_ps_initial_screenings.select_may_i_begin AS ps_interested2,
                    ipa_ps_initial_screenings.select_still_interested AS ps_still_interested,
                    rank() OVER (PARTITION BY al.master_id ORDER BY al.created_at DESC) AS r
                   FROM (((ipa_ops.activity_log_ipa_assignments al
                     LEFT JOIN ipa_ops.ipa_screenings ON ((al.master_id = ipa_screenings.master_id)))
                     LEFT JOIN ipa_ops.ipa_surveys ON ((al.master_id = ipa_surveys.master_id)))
                     LEFT JOIN ipa_ops.ipa_ps_initial_screenings ON ((al.master_id = ipa_ps_initial_screenings.master_id)))
                  WHERE (((ipa_ps_initial_screenings.select_is_good_time_to_speak)::text = 'not interested'::text) OR ((ipa_ps_initial_screenings.select_may_i_begin)::text = 'not interested'::text) OR ((ipa_ps_initial_screenings.select_still_interested)::text = 'no'::text) OR (((al.extra_log_type)::text = 'perform_screening_follow_up'::text) AND (((ipa_screenings.eligible_for_study_blank_yes_no)::text = 'no'::text) OR ((ipa_screenings.still_interested_blank_yes_no)::text = 'no'::text))) OR (((al.extra_log_type)::text = 'follow_up_surveys'::text) AND ((ipa_surveys.select_survey_type)::text = 'exit survey'::text)) OR ((al.extra_log_type)::text = 'withdraw'::text) OR ((al.extra_log_type)::text = 'schedule_screening'::text))) dt
             JOIN ml_app.player_infos pi ON ((dt.master_id = pi.master_id)))
             JOIN ipa_ops.ipa_assignments ipa ON ((dt.master_id = ipa.master_id)))
          WHERE (dt.r = 1)) dt2
  ORDER BY dt2.status, dt2."when" DESC;


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
    select_organization character varying,
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
    select_organization character varying,
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
    category character varying
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
    category character varying
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
    password_updated_at timestamp without time zone
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
    do_not_email boolean DEFAULT false
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
    updated_at timestamp without time zone
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
    alphanumeric boolean
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
    extra_fields character varying
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
    recipient_data character varying[],
    from_user_email character varying,
    role_name character varying,
    content_template_text character varying,
    importance character varying,
    extra_substitutions character varying
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
    updated_at timestamp without time zone
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
    external_id character varying,
    external_type character varying,
    event character varying,
    select_status character varying DEFAULT 'new'::character varying,
    record_updated_at timestamp without time zone,
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
    last_name character varying
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
    do_not_email boolean DEFAULT false
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

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_discussion_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_discussion_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_discussions ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_discussions_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_med_nav_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_med_nav_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_med_navs ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_med_navs_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_post_visit_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_post_visit_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_post_visits ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_post_visits_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_summaries ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_summaries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_summary_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignment_summary_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignments ALTER COLUMN id SET DEFAULT nextval('ipa_ops.activity_log_ipa_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.adl_screener_data ALTER COLUMN id SET DEFAULT nextval('ipa_ops.adl_screener_data_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.emergency_contact_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.emergency_contact_history_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.ipa_assignments ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_assignments_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.ipa_exit_interview_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_exit_interview_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_exit_interviews ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_exit_interviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_four_wk_followup_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_four_wk_followup_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_four_wk_followups ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_four_wk_followups_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.ipa_incidental_finding_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_incidental_finding_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_incidental_findings ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_incidental_findings_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.ipa_medical_detail_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_medical_detail_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medical_details ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_medical_details_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medication_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_medication_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medications ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_medications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_followup_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_mednav_followup_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_followups ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_mednav_followups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_comm_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_mednav_provider_comm_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_comms ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_mednav_provider_comms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_report_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_mednav_provider_report_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_reports ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_mednav_provider_reports_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.ipa_protocol_exception_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_protocol_exception_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_exceptions ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_protocol_exceptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_comp_review_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_comp_review_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_comp_reviews ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_comp_reviews_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.ipa_ps_informant_detail_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_informant_detail_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_informant_details ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_ps_informant_details_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.ipa_reimbursement_req_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_reimbursement_req_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_reimbursement_reqs ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_reimbursement_reqs_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.ipa_special_consideration_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_special_consideration_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_special_considerations ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_special_considerations_id_seq'::regclass);


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

ALTER TABLE ONLY ipa_ops.ipa_two_wk_followup_history ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_two_wk_followup_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_two_wk_followups ALTER COLUMN id SET DEFAULT nextval('ipa_ops.ipa_two_wk_followups_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.scantron_history ALTER COLUMN id SET DEFAULT nextval('ml_app.scantron_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.scantrons ALTER COLUMN id SET DEFAULT nextval('ml_app.scantrons_id_seq'::regclass);


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

ALTER TABLE ONLY ml_app.user_history ALTER COLUMN id SET DEFAULT nextval('ml_app.user_history_id_seq'::regclass);


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
-- Name: activity_log_ipa_assignment_discussion_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_discussion_history
    ADD CONSTRAINT activity_log_ipa_assignment_discussion_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_discussions_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_discussions
    ADD CONSTRAINT activity_log_ipa_assignment_discussions_pkey PRIMARY KEY (id);


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
-- Name: activity_log_ipa_assignment_med_nav_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_med_nav_history
    ADD CONSTRAINT activity_log_ipa_assignment_med_nav_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_med_navs_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_med_navs
    ADD CONSTRAINT activity_log_ipa_assignment_med_navs_pkey PRIMARY KEY (id);


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
-- Name: activity_log_ipa_assignment_post_visit_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_post_visit_history
    ADD CONSTRAINT activity_log_ipa_assignment_post_visit_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_post_visits_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_post_visits
    ADD CONSTRAINT activity_log_ipa_assignment_post_visits_pkey PRIMARY KEY (id);


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
-- Name: activity_log_ipa_assignment_summaries_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_summaries
    ADD CONSTRAINT activity_log_ipa_assignment_summaries_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignment_summary_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_summary_history
    ADD CONSTRAINT activity_log_ipa_assignment_summary_history_pkey PRIMARY KEY (id);


--
-- Name: activity_log_ipa_assignments_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignments
    ADD CONSTRAINT activity_log_ipa_assignments_pkey PRIMARY KEY (id);


--
-- Name: adl_screener_data_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.adl_screener_data
    ADD CONSTRAINT adl_screener_data_pkey PRIMARY KEY (id);


--
-- Name: emergency_contact_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.emergency_contact_history
    ADD CONSTRAINT emergency_contact_history_pkey PRIMARY KEY (id);


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
-- Name: ipa_assignment_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_assignment_history
    ADD CONSTRAINT ipa_assignment_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_assignments_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_assignments
    ADD CONSTRAINT ipa_assignments_pkey PRIMARY KEY (id);


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
-- Name: ipa_exit_interview_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_exit_interview_history
    ADD CONSTRAINT ipa_exit_interview_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_exit_interviews_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_exit_interviews
    ADD CONSTRAINT ipa_exit_interviews_pkey PRIMARY KEY (id);


--
-- Name: ipa_four_wk_followup_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_four_wk_followup_history
    ADD CONSTRAINT ipa_four_wk_followup_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_four_wk_followups_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_four_wk_followups
    ADD CONSTRAINT ipa_four_wk_followups_pkey PRIMARY KEY (id);


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
-- Name: ipa_incidental_finding_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_incidental_finding_history
    ADD CONSTRAINT ipa_incidental_finding_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_incidental_findings_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_incidental_findings
    ADD CONSTRAINT ipa_incidental_findings_pkey PRIMARY KEY (id);


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
-- Name: ipa_medical_detail_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medical_detail_history
    ADD CONSTRAINT ipa_medical_detail_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_medical_details_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medical_details
    ADD CONSTRAINT ipa_medical_details_pkey PRIMARY KEY (id);


--
-- Name: ipa_medication_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medication_history
    ADD CONSTRAINT ipa_medication_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_medications_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medications
    ADD CONSTRAINT ipa_medications_pkey PRIMARY KEY (id);


--
-- Name: ipa_mednav_followup_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_followup_history
    ADD CONSTRAINT ipa_mednav_followup_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_mednav_followups_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_followups
    ADD CONSTRAINT ipa_mednav_followups_pkey PRIMARY KEY (id);


--
-- Name: ipa_mednav_provider_comm_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_comm_history
    ADD CONSTRAINT ipa_mednav_provider_comm_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_mednav_provider_comms_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_comms
    ADD CONSTRAINT ipa_mednav_provider_comms_pkey PRIMARY KEY (id);


--
-- Name: ipa_mednav_provider_report_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_report_history
    ADD CONSTRAINT ipa_mednav_provider_report_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_mednav_provider_reports_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_reports
    ADD CONSTRAINT ipa_mednav_provider_reports_pkey PRIMARY KEY (id);


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
-- Name: ipa_protocol_exception_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_exception_history
    ADD CONSTRAINT ipa_protocol_exception_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_protocol_exceptions_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_exceptions
    ADD CONSTRAINT ipa_protocol_exceptions_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_comp_review_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_comp_review_history
    ADD CONSTRAINT ipa_ps_comp_review_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_comp_reviews_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_comp_reviews
    ADD CONSTRAINT ipa_ps_comp_reviews_pkey PRIMARY KEY (id);


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
-- Name: ipa_ps_informant_detail_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_informant_detail_history
    ADD CONSTRAINT ipa_ps_informant_detail_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_ps_informant_details_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_informant_details
    ADD CONSTRAINT ipa_ps_informant_details_pkey PRIMARY KEY (id);


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
-- Name: ipa_reimbursement_req_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_reimbursement_req_history
    ADD CONSTRAINT ipa_reimbursement_req_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_reimbursement_reqs_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_reimbursement_reqs
    ADD CONSTRAINT ipa_reimbursement_reqs_pkey PRIMARY KEY (id);


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
-- Name: ipa_special_consideration_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_special_consideration_history
    ADD CONSTRAINT ipa_special_consideration_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_special_considerations_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_special_considerations
    ADD CONSTRAINT ipa_special_considerations_pkey PRIMARY KEY (id);


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
-- Name: ipa_two_wk_followup_history_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_two_wk_followup_history
    ADD CONSTRAINT ipa_two_wk_followup_history_pkey PRIMARY KEY (id);


--
-- Name: ipa_two_wk_followups_pkey; Type: CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_two_wk_followups
    ADD CONSTRAINT ipa_two_wk_followups_pkey PRIMARY KEY (id);


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
-- Name: user_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.user_history
    ADD CONSTRAINT user_history_pkey PRIMARY KEY (id);


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
-- Name: index_activity_log_ipa_assignment_discussions_on_ipa_assignment; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_discussions_on_ipa_assignment ON ipa_ops.activity_log_ipa_assignment_discussions USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_discussions_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_discussions_on_master_id ON ipa_ops.activity_log_ipa_assignment_discussions USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_discussions_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_discussions_on_user_id ON ipa_ops.activity_log_ipa_assignment_discussions USING btree (user_id);


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
-- Name: index_activity_log_ipa_assignment_med_navs_on_ipa_assignment_me; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_med_navs_on_ipa_assignment_me ON ipa_ops.activity_log_ipa_assignment_med_navs USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_med_navs_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_med_navs_on_master_id ON ipa_ops.activity_log_ipa_assignment_med_navs USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_med_navs_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_med_navs_on_user_id ON ipa_ops.activity_log_ipa_assignment_med_navs USING btree (user_id);


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
-- Name: index_activity_log_ipa_assignment_post_visit_history_on_activit; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_post_visit_history_on_activit ON ipa_ops.activity_log_ipa_assignment_post_visit_history USING btree (activity_log_ipa_assignment_post_visit_id);


--
-- Name: index_activity_log_ipa_assignment_post_visit_history_on_ipa_ass; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_post_visit_history_on_ipa_ass ON ipa_ops.activity_log_ipa_assignment_post_visit_history USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_post_visit_history_on_master_; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_post_visit_history_on_master_ ON ipa_ops.activity_log_ipa_assignment_post_visit_history USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_post_visit_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_post_visit_history_on_user_id ON ipa_ops.activity_log_ipa_assignment_post_visit_history USING btree (user_id);


--
-- Name: index_activity_log_ipa_assignment_post_visits_on_ipa_assignment; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_post_visits_on_ipa_assignment ON ipa_ops.activity_log_ipa_assignment_post_visits USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_post_visits_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_post_visits_on_master_id ON ipa_ops.activity_log_ipa_assignment_post_visits USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_post_visits_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_post_visits_on_user_id ON ipa_ops.activity_log_ipa_assignment_post_visits USING btree (user_id);


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
-- Name: index_activity_log_ipa_assignment_summaries_on_ipa_assignment_s; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_summaries_on_ipa_assignment_s ON ipa_ops.activity_log_ipa_assignment_summaries USING btree (ipa_assignment_id);


--
-- Name: index_activity_log_ipa_assignment_summaries_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_summaries_on_master_id ON ipa_ops.activity_log_ipa_assignment_summaries USING btree (master_id);


--
-- Name: index_activity_log_ipa_assignment_summaries_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_activity_log_ipa_assignment_summaries_on_user_id ON ipa_ops.activity_log_ipa_assignment_summaries USING btree (user_id);


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
-- Name: index_al_ipa_assignment_discussion_history_on_activity_log_ipa_; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_discussion_history_on_activity_log_ipa_ ON ipa_ops.activity_log_ipa_assignment_discussion_history USING btree (activity_log_ipa_assignment_discussion_id);


--
-- Name: index_al_ipa_assignment_discussion_history_on_ipa_assignment_di; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_discussion_history_on_ipa_assignment_di ON ipa_ops.activity_log_ipa_assignment_discussion_history USING btree (ipa_assignment_id);


--
-- Name: index_al_ipa_assignment_discussion_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_discussion_history_on_master_id ON ipa_ops.activity_log_ipa_assignment_discussion_history USING btree (master_id);


--
-- Name: index_al_ipa_assignment_discussion_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_discussion_history_on_user_id ON ipa_ops.activity_log_ipa_assignment_discussion_history USING btree (user_id);


--
-- Name: index_al_ipa_assignment_med_nav_history_on_activity_log_ipa_ass; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_med_nav_history_on_activity_log_ipa_ass ON ipa_ops.activity_log_ipa_assignment_med_nav_history USING btree (activity_log_ipa_assignment_med_nav_id);


--
-- Name: index_al_ipa_assignment_med_nav_history_on_ipa_assignment_med_n; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_med_nav_history_on_ipa_assignment_med_n ON ipa_ops.activity_log_ipa_assignment_med_nav_history USING btree (ipa_assignment_id);


--
-- Name: index_al_ipa_assignment_med_nav_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_med_nav_history_on_master_id ON ipa_ops.activity_log_ipa_assignment_med_nav_history USING btree (master_id);


--
-- Name: index_al_ipa_assignment_med_nav_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_med_nav_history_on_user_id ON ipa_ops.activity_log_ipa_assignment_med_nav_history USING btree (user_id);


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
-- Name: index_al_ipa_assignment_summary_history_on_activity_log_ipa_ass; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_summary_history_on_activity_log_ipa_ass ON ipa_ops.activity_log_ipa_assignment_summary_history USING btree (activity_log_ipa_assignment_summary_id);


--
-- Name: index_al_ipa_assignment_summary_history_on_ipa_assignment_summa; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_summary_history_on_ipa_assignment_summa ON ipa_ops.activity_log_ipa_assignment_summary_history USING btree (ipa_assignment_id);


--
-- Name: index_al_ipa_assignment_summary_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_summary_history_on_master_id ON ipa_ops.activity_log_ipa_assignment_summary_history USING btree (master_id);


--
-- Name: index_al_ipa_assignment_summary_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_al_ipa_assignment_summary_history_on_user_id ON ipa_ops.activity_log_ipa_assignment_summary_history USING btree (user_id);


--
-- Name: index_emergency_contact_history_on_emergency_contact_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_emergency_contact_history_on_emergency_contact_id ON ipa_ops.emergency_contact_history USING btree (emergency_contact_id);


--
-- Name: index_emergency_contact_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_emergency_contact_history_on_master_id ON ipa_ops.emergency_contact_history USING btree (master_id);


--
-- Name: index_emergency_contact_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_emergency_contact_history_on_user_id ON ipa_ops.emergency_contact_history USING btree (user_id);


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
-- Name: index_ipa_assignments_on_admin_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_assignments_on_admin_id ON ipa_ops.ipa_assignments USING btree (admin_id);


--
-- Name: index_ipa_assignments_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_assignments_on_master_id ON ipa_ops.ipa_assignments USING btree (master_id);


--
-- Name: index_ipa_assignments_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_assignments_on_user_id ON ipa_ops.ipa_assignments USING btree (user_id);


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
-- Name: index_ipa_exit_interview_history_on_ipa_exit_interview_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_exit_interview_history_on_ipa_exit_interview_id ON ipa_ops.ipa_exit_interview_history USING btree (ipa_exit_interview_id);


--
-- Name: index_ipa_exit_interview_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_exit_interview_history_on_master_id ON ipa_ops.ipa_exit_interview_history USING btree (master_id);


--
-- Name: index_ipa_exit_interview_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_exit_interview_history_on_user_id ON ipa_ops.ipa_exit_interview_history USING btree (user_id);


--
-- Name: index_ipa_exit_interviews_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_exit_interviews_on_master_id ON ipa_ops.ipa_exit_interviews USING btree (master_id);


--
-- Name: index_ipa_exit_interviews_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_exit_interviews_on_user_id ON ipa_ops.ipa_exit_interviews USING btree (user_id);


--
-- Name: index_ipa_four_wk_followup_history_on_ipa_four_wk_followup_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_four_wk_followup_history_on_ipa_four_wk_followup_id ON ipa_ops.ipa_four_wk_followup_history USING btree (ipa_four_wk_followup_id);


--
-- Name: index_ipa_four_wk_followup_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_four_wk_followup_history_on_master_id ON ipa_ops.ipa_four_wk_followup_history USING btree (master_id);


--
-- Name: index_ipa_four_wk_followup_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_four_wk_followup_history_on_user_id ON ipa_ops.ipa_four_wk_followup_history USING btree (user_id);


--
-- Name: index_ipa_four_wk_followups_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_four_wk_followups_on_master_id ON ipa_ops.ipa_four_wk_followups USING btree (master_id);


--
-- Name: index_ipa_four_wk_followups_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_four_wk_followups_on_user_id ON ipa_ops.ipa_four_wk_followups USING btree (user_id);


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
-- Name: index_ipa_incidental_finding_history_on_ipa_incidental_finding_; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_incidental_finding_history_on_ipa_incidental_finding_ ON ipa_ops.ipa_incidental_finding_history USING btree (ipa_incidental_finding_id);


--
-- Name: index_ipa_incidental_finding_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_incidental_finding_history_on_master_id ON ipa_ops.ipa_incidental_finding_history USING btree (master_id);


--
-- Name: index_ipa_incidental_finding_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_incidental_finding_history_on_user_id ON ipa_ops.ipa_incidental_finding_history USING btree (user_id);


--
-- Name: index_ipa_incidental_findings_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_incidental_findings_on_master_id ON ipa_ops.ipa_incidental_findings USING btree (master_id);


--
-- Name: index_ipa_incidental_findings_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_incidental_findings_on_user_id ON ipa_ops.ipa_incidental_findings USING btree (user_id);


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
-- Name: index_ipa_medical_detail_history_on_ipa_medical_detail_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_medical_detail_history_on_ipa_medical_detail_id ON ipa_ops.ipa_medical_detail_history USING btree (ipa_medical_detail_id);


--
-- Name: index_ipa_medical_detail_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_medical_detail_history_on_master_id ON ipa_ops.ipa_medical_detail_history USING btree (master_id);


--
-- Name: index_ipa_medical_detail_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_medical_detail_history_on_user_id ON ipa_ops.ipa_medical_detail_history USING btree (user_id);


--
-- Name: index_ipa_medical_details_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_medical_details_on_master_id ON ipa_ops.ipa_medical_details USING btree (master_id);


--
-- Name: index_ipa_medical_details_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_medical_details_on_user_id ON ipa_ops.ipa_medical_details USING btree (user_id);


--
-- Name: index_ipa_medication_history_on_ipa_medication_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_medication_history_on_ipa_medication_id ON ipa_ops.ipa_medication_history USING btree (ipa_medication_id);


--
-- Name: index_ipa_medication_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_medication_history_on_master_id ON ipa_ops.ipa_medication_history USING btree (master_id);


--
-- Name: index_ipa_medication_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_medication_history_on_user_id ON ipa_ops.ipa_medication_history USING btree (user_id);


--
-- Name: index_ipa_medications_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_medications_on_master_id ON ipa_ops.ipa_medications USING btree (master_id);


--
-- Name: index_ipa_medications_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_medications_on_user_id ON ipa_ops.ipa_medications USING btree (user_id);


--
-- Name: index_ipa_mednav_followup_history_on_ipa_mednav_followup_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_followup_history_on_ipa_mednav_followup_id ON ipa_ops.ipa_mednav_followup_history USING btree (ipa_mednav_followup_id);


--
-- Name: index_ipa_mednav_followup_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_followup_history_on_master_id ON ipa_ops.ipa_mednav_followup_history USING btree (master_id);


--
-- Name: index_ipa_mednav_followup_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_followup_history_on_user_id ON ipa_ops.ipa_mednav_followup_history USING btree (user_id);


--
-- Name: index_ipa_mednav_followups_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_followups_on_master_id ON ipa_ops.ipa_mednav_followups USING btree (master_id);


--
-- Name: index_ipa_mednav_followups_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_followups_on_user_id ON ipa_ops.ipa_mednav_followups USING btree (user_id);


--
-- Name: index_ipa_mednav_provider_comm_history_on_ipa_mednav_provider_c; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_provider_comm_history_on_ipa_mednav_provider_c ON ipa_ops.ipa_mednav_provider_comm_history USING btree (ipa_mednav_provider_comm_id);


--
-- Name: index_ipa_mednav_provider_comm_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_provider_comm_history_on_master_id ON ipa_ops.ipa_mednav_provider_comm_history USING btree (master_id);


--
-- Name: index_ipa_mednav_provider_comm_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_provider_comm_history_on_user_id ON ipa_ops.ipa_mednav_provider_comm_history USING btree (user_id);


--
-- Name: index_ipa_mednav_provider_comms_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_provider_comms_on_master_id ON ipa_ops.ipa_mednav_provider_comms USING btree (master_id);


--
-- Name: index_ipa_mednav_provider_comms_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_provider_comms_on_user_id ON ipa_ops.ipa_mednav_provider_comms USING btree (user_id);


--
-- Name: index_ipa_mednav_provider_report_history_on_ipa_mednav_provider; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_provider_report_history_on_ipa_mednav_provider ON ipa_ops.ipa_mednav_provider_report_history USING btree (ipa_mednav_provider_report_id);


--
-- Name: index_ipa_mednav_provider_report_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_provider_report_history_on_master_id ON ipa_ops.ipa_mednav_provider_report_history USING btree (master_id);


--
-- Name: index_ipa_mednav_provider_report_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_provider_report_history_on_user_id ON ipa_ops.ipa_mednav_provider_report_history USING btree (user_id);


--
-- Name: index_ipa_mednav_provider_reports_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_provider_reports_on_master_id ON ipa_ops.ipa_mednav_provider_reports USING btree (master_id);


--
-- Name: index_ipa_mednav_provider_reports_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_mednav_provider_reports_on_user_id ON ipa_ops.ipa_mednav_provider_reports USING btree (user_id);


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
-- Name: index_ipa_protocol_exception_history_on_ipa_protocol_exception_; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_protocol_exception_history_on_ipa_protocol_exception_ ON ipa_ops.ipa_protocol_exception_history USING btree (ipa_protocol_exception_id);


--
-- Name: index_ipa_protocol_exception_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_protocol_exception_history_on_master_id ON ipa_ops.ipa_protocol_exception_history USING btree (master_id);


--
-- Name: index_ipa_protocol_exception_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_protocol_exception_history_on_user_id ON ipa_ops.ipa_protocol_exception_history USING btree (user_id);


--
-- Name: index_ipa_protocol_exceptions_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_protocol_exceptions_on_master_id ON ipa_ops.ipa_protocol_exceptions USING btree (master_id);


--
-- Name: index_ipa_protocol_exceptions_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_protocol_exceptions_on_user_id ON ipa_ops.ipa_protocol_exceptions USING btree (user_id);


--
-- Name: index_ipa_ps_comp_review_history_on_ipa_ps_comp_review_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_comp_review_history_on_ipa_ps_comp_review_id ON ipa_ops.ipa_ps_comp_review_history USING btree (ipa_ps_comp_review_id);


--
-- Name: index_ipa_ps_comp_review_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_comp_review_history_on_master_id ON ipa_ops.ipa_ps_comp_review_history USING btree (master_id);


--
-- Name: index_ipa_ps_comp_review_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_comp_review_history_on_user_id ON ipa_ops.ipa_ps_comp_review_history USING btree (user_id);


--
-- Name: index_ipa_ps_comp_reviews_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_comp_reviews_on_master_id ON ipa_ops.ipa_ps_comp_reviews USING btree (master_id);


--
-- Name: index_ipa_ps_comp_reviews_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_comp_reviews_on_user_id ON ipa_ops.ipa_ps_comp_reviews USING btree (user_id);


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
-- Name: index_ipa_ps_informant_detail_history_on_ipa_ps_informant_detai; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_informant_detail_history_on_ipa_ps_informant_detai ON ipa_ops.ipa_ps_informant_detail_history USING btree (ipa_ps_informant_detail_id);


--
-- Name: index_ipa_ps_informant_detail_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_informant_detail_history_on_master_id ON ipa_ops.ipa_ps_informant_detail_history USING btree (master_id);


--
-- Name: index_ipa_ps_informant_detail_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_informant_detail_history_on_user_id ON ipa_ops.ipa_ps_informant_detail_history USING btree (user_id);


--
-- Name: index_ipa_ps_informant_details_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_informant_details_on_master_id ON ipa_ops.ipa_ps_informant_details USING btree (master_id);


--
-- Name: index_ipa_ps_informant_details_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_ps_informant_details_on_user_id ON ipa_ops.ipa_ps_informant_details USING btree (user_id);


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
-- Name: index_ipa_reimbursement_req_history_on_ipa_reimbursement_req_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_reimbursement_req_history_on_ipa_reimbursement_req_id ON ipa_ops.ipa_reimbursement_req_history USING btree (ipa_reimbursement_req_id);


--
-- Name: index_ipa_reimbursement_req_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_reimbursement_req_history_on_master_id ON ipa_ops.ipa_reimbursement_req_history USING btree (master_id);


--
-- Name: index_ipa_reimbursement_req_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_reimbursement_req_history_on_user_id ON ipa_ops.ipa_reimbursement_req_history USING btree (user_id);


--
-- Name: index_ipa_reimbursement_reqs_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_reimbursement_reqs_on_master_id ON ipa_ops.ipa_reimbursement_reqs USING btree (master_id);


--
-- Name: index_ipa_reimbursement_reqs_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_reimbursement_reqs_on_user_id ON ipa_ops.ipa_reimbursement_reqs USING btree (user_id);


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
-- Name: index_ipa_special_consideration_history_on_ipa_special_consider; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_special_consideration_history_on_ipa_special_consider ON ipa_ops.ipa_special_consideration_history USING btree (ipa_special_consideration_id);


--
-- Name: index_ipa_special_consideration_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_special_consideration_history_on_master_id ON ipa_ops.ipa_special_consideration_history USING btree (master_id);


--
-- Name: index_ipa_special_consideration_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_special_consideration_history_on_user_id ON ipa_ops.ipa_special_consideration_history USING btree (user_id);


--
-- Name: index_ipa_special_considerations_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_special_considerations_on_master_id ON ipa_ops.ipa_special_considerations USING btree (master_id);


--
-- Name: index_ipa_special_considerations_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_special_considerations_on_user_id ON ipa_ops.ipa_special_considerations USING btree (user_id);


--
-- Name: index_ipa_station_contact_history_on_ipa_station_contact_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_station_contact_history_on_ipa_station_contact_id ON ipa_ops.ipa_station_contact_history USING btree (ipa_station_contact_id);


--
-- Name: index_ipa_station_contact_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_station_contact_history_on_user_id ON ipa_ops.ipa_station_contact_history USING btree (user_id);


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
-- Name: index_ipa_two_wk_followup_history_on_ipa_two_wk_followup_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_two_wk_followup_history_on_ipa_two_wk_followup_id ON ipa_ops.ipa_two_wk_followup_history USING btree (ipa_two_wk_followup_id);


--
-- Name: index_ipa_two_wk_followup_history_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_two_wk_followup_history_on_master_id ON ipa_ops.ipa_two_wk_followup_history USING btree (master_id);


--
-- Name: index_ipa_two_wk_followup_history_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_two_wk_followup_history_on_user_id ON ipa_ops.ipa_two_wk_followup_history USING btree (user_id);


--
-- Name: index_ipa_two_wk_followups_on_master_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_two_wk_followups_on_master_id ON ipa_ops.ipa_two_wk_followups USING btree (master_id);


--
-- Name: index_ipa_two_wk_followups_on_user_id; Type: INDEX; Schema: ipa_ops; Owner: -
--

CREATE INDEX index_ipa_two_wk_followups_on_user_id ON ipa_ops.ipa_two_wk_followups USING btree (user_id);


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
-- Name: index_user_history_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_history_on_app_type_id ON ml_app.user_history USING btree (app_type_id);


--
-- Name: index_user_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--

CREATE INDEX index_user_history_on_user_id ON ml_app.user_history USING btree (user_id);


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
-- Name: activity_log_ipa_assignment_adverse_event_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_adverse_event_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_adverse_events FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_adverse_event_update();


--
-- Name: activity_log_ipa_assignment_adverse_event_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_adverse_event_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_adverse_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_adverse_event_update();


--
-- Name: activity_log_ipa_assignment_discussion_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_discussion_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_discussions FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_discussion_update();


--
-- Name: activity_log_ipa_assignment_discussion_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_discussion_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_discussions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_discussion_update();


--
-- Name: activity_log_ipa_assignment_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignments FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_update();


--
-- Name: activity_log_ipa_assignment_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_update();


--
-- Name: activity_log_ipa_assignment_inex_checklist_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_inex_checklist_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_inex_checklists FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_inex_checklist_update();


--
-- Name: activity_log_ipa_assignment_inex_checklist_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_inex_checklist_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_inex_checklists FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_inex_checklist_update();


--
-- Name: activity_log_ipa_assignment_med_nav_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_med_nav_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_med_navs FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_med_nav_update();


--
-- Name: activity_log_ipa_assignment_med_nav_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_med_nav_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_med_navs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_med_nav_update();


--
-- Name: activity_log_ipa_assignment_minor_deviation_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_minor_deviation_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_minor_deviations FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_minor_deviation_update();


--
-- Name: activity_log_ipa_assignment_minor_deviation_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_minor_deviation_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_minor_deviations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_minor_deviation_update();


--
-- Name: activity_log_ipa_assignment_navigation_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_navigation_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_navigations FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_navigation_update();


--
-- Name: activity_log_ipa_assignment_navigation_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_navigation_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_navigations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_navigation_update();


--
-- Name: activity_log_ipa_assignment_phone_screen_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_phone_screen_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_phone_screens FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_phone_screen_update();


--
-- Name: activity_log_ipa_assignment_phone_screen_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_phone_screen_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_phone_screens FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_phone_screen_update();


--
-- Name: activity_log_ipa_assignment_post_visit_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_post_visit_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_post_visits FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_post_visit_update();


--
-- Name: activity_log_ipa_assignment_post_visit_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_post_visit_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_post_visits FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_post_visit_update();


--
-- Name: activity_log_ipa_assignment_protocol_deviation_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_protocol_deviation_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_protocol_deviations FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_protocol_deviation_update();


--
-- Name: activity_log_ipa_assignment_protocol_deviation_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_protocol_deviation_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_protocol_deviations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_protocol_deviation_update();


--
-- Name: activity_log_ipa_assignment_summary_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_summary_history_insert AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_summaries FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_summary_update();


--
-- Name: activity_log_ipa_assignment_summary_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER activity_log_ipa_assignment_summary_history_update AFTER UPDATE ON ipa_ops.activity_log_ipa_assignment_summaries FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_activity_log_ipa_assignment_summary_update();


--
-- Name: emergency_contact_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER emergency_contact_history_insert AFTER INSERT ON ipa_ops.emergency_contacts FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_emergency_contact_update();


--
-- Name: emergency_contact_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER emergency_contact_history_update AFTER UPDATE ON ipa_ops.emergency_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_emergency_contact_update();


--
-- Name: ipa_adl_informant_screener_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_adl_informant_screener_history_insert AFTER INSERT ON ipa_ops.ipa_adl_informant_screeners FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_adl_informant_screener_update();


--
-- Name: ipa_adl_informant_screener_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_adl_informant_screener_history_update AFTER UPDATE ON ipa_ops.ipa_adl_informant_screeners FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_adl_informant_screener_update();


--
-- Name: ipa_adverse_event_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_adverse_event_history_insert AFTER INSERT ON ipa_ops.ipa_adverse_events FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_adverse_event_update();


--
-- Name: ipa_adverse_event_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_adverse_event_history_update AFTER UPDATE ON ipa_ops.ipa_adverse_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_adverse_event_update();


--
-- Name: ipa_appointment_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_appointment_history_insert AFTER INSERT ON ipa_ops.ipa_appointments FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_appointment_update();


--
-- Name: ipa_appointment_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_appointment_history_update AFTER UPDATE ON ipa_ops.ipa_appointments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_appointment_update();


--
-- Name: ipa_assignment_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_assignment_history_insert AFTER INSERT ON ipa_ops.ipa_assignments FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_assignment_update();


--
-- Name: ipa_assignment_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_assignment_history_update AFTER UPDATE ON ipa_ops.ipa_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_assignment_update();


--
-- Name: ipa_consent_mailing_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_consent_mailing_history_insert AFTER INSERT ON ipa_ops.ipa_consent_mailings FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_consent_mailing_update();


--
-- Name: ipa_consent_mailing_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_consent_mailing_history_update AFTER UPDATE ON ipa_ops.ipa_consent_mailings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_consent_mailing_update();


--
-- Name: ipa_exit_interview_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_exit_interview_history_insert AFTER INSERT ON ipa_ops.ipa_exit_interviews FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_exit_interview_update();


--
-- Name: ipa_exit_interview_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_exit_interview_history_update AFTER UPDATE ON ipa_ops.ipa_exit_interviews FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_exit_interview_update();


--
-- Name: ipa_four_wk_followup_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_four_wk_followup_history_insert AFTER INSERT ON ipa_ops.ipa_four_wk_followups FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_four_wk_followup_update();


--
-- Name: ipa_four_wk_followup_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_four_wk_followup_history_update AFTER UPDATE ON ipa_ops.ipa_four_wk_followups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_four_wk_followup_update();


--
-- Name: ipa_hotel_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_hotel_history_insert AFTER INSERT ON ipa_ops.ipa_hotels FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_hotel_update();


--
-- Name: ipa_hotel_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_hotel_history_update AFTER UPDATE ON ipa_ops.ipa_hotels FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_hotel_update();


--
-- Name: ipa_incidental_finding_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_incidental_finding_history_insert AFTER INSERT ON ipa_ops.ipa_incidental_findings FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_incidental_finding_update();


--
-- Name: ipa_incidental_finding_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_incidental_finding_history_update AFTER UPDATE ON ipa_ops.ipa_incidental_findings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_incidental_finding_update();


--
-- Name: ipa_inex_checklist_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_inex_checklist_history_insert AFTER INSERT ON ipa_ops.ipa_inex_checklists FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_inex_checklist_update();


--
-- Name: ipa_inex_checklist_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_inex_checklist_history_update AFTER UPDATE ON ipa_ops.ipa_inex_checklists FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_inex_checklist_update();


--
-- Name: ipa_initial_screening_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_initial_screening_history_insert AFTER INSERT ON ipa_ops.ipa_initial_screenings FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_initial_screening_update();


--
-- Name: ipa_initial_screening_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_initial_screening_history_update AFTER UPDATE ON ipa_ops.ipa_initial_screenings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_initial_screening_update();


--
-- Name: ipa_medical_detail_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_medical_detail_history_insert AFTER INSERT ON ipa_ops.ipa_medical_details FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_medical_detail_update();


--
-- Name: ipa_medical_detail_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_medical_detail_history_update AFTER UPDATE ON ipa_ops.ipa_medical_details FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_medical_detail_update();


--
-- Name: ipa_medication_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_medication_history_insert AFTER INSERT ON ipa_ops.ipa_medications FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_medication_update();


--
-- Name: ipa_medication_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_medication_history_update AFTER UPDATE ON ipa_ops.ipa_medications FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_medication_update();


--
-- Name: ipa_mednav_followup_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_mednav_followup_history_insert AFTER INSERT ON ipa_ops.ipa_mednav_followups FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_mednav_followup_update();


--
-- Name: ipa_mednav_followup_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_mednav_followup_history_update AFTER UPDATE ON ipa_ops.ipa_mednav_followups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_mednav_followup_update();


--
-- Name: ipa_mednav_provider_comm_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_mednav_provider_comm_history_insert AFTER INSERT ON ipa_ops.ipa_mednav_provider_comms FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_mednav_provider_comm_update();


--
-- Name: ipa_mednav_provider_comm_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_mednav_provider_comm_history_update AFTER UPDATE ON ipa_ops.ipa_mednav_provider_comms FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_mednav_provider_comm_update();


--
-- Name: ipa_mednav_provider_report_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_mednav_provider_report_history_insert AFTER INSERT ON ipa_ops.ipa_mednav_provider_reports FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_mednav_provider_report_update();


--
-- Name: ipa_mednav_provider_report_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_mednav_provider_report_history_update AFTER UPDATE ON ipa_ops.ipa_mednav_provider_reports FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_mednav_provider_report_update();


--
-- Name: ipa_payment_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_payment_history_insert AFTER INSERT ON ipa_ops.ipa_payments FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_payment_update();


--
-- Name: ipa_payment_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_payment_history_update AFTER UPDATE ON ipa_ops.ipa_payments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_payment_update();


--
-- Name: ipa_protocol_deviation_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_protocol_deviation_history_insert AFTER INSERT ON ipa_ops.ipa_protocol_deviations FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_protocol_deviation_update();


--
-- Name: ipa_protocol_deviation_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_protocol_deviation_history_update AFTER UPDATE ON ipa_ops.ipa_protocol_deviations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_protocol_deviation_update();


--
-- Name: ipa_protocol_exception_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_protocol_exception_history_insert AFTER INSERT ON ipa_ops.ipa_protocol_exceptions FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_protocol_exception_update();


--
-- Name: ipa_protocol_exception_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_protocol_exception_history_update AFTER UPDATE ON ipa_ops.ipa_protocol_exceptions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_protocol_exception_update();


--
-- Name: ipa_ps_comp_review_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_comp_review_history_insert AFTER INSERT ON ipa_ops.ipa_ps_comp_reviews FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_ps_comp_review_update();


--
-- Name: ipa_ps_comp_review_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_comp_review_history_update AFTER UPDATE ON ipa_ops.ipa_ps_comp_reviews FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_ps_comp_review_update();


--
-- Name: ipa_ps_football_experience_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_football_experience_history_insert AFTER INSERT ON ipa_ops.ipa_ps_football_experiences FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_ps_football_experience_update();


--
-- Name: ipa_ps_football_experience_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_football_experience_history_update AFTER UPDATE ON ipa_ops.ipa_ps_football_experiences FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_ps_football_experience_update();


--
-- Name: ipa_ps_health_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_health_history_insert AFTER INSERT ON ipa_ops.ipa_ps_healths FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_ps_health_update();


--
-- Name: ipa_ps_health_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_health_history_update AFTER UPDATE ON ipa_ops.ipa_ps_healths FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_ps_health_update();


--
-- Name: ipa_ps_informant_detail_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_informant_detail_history_insert AFTER INSERT ON ipa_ops.ipa_ps_informant_details FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_ps_informant_detail_update();


--
-- Name: ipa_ps_informant_detail_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_informant_detail_history_update AFTER UPDATE ON ipa_ops.ipa_ps_informant_details FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_ps_informant_detail_update();


--
-- Name: ipa_ps_initial_screening_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_initial_screening_history_insert AFTER INSERT ON ipa_ops.ipa_ps_initial_screenings FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_ps_initial_screening_update();


--
-- Name: ipa_ps_initial_screening_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_initial_screening_history_update AFTER UPDATE ON ipa_ops.ipa_ps_initial_screenings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_ps_initial_screening_update();


--
-- Name: ipa_ps_mri_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_mri_history_insert AFTER INSERT ON ipa_ops.ipa_ps_mris FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_ps_mri_update();


--
-- Name: ipa_ps_mri_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_mri_history_update AFTER UPDATE ON ipa_ops.ipa_ps_mris FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_ps_mri_update();


--
-- Name: ipa_ps_size_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_size_history_insert AFTER INSERT ON ipa_ops.ipa_ps_sizes FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_ps_size_update();


--
-- Name: ipa_ps_size_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_size_history_update AFTER UPDATE ON ipa_ops.ipa_ps_sizes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_ps_size_update();


--
-- Name: ipa_ps_sleep_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_sleep_history_insert AFTER INSERT ON ipa_ops.ipa_ps_sleeps FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_ps_sleep_update();


--
-- Name: ipa_ps_sleep_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_sleep_history_update AFTER UPDATE ON ipa_ops.ipa_ps_sleeps FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_ps_sleep_update();


--
-- Name: ipa_ps_tmoca_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_tmoca_history_insert AFTER INSERT ON ipa_ops.ipa_ps_tmocas FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_ps_tmoca_update();


--
-- Name: ipa_ps_tmoca_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_tmoca_history_update AFTER UPDATE ON ipa_ops.ipa_ps_tmocas FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_ps_tmoca_update();


--
-- Name: ipa_ps_tmoca_score_calc; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_tmoca_score_calc BEFORE INSERT ON ipa_ops.ipa_ps_tmocas FOR EACH ROW EXECUTE PROCEDURE ipa_ops.ipa_ps_tmoca_score_calc();


--
-- Name: ipa_ps_tmoca_score_calc_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_tmoca_score_calc_update BEFORE UPDATE ON ipa_ops.ipa_ps_tmocas FOR EACH ROW EXECUTE PROCEDURE ipa_ops.ipa_ps_tmoca_score_calc();


--
-- Name: ipa_ps_tms_test_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_tms_test_history_insert AFTER INSERT ON ipa_ops.ipa_ps_tms_tests FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_ps_tms_test_update();


--
-- Name: ipa_ps_tms_test_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_tms_test_history_update AFTER UPDATE ON ipa_ops.ipa_ps_tms_tests FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_ps_tms_test_update();


--
-- Name: ipa_ps_to_inex; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_ps_to_inex AFTER INSERT ON ipa_ops.activity_log_ipa_assignment_phone_screens FOR EACH ROW EXECUTE PROCEDURE ipa_ops.activity_log_ipa_assignment_phone_screens_callback_set();


--
-- Name: ipa_reimbursement_req_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_reimbursement_req_history_insert AFTER INSERT ON ipa_ops.ipa_reimbursement_reqs FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_reimbursement_req_update();


--
-- Name: ipa_reimbursement_req_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_reimbursement_req_history_update AFTER UPDATE ON ipa_ops.ipa_reimbursement_reqs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_reimbursement_req_update();


--
-- Name: ipa_screening_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_screening_history_insert AFTER INSERT ON ipa_ops.ipa_screenings FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_screening_update();


--
-- Name: ipa_screening_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_screening_history_update AFTER UPDATE ON ipa_ops.ipa_screenings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_screening_update();


--
-- Name: ipa_special_consideration_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_special_consideration_history_insert AFTER INSERT ON ipa_ops.ipa_special_considerations FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_special_consideration_update();


--
-- Name: ipa_special_consideration_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_special_consideration_history_update AFTER UPDATE ON ipa_ops.ipa_special_considerations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_special_consideration_update();


--
-- Name: ipa_station_contact_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_station_contact_history_insert AFTER INSERT ON ipa_ops.ipa_station_contacts FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_station_contact_update();


--
-- Name: ipa_station_contact_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_station_contact_history_update AFTER UPDATE ON ipa_ops.ipa_station_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_station_contact_update();


--
-- Name: ipa_survey_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_survey_history_insert AFTER INSERT ON ipa_ops.ipa_surveys FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_survey_update();


--
-- Name: ipa_survey_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_survey_history_update AFTER UPDATE ON ipa_ops.ipa_surveys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_survey_update();


--
-- Name: ipa_transportation_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_transportation_history_insert AFTER INSERT ON ipa_ops.ipa_transportations FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_transportation_update();


--
-- Name: ipa_transportation_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_transportation_history_update AFTER UPDATE ON ipa_ops.ipa_transportations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_transportation_update();


--
-- Name: ipa_two_wk_followup_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_two_wk_followup_history_insert AFTER INSERT ON ipa_ops.ipa_two_wk_followups FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_two_wk_followup_update();


--
-- Name: ipa_two_wk_followup_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_two_wk_followup_history_update AFTER UPDATE ON ipa_ops.ipa_two_wk_followups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_two_wk_followup_update();


--
-- Name: ipa_withdrawal_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_withdrawal_history_insert AFTER INSERT ON ipa_ops.ipa_withdrawals FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_ipa_withdrawal_update();


--
-- Name: ipa_withdrawal_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER ipa_withdrawal_history_update AFTER UPDATE ON ipa_ops.ipa_withdrawals FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_ipa_withdrawal_update();


--
-- Name: mrn_number_history_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER mrn_number_history_insert AFTER INSERT ON ipa_ops.mrn_numbers FOR EACH ROW EXECUTE PROCEDURE ipa_ops.log_mrn_number_update();


--
-- Name: mrn_number_history_update; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER mrn_number_history_update AFTER UPDATE ON ipa_ops.mrn_numbers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ipa_ops.log_mrn_number_update();


--
-- Name: on_adl_screener_data_insert; Type: TRIGGER; Schema: ipa_ops; Owner: -
--

CREATE TRIGGER on_adl_screener_data_insert AFTER INSERT ON ipa_ops.adl_screener_data FOR EACH ROW EXECUTE PROCEDURE ipa_ops.sync_new_adl_screener();


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
-- Name: activity_log_bhs_assignment_insert_defaults; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_bhs_assignment_insert_defaults BEFORE INSERT ON ml_app.activity_log_bhs_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app.activity_log_bhs_assignment_insert_defaults();


--
-- Name: activity_log_bhs_assignment_insert_notification; Type: TRIGGER; Schema: ml_app; Owner: -
--

CREATE TRIGGER activity_log_bhs_assignment_insert_notification AFTER INSERT ON ml_app.activity_log_bhs_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app.activity_log_bhs_assignment_insert_notification();


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
-- Name: fk_activity_log_ipa_assignment_adverse_event_history_activity_l; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_event_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_adverse_event_history_activity_l FOREIGN KEY (activity_log_ipa_assignment_adverse_event_id) REFERENCES ipa_ops.activity_log_ipa_assignment_adverse_events(id);


--
-- Name: fk_activity_log_ipa_assignment_adverse_event_history_ipa_assign; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_event_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_adverse_event_history_ipa_assign FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


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
-- Name: fk_activity_log_ipa_assignment_discussion_history_activity_log_; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_discussion_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_discussion_history_activity_log_ FOREIGN KEY (activity_log_ipa_assignment_discussion_id) REFERENCES ipa_ops.activity_log_ipa_assignment_discussions(id);


--
-- Name: fk_activity_log_ipa_assignment_discussion_history_ipa_assignmen; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_discussion_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_discussion_history_ipa_assignmen FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_activity_log_ipa_assignment_discussion_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_discussion_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_discussion_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_discussion_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_discussion_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_discussion_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_assignment_history_activity_log_ipa_assignm; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_activity_log_ipa_assignm FOREIGN KEY (activity_log_ipa_assignment_id) REFERENCES ipa_ops.activity_log_ipa_assignments(id);


--
-- Name: fk_activity_log_ipa_assignment_history_ipa_assignment_id; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_history_ipa_assignment_id FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


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
-- Name: fk_activity_log_ipa_assignment_inex_checklist_history_ipa_assig; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklist_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_inex_checklist_history_ipa_assig FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


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
-- Name: fk_activity_log_ipa_assignment_med_nav_history_activity_log_ipa; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_med_nav_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_med_nav_history_activity_log_ipa FOREIGN KEY (activity_log_ipa_assignment_med_nav_id) REFERENCES ipa_ops.activity_log_ipa_assignment_med_navs(id);


--
-- Name: fk_activity_log_ipa_assignment_med_nav_history_ipa_assignment_m; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_med_nav_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_med_nav_history_ipa_assignment_m FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_activity_log_ipa_assignment_med_nav_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_med_nav_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_med_nav_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_med_nav_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_med_nav_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_med_nav_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_assignment_minor_deviation_history_activity; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_activity FOREIGN KEY (activity_log_ipa_assignment_minor_deviation_id) REFERENCES ipa_ops.activity_log_ipa_assignment_minor_deviations(id);


--
-- Name: fk_activity_log_ipa_assignment_minor_deviation_history_ipa_assi; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_ipa_assi FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


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
-- Name: fk_activity_log_ipa_assignment_navigation_history_ipa_assignmen; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_navigation_history_ipa_assignmen FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


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
-- Name: fk_activity_log_ipa_assignment_phone_screen_history_ipa_assignm; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screen_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_phone_screen_history_ipa_assignm FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


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
-- Name: fk_activity_log_ipa_assignment_post_visit_history_activity_log_; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_post_visit_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_post_visit_history_activity_log_ FOREIGN KEY (activity_log_ipa_assignment_post_visit_id) REFERENCES ipa_ops.activity_log_ipa_assignment_post_visits(id);


--
-- Name: fk_activity_log_ipa_assignment_post_visit_history_ipa_assignmen; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_post_visit_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_post_visit_history_ipa_assignmen FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_activity_log_ipa_assignment_post_visit_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_post_visit_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_post_visit_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_post_visit_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_post_visit_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_post_visit_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_activity_log_ipa_assignment_protocol_deviation_history_activ; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_protocol_deviation_history_activ FOREIGN KEY (activity_log_ipa_assignment_protocol_deviation_id) REFERENCES ipa_ops.activity_log_ipa_assignment_protocol_deviations(id);


--
-- Name: fk_activity_log_ipa_assignment_protocol_deviation_history_ipa_a; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviation_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_protocol_deviation_history_ipa_a FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


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
-- Name: fk_activity_log_ipa_assignment_summary_history_activity_log_ipa; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_summary_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_summary_history_activity_log_ipa FOREIGN KEY (activity_log_ipa_assignment_summary_id) REFERENCES ipa_ops.activity_log_ipa_assignment_summaries(id);


--
-- Name: fk_activity_log_ipa_assignment_summary_history_ipa_assignment_s; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_summary_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_summary_history_ipa_assignment_s FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_activity_log_ipa_assignment_summary_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_summary_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_summary_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_activity_log_ipa_assignment_summary_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_summary_history
    ADD CONSTRAINT fk_activity_log_ipa_assignment_summary_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_emergency_contact_history_emergency_contacts; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.emergency_contact_history
    ADD CONSTRAINT fk_emergency_contact_history_emergency_contacts FOREIGN KEY (emergency_contact_id) REFERENCES ipa_ops.emergency_contacts(id);


--
-- Name: fk_emergency_contact_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.emergency_contact_history
    ADD CONSTRAINT fk_emergency_contact_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_emergency_contact_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.emergency_contact_history
    ADD CONSTRAINT fk_emergency_contact_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_ipa_assignment_history_ipa_assignments; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_assignment_history
    ADD CONSTRAINT fk_ipa_assignment_history_ipa_assignments FOREIGN KEY (ipa_assignment_table_id) REFERENCES ipa_ops.ipa_assignments(id);


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
-- Name: fk_ipa_exit_interview_history_ipa_exit_interviews; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_exit_interview_history
    ADD CONSTRAINT fk_ipa_exit_interview_history_ipa_exit_interviews FOREIGN KEY (ipa_exit_interview_id) REFERENCES ipa_ops.ipa_exit_interviews(id);


--
-- Name: fk_ipa_exit_interview_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_exit_interview_history
    ADD CONSTRAINT fk_ipa_exit_interview_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_exit_interview_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_exit_interview_history
    ADD CONSTRAINT fk_ipa_exit_interview_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_four_wk_followup_history_ipa_four_wk_followups; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_four_wk_followup_history
    ADD CONSTRAINT fk_ipa_four_wk_followup_history_ipa_four_wk_followups FOREIGN KEY (ipa_four_wk_followup_id) REFERENCES ipa_ops.ipa_four_wk_followups(id);


--
-- Name: fk_ipa_four_wk_followup_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_four_wk_followup_history
    ADD CONSTRAINT fk_ipa_four_wk_followup_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_four_wk_followup_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_four_wk_followup_history
    ADD CONSTRAINT fk_ipa_four_wk_followup_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_ipa_incidental_finding_history_ipa_incidental_findings; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_incidental_finding_history
    ADD CONSTRAINT fk_ipa_incidental_finding_history_ipa_incidental_findings FOREIGN KEY (ipa_incidental_finding_id) REFERENCES ipa_ops.ipa_incidental_findings(id);


--
-- Name: fk_ipa_incidental_finding_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_incidental_finding_history
    ADD CONSTRAINT fk_ipa_incidental_finding_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_incidental_finding_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_incidental_finding_history
    ADD CONSTRAINT fk_ipa_incidental_finding_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_ipa_medical_detail_history_ipa_medical_details; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medical_detail_history
    ADD CONSTRAINT fk_ipa_medical_detail_history_ipa_medical_details FOREIGN KEY (ipa_medical_detail_id) REFERENCES ipa_ops.ipa_medical_details(id);


--
-- Name: fk_ipa_medical_detail_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medical_detail_history
    ADD CONSTRAINT fk_ipa_medical_detail_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_medical_detail_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medical_detail_history
    ADD CONSTRAINT fk_ipa_medical_detail_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_medication_history_ipa_medications; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medication_history
    ADD CONSTRAINT fk_ipa_medication_history_ipa_medications FOREIGN KEY (ipa_medication_id) REFERENCES ipa_ops.ipa_medications(id);


--
-- Name: fk_ipa_medication_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medication_history
    ADD CONSTRAINT fk_ipa_medication_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_medication_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medication_history
    ADD CONSTRAINT fk_ipa_medication_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_mednav_followup_history_ipa_mednav_followups; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_followup_history
    ADD CONSTRAINT fk_ipa_mednav_followup_history_ipa_mednav_followups FOREIGN KEY (ipa_mednav_followup_id) REFERENCES ipa_ops.ipa_mednav_followups(id);


--
-- Name: fk_ipa_mednav_followup_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_followup_history
    ADD CONSTRAINT fk_ipa_mednav_followup_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_mednav_followup_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_followup_history
    ADD CONSTRAINT fk_ipa_mednav_followup_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_mednav_provider_comm_history_ipa_mednav_provider_comms; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_comm_history
    ADD CONSTRAINT fk_ipa_mednav_provider_comm_history_ipa_mednav_provider_comms FOREIGN KEY (ipa_mednav_provider_comm_id) REFERENCES ipa_ops.ipa_mednav_provider_comms(id);


--
-- Name: fk_ipa_mednav_provider_comm_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_comm_history
    ADD CONSTRAINT fk_ipa_mednav_provider_comm_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_mednav_provider_comm_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_comm_history
    ADD CONSTRAINT fk_ipa_mednav_provider_comm_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_mednav_provider_report_history_ipa_mednav_provider_repor; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_report_history
    ADD CONSTRAINT fk_ipa_mednav_provider_report_history_ipa_mednav_provider_repor FOREIGN KEY (ipa_mednav_provider_report_id) REFERENCES ipa_ops.ipa_mednav_provider_reports(id);


--
-- Name: fk_ipa_mednav_provider_report_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_report_history
    ADD CONSTRAINT fk_ipa_mednav_provider_report_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_mednav_provider_report_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_report_history
    ADD CONSTRAINT fk_ipa_mednav_provider_report_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_ipa_protocol_exception_history_ipa_protocol_exceptions; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_exception_history
    ADD CONSTRAINT fk_ipa_protocol_exception_history_ipa_protocol_exceptions FOREIGN KEY (ipa_protocol_exception_id) REFERENCES ipa_ops.ipa_protocol_exceptions(id);


--
-- Name: fk_ipa_protocol_exception_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_exception_history
    ADD CONSTRAINT fk_ipa_protocol_exception_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_protocol_exception_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_exception_history
    ADD CONSTRAINT fk_ipa_protocol_exception_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_ps_comp_review_history_ipa_ps_comp_reviews; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_comp_review_history
    ADD CONSTRAINT fk_ipa_ps_comp_review_history_ipa_ps_comp_reviews FOREIGN KEY (ipa_ps_comp_review_id) REFERENCES ipa_ops.ipa_ps_comp_reviews(id);


--
-- Name: fk_ipa_ps_comp_review_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_comp_review_history
    ADD CONSTRAINT fk_ipa_ps_comp_review_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_ps_comp_review_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_comp_review_history
    ADD CONSTRAINT fk_ipa_ps_comp_review_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_ipa_ps_informant_detail_history_ipa_ps_informant_details; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_informant_detail_history
    ADD CONSTRAINT fk_ipa_ps_informant_detail_history_ipa_ps_informant_details FOREIGN KEY (ipa_ps_informant_detail_id) REFERENCES ipa_ops.ipa_ps_informant_details(id);


--
-- Name: fk_ipa_ps_informant_detail_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_informant_detail_history
    ADD CONSTRAINT fk_ipa_ps_informant_detail_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_ps_informant_detail_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_informant_detail_history
    ADD CONSTRAINT fk_ipa_ps_informant_detail_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_ipa_reimbursement_req_history_ipa_reimbursement_reqs; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_reimbursement_req_history
    ADD CONSTRAINT fk_ipa_reimbursement_req_history_ipa_reimbursement_reqs FOREIGN KEY (ipa_reimbursement_req_id) REFERENCES ipa_ops.ipa_reimbursement_reqs(id);


--
-- Name: fk_ipa_reimbursement_req_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_reimbursement_req_history
    ADD CONSTRAINT fk_ipa_reimbursement_req_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_reimbursement_req_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_reimbursement_req_history
    ADD CONSTRAINT fk_ipa_reimbursement_req_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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
-- Name: fk_ipa_special_consideration_history_ipa_special_considerations; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_special_consideration_history
    ADD CONSTRAINT fk_ipa_special_consideration_history_ipa_special_considerations FOREIGN KEY (ipa_special_consideration_id) REFERENCES ipa_ops.ipa_special_considerations(id);


--
-- Name: fk_ipa_special_consideration_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_special_consideration_history
    ADD CONSTRAINT fk_ipa_special_consideration_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_special_consideration_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_special_consideration_history
    ADD CONSTRAINT fk_ipa_special_consideration_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_ipa_station_contact_history_ipa_station_contacts; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_station_contact_history
    ADD CONSTRAINT fk_ipa_station_contact_history_ipa_station_contacts FOREIGN KEY (ipa_station_contact_id) REFERENCES ipa_ops.ipa_station_contacts(id);


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
-- Name: fk_ipa_two_wk_followup_history_ipa_two_wk_followups; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_two_wk_followup_history
    ADD CONSTRAINT fk_ipa_two_wk_followup_history_ipa_two_wk_followups FOREIGN KEY (ipa_two_wk_followup_id) REFERENCES ipa_ops.ipa_two_wk_followups(id);


--
-- Name: fk_ipa_two_wk_followup_history_masters; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_two_wk_followup_history
    ADD CONSTRAINT fk_ipa_two_wk_followup_history_masters FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_ipa_two_wk_followup_history_users; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_two_wk_followup_history
    ADD CONSTRAINT fk_ipa_two_wk_followup_history_users FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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

ALTER TABLE ONLY ipa_ops.ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_events
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklists
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screens
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_post_visits
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.emergency_contacts
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adverse_events
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_consent_mailings
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_hotels
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_inex_checklists
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_initial_screenings
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_payments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_deviations
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

ALTER TABLE ONLY ipa_ops.ipa_ps_informant_details
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_initial_screenings
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sizes
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_mris
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tmocas
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_screenings
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sleeps
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_surveys
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tms_tests
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_transportations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_withdrawals
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_numbers
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

ALTER TABLE ONLY ipa_ops.ipa_protocol_exceptions
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_med_navs
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_exit_interviews
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_four_wk_followups
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_incidental_findings
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_followups
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_comms
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_reports
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_two_wk_followups
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_comp_reviews
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_reimbursement_reqs
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_summaries
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medical_details
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medications
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_special_considerations
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_discussions
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_numbers
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_events
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklists
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screens
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_post_visits
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.emergency_contacts
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adverse_events
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_appointments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_consent_mailings
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_hotels
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_inex_checklists
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_initial_screenings
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_payments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_deviations
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

ALTER TABLE ONLY ipa_ops.ipa_ps_informant_details
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_initial_screenings
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sizes
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_mris
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tmocas
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_screenings
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_sleeps
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_surveys
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_tms_tests
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_transportations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_withdrawals
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.mrn_numbers
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_adl_informant_screeners
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_protocol_exceptions
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_med_navs
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_exit_interviews
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_four_wk_followups
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_incidental_findings
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_followups
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_comms
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_mednav_provider_reports
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_two_wk_followups
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_ps_comp_reviews
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_reimbursement_reqs
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_summaries
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medical_details
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_medications
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.ipa_special_considerations
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_discussions
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_adverse_events
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_inex_checklists
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_phone_screens
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignments
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_protocol_deviations
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_navigations
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_post_visits
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_minor_deviations
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_med_navs
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_summaries
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


--
-- Name: fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ipa_ops; Owner: -
--

ALTER TABLE ONLY ipa_ops.activity_log_ipa_assignment_discussions
    ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_ops.ipa_assignments(id);


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

ALTER TABLE ONLY ml_app.bhs_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


--
-- Name: fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


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
-- Name: fk_rails_2b59e23148; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_archived_files
    ADD CONSTRAINT fk_rails_2b59e23148 FOREIGN KEY (nfs_store_stored_file_id) REFERENCES ml_app.nfs_store_stored_files(id);


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
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.bhs_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES ml_app.masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.activity_log_bhs_assignments
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
-- Name: fk_rails_bdb308087e; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--

ALTER TABLE ONLY ml_app.nfs_store_uploads
    ADD CONSTRAINT fk_rails_bdb308087e FOREIGN KEY (user_id) REFERENCES ml_app.users(id);


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

SET search_path TO ml_app,ipa_ops;

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

INSERT INTO schema_migrations (version) VALUES ('20181030185123');

INSERT INTO schema_migrations (version) VALUES ('20181108115216');

INSERT INTO schema_migrations (version) VALUES ('20181113143210');

INSERT INTO schema_migrations (version) VALUES ('20181113143327');

INSERT INTO schema_migrations (version) VALUES ('20181113150331');

INSERT INTO schema_migrations (version) VALUES ('20181113150713');

INSERT INTO schema_migrations (version) VALUES ('20181113152652');

INSERT INTO schema_migrations (version) VALUES ('20181113154525');

INSERT INTO schema_migrations (version) VALUES ('20181113154855');

INSERT INTO schema_migrations (version) VALUES ('20181113154920');

INSERT INTO schema_migrations (version) VALUES ('20181113154942');

INSERT INTO schema_migrations (version) VALUES ('20181113165948');

INSERT INTO schema_migrations (version) VALUES ('20181113170144');

INSERT INTO schema_migrations (version) VALUES ('20181113172429');

INSERT INTO schema_migrations (version) VALUES ('20181113175031');

INSERT INTO schema_migrations (version) VALUES ('20181113180608');

INSERT INTO schema_migrations (version) VALUES ('20181113183446');

INSERT INTO schema_migrations (version) VALUES ('20181113184022');

INSERT INTO schema_migrations (version) VALUES ('20181113184516');

INSERT INTO schema_migrations (version) VALUES ('20181113184920');

INSERT INTO schema_migrations (version) VALUES ('20181113185315');

INSERT INTO schema_migrations (version) VALUES ('20181205103333');

INSERT INTO schema_migrations (version) VALUES ('20181206123849');

INSERT INTO schema_migrations (version) VALUES ('20181220131156');

INSERT INTO schema_migrations (version) VALUES ('20181220160047');

INSERT INTO schema_migrations (version) VALUES ('20190130152053');

INSERT INTO schema_migrations (version) VALUES ('20190130152208');

INSERT INTO schema_migrations (version) VALUES ('20190131130024');

INSERT INTO schema_migrations (version) VALUES ('20190201160559');

INSERT INTO schema_migrations (version) VALUES ('20190201160606');

INSERT INTO schema_migrations (version) VALUES ('20190225094021');

INSERT INTO schema_migrations (version) VALUES ('20190226165932');

INSERT INTO schema_migrations (version) VALUES ('20190226165938');

INSERT INTO schema_migrations (version) VALUES ('20190226173917');

INSERT INTO schema_migrations (version) VALUES ('20190312160404');

INSERT INTO schema_migrations (version) VALUES ('20190312163119');

INSERT INTO schema_migrations (version) VALUES ('20190416181222');

INSERT INTO schema_migrations (version) VALUES ('20190502142561');

INSERT INTO schema_migrations (version) VALUES ('20190517135351');

INSERT INTO schema_migrations (version) VALUES ('20190523115611');

INSERT INTO schema_migrations (version) VALUES ('20190528152006');

INSERT INTO schema_migrations (version) VALUES ('20190612140618');

INSERT INTO schema_migrations (version) VALUES ('20190614162317');

INSERT INTO schema_migrations (version) VALUES ('20190624082535');

INSERT INTO schema_migrations (version) VALUES ('20190628131713');

INSERT INTO schema_migrations (version) VALUES ('20190709174613');

INSERT INTO schema_migrations (version) VALUES ('20190709174638');

INSERT INTO schema_migrations (version) VALUES ('20190711074003');

INSERT INTO schema_migrations (version) VALUES ('20190711084434');

INSERT INTO schema_migrations (version) VALUES ('20190902123518');

INSERT INTO schema_migrations (version) VALUES ('20190906172361');

INSERT INTO schema_migrations (version) VALUES ('20191115124723');

INSERT INTO schema_migrations (version) VALUES ('20191115124732');

