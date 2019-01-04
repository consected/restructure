set search_path = ml_app, ipa_ops;

      BEGIN;

-- Command line:
-- table_generators/generate.sh create dynamic_models_table ipa_ps_sizes false weight height hat_size shirt_size jacket_size waist_size

      CREATE or REPLACE FUNCTION log_ipa_ps_size_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_ps_size_history
                  (
                      master_id,
                      birth_date,
                      weight,
                      height,
                      hat_size,
                      shirt_size,
                      jacket_size,
                      waist_size,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_size_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.birth_date,
                      NEW.weight,
                      NEW.height,
                      NEW.hat_size,
                      NEW.shirt_size,
                      NEW.jacket_size,
                      NEW.waist_size,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      alter TABLE ipa_ps_size_history
          add column birth_date date
      ;

      alter TABLE ipa_ps_sizes
          add column birth_date date
      ;


      COMMIT;
