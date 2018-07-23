set search_path=ml_app;

CREATE TEMPORARY TABLE temp_ipa_assignments_results (
    master_id integer,
    ipa_id bigint,
    status varchar,
    to_master_id integer
);

\copy temp_ipa_assignments_results (master_id, ipa_id, status, to_master_id) from $IPA_ASSIGNMENTS_RESULTS_FILE with (header true, format csv)

UPDATE sync_statuses
SET
  select_status = t.status,
  to_master_id=t.to_master_id
FROM (
  SELECT * FROM temp_ipa_assignments_results
) AS t
WHERE
  from_master_id = t.master_id
  AND from_db = 'fphs-db'
  AND to_db = 'athena-db'
  AND select_status = 'new';
