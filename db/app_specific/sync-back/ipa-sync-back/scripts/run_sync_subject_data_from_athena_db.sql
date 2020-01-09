BEGIN;

CREATE TEMPORARY TABLE temp_ipa_assignments (
    master_id integer,
    ipa_id integer,
    event varchar,
    record_updated_at timestamp without time zone
);

CREATE TEMP TABLE temp_events AS
SELECT * FROM (
  SELECT distinct
    dt.master_id,
    ipa.ipa_id,
    CASE
      WHEN extra_log_type = 'follow_up_surveys' THEN 'completed'
      WHEN extra_log_type = 'withdraw' THEN 'withdrawn'
      WHEN extra_log_type = 'exit_l2fu' THEN 'lost to follow up'
      WHEN ps_interested1 = 'not interested' OR ps_interested2 = 'not interested' OR ps_still_interested = 'no'
        THEN 'not interest during phone screening'
      WHEN extra_log_type = 'perform_screening_follow_up' AND follow_up_still_interested = 'no'
        THEN 'not interest during screening follow-up'
      WHEN extra_log_type = 'perform_screening_follow_up' AND eligible_for_study_blank_yes_no = 'no'
        THEN 'ineligible'
      -- WHEN extra_log_type = 'perform_screening_follow_up' AND eligible_for_study_blank_yes_no = 'yes'
      --   THEN 'eligible'
      WHEN extra_log_type = 'appointment' THEN 'scheduled'
      WHEN extra_log_type IN ('eligible', 'eligible with study partner', 'not eligible')
        THEN extra_log_type
      WHEN extra_log_type = 'screening_follow_up' THEN 'screened'
      ELSE NULL
    END "event",
    dt.created_at
  FROM (
      SELECT
        al.master_id,
        al.created_at,
        al.extra_log_type,
        ipa_screenings.eligible_for_study_blank_yes_no,
        ipa_screenings.still_interested_blank_yes_no "follow_up_still_interested",
        ipa_ps_initial_screenings.select_is_good_time_to_speak "ps_interested1",
        ipa_ps_initial_screenings.select_may_i_begin "ps_interested2",
        ipa_ps_initial_screenings.select_still_interested "ps_still_interested"
      FROM activity_log_ipa_assignments al
      LEFT JOIN ipa_screenings ON al.master_id = ipa_screenings.master_id
      LEFT JOIN ipa_surveys ON al.master_id = ipa_surveys.master_id
      LEFT JOIN ipa_ps_initial_screenings ON al.master_id = ipa_ps_initial_screenings.master_id
      WHERE
        ipa_ps_initial_screenings.select_is_good_time_to_speak = 'not interested'
        OR ipa_ps_initial_screenings.select_may_i_begin = 'not interested'
        OR ipa_ps_initial_screenings.select_still_interested = 'no'
        OR (
          al.extra_log_type = 'follow_up_surveys'
          AND ipa_surveys.select_survey_type = 'exit survey'
        )
        OR
          al.extra_log_type in ('screening_follow_up', 'perform_screening_follow_up', 'withdraw', 'schedule_screening',  'appointment')

      UNION

      SELECT
        al.master_id,
        al.created_at,
        ipa_inex_checklists.select_subject_eligibility "extra_log_type",
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
      FROM activity_log_ipa_assignment_inex_checklists al
      INNER JOIN ipa_inex_checklists ON al.master_id = ipa_inex_checklists.master_id
      WHERE
        al.extra_log_type =  'sign_phone_screen'
        AND ipa_inex_checklists.fixed_checklist_type = 'phone screen review'

  ) dt
  INNER JOIN ipa_assignments ipa
    ON dt.master_id = ipa.master_id
) e1
WHERE event IS NOT NULL
ORDER by master_id, created_at asc;


INSERT INTO temp_ipa_assignments (SELECT * FROM ml_app.find_new_athena_ipa_records());

SELECT ml_app.lock_transfer_records_with_external_ids_and_events(
  'athena-db',
  'fphs-db',
  (select array_agg(master_id) from temp_ipa_assignments),
  (select array_agg(ipa_id) from temp_ipa_assignments),
  'ipa_assignments',
  (select array_agg(event) from temp_ipa_assignments),
  (select array_agg(record_updated_at) from temp_ipa_assignments)
);


\copy (SELECT * FROM temp_ipa_assignments) TO $ASSIGNMENTS_FILE WITH (format csv, header true);
\copy (SELECT id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source FROM player_infos WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO $PLAYER_INFOS_FILE WITH (format csv, header true);
\copy (SELECT * FROM player_contacts WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO $PLAYER_CONTACTS_FILE WITH (format csv, header true);
\copy (SELECT * FROM addresses WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO $ADDRESSES_FILE WITH (format csv, header true);

\copy (SELECT * FROM temp_events WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments WHERE event IS NOT NULL)) TO $EVENTS_FILE WITH (format csv, header true);

COMMIT;
