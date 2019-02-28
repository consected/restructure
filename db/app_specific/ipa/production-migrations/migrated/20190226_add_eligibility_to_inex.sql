SET search_path=ipa_ops, ml_app;

    BEGIN;


    CREATE OR REPLACE FUNCTION ipa_ops.log_ipa_inex_checklist_update()
     RETURNS trigger
     LANGUAGE plpgsql
      AS $function$
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
    $function$;


      ALTER TABLE ipa_inex_checklist_history
      ADD COLUMN select_subject_eligibility varchar
      ;
      ALTER TABLE ipa_inex_checklists
      ADD COLUMN select_subject_eligibility varchar
      ;


      COMMIT;
