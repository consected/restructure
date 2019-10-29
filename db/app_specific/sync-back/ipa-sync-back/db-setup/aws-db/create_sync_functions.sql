SET search_path=ml_app;
-------------------------------------------------------
-- Find the IPA IDs, event that
-- are not null (an IPA ID is necessary)
-- don't have a sync_statuses record (no attempt to sync has already been made) or
-- a sync_statuses record is not marked as 'completed' or 'already transferred', and was created over 2 hours ago (allowing failed items to be retried)
--
CREATE OR REPLACE FUNCTION find_new_athena_ipa_records() RETURNS TABLE (
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
      AND al.extra_log_type IN ('appointment', 'withdraw', 'follow_up_surveys')
    LEFT JOIN sync_statuses s
      ON from_db = 'athena-db'
      AND to_db = 'fphs-db'
      AND m.id = s.from_master_id
      AND ipa.ipa_id::varchar = s.external_id
      AND s.external_type = 'ipa_assignments'
      AND s.event = al.extra_log_type
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
CREATE OR REPLACE FUNCTION lock_transfer_records_with_external_ids_and_events(from_db VARCHAR, to_db VARCHAR, master_ids INTEGER[], external_ids INTEGER[], external_type VARCHAR, events VARCHAR[]) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT into ml_app.sync_statuses
  ( from_master_id, external_id, external_type, from_db, to_db, event, select_status, created_at, updated_at )
  (
    SELECT unnest(master_ids), unnest(external_ids), external_type, from_db, to_db, unnest(events), 'new', now(), now()
  );

  RETURN 1;

END;
$$;


-- Add records to sync_statuses that indicate specific master IDs are in the process of being sync'd
CREATE OR REPLACE FUNCTION update_transfer_record_results(new_from_db VARCHAR, new_to_db VARCHAR, for_external_type VARCHAR) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN

  UPDATE ml_app.sync_statuses
  SET
    select_status = t.status,
    to_master_id = t.to_master_id,
    event = t.event,
    updated_at = now()
  FROM (
    SELECT * FROM temp_ipa_assignments_results
  ) AS t
  WHERE
    from_master_id = t.master_id
    AND from_db = new_from_db
    AND to_db = new_to_db
    AND external_id = t.ipa_id::varchar
    AND external_type = for_external_type
    AND coalesce(select_status, '') NOT IN ('completed', 'already transferred');

END;
$$;
