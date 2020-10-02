SET search_path = ml_app;

-------------------------------------------------------
---- Remote AWS Database Synchronization functions ----
-------------------------------------------------------
-- See sync_subject_data.sh for more information on usage
-------------------------------------------------------
----> At this point we switch to the Athena DB
-- Get appropriate data as CSV
----> Switch back to the FPHS DB
-- Generate temporary tables from the exported CSVs
-------------------------------------------------------
-------------------------------------------------------
-- Run through the entries in temporary temp_pitt_bhi_assignments table to update all the Zeus PITT BHI records
-- Call create_remote_pitt_bhi_record() for each, pulling matched records from temp_player_infos and temp_player_contacts.
-- Temporary tables are used, since they will already be populated with data from the Zeus server via CSV files

CREATE OR REPLACE FUNCTION create_all_remote_pitt_bhi_records ()
  RETURNS integer
  LANGUAGE plpgsql
  AS $$
DECLARE
  pitt_bhi_record RECORD;
BEGIN
  FOR pitt_bhi_record IN
  SELECT
    *
  FROM
    temp_pitt_bhi_assignments LOOP
      PERFORM
        create_remote_pitt_bhi_record (pitt_bhi_record.pitt_bhi_id::bigint, (
            SELECT
              (pi::varchar)::player_infos FROM temp_player_infos pi
WHERE
  master_id = pitt_bhi_record.master_id LIMIT 1), ARRAY ( SELECT DISTINCT
    (pc::varchar)::player_contacts FROM temp_player_contacts pc
WHERE
  master_id = pitt_bhi_record.master_id), ARRAY ( SELECT DISTINCT
    (a::varchar)::addresses FROM temp_addresses a
WHERE
  master_id = pitt_bhi_record.master_id));
    END LOOP;
  RETURN 1;
END;
  $$;
  -------------------------------------------------------
  -- Create player_infos record, multiple player_contacts records, multiple addresses records
  -- Pass in the PITT BHI ID to be matched, a single row player info, and arrays of player_contacts and addresses records.
  -- Run tests with:
  -- select pitt_bhi.create_remote_pitt_bhi_record(364648868, (select pi from player_infos pi where master_id = 105029 limit 1), ARRAY(select pi from player_contacts pi where master_id = 105029), ARRAY(select pi from addresses pi where master_id = 105029) );
  -- Notice that player_contacts and addresses results are converted to an array, using the ARRAY() function, allowing them to be passed to the function.
  CREATE OR REPLACE FUNCTION create_remote_pitt_bhi_record (match_pitt_bhi_id bigint, new_player_info_record player_infos, new_player_contact_records player_contacts[], new_address_records addresses[] )
    RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  found_pitt_bhi record;
  etl_user_id integer;
  new_master_id integer;
  player_contact record;
  address record;
  pc_length integer;
  found_pc record;
  a_length integer;
  found_a record;
  last_id integer;
BEGIN
  -- Find the pitt_bhi_assignments external identifier record for this master record and
  -- validate that it exists
  SELECT
    * INTO found_pitt_bhi
  FROM
    pitt_bhi.pitt_bhi_assignments pitt
  WHERE
    pitt.pitt_bhi_id = match_pitt_bhi_id
  LIMIT 1;
  -- If the PITT BHI external identifier already exists then the sync should fail.
  IF FOUND THEN
    RAISE NOTICE 'Already transferred: pitt_bhi_assigments record found for PITT_BHI_ID --> %', (match_pitt_bhi_id);
    UPDATE
      temp_pitt_bhi_assignments
    SET
      status = 'already transferred',
      to_master_id = new_master_id
    WHERE
      pitt_bhi_id = match_pitt_bhi_id;
    RETURN found_pitt_bhi.master_id;
  END IF;
  -- We create new records setting user_id for the user with email fphsetl@hms.harvard.edu, rather than the original
  -- value from the source database, which probably would not match the user IDs in the remote database.
  SELECT
    id INTO etl_user_id
  FROM
    users u
  WHERE
    u.email = 'fphsetl@hms.harvard.edu'
  LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No user with email fphsetl@hms.harvard.edu was found. Can not continue.';
  END IF;
  UPDATE
    temp_pitt_bhi_assignments
  SET
    status = 'started sync'
  WHERE
    pitt_bhi_id = match_pitt_bhi_id;
  RAISE NOTICE 'Creating master record with user_id %', (etl_user_id::varchar);
  INSERT INTO masters (
    user_id,
    created_at,
    updated_at)
  VALUES (
    etl_user_id,
    now(),
    now())
