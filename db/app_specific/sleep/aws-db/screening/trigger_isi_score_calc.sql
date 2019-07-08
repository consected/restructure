set search_path=sleep, ml_app;

DROP FUNCTION IF EXISTS sleep_isi_question_score_calc() CASCADE;

CREATE OR REPLACE FUNCTION sleep_isi_question_score_calc() RETURNS trigger
LANGUAGE plpgsql
AS $$
  BEGIN

--falling_asleep staying_asleep waking_too_early satisfaction_with_pattern noticeable_to_others worried_distressed interferes_with_daily_function total_score
    NEW.total_score :=
      NEW.falling_asleep +
      NEW.staying_asleep +
      NEW.waking_too_early +
      NEW.satisfaction_with_pattern +
      NEW.noticeable_to_others +
      NEW.worried_distressed +
      NEW.interferes_with_daily_function;
    RETURN NEW;

  END;
$$;


CREATE TRIGGER sleep_isi_question_score_calc BEFORE INSERT ON sleep_isi_questions FOR EACH ROW EXECUTE PROCEDURE sleep_isi_question_score_calc();
CREATE TRIGGER sleep_isi_question_score_calc_update BEFORE UPDATE ON sleep_isi_questions FOR EACH ROW EXECUTE PROCEDURE sleep_isi_question_score_calc();
