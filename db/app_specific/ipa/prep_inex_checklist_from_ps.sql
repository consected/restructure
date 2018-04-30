/*
Prepare inclusion / exclusion checklist from phone screen

When a phone screen activity log callback record is added that indicates the phone screen is complete, add a new inex record.
Ensure it references the original phone screen dynamic model record.

*/


DROP FUNCTION IF EXISTS activity_log_ipa_assignment_phone_screens_callback_set() CASCADE;

CREATE OR REPLACE FUNCTION activity_log_ipa_assignment_phone_screens_callback_set() RETURNS trigger
LANGUAGE plpgsql
AS $$
    DECLARE
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

  IF NEW.extra_log_type = 'schedule_callback' THEN

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
      ix_not_pro_blank_yes_no,
      ix_age_range_blank_yes_no,
      ix_weight_ok_blank_yes_no,
      ix_no_seizure_blank_yes_no,
      ix_no_device_impl_blank_yes_no,
      ix_no_ferromagnetic_impl_blank_yes_no,
      ix_diagnosed_sleep_apnea_blank_yes_no,
      ix_diagnosed_heart_stroke_or_meds_blank_yes_no,
      ix_chronic_pain_and_meds_blank_yes_no,
      ix_tmoca_score_blank_yes_no,
      ix_no_hemophilia_blank_yes_no,
      ix_raynauds_ok_blank_yes_no,
      ix_mi_ok_blank_yes_no,
      ix_bicycle_ok_blank_yes_no

    )
    VALUES
    (
      NEW.master_id,
      NOW(),
      NOW(),
      NEW.user_id,

      --ix_not_pro_blank_yes_no
      CASE WHEN football_experience.played_in_nfl_blank_yes_no = 'no' THEN 'yes' ELSE 'no' END,

      --ix_age_range_blank_yes_no
      CASE WHEN football_experience.age >= 24
        AND football_experience.age <= 55
        THEN 'yes' ELSE 'no' END,

      --ix_weight_ok_blank_yes_no
      CASE WHEN subject_size.weight <= 450 THEN 'yes' ELSE 'no' END,

      --ix_no_seizure_blank_yes_no
      NULL,

      --ix_no_device_impl_blank_yes_no
      CASE WHEN tms.pacemaker_blank_yes_no_dont_know = 'no' THEN 'yes' ELSE 'no' END,

      --ix_no_ferromagnetic_impl_blank_yes_no
      CASE WHEN tms.metal_blank_yes_no_dont_know = 'no'
        AND mri.metal_implants_blank_yes_no_dont_know = 'no'
        AND mri.metal_jewelry_blank_yes_no = 'no'
        THEN 'yes' ELSE 'no' END,

      --ix_diagnosed_sleep_apnea_blank_yes_no
      CASE WHEN sleep.sleep_disorder_blank_yes_no_dont_know = 'yes' THEN 'yes' ELSE 'no' END,

      --ix_diagnosed_heart_stroke_or_meds_blank_yes_no
      NULL,

      --ix_chronic_pain_and_meds_blank_yes_no
      CASE WHEN health.chronic_pain_blank_yes_no = 'yes'
        AND health.chronic_pain_meds_blank_yes_no_dont_know = 'yes'
        THEN 'yes' ELSE 'no' END,

      --ix_tmoca_score_blank_yes_no
      CASE WHEN tmoca.tmoca_score <= 19 THEN 'yes' ELSE 'no' END,

      --ix_no_hemophilia_blank_yes_no
      CASE WHEN health.hemophilia_blank_yes_no_dont_know = 'yes' THEN 'no'
           WHEN health.hemophilia_blank_yes_no_dont_know = 'no' THEN 'yes'
           ELSE null END,

      --ix_raynauds_ok_blank_yes_no
      CASE WHEN health.raynauds_syndrome_severity_selection = 'moderate' OR
        health.raynauds_syndrome_severity_selection = 'severe'
        THEN 'no'
        ELSE 'yes' END,


      --ix_mi_ok_blank_yes_no
      NULL,

      --ix_bicycle_ok_blank_yes_no
      CASE WHEN health.cycle_blank_yes_no = 'yes' THEN 'yes' ELSE 'no' END

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



CREATE TRIGGER ipa_ps_to_inex AFTER INSERT ON activity_log_ipa_assignment_phone_screens FOR EACH ROW EXECUTE PROCEDURE activity_log_ipa_assignment_phone_screens_callback_set();
