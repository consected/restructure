set search_path=ipa_ops, ml_app;

      BEGIN;


      CREATE or REPLACE FUNCTION log_ipa_special_consideration_update() RETURNS trigger
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
                      same_hotel_yes_no,
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
                      NEW.same_hotel_yes_no,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      ALTER TABLE ipa_special_consideration_history 
        add column same_hotel_yes_no varchar
      ;
      ALTER TABLE ipa_special_considerations
               add column same_hotel_yes_no varchar
        ;

      COMMIT;
