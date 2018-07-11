-------------------------------------------------------
---- Remote AWS Database Synchronization functions ----
-------------------------------------------------------
-- See sync_subject_data.sh for more information on usage


-------------------------------------------------------
----> At this point we switch to the Zeus FPHS DB
-- Get appropriate data as CSV
----> Switch back to the AWS DB
-- Generate temporary tables from the exported CSVs
-------------------------------------------------------

-------------------------------------------------------
-- Run through the entries in temporary temp_ipa_assignments table to create all the remote IPA records
-- Call create_remote_ipa_record() for each, pulling matched records from temp_player_infos and temp_player_contacts.
-- Temporary tables are used, since they will already be populated with data from the Zeus server via CSV files
CREATE OR REPLACE FUNCTION create_all_remote_ipa_records() returns INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	ipa_record RECORD;
BEGIN

	FOR ipa_record IN
	  SELECT * from temp_ipa_assignments
	LOOP

		PERFORM create_remote_ipa_record(
			ipa_record.ipa_id,
			(SELECT (pi::varchar)::player_infos FROM temp_player_infos pi WHERE master_id = ipa_record.master_id LIMIT 1),
			ARRAY(SELECT distinct (pc::varchar)::player_contacts FROM temp_player_contacts pc WHERE master_id = ipa_record.master_id),
			ARRAY(SELECT distinct (a::varchar)::addresses FROM temp_addresses a WHERE master_id = ipa_record.master_id)
		);

	END LOOP;

	return 1;

END;
$$;

-------------------------------------------------------
-- Create player_infos record, multiple player_contacts records, multiple addresses records
-- Pass in the IPA ID to be matched, a single row player info, and an array of player_contacts records.
-- Run tests with:
-- select ml_app.create_remote_ipa_record(364648868, (select pi from player_infos pi where master_id = 105029 limit 1), ARRAY(select pi from player_contacts pi where master_id = 105029), ARRAY(select pi from addresses pi where master_id = 105029) );
-- Notice that player_contacts and addresses results are converted to an array, using the ARRAY() function, allowing them to be passed to the function.
CREATE OR REPLACE FUNCTION create_remote_ipa_record(match_ipa_id BIGINT, new_player_info_record player_infos, new_player_contact_records player_contacts[], new_address_records addresses[]) returns INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	found_ipa record;
	player_contact record;
	address record;
	pc_length INTEGER;
	found_pc record;
	a_length INTEGER;
	found_a record;
	last_id INTEGER;
	phone VARCHAR;
BEGIN

-- Find the ipa_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_ipa
FROM ipa_assignments ipa
WHERE ipa.ipa_id = match_ipa_id
LIMIT 1;

-- At this point, if we found the above record, then the master record can be referred to with found_ipa.master_id
-- We also create the new records setting the user_id to match that of the found_ipa record, rather than the original
-- value from the source database, which probably would not match the user IDs in the remote database. The user_id of the
-- found_ipa record is conceptually valid, since it is that user that has effectively kicked off the synchronization process
-- and requested the new player_infos and player_contacts records be created.

IF NOT FOUND THEN
	RAISE EXCEPTION 'No ipa_assigments record found for IPA_ID --> %', (match_ipa_id);
END IF;




IF new_player_info_record.master_id IS NULL THEN
	RAISE NOTICE 'No new_player_info_record found for IPA_ID --> %', (match_ipa_id);
	RETURN NULL;
ELSE

	RAISE NOTICE 'Syncing player info record %', (new_player_info_record::varchar);

	-- Create the player info record
  INSERT INTO player_infos
  (
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
    source
  )
  SELECT
    found_ipa.master_id,
    new_player_info_record.first_name,
    new_player_info_record.last_name,
    new_player_info_record.middle_name,
    new_player_info_record.nick_name,
    new_player_info_record.birth_date,
    new_player_info_record.death_date,
    found_ipa.user_id,
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

		RETURNING id
	  INTO last_id
	  ;


END IF;



SELECT array_length(new_player_contact_records, 1)
INTO pc_length;


IF pc_length IS NULL THEN
	RAISE NOTICE 'No new_player_contact_records found for IPA_ID --> %', (match_ipa_id);
ELSE

	RAISE NOTICE 'player contacts length %', (pc_length);

	FOREACH player_contact IN ARRAY new_player_contact_records LOOP

		SELECT * from player_contacts
		INTO found_pc
		WHERE
			master_id = found_ipa.master_id AND
			rec_type = player_contact.rec_type AND
			data = player_contact.data
		LIMIT 1;

		IF found_pc.id IS NULL THEN

		  INSERT INTO player_contacts
			(
							master_id,
							rec_type,
							data,
							source,
							rank,
							user_id,
							created_at,
							updated_at
			)
			SELECT
					found_ipa.master_id,
					player_contact.rec_type,
					player_contact.data,
					player_contact.source,
					player_contact.rank,
					found_ipa.user_id,
					player_contact.created_at,
					player_contact.updated_at
			;
		END IF;

	END LOOP;

END IF;




SELECT array_length(new_address_records, 1)
INTO a_length;


IF a_length IS NULL THEN
	RAISE NOTICE 'No new_address_records found for IPA_ID --> %', (match_ipa_id);
ELSE

	RAISE NOTICE 'addresses length %', (a_length);

	FOREACH address IN ARRAY new_address_records LOOP

		SELECT * from addresses
		INTO found_a
		WHERE
			master_id = found_ipa.master_id AND
			street = address.street AND
			zip = address.zip
		LIMIT 1;

		IF found_a.id IS NULL THEN

		  INSERT INTO addresses
			(
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
							updated_at
			)
			SELECT
					found_ipa.master_id,
					address.street,
					address.street2,
					address.street3,
					address.city,
					address.state,
					address.zip,
					address.source,
					address.rank,
					address.rec_type,
					found_ipa.user_id,
					address.created_at,
					address.updated_at
			;
		END IF;

	END LOOP;

END IF;




return found_ipa.master_id;

END;
$$;
