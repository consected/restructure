set search_path=bulk_msg,ml_app;

  BEGIN;

    CREATE or REPLACE FUNCTION log_player_contact_phone_info_update() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
          BEGIN
              INSERT INTO player_contact_phone_info_history
              (
                  master_id,
                  player_contact_id,
                  carrier,
                  city,
                  cleansed_phone_number_e164,
                  cleansed_phone_number_national,
                  country,
                  country_code_iso_2,
                  country_code_numeric,
                  county,
                  original_country_code_iso_2,
                  original_phone_number,
                  phone_type,
                  phone_type_code,
                  timezone,
                  zip_code,
                  opted_out_at,
                  user_id,
                  created_at,
                  updated_at,
                  player_contact_phone_info_id
                  )
              SELECT
                  NEW.master_id,
                  NEW.player_contact_id,
                  NEW.carrier,
                  NEW.city,
                  NEW.cleansed_phone_number_e164,
                  NEW.cleansed_phone_number_national,
                  NEW.country,
                  NEW.country_code_iso_2,
                  NEW.country_code_numeric,
                  NEW.county,
                  NEW.original_country_code_iso_2,
                  NEW.original_phone_number,
                  NEW.phone_type,
                  NEW.phone_type_code,
                  NEW.timezone,
                  NEW.zip_code,
                  NEW.opted_out_at,
                  NEW.user_id,
                  NEW.created_at,
                  NEW.updated_at,
                  NEW.id
              ;
              RETURN NEW;
          END;
      $$;


      ALTER TABLE player_contact_phone_info_history
      add column opted_out_at timestamp without time zone;

      ALTER TABLE player_contact_phone_infos
      add column opted_out_at timestamp without time zone;


commit;
