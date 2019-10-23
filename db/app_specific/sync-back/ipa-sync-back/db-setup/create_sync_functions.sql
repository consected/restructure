SET search_path=ml_app;
-------------------------------------------------------
-- Find the IPA IDs, event that
-- are not null (an IPA ID is necessary)
-- don't have a sync_statuses record (no attempt to sync has already been made) or
-- a sync_statuses record is not marked as 'completed' or 'already transferred', and was created over 2 hours ago (allowing failed items to be retried)
--
CREATE OR REPLACE FUNCTION find_new_athena_ipa_records(event_name VARCHAR) RETURNS TABLE (
  master_id integer,
  ipa_id bigint,
  event varchar
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
    SELECT distinct m.id, ipa.ipa_id, al.extra_log_type
    FROM masters m
    INNER JOIN ipa_ops.ipa_assignments ipa
      ON m.id = ipa.master_id
    INNER JOIN ipa_ops.activity_log_ipa_assignments al
      ON m.id = al.master_id
      AND al.extra_log_type = event_name
    LEFT JOIN sync_statuses s
      ON from_db = 'athena-db'
      AND to_db = 'fphs-db'
      AND m.id = s.from_master_id
      AND ipa.ipa_id::varchar = s.external_id
      AND s.external_type = 'ipa_assignments'
      AND s.event = event_name
    WHERE
      (
        s.id IS NULL
        OR coalesce(s.select_status, '') NOT IN ('completed', 'already transferred')
        AND s.created_at < now() - interval '2 hours'
      )
    ;
END;
$$;

-- Add records to sync_statuses that indicate specific master IDs are in the process of being sync'd
CREATE OR REPLACE FUNCTION lock_transfer_records_with_external_ids(from_db VARCHAR, to_db VARCHAR, master_ids INTEGER[], external_ids INTEGER[], external_type VARCHAR, event VARCHAR) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT into sync_statuses
  ( from_master_id, external_id, external_type, from_db, to_db, event, select_status, created_at, updated_at )
  (
    SELECT unnest(master_ids), unnest(external_ids), external_type, from_db, to_db, event, 'new', now(), now()
  );

  RETURN 1;

END;
$$;
