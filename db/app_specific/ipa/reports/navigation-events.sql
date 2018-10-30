create temp table nav_events
from activity_log_ipa_assignment_navigations al
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

select
'' "-",
al.event_date,
al.start_time,
pi.master_id,
ipa.ipa_id,
pi.first_name,
pi.last_name,
al.extra_log_type "type",
al.select_status "status",
al.select_station "station",
al.select_event_type "event type",
al.other_event_type "other event type",
al.completion_time,
al.arrival_time

from activity_log_ipa_assignment_navigations al
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


UNION

SELECT
'week commencing: ',
date_trunc('week', dd):: date event_date,
NULL,
NULL,
NULL,
'--------',
'--------',
'--------',
'--------',
'--------',
'--------',
'--------',
NULL,
NULL
FROM generate_series
      ( :from_date::timestamp
      , :to_date::timestamp
      , '7 day'::interval) dd

order by
event_date,
start_time


;
