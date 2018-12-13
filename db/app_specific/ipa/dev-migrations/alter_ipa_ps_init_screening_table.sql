set search_path = ml_app, ipa_ops;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_ps_initial_screenings select_is_good_time_to_speak select_may_i_begin any_questions_blank_yes_no select_still_interested follow_up_date follow_up_time notes

      CREATE OR REPLACE FUNCTION log_ipa_ps_initial_screening_update() RETURNS trigger
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

      alter TABLE ipa_ps_initial_screening_history
          add column looked_at_website_yes_no varchar
          ;


      alter TABLE ipa_ps_initial_screenings
        add column looked_at_website_yes_no varchar
        ;
      COMMIT;
