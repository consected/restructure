SET search_path=ml_app;
-------------------------------------------------------
-- Find the Sleep IDs that
-- are not null (Sleep ID is necessary)
-- have Sleep "Opt In" tracker history record (the user has requested the sync)
-- don't have a sync_statuses record (no attempt to sync has already been made) or
-- a sync_statuses record is not marked as 'completed' or 'already transferred', and was created over 2 hours ago (allowing failed items to be retried)
-- master ids in the source database can be
CREATE OR REPLACE FUNCTION find_new_local_sleep_records(sel_sub_process_id INTEGER) RETURNS TABLE (
  master_id integer,
  sleep_id bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
    SELECT distinct m.id, sleep.sleep_id
    FROM masters m
    INNER JOIN sleep_assignments sleep
      ON m.id = sleep.master_id
    INNER JOIN tracker_history th
      ON m.id = th.master_id
    LEFT JOIN sync_statuses s
      ON from_db = 'fphs-db'
      AND to_db = 'athena-db'
      AND m.id = s.from_master_id
      AND sleep.sleep_id::varchar = s.external_id
      AND s.external_type = 'sleep_assignments'
    WHERE
      (
        s.id IS NULL
        OR coalesce(s.select_status, '') NOT IN ('completed', 'already transferred') AND s.created_at < now() - interval '2 hours'
      )
      AND sleep.sleep_id is not null
      AND th.sub_process_id = sel_sub_process_id
    ;
END;
$$;


-- Add records to sync_statuses that indicate specific master IDs with external IDs are in the process of being sync'd
CREATE OR REPLACE FUNCTION lock_transfer_records_with_external_ids(from_db VARCHAR, to_db VARCHAR, master_ids INTEGER[], external_ids INTEGER[], external_type VARCHAR) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT into sync_statuses
  ( from_master_id, external_id, external_type, from_db, to_db, select_status, created_at, updated_at )
  (
    SELECT unnest(master_ids), unnest(external_ids), external_type, from_db, to_db, 'new', now(), now()
  );

  RETURN 1;

END;
$$;
