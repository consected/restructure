set search_path=sleep, ml_app;

DROP FUNCTION IF EXISTS sleep_ese_question_score_calc() CASCADE;

CREATE OR REPLACE FUNCTION sleep_ese_question_score_calc() RETURNS trigger
LANGUAGE plpgsql
AS $$
  BEGIN

--sitting_and_reading watching_tv public_place car_passenger afternoon_rest sitting_and_talking after_lunch stopped_in_traffic total_score
    NEW.total_score :=
      NEW.sitting_and_reading +
      NEW.watching_tv +
      NEW.public_place +
      NEW.car_passenger +
      NEW.afternoon_rest +
      NEW.sitting_and_talking +
      NEW.after_lunch +
      NEW.stopped_in_traffic
      ;
    RETURN NEW;

  END;
$$;


CREATE TRIGGER sleep_ese_question_score_calc BEFORE INSERT ON sleep_ese_questions FOR EACH ROW EXECUTE PROCEDURE sleep_ese_question_score_calc();
CREATE TRIGGER sleep_ese_question_score_calc_update BEFORE UPDATE ON sleep_ese_questions FOR EACH ROW EXECUTE PROCEDURE sleep_ese_question_score_calc();
