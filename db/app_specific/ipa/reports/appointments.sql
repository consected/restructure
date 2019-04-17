create temp table nav_events
as select
'' "-",
al.event_date,
al.start_time,
pi.master_id,
ipa.ipa_id,
pi.first_name,
pi.last_name,
al.extra_log_type,
al.select_status,
al.select_station,
al.select_event_type,
al.other_event_type,
al.completion_time,
al.arrival_time,
al.select_navigator,
al.select_pi,
al.location
from
activity_log_ipa_assignment_navigations al
inner join player_infos pi
on pi.master_id = al.master_id
inner join ipa_assignments ipa
on ipa.master_id = al.master_id

where
(:from_date IS NULL or event_date >= :from_date)
AND (:to_date IS NULL or event_date <= :to_date)
AND ((:type) IS NULL or extra_log_type in (:type))
AND ((:confirmed) IS NULL or select_status in (:confirmed))
AND ((:station) IS NULL or select_station in (:station))
AND (:ipa_id IS NULL or ipa.ipa_id = :ipa_id)
;


create temp table appointments
as select
visit_start_date,
ap.master_id,
ipa.ipa_id,
pi.first_name,
pi.last_name,
max(ap.id) appointment_id
from ipa_appointments ap
inner join activity_log_ipa_assignments al
on al.master_id = ap.master_id

inner join player_infos pi
on ap.master_id = pi.master_id

inner join ipa_assignments ipa
on ipa.master_id = al.master_id


where
  visit_start_date IS NOT NULL
  AND (:from_date IS NULL or visit_start_date >= :from_date)
  AND (:to_date IS NULL or visit_start_date <= :to_date)
  AND (:ipa_id IS NULL or ipa.ipa_id = :ipa_id)
GROUP BY
ap.master_id, visit_start_date, pi.first_name, pi.last_name, ipa.ipa_id
;

create temp table scheduled_calls
as select
  dt.follow_up_when,
  dt.follow_up_time,
  dt.master_id,
  ipa.ipa_id,
  p.first_name,
  p.last_name,
  dt.extra_log_type,
  dt.select_who
from
  (
    select a.master_id,
      a.extra_log_type,
      a.select_who,
      a.follow_up_when,
      a.follow_up_time,
      a.notes,
      rank()
    OVER (
      PARTITION BY a.master_id, a.extra_log_type
      ORDER BY a.created_at DESC
    ) AS r

    from activity_log_ipa_assignments a
    where
      follow_up_when is not null
      AND (:from_date IS NULL OR follow_up_when >= :from_date)
      AND (:to_date IS NULL OR follow_up_when <= :to_date )
  ) dt
inner join player_infos p
  on dt.master_id = p.master_id

inner join ipa_assignments ipa
  on dt.master_id = ipa.master_id

WHERE r = 1
AND (:ipa_id IS NULL or ipa.ipa_id = :ipa_id)
;

create temp table all_dates
as
select event_date from nav_events
union
select follow_up_when from scheduled_calls
union
select visit_start_date from appointments
;

SELECT
  al.event_date "date",
  al.start_time "start time",
  'assessment event' "-",
  al.extra_log_type "type",
  select_navigator "assigned to nav",
  select_pi "assigned to pi",
  al.master_id,
  al.ipa_id "IPA ID",
  al.first_name "first name",
  al.last_name "last name",
  al.select_status "status",
  al.select_station "station",
  al.select_event_type "event type",
  al.other_event_type "other event type",
  al.location,
  al.completion_time "planned or actual completion time",
  al.arrival_time "arrival time"

FROM nav_events al

UNION

SELECT
  date_trunc('week', dd)::date,
  NULL,
  '          ',
  '          ',
  '          ',
  NULL,
  NULL,
  NULL,
  '          ',
  '          ',
  '          ',
  '          ',
  '          ',
  '          ',
  NULL,
  NULL,
  NULL
FROM generate_series
      ( (select min(event_date)::timestamp from all_dates)
      , (select max(event_date)::timestamp from all_dates)
      , '7 day'::interval) dd

UNION

SELECT
  visit_start_date event_date,
  NULL,
  'appointment start',
  '',
  '' "assigned to nav",
  '' "assigned to pi",
  master_id,
  ipa_id,
  first_name,
  last_name,
  '',
  '',
  '',
  '',
  NULL,
  NULL,
  NULL
FROM appointments

UNION

SELECT
  follow_up_when,
  follow_up_time,
  'scheduled call' "-",
  extra_log_type,
  select_who "assigned to nav",
  '' "assigned to pi",
  master_id,
  ipa_id,
  first_name,
  last_name,
  '',
  '',
  '',
  '',
  NULL,
  NULL,
  NULL
FROM scheduled_calls


order by
"date",
"start time"
;
