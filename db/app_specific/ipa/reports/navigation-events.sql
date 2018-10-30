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
al.arrival_time
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

select
'' "-",
al.event_date "date",
al.start_time "start time",
al.master_id,
al.ipa_id "IPA ID",
al.first_name "first name",
al.last_name "last name",
al.extra_log_type "type",
al.select_status "status",
al.select_station "station",
al.select_event_type "event type",
al.other_event_type "other event type",
al.completion_time "planned or actual completion time",
al.arrival_time "arrival time"

from nav_events al

UNION

SELECT
'week commencing: ',
date_trunc('week', dd)::date,
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
      ( (select min(event_date)::timestamp from nav_events)
      , (select max(event_date)::timestamp from nav_events)
      , '7 day'::interval) dd

order by
"date",
"start time"


;
