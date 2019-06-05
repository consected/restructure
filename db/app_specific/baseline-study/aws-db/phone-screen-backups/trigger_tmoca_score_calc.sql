DROP FUNCTION IF EXISTS ${target_name_us}_ps_tmoca_score_calc() CASCADE;

CREATE OR REPLACE FUNCTION ${target_name_us}_ps_tmoca_score_calc() RETURNS trigger
LANGUAGE plpgsql
AS $$
  BEGIN


    NEW.tmoca_score :=
      NEW.attn_digit_span +
      NEW.attn_digit_vigilance +
      NEW.attn_digit_calculation +
      NEW.language_repeat +
      NEW.language_fluency +
      NEW.abstraction +
      NEW.delayed_recall +
      NEW.orientation;

    RETURN NEW;
    
  END;
$$;


CREATE TRIGGER ${target_name_us}_ps_tmoca_score_calc BEFORE INSERT ON ${target_name_us}_ps_tmocas FOR EACH ROW EXECUTE PROCEDURE ${target_name_us}_ps_tmoca_score_calc();
CREATE TRIGGER ${target_name_us}_ps_tmoca_score_calc_update BEFORE UPDATE ON ${target_name_us}_ps_tmocas FOR EACH ROW EXECUTE PROCEDURE ${target_name_us}_ps_tmoca_score_calc();
