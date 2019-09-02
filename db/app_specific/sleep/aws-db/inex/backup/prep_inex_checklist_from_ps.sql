/*
Prepare inclusion / exclusion checklist from phone screen

When a phone screen activity log callback record is added that indicates the phone screen is complete, add a new inex record.
Ensure it references the original phone screen dynamic model record.

*/


DROP FUNCTION IF EXISTS sleep.activity_log_sleep_assignment_phone_screens_callback_set() CASCADE;

CREATE OR REPLACE FUNCTION sleep.activity_log_sleep_assignment_phone_screens_callback_set() RETURNS trigger
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
    FROM sleep_ps_initial_screenings
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;


    -- -- Get the latest football experience record
    -- SELECT *
    -- INTO football_experience
    -- FROM sleep_ps_football_experiences
    -- WHERE master_id = NEW.master_id
    -- ORDER BY id DESC
    -- LIMIT 1;

    -- Get the latest subject size record
    SELECT *,
    extract(YEAR from age(birth_date)) age
    INTO subject_size
    FROM sleep_ps_sizes
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest MRI record
    SELECT *
    INTO mri
    FROM sleep_ps_mris
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest TMS record
    SELECT *
    INTO tms
    FROM sleep_ps_tms_tests
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest sleep record
    SELECT *
    INTO sleep
    FROM sleep_ps_sleeps
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest health record
    SELECT *
    INTO health
    FROM sleep_ps_healths
    WHERE master_id = NEW.master_id
    ORDER BY id DESC
    LIMIT 1;

    -- Get the latest tmoca record
    SELECT *
    INTO tmoca
    FROM sleep_ps_tmocas
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


    INSERT INTO sleep_inex_checklists
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

    INSERT INTO activity_log_sleep_assignment_inex_checklists
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

    INSERT INTO activity_log_sleep_assignment_inex_checklists
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



CREATE TRIGGER sleep_ps_to_inex AFTER INSERT ON sleep.activity_log_sleep_assignment_phone_screens FOR EACH ROW EXECUTE PROCEDURE activity_log_sleep_assignment_phone_screens_callback_set();
