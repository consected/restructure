BEGIN;

CREATE TEMPORARY TABLE temp_ipa_assignments (
    master_id integer,
    ipa_id integer,
    event varchar
);

CREATE TEMP TABLE temp_events AS
SELECT distinct
  dt.master_id,
  ipa.ipa_id,
  CASE
    WHEN extra_log_type = 'follow_up_surveys' THEN 'completed'
    WHEN extra_log_type = 'withdraw' THEN 'withdrawn'
    WHEN ps_interested1 = 'not interested' OR ps_interested2 = 'not interested' OR ps_still_interested = 'no'
      THEN 'not interest during phone screening'
    WHEN extra_log_type = 'perform_screening_follow_up' AND follow_up_still_interested = 'no'
      THEN 'not interest during screening follow-up'
    WHEN extra_log_type = 'perform_screening_follow_up' AND eligible_for_study_blank_yes_no = 'no'
      THEN 'ineligible'
    WHEN extra_log_type = 'perform_screening_follow_up' AND eligible_for_study_blank_yes_no = 'yes'
      THEN 'eligible'
    WHEN extra_log_type = 'appointment' THEN 'enrolled'
    WHEN extra_log_type = 'schedule_screening' THEN 'in process'
    WHEN ps_finalized = 'finalized' THEN 'screened'
    ELSE extra_log_type
  END "event",
  dt.created_at
FROM (
    SELECT
      al.master_id,
      CASE WHEN activity_log_ipa_assignment_phone_screens.extra_log_type = 'finalize' THEN activity_log_ipa_assignment_phone_screens.created_at
        ELSE al.created_at
      END "created_at",
      al.extra_log_type,
      ipa_screenings.eligible_for_study_blank_yes_no, ipa_screenings.still_interested_blank_yes_no "follow_up_still_interested",
      ipa_ps_initial_screenings.select_is_good_time_to_speak "ps_interested1",
      ipa_ps_initial_screenings.select_may_i_begin "ps_interested2",
      ipa_ps_initial_screenings.select_still_interested "ps_still_interested",
      activity_log_ipa_assignment_phone_screens.extra_log_type "ps_finalized"
    FROM activity_log_ipa_assignments al
    LEFT JOIN ipa_screenings ON al.master_id = ipa_screenings.master_id
    LEFT JOIN ipa_surveys ON al.master_id = ipa_surveys.master_id
    LEFT JOIN ipa_ps_initial_screenings ON al.master_id = ipa_ps_initial_screenings.master_id
    LEFT JOIN activity_log_ipa_assignment_phone_screens ON al.master_id = activity_log_ipa_assignment_phone_screens.master_id AND activity_log_ipa_assignment_phone_screens.extra_log_type = 'finalize'
    WHERE
      ipa_ps_initial_screenings.select_is_good_time_to_speak = 'not interested'
      OR ipa_ps_initial_screenings.select_may_i_begin = 'not interested'
      OR ipa_ps_initial_screenings.select_still_interested = 'no'
      OR activity_log_ipa_assignment_phone_screens.extra_log_type = 'finalize'
      OR (
        al.extra_log_type = 'follow_up_surveys'
        AND ipa_surveys.select_survey_type = 'exit survey'
      )
      OR
        al.extra_log_type in ('perform_screening_follow_up', 'withdraw', 'schedule_screening',  'appointment')
) dt
INNER JOIN ipa_assignments ipa
  ON dt.master_id = ipa.master_id
ORDER by dt.master_id, dt.created_at desc;


INSERT INTO temp_ipa_assignments (SELECT * FROM ml_app.find_new_athena_ipa_records());

SELECT ml_app.lock_transfer_records_with_external_ids_and_events(
  'athena-db',
  'fphs-db',
  (select array_agg(master_id) from temp_ipa_assignments),
  (select array_agg(ipa_id) from temp_ipa_assignments),
  'ipa_assignments',
  (select array_agg(event) from temp_ipa_assignments)
);


\copy (SELECT * FROM temp_ipa_assignments) TO $ASSIGNMENTS_FILE WITH (format csv, header true);
\copy (SELECT id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source FROM player_infos WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO $PLAYER_INFOS_FILE WITH (format csv, header true);
\copy (SELECT * FROM player_contacts WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO $PLAYER_CONTACTS_FILE WITH (format csv, header true);
\copy (SELECT * FROM addresses WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO $ADDRESSES_FILE WITH (format csv, header true);

\copy (SELECT * FROM temp_events WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments WHERE event IS NOT NULL)) TO $EVENTS_FILE WITH (format csv, header true);

COMMIT;
