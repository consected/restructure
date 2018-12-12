set search_path = ml_app, ipa_ops;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_ps_tmocas tmoca_score

      CREATE or replace FUNCTION log_ipa_ps_tmoca_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_ps_tmoca_history
                  (
                      master_id,
                      attn_digit_span,
                      attn_digit_vigilance,
                      attn_digit_calculation,
                      language_repeat,
                      language_fluency,
                      abstraction,
                      delayed_recall,
                      orientation,
                      tmoca_score,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_tmoca_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.attn_digit_span,
                      NEW.attn_digit_vigilance,
                      NEW.attn_digit_calculation,
                      NEW.language_repeat,
                      NEW.language_fluency,
                      NEW.abstraction,
                      NEW.delayed_recall,
                      NEW.orientation,
                      NEW.tmoca_score,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      alter TABLE ipa_ps_tmoca_history
        add column attn_digit_span integer,
        add column attn_digit_vigilance integer,
        add column attn_digit_calculation integer,
        add column language_repeat integer,
        add column language_fluency integer,
        add column abstraction integer,
        add column delayed_recall integer,
        add column orientation integer
        ;

      alter TABLE ipa_ps_tmocas
      add column attn_digit_span integer,
      add column attn_digit_vigilance integer,
      add column attn_digit_calculation integer,
      add column language_repeat integer,
      add column language_fluency integer,
      add column abstraction integer,
      add column delayed_recall integer,
      add column orientation integer
        ;

      COMMIT;
