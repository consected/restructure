set search_path=ipa_ops, ml_app;

      BEGIN;


      CREATE or REPLACE FUNCTION log_ipa_ps_mri_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_ps_mri_history
                  (
                      master_id,
                      form_version,
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
                      select_radiation_type,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_mri_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.form_version,
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
                      NEW.select_radiation_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      ALTER TABLE ipa_ps_mri_history 
      add column form_version varchar,
      add column select_radiation_type varchar
      ;


      ALTER TABLE ipa_ps_mris 
      add column form_version varchar,
      add column select_radiation_type varchar
      ;

      COMMIT;
