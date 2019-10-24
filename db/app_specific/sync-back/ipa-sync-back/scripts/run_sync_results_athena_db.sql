set search_path=ml_app;

CREATE TEMPORARY TABLE temp_ipa_assignments_results (
    master_id integer,
    ipa_id bigint,
    status varchar,
    to_master_id integer,
    event varchar
);

\copy temp_ipa_assignments_results (master_id, ipa_id, status, to_master_id, event) from $IPA_ASSIGNMENTS_RESULTS_FILE with (header true, format csv)

-- UPDATE sync_statuses
-- SET
--   select_status = t.status,
--   to_master_id=t.to_master_id,
--   external_id=t.ipa_id::varchar,
--   external_type='ipa_assignments',
--   updated_at = now()
-- FROM (
--   SELECT * FROM temp_ipa_assignments_results
-- ) AS t
-- WHERE
--   from_master_id = t.master_id
--   AND from_db = 'fphs-db'
--   AND to_db = 'athena-db'
--   AND coalesce(select_status, '') NOT IN ('completed', 'already transferred');
-- Add records to sync_statuses that indicate specific master IDs are in the process of being sync'd
select update_transfer_record_results('athena-db', 'fphs-db', 'ipa_assignments') RETURNS INTEGER
