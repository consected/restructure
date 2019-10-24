set search_path=ml_app;

CREATE TEMPORARY TABLE temp_sleep_assignments_results (
    master_id integer,
    sleep_id bigint,
    status varchar,
    to_master_id integer
);

\copy temp_sleep_assignments_results (master_id, sleep_id, status, to_master_id) from $SLEEP_ASSIGNMENTS_RESULTS_FILE with (header true, format csv)

UPDATE sync_statuses
SET
  select_status = t.status,
  to_master_id=t.to_master_id,
  updated_at = now()
FROM (
  SELECT * FROM temp_sleep_assignments_results
) AS t
WHERE
  from_master_id = t.master_id
  AND from_db = 'fphs-db'
  AND to_db = 'athena-db'
  AND external_id = t.sleep_id::varchar
  AND external_type = 'sleep_assignments'
  AND coalesce(select_status, '') NOT IN ('completed', 'already transferred');
