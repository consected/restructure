SELECT * from (
SELECT distinct dt.master_id, ipa.ipa_id,
CASE
WHEN extra_log_type = 'follow_up_surveys' THEN 'completed'
WHEN extra_log_type = 'withdraw' THEN 'withdrawn'
WHEN ps_interested1 = 'not interested' OR ps_interested2 = 'not interested' OR ps_still_interested = 'no'
  THEN 'not interest during phone screening'
WHEN extra_log_type = 'perform_screening_follow_up' AND eligible_for_study_blank_yes_no = 'no'
  THEN 'ineligible'
WHEN extra_log_type = 'perform_screening_follow_up' AND follow_up_still_interested = 'no'
  THEN 'not interest during screening follow-up'
WHEN extra_log_type = 'schedule_screening' THEN 'in process'
ELSE extra_log_type
END "status",
--pi.first_name, pi.last_name ,
dt.created_at "when"
-- , ps_interested1, ps_interested2, ps_still_interested
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
LEFT JOIN ipa_surveys
ON al.master_id = ipa_surveys.master_id
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
  extra_log_type = 'follow_up_surveys'
  AND ipa_surveys.select_survey_type = 'exit survey'
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
INNER JOIN player_infos pi
ON dt.master_id = pi.master_id
INNER JOIN ipa_assignments ipa
  ON dt.master_id = ipa.master_id
WHERE r = 1
) dt2
WHERE status IN(:select_status)
ORDER BY status, "when" desc
;
