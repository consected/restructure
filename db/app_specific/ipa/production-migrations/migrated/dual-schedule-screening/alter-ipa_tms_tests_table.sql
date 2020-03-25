set search_path=ipa_ops, ml_app;

      BEGIN;


        CREATE or replace FUNCTION log_ipa_ps_tms_test_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_ps_tms_test_history
                  (
                      master_id,
                      form_version,
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
                      tobacco_smoker_blank_yes_no, 
                      tobacco_smoker_details, 
                      healthcare_anxiety_blank_yes_no, 
                      healthcare_anxiety_details,
                      anything_else_blank_yes_no,
                      anything_else_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_tms_test_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.form_version,
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
                      NEW.tobacco_smoker_blank_yes_no, 
                      NEW.tobacco_smoker_details, 
                      NEW.healthcare_anxiety_blank_yes_no, 
                      NEW.healthcare_anxiety_details,                      
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

      ALTER TABLE ipa_ps_tms_test_history
        add column form_version varchar,
        add column tobacco_smoker_blank_yes_no varchar,
        add column tobacco_smoker_details varchar,
        add column healthcare_anxiety_blank_yes_no varchar, 
        add column healthcare_anxiety_details varchar
        ;
         
      ALTER TABLE ipa_ps_tms_tests 
        add column form_version varchar,
        add column tobacco_smoker_blank_yes_no varchar,
        add column tobacco_smoker_details varchar,
        add column healthcare_anxiety_blank_yes_no varchar, 
        add column healthcare_anxiety_details varchar
      ;
          
      COMMIT;
