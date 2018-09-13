set search_path=ml_app;
CREATE TEMPORARY TABLE temp_{{app_name}}_assignments_results (
    master_id integer,
    {{app_name}}_id bigint,
    status varchar,
    to_master_id integer
);

\copy temp_{{app_name}}_assignments_results (master_id, {{app_name}}_id, status, to_master_id) from ${{app_name_uc}}_ASSIGNMENTS_RESULTS_FILE with (header true, format csv)

UPDATE sync_statuses
SET
  select_status = t.status,
  to_master_id=t.to_master_id,
  updated_at = now()
FROM (
  SELECT * FROM temp_{{app_name}}_assignments_results
) AS t
WHERE
  from_master_id = t.master_id
  AND from_db = 'fphs-db'
  AND to_db = 'athena-db'
  AND coalesce(select_status, '') NOT IN ('completed', 'already transferred');
