set search_path=ml_app, ipa_ops;


create or replace view ipa_ops.ipa_participant_exits
as
SELECT * from (
SELECT distinct dt.master_id, ipa.ipa_id,
CASE
WHEN extra_log_type = 'completed' THEN 'completed'
WHEN extra_log_type = 'withdraw' THEN 'withdrawn'
WHEN ps_interested1 = 'not interested' OR ps_interested2 = 'not interested' OR ps_still_interested = 'no'
  THEN 'not interest during phone screening'
WHEN extra_log_type = 'perform_screening_follow_up' AND eligible_for_study_blank_yes_no = 'no'
  THEN 'ineligible'
WHEN extra_log_type = 'perform_screening_follow_up' AND follow_up_still_interested = 'no'
  THEN 'not interest during screening follow-up'
WHEN extra_log_type = 'schedule_screening' THEN 'in process'
WHEN extra_log_type = 'exit_opt_out' THEN 'opted out'
WHEN extra_log_type = 'exit_opt_out_covid19' THEN 'exit (no COVID-19 test)'
WHEN extra_log_type = 'exit_l2fu' THEN 'lost to follow-up (before scheduling)'
ELSE extra_log_type
END "status",
dt.created_at "when"
FROM
(
SELECT
al.master_id, al.created_at, al.extra_log_type,
ipa_screenings.eligible_for_study_blank_yes_no, ipa_screenings.still_interested_blank_yes_no "follow_up_still_interested",
ipa_ps_initial_screenings.select_is_good_time_to_speak "ps_interested1",
ipa_ps_initial_screenings.select_may_i_begin "ps_interested2",
ipa_ps_initial_screenings.select_still_interested "ps_still_interested",
rank()
 OVER (
  PARTITION BY al.master_id
  ORDER BY al.created_at DESC
 ) AS r

FROM activity_log_ipa_assignments al
LEFT JOIN ipa_screenings
ON al.master_id = ipa_screenings.master_id
-- LEFT JOIN ipa_surveys
-- ON al.master_id = ipa_surveys.master_id
LEFT JOIN ipa_ps_initial_screenings
ON al.master_id = ipa_ps_initial_screenings.master_id
WHERE
(
(
  ipa_ps_initial_screenings.select_is_good_time_to_speak = 'not interested'
  OR ipa_ps_initial_screenings.select_may_i_begin = 'not interested'
  OR ipa_ps_initial_screenings.select_still_interested = 'no'
)
OR
(
  extra_log_type = 'perform_screening_follow_up'
  AND (
    ipa_screenings.eligible_for_study_blank_yes_no = 'no'
    OR ipa_screenings.still_interested_blank_yes_no = 'no'
  )
)
OR
(
  extra_log_type IN ('completed', 'exit_opt_out', 'exit_l2fu', 'exit_opt_out_covid19')
)
OR
(
  extra_log_type = 'withdraw'
)
OR
(
  extra_log_type = 'schedule_screening'
)
)
) dt
INNER JOIN ipa_assignments ipa
  ON dt.master_id = ipa.master_id
WHERE r = 1
) dt2
ORDER BY status, "when" desc
;