RETURNING
  id INTO new_master_id;
  RAISE NOTICE 'Creating external identifier record %', (match_pitt_bhi_id::varchar);
  INSERT INTO pitt_bhi.pitt_bhi_assignments (
    pitt_bhi_id,
    master_id,
    user_id,
    created_at,
    updated_at)
  VALUES (
    match_pitt_bhi_id,
    new_master_id,
    etl_user_id,
    now(),
    now());
  IF new_player_info_record.master_id IS NULL THEN
    RAISE NOTICE 'No new_player_info_record found for PITT_BHI_ID --> %', (match_pitt_bhi_id);
    UPDATE
      temp_pitt_bhi_assignments
    SET
      status = 'failed - no player info provided'
    WHERE
      pitt_bhi_id = match_pitt_bhi_id;
    RETURN NULL;
  ELSE
    RAISE NOTICE 'Syncing player info record %', (new_player_info_record::varchar);
    -- Create the player info record
    INSERT INTO player_infos (
      master_id,
      first_name,
      last_name,
      middle_name,
      nick_name,
      birth_date,
      death_date,
      user_id,
      created_at,
      updated_at,
      contact_pref,
      start_year,
      rank,
      notes,
      contact_id,
      college,
      end_year,
      source)
    SELECT
      new_master_id,
      new_player_info_record.first_name,
      new_player_info_record.last_name,
      new_player_info_record.middle_name,
      new_player_info_record.nick_name,
      new_player_info_record.birth_date,
      new_player_info_record.death_date,
      etl_user_id,
      new_player_info_record.created_at,
      new_player_info_record.updated_at,
      new_player_info_record.contact_pref,
      new_player_info_record.start_year,
      new_player_info_record.rank,
      new_player_info_record.notes,
      new_player_info_record.contact_id,
      new_player_info_record.college,
      new_player_info_record.end_year,
      new_player_info_record.source
    RETURNING
      id INTO last_id;
  END IF;
  SELECT
    array_length(new_player_contact_records, 1) INTO pc_length;
  IF pc_length IS NULL THEN
    RAISE NOTICE 'No new_player_contact_records found for PITT_BHI_ID --> %', (match_pitt_bhi_id);
  ELSE
    RAISE NOTICE 'player contacts length %', (pc_length);
    FOREACH player_contact IN ARRAY new_player_contact_records LOOP
      SELECT
        *
      FROM
        player_contacts INTO found_pc
      WHERE
        master_id = new_master_id
        AND rec_type = player_contact.rec_type
        AND data = player_contact.data
      LIMIT 1;
      IF found_pc.id IS NULL THEN
        INSERT INTO player_contacts (
          master_id,
          rec_type,
          data,
          source,
          rank,
          user_id,
          created_at,
          updated_at)
        SELECT
          new_master_id,
          player_contact.rec_type,
          player_contact.data,
          player_contact.source,
          player_contact.rank,
          etl_user_id,
          player_contact.created_at,
          player_contact.updated_at;
      END IF;
    END LOOP;
  END IF;
  SELECT
    array_length(new_address_records, 1) INTO a_length;
  IF a_length IS NULL THEN
    RAISE NOTICE 'No new_address_records found for PITT_BHI_ID --> %', (match_pitt_bhi_id);
  ELSE
    RAISE NOTICE 'addresses length %', (a_length);
    FOREACH address IN ARRAY new_address_records LOOP
      SELECT
        *
      FROM
        addresses INTO found_a
      WHERE
        master_id = new_master_id
        AND street = address.street
        AND zip = address.zip
      LIMIT 1;
      IF found_a.id IS NULL THEN
        INSERT INTO addresses (
          master_id,
          street,
          street2,
          street3,
          city,
          state,
          zip,
          source,
          rank,
          rec_type,
          user_id,
          created_at,
          updated_at)
        SELECT
          new_master_id,
          address.street,
          address.street2,
          address.street3,
          address.city,
          address.state,
          address.zip,
          address.source,
          address.rank,
          address.rec_type,
          etl_user_id,
          address.created_at,
          address.updated_at;
      END IF;
    END LOOP;
  END IF;
  RAISE NOTICE 'Setting results for master_id %', (new_master_id);
  UPDATE
    temp_pitt_bhi_assignments
  SET
    status = 'completed',
    to_master_id = new_master_id
  WHERE
    pitt_bhi_id = match_pitt_bhi_id;
  RETURN new_master_id;
END;
  $$;
