DROP FUNCTION IF EXISTS activity_log_ipa_assignment_ps_follow_up() CASCADE;

CREATE OR REPLACE FUNCTION activity_log_ipa_assignment_ps_follow_up() RETURNS trigger
LANGUAGE plpgsql
AS $$
  DECLARE
    res RECORD;
    prev_sched RECORD;
    act_id INTEGER;
  BEGIN

  res := NEW;

  IF res.extra_log_type = 'schedule_callback' THEN

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
      'screening_follow_up',
      res.master_id,
      res.user_id,
      now(),
      now(),
      now(),
      prev_sched.select_record_from_player_contacts,
      prev_sched.select_who,
      res.callback_date,
      res.callback_time,
      'Participant phone screening completed. Follow up scheduled.'
    )
    RETURNING id INTO act_id
    ;


  END IF;

  RETURN NEW;
END;
$$;


CREATE TRIGGER ipa_ps_ps_follow_up AFTER INSERT ON activity_log_ipa_assignment_phone_screens FOR EACH ROW EXECUTE PROCEDURE activity_log_ipa_assignment_ps_follow_up();
