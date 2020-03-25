set search_path=ipa_ops, ml_app;

      BEGIN;


      CREATE or REPLACE FUNCTION log_ipa_ps_sleep_update() RETURNS trigger
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
                      form_version,
                      number_of_nights_sleep_apnea_device,
                      sleep_apnea_travel_with_device_yes_no,
                      sleep_apnea_bring_device_yes_no,
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
                      NEW.form_version,
                      NEW.number_of_nights_sleep_apnea_device,
                      NEW.sleep_apnea_travel_with_device_yes_no,
                      NEW.sleep_apnea_bring_device_yes_no,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      ALTER TABLE ipa_ps_sleep_history 
        ADD COLUMN form_version varchar,
        ADD COLUMN number_of_nights_sleep_apnea_device integer,
        ADD COLUMN sleep_apnea_travel_with_device_yes_no varchar,
        ADD COLUMN sleep_apnea_bring_device_yes_no varchar
      ;

      ALTER TABLE ipa_ps_sleeps 
        ADD COLUMN form_version varchar,
        ADD COLUMN number_of_nights_sleep_apnea_device integer,
        ADD COLUMN sleep_apnea_travel_with_device_yes_no varchar,
        ADD COLUMN sleep_apnea_bring_device_yes_no varchar
      ;

      COMMIT;
