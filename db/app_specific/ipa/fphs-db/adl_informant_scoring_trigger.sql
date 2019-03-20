set search_path=ipa_ops;
-- DROP FUNCTION IF EXISTS adl_screener_score_calc() CASCADE;

CREATE OR REPLACE FUNCTION adl_screener_score_dont_know(init_q NUMERIC, VARIADIC scores NUMERIC[]) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
  DECLARE
    l INTEGER;
    i INTEGER;
    total INTEGER;
  BEGIN

    l := array_upper(scores, 1);

    init_q := COALESCE(init_q, 0)::integer;


    total := 0;
    FOR i in 1 .. l LOOP
      total := total +  COALESCE(scores[i], 0)::integer;
    END LOOP;

    IF init_q = 9 THEN
      RETURN 0;
    ELSE
      RETURN init_q * total;
    END IF;

    END;
$$;

CREATE OR REPLACE FUNCTION adl_screener_one_dk(response NUMERIC) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
  BEGIN
    IF response = 9 THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  END;
$$;

CREATE OR REPLACE FUNCTION adl_screener_score_calc() RETURNS trigger
LANGUAGE plpgsql
AS $$
  DECLARE
    score INTEGER;
    dk INTEGER;
  BEGIN

    score :=
      COALESCE(NEW.adl_eat, 0) +
      COALESCE(NEW.adl_walk, 0) +
      COALESCE(NEW.adl_toilet, 0) +
      COALESCE(NEW.adl_bath, 0) +
      COALESCE(NEW.adl_groom, 0) +
      adl_screener_score_dont_know(NEW.adl_dressa, NEW.adl_dressa_perf, NEW.adl_dressb) +
      adl_screener_score_dont_know(NEW.adl_phone, NEW.adl_phone_perf) +
      adl_screener_score_dont_know(NEW.adl_tv,
        adl_screener_score_dont_know(NEW.adl_tva, 1),
        adl_screener_score_dont_know(NEW.adl_tvb, 1),
        adl_screener_score_dont_know(NEW.adl_tvc, 1)
      ) +
      adl_screener_score_dont_know(NEW.adl_attnconvo, NEW.adl_attnconvo_part) +
      adl_screener_score_dont_know(NEW.adl_dishes, NEW.adl_dishes_perf) +
      adl_screener_score_dont_know(NEW.adl_belong, NEW.adl_belong_perf) +
      adl_screener_score_dont_know(NEW.adl_beverage, NEW.adl_beverage_perf) +
      adl_screener_score_dont_know(NEW.adl_snack, NEW.adl_snack_prep) +
      adl_screener_score_dont_know(NEW.adl_garbage, NEW.adl_garbage_perf) +
      adl_screener_score_dont_know(NEW.adl_travel, NEW.adl_travel_perf) +
      -- Shopping payment is a second yes/no/don't-know response dependent on the top level shopping response
      adl_screener_score_dont_know(NEW.adl_shop,
        NEW.adl_shop_select,
        adl_screener_score_dont_know(NEW.adl_shop_pay, 1)
      ) +
      adl_screener_score_dont_know(NEW.adl_appt, NEW.adl_appt_aware) +
      -- Make the institutionalized question (originally 1=yes, 0=no) return 0=yes, 1=no, allowing
      -- it to simply multiply the result of the following question to return the score or not
      -- If institutionalized, the following score should be 0
      ABS(COALESCE(NEW.institutionalized___1, 0) - 1) *
        adl_screener_score_dont_know(NEW.adl_alone,
          adl_screener_score_dont_know(NEW.adl_alone_15m, 1),
          adl_screener_score_dont_know(NEW.adl_alone_gt1hr, 1),
          adl_screener_score_dont_know(NEW.adl_alone_lt1hr, 1)
        ) +
      adl_screener_score_dont_know(NEW.adl_currev,
        adl_screener_score_dont_know(NEW.adl_currev_tv, 1),
        adl_screener_score_dont_know(NEW.adl_currev_outhome, 1),
        adl_screener_score_dont_know(NEW.adl_currev_inhome, 1)
      ) +
      adl_screener_score_dont_know(NEW.adl_read,
        adl_screener_score_dont_know(NEW.adl_read_lt1hr, 1),
        adl_screener_score_dont_know(NEW.adl_read_gt1hr, 1)
      ) +
      adl_screener_score_dont_know(NEW.adl_write, NEW.adl_write_complex) +
      adl_screener_score_dont_know(NEW.adl_hob, NEW.adl_hob_perf) +
      adl_screener_score_dont_know(NEW.adl_appl, NEW.adl_appl_perf)
    ;

    dk :=
      adl_screener_one_dk(NEW.adl_dressa) +
      adl_screener_one_dk(NEW.adl_phone) +
      adl_screener_one_dk(NEW.adl_tv) +
      adl_screener_score_dont_know(NEW.adl_tv,
        adl_screener_one_dk(NEW.adl_tva),
        adl_screener_one_dk(NEW.adl_tvb),
        adl_screener_one_dk(NEW.adl_tvc)
      ) +

      adl_screener_one_dk(NEW.adl_attnconvo) +
      adl_screener_one_dk(NEW.adl_dishes) +
      adl_screener_one_dk(NEW.adl_belong) +
      adl_screener_one_dk(NEW.adl_beverage) +
      adl_screener_one_dk(NEW.adl_snack) +
      adl_screener_one_dk(NEW.adl_garbage) +
      adl_screener_one_dk(NEW.adl_travel) +
      -- Shopping payment is a second yes/no/don't-know response dependent on the top level shopping response
      adl_screener_one_dk(NEW.adl_shop) +
      adl_screener_score_dont_know(NEW.adl_shop,
        adl_screener_one_dk(NEW.adl_shop_pay)
      )+
      adl_screener_one_dk(NEW.adl_appt) +

      ABS(COALESCE(NEW.institutionalized___1, 0) - 1) *
      (
        adl_screener_one_dk(NEW.adl_alone) +
        adl_screener_score_dont_know(NEW.adl_alone,
          adl_screener_one_dk(NEW.adl_alone_15m),
          adl_screener_one_dk(NEW.adl_alone_gt1hr),
          adl_screener_one_dk(NEW.adl_alone_lt1hr)
        )
      ) +

      adl_screener_one_dk(NEW.adl_currev) +

      adl_screener_score_dont_know(NEW.adl_currev,
        adl_screener_one_dk(NEW.adl_currev_tv),
        adl_screener_one_dk(NEW.adl_currev_outhome),
        adl_screener_one_dk(NEW.adl_currev_inhome)
      ) +

      adl_screener_one_dk(NEW.adl_read) +
      adl_screener_score_dont_know(NEW.adl_read,
        adl_screener_one_dk(NEW.adl_read_lt1hr),
        adl_screener_one_dk(NEW.adl_read_gt1hr)
      ) +

      adl_screener_one_dk(NEW.adl_write) +
      adl_screener_one_dk(NEW.adl_hob) +
      adl_screener_one_dk(NEW.adl_appl)
    ;


    NEW.score := score;
    NEW.dk_count := dk;
    raise notice 'Value: %', NEW.score;

    RETURN NEW;
END;
$$;


CREATE TRIGGER adl_screener_score_trigger BEFORE INSERT ON adl_screener_data FOR EACH ROW EXECUTE PROCEDURE adl_screener_score_calc();
