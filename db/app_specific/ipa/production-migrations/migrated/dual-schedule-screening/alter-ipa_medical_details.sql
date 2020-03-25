set search_path=ipa_ops, ml_app;


      BEGIN;


      CREATE or REPLACE FUNCTION log_ipa_medical_detail_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_medical_detail_history
                  (
                      master_id,
                      form_version,
                      convulsion_or_seizure_blank_yes_no_dont_know,
                      convulsion_or_seizure_details,
                      sleep_disorder_blank_yes_no_dont_know,
                      sleep_disorder_details,
                      sleep_apnea_device_no_yes,
                      sleep_apnea_device_details,
                      number_of_nights_sleep_apnea_device,
                      sleep_apnea_travel_with_device_yes_no,
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
                      radiation_blank_yes_no,
                      select_radiation_type,
                      radiation_details,
                      dietary_restrictions_blank_yes_no_dont_know,
                      dietary_restrictions_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_medical_detail_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.form_version,
                      NEW.convulsion_or_seizure_blank_yes_no_dont_know,
                      NEW.convulsion_or_seizure_details,
                      NEW.sleep_disorder_blank_yes_no_dont_know,
                      NEW.sleep_disorder_details,
                      NEW.sleep_apnea_device_no_yes,
                      NEW.sleep_apnea_device_details,
                      NEW.number_of_nights_sleep_apnea_device,
                      NEW.sleep_apnea_travel_with_device_yes_no,
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
                      NEW.radiation_blank_yes_no,
                      NEW.select_radiation_type,
                      NEW.radiation_details,
                      NEW.dietary_restrictions_blank_yes_no_dont_know,
                      NEW.dietary_restrictions_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      ALTER TABLE ipa_medical_detail_history 
        add column form_version varchar,
        add column number_of_nights_sleep_apnea_device integer,
        add column sleep_apnea_travel_with_device_yes_no varchar,
        add column select_radiation_type varchar
      ;


      ALTER TABLE ipa_medical_details 
        add column form_version varchar,
        add column number_of_nights_sleep_apnea_device integer,
        add column sleep_apnea_travel_with_device_yes_no varchar,
        add column select_radiation_type varchar
      ;


    COMMIT;
