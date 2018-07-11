DROP FUNCTION IF EXISTS activity_log_ipa_assignment_perform_screening_callback() CASCADE;

CREATE OR REPLACE FUNCTION activity_log_ipa_assignment_perform_screening_callback() RETURNS trigger
LANGUAGE plpgsql
AS $$
  DECLARE
    res RECORD;
    prev_sched RECORD;
    act_id INTEGER;
  BEGIN

  -- Get the references dynamic model record data
  SELECT *
  INTO res
  FROM model_references mr
  INNER JOIN ipa_screenings psis ON psis.id = mr.to_record_id
  INNER JOIN activity_log_ipa_assignments al ON al.id = mr.from_record_id
  WHERE mr.id=NEW.id;


  IF res.extra_log_type = 'perform_screening_follow_up' THEN

    -- If a follow up was set, generate a new record in the IPA tracker log
    IF res.good_time_to_speak_blank_yes_no = 'no' THEN

      -- Get the previous schedule, so we can reuse caller and phone number
      SELECT * FROM activity_log_ipa_assignments
      INTO prev_sched
      WHERE
      master_id = res.master_id
      AND extra_log_type = 'schedule_screening'
      ORDER BY id DESC
      LIMIT 1;


      INSERT INTO activity_log_ipa_assignments (
        extra_log_type,
        master_id,
        user_id,
        created_at,
        updated_at,
        activity_date,
        select_record_from_player_contacts,
        select_who,
        follow_up_when,
        follow_up_time,
        notes
      )
      VALUES (
        'schedule_screening',
        res.master_id,
        res.user_id,
        now(),
        now(),
        now(),
        prev_sched.select_record_from_player_contacts,
        prev_sched.select_who,
        res.callback_date,
        res.callback_time,
        'Participant requested a call back during the when performing a scheduled screening follow up'
      )
      RETURNING id INTO act_id
      ;

    END IF;


  END IF;

  RETURN NEW;
END;
$$;


CREATE TRIGGER ipa_perform_screening_callback AFTER INSERT ON model_references FOR EACH ROW EXECUTE PROCEDURE activity_log_ipa_assignment_perform_screening_callback();
