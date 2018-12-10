DROP FUNCTION IF EXISTS activity_log_ipa_assignment_new_ps_schedule() CASCADE;

CREATE OR REPLACE FUNCTION activity_log_ipa_assignment_new_ps_schedule() RETURNS trigger
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
  INNER JOIN ipa_ps_initial_screenings psis ON psis.id = mr.to_record_id
  INNER JOIN activity_log_ipa_assignment_phone_screens alps ON alps.id = mr.from_record_id
  WHERE mr.id=NEW.id;


  IF res.extra_log_type = 'start_phone_screen' THEN

    -- If a follow up was set, generate a new record in the IPA tracker log
    IF res.select_is_good_time_to_speak = 'not appropriate time'
      OR res.select_is_good_time_to_speak = 'left voicemail'
      OR res.select_may_i_begin = 'not appropriate time'
      OR res.select_still_interested = 'yes - call back' THEN

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
        res.follow_up_date,
        res.follow_up_time,
        'Participant requested a call back during the initial stages of phone screening'
      )
      RETURNING id INTO act_id
      ;

    END IF;


  END IF;

  RETURN NEW;
END;
$$;


CREATE TRIGGER ipa_ps_new_ps_schedule AFTER INSERT ON model_references FOR EACH ROW EXECUTE PROCEDURE activity_log_ipa_assignment_new_ps_schedule();
