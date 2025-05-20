set
  statement_timeout = 0
;


set
  lock_timeout = 0
;


set
  idle_in_transaction_session_timeout = 0
;


set
  client_encoding = 'UTF8'
;


set
  standard_conforming_strings = on
;


select
  pg_catalog.set_config ('search_path', '', false)
;


set
  check_function_bodies = false
;


set
  xmloption = content
;


set
  client_min_messages = warning
;


set
  row_security = off
;


--
-- Name: ml_app; Type: SCHEMA; Schema: -; Owner: -
--
create schema ml_app
;


--
-- Name: ref_data; Type: SCHEMA; Schema: -; Owner: -
--
create schema ref_data
;


--
-- Name: add_study_update_entry(integer, character varying, character varying, date, character varying, integer, integer, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.add_study_update_entry (
  master_id integer,
  update_type character varying,
  update_name character varying,
  event_date date,
  update_notes character varying,
  user_id integer,
  item_id integer,
  item_type character varying
) returns integer language plpgsql as $$
        DECLARE
          new_tracker_id integer;
          protocol_record RECORD;
        BEGIN
        
          SELECT add_tracker_entry_by_name(master_id, 'Updates', 'record updates', (update_type || ' ' || update_name), event_date, update_notes, user_id, item_id, item_type) into new_tracker_id;
          /*
          SELECT p.id protocol_id, sp.id sub_process_id, pe.id protocol_event_id 
          INTO protocol_record           
          FROM protocol_events pe 
          INNER JOIN sub_processes sp on pe.sub_process_id = sp.id 
          INNER JOIN protocols p on sp.protocol_id = p.id
          WHERE p.name = 'Updates' 
          AND sp.name = 'record updates' 
          AND pe.name = (update_type || ' ' || update_name) 
          AND (p.disabled IS NULL or p.disabled = FALSE) AND (sp.disabled IS NULL or sp.disabled = FALSE) AND (pe.disabled IS NULL or pe.disabled = FALSE);

          IF NOT FOUND THEN
            RAISE EXCEPTION 'Nonexistent protocol record --> %', (update_type || ' ' || update_name );
          ELSE

            INSERT INTO trackers 
            (master_id, protocol_id, sub_process_id, protocol_event_id, item_type, item_id, user_id, event_date, updated_at, created_at, notes)
            VALUES
            (master_id, protocol_record.protocol_id, protocol_record.sub_process_id, protocol_record.protocol_event_id, 
             item_type, item_id, user_id, now(), now(), now(), update_notes);                        

            RETURN new_tracker_id;
          END IF;
          */  
          RETURN new_tracker_id;
        END;
    $$
;


--
-- Name: add_tracker_entry_by_name(integer, character varying, character varying, character varying, character varying, integer, integer, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.add_tracker_entry_by_name (
  master_id integer,
  protocol_name character varying,
  sub_process_name character varying,
  protocol_event_name character varying,
  set_notes character varying,
  user_id integer,
  item_id integer,
  item_type character varying
) returns integer language plpgsql as $$
        DECLARE
          new_tracker_id integer;
          protocol_record RECORD;
        BEGIN

          
          SELECT p.id protocol_id, sp.id sub_process_id, pe.id protocol_event_id 
          INTO protocol_record           
          FROM protocol_events pe 
          INNER JOIN sub_processes sp on pe.sub_process_id = sp.id 
          INNER JOIN protocols p on sp.protocol_id = p.id
          WHERE p.name = protocol_name
          AND sp.name = sub_process_name 
          AND pe.name = protocol_event_name
          AND (p.disabled IS NULL or p.disabled = FALSE) AND (sp.disabled IS NULL or sp.disabled = FALSE) AND (pe.disabled IS NULL or pe.disabled = FALSE);

          IF NOT FOUND THEN
            RAISE EXCEPTION 'Nonexistent protocol record --> %', (protocol_name || ' ' || sub_process_name || ' ' || protocol_event_name);
          ELSE

            INSERT INTO trackers 
            (master_id, protocol_id, sub_process_id, protocol_event_id, item_type, item_id, user_id, event_date, updated_at, created_at, notes)
            VALUES
            (master_id, protocol_record.protocol_id, protocol_record.sub_process_id, protocol_record.protocol_event_id, 
             item_type, item_id, user_id, now(), now(), now(), set_notes);                        

            RETURN new_tracker_id;
          END IF;

        END;
    $$
;


--
-- Name: add_tracker_entry_by_name(integer, character varying, character varying, character varying, date, character varying, integer, integer, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.add_tracker_entry_by_name (
  master_id integer,
  protocol_name character varying,
  sub_process_name character varying,
  protocol_event_name character varying,
  event_date date,
  set_notes character varying,
  user_id integer,
  item_id integer,
  item_type character varying
) returns integer language plpgsql as $$
        DECLARE
          new_tracker_id integer;
          protocol_record RECORD;
        BEGIN

          
          SELECT p.id protocol_id, sp.id sub_process_id, pe.id protocol_event_id 
          INTO protocol_record           
          FROM protocol_events pe 
          INNER JOIN sub_processes sp on pe.sub_process_id = sp.id 
          INNER JOIN protocols p on sp.protocol_id = p.id
          WHERE lower(p.name) = lower(protocol_name)
          AND lower(sp.name) = lower(sub_process_name) 
          AND lower(pe.name) = lower(protocol_event_name)
          AND (p.disabled IS NULL or p.disabled = FALSE) AND (sp.disabled IS NULL or sp.disabled = FALSE) AND (pe.disabled IS NULL or pe.disabled = FALSE);

          IF NOT FOUND THEN
            RAISE EXCEPTION 'Nonexistent protocol record --> %', (protocol_name || ' ' || sub_process_name || ' ' || protocol_event_name);
          ELSE

            INSERT INTO trackers 
            (master_id, protocol_id, sub_process_id, protocol_event_id, item_type, item_id, user_id, event_date, updated_at, created_at, notes)
            VALUES
            (master_id, protocol_record.protocol_id, protocol_record.sub_process_id, protocol_record.protocol_event_id, 
             item_type, item_id, user_id, now(), now(), now(), set_notes);                        

            RETURN new_tracker_id;
          END IF;

        END;
    $$
;


--
-- Name: assign_sage_ids_to_players(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.assign_sage_ids_to_players () returns record language plpgsql as $$
      DECLARE
        min_sa integer;
        max_sa integer;
        res record;
      BEGIN

        -- update the precreated Sage ID records with the master_id from the player info, based on matching ID. 
        -- apply an offset here if the Sage ID does not start at zero
        -- find the first unassigned Sage ID
        select min(id) into min_sa from sage_assignments where master_id is null;
        -- update the sage assignments in a block starting from the minimum unassigned ID
        update sage_assignments sa set master_id = (select master_id from temp_pit where id = sa.id - min_sa) where sa.master_id is null and sa.id >= min_sa;
        -- get the max value to return the results
        select max(id) into max_sa from sage_assignments where master_id is not null;
        select min_sa, max_sa into res;
        return res;

       END;

    $$
;


--
-- Name: create_message_notification_email(character varying, character varying, character varying, json, character varying[], character varying, timestamp without time zone); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.create_message_notification_email (
  layout_template_name character varying,
  content_template_name character varying,
  subject character varying,
  data json,
  recipient_emails character varying[],
  from_user_email character varying,
  run_at timestamp without time zone default null::timestamp without time zone
) returns integer language plpgsql as $$
    DECLARE
      last_id INTEGER;
    BEGIN

      IF run_at IS NULL THEN
        run_at := now();
      END IF;

      INSERT INTO ml_app.message_notifications
      (
        message_type,
        created_at,
        updated_at,
        layout_template_name,
        content_template_name,
        subject,
        data,
        recipient_emails,
        from_user_email
      )
      VALUES
      (
        'email',
        now(),
        now(),
        layout_template_name,
        content_template_name,
        subject,
        data,
        recipient_emails,
        from_user_email
      )
      RETURNING id
      INTO last_id
      ;

      SELECT create_message_notification_job(last_id, run_at)
      INTO last_id
      ;

      RETURN last_id;
    END;
    $$
;


--
-- Name: create_message_notification_email(integer, integer, integer, character varying, integer, integer[], character varying, character varying, character varying, timestamp without time zone); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.create_message_notification_email (
  app_type_id integer,
  master_id integer,
  item_id integer,
  item_type character varying,
  user_id integer,
  recipient_user_ids integer[],
  layout_template_name character varying,
  content_template_name character varying,
  subject character varying,
  run_at timestamp without time zone default null::timestamp without time zone
) returns integer language plpgsql as $$
    DECLARE
      last_id INTEGER;
    BEGIN

      IF run_at IS NULL THEN
        run_at := now();
      END IF;

      INSERT INTO ml_app.message_notifications
      (
        subject,
        app_type_id,
        user_id,
        recipient_user_ids,
        layout_template_name,
        content_template_name,
        item_type,
        item_id,
        master_id,
        message_type,
        created_at,
        updated_at
      )
      VALUES
      (
        subject,
        app_type_id,
        user_id,
        recipient_user_ids,
        layout_template_name,
        content_template_name,
        item_type,
        item_id,
        master_id,
        'email',
        now(),
        now()
      )
      RETURNING id
      INTO last_id
      ;

      SELECT create_message_notification_job(last_id, run_at)
      INTO last_id
      ;

      RETURN last_id;
    END;
    $$
;


--
-- Name: create_message_notification_job(integer, timestamp without time zone); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.create_message_notification_job (
  message_notification_id integer,
  run_at timestamp without time zone default null::timestamp without time zone
) returns integer language plpgsql as $$
    DECLARE
      last_id INTEGER;
    BEGIN

      IF run_at IS NULL THEN
        run_at := now();
      END IF;

      INSERT INTO ml_app.delayed_jobs
      (
        priority,
        attempts,
        handler,
        run_at,
        queue,
        created_at,
        updated_at
      )
      VALUES
      (
        0,
        0,
        '--- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
        job_data:
          job_class: HandleMessageNotificationJob
          job_id: ' || gen_random_uuid() || '
          queue_name: default
          arguments:
          - _aj_globalid: gid://fpa1/MessageNotification/' || message_notification_id::varchar || '
          locale: :en',
        run_at,
        'default',
        now(),
        now()
      )
      RETURNING id
      INTO last_id
      ;

    	RETURN last_id;
    END;
    $$
;


set
  default_tablespace = ''
;


set
  default_table_access_method = heap
;


--
-- Name: player_contacts; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.player_contacts (
    id integer not null,
    master_id integer,
    rec_type character varying,
    data character varying,
    source character varying,
    rank integer,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone default '2017-09-25 15:43:36.922871'::timestamp without time zone
  )
;


--
-- Name: player_infos; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.player_infos (
    id integer not null,
    master_id integer,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    nick_name character varying,
    birth_date date,
    death_date date,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone default '2017-09-25 15:43:37.094626'::timestamp without time zone,
    contact_pref character varying,
    start_year integer,
    rank integer,
    notes character varying,
    contact_id integer,
    college character varying,
    end_year integer,
    source character varying,
    other_count integer,
    other_type character varying
  )
;


--
-- Name: create_remote_bhs_record(bigint, ml_app.player_infos, ml_app.player_contacts[]); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.create_remote_bhs_record (
  match_bhs_id bigint,
  new_player_info_record ml_app.player_infos,
  new_player_contact_records ml_app.player_contacts[]
) returns integer language plpgsql as $$
DECLARE
found_bhs record;
player_contact record;
pc_length INTEGER;
found_pc record;
last_id INTEGER;
phone VARCHAR;
BEGIN

-- Find the bhs_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_bhs
FROM bhs_assignments bhs
WHERE bhs.bhs_id = match_bhs_id
LIMIT 1;

-- At this point, if we found the above record, then the master record can be referred to with found_bhs.master_id
-- We also create the new records setting the user_id to match that of the found_bhs record, rather than the original
-- value from the source database, which probably would not match the user IDs in the remote database. The user_id of the
-- found_bhs record is conceptually valid, since it is that user that has effectively kicked off the synchronization process
-- and requested the new player_infos and player_contacts records be created.

IF NOT FOUND THEN
RAISE EXCEPTION 'No bhs_assigments record found for BHS_ID --> %', (match_bhs_id);
END IF;




IF new_player_info_record.master_id IS NULL THEN
RAISE NOTICE 'No new_player_info_record found for BHS_ID --> %', (match_bhs_id);
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
    found_bhs.master_id,
    new_player_info_record.first_name,
    new_player_info_record.last_name,
    new_player_info_record.middle_name,
    new_player_info_record.nick_name,
    new_player_info_record.birth_date,
    new_player_info_record.death_date,
    found_bhs.user_id,
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
RAISE NOTICE 'No new_player_contact_records found for BHS_ID --> %', (match_bhs_id);
ELSE

RAISE NOTICE 'player contacts length %', (pc_length);

FOREACH player_contact IN ARRAY new_player_contact_records LOOP

SELECT * from player_contacts
INTO found_pc
WHERE
master_id = found_bhs.master_id AND
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
found_bhs.master_id,
player_contact.rec_type,
player_contact.data,
player_contact.source,
player_contact.rank,
found_bhs.user_id,
player_contact.created_at,
player_contact.updated_at
;
END IF;

END LOOP;


SELECT id
INTO last_id
FROM activity_log_bhs_assignments
WHERE
bhs_assignment_id IS NOT NULL
AND (select_record_from_player_contact_phones is null OR select_record_from_player_contact_phones = '')
AND master_id = found_bhs.master_id
AND extra_log_type = 'primary'
ORDER BY id ASC
LIMIT 1;


-- Get the best phone number
SELECT data FROM player_contacts
INTO phone
WHERE rec_type='phone' AND rank is not null AND master_id = found_bhs.master_id
ORDER BY rank desc
LIMIT 1;

RAISE NOTICE 'best phone number %', (phone);
  RAISE NOTICE 'AL ID %', (last_id);

  -- Now update the activity log record.
UPDATE activity_log_bhs_assignments
SET
  select_record_from_player_contact_phones = phone,
results_link = ('https://testmybrain.org?demotestid=' || found_bhs.bhs_id::varchar),
updated_at = now()
WHERE
id = last_id;


-- Now send a notification to the PI
PERFORM activity_log_bhs_assignment_info_request_notification(last_id);


END IF;

return found_bhs.master_id;

END;
$$
;


--
-- Name: addresses; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.addresses (
    id integer not null,
    master_id integer,
    street character varying,
    street2 character varying,
    street3 character varying,
    city character varying,
    state character varying,
    zip character varying,
    source character varying,
    rank integer,
    rec_type character varying,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone default '2017-09-25 15:43:35.929228'::timestamp without time zone,
    country character varying(3),
    postal_code character varying,
    region character varying
  )
;


--
-- Name: create_remote_sleep_record(bigint, ml_app.player_infos, ml_app.player_contacts[], ml_app.addresses[]); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.create_remote_sleep_record (
  match_sleep_id bigint,
  new_player_info_record ml_app.player_infos,
  new_player_contact_records ml_app.player_contacts[],
  new_address_records ml_app.addresses[]
) returns integer language plpgsql as $$
DECLARE
	found_ipa record;
	etl_user_id INTEGER;
	new_master_id INTEGER;
	player_contact record;
	address record;
	pc_length INTEGER;
	found_pc record;
	a_length INTEGER;
	found_a record;
	last_id INTEGER;
BEGIN

-- Find the sleep_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_ipa
FROM sleep.sleep_assignments ipa
WHERE ipa.sleep_id = match_sleep_id
LIMIT 1;

-- If the IPA external identifier already exists then the sync should fail.

IF FOUND THEN
	RAISE NOTICE 'Already transferred: sleep_assigments record found for IPA_ID --> %', (match_sleep_id);
	UPDATE temp_sleep_assignments SET status='already transferred', to_master_id=new_master_id WHERE sleep_id = match_sleep_id;
  RETURN found_ipa.master_id;
END IF;

-- We create new records setting user_id for the user with email fphsetl@hms.harvard.edu, rather than the original
-- value from the source database, which probably would not match the user IDs in the remote database.
SELECT id
INTO etl_user_id
FROM users u
WHERE u.email = 'fphsetl@hms.harvard.edu'
LIMIT 1;

IF NOT FOUND THEN
	RAISE EXCEPTION 'No user with email fphsetl@hms.harvard.edu was found. Can not continue.';
END IF;

UPDATE temp_sleep_assignments SET status='started sync' WHERE sleep_id = match_sleep_id;


RAISE NOTICE 'Creating master record with user_id %', (etl_user_id::varchar);

INSERT INTO masters
(user_id, created_at, updated_at) VALUES (etl_user_id, now(), now())
RETURNING id
INTO new_master_id;

RAISE NOTICE 'Creating external identifier record %', (match_sleep_id::varchar);

INSERT INTO sleep.sleep_assignments
(sleep_id, master_id, user_id, created_at, updated_at)
VALUES (match_sleep_id, new_master_id, etl_user_id, now(), now());



IF new_player_info_record.master_id IS NULL THEN
	RAISE NOTICE 'No new_player_info_record found for IPA_ID --> %', (match_sleep_id);
	UPDATE temp_sleep_assignments SET status='failed - no player info provided' WHERE sleep_id = match_sleep_id;
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

		RETURNING id
	  INTO last_id
	  ;


END IF;



SELECT array_length(new_player_contact_records, 1)
INTO pc_length;


IF pc_length IS NULL THEN
	RAISE NOTICE 'No new_player_contact_records found for IPA_ID --> %', (match_sleep_id);
ELSE

	RAISE NOTICE 'player contacts length %', (pc_length);

	FOREACH player_contact IN ARRAY new_player_contact_records LOOP

		SELECT * from player_contacts
		INTO found_pc
		WHERE
			master_id = new_master_id AND
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
					new_master_id,
					player_contact.rec_type,
					player_contact.data,
					player_contact.source,
					player_contact.rank,
					etl_user_id,
					player_contact.created_at,
					player_contact.updated_at
			;
		END IF;

	END LOOP;

END IF;




SELECT array_length(new_address_records, 1)
INTO a_length;


IF a_length IS NULL THEN
	RAISE NOTICE 'No new_address_records found for IPA_ID --> %', (match_sleep_id);
ELSE

	RAISE NOTICE 'addresses length %', (a_length);

	FOREACH address IN ARRAY new_address_records LOOP

		SELECT * from addresses
		INTO found_a
		WHERE
			master_id = new_master_id AND
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
					address.updated_at
			;
		END IF;

	END LOOP;

END IF;

RAISE NOTICE 'Setting results for master_id %', (new_master_id);

UPDATE temp_sleep_assignments SET status='completed', to_master_id=new_master_id WHERE sleep_id = match_sleep_id;

return new_master_id;

END;
$$
;


--
-- Name: create_remote_tbs_record(bigint, ml_app.player_infos, ml_app.player_contacts[], ml_app.addresses[]); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.create_remote_tbs_record (
  match_tbs_id bigint,
  new_player_info_record ml_app.player_infos,
  new_player_contact_records ml_app.player_contacts[],
  new_address_records ml_app.addresses[]
) returns integer language plpgsql as $$
DECLARE
	found_ipa record;
	etl_user_id INTEGER;
	new_master_id INTEGER;
	player_contact record;
	address record;
	pc_length INTEGER;
	found_pc record;
	a_length INTEGER;
	found_a record;
	last_id INTEGER;
BEGIN

-- Find the tbs_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_ipa
FROM tbs.tbs_assignments ipa
WHERE ipa.tbs_id = match_tbs_id
LIMIT 1;

-- If the IPA external identifier already exists then the sync should fail.

IF FOUND THEN
	RAISE NOTICE 'Already transferred: tbs_assigments record found for IPA_ID --> %', (match_tbs_id);
	UPDATE temp_tbs_assignments SET status='already transferred', to_master_id=new_master_id WHERE tbs_id = match_tbs_id;
  RETURN found_ipa.master_id;
END IF;

-- We create new records setting user_id for the user with email fphsetl@hms.harvard.edu, rather than the original
-- value from the source database, which probably would not match the user IDs in the remote database.
SELECT id
INTO etl_user_id
FROM users u
WHERE u.email = 'fphsetl@hms.harvard.edu'
LIMIT 1;

IF NOT FOUND THEN
	RAISE EXCEPTION 'No user with email fphsetl@hms.harvard.edu was found. Can not continue.';
END IF;

UPDATE temp_tbs_assignments SET status='started sync' WHERE tbs_id = match_tbs_id;


RAISE NOTICE 'Creating master record with user_id %', (etl_user_id::varchar);

INSERT INTO masters
(user_id, created_at, updated_at) VALUES (etl_user_id, now(), now())
RETURNING id
INTO new_master_id;

RAISE NOTICE 'Creating external identifier record %', (match_tbs_id::varchar);

INSERT INTO tbs.tbs_assignments
(tbs_id, master_id, user_id, created_at, updated_at)
VALUES (match_tbs_id, new_master_id, etl_user_id, now(), now());



IF new_player_info_record.master_id IS NULL THEN
	RAISE NOTICE 'No new_player_info_record found for IPA_ID --> %', (match_tbs_id);
	UPDATE temp_tbs_assignments SET status='failed - no player info provided' WHERE tbs_id = match_tbs_id;
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

		RETURNING id
	  INTO last_id
	  ;


END IF;



SELECT array_length(new_player_contact_records, 1)
INTO pc_length;


IF pc_length IS NULL THEN
	RAISE NOTICE 'No new_player_contact_records found for IPA_ID --> %', (match_tbs_id);
ELSE

	RAISE NOTICE 'player contacts length %', (pc_length);

	FOREACH player_contact IN ARRAY new_player_contact_records LOOP

		SELECT * from player_contacts
		INTO found_pc
		WHERE
			master_id = new_master_id AND
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
					new_master_id,
					player_contact.rec_type,
					player_contact.data,
					player_contact.source,
					player_contact.rank,
					etl_user_id,
					player_contact.created_at,
					player_contact.updated_at
			;
		END IF;

	END LOOP;

END IF;




SELECT array_length(new_address_records, 1)
INTO a_length;


IF a_length IS NULL THEN
	RAISE NOTICE 'No new_address_records found for IPA_ID --> %', (match_tbs_id);
ELSE

	RAISE NOTICE 'addresses length %', (a_length);

	FOREACH address IN ARRAY new_address_records LOOP

		SELECT * from addresses
		INTO found_a
		WHERE
			master_id = new_master_id AND
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
					address.updated_at
			;
		END IF;

	END LOOP;

END IF;

RAISE NOTICE 'Setting results for master_id %', (new_master_id);

UPDATE temp_tbs_assignments SET status='completed', to_master_id=new_master_id WHERE tbs_id = match_tbs_id;

return new_master_id;

END;
$$
;


--
-- Name: create_remote_test_baseline_study_record(bigint, ml_app.player_infos, ml_app.player_contacts[], ml_app.addresses[]); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.create_remote_test_baseline_study_record (
  match_test_baseline_study_id bigint,
  new_player_info_record ml_app.player_infos,
  new_player_contact_records ml_app.player_contacts[],
  new_address_records ml_app.addresses[]
) returns integer language plpgsql as $$
DECLARE
	found_ipa record;
	etl_user_id INTEGER;
	new_master_id INTEGER;
	player_contact record;
	address record;
	pc_length INTEGER;
	found_pc record;
	a_length INTEGER;
	found_a record;
	last_id INTEGER;
BEGIN

-- Find the test_baseline_study_assignments external identifier record for this master record and
-- validate that it exists
SELECT *
INTO found_ipa
FROM tbs.test_baseline_study_assignments ipa
WHERE ipa.test_baseline_study_id = match_test_baseline_study_id
LIMIT 1;

-- If the IPA external identifier already exists then the sync should fail.

IF FOUND THEN
	RAISE NOTICE 'Already transferred: test_baseline_study_assigments record found for IPA_ID --> %', (match_test_baseline_study_id);
	UPDATE temp_test_baseline_study_assignments SET status='already transferred', to_master_id=new_master_id WHERE test_baseline_study_id = match_test_baseline_study_id;
  RETURN found_ipa.master_id;
END IF;

-- We create new records setting user_id for the user with email fphsetl@hms.harvard.edu, rather than the original
-- value from the source database, which probably would not match the user IDs in the remote database.
SELECT id
INTO etl_user_id
FROM users u
WHERE u.email = 'fphsetl@hms.harvard.edu'
LIMIT 1;

IF NOT FOUND THEN
	RAISE EXCEPTION 'No user with email fphsetl@hms.harvard.edu was found. Can not continue.';
END IF;

UPDATE temp_test_baseline_study_assignments SET status='started sync' WHERE test_baseline_study_id = match_test_baseline_study_id;


RAISE NOTICE 'Creating master record with user_id %', (etl_user_id::varchar);

INSERT INTO masters
(user_id, created_at, updated_at) VALUES (etl_user_id, now(), now())
RETURNING id
INTO new_master_id;

RAISE NOTICE 'Creating external identifier record %', (match_test_baseline_study_id::varchar);

INSERT INTO tbs.test_baseline_study_assignments
(test_baseline_study_id, master_id, user_id, created_at, updated_at)
VALUES (match_test_baseline_study_id, new_master_id, etl_user_id, now(), now());



IF new_player_info_record.master_id IS NULL THEN
	RAISE NOTICE 'No new_player_info_record found for IPA_ID --> %', (match_test_baseline_study_id);
	UPDATE temp_test_baseline_study_assignments SET status='failed - no player info provided' WHERE test_baseline_study_id = match_test_baseline_study_id;
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

		RETURNING id
	  INTO last_id
	  ;


END IF;



SELECT array_length(new_player_contact_records, 1)
INTO pc_length;


IF pc_length IS NULL THEN
	RAISE NOTICE 'No new_player_contact_records found for IPA_ID --> %', (match_test_baseline_study_id);
ELSE

	RAISE NOTICE 'player contacts length %', (pc_length);

	FOREACH player_contact IN ARRAY new_player_contact_records LOOP

		SELECT * from player_contacts
		INTO found_pc
		WHERE
			master_id = new_master_id AND
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
					new_master_id,
					player_contact.rec_type,
					player_contact.data,
					player_contact.source,
					player_contact.rank,
					etl_user_id,
					player_contact.created_at,
					player_contact.updated_at
			;
		END IF;

	END LOOP;

END IF;




SELECT array_length(new_address_records, 1)
INTO a_length;


IF a_length IS NULL THEN
	RAISE NOTICE 'No new_address_records found for IPA_ID --> %', (match_test_baseline_study_id);
ELSE

	RAISE NOTICE 'addresses length %', (a_length);

	FOREACH address IN ARRAY new_address_records LOOP

		SELECT * from addresses
		INTO found_a
		WHERE
			master_id = new_master_id AND
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
					address.updated_at
			;
		END IF;

	END LOOP;

END IF;

RAISE NOTICE 'Setting results for master_id %', (new_master_id);

UPDATE temp_test_baseline_study_assignments SET status='completed', to_master_id=new_master_id WHERE test_baseline_study_id = match_test_baseline_study_id;

return new_master_id;

END;
$$
;


--
-- Name: current_user_id(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.current_user_id () returns integer language plpgsql as $$
      DECLARE
        user_id integer;
      BEGIN
        user_id := (select id from users where email = current_user limit 1);

        return user_id;
      END;
    $$
;


--
-- Name: datadic_choice_history_upd(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.datadic_choice_history_upd () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO datadic_choice_history (
    source_name, source_type, form_name, field_name, value, label, redcap_data_dictionary_id,
    disabled,
    admin_id,
    created_at,
    updated_at,
    datadic_choice_id)
  SELECT
    NEW.source_name, NEW.source_type, NEW.form_name, NEW.field_name, NEW.value, NEW.label, NEW.redcap_data_dictionary_id,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: datadic_variable_history_upd(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.datadic_variable_history_upd () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO datadic_variable_history (
    study, source_name, source_type, domain, form_name, variable_name, variable_type, presentation_type, label, label_note, annotation, is_required, valid_type, valid_min, valid_max, multi_valid_choices, is_identifier, is_derived_var, multi_derived_from_id, doc_url, target_type, owner_email, classification, other_classification, multi_timepoints, equivalent_to_id, storage_type, db_or_fs, schema_or_path, table_or_file, storage_varname, redcap_data_dictionary_id, position, section_id, sub_section_id, title,
    disabled,
    admin_id,
    created_at,
    updated_at,
    datadic_variable_id)
  SELECT
    NEW.study, NEW.source_name, NEW.source_type, NEW.domain, NEW.form_name, NEW.variable_name, NEW.variable_type, NEW.presentation_type, NEW.label, NEW.label_note, NEW.annotation, NEW.is_required, NEW.valid_type, NEW.valid_min, NEW.valid_max, NEW.multi_valid_choices, NEW.is_identifier, NEW.is_derived_var, NEW.multi_derived_from_id, NEW.doc_url, NEW.target_type, NEW.owner_email, NEW.classification, NEW.other_classification, NEW.multi_timepoints, NEW.equivalent_to_id, NEW.storage_type, NEW.db_or_fs, NEW.schema_or_path, NEW.table_or_file, NEW.storage_varname, NEW.redcap_data_dictionary_id, NEW.position, NEW.section_id, NEW.sub_section_id, NEW.title,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


set
  default_tablespace = ''
;


set
  default_table_access_method = heap
;


--
-- Name: nfs_store_archived_files; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.nfs_store_archived_files (
    id integer not null,
    file_hash character varying,
    file_name character varying not null,
    content_type character varying not null,
    archive_file character varying not null,
    path character varying not null,
    file_size bigint not null,
    file_updated_at timestamp without time zone,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    nfs_store_container_id integer,
    user_id integer,
    title character varying,
    description character varying,
    nfs_store_stored_file_id integer,
    file_metadata jsonb,
    embed_resource_name character varying,
    embed_resource_id bigint
  )
;


--
-- Name: nfs_store_stored_files; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.nfs_store_stored_files (
    id integer not null,
    file_hash character varying not null,
    file_name character varying not null,
    content_type character varying not null,
    file_size bigint not null,
    path character varying,
    file_updated_at timestamp without time zone,
    user_id integer,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    title character varying,
    description character varying,
    last_process_name_run character varying,
    file_metadata jsonb,
    embed_resource_name character varying,
    embed_resource_id bigint
  )
;


--
-- Name: filestore_report_full_file_path(ml_app.nfs_store_stored_files, ml_app.nfs_store_archived_files); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.filestore_report_full_file_path (sf ml_app.nfs_store_stored_files, af ml_app.nfs_store_archived_files) returns character varying language plpgsql as $$
    BEGIN

      return CASE WHEN af.id IS NOT NULL THEN
        coalesce(sf.path, '') || '/' || sf.file_name || '/' || af.path || '/' || af.file_name
        ELSE coalesce(sf.path, '') || '/' || sf.file_name
      END;

	END;
$$
;


--
-- Name: find_new_athena_ipa_records(character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.find_new_athena_ipa_records (event_name character varying) returns table (master_id integer, ipa_id bigint, event character varying) language plpgsql as $$
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
$$
;


--
-- Name: find_new_athena_sleep_records(character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.find_new_athena_sleep_records (event character varying) returns table (master_id integer, ipa_id integer) language plpgsql as $$
BEGIN
  RETURN QUERY
    SELECT distinct m.id, ipa.ipa_id, event
    FROM masters m
    INNER JOIN sleep.activity_log_ipa_assignments ipa
      ON m.id = ipa.master_id
      AND ipa.extra_log_type = event
    LEFT JOIN sync_statuses s
      ON from_db = 'athena-db'
      AND to_db = 'fphs-db'
      AND m.id = s.from_master_id
      AND ipa.ipa_id::varchar = s.external_id
      AND s.external_type = 'sleep_assignments'
      AND s.event = event
    WHERE
      (
        s.id IS NULL
        OR coalesce(s.select_status, '') NOT IN ('completed', 'already transferred')
        AND s.created_at < now() - interval '2 hours'
      )
    ;
END;
$$
;


--
-- Name: format_update_notes(character varying, character varying, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.format_update_notes (field_name character varying, old_val character varying, new_val character varying) returns character varying language plpgsql as $$
        DECLARE
          res VARCHAR;
        BEGIN
          res := '';
          old_val := lower(coalesce(old_val, '-')::varchar);
          new_val := lower(coalesce(new_val, '')::varchar);
          IF old_val <> new_val THEN 
            res := field_name;
            IF old_val <> '-' THEN
              res := res || ' from ' || old_val ;
            END IF;
            res := res || ' to ' || new_val || '; ';
          END IF;
          RETURN res;
        END;
      $$
;


--
-- Name: get_app_type_id_by_name(character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.get_app_type_id_by_name (app_type_name character varying) returns integer language plpgsql as $$
  DECLARE
    app_type_id INTEGER;
  BEGIN

    select id from app_types
    into app_type_id
    where name = app_type_name and (disabled is null or disabled = false)
    order by id asc
    limit 1;

    RETURN app_type_id;

  END;
$$
;


--
-- Name: get_user_ids_for_app_type_role(integer, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.get_user_ids_for_app_type_role (for_app_type_id integer, with_role_name character varying) returns integer[] language plpgsql as $$
  DECLARE
    user_ids INTEGER[];
  BEGIN

    select array_agg(ur.user_id)
    from user_roles ur
    inner join users u on ur.user_id = u.id
    into user_ids
    where
      role_name = with_role_name AND
      ur.app_type_id = for_app_type_id AND
      (ur.disabled is null or ur.disabled = false) AND
      (ur.disabled is null or u.disabled = false)
    ;

    RETURN user_ids;

  END;
$$
;


--
-- Name: handle_address_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.handle_address_update () returns trigger language plpgsql as $$
        BEGIN
          
          NEW.street := lower(NEW.street);
          NEW.street2 := lower(NEW.street2);
          NEW.street3 := lower(NEW.street3);
          NEW.city := lower(NEW.city);
          NEW.state := lower(NEW.state);
          NEW.zip := lower(NEW.zip);
          NEW.country := lower(NEW.country);
          NEW.postal_code := lower(NEW.postal_code);
          NEW.region := lower(NEW.region);
          NEW.source := lower(NEW.source);
          RETURN NEW;

        END;
    $$
;


--
-- Name: handle_delete(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.handle_delete () returns trigger language plpgsql as $$
      DECLARE
        latest_tracker tracker_history%ROWTYPE;
      BEGIN

        -- Find the most recent remaining item in tracker_history for the master/protocol pair,
        -- now that the target record has been deleted.
        -- tracker_id is the foreign key onto the trackers table master/protocol record.

        SELECT * INTO latest_tracker
          FROM tracker_history 
          WHERE tracker_id = OLD.tracker_id 
          ORDER BY event_date DESC NULLS last, updated_at DESC NULLS last LIMIT 1;

        IF NOT FOUND THEN
          -- No record was found in tracker_history for the master/protocol pair.
          -- Therefore there should be no corresponding trackers record either. Delete it.
          DELETE FROM trackers WHERE trackers.id = OLD.tracker_id;

        ELSE
          -- A record was found in tracker_history. Since it is the latest one for the master/protocol pair,
          -- just go ahead and update the corresponding record in trackers.
          UPDATE trackers 
            SET 
              event_date = latest_tracker.event_date, 
              sub_process_id = latest_tracker.sub_process_id, 
              protocol_event_id = latest_tracker.protocol_event_id, 
              item_id = latest_tracker.item_id, 
              item_type = latest_tracker.item_type, 
              updated_at = latest_tracker.updated_at, 
              notes = latest_tracker.notes, 
              user_id = latest_tracker.user_id
            WHERE trackers.id = OLD.tracker_id;

        END IF;


        RETURN OLD;

      END
    $$
;


--
-- Name: handle_player_contact_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.handle_player_contact_update () returns trigger language plpgsql as $$
        BEGIN
         

          NEW.rec_type := lower(NEW.rec_type);
          NEW.data := lower(NEW.data);
          NEW.source := lower(NEW.source);


          RETURN NEW;

        END;
    $$
;


--
-- Name: handle_player_info_before_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.handle_player_info_before_update () returns trigger language plpgsql as $$
        BEGIN
          NEW.first_name := lower(NEW.first_name);          
          NEW.last_name := lower(NEW.last_name);          
          NEW.middle_name := lower(NEW.middle_name);          
          NEW.nick_name := lower(NEW.nick_name);          
          NEW.college := lower(NEW.college);                    
          NEW.source := lower(NEW.source);
          RETURN NEW;

        END;
    $$
;


--
-- Name: handle_rc_cis_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.handle_rc_cis_update () returns trigger language plpgsql as $$
        DECLARE
          new_master_id integer;
          new_msid integer;
          updated_item_id integer;
          register_tracker boolean;
          update_notes VARCHAR;
          event_date DATE;
          track_p varchar;
          track_sp varchar;
          track_pe varchar;
          res_status varchar;
          
        BEGIN


          track_p := 'study';
          track_sp := 'CIS-received';
          track_pe := 'REDCap';

          register_tracker := FALSE;
          update_notes := '';
          res_status := NEW.status;

          event_date :=  NEW.time_stamp::date;

          IF coalesce(NEW.status,'') <> '' THEN

            IF NEW.status = 'create master' THEN

                IF NEW.master_id IS NOT NULL THEN
                  RAISE EXCEPTION 'Can not create a master when the master ID is already set. Review the linked Master record, or to create a new Master record clear the master_id first and try again.';
                END IF;


                SELECT MAX(msid) + 1 INTO new_msid FROM masters;
                
                INSERT INTO masters
                  (msid, created_at, updated_at, user_id)
                  VALUES 
                  (new_msid, now(), now(), NEW.user_id)
                  RETURNING id INTO new_master_id;

                INSERT INTO player_infos
                  (master_id, first_name, last_name, source, created_at, updated_at, user_id)
                  VALUES
                  (new_master_id, NEW.first_name, NEW.last_name, 'cis-redcap', now(), now(), NEW.user_id);
                
                register_tracker := TRUE;
                
            ELSE              
                SELECT id INTO new_master_id FROM masters WHERE id = NEW.master_id;
            END IF;
  
            IF NEW.status = 'update name' OR NEW.status = 'update all' OR NEW.status = 'create master' THEN  
                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;


                SELECT format_update_notes('first name', first_name, NEW.first_name) ||
                  format_update_notes('last name', last_name, NEW.last_name) ||
                  format_update_notes('middle name', middle_name, NEW.middle_name) ||
                  format_update_notes('nick name', nick_name, NEW.nick_name)
                INTO update_notes
                FROM player_infos
                WHERE master_id = new_master_id order by rank desc limit 1;

                UPDATE player_infos SET
                  master_id = new_master_id, first_name = NEW.first_name, last_name = NEW.last_name, 
                  middle_name = NEW.middle_name, nick_name = NEW.nick_name, 
                  source = 'cis-redcap', created_at = now(), updated_at = now(), user_id = NEW.user_id
                  WHERE master_id = new_master_id
                  RETURNING id INTO updated_item_id;
                

                PERFORM add_study_update_entry(new_master_id, 'updated', 'player info', event_date, update_notes, NEW.user_id, updated_item_id, 'PlayerInfo');

                register_tracker := TRUE;                
                res_status := 'updated name';
            END IF;

            IF NEW.status = 'update address' OR NEW.status = 'update all' OR NEW.status = 'create master' THEN  
                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;

                IF NEW.street IS NOT NULL AND trim(NEW.street) <> '' OR
                    NEW.state IS NOT NULL AND trim(NEW.state) <> '' OR
                    NEW.zipcode IS NOT NULL AND trim(NEW.zipcode) <> '' THEN   

                  SELECT format_update_notes('street', NULL, NEW.street) ||
                    format_update_notes('street2', NULL, NEW.street2) ||
                    format_update_notes('city', NULL, NEW.city) ||
                    format_update_notes('state', NULL, NEW.state) ||
                    format_update_notes('zip', NULL, NEW.zipcode)                  
                  INTO update_notes;
                  -- FROM addresses
                  -- WHERE master_id = new_master_id;


                  
                  INSERT INTO addresses
                    (master_id, street, street2, city, state, zip, source, rank, created_at, updated_at, user_id)
                    VALUES
                    (new_master_id, NEW.street, NEW.street2, NEW.city, NEW.state, NEW.zipcode, 'cis-redcap', 10, now(), now(), NEW.user_id)
                    RETURNING id INTO updated_item_id;
                  
                  PERFORM update_address_ranks(new_master_id);
                  PERFORM add_study_update_entry(new_master_id, 'updated', 'address', event_date, update_notes, NEW.user_id, updated_item_id, 'Address');

                  register_tracker := TRUE;
                  res_status := 'updated address';
                ELSE
                  res_status := 'address not updated - details blank';
                END IF;

                
            END IF;

            IF NEW.status = 'update email' OR NEW.status = 'update all' OR NEW.status = 'create master' THEN  

                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;

                IF NEW.email IS NOT NULL AND trim(NEW.email) <> '' THEN   

                  SELECT format_update_notes('data', NULL, NEW.email)           
                  INTO update_notes;                  


                  INSERT INTO player_contacts
                    (master_id, data, rec_type, source, rank, created_at, updated_at, user_id)
                    VALUES
                    (new_master_id, NEW.email, 'email', 'cis-redcap', 10, now(), now(), NEW.user_id)
                    RETURNING id INTO updated_item_id;


                  PERFORM update_player_contact_ranks(new_master_id, 'email');
                  PERFORM add_study_update_entry(new_master_id, 'updated', 'player contact', event_date, update_notes, NEW.user_id, updated_item_id, 'PlayerContact');

                  register_tracker := TRUE;
                  res_status := 'updated email';
                ELSE
                  res_status := 'email not updated - details blank';
                END IF;                
            END IF;

            IF NEW.status = 'update phone' OR NEW.status = 'update all' OR NEW.status = 'create master' THEN  
                IF new_master_id IS NULL THEN
                  RAISE EXCEPTION 'Must set a master ID to %', NEW.status;
                END IF;

                IF NEW.phone IS NOT NULL AND trim(NEW.phone) <> '' THEN   

                  SELECT format_update_notes('data', NULL, NEW.phone)           
                  INTO update_notes;                  

                  INSERT INTO player_contacts
                    (master_id, data, rec_type, source, rank, created_at, updated_at, user_id)
                    VALUES
                    (new_master_id, NEW.phone, 'phone', 'cis-redcap', 10, now(), now(), NEW.user_id)
                    RETURNING id INTO updated_item_id;

                  PERFORM update_player_contact_ranks(new_master_id, 'phone');
                  PERFORM add_study_update_entry(new_master_id, 'updated', 'player contact', event_date, update_notes, NEW.user_id, updated_item_id, 'PlayerContact');

                  register_tracker := TRUE;
                  res_status := 'updated phone';
                ELSE
                  res_status := 'phone not updated - details blank';
                END IF;
            END IF;
            

            CASE 
              WHEN NEW.status = 'create master' THEN 
                res_status := 'created master';
              WHEN NEW.status = 'update all' THEN 
                res_status := 'updated all';              
              ELSE
            END CASE;

            -- the master_id was set and an action performed. Register the tracker event
            IF coalesce(NEW.added_tracker, FALSE) = FALSE AND new_master_id IS NOT NULL AND register_tracker THEN
              PERFORM add_tracker_entry_by_name(new_master_id, track_p, track_sp, track_pe, OLD.time_stamp::date, ('Heard about: ' || coalesce(OLD.hearabout, '(not set)') || E'
Submitted by REDCap ID '|| OLD.redcap_survey_identifier), NEW.user_id, NULL, NULL);
              NEW.added_tracker = TRUE;
            END IF;

            NEW.master_id := new_master_id;
            NEW.updated_at := now();
            NEW.status := res_status;

          END IF;

          RETURN NEW;

        END;
    $$
;


--
-- Name: handle_tracker_history_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.handle_tracker_history_update () returns trigger language plpgsql as $$
    BEGIN
      
      DELETE FROM tracker_history WHERE id = OLD.id;
  
      INSERT INTO trackers 
        (master_id, protocol_id, 
         protocol_event_id, event_date, sub_process_id, notes,
         item_id, item_type,
         created_at, updated_at, user_id)

        SELECT NEW.master_id, NEW.protocol_id, 
           NEW.protocol_event_id, NEW.event_date, 
           NEW.sub_process_id, NEW.notes, 
           NEW.item_id, NEW.item_type,
           NEW.created_at, NEW.updated_at, NEW.user_id  ;

      RETURN NULL;
    END;
    $$
;


--
-- Name: ipa_ps_tmoca_score_calc(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.ipa_ps_tmoca_score_calc () returns trigger language plpgsql as $$
  BEGIN


    NEW.tmoca_score :=
      NEW.attn_digit_span +
      NEW.attn_digit_vigilance +
      NEW.attn_digit_calculation +
      NEW.language_repeat +
      NEW.language_fluency +
      NEW.abstraction +
      NEW.delayed_recall +
      NEW.orientation;

    RETURN NEW;
    
  END;
$$
;


--
-- Name: lock_transfer_records_with_external_ids(character varying, character varying, integer[], integer[], character varying, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.lock_transfer_records_with_external_ids (
  from_db character varying,
  to_db character varying,
  master_ids integer[],
  external_ids integer[],
  external_type character varying,
  event character varying
) returns integer language plpgsql as $$
BEGIN
  INSERT into sync_statuses
  ( from_master_id, external_id, external_type, from_db, to_db, event, select_status, created_at, updated_at )
  (
    SELECT unnest(master_ids), unnest(external_ids), external_type, from_db, to_db, event, 'new', now(), now()
  );

  RETURN 1;

END;
$$
;


--
-- Name: log_accuracy_score_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_accuracy_score_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO accuracy_score_history
            (
                    accuracy_score_id,
                    name ,
                    value ,                    
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id                      
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.value ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id                      
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_activity_log_bhs_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_bhs_assignment_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO activity_log_bhs_assignment_history
                  (
                      master_id,
                      bhs_assignment_id,
                      select_record_from_player_contact_phones,
                      return_call_availability_notes,
                      questions_from_call_notes,
                      results_link,
                      select_result,
                      pi_return_call_notes,
                      completed_q1_no_yes,
                      completed_teamstudy_no_yes,
                      previous_contact_with_team_no_yes,
                      previous_contact_with_team_notes,
                      notes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_bhs_assignment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.bhs_assignment_id,
                      NEW.select_record_from_player_contact_phones,
                      NEW.return_call_availability_notes,
                      NEW.questions_from_call_notes,
                      NEW.results_link,
                      NEW.select_result,
                      NEW.pi_return_call_notes,
                      NEW.completed_q1_no_yes,
                      NEW.completed_teamstudy_no_yes,
                      NEW.previous_contact_with_team_no_yes,
                      NEW.previous_contact_with_team_notes,
                      NEW.notes,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_activity_log_ext_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_ext_assignment_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO activity_log_ext_assignment_history
                  (
                      master_id,
                      ext_assignment_id,
                      do_when,
notes,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ext_assignment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ext_assignment_id,
                      NEW.do_when,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_activity_log_ipa_assignment_adverse_event_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_ipa_assignment_adverse_event_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_adverse_event_history
                  (
                      master_id,
                      ipa_assignment_id,
                      
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_adverse_event_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_activity_log_ipa_assignment_minor_deviation_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_ipa_assignment_minor_deviation_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_minor_deviation_history
                  (
                      master_id,
                      ipa_assignment_id,
                      activity_date,
                      deviation_discovered_when,
                      deviation_occurred_when,
                      deviation_description,
                      corrective_action_description,
                      select_status,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_minor_deviation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.activity_date,
                      NEW.deviation_discovered_when,
                      NEW.deviation_occurred_when,
                      NEW.deviation_description,
                      NEW.corrective_action_description,
                      NEW.select_status,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_activity_log_ipa_assignment_navigation_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_ipa_assignment_navigation_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO activity_log_ipa_assignment_navigation_history
            (
                master_id,
                ipa_assignment_id,
                event_date,
                select_station,
                arrival_time,
                start_time,
                event_notes,
                completion_time,
                participant_feedback_notes,
                other_navigator_notes,
                add_protocol_deviation_record_no_yes,
                add_adverse_event_record_no_yes,
                select_event_type,
                other_event_type,
                select_status,
                extra_log_type,
                user_id,
                created_at,
                updated_at,
                activity_log_ipa_assignment_navigation_id
                )
            SELECT
                NEW.master_id,
                NEW.ipa_assignment_id,
                NEW.event_date,
                NEW.select_station,
                NEW.arrival_time,
                NEW.start_time,
                NEW.event_notes,
                NEW.completion_time,
                NEW.participant_feedback_notes,
                NEW.other_navigator_notes,
                NEW.add_protocol_deviation_record_no_yes,
                NEW.add_adverse_event_record_no_yes,
                NEW.select_event_type,
                NEW.other_event_type,
                NEW.select_status,
                NEW.extra_log_type,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_activity_log_ipa_assignment_phone_screen_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_ipa_assignment_phone_screen_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_phone_screen_history
                  (
                      master_id,
                      ipa_assignment_id,
                      callback_required,
                      callback_date,
                      callback_time,
                      notes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_phone_screen_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.callback_required,
                      NEW.callback_date,
                      NEW.callback_time,
                      NEW.notes,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_activity_log_ipa_assignment_post_visit_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_ipa_assignment_post_visit_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_post_visit_history
                  (
                      master_id,
                      ipa_assignment_id,
                      select_activity,
                      activity_date,
                      select_record_from_player_contacts,
                      select_record_from_addresses,
                      select_direction,
                      select_who,
                      select_result,
                      select_next_step,
                      follow_up_when,
                      follow_up_time,
                      notes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_post_visit_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.select_activity,
                      NEW.activity_date,
                      NEW.select_record_from_player_contacts,
                      NEW.select_record_from_addresses,
                      NEW.select_direction,
                      NEW.select_who,
                      NEW.select_result,
                      NEW.select_next_step,
                      NEW.follow_up_when,
                      NEW.follow_up_time,
                      NEW.notes,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_activity_log_ipa_assignment_protocol_deviation_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_ipa_assignment_protocol_deviation_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_protocol_deviation_history
                  (
                      master_id,
                      ipa_assignment_id,
                      
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_protocol_deviation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_activity_log_ipa_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_ipa_assignment_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_history
                  (
                      master_id,
                      ipa_assignment_id,
                      select_activity,
                      activity_date,
                      select_record_from_player_contacts,
                      select_direction,
                      select_who,
                      select_result,
                      select_next_step,
                      follow_up_when,
                      follow_up_time,
                      notes,
                      protocol_id,
                      select_record_from_addresses,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.select_activity,
                      NEW.activity_date,
                      NEW.select_record_from_player_contacts,
                      NEW.select_direction,
                      NEW.select_who,
                      NEW.select_result,
                      NEW.select_next_step,
                      NEW.follow_up_when,
                      NEW.follow_up_time,
                      NEW.notes,
                      NEW.protocol_id,
                      NEW.select_record_from_addresses,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_activity_log_ipa_survey_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_ipa_survey_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO activity_log_ipa_survey_history
                  (
                      master_id,
                      ipa_survey_id,
                      screened_by_who,
                      screening_date,
                      select_status,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_survey_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_survey_id,
                      NEW.screened_by_who,
                      NEW.screening_date,
                      NEW.select_status,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_activity_log_new_test_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_new_test_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO activity_log_new_test_history
                  (
                      master_id,
                      new_test_id,
                      done_when,
                      select_result,
                      notes,
                      protocol_id,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_new_test_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.new_test_id,
                      NEW.done_when,
                      NEW.select_result,
                      NEW.notes,
                      NEW.protocol_id,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_activity_log_player_contact_phone_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_player_contact_phone_update () returns trigger language plpgsql as $$
                BEGIN
                    INSERT INTO activity_log_player_contact_phone_history
                    (
                        master_id,
                        player_contact_id,
                        data,
                        select_call_direction,
                        select_who,
                        called_when,
                        select_result,
                        select_next_step,
                        follow_up_when,
                        notes,
                        protocol_id,
                        set_related_player_contact_rank,
                        extra_log_type,
                        user_id,
                        created_at,
                        updated_at,
                        activity_log_player_contact_phone_id
                        )
                    SELECT
                        NEW.master_id,
                        NEW.player_contact_id,
                        NEW.data,
                        NEW.select_call_direction,
                        NEW.select_who,
                        NEW.called_when,
                        NEW.select_result,
                        NEW.select_next_step,
                        NEW.follow_up_when,
                        NEW.notes,
                        NEW.protocol_id,
                        NEW.set_related_player_contact_rank,
                        NEW.extra_log_type,
                        NEW.user_id,
                        NEW.created_at,
                        NEW.updated_at,
                        NEW.id
                    ;
                    RETURN NEW;
                END;
            $$
;


--
-- Name: log_activity_log_player_info_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_player_info_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO activity_log_player_info_history
                  (
                      master_id,
                      player_info_id,
                      done_when,
                      notes,
                      protocol_id,
                      select_who,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_player_info_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.player_info_id,
                      NEW.done_when,
                      NEW.notes,
                      NEW.protocol_id,
                      NEW.select_who,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_activity_log_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_activity_log_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO activity_log_history
            (
                name,
                activity_log_id,
                admin_id,
                created_at,
                updated_at,
                item_type,
                rec_type,
                disabled,
                action_when_attribute,
                field_list,
                blank_log_field_list,
                blank_log_name,
                extra_log_types,
                hide_item_list_panel,
                main_log_name,
                process_name,
                table_name,
                category,
                schema_name
                )
            SELECT
                NEW.name,
                NEW.id,
                NEW.admin_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.item_type,
                NEW.rec_type,
                NEW.disabled,
                NEW.action_when_attribute,
                NEW.field_list,
                NEW.blank_log_field_list,
                NEW.blank_log_name,
                NEW.extra_log_types,
                NEW.hide_item_list_panel,
                NEW.main_log_name,
                NEW.process_name,
                NEW.table_name,
                NEW.category,
                NEW.schema_name
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_address_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_address_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO address_history 
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
                    updated_at,
                    country,
                    postal_code,
                    region,
                    address_id
                )
                 
            SELECT                 
                NEW.master_id,
                NEW.street,
                NEW.street2,
                NEW.street3,
                NEW.city,
                NEW.state,
                NEW.zip,
                NEW.source,
                NEW.rank,
                NEW.rec_type,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.country,
                NEW.postal_code,
                NEW.region,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_admin_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_admin_update () returns trigger language plpgsql as $$
    BEGIN
      INSERT INTO admin_history
      (
        admin_id,
        email,
        encrypted_password,
        sign_in_count,
        current_sign_in_at,
        last_sign_in_at,
        current_sign_in_ip ,
        last_sign_in_ip ,
        created_at ,
        updated_at,
        failed_attempts,
        unlock_token,
        locked_at,
        disabled,
        consumed_timestep,
        otp_required_for_login,
        reset_password_sent_at,
        password_updated_at,
        updated_by_admin_id,
        first_name,
        last_name,
        do_not_email,
        capabilities,
        otp_secret
      )
      SELECT
        NEW.id,
        NEW.email,
        NEW.encrypted_password,
        NEW.sign_in_count,
        NEW.current_sign_in_at,
        NEW.last_sign_in_at,
        NEW.current_sign_in_ip ,
        NEW.last_sign_in_ip ,
        NEW.created_at ,
        NEW.updated_at,
        NEW.failed_attempts,
        NEW.unlock_token,
        NEW.locked_at,
        NEW.disabled,
        NEW.consumed_timestep,
        NEW.otp_required_for_login,
        NEW.reset_password_sent_at,
        NEW.password_updated_at,
        NEW.admin_id,
        NEW.first_name,
        NEW.last_name,
        NEW.do_not_email,
        NEW.capabilities,
        NEW.otp_secret
        ;
        RETURN NEW;
    END;
    $$
;


--
-- Name: log_bhs_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_bhs_assignment_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO bhs_assignment_history
                  (
                      master_id,
                      bhs_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      bhs_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.bhs_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_college_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_college_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO college_history
            (
                    college_id,
                    name ,
                    synonym_for_id,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id,
                    user_id            
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.synonym_for_id ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id,
                    NEW.user_id
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_config_library_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_config_library_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO config_library_history
            (
                    config_library_id,
                    category,
                    name,
                    options,
                    format,
                    disabled,
                    admin_id,
                    updated_at,
                    created_at
                )
            SELECT
                NEW.id,
                NEW.category,
                NEW.name,
                NEW.options,
                NEW.format,
                NEW.disabled,
                NEW.admin_id,
                NEW.updated_at,
                NEW.created_at
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_dynamic_model_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_dynamic_model_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO dynamic_model_history
            (
                    dynamic_model_id,
                    name,                    
                    table_name, 
                    schema_name,
                    primary_key_name,
                    foreign_key_name,
                    description,
                    admin_id,
                    disabled,                    
                    created_at,
                    updated_at,
                    position,
                    category,
                    table_key_name,
                    field_list,
                    result_order,
                    options
                    
                )                 
            SELECT                 
                NEW.id,
                                    NEW.name,    
                    NEW.table_name, 
                    NEW.schema_name,
                    NEW.primary_key_name,
                    NEW.foreign_key_name,
                    NEW.description,
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.position,
                    NEW.category,
                    NEW.table_key_name,
                    NEW.field_list,
                    NEW.result_order,
                    NEW.options
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_ext_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ext_assignment_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ext_assignment_history
                  (
                      master_id,
                      ext_id,
                      user_id,
                      created_at,
                      updated_at,
                      ext_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ext_id,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ext_gen_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ext_gen_assignment_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ext_gen_assignment_history
                  (
                      master_id,
                      ext_gen_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      ext_gen_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ext_gen_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_external_identifier_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_external_identifier_update () returns trigger language plpgsql as $$
      BEGIN
          INSERT INTO external_identifier_history
          (
              name,
              label,
              external_id_attribute,
              external_id_view_formatter,
              external_id_edit_pattern,
              prevent_edit,
              pregenerate_ids,
              min_id,
              max_id,
              alphanumeric,
              extra_fields,
              admin_id,
              disabled,
              created_at,
              updated_at,
              external_identifier_id,
              schema_name,
              options
              )
          SELECT
              NEW.name,
              NEW.label,
              NEW.external_id_attribute,
              NEW.external_id_view_formatter,
              NEW.external_id_edit_pattern,
              NEW.prevent_edit,
              NEW.pregenerate_ids,
              NEW.min_id,
              NEW.max_id,
              NEW.alphanumeric,
              NEW.extra_fields,
              NEW.admin_id,
              NEW.disabled,
              NEW.created_at,
              NEW.updated_at,
              NEW.id,
              NEW.schema_name,
              NEW.options
          ;
          RETURN NEW;
      END;
  $$
;


--
-- Name: log_external_link_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_external_link_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO external_link_history
            (
                    external_link_id,                    
                    name,                    
                    value,
                    admin_id,
                    disabled,                    
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.name,    
                    NEW.value,                     
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_general_selection_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_general_selection_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO general_selection_history
            (
                    general_selection_id,
                    name ,
                    value ,
                    item_type ,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id ,
                    create_with ,
                    edit_if_set ,
                    edit_always ,
                    position ,
                    description ,
                    lock 
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                NEW.value ,
                NEW.item_type ,
                NEW.created_at ,
                NEW.updated_at ,
                NEW.disabled ,
                NEW.admin_id ,
                NEW.create_with ,
                NEW.edit_if_set ,
                NEW.edit_always ,
                NEW.position "position",
                NEW.description ,
                NEW.lock
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_ipa_adl_informant_screener_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_adl_informant_screener_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_adl_informant_screener_history
                  (
                      master_id,
                      select_regarding_eating,
                      select_regarding_walking,
                      select_regarding_bowel_and_bladder,
                      select_regarding_bathing,
                      select_regarding_grooming,
                      select_regarding_dressing,
                      select_regarding_dressing_performance,
                      select_regarding_getting_dressed,
                      used_telephone_yes_no_dont_know,
                      select_telephone_performance,
                      watched_tv_yes_no_dont_know,
                      selected_programs_yes_no_dont_know,
                      talk_about_content_during_yes_no_dont_know,
                      talk_about_content_after_yes_no_dont_know,
                      pay_attention_to_conversation_yes_no_dont_know,
                      select_degree_of_participation,
                      clear_dishes_yes_no_dont_know,
                      select_clear_dishes_performance,
                      find_personal_belongings_yes_no_dont_know,
                      select_find_personal_belongings_performance,
                      obtain_beverage_yes_no_dont_know,
                      select_obtain_beverage_performance,
                      make_meal_yes_no_dont_know,
                      select_make_meal_performance,
                      dispose_of_garbage_yes_no_dont_know,
                      select_dispose_of_garbage_performance,
                      get_around_outside_yes_no_dont_know,
                      select_get_around_outside_performance,
                      go_shopping_yes_no_dont_know,
                      select_go_shopping_performance,
                      pay_for_items_yes_no_dont_know,
                      keep_appointments_yes_no_dont_know,
                      select_keep_appointments_performance,
                      left_on_own_yes_no_dont_know,
                      away_from_home_yes_no_dont_know,
                      at_home_more_than_hour_yes_no_dont_know,
                      at_home_less_than_hour_yes_no_dont_know,
                      talk_about_current_events_yes_no_dont_know,
                      did_not_take_part_in_yes_no_dont_know,
                      took_part_in_outside_home_yes_no_dont_know,
                      took_part_in_at_home_yes_no_dont_know,
                      read_yes_no_dont_know,
                      talk_about_reading_shortly_after_yes_no_dont_know,
                      talk_about_reading_later_yes_no_dont_know,
                      write_yes_no_dont_know,
                      select_write_performance,
                      pastime_yes_no_dont_know,
                      multi_select_pastimes,
                      pastime_other,
                      pastimes_only_at_daycare_no_yes,
                      select_pastimes_only_at_daycare_performance,
                      use_household_appliance_yes_no_dont_know,
                      multi_select_household_appliances,
                      household_appliance_other,
                      select_household_appliance_performance,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_adl_informant_screener_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_regarding_eating,
                      NEW.select_regarding_walking,
                      NEW.select_regarding_bowel_and_bladder,
                      NEW.select_regarding_bathing,
                      NEW.select_regarding_grooming,
                      NEW.select_regarding_dressing,
                      NEW.select_regarding_dressing_performance,
                      NEW.select_regarding_getting_dressed,
                      NEW.used_telephone_yes_no_dont_know,
                      NEW.select_telephone_performance,
                      NEW.watched_tv_yes_no_dont_know,
                      NEW.selected_programs_yes_no_dont_know,
                      NEW.talk_about_content_during_yes_no_dont_know,
                      NEW.talk_about_content_after_yes_no_dont_know,
                      NEW.pay_attention_to_conversation_yes_no_dont_know,
                      NEW.select_degree_of_participation,
                      NEW.clear_dishes_yes_no_dont_know,
                      NEW.select_clear_dishes_performance,
                      NEW.find_personal_belongings_yes_no_dont_know,
                      NEW.select_find_personal_belongings_performance,
                      NEW.obtain_beverage_yes_no_dont_know,
                      NEW.select_obtain_beverage_performance,
                      NEW.make_meal_yes_no_dont_know,
                      NEW.select_make_meal_performance,
                      NEW.dispose_of_garbage_yes_no_dont_know,
                      NEW.select_dispose_of_garbage_performance,
                      NEW.get_around_outside_yes_no_dont_know,
                      NEW.select_get_around_outside_performance,
                      NEW.go_shopping_yes_no_dont_know,
                      NEW.select_go_shopping_performance,
                      NEW.pay_for_items_yes_no_dont_know,
                      NEW.keep_appointments_yes_no_dont_know,
                      NEW.select_keep_appointments_performance,
                      NEW.left_on_own_yes_no_dont_know,
                      NEW.away_from_home_yes_no_dont_know,
                      NEW.at_home_more_than_hour_yes_no_dont_know,
                      NEW.at_home_less_than_hour_yes_no_dont_know,
                      NEW.talk_about_current_events_yes_no_dont_know,
                      NEW.did_not_take_part_in_yes_no_dont_know,
                      NEW.took_part_in_outside_home_yes_no_dont_know,
                      NEW.took_part_in_at_home_yes_no_dont_know,
                      NEW.read_yes_no_dont_know,
                      NEW.talk_about_reading_shortly_after_yes_no_dont_know,
                      NEW.talk_about_reading_later_yes_no_dont_know,
                      NEW.write_yes_no_dont_know,
                      NEW.select_write_performance,
                      NEW.pastime_yes_no_dont_know,
                      NEW.multi_select_pastimes,
                      NEW.pastime_other,
                      NEW.pastimes_only_at_daycare_no_yes,
                      NEW.select_pastimes_only_at_daycare_performance,
                      NEW.use_household_appliance_yes_no_dont_know,
                      NEW.multi_select_household_appliances,
                      NEW.household_appliance_other,
                      NEW.select_household_appliance_performance,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_adverse_event_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_adverse_event_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_adverse_event_history
                  (
                      master_id,
                      select_problem_type,
                      event_occurred_when,
                      event_discovered_when,
                      select_severity,
                      select_location,
                      select_expectedness,
                      select_relatedness,
                      event_description,
                      corrective_action_description,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_adverse_event_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_problem_type,
                      NEW.event_occurred_when,
                      NEW.event_discovered_when,
                      NEW.select_severity,
                      NEW.select_location,
                      NEW.select_expectedness,
                      NEW.select_relatedness,
                      NEW.event_description,
                      NEW.corrective_action_description,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_appointment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_appointment_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_appointment_history
                  (
                      master_id,
                      visit_start_date,
                      select_navigator,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_appointment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.visit_start_date,
                      NEW.select_navigator,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_assignment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_assignment_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_assignment_history
                  (
                      master_id,
                      ipa_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      ipa_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_consent_mailing_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_consent_mailing_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_consent_mailing_history
                  (
                      master_id,
                      select_record_from_player_contact_email,
                      select_record_from_addresses,
                      sent_when,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_consent_mailing_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_record_from_player_contact_email,
                      NEW.select_record_from_addresses,
                      NEW.sent_when,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_hotel_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_hotel_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_hotel_history
                  (
                      master_id,
                      hotel,
                      room_number,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_hotel_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.hotel,
                      NEW.room_number,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_inex_checklist_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_inex_checklist_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_inex_checklist_history
                  (
                      master_id,
                      fixed_checklist_type,
                      ix_consent_blank_yes_no,
                      ix_consent_details,
                      ix_not_pro_blank_yes_no,
                      ix_not_pro_details,
                      ix_age_range_blank_yes_no,
                      ix_age_range_details,
                      ix_weight_ok_blank_yes_no,
                      ix_weight_ok_details,
                      ix_no_seizure_blank_yes_no,
                      ix_no_seizure_details,
                      ix_no_device_impl_blank_yes_no,
                      ix_no_device_impl_details,
                      ix_no_ferromagnetic_impl_blank_yes_no,
                      ix_no_ferromagnetic_impl_details,
                      ix_diagnosed_sleep_apnea_blank_yes_no,
                      ix_diagnosed_sleep_apnea_details,
                      ix_diagnosed_heart_stroke_or_meds_blank_yes_no,
                      ix_diagnosed_heart_stroke_or_meds_details,
                      ix_chronic_pain_and_meds_blank_yes_no,
                      ix_chronic_pain_and_meds_details,
                      ix_tmoca_score_blank_yes_no,
                      ix_tmoca_score_details,
                      ix_no_hemophilia_blank_yes_no,
                      ix_no_hemophilia_details,
                      ix_raynauds_ok_blank_yes_no,
                      ix_raynauds_ok_details,
                      ix_mi_ok_blank_yes_no,
                      ix_mi_ok_details,
                      ix_bicycle_ok_blank_yes_no,
                      ix_bicycle_ok_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_inex_checklist_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.fixed_checklist_type,
                      NEW.ix_consent_blank_yes_no,
                      NEW.ix_consent_details,
                      NEW.ix_not_pro_blank_yes_no,
                      NEW.ix_not_pro_details,
                      NEW.ix_age_range_blank_yes_no,
                      NEW.ix_age_range_details,
                      NEW.ix_weight_ok_blank_yes_no,
                      NEW.ix_weight_ok_details,
                      NEW.ix_no_seizure_blank_yes_no,
                      NEW.ix_no_seizure_details,
                      NEW.ix_no_device_impl_blank_yes_no,
                      NEW.ix_no_device_impl_details,
                      NEW.ix_no_ferromagnetic_impl_blank_yes_no,
                      NEW.ix_no_ferromagnetic_impl_details,
                      NEW.ix_diagnosed_sleep_apnea_blank_yes_no,
                      NEW.ix_diagnosed_sleep_apnea_details,
                      NEW.ix_diagnosed_heart_stroke_or_meds_blank_yes_no,
                      NEW.ix_diagnosed_heart_stroke_or_meds_details,
                      NEW.ix_chronic_pain_and_meds_blank_yes_no,
                      NEW.ix_chronic_pain_and_meds_details,
                      NEW.ix_tmoca_score_blank_yes_no,
                      NEW.ix_tmoca_score_details,
                      NEW.ix_no_hemophilia_blank_yes_no,
                      NEW.ix_no_hemophilia_details,
                      NEW.ix_raynauds_ok_blank_yes_no,
                      NEW.ix_raynauds_ok_details,
                      NEW.ix_mi_ok_blank_yes_no,
                      NEW.ix_mi_ok_details,
                      NEW.ix_bicycle_ok_blank_yes_no,
                      NEW.ix_bicycle_ok_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_initial_screening_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_initial_screening_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_initial_screening_history
                  (
                      master_id,
                      select_is_good_time_to_speak,
                      select_looked_at_website_yes_no,
                      select_may_i_begin,
                      any_questions_blank_yes_no,
                      select_still_interested,
                      follow_up_date,
                      follow_up_time,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_initial_screening_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_is_good_time_to_speak,
                      NEW.select_looked_at_website_yes_no,
                      NEW.select_may_i_begin,
                      NEW.any_questions_blank_yes_no,
                      NEW.select_still_interested,
                      NEW.follow_up_date,
                      NEW.follow_up_time,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_payment_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_payment_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_payment_history
                  (
                      master_id,
                      select_type,
                      sent_date,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_payment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_type,
                      NEW.sent_date,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_protocol_deviation_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_protocol_deviation_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_protocol_deviation_history
                  (
                      master_id,
                      deviation_occurred_when,
                      deviation_discovered_when,
                      select_severity,
                      deviation_description,
                      corrective_action_description,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_protocol_deviation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.deviation_occurred_when,
                      NEW.deviation_discovered_when,
                      NEW.select_severity,
                      NEW.deviation_description,
                      NEW.corrective_action_description,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_ps_football_experience_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_ps_football_experience_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_ps_football_experience_history
                  (
                      master_id,
                      age,
                      played_in_nfl_blank_yes_no,
                      played_before_nfl_blank_yes_no,
                      football_experience_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_football_experience_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.age,
                      NEW.played_in_nfl_blank_yes_no,
                      NEW.played_before_nfl_blank_yes_no,
                      NEW.football_experience_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_ps_health_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_ps_health_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_ps_health_history
                  (
                      master_id,
                      physical_limitations_blank_yes_no,
                      physical_limitations_details,
                      sit_back_blank_yes_no,
                      sit_back_details,
                      cycle_blank_yes_no,
                      cycle_details,
                      chronic_pain_blank_yes_no,
                      chronic_pain_details,
                      chronic_pain_meds_blank_yes_no_dont_know,
                      chronic_pain_meds_details,
                      hemophilia_blank_yes_no_dont_know,
                      hemophilia_details,
                      raynauds_syndrome_blank_yes_no_dont_know,
                      raynauds_syndrome_severity_selection,
                      raynauds_syndrome_details,

                      hypertension_diagnosis_blank_yes_no_dont_know,
                      hypertension_medications_blank_yes_no,
                      hypertension_diagnosis_details,

                      diabetes_diagnosis_blank_yes_no_dont_know,
                      diabetes_medications_blank_yes_no,
                      diabetes_diagnosis_details,

                      high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      high_cholesterol_medications_blank_yes_no,
                      high_cholesterol_diagnosis_details,

                      other_heart_conditions_blank_yes_no_dont_know,
                      other_heart_conditions_details,

                      heart_surgeries_blank_yes_no_dont_know,
                      heart_surgeries_details,
                      caridiac_pacemaker_blank_yes_no_dont_know,
                      caridiac_pacemaker_details,

                      memory_problems_blank_yes_no_dont_know,
                      memory_problems_details,
                      mental_health_conditions_blank_yes_no_dont_know,
                      mental_health_conditions_details,

                      mental_health_help_blank_yes_no_dont_know,
                      mental_health_help_details,

                      neurological_problems_blank_yes_no_dont_know,
                      neurological_problems_details,

                      neurological_surgeries_blank_yes_no_dont_know,
                      neurological_surgeries_details,

                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_health_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.physical_limitations_blank_yes_no,
                      NEW.physical_limitations_details,
                      NEW.sit_back_blank_yes_no,
                      NEW.sit_back_details,
                      NEW.cycle_blank_yes_no,
                      NEW.cycle_details,
                      NEW.chronic_pain_blank_yes_no,
                      NEW.chronic_pain_details,
                      NEW.chronic_pain_meds_blank_yes_no_dont_know,
                      NEW.chronic_pain_meds_details,
                      NEW.hemophilia_blank_yes_no_dont_know,
                      NEW.hemophilia_details,
                      NEW.raynauds_syndrome_blank_yes_no_dont_know,
                      NEW.raynauds_syndrome_severity_selection,
                      NEW.raynauds_syndrome_details,

                      NEW.hypertension_diagnosis_blank_yes_no_dont_know,
                      NEW.hypertension_medications_blank_yes_no,
                      NEW.hypertension_diagnosis_details,

                      NEW.diabetes_diagnosis_blank_yes_no_dont_know,
                      NEW.diabetes_medications_blank_yes_no,
                      NEW.diabetes_diagnosis_details,

                      NEW.high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      NEW.high_cholesterol_medications_blank_yes_no,
                      NEW.high_cholesterol_diagnosis_details,

                      NEW.other_heart_conditions_blank_yes_no_dont_know,
                      NEW.other_heart_conditions_details,

                      NEW.heart_surgeries_blank_yes_no_dont_know,
                      NEW.heart_surgeries_details,
                      NEW.caridiac_pacemaker_blank_yes_no_dont_know,
                      NEW.caridiac_pacemaker_details,

                      NEW.memory_problems_blank_yes_no_dont_know,
                      NEW.memory_problems_details,
                      NEW.mental_health_conditions_blank_yes_no_dont_know,
                      NEW.mental_health_conditions_details,

                      NEW.mental_health_help_blank_yes_no_dont_know,
                      NEW.mental_health_help_details,

                      NEW.neurological_problems_blank_yes_no_dont_know,
                      NEW.neurological_problems_details,

                      NEW.neurological_surgeries_blank_yes_no_dont_know,
                      NEW.neurological_surgeries_details,

                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_ps_initial_screening_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_ps_initial_screening_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_ps_initial_screening_history
                  (
                      master_id,
                      select_is_good_time_to_speak,
                      looked_at_website_yes_no,
                      select_may_i_begin,
                      any_questions_blank_yes_no,
                      --- Note we retain select_still_interested since it is used in the withdrawal logic
                      select_still_interested,
                      follow_up_date,
                      follow_up_time,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_initial_screening_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_is_good_time_to_speak,
                      NEW.looked_at_website_yes_no,
                      NEW.select_may_i_begin,
                      NEW.any_questions_blank_yes_no,
                      NEW.select_still_interested,
                      NEW.follow_up_date,
                      NEW.follow_up_time,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_ps_mri_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_ps_mri_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_ps_mri_history
                  (
                      master_id,
                      past_mri_yes_no_dont_know,
                      past_mri_details,
                      electrical_implants_blank_yes_no_dont_know,
                      electrical_implants_details,
                      metal_implants_blank_yes_no_dont_know,
                      metal_implants_details,
                      metal_jewelry_blank_yes_no,
                      hearing_aid_blank_yes_no,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_mri_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.past_mri_yes_no_dont_know,
                      NEW.past_mri_details,
                      NEW.electrical_implants_blank_yes_no_dont_know,
                      NEW.electrical_implants_details,
                      NEW.metal_implants_blank_yes_no_dont_know,
                      NEW.metal_implants_details,
                      NEW.metal_jewelry_blank_yes_no,
                      NEW.hearing_aid_blank_yes_no,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_ps_size_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_ps_size_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_ps_size_history
                  (
                      master_id,
                      birth_date,
                      weight,
                      height,
                      hat_size,
                      shirt_size,
                      jacket_size,
                      waist_size,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_size_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.birth_date,
                      NEW.weight,
                      NEW.height,
                      NEW.hat_size,
                      NEW.shirt_size,
                      NEW.jacket_size,
                      NEW.waist_size,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_ps_sleep_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_ps_sleep_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_ps_sleep_history
                  (
                      master_id,
                      sleep_disorder_blank_yes_no_dont_know,
                      sleep_disorder_details,
                      sleep_apnea_device_no_yes,
                      sleep_apnea_device_details,
                      bed_and_wake_time_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_sleep_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.sleep_disorder_blank_yes_no_dont_know,
                      NEW.sleep_disorder_details,
                      NEW.sleep_apnea_device_no_yes,
                      NEW.sleep_apnea_device_details,
                      NEW.bed_and_wake_time_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_ps_tmoca_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_ps_tmoca_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_ps_tmoca_history
                  (
                      master_id,
                      tmoca_version,
                      attn_digit_span,
                      attn_digit_vigilance,
                      attn_digit_calculation,
                      language_repeat,
                      language_fluency,
                      abstraction,
                      delayed_recall,
                      orientation,
                      tmoca_score,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_tmoca_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.tmoca_version,
                      NEW.attn_digit_span,
                      NEW.attn_digit_vigilance,
                      NEW.attn_digit_calculation,
                      NEW.language_repeat,
                      NEW.language_fluency,
                      NEW.abstraction,
                      NEW.delayed_recall,
                      NEW.orientation,
                      NEW.tmoca_score,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
            END;
          $$
;


--
-- Name: log_ipa_ps_tms_test_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_ps_tms_test_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_ps_tms_test_history
                  (
                      master_id,
                      convulsion_or_seizure_blank_yes_no_dont_know,
                      epilepsy_blank_yes_no_dont_know,
                      fainting_blank_yes_no_dont_know,
                      concussion_blank_yes_no_dont_know,
                      loss_of_conciousness_details,
                      hearing_problems_blank_yes_no_dont_know,
                      cochlear_implants_blank_yes_no_dont_know,
                      metal_blank_yes_no_dont_know,
                      metal_details,
                      neurostimulator_blank_yes_no_dont_know,
                      neurostimulator_details,
                      med_infusion_device_blank_yes_no_dont_know,
                      med_infusion_device_details,
                      past_tms_blank_yes_no_dont_know,
                      past_tms_details,
                      current_meds_blank_yes_no_dont_know,
                      current_meds_details,
                      other_chronic_problems_blank_yes_no_dont_know,
                      other_chronic_problems_details,
                      hospital_visits_blank_yes_no_dont_know,
                      hospital_visits_details,
                      dietary_restrictions_blank_yes_no_dont_know,
                      dietary_restrictions_details,
                      anything_else_blank_yes_no,
                      anything_else_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_tms_test_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.convulsion_or_seizure_blank_yes_no_dont_know,
                      NEW.epilepsy_blank_yes_no_dont_know,
                      NEW.fainting_blank_yes_no_dont_know,
                      NEW.concussion_blank_yes_no_dont_know,
                      NEW.loss_of_conciousness_details,
                      NEW.hearing_problems_blank_yes_no_dont_know,
                      NEW.cochlear_implants_blank_yes_no_dont_know,
                      NEW.metal_blank_yes_no_dont_know,
                      NEW.metal_details,
                      NEW.neurostimulator_blank_yes_no_dont_know,
                      NEW.neurostimulator_details,
                      NEW.med_infusion_device_blank_yes_no_dont_know,
                      NEW.med_infusion_device_details,
                      NEW.past_tms_blank_yes_no_dont_know,
                      NEW.past_tms_details,
                      NEW.current_meds_blank_yes_no_dont_know,
                      NEW.current_meds_details,
                      NEW.other_chronic_problems_blank_yes_no_dont_know,
                      NEW.other_chronic_problems_details,
                      NEW.hospital_visits_blank_yes_no_dont_know,
                      NEW.hospital_visits_details,
                      NEW.dietary_restrictions_blank_yes_no_dont_know,
                      NEW.dietary_restrictions_details,
                      NEW.anything_else_blank_yes_no,
                      NEW.anything_else_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_screening_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_screening_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_screening_history
                  (
                      master_id,
                      eligible_for_study_blank_yes_no,
                      requires_study_partner_blank_yes_no,
                      notes,
                      good_time_to_speak_blank_yes_no,
                      callback_date,
                      callback_time,
                      still_interested_blank_yes_no,
                      not_interested_notes,
                      ineligible_notes,
                      eligible_notes,
                      contact_in_future_yes_no,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_screening_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.eligible_for_study_blank_yes_no,
                      NEW.requires_study_partner_blank_yes_no,
                      NEW.notes,
                      NEW.good_time_to_speak_blank_yes_no,
                      NEW.callback_date,
                      NEW.callback_time,
                      NEW.still_interested_blank_yes_no,
                      NEW.not_interested_notes,
                      NEW.ineligible_notes,
                      NEW.eligible_notes,
                      NEW.contact_in_future_yes_no,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_station_contact_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_station_contact_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_station_contact_history
                  (
                      first_name,
                      last_name,
                      role,
                      select_availability,
                      phone,
                      alt_phone,
                      email,
                      alt_email,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_station_contact_id
                      )
                  SELECT
                      NEW.first_name,
                      NEW.last_name,
                      NEW.role,
                      NEW.phone,
                      NEW.select_availability,
                      NEW.alt_phone,
                      NEW.email,
                      NEW.alt_email,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_survey_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_survey_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_survey_history
                  (
                      master_id,
                      select_survey_type,
                      sent_date,
                      completed_date,
                      send_next_survey_when,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_survey_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_survey_type,
                      NEW.sent_date,
                      NEW.completed_date,
                      NEW.send_next_survey_when,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_transportation_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_transportation_update () returns trigger language plpgsql as $$
              BEGIN
                  INSERT INTO ipa_transportation_history
                  (
                      master_id,
                      travel_date,
                      travel_confirmed_no_yes,
                      select_direction,
                      origin_city_and_state,
                      destination_city_and_state,
                      select_mode_of_transport,
                      airline,
                      flight_number,
                      departure_time,
                      arrival_time,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_transportation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.travel_date,
                      NEW.travel_confirmed_no_yes,
                      NEW.select_direction,
                      NEW.origin_city_and_state,
                      NEW.destination_city_and_state,
                      NEW.select_mode_of_transport,
                      NEW.airline,
                      NEW.flight_number,
                      NEW.departure_time,
                      NEW.arrival_time,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$
;


--
-- Name: log_ipa_withdrawal_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_ipa_withdrawal_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO ipa_withdrawal_history
            (
                master_id,
                select_subject_withdrew_reason,
                select_investigator_terminated,
                lost_to_follow_up_no_yes,
                no_longer_participating_no_yes,
                notes,
                user_id,
                created_at,
                updated_at,
                ipa_withdrawal_id
                )
            SELECT
                NEW.master_id,
                NEW.select_subject_withdrew_reason,
                NEW.select_investigator_terminated,
                NEW.lost_to_follow_up_no_yes,
                NEW.no_longer_participating_no_yes,
                NEW.notes,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_item_flag_name_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_item_flag_name_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO item_flag_name_history
            (
                    item_flag_name_id,
                    name ,
                    item_type,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.item_type ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_item_flag_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_item_flag_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO item_flag_history
            (
                    item_flag_id,
                    item_id ,
                    item_type,
                    item_flag_name_id,
                    created_at ,
                    updated_at ,
                    user_id ,
                    disabled
                )                 
            SELECT                 
                NEW.id,
                NEW.item_id ,
                    NEW.item_type,
                    NEW.item_flag_name_id,
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.user_id ,
                    NEW.disabled
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_message_template_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_message_template_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO message_template_history
            (
                name,
                template_type,
                template,
                message_type,
                category,
                admin_id,
                disabled,
                created_at,
                updated_at,
                message_template_id
                )
            SELECT
                NEW.name,
                NEW.template_type,
                NEW.template,
                NEW.message_type,
                NEW.category,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_nfs_store_archived_file_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_nfs_store_archived_file_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO nfs_store_archived_file_history
            (
                file_hash,
                file_name,
                content_type,
                archive_file,
                path,
                file_size,
                file_updated_at,
                nfs_store_container_id,
                title,
                description,
                file_metadata,
                nfs_store_stored_file_id,
                user_id,
                created_at,
                updated_at,
                nfs_store_archived_file_id,
                embed_resource_name,
                embed_resource_id
                )
            SELECT
                NEW.file_hash,
                NEW.file_name,
                NEW.content_type,
                NEW.archive_file,
                NEW.path,
                NEW.file_size,
                NEW.file_updated_at,
                NEW.nfs_store_container_id,
                NEW.title,
                NEW.description,
                NEW.file_metadata,
                NEW.nfs_store_stored_file_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id,
                NEW.embed_resource_name,
                NEW.embed_resource_id
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_nfs_store_container_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_nfs_store_container_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO nfs_store_container_history
            (
                master_id,
                name,
                app_type_id,
                orig_nfs_store_container_id,
                created_by_user_id,
                user_id,
                created_at,
                updated_at,
                nfs_store_container_id
                )
            SELECT
                NEW.master_id,
                NEW.name,
                NEW.app_type_id,
                NEW.nfs_store_container_id,
                NEW.created_by_user_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_nfs_store_stored_file_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_nfs_store_stored_file_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO nfs_store_stored_file_history
            (
                file_hash,
                file_name,
                content_type,
                path,
                file_size,
                file_updated_at,
                nfs_store_container_id,
                title,
                description,
                file_metadata,
                last_process_name_run,
                user_id,
                created_at,
                updated_at,
                nfs_store_stored_file_id,
                embed_resource_name,
                embed_resource_id
                )
            SELECT
                NEW.file_hash,
                NEW.file_name,
                NEW.content_type,
                NEW.path,
                NEW.file_size,
                NEW.file_updated_at,
                NEW.nfs_store_container_id,
                NEW.title,
                NEW.description,
                NEW.file_metadata,
                NEW.last_process_name_run,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id,
                NEW.embed_resource_name,
                NEW.embed_resource_id
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_page_layout_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_page_layout_update () returns trigger language plpgsql as $$
          BEGIN
              INSERT INTO page_layout_history
              (
                      page_layout_id,
                      app_type_id,
                      layout_name,
                      panel_name,
                      panel_label,
                      panel_position,
                      options,
                      disabled,
                      admin_id,
                      created_at,
                      updated_at,
                      description
                  )
              SELECT
                  NEW.id,
                  -- NEW.page_layout_id,
                  NEW.app_type_id,
                  NEW.layout_name,
                  NEW.panel_name,
                  NEW.panel_label,
                  NEW.panel_position,
                  NEW.options,
                  NEW.disabled,
                  NEW.admin_id,
                  NEW.created_at,
                  NEW.updated_at,
                  NEW.description
              ;
              RETURN NEW;
          END;
      $$
;


--
-- Name: log_player_contact_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_player_contact_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO player_contact_history
            (
                    player_contact_id,
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
                NEW.id,
                NEW.master_id,
                NEW.rec_type,
                NEW.data,
                NEW.source,
                NEW.rank,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_player_info_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_player_info_update () returns trigger language plpgsql as $$
 BEGIN
 INSERT INTO player_info_history
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
 source,
 other_count, -- <<<< added
 other_type, -- <<<< added
 player_info_id
 ) 
 SELECT
 NEW.master_id,
 NEW.first_name,
 NEW.last_name,
 NEW.middle_name,
 NEW.nick_name,
 NEW.birth_date,
 NEW.death_date,
 NEW.user_id,
 NEW.created_at,
 NEW.updated_at,
 NEW.contact_pref,
 NEW.start_year,
 NEW.rank,
 NEW.notes,
 NEW.contact_id,
 NEW.college,
 NEW.end_year, 
 NEW.source, 
 NEW.other_count, -- <<<< added
 NEW.other_type,  -- <<<< added
 NEW.id
 ;
 RETURN NEW;
 END;
 $$
;


--
-- Name: log_protocol_event_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_protocol_event_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO protocol_event_history
            (
                    protocol_event_id,                    
    name ,
    admin_id,
    created_at,
    updated_at,
    disabled ,
    sub_process_id,
    milestone ,
    description

                )                 
            SELECT                 
                NEW.id,
                NEW.name ,                    
                    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.disabled ,
    NEW.sub_process_id,
    NEW.milestone ,
    NEW.description
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_protocol_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_protocol_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO protocol_history
            (
                    protocol_id,
                    name ,                    
                    created_at ,
                    updated_at ,
                    disabled,
                    admin_id ,
                    "position"
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled,
                    NEW.admin_id ,
                    NEW.position
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_report_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_report_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO report_history
            (
                    report_id,
                    name,
                    description,
                    sql,
                    search_attrs,
                    admin_id,
                    disabled,
                    report_type,
                    auto,
                    searchable,
                    position,
                    created_at,
                    updated_at,
                    edit_field_names,
                    selection_fields,
                    item_type,
                    short_name,
                    options
                )
            SELECT
                NEW.id,
                NEW.name,
                NEW.description,
                NEW.sql,
                NEW.search_attrs,
                NEW.admin_id,
                NEW.disabled,
                NEW.report_type,
                NEW.auto,
                NEW.searchable,
                NEW.position,
                NEW.created_at,
                NEW.updated_at,
                NEW.edit_field_names,
                NEW.selection_fields,
                NEW.item_type,
                NEW.short_name,
                NEW.options
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_sage_two_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_sage_two_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO sage_two_history
            (
                    sage_two_id,                    
                    external_id,
                    user_id,
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.external_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at 
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_scantron_series_two_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_scantron_series_two_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO scantron_series_two_history
            (
                    scantron_series_two_id,                    
                    external_id,
                    user_id,
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.external_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at 
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_scantron_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_scantron_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO scantron_history
            (
                master_id,
                scantron_id,
                user_id,
                created_at,
                updated_at,
                scantron_table_id
                )                 
            SELECT
                NEW.master_id,
                NEW.scantron_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_sub_process_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_sub_process_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO sub_process_history
            (
                    sub_process_id,                    
    
    name,
    disabled,
    protocol_id,
    admin_id ,
    created_at,
    updated_at

                )                 
            SELECT                 
                NEW.id,
                NEW.name,
    NEW.disabled,
    NEW.protocol_id,
    NEW.admin_id ,
    NEW.created_at,
    NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_tracker_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_tracker_update () returns trigger language plpgsql as $$
        BEGIN

          -- Check to see if there is an existing record in tracker_history that matches the 
          -- that inserted or updated in trackers.
          -- If there is, just skip the insert into tracker_history, otherwise make the insert happen.

          PERFORM * from tracker_history 
            WHERE
              master_id = NEW.master_id 
              AND protocol_id = NEW.protocol_id
              AND coalesce(protocol_event_id,-1) = coalesce(NEW.protocol_event_id,-1)
              AND coalesce(event_date, '1900-01-01'::date)::date = coalesce(NEW.event_date, '1900-01-01')::date
              AND sub_process_id = NEW.sub_process_id
              AND coalesce(notes,'') = coalesce(NEW.notes,'')
              AND coalesce(item_id,-1) = coalesce(NEW.item_id,-1)
              AND coalesce(item_type,'') = coalesce(NEW.item_type,'')
              -- do not check created_at --
              AND updated_at::timestamp = NEW.updated_at::timestamp
              AND coalesce(user_id,-1) = coalesce(NEW.user_id,-1);
              
            IF NOT FOUND THEN
              INSERT INTO tracker_history 
                  (tracker_id, master_id, protocol_id, 
                   protocol_event_id, event_date, sub_process_id, notes,
                   item_id, item_type,
                   created_at, updated_at, user_id)

                  SELECT NEW.id, NEW.master_id, NEW.protocol_id, 
                     NEW.protocol_event_id, NEW.event_date, 
                     NEW.sub_process_id, NEW.notes, 
                     NEW.item_id, NEW.item_type,
                     NEW.created_at, NEW.updated_at, NEW.user_id  ;
            END IF;

            RETURN NEW;

        END;
    $$
;


--
-- Name: log_user_authorization_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_user_authorization_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO user_authorization_history
            (
                    user_authorization_id,
                    user_id,                    
                    has_authorization,                    
                    admin_id,
                    disabled,                    
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.user_id,                
                NEW.has_authorization,               
                NEW.admin_id,                
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_user_role_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_user_role_update () returns trigger language plpgsql as $$
        BEGIN
            INSERT INTO user_role_history
            (
                app_type_id,
                role_name,
                user_id,
                admin_id,
                disabled,
                created_at,
                updated_at,
                user_role_id
                )
            SELECT
                NEW.app_type_id,
                NEW.role_name,
                NEW.user_id,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$
;


--
-- Name: log_user_update(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.log_user_update () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO user_history
  (
      user_id,
      email,
      encrypted_password,
      reset_password_token,
      reset_password_sent_at,
      remember_created_at,
      sign_in_count,
      current_sign_in_at,
      last_sign_in_at,
      current_sign_in_ip ,
      last_sign_in_ip ,
      created_at,
      updated_at,
      failed_attempts,
      unlock_token,
      locked_at,
      disabled,
      admin_id,
      app_type_id,
      authentication_token,
      consumed_timestep,
      otp_required_for_login,
      password_updated_at,
      first_name,
      last_name,
      confirmation_token,
      confirmed_at,
      confirmation_sent_at,
      do_not_email,
      country_code,
      terms_of_use_accepted,
      otp_secret
  )
  SELECT
    NEW.id,
    NEW.email,
    NEW.encrypted_password,
    NEW.reset_password_token,
    NEW.reset_password_sent_at,
    NEW.remember_created_at,
    NEW.sign_in_count,
    NEW.current_sign_in_at,
    NEW.last_sign_in_at,
    NEW.current_sign_in_ip ,
    NEW.last_sign_in_ip ,
    NEW.created_at ,
    NEW.updated_at,
    NEW.failed_attempts,
    NEW.unlock_token,
    NEW.locked_at,
    NEW.disabled ,
    NEW.admin_id,
    NEW.app_type_id,
    NEW.authentication_token,
    NEW.consumed_timestep,
    NEW.otp_required_for_login,
    NEW.password_updated_at,
    NEW.first_name,
    NEW.last_name,
    NEW.confirmation_token,
    NEW.confirmed_at,
    NEW.confirmation_sent_at,
    NEW.do_not_email,
    NEW.country_code,
    NEW.terms_of_use_accepted,
    NEW.otp_secret
  ;
  RETURN NEW;
  END;
  $$
;


--
-- Name: redcap_data_dictionary_history_upd(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.redcap_data_dictionary_history_upd () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO redcap_data_dictionary_history (
    redcap_project_admin_id, field_count, captured_metadata,
    disabled,
    admin_id,
    created_at,
    updated_at,
    redcap_data_dictionary_id)
  SELECT
    NEW.redcap_project_admin_id, NEW.field_count, NEW.captured_metadata,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: redcap_project_admin_history_upd(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.redcap_project_admin_history_upd () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO redcap_project_admin_history (
    name, api_key, server_url, captured_project_info, study, transfer_mode, frequency, status, post_transfer_pipeline, notes, dynamic_model_table,
    disabled,
    admin_id,
    created_at,
    updated_at,
    redcap_project_admin_id)
  SELECT
    NEW.name, NEW.api_key, NEW.server_url, NEW.captured_project_info, NEW.study, NEW.transfer_mode, NEW.frequency, NEW.status, NEW.post_transfer_pipeline, NEW.notes, NEW.dynamic_model_table,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: role_description_history_upd(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.role_description_history_upd () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO role_description_history (
    app_type_id, role_name, role_template, name, description,
    disabled,
    admin_id,
    created_at,
    updated_at,
    role_description_id)
  SELECT
    NEW.app_type_id, NEW.role_name, NEW.role_template, NEW.name, NEW.description,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: tracker_upsert(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.tracker_upsert () returns trigger language plpgsql as $$
      DECLARE
        latest_tracker trackers%ROWTYPE;
      BEGIN

        

        -- Look for a row in trackers for the inserted master / protocol pair
        SELECT * into latest_tracker 
          FROM trackers 
          WHERE
            master_id = NEW.master_id 
            AND protocol_id = NEW.protocol_id              
          ORDER BY
            event_date DESC NULLS LAST, updated_at DESC NULLS LAST
          LIMIT 1
        ;

        IF NOT FOUND THEN
          -- Nothing was found, so just allow the insert to continue
          
          RETURN NEW;

        ELSE   
          -- A trackers row for the master / protocol pair was found.
          -- Check if it is more recent, by having an event date either later than the insert, or 
          -- has an event_date the same as the insert but with later updated_at time (unlikely)

          IF latest_tracker.event_date > NEW.event_date OR 
              latest_tracker.event_date = NEW.event_date AND latest_tracker.updated_at > NEW.updated_at
              THEN

            -- The retrieved record was more recent, we should not make a change to the trackers table,
            -- but instead we need to ensure an insert into the tracker_history table does happen even though there
            -- is no actual insert or update trigger to fire.
            -- We use the trackers record ID that was retrieved as the tracker_id in tracker_history

            INSERT INTO tracker_history (
                tracker_id, master_id, protocol_id, 
                protocol_event_id, event_date, sub_process_id, notes,
                item_id, item_type,
                created_at, updated_at, user_id
              )                 
              SELECT 
                latest_tracker.id, NEW.master_id, NEW.protocol_id, 
                NEW.protocol_event_id, NEW.event_date, 
                NEW.sub_process_id, NEW.notes, 
                NEW.item_id, NEW.item_type,
                NEW.created_at, NEW.updated_at, NEW.user_id  ;
            
            RETURN NULL;

          ELSE
            -- The tracker record for the master / protocol pair exists and was not more recent, therefore it
            -- needs to be replaced by the intended NEW record. Complete with an update and allow the cascading 
            -- trackers update trigger to handle the insert into tracker_history.

            UPDATE trackers SET
              master_id = NEW.master_id, 
              protocol_id = NEW.protocol_id, 
              protocol_event_id = NEW.protocol_event_id, 
              event_date = NEW.event_date, 
              sub_process_id = NEW.sub_process_id, 
              notes = NEW.notes, 
              item_id = NEW.item_id, 
              item_type = NEW.item_type,
              -- do not update created_at --
              updated_at = NEW.updated_at, 
              user_id = NEW.user_id
            WHERE master_id = NEW.master_id AND 
              protocol_id = NEW.protocol_id
            ;

            -- Prevent the original insert from actually completing.
            RETURN NULL;
          END IF;
        END IF;      
      END;
    $$
;


--
-- Name: update_address_ranks(integer); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.update_address_ranks (set_master_id integer) returns integer language plpgsql as $$
        DECLARE
          latest_primary RECORD;
        BEGIN
  
          SELECT * into latest_primary 
          FROM addresses
          WHERE master_id = set_master_id
          AND rank = 10
          ORDER BY updated_at DESC
          LIMIT 1;
        
          IF NOT FOUND THEN
            RETURN NULL;
          END IF;

          
          UPDATE addresses SET rank = 5 
          WHERE 
            master_id = set_master_id 
            AND rank = 10
            AND id <> latest_primary.id;
          

          RETURN 1;
        END;
    $$
;


--
-- Name: update_master_with_player_info(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.update_master_with_player_info () returns trigger language plpgsql as $$
      BEGIN
          UPDATE masters 
              set rank = (
              case when NEW.rank is null then null 
                   when (NEW.rank > 12) then NEW.rank * -1 
                   else new.rank
              end
              )

          WHERE masters.id = NEW.master_id;

          RETURN NEW;
      END;
      $$
;


--
-- Name: update_master_with_pro_info(); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.update_master_with_pro_info () returns trigger language plpgsql as $$
    BEGIN
        UPDATE masters 
            set pro_info_id = NEW.id, pro_id = NEW.pro_id             
        WHERE masters.id = NEW.master_id;

        RETURN NEW;
    END;
    $$
;


--
-- Name: update_player_contact_ranks(integer, character varying); Type: FUNCTION; Schema: ml_app; Owner: -
--
create function ml_app.update_player_contact_ranks (set_master_id integer, set_rec_type character varying) returns integer language plpgsql as $$
        DECLARE
          latest_primary RECORD;
        BEGIN
  
          SELECT * into latest_primary 
          FROM player_contacts
          WHERE master_id = set_master_id
          AND rank = 10
          AND rec_type = set_rec_type
          ORDER BY updated_at DESC
          LIMIT 1;
        
          IF NOT FOUND THEN
            RETURN NULL;
          END IF;

          
          UPDATE player_contacts SET rank = 5 
          WHERE 
            master_id = set_master_id 
            AND rank = 10
            AND rec_type = set_rec_type
            AND id <> latest_primary.id;
          

          RETURN 1;
        END;
    $$
;


--
-- Name: log_data_variable_package_vars_update(); Type: FUNCTION; Schema: ref_data; Owner: -
--
create function ref_data.log_data_variable_package_vars_update () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO data_variable_package_var_history (
    
    data_variable_package_id, domain, record_id, variable_name, record_type, disabled,
    user_id,
    created_at,
    updated_at,
    data_variable_package_var_id)
  SELECT
    
    NEW.data_variable_package_id, NEW.domain, NEW.record_id, NEW.variable_name, NEW.record_type, NEW.disabled,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: log_data_variable_packages_update(); Type: FUNCTION; Schema: ref_data; Owner: -
--
create function ref_data.log_data_variable_packages_update () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO data_variable_package_history (
    
    name, tag_select_health_categories, package_type, storage_type, db_or_fs, schema_or_path, table_or_file, is_static, sourced_from_packages, n_for_timepoints, description, disabled,
    user_id,
    created_at,
    updated_at,
    data_variable_package_id)
  SELECT
    
    NEW.name, NEW.tag_select_health_categories, NEW.package_type, NEW.storage_type, NEW.db_or_fs, NEW.schema_or_path, NEW.table_or_file, NEW.is_static, NEW.sourced_from_packages, NEW.n_for_timepoints, NEW.description, NEW.disabled,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: log_datadic_variables_update(); Type: FUNCTION; Schema: ref_data; Owner: -
--
create function ref_data.log_datadic_variables_update () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO datadic_variable_history (
    
    study, source_name, source_type, domain, form_name, variable_name, variable_type, presentation_type, label, label_note, annotation, is_required, valid_type, valid_min, valid_max, multi_valid_choices, is_identifier, is_derived_var, multi_derived_from_id, doc_url, target_type, owner_email, classification, other_classification, multi_timepoints, equivalent_to_id, storage_type, db_or_fs, schema_or_path, table_or_file, disabled, admin_id, redcap_data_dictionary_id, position, section_id, sub_section_id, title, storage_varname, contributor_type, n_for_timepoints, notes,
    user_id,
    created_at,
    updated_at,
    datadic_variable_id)
  SELECT
    
    NEW.study, NEW.source_name, NEW.source_type, NEW.domain, NEW.form_name, NEW.variable_name, NEW.variable_type, NEW.presentation_type, NEW.label, NEW.label_note, NEW.annotation, NEW.is_required, NEW.valid_type, NEW.valid_min, NEW.valid_max, NEW.multi_valid_choices, NEW.is_identifier, NEW.is_derived_var, NEW.multi_derived_from_id, NEW.doc_url, NEW.target_type, NEW.owner_email, NEW.classification, NEW.other_classification, NEW.multi_timepoints, NEW.equivalent_to_id, NEW.storage_type, NEW.db_or_fs, NEW.schema_or_path, NEW.table_or_file, NEW.disabled, NEW.admin_id, NEW.redcap_data_dictionary_id, NEW.position, NEW.section_id, NEW.sub_section_id, NEW.title, NEW.storage_varname, NEW.contributor_type, NEW.n_for_timepoints, NEW.notes,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: log_domain_mappings_update(); Type: FUNCTION; Schema: ref_data; Owner: -
--
create function ref_data.log_domain_mappings_update () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO domain_mapping_history (
    
    domain, domain_title, tag_select_health_categories, notes, hide_from_datadic, disabled,
    user_id,
    created_at,
    updated_at,
    domain_mapping_id)
  SELECT
    
    NEW.domain, NEW.domain_title, NEW.tag_select_health_categories, NEW.notes, NEW.hide_from_datadic, NEW.disabled,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: log_ipa_datadic_update(); Type: FUNCTION; Schema: ref_data; Owner: -
--
create function ref_data.log_ipa_datadic_update () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO ipa_datadic_history (
    
    
    user_id,
    created_at,
    updated_at,
    ipa_datadic_id)
  SELECT
    
    
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: log_q1_datadic_update(); Type: FUNCTION; Schema: ref_data; Owner: -
--
create function ref_data.log_q1_datadic_update () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO q1_datadic_history (
    
    
    user_id,
    created_at,
    updated_at,
    q1_datadic_id)
  SELECT
    
    
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: redcap_data_collection_instrument_history_upd(); Type: FUNCTION; Schema: ref_data; Owner: -
--
create function ref_data.redcap_data_collection_instrument_history_upd () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO redcap_data_collection_instrument_history (
    redcap_project_admin_id, name, label,
    disabled,
    admin_id,
    created_at,
    updated_at,
    redcap_data_collection_instrument_id)
  SELECT
    NEW.redcap_project_admin_id, NEW.name, NEW.label,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: redcap_project_user_history_upd(); Type: FUNCTION; Schema: ref_data; Owner: -
--
create function ref_data.redcap_project_user_history_upd () returns trigger language plpgsql as $$
BEGIN
  INSERT INTO redcap_project_user_history (
    redcap_project_admin_id, username, email, expiration,
    disabled,
    admin_id,
    created_at,
    updated_at,
    redcap_project_user_id)
  SELECT
    NEW.redcap_project_admin_id, NEW.username, NEW.email, NEW.expiration,
    NEW.disabled,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$
;


--
-- Name: accuracy_score_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.accuracy_score_history (
    id integer not null,
    name character varying,
    value integer,
    admin_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    disabled boolean,
    accuracy_score_id integer
  )
;


--
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.accuracy_score_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.accuracy_score_history_id_seq owned by ml_app.accuracy_score_history.id
;


--
-- Name: accuracy_scores; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.accuracy_scores (
    id integer not null,
    name character varying,
    value integer,
    admin_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    disabled boolean
  )
;


--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.accuracy_scores_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.accuracy_scores_id_seq owned by ml_app.accuracy_scores.id
;


--
-- Name: activity_log_bhs_assignment_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.activity_log_bhs_assignment_history (
    id integer not null,
    master_id integer,
    bhs_assignment_id integer,
    select_record_from_player_contact_phones character varying,
    return_call_availability_notes character varying,
    questions_from_call_notes character varying,
    results_link character varying,
    select_result character varying,
    completed_q1_no_yes character varying,
    completed_teamstudy_no_yes character varying,
    previous_contact_with_team_no_yes character varying,
    previous_contact_with_team_notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    activity_log_bhs_assignment_id integer,
    notes character varying,
    pi_return_call_notes character varying
  )
;


--
-- Name: activity_log_bhs_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.activity_log_bhs_assignment_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: activity_log_bhs_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_log_bhs_assignment_history_id_seq owned by ml_app.activity_log_bhs_assignment_history.id
;


--
-- Name: activity_log_bhs_assignments; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.activity_log_bhs_assignments (
    id integer not null,
    master_id integer,
    bhs_assignment_id integer,
    select_record_from_player_contact_phones character varying,
    return_call_availability_notes character varying,
    questions_from_call_notes character varying,
    results_link character varying,
    select_result character varying,
    completed_q1_no_yes character varying,
    completed_teamstudy_no_yes character varying,
    previous_contact_with_team_no_yes character varying,
    previous_contact_with_team_notes character varying,
    extra_log_type character varying,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    notes character varying,
    pi_return_call_notes character varying
  )
;


--
-- Name: activity_log_bhs_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.activity_log_bhs_assignments_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: activity_log_bhs_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_log_bhs_assignments_id_seq owned by ml_app.activity_log_bhs_assignments.id
;


--
-- Name: activity_log_ext_assignment_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.activity_log_ext_assignment_history (
    id integer not null,
    master_id integer,
    ext_assignment_id integer,
    do_when date,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    activity_log_ext_assignment_id integer
  )
;


--
-- Name: activity_log_ext_assignment_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.activity_log_ext_assignment_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: activity_log_ext_assignment_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_log_ext_assignment_history_id_seq owned by ml_app.activity_log_ext_assignment_history.id
;


--
-- Name: activity_log_ext_assignments; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.activity_log_ext_assignments (
    id integer not null,
    master_id integer,
    ext_assignment_id integer,
    do_when date,
    notes character varying,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    select_call_direction character varying,
    select_who character varying,
    extra_text character varying,
    extra_log_type character varying
  )
;


--
-- Name: activity_log_ext_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.activity_log_ext_assignments_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: activity_log_ext_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_log_ext_assignments_id_seq owned by ml_app.activity_log_ext_assignments.id
;


--
-- Name: activity_log_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.activity_log_history (
    id integer not null,
    activity_log_id integer,
    name character varying,
    item_type character varying,
    rec_type character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    action_when_attribute character varying,
    field_list character varying,
    blank_log_field_list character varying,
    blank_log_name character varying,
    extra_log_types character varying,
    hide_item_list_panel boolean,
    main_log_name character varying,
    process_name character varying,
    table_name character varying,
    category character varying,
    schema_name character varying
  )
;


--
-- Name: activity_log_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.activity_log_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: activity_log_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_log_history_id_seq owned by ml_app.activity_log_history.id
;


--
-- Name: activity_log_new_test_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.activity_log_new_test_history (
    id integer not null,
    master_id integer,
    new_test_id integer,
    done_when date,
    select_result character varying,
    notes character varying,
    protocol_id integer,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    activity_log_new_test_id integer
  )
;


--
-- Name: activity_log_new_test_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.activity_log_new_test_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: activity_log_new_test_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_log_new_test_history_id_seq owned by ml_app.activity_log_new_test_history.id
;


--
-- Name: activity_log_new_tests; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.activity_log_new_tests (
    id integer not null,
    master_id integer,
    new_test_id integer,
    done_when date,
    select_result character varying,
    notes character varying,
    protocol_id integer,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    new_test_ext_id bigint
  )
;


--
-- Name: activity_log_new_tests_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.activity_log_new_tests_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: activity_log_new_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_log_new_tests_id_seq owned by ml_app.activity_log_new_tests.id
;


--
-- Name: activity_log_player_contact_emails; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.activity_log_player_contact_emails (
    id integer not null,
    data character varying,
    select_email_direction character varying,
    select_who character varying,
    emailed_when date,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    protocol_id integer,
    notes character varying,
    user_id integer,
    player_contact_id integer,
    master_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    set_related_player_contact_rank character varying
  )
;


--
-- Name: activity_log_player_contact_emails_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.activity_log_player_contact_emails_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: activity_log_player_contact_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_log_player_contact_emails_id_seq owned by ml_app.activity_log_player_contact_emails.id
;


--
-- Name: activity_log_player_contact_phone_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.activity_log_player_contact_phone_history (
    id integer not null,
    master_id integer,
    player_contact_id integer,
    data character varying,
    select_call_direction character varying,
    select_who character varying,
    called_when date,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    notes character varying,
    protocol_id integer,
    set_related_player_contact_rank character varying,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    activity_log_player_contact_phone_id integer,
    extra_log_type character varying
  )
;


--
-- Name: activity_log_player_contact_phone_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.activity_log_player_contact_phone_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: activity_log_player_contact_phone_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_log_player_contact_phone_history_id_seq owned by ml_app.activity_log_player_contact_phone_history.id
;


--
-- Name: activity_log_player_contact_phones; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.activity_log_player_contact_phones (
    id integer not null,
    data character varying,
    select_call_direction character varying,
    select_who character varying,
    called_when date,
    select_result character varying,
    select_next_step character varying,
    follow_up_when date,
    protocol_id integer,
    notes character varying,
    user_id integer,
    player_contact_id integer,
    master_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    set_related_player_contact_rank character varying,
    extra_log_type character varying
  )
;


--
-- Name: activity_log_player_contact_phones_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.activity_log_player_contact_phones_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: activity_log_player_contact_phones_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_log_player_contact_phones_id_seq owned by ml_app.activity_log_player_contact_phones.id
;


--
-- Name: activity_log_player_info_history; Type: TABLE; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_log_player_contact_phones_id_seq owned by ml_app.activity_log_player_contact_phones.id
;


--
-- Name: activity_logs; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.activity_logs (
    id integer not null,
    name character varying,
    item_type character varying,
    rec_type character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    action_when_attribute character varying,
    field_list character varying,
    blank_log_field_list character varying,
    blank_log_name character varying,
    extra_log_types character varying,
    hide_item_list_panel boolean,
    main_log_name character varying,
    process_name character varying,
    table_name character varying,
    category character varying,
    schema_name character varying
  )
;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.activity_logs_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.activity_logs_id_seq owned by ml_app.activity_logs.id
;


--
-- Name: address_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.address_history (
    id integer not null,
    master_id integer,
    street character varying,
    street2 character varying,
    street3 character varying,
    city character varying,
    state character varying,
    zip character varying,
    source character varying,
    rank integer,
    rec_type character varying,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone default now(),
    country character varying(3),
    postal_code character varying,
    region character varying,
    address_id integer
  )
;


--
-- Name: address_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.address_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: address_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.address_history_id_seq owned by ml_app.address_history.id
;


--
-- Name: addresses; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.addresses (
    id integer not null,
    master_id integer,
    street character varying,
    street2 character varying,
    street3 character varying,
    city character varying,
    state character varying,
    zip character varying,
    source character varying,
    rank integer,
    rec_type character varying,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone default now(),
    country character varying(3),
    postal_code character varying,
    region character varying
  )
;


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.addresses_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.addresses_id_seq owned by ml_app.addresses.id
;


--
-- Name: admin_action_logs; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.admin_action_logs (
    id integer not null,
    admin_id integer,
    item_type character varying,
    item_id integer,
    action character varying,
    url character varying,
    prev_value json,
    new_value json,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: admin_action_logs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.admin_action_logs_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: admin_action_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.admin_action_logs_id_seq owned by ml_app.admin_action_logs.id
;


--
-- Name: admin_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.admin_history (
    id integer not null,
    email character varying default ''::character varying not null,
    encrypted_password character varying default ''::character varying not null,
    sign_in_count integer default 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    failed_attempts integer default 0,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    disabled boolean,
    admin_id integer,
    consumed_timestep integer,
    otp_required_for_login boolean,
    reset_password_sent_at timestamp without time zone,
    password_updated_at timestamp without time zone,
    updated_by_admin_id integer,
    first_name character varying,
    last_name character varying,
    do_not_email boolean,
    capabilities character varying[],
    otp_secret character varying
  )
;


--
-- Name: admin_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.admin_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: admin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.admin_history_id_seq owned by ml_app.admin_history.id
;


--
-- Name: admins; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.admins (
    id integer not null,
    email character varying default ''::character varying not null,
    encrypted_password character varying default ''::character varying not null,
    sign_in_count integer default 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    failed_attempts integer default 0,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    disabled boolean,
    consumed_timestep integer,
    otp_required_for_login boolean,
    reset_password_sent_at timestamp without time zone,
    password_updated_at timestamp without time zone,
    first_name character varying,
    last_name character varying,
    do_not_email boolean default false,
    admin_id bigint,
    capabilities character varying[],
    otp_secret character varying
  )
;


--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.admins_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.admins_id_seq owned by ml_app.admins.id
;


--
-- Name: app_configurations; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.app_configurations (
    id integer not null,
    name character varying,
    value character varying,
    disabled boolean,
    admin_id integer,
    user_id integer,
    app_type_id integer,
    role_name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
  )
;


--
-- Name: app_configurations_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.app_configurations_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: app_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.app_configurations_id_seq owned by ml_app.app_configurations.id
;


--
-- Name: app_types; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.app_types (
    id integer not null,
    name character varying,
    label character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    default_schema_name character varying
  )
;


--
-- Name: app_types_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.app_types_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: app_types_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.app_types_id_seq owned by ml_app.app_types.id
;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.ar_internal_metadata (
    key character varying not null,
    value character varying,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: college_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.college_history (
    id integer not null,
    name character varying,
    synonym_for_id integer,
    disabled boolean,
    admin_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    college_id integer
  )
;


--
-- Name: college_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.college_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: college_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.college_history_id_seq owned by ml_app.college_history.id
;


--
-- Name: colleges; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.colleges (
    id integer not null,
    name character varying,
    synonym_for_id integer,
    disabled boolean,
    admin_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
  )
;


--
-- Name: colleges_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.colleges_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: colleges_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.colleges_id_seq owned by ml_app.colleges.id
;


--
-- Name: config_libraries; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.config_libraries (
    id integer not null,
    category character varying,
    name character varying,
    options character varying,
    format character varying,
    disabled boolean default false,
    admin_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
  )
;


--
-- Name: config_libraries_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.config_libraries_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: config_libraries_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.config_libraries_id_seq owned by ml_app.config_libraries.id
;


--
-- Name: config_library_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.config_library_history (
    id integer not null,
    category character varying,
    name character varying,
    options character varying,
    format character varying,
    disabled boolean default false,
    admin_id integer,
    config_library_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
  )
;


--
-- Name: config_library_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.config_library_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: config_library_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.config_library_history_id_seq owned by ml_app.config_library_history.id
;


--
-- Name: copy_player_infos; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.copy_player_infos (
    id integer,
    master_id integer,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    nick_name character varying,
    birth_date date,
    death_date date,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    contact_pref character varying,
    start_year integer,
    rank integer,
    notes character varying,
    contactid integer,
    college character varying,
    end_year integer,
    source character varying
  )
;


--
-- Name: delayed_jobs; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.delayed_jobs (
    id integer not null,
    priority integer default 0 not null,
    attempts integer default 0 not null,
    handler text not null,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
  )
;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.delayed_jobs_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.delayed_jobs_id_seq owned by ml_app.delayed_jobs.id
;


--
-- Name: dynamic_model_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.dynamic_model_history (
    id integer not null,
    name character varying,
    table_name character varying,
    schema_name character varying,
    primary_key_name character varying,
    foreign_key_name character varying,
    description character varying,
    admin_id integer,
    disabled boolean,
    "position" integer,
    category character varying,
    table_key_name character varying,
    field_list character varying,
    result_order character varying,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    dynamic_model_id integer,
    options character varying
  )
;


--
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.dynamic_model_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: dynamic_model_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.dynamic_model_history_id_seq owned by ml_app.dynamic_model_history.id
;


--
-- Name: dynamic_models; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.dynamic_models (
    id integer not null,
    name character varying,
    table_name character varying,
    schema_name character varying,
    primary_key_name character varying,
    foreign_key_name character varying,
    description character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    "position" integer,
    category character varying,
    table_key_name character varying,
    field_list character varying,
    result_order character varying,
    options character varying
  )
;


--
-- Name: dynamic_models_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.dynamic_models_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: dynamic_models_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.dynamic_models_id_seq owned by ml_app.dynamic_models.id
;


--
-- Name: exception_logs; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.exception_logs (
    id integer not null,
    message character varying,
    main character varying,
    backtrace character varying,
    user_id integer,
    admin_id integer,
    notified_at timestamp without time zone,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: exception_logs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.exception_logs_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: exception_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.exception_logs_id_seq owned by ml_app.exception_logs.id
;


--
-- Name: external_identifier_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.external_identifier_history (
    id integer not null,
    name character varying,
    label character varying,
    external_id_attribute character varying,
    external_id_view_formatter character varying,
    external_id_edit_pattern character varying,
    prevent_edit boolean,
    pregenerate_ids boolean,
    min_id bigint,
    max_id bigint,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    external_identifier_id integer,
    extra_fields character varying,
    alphanumeric boolean,
    schema_name character varying,
    options character varying
  )
;


--
-- Name: external_identifier_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.external_identifier_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: external_identifier_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.external_identifier_history_id_seq owned by ml_app.external_identifier_history.id
;


--
-- Name: external_identifiers; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.external_identifiers (
    id integer not null,
    name character varying,
    label character varying,
    external_id_attribute character varying,
    external_id_view_formatter character varying,
    external_id_edit_pattern character varying,
    prevent_edit boolean,
    pregenerate_ids boolean,
    min_id bigint,
    max_id bigint,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    alphanumeric boolean,
    extra_fields character varying,
    category character varying,
    schema_name character varying,
    options character varying
  )
;


--
-- Name: external_identifiers_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.external_identifiers_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: external_identifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.external_identifiers_id_seq owned by ml_app.external_identifiers.id
;


--
-- Name: external_link_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.external_link_history (
    id integer not null,
    name character varying,
    value character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    external_link_id integer
  )
;


--
-- Name: external_link_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.external_link_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: external_link_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.external_link_history_id_seq owned by ml_app.external_link_history.id
;


--
-- Name: external_links; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.external_links (
    id integer not null,
    name character varying,
    value character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: external_links_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.external_links_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: external_links_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.external_links_id_seq owned by ml_app.external_links.id
;


--
-- Name: general_selection_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.general_selection_history (
    id integer not null,
    name character varying,
    value character varying,
    item_type character varying,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    disabled boolean,
    admin_id integer,
    create_with boolean,
    edit_if_set boolean,
    edit_always boolean,
    "position" integer,
    description character varying,
    lock boolean,
    general_selection_id integer
  )
;


--
-- Name: general_selection_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.general_selection_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: general_selection_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.general_selection_history_id_seq owned by ml_app.general_selection_history.id
;


--
-- Name: general_selections; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.general_selections (
    id integer not null,
    name character varying,
    value character varying,
    item_type character varying,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    disabled boolean,
    admin_id integer,
    create_with boolean,
    edit_if_set boolean,
    edit_always boolean,
    "position" integer,
    description character varying,
    lock boolean
  )
;


--
-- Name: general_selections_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.general_selections_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: general_selections_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.general_selections_id_seq owned by ml_app.general_selections.id
;


--
-- Name: imports; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.imports (
    id integer not null,
    primary_table character varying,
    item_count integer,
    filename character varying,
    imported_items integer[],
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: imports_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.imports_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.imports_id_seq owned by ml_app.imports.id
;


--
-- Name: imports_model_generators; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.imports_model_generators (
    id bigint not null,
    name character varying,
    dynamic_model_table character varying,
    options json,
    description character varying,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: imports_model_generators_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.imports_model_generators_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: imports_model_generators_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.imports_model_generators_id_seq owned by ml_app.imports_model_generators.id
;


--
-- Name: item_flag_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.item_flag_history (
    id integer not null,
    item_id integer,
    item_type character varying,
    item_flag_name_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    user_id integer,
    item_flag_id integer,
    disabled boolean
  )
;


--
-- Name: item_flag_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.item_flag_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: item_flag_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.item_flag_history_id_seq owned by ml_app.item_flag_history.id
;


--
-- Name: item_flag_name_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.item_flag_name_history (
    id integer not null,
    name character varying,
    item_type character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    item_flag_name_id integer
  )
;


--
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.item_flag_name_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.item_flag_name_history_id_seq owned by ml_app.item_flag_name_history.id
;


--
-- Name: item_flag_names; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.item_flag_names (
    id integer not null,
    name character varying,
    item_type character varying,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    disabled boolean,
    admin_id integer
  )
;


--
-- Name: item_flag_names_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.item_flag_names_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: item_flag_names_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.item_flag_names_id_seq owned by ml_app.item_flag_names.id
;


--
-- Name: item_flags; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.item_flags (
    id integer not null,
    item_id integer,
    item_type character varying,
    item_flag_name_id integer not null,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    user_id integer,
    disabled boolean
  )
;


--
-- Name: item_flags_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.item_flags_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: item_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.item_flags_id_seq owned by ml_app.item_flags.id
;


--
-- Name: manage_users; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.manage_users (
    id integer not null,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: manage_users_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.manage_users_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: manage_users_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.manage_users_id_seq owned by ml_app.manage_users.id
;


--
-- Name: masters; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.masters (
    id integer not null,
    msid integer,
    pro_id integer,
    pro_info_id integer,
    rank integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    contact_id integer,
    created_by_user_id bigint
  )
;


--
-- Name: masters_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.masters_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: masters_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.masters_id_seq owned by ml_app.masters.id
;


--
-- Name: message_notifications; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.message_notifications (
    id integer not null,
    app_type_id integer,
    master_id integer,
    user_id integer,
    item_id integer,
    item_type character varying,
    message_type character varying,
    recipient_user_ids integer[],
    layout_template_name character varying,
    content_template_name character varying,
    generated_content character varying,
    status character varying,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    status_changed character varying,
    subject character varying,
    data json,
    recipient_data character varying[],
    from_user_email character varying,
    role_name character varying,
    content_template_text character varying,
    importance character varying,
    extra_substitutions character varying,
    content_hash character varying
  )
;


--
-- Name: message_notifications_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.message_notifications_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: message_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.message_notifications_id_seq owned by ml_app.message_notifications.id
;


--
-- Name: message_template_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.message_template_history (
    id integer not null,
    name character varying,
    template_type character varying,
    template character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    message_template_id integer,
    message_type character varying,
    category character varying
  )
;


--
-- Name: message_template_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.message_template_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: message_template_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.message_template_history_id_seq owned by ml_app.message_template_history.id
;


--
-- Name: message_templates; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.message_templates (
    id integer not null,
    name character varying,
    message_type character varying,
    template_type character varying,
    template character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    category character varying
  )
;


--
-- Name: message_templates_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.message_templates_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: message_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.message_templates_id_seq owned by ml_app.message_templates.id
;


--
-- Name: model_references; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.model_references (
    id integer not null,
    from_record_type character varying,
    from_record_id integer,
    from_record_master_id integer,
    to_record_type character varying,
    to_record_id integer,
    to_record_master_id integer,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    disabled boolean
  )
;


--
-- Name: model_references_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.model_references_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: model_references_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.model_references_id_seq owned by ml_app.model_references.id
;


--
-- Name: msid_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.msid_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_archived_file_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.nfs_store_archived_file_history (
    id integer not null,
    file_hash character varying,
    file_name character varying,
    content_type character varying,
    archive_file character varying,
    path character varying,
    file_size character varying,
    file_updated_at character varying,
    nfs_store_container_id bigint,
    title character varying,
    description character varying,
    file_metadata character varying,
    nfs_store_stored_file_id bigint,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_archived_file_id integer,
    embed_resource_name character varying,
    embed_resource_id bigint
  )
;


--
-- Name: nfs_store_archived_file_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.nfs_store_archived_file_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_archived_file_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.nfs_store_archived_file_history_id_seq owned by ml_app.nfs_store_archived_file_history.id
;


--
-- Name: nfs_store_archived_files_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.nfs_store_archived_files_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_archived_files_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.nfs_store_archived_files_id_seq owned by ml_app.nfs_store_archived_files.id
;


--
-- Name: nfs_store_container_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.nfs_store_container_history (
    id integer not null,
    master_id integer,
    name character varying,
    app_type_id bigint,
    orig_nfs_store_container_id bigint,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_container_id integer,
    created_by_user_id bigint
  )
;


--
-- Name: nfs_store_container_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.nfs_store_container_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_container_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.nfs_store_container_history_id_seq owned by ml_app.nfs_store_container_history.id
;


--
-- Name: nfs_store_containers; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.nfs_store_containers (
    id integer not null,
    name character varying,
    user_id integer,
    app_type_id integer,
    nfs_store_container_id integer,
    master_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    created_by_user_id bigint
  )
;


--
-- Name: nfs_store_containers_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.nfs_store_containers_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_containers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.nfs_store_containers_id_seq owned by ml_app.nfs_store_containers.id
;


--
-- Name: nfs_store_downloads; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.nfs_store_downloads (
    id integer not null,
    user_groups integer[] default '{}'::integer[],
    path character varying,
    retrieval_path character varying,
    retrieved_items character varying,
    user_id integer not null,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_container_ids integer[]
  )
;


--
-- Name: nfs_store_downloads_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.nfs_store_downloads_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_downloads_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.nfs_store_downloads_id_seq owned by ml_app.nfs_store_downloads.id
;


--
-- Name: nfs_store_filters; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.nfs_store_filters (
    id integer not null,
    app_type_id integer,
    role_name character varying,
    user_id integer,
    resource_name character varying,
    filter character varying,
    description character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
  )
;


--
-- Name: nfs_store_filters_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.nfs_store_filters_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.nfs_store_filters_id_seq owned by ml_app.nfs_store_filters.id
;


--
-- Name: nfs_store_move_actions; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.nfs_store_move_actions (
    id integer not null,
    user_groups integer[],
    path character varying,
    new_path character varying,
    retrieval_path character varying,
    moved_items character varying,
    nfs_store_container_ids integer[],
    user_id integer not null,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
  )
;


--
-- Name: nfs_store_move_actions_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.nfs_store_move_actions_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_move_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.nfs_store_move_actions_id_seq owned by ml_app.nfs_store_move_actions.id
;


--
-- Name: nfs_store_stored_file_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.nfs_store_stored_file_history (
    id integer not null,
    file_hash character varying,
    file_name character varying,
    content_type character varying,
    path character varying,
    file_size character varying,
    file_updated_at character varying,
    nfs_store_container_id bigint,
    title character varying,
    description character varying,
    file_metadata character varying,
    last_process_name_run character varying,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_stored_file_id integer,
    embed_resource_name character varying,
    embed_resource_id bigint
  )
;


--
-- Name: nfs_store_stored_file_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.nfs_store_stored_file_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_stored_file_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.nfs_store_stored_file_history_id_seq owned by ml_app.nfs_store_stored_file_history.id
;


--
-- Name: nfs_store_stored_files_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.nfs_store_stored_files_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_stored_files_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.nfs_store_stored_files_id_seq owned by ml_app.nfs_store_stored_files.id
;


--
-- Name: nfs_store_uploads; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.nfs_store_uploads (
    id integer not null,
    file_hash character varying not null,
    file_name character varying not null,
    content_type character varying not null,
    file_size bigint not null,
    chunk_count integer,
    completed boolean,
    file_updated_at timestamp without time zone,
    user_id integer,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    path character varying,
    nfs_store_stored_file_id integer,
    upload_set character varying
  )
;


--
-- Name: nfs_store_uploads_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.nfs_store_uploads_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.nfs_store_uploads_id_seq owned by ml_app.nfs_store_uploads.id
;


--
-- Name: nfs_store_user_file_actions; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.nfs_store_user_file_actions (
    id integer not null,
    user_groups integer[],
    path character varying,
    new_path character varying,
    action character varying,
    retrieval_path character varying,
    action_items character varying,
    nfs_store_container_ids integer[],
    user_id integer not null,
    nfs_store_container_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
  )
;


--
-- Name: nfs_store_user_file_actions_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.nfs_store_user_file_actions_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: nfs_store_user_file_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.nfs_store_user_file_actions_id_seq owned by ml_app.nfs_store_user_file_actions.id
;


--
-- Name: page_layout_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.page_layout_history (
    id integer not null,
    layout_name character varying,
    panel_name character varying,
    panel_label character varying,
    panel_position character varying,
    options character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    page_layout_id integer,
    app_type_id character varying,
    description character varying
  )
;


--
-- Name: page_layout_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.page_layout_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: page_layout_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.page_layout_history_id_seq owned by ml_app.page_layout_history.id
;


--
-- Name: page_layouts; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.page_layouts (
    id integer not null,
    app_type_id integer,
    layout_name character varying,
    panel_name character varying,
    panel_label character varying,
    panel_position integer,
    options character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    description character varying
  )
;


--
-- Name: page_layouts_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.page_layouts_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: page_layouts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.page_layouts_id_seq owned by ml_app.page_layouts.id
;


--
-- Name: player_contact_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.player_contact_history (
    id integer not null,
    master_id integer,
    rec_type character varying,
    data character varying,
    source character varying,
    rank integer,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone default now(),
    player_contact_id integer
  )
;


--
-- Name: player_contact_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.player_contact_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: player_contact_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.player_contact_history_id_seq owned by ml_app.player_contact_history.id
;


--
-- Name: player_contacts; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.player_contacts (
    id integer not null,
    master_id integer,
    rec_type character varying,
    data character varying,
    source character varying,
    rank integer,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone default now()
  )
;


--
-- Name: player_contacts_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.player_contacts_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: player_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.player_contacts_id_seq owned by ml_app.player_contacts.id
;


--
-- Name: player_info_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.player_info_history (
    id integer not null,
    master_id integer,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    nick_name character varying,
    birth_date date,
    death_date date,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone default now(),
    contact_pref character varying,
    start_year integer,
    rank integer,
    notes character varying,
    contact_id integer,
    college character varying,
    end_year integer,
    source character varying,
    player_info_id integer,
    other_count integer,
    other_type character varying
  )
;


--
-- Name: player_info_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.player_info_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: player_info_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.player_info_history_id_seq owned by ml_app.player_info_history.id
;


--
-- Name: player_infos; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.player_infos (
    id integer not null,
    master_id integer,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    nick_name character varying,
    birth_date date,
    death_date date,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone default now(),
    contact_pref character varying,
    start_year integer,
    rank integer,
    notes character varying,
    contact_id integer,
    college character varying,
    end_year integer,
    source character varying
  )
;


--
-- Name: player_infos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.player_infos_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: player_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.player_infos_id_seq owned by ml_app.player_infos.id
;


--
-- Name: pro_infos; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.pro_infos (
    id integer not null,
    master_id integer,
    pro_id integer,
    first_name character varying,
    middle_name character varying,
    nick_name character varying,
    last_name character varying,
    birth_date date,
    death_date date,
    start_year integer,
    end_year integer,
    college character varying,
    birthplace character varying,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone default now()
  )
;


--
-- Name: pro_infos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.pro_infos_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: pro_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.pro_infos_id_seq owned by ml_app.pro_infos.id
;


--
-- Name: protocol_event_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.protocol_event_history (
    id integer not null,
    name character varying,
    admin_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    disabled boolean,
    sub_process_id integer,
    milestone character varying,
    description character varying,
    protocol_event_id integer
  )
;


--
-- Name: protocol_event_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.protocol_event_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: protocol_event_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.protocol_event_history_id_seq owned by ml_app.protocol_event_history.id
;


--
-- Name: protocol_events; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.protocol_events (
    id integer not null,
    name character varying,
    admin_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    disabled boolean,
    sub_process_id integer,
    milestone character varying,
    description character varying
  )
;


--
-- Name: protocol_events_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.protocol_events_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: protocol_events_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.protocol_events_id_seq owned by ml_app.protocol_events.id
;


--
-- Name: protocol_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.protocol_history (
    id integer not null,
    name character varying,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    disabled boolean,
    admin_id integer,
    "position" integer,
    protocol_id integer
  )
;


--
-- Name: protocol_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.protocol_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: protocol_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.protocol_history_id_seq owned by ml_app.protocol_history.id
;


--
-- Name: protocols; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.protocols (
    id integer not null,
    name character varying,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    disabled boolean,
    admin_id integer,
    "position" integer,
    app_type_id bigint
  )
;


--
-- Name: protocols_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.protocols_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: protocols_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.protocols_id_seq owned by ml_app.protocols.id
;


--
-- Name: rc_cis; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.rc_cis (
    id integer not null,
    fname character varying,
    lname character varying,
    status character varying,
    created_at timestamp without time zone default now(),
    updated_at timestamp without time zone default now(),
    user_id integer,
    master_id integer,
    street character varying,
    street2 character varying,
    city character varying,
    state character varying,
    zip character varying,
    phone character varying,
    email character varying,
    form_date timestamp without time zone
  )
;


--
-- Name: rc_cis2; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.rc_cis2 (
    id integer,
    fname character varying,
    lname character varying,
    status character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer
  )
;


--
-- Name: rc_cis_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.rc_cis_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: rc_cis_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.rc_cis_id_seq owned by ml_app.rc_cis.id
;


--
-- Name: rc_stage_cif_copy; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.rc_stage_cif_copy (
    id integer not null,
    record_id integer,
    redcap_survey_identifier integer,
    time_stamp timestamp without time zone,
    first_name character varying,
    middle_name character varying,
    last_name character varying,
    nick_name character varying,
    street character varying,
    street2 character varying,
    city character varying,
    state character varying,
    zipcode character varying,
    phone character varying,
    email character varying,
    hearabout character varying,
    completed integer,
    status character varying,
    created_at timestamp without time zone default '2017-09-25 15:43:37.419709'::timestamp without time zone,
    user_id integer,
    master_id integer,
    updated_at timestamp without time zone default '2017-09-25 15:43:37.419709'::timestamp without time zone,
    added_tracker boolean
  )
;


--
-- Name: rc_stage_cif_copy_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.rc_stage_cif_copy_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: rc_stage_cif_copy_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.rc_stage_cif_copy_id_seq owned by ml_app.rc_stage_cif_copy.id
;


--
-- Name: report_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.report_history (
    id integer not null,
    name character varying,
    description character varying,
    sql character varying,
    search_attrs character varying,
    admin_id integer,
    disabled boolean,
    report_type character varying,
    auto boolean,
    searchable boolean,
    "position" integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    report_id integer,
    item_type character varying,
    edit_model character varying,
    edit_field_names character varying,
    selection_fields character varying,
    short_name character varying,
    options character varying
  )
;


--
-- Name: report_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.report_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: report_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.report_history_id_seq owned by ml_app.report_history.id
;


--
-- Name: reports; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.reports (
    id integer not null,
    name character varying,
    description character varying,
    sql character varying,
    search_attrs character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    report_type character varying,
    auto boolean,
    searchable boolean,
    "position" integer,
    edit_model character varying,
    edit_field_names character varying,
    selection_fields character varying,
    item_type character varying,
    short_name character varying,
    options character varying
  )
;


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.reports_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.reports_id_seq owned by ml_app.reports.id
;


--
-- Name: role_description_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.role_description_history (
    id bigint not null,
    role_description_id bigint,
    app_type_id bigint,
    role_name character varying,
    role_template character varying,
    name character varying,
    description character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: role_description_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.role_description_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: role_description_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.role_description_history_id_seq owned by ml_app.role_description_history.id
;


--
-- Name: role_descriptions; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.role_descriptions (
    id bigint not null,
    app_type_id bigint,
    role_name character varying,
    role_template character varying,
    name character varying,
    description character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: role_descriptions_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.role_descriptions_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: role_descriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.role_descriptions_id_seq owned by ml_app.role_descriptions.id
;


--
-- Name: sage_assignments; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.sage_assignments (
    id integer not null,
    sage_id character varying(10),
    assigned_by character varying,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    master_id integer,
    admin_id integer
  )
;


--
-- Name: sage_assignments_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.sage_assignments_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: sage_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.sage_assignments_id_seq owned by ml_app.sage_assignments.id
;


--
-- Name: scantron_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.scantron_history (
    id integer not null,
    master_id integer,
    scantron_id integer,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    scantron_table_id integer
  )
;


--
-- Name: scantron_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.scantron_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: scantron_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.scantron_history_id_seq owned by ml_app.scantron_history.id
;


--
-- Name: scantron_series_two_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.scantron_series_two_history (
    id integer not null,
    scantron_series_two_id integer,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: scantron_series_two_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.scantron_series_two_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: scantron_series_two_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.scantron_series_two_history_id_seq owned by ml_app.scantron_series_two_history.id
;


--
-- Name: scantron_series_twos; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.scantron_series_twos (
    id integer not null,
    master_id integer,
    external_id bigint,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: scantron_series_twos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.scantron_series_twos_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: scantron_series_twos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.scantron_series_twos_id_seq owned by ml_app.scantron_series_twos.id
;


--
-- Name: scantrons; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.scantrons (
    id integer not null,
    master_id integer,
    scantron_id integer,
    user_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: scantrons_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.scantrons_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: scantrons_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.scantrons_id_seq owned by ml_app.scantrons.id
;


--
-- Name: schema_migrations; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.schema_migrations (version character varying not null)
;


--
-- Name: sessions; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.sessions (
    id bigint not null,
    session_id character varying not null,
    data text,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.sessions_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.sessions_id_seq owned by ml_app.sessions.id
;


--
-- Name: smback; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.smback (version character varying)
;


--
-- Name: sub_process_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.sub_process_history (
    id integer not null,
    name character varying,
    disabled boolean,
    protocol_id integer,
    admin_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    sub_process_id integer
  )
;


--
-- Name: sub_process_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.sub_process_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: sub_process_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.sub_process_history_id_seq owned by ml_app.sub_process_history.id
;


--
-- Name: sub_processes; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.sub_processes (
    id integer not null,
    name character varying,
    disabled boolean,
    protocol_id integer,
    admin_id integer,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: sub_processes_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.sub_processes_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: sub_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.sub_processes_id_seq owned by ml_app.sub_processes.id
;


--
-- Name: tracker_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.tracker_history (
    id integer not null,
    master_id integer,
    protocol_id integer,
    tracker_id integer,
    event_date timestamp without time zone,
    user_id integer,
    notes character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    sub_process_id integer,
    protocol_event_id integer,
    item_id integer,
    item_type character varying
  )
;


--
-- Name: tracker_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.tracker_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: tracker_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.tracker_history_id_seq owned by ml_app.tracker_history.id
;


--
-- Name: trackers; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.trackers (
    id integer not null,
    master_id integer,
    protocol_id integer not null,
    event_date timestamp without time zone,
    user_id integer default ml_app.current_user_id (),
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    notes character varying,
    sub_process_id integer not null,
    protocol_event_id integer,
    item_id integer,
    item_type character varying
  )
;


--
-- Name: trackers_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.trackers_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.trackers_id_seq owned by ml_app.trackers.id
;


--
-- Name: user_access_controls; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.user_access_controls (
    id integer not null,
    user_id integer,
    resource_type character varying,
    resource_name character varying,
    options character varying,
    access character varying,
    disabled boolean,
    admin_id integer,
    app_type_id integer,
    role_name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
  )
;


--
-- Name: user_access_controls_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.user_access_controls_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: user_access_controls_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.user_access_controls_id_seq owned by ml_app.user_access_controls.id
;


--
-- Name: user_action_logs; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.user_action_logs (
    id integer not null,
    user_id integer,
    app_type_id integer,
    master_id integer,
    item_type character varying,
    item_id integer,
    index_action_ids integer[],
    action character varying,
    url character varying,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: user_action_logs_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.user_action_logs_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: user_action_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.user_action_logs_id_seq owned by ml_app.user_action_logs.id
;


--
-- Name: user_authorization_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.user_authorization_history (
    id integer not null,
    user_id character varying,
    has_authorization character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    user_authorization_id integer
  )
;


--
-- Name: user_authorization_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.user_authorization_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: user_authorization_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.user_authorization_history_id_seq owned by ml_app.user_authorization_history.id
;


--
-- Name: user_authorizations; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.user_authorizations (
    id integer not null,
    user_id integer,
    has_authorization character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: user_authorizations_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.user_authorizations_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: user_authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.user_authorizations_id_seq owned by ml_app.user_authorizations.id
;


--
-- Name: user_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.user_history (
    id integer not null,
    email character varying default ''::character varying not null,
    encrypted_password character varying default ''::character varying not null,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer default 0 not null,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    failed_attempts integer default 0 not null,
    unlock_token character varying,
    locked_at timestamp without time zone,
    disabled boolean,
    admin_id integer,
    user_id integer,
    app_type_id integer,
    authentication_token character varying,
    consumed_timestep integer,
    otp_required_for_login boolean,
    password_updated_at timestamp without time zone,
    first_name character varying,
    last_name character varying,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    do_not_email boolean,
    otp_secret character varying,
    country_code character varying,
    terms_of_use_accepted character varying
  )
;


--
-- Name: user_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.user_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: user_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.user_history_id_seq owned by ml_app.user_history.id
;


--
-- Name: user_preferences; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.user_preferences (
    id bigint not null,
    user_id bigint,
    date_format character varying,
    date_time_format character varying,
    time_format character varying,
    timezone character varying,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: user_preferences_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.user_preferences_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: user_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.user_preferences_id_seq owned by ml_app.user_preferences.id
;


--
-- Name: user_role_history; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.user_role_history (
    id integer not null,
    app_type_id bigint,
    role_name character varying,
    user_id bigint,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_role_id integer
  )
;


--
-- Name: user_role_history_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.user_role_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: user_role_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.user_role_history_id_seq owned by ml_app.user_role_history.id
;


--
-- Name: user_roles; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.user_roles (
    id integer not null,
    app_type_id integer,
    role_name character varying,
    user_id integer,
    admin_id integer,
    disabled boolean default false not null,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.user_roles_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.user_roles_id_seq owned by ml_app.user_roles.id
;


--
-- Name: users; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.users (
    id integer not null,
    email character varying default ''::character varying not null,
    encrypted_password character varying default ''::character varying not null,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer default 0 not null,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    failed_attempts integer default 0 not null,
    unlock_token character varying,
    locked_at timestamp without time zone,
    disabled boolean,
    admin_id integer,
    app_type_id integer,
    authentication_token character varying(30),
    consumed_timestep integer,
    otp_required_for_login boolean,
    password_updated_at timestamp without time zone,
    first_name character varying,
    last_name character varying,
    do_not_email boolean default false,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    country_code character varying,
    terms_of_use_accepted character varying,
    otp_secret character varying
  )
;


--
-- Name: users_contact_infos; Type: TABLE; Schema: ml_app; Owner: -
--
create table
  ml_app.users_contact_infos (
    id integer not null,
    user_id integer,
    sms_number character varying,
    phone_number character varying,
    alt_email character varying,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    admin_id integer,
    disabled boolean
  )
;


--
-- Name: users_contact_infos_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.users_contact_infos_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: users_contact_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.users_contact_infos_id_seq owned by ml_app.users_contact_infos.id
;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: ml_app; Owner: -
--
create sequence ml_app.users_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: ml_app; Owner: -
--
alter sequence ml_app.users_id_seq owned by ml_app.users.id
;


--
-- Name: view_users; Type: VIEW; Schema: ml_app; Owner: -
--
create table
  ref_data.data_variable_package_history (
    id bigint not null,
    name character varying,
    tag_select_health_categories character varying[],
    package_type character varying,
    storage_type character varying,
    db_or_fs character varying,
    schema_or_path character varying,
    table_or_file character varying,
    is_static boolean,
    sourced_from_packages character varying,
    n_for_timepoints jsonb,
    description character varying,
    disabled boolean,
    user_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    data_variable_package_id bigint
  )
;


--
-- Name: COLUMN data_variable_package_history.name; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.name is 'Name'
;


--
-- Name: COLUMN data_variable_package_history.tag_select_health_categories; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.tag_select_health_categories is 'Health Categories'
;


--
-- Name: COLUMN data_variable_package_history.package_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.package_type is 'Package type'
;


--
-- Name: COLUMN data_variable_package_history.storage_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.storage_type is 'Type of storage for dataset'
;


--
-- Name: COLUMN data_variable_package_history.db_or_fs; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.db_or_fs is 'Database or Filesystem name'
;


--
-- Name: COLUMN data_variable_package_history.schema_or_path; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.schema_or_path is 'Database schema or Filesystem directory path'
;


--
-- Name: COLUMN data_variable_package_history.table_or_file; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.table_or_file is 'Database table / view name, or filename in directory'
;


--
-- Name: COLUMN data_variable_package_history.is_static; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.is_static is 'Static, unchanging dataset'
;


--
-- Name: COLUMN data_variable_package_history.sourced_from_packages; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.sourced_from_packages is 'List of packages dataset is sourced from (empty if it is the primary source)'
;


--
-- Name: COLUMN data_variable_package_history.n_for_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.n_for_timepoints is 'For each named timepoint (name:), the population or count of
responses (n:), with notes (notes:)'
;


--
-- Name: COLUMN data_variable_package_history.description; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.description is 'Description'
;


--
-- Name: COLUMN data_variable_package_history.disabled; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_history.disabled is 'Disabled'
;


--
-- Name: data_variable_package_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.data_variable_package_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: data_variable_package_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.data_variable_package_history_id_seq owned by ref_data.data_variable_package_history.id
;


--
-- Name: data_variable_package_var_history; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.data_variable_package_var_history (
    id bigint not null,
    data_variable_package_id integer,
    domain character varying,
    record_id integer,
    variable_name character varying,
    record_type character varying,
    disabled boolean,
    user_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    data_variable_package_var_id bigint
  )
;


--
-- Name: COLUMN data_variable_package_var_history.domain; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_var_history.domain is 'Domain'
;


--
-- Name: COLUMN data_variable_package_var_history.record_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_var_history.record_id is 'Link to Variable'
;


--
-- Name: data_variable_package_var_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.data_variable_package_var_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: data_variable_package_var_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.data_variable_package_var_history_id_seq owned by ref_data.data_variable_package_var_history.id
;


--
-- Name: data_variable_package_vars; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.data_variable_package_vars (
    id bigint not null,
    data_variable_package_id integer,
    domain character varying,
    record_id integer,
    variable_name character varying,
    record_type character varying,
    disabled boolean,
    user_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: TABLE data_variable_package_vars; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on table ref_data.data_variable_package_vars is 'Dynamicmodel: Data Variable Packages'
;


--
-- Name: COLUMN data_variable_package_vars.domain; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_vars.domain is 'Domain'
;


--
-- Name: COLUMN data_variable_package_vars.record_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_package_vars.record_id is 'Link to Variable'
;


--
-- Name: data_variable_package_vars_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.data_variable_package_vars_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: data_variable_package_vars_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.data_variable_package_vars_id_seq owned by ref_data.data_variable_package_vars.id
;


--
-- Name: data_variable_packages; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.data_variable_packages (
    id bigint not null,
    name character varying,
    tag_select_health_categories character varying[],
    package_type character varying,
    storage_type character varying,
    db_or_fs character varying,
    schema_or_path character varying,
    table_or_file character varying,
    is_static boolean,
    sourced_from_packages character varying,
    n_for_timepoints jsonb,
    description character varying,
    disabled boolean,
    user_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: TABLE data_variable_packages; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on table ref_data.data_variable_packages is 'Dynamicmodel: Data Variable Packages'
;


--
-- Name: COLUMN data_variable_packages.name; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.name is 'Name'
;


--
-- Name: COLUMN data_variable_packages.tag_select_health_categories; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.tag_select_health_categories is 'Health Categories'
;


--
-- Name: COLUMN data_variable_packages.package_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.package_type is 'Package type'
;


--
-- Name: COLUMN data_variable_packages.storage_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.storage_type is 'Type of storage for dataset'
;


--
-- Name: COLUMN data_variable_packages.db_or_fs; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.db_or_fs is 'Database or Filesystem name'
;


--
-- Name: COLUMN data_variable_packages.schema_or_path; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.schema_or_path is 'Database schema or Filesystem directory path'
;


--
-- Name: COLUMN data_variable_packages.table_or_file; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.table_or_file is 'Database table / view name, or filename in directory'
;


--
-- Name: COLUMN data_variable_packages.is_static; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.is_static is 'Static, unchanging dataset'
;


--
-- Name: COLUMN data_variable_packages.sourced_from_packages; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.sourced_from_packages is 'List of packages dataset is sourced from (empty if it is the primary source)'
;


--
-- Name: COLUMN data_variable_packages.n_for_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.n_for_timepoints is 'For each named timepoint (name:), the population or count of
responses (n:), with notes (notes:)'
;


--
-- Name: COLUMN data_variable_packages.description; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.description is 'Description'
;


--
-- Name: COLUMN data_variable_packages.disabled; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.data_variable_packages.disabled is 'Disabled'
;


--
-- Name: data_variable_packages_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.data_variable_packages_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: data_variable_packages_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.data_variable_packages_id_seq owned by ref_data.data_variable_packages.id
;


--
-- Name: datadic_choice_history; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.datadic_choice_history (
    id bigint not null,
    datadic_choice_id bigint,
    source_name character varying,
    source_type character varying,
    form_name character varying,
    field_name character varying,
    value character varying,
    label character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: datadic_choice_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.datadic_choice_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: datadic_choice_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.datadic_choice_history_id_seq owned by ref_data.datadic_choice_history.id
;


--
-- Name: datadic_choices; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.datadic_choices (
    id bigint not null,
    source_name character varying,
    source_type character varying,
    form_name character varying,
    field_name character varying,
    value character varying,
    label character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: datadic_choices_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.datadic_choices_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: datadic_choices_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.datadic_choices_id_seq owned by ref_data.datadic_choices.id
;


--
-- Name: datadic_variable_history; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.datadic_variable_history (
    id bigint not null,
    datadic_variable_id bigint,
    study character varying,
    source_name character varying,
    source_type character varying,
    domain character varying,
    form_name character varying,
    variable_name character varying,
    variable_type character varying,
    presentation_type character varying,
    label character varying,
    label_note character varying,
    annotation character varying,
    is_required boolean,
    valid_type character varying,
    valid_min character varying,
    valid_max character varying,
    multi_valid_choices character varying[],
    is_identifier boolean,
    is_derived_var boolean,
    multi_derived_from_id bigint[],
    doc_url character varying,
    target_type character varying,
    owner_email character varying,
    classification character varying,
    other_classification character varying,
    multi_timepoints character varying[],
    equivalent_to_id bigint,
    storage_type character varying,
    db_or_fs character varying,
    schema_or_path character varying,
    table_or_file character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    "position" integer,
    section_id integer,
    sub_section_id integer,
    title character varying,
    storage_varname character varying,
    contributor_type character varying,
    n_for_timepoints jsonb,
    notes character varying,
    user_id integer
  )
;


--
-- Name: COLUMN datadic_variable_history.study; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.study is 'Study name'
;


--
-- Name: COLUMN datadic_variable_history.source_name; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.source_name is 'Source of variable'
;


--
-- Name: COLUMN datadic_variable_history.source_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.source_type is 'Source type'
;


--
-- Name: COLUMN datadic_variable_history.domain; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.domain is 'Domain'
;


--
-- Name: COLUMN datadic_variable_history.form_name; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.form_name is 'Form name (if the source was a type of form)'
;


--
-- Name: COLUMN datadic_variable_history.variable_name; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.variable_name is 'Variable name'
;


--
-- Name: COLUMN datadic_variable_history.variable_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.variable_type is 'Variable type'
;


--
-- Name: COLUMN datadic_variable_history.presentation_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.presentation_type is 'Data type for presentation purposes'
;


--
-- Name: COLUMN datadic_variable_history.label; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.label is 'Primary label or title (if source was a form, the label presented for the field)'
;


--
-- Name: COLUMN datadic_variable_history.label_note; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.label_note is 'Description (if source was a form, a note presented for the field)'
;


--
-- Name: COLUMN datadic_variable_history.annotation; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.annotation is 'Annotations (if source was a form, annotations not presented to the user)'
;


--
-- Name: COLUMN datadic_variable_history.is_required; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.is_required is 'Was required in source'
;


--
-- Name: COLUMN datadic_variable_history.valid_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.valid_type is 'Source data type'
;


--
-- Name: COLUMN datadic_variable_history.valid_min; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.valid_min is 'Minimum value'
;


--
-- Name: COLUMN datadic_variable_history.valid_max; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.valid_max is 'Maximum value'
;


--
-- Name: COLUMN datadic_variable_history.multi_valid_choices; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.multi_valid_choices is 'List of valid choices for categorical variables'
;


--
-- Name: COLUMN datadic_variable_history.is_identifier; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.is_identifier is 'Represents identifiable information'
;


--
-- Name: COLUMN datadic_variable_history.is_derived_var; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.is_derived_var is 'Is a derived variable'
;


--
-- Name: COLUMN datadic_variable_history.multi_derived_from_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.multi_derived_from_id is 'If a derived variable, ids of variables used to calculate it'
;


--
-- Name: COLUMN datadic_variable_history.doc_url; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.doc_url is 'URL to additional documentation'
;


--
-- Name: COLUMN datadic_variable_history.target_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.target_type is 'Type of participant this variable relates to'
;


--
-- Name: COLUMN datadic_variable_history.owner_email; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.owner_email is 'Owner, especially for derived variables'
;


--
-- Name: COLUMN datadic_variable_history.classification; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.classification is 'Category of sensitivity from a privacy perspective'
;


--
-- Name: COLUMN datadic_variable_history.other_classification; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.other_classification is 'Additional information regarding classification'
;


--
-- Name: COLUMN datadic_variable_history.multi_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.multi_timepoints is 'Timepoints this data is collected (in longitudinal studies)'
;


--
-- Name: COLUMN datadic_variable_history.equivalent_to_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.equivalent_to_id is 'Primary variable id this is equivalent to'
;


--
-- Name: COLUMN datadic_variable_history.storage_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.storage_type is 'Type of storage for dataset'
;


--
-- Name: COLUMN datadic_variable_history.db_or_fs; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.db_or_fs is 'Database or Filesystem name'
;


--
-- Name: COLUMN datadic_variable_history.schema_or_path; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.schema_or_path is 'Database schema or Filesystem directory path'
;


--
-- Name: COLUMN datadic_variable_history.table_or_file; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.table_or_file is 'Database table (or view, if derived or equivalent to another variable), or filename in directory'
;


--
-- Name: COLUMN datadic_variable_history.redcap_data_dictionary_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.redcap_data_dictionary_id is 'Reference to REDCap data dictionary representation'
;


--
-- Name: COLUMN datadic_variable_history."position"; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history."position" is 'Relative position (for source forms or other variables where order of collection matters)'
;


--
-- Name: COLUMN datadic_variable_history.section_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.section_id is 'Section this belongs to'
;


--
-- Name: COLUMN datadic_variable_history.sub_section_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.sub_section_id is 'Sub-section this belongs to'
;


--
-- Name: COLUMN datadic_variable_history.title; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.title is 'Section caption'
;


--
-- Name: COLUMN datadic_variable_history.storage_varname; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.storage_varname is 'Database field name, or variable name in data file'
;


--
-- Name: COLUMN datadic_variable_history.contributor_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.contributor_type is 'Type of contributor this variable was provided by'
;


--
-- Name: COLUMN datadic_variable_history.n_for_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.n_for_timepoints is 'For each named timepoint (name:), the population or count of responses (n:), with notes (notes:)'
;


--
-- Name: COLUMN datadic_variable_history.notes; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variable_history.notes is 'Notes'
;


--
-- Name: datadic_variable_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.datadic_variable_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: datadic_variable_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.datadic_variable_history_id_seq owned by ref_data.datadic_variable_history.id
;


--
-- Name: datadic_variables; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.datadic_variables (
    id bigint not null,
    study character varying,
    source_name character varying,
    source_type character varying,
    domain character varying,
    form_name character varying,
    variable_name character varying,
    variable_type character varying,
    presentation_type character varying,
    label character varying,
    label_note character varying,
    annotation character varying,
    is_required boolean,
    valid_type character varying,
    valid_min character varying,
    valid_max character varying,
    multi_valid_choices character varying[],
    is_identifier boolean,
    is_derived_var boolean,
    multi_derived_from_id bigint[],
    doc_url character varying,
    target_type character varying,
    owner_email character varying,
    classification character varying,
    other_classification character varying,
    multi_timepoints character varying[],
    equivalent_to_id bigint,
    storage_type character varying,
    db_or_fs character varying,
    schema_or_path character varying,
    table_or_file character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    "position" integer,
    section_id integer,
    sub_section_id integer,
    title character varying,
    storage_varname character varying,
    user_id bigint,
    contributor_type character varying,
    n_for_timepoints jsonb,
    notes character varying
  )
;


--
-- Name: TABLE datadic_variables; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on table ref_data.datadic_variables is 'Dynamicmodel: User Variables'
;


--
-- Name: COLUMN datadic_variables.study; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.study is 'Study name'
;


--
-- Name: COLUMN datadic_variables.source_name; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.source_name is 'Source of variable'
;


--
-- Name: COLUMN datadic_variables.source_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.source_type is 'Source type'
;


--
-- Name: COLUMN datadic_variables.domain; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.domain is 'Domain'
;


--
-- Name: COLUMN datadic_variables.form_name; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.form_name is 'Form name (if the source was a type of form)'
;


--
-- Name: COLUMN datadic_variables.variable_name; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.variable_name is 'Variable name'
;


--
-- Name: COLUMN datadic_variables.variable_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.variable_type is 'Variable type'
;


--
-- Name: COLUMN datadic_variables.presentation_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.presentation_type is 'Data type for presentation purposes'
;


--
-- Name: COLUMN datadic_variables.label; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.label is 'Primary label or title (if source was a form, the label presented for the field)'
;


--
-- Name: COLUMN datadic_variables.label_note; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.label_note is 'Description (if source was a form, a note presented for the field)'
;


--
-- Name: COLUMN datadic_variables.annotation; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.annotation is 'Annotations (if source was a form, annotations not presented to the user)'
;


--
-- Name: COLUMN datadic_variables.is_required; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.is_required is 'Was required in source'
;


--
-- Name: COLUMN datadic_variables.valid_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.valid_type is 'Source data type'
;


--
-- Name: COLUMN datadic_variables.valid_min; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.valid_min is 'Minimum value'
;


--
-- Name: COLUMN datadic_variables.valid_max; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.valid_max is 'Maximum value'
;


--
-- Name: COLUMN datadic_variables.multi_valid_choices; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.multi_valid_choices is 'List of valid choices for categorical variables'
;


--
-- Name: COLUMN datadic_variables.is_identifier; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.is_identifier is 'Represents identifiable information'
;


--
-- Name: COLUMN datadic_variables.is_derived_var; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.is_derived_var is 'Is a derived variable'
;


--
-- Name: COLUMN datadic_variables.multi_derived_from_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.multi_derived_from_id is 'If a derived variable, ids of variables used to calculate it'
;


--
-- Name: COLUMN datadic_variables.doc_url; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.doc_url is 'URL to additional documentation'
;


--
-- Name: COLUMN datadic_variables.target_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.target_type is 'Type of participant this variable relates to'
;


--
-- Name: COLUMN datadic_variables.owner_email; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.owner_email is 'Owner, especially for derived variables'
;


--
-- Name: COLUMN datadic_variables.classification; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.classification is 'Category of sensitivity from a privacy perspective'
;


--
-- Name: COLUMN datadic_variables.other_classification; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.other_classification is 'Additional information regarding classification'
;


--
-- Name: COLUMN datadic_variables.multi_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.multi_timepoints is 'Timepoints this data is collected (in longitudinal studies)'
;


--
-- Name: COLUMN datadic_variables.equivalent_to_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.equivalent_to_id is 'Primary variable id this is equivalent to'
;


--
-- Name: COLUMN datadic_variables.storage_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.storage_type is 'Type of storage for dataset'
;


--
-- Name: COLUMN datadic_variables.db_or_fs; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.db_or_fs is 'Database or Filesystem name'
;


--
-- Name: COLUMN datadic_variables.schema_or_path; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.schema_or_path is 'Database schema or Filesystem directory path'
;


--
-- Name: COLUMN datadic_variables.table_or_file; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.table_or_file is 'Database table (or view, if derived or equivalent to another variable), or filename in directory'
;


--
-- Name: COLUMN datadic_variables.redcap_data_dictionary_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.redcap_data_dictionary_id is 'Reference to REDCap data dictionary representation'
;


--
-- Name: COLUMN datadic_variables."position"; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables."position" is 'Relative position (for source forms or other variables where order of collection matters)'
;


--
-- Name: COLUMN datadic_variables.section_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.section_id is 'Section this belongs to'
;


--
-- Name: COLUMN datadic_variables.sub_section_id; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.sub_section_id is 'Sub-section this belongs to'
;


--
-- Name: COLUMN datadic_variables.title; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.title is 'Section caption'
;


--
-- Name: COLUMN datadic_variables.storage_varname; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.storage_varname is 'Database field name, or variable name in data file'
;


--
-- Name: COLUMN datadic_variables.contributor_type; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.contributor_type is 'Type of contributor this variable was provided by'
;


--
-- Name: COLUMN datadic_variables.n_for_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.n_for_timepoints is 'For each named timepoint (name:), the population or count of responses (n:), with notes (notes:)'
;


--
-- Name: COLUMN datadic_variables.notes; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on column ref_data.datadic_variables.notes is 'Notes'
;


--
-- Name: datadic_variables_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.datadic_variables_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: datadic_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.datadic_variables_id_seq owned by ref_data.datadic_variables.id
;


--
-- Name: mv_datadic_stats; Type: MATERIALIZED VIEW; Schema: ref_data; Owner: -
--
create materialized view
  ref_data.mv_datadic_stats as
with
  vars as (
    select
      var.id,
      var.study,
      var.source_name,
      var.source_type,
      var.domain,
      var.form_name,
      var.variable_name,
      var.variable_type,
      var.presentation_type,
      var.label,
      var.label_note,
      var.annotation,
      var.is_required,
      var.valid_type,
      var.valid_min,
      var.valid_max,
      var.multi_valid_choices,
      var.is_identifier,
      var.is_derived_var,
      var.multi_derived_from_id,
      var.doc_url,
      var.target_type,
      var.owner_email,
      var.classification,
      var.other_classification,
      var.multi_timepoints,
      var.equivalent_to_id,
      var.storage_type,
      var.db_or_fs,
      var.schema_or_path,
      var.table_or_file,
      var.disabled,
      var.admin_id,
      var.redcap_data_dictionary_id,
      var.created_at,
      var.updated_at,
      var."position",
      var.section_id,
      var.sub_section_id,
      var.title,
      var.storage_varname,
      var.user_id
    from
      ref_data.datadic_variables var
    where
      (
        (not coalesce(var.disabled, false))
        and ((var.variable_name)::text <> 'participant_id'::text)
        and (nullif((var.storage_varname)::text, ''::text) is not null)
      )
  )
select
  var.id as variable_id,
  stats.variable as variable_name,
  var.label as variable_label,
  stats.results,
  stats.labels,
  stats.mean,
  stats.stddev,
  stats.min,
  stats.med,
  stats.max,
  null::character varying as choices,
  stats.distincts,
  stats.completed,
  stats.total_recs
from
  (
    vars var
    join lateral ref_data.calc_var_stats_for_numeric (var.id) stats (
      variable_id,
      variable,
      results,
      labels,
      min,
      med,
      max,
      mean,
      stddev,
      distincts,
      completed,
      total_recs,
      "chart:"
    ) on ((stats.variable is not null))
  )
where
  (
    (var.table_or_file is not null)
    and (
      (var.variable_type)::text = any (array[('numeric'::character varying)::text, ('calculated'::character varying)::text])
    )
  )
union
select
  var.id as variable_id,
  stats.variable as variable_name,
  var.label as variable_label,
  stats.results,
  stats.labels,
  null::numeric as mean,
  null::numeric as stddev,
  null::numeric as min,
  null::numeric as med,
  null::numeric as max,
  (to_json(var.multi_valid_choices))::character varying as choices,
  stats.distincts,
  stats.completed,
  stats.total_recs
from
  (
    vars var
    join lateral ref_data.calc_var_stats_for_categorical (var.id) stats (variable_id, variable, results, labels, cat_counts, distincts, completed, total_recs, "chart:") on ((stats.variable is not null))
  )
where
  (
    (var.table_or_file is not null)
    and ((var.variable_type)::text = 'categorical'::text)
  )
union
select
  var.id as variable_id,
  stats.variable as variable_name,
  var.label as variable_label,
  stats.results,
  stats.labels,
  null::numeric as mean,
  null::numeric as stddev,
  null::numeric as min,
  null::numeric as med,
  null::numeric as max,
  null::character varying as choices,
  stats.distincts,
  stats.completed,
  stats.total_recs
from
  (
    vars var
    join lateral ref_data.calc_var_stats_for_boolean (var.id) stats (variable_id, variable, results, labels, cat_counts, distincts, completed, total_recs, "chart:") on ((stats.variable is not null))
  )
where
  (
    (var.table_or_file is not null)
    and ((var.variable_type)::text = 'dichotomous'::text)
  )
with
  no data
;


--
-- Name: ipa_datadic; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.ipa_datadic (
    id bigint not null,
    user_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: ipa_datadic_history; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.ipa_datadic_history (
    id bigint not null,
    user_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    ipa_datadic_id bigint
  )
;


--
-- Name: ipa_datadic_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.ipa_datadic_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: ipa_datadic_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.ipa_datadic_history_id_seq owned by ref_data.ipa_datadic_history.id
;


--
-- Name: ipa_datadic_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.ipa_datadic_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: ipa_datadic_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.ipa_datadic_id_seq owned by ref_data.ipa_datadic.id
;


--
-- Name: q1_datadic; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.q1_datadic (
    id bigint not null,
    user_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: q1_datadic_history; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.q1_datadic_history (
    id bigint not null,
    user_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    q1_datadic_id bigint
  )
;


--
-- Name: q1_datadic_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.q1_datadic_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: q1_datadic_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.q1_datadic_history_id_seq owned by ref_data.q1_datadic_history.id
;


--
-- Name: q1_datadic_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.q1_datadic_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: q1_datadic_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.q1_datadic_id_seq owned by ref_data.q1_datadic.id
;


--
-- Name: redcap_client_requests; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.redcap_client_requests (
    id bigint not null,
    redcap_project_admin_id bigint,
    action character varying,
    name character varying,
    server_url character varying,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    result jsonb
  )
;


--
-- Name: TABLE redcap_client_requests; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on table ref_data.redcap_client_requests is 'Redcap client requests'
;


--
-- Name: redcap_client_requests_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.redcap_client_requests_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: redcap_client_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.redcap_client_requests_id_seq owned by ref_data.redcap_client_requests.id
;


--
-- Name: redcap_data_collection_instrument_history; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.redcap_data_collection_instrument_history (
    id bigint not null,
    redcap_data_collection_instrument_id bigint,
    redcap_project_admin_id bigint,
    name character varying,
    label character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: redcap_data_collection_instrument_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.redcap_data_collection_instrument_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: redcap_data_collection_instrument_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.redcap_data_collection_instrument_history_id_seq owned by ref_data.redcap_data_collection_instrument_history.id
;


--
-- Name: redcap_data_collection_instruments; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.redcap_data_collection_instruments (
    id bigint not null,
    name character varying,
    label character varying,
    disabled boolean,
    redcap_project_admin_id bigint,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: redcap_data_collection_instruments_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.redcap_data_collection_instruments_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: redcap_data_collection_instruments_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.redcap_data_collection_instruments_id_seq owned by ref_data.redcap_data_collection_instruments.id
;


--
-- Name: redcap_data_dictionaries; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.redcap_data_dictionaries (
    id bigint not null,
    redcap_project_admin_id bigint,
    field_count integer,
    captured_metadata jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: TABLE redcap_data_dictionaries; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on table ref_data.redcap_data_dictionaries is 'Retrieved Redcap Data Dictionaries (metadata)'
;


--
-- Name: redcap_data_dictionaries_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.redcap_data_dictionaries_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: redcap_data_dictionaries_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.redcap_data_dictionaries_id_seq owned by ref_data.redcap_data_dictionaries.id
;


--
-- Name: redcap_data_dictionary_history; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.redcap_data_dictionary_history (
    id bigint not null,
    redcap_data_dictionary_id bigint,
    redcap_project_admin_id bigint,
    field_count integer,
    captured_metadata jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: TABLE redcap_data_dictionary_history; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on table ref_data.redcap_data_dictionary_history is 'Retrieved Redcap Data Dictionaries (metadata) - history'
;


--
-- Name: redcap_data_dictionary_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.redcap_data_dictionary_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: redcap_data_dictionary_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.redcap_data_dictionary_history_id_seq owned by ref_data.redcap_data_dictionary_history.id
;


--
-- Name: redcap_project_admin_history; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.redcap_project_admin_history (
    id bigint not null,
    redcap_project_admin_id bigint,
    name character varying,
    api_key character varying,
    server_url character varying,
    captured_project_info jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    transfer_mode character varying,
    frequency character varying,
    status character varying,
    post_transfer_pipeline character varying[] default '{}'::character varying[],
    notes character varying,
    study character varying,
    dynamic_model_table character varying
  )
;


--
-- Name: TABLE redcap_project_admin_history; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on table ref_data.redcap_project_admin_history is 'Redcap project administration - history'
;


--
-- Name: redcap_project_admin_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.redcap_project_admin_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: redcap_project_admin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.redcap_project_admin_history_id_seq owned by ref_data.redcap_project_admin_history.id
;


--
-- Name: redcap_project_admins; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.redcap_project_admins (
    id bigint not null,
    name character varying,
    api_key character varying,
    server_url character varying,
    captured_project_info jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null,
    transfer_mode character varying,
    frequency character varying,
    status character varying,
    post_transfer_pipeline character varying[] default '{}'::character varying[],
    notes character varying,
    study character varying,
    dynamic_model_table character varying,
    options character varying
  )
;


--
-- Name: TABLE redcap_project_admins; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on table ref_data.redcap_project_admins is 'Redcap project administration'
;


--
-- Name: redcap_project_admins_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.redcap_project_admins_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: redcap_project_admins_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.redcap_project_admins_id_seq owned by ref_data.redcap_project_admins.id
;


--
-- Name: redcap_project_user_history; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.redcap_project_user_history (
    id bigint not null,
    redcap_project_user_id bigint,
    redcap_project_admin_id bigint,
    username character varying,
    email character varying,
    expiration character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: redcap_project_user_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.redcap_project_user_history_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: redcap_project_user_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.redcap_project_user_history_id_seq owned by ref_data.redcap_project_user_history.id
;


--
-- Name: redcap_project_users; Type: TABLE; Schema: ref_data; Owner: -
--
create table
  ref_data.redcap_project_users (
    id bigint not null,
    redcap_project_admin_id bigint,
    username character varying,
    email character varying,
    expiration character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone not null,
    updated_at timestamp without time zone not null
  )
;


--
-- Name: redcap_project_users_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--
create sequence ref_data.redcap_project_users_id_seq start
with
  1 increment by 1 no minvalue no maxvalue cache 1
;


--
-- Name: redcap_project_users_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--
alter sequence ref_data.redcap_project_users_id_seq owned by ref_data.redcap_project_users.id
;


--
-- Name: view_datadic_studies; Type: VIEW; Schema: ref_data; Owner: -
--
create view
  ref_data.view_datadic_studies as
select distinct
  datadic_variables.study
from
  ref_data.datadic_variables
where
  (not coalesce(datadic_variables.disabled, false))
order by
  datadic_variables.study
;


--
-- Name: VIEW view_datadic_studies; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on view ref_data.view_datadic_studies is 'Dynamicmodel: View Data Dictionary Studies'
;


--
-- Name: view_searchable_domains; Type: VIEW; Schema: ref_data; Owner: -
--
create view
  ref_data.view_searchable_domains as
select distinct
  dm.domain_title,
  dv.domain
from
  (
    ref_data.datadic_variables dv
    left join ref_data.domain_mappings dm on (
      (
        ((dv.domain)::text = (dm.domain)::text)
        and (not coalesce(dm.disabled, false))
      )
    )
  )
where
  (
    (not coalesce(dv.disabled, false))
    and (not coalesce(dm.hide_from_datadic, false))
  )
order by
  dm.domain_title
;


--
-- Name: VIEW view_searchable_domains; Type: COMMENT; Schema: ref_data; Owner: -
--
comment on view ref_data.view_searchable_domains is 'Dynamicmodel: View Searchable Domains'
;


--
-- Name: accuracy_score_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.accuracy_score_history
alter column id
set default nextval('ml_app.accuracy_score_history_id_seq'::regclass)
;


--
-- Name: accuracy_scores id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.accuracy_scores
alter column id
set default nextval('ml_app.accuracy_scores_id_seq'::regclass)
;


--
-- Name: activity_log_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_history
alter column id
set default nextval('ml_app.activity_log_history_id_seq'::regclass)
;


--
-- Name: activity_log_new_test_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_new_test_history
alter column id
set default nextval('ml_app.activity_log_new_test_history_id_seq'::regclass)
;


--
-- Name: activity_log_new_tests id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_new_tests
alter column id
set default nextval('ml_app.activity_log_new_tests_id_seq'::regclass)
;


--
-- Name: activity_log_player_contact_emails id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_emails
alter column id
set default nextval('ml_app.activity_log_player_contact_emails_id_seq'::regclass)
;


--
-- Name: activity_log_player_contact_phone_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phone_history
alter column id
set default nextval('ml_app.activity_log_player_contact_phone_history_id_seq'::regclass)
;


--
-- Name: activity_log_player_contact_phones id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phones
alter column id
set default nextval('ml_app.activity_log_player_contact_phones_id_seq'::regclass)
;


--
-- Name: activity_log_player_info_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phones
alter column id
set default nextval('ml_app.activity_log_player_contact_phones_id_seq'::regclass)
;


--
-- Name: activity_logs id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_logs
alter column id
set default nextval('ml_app.activity_logs_id_seq'::regclass)
;


--
-- Name: address_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.address_history
alter column id
set default nextval('ml_app.address_history_id_seq'::regclass)
;


--
-- Name: addresses id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.addresses
alter column id
set default nextval('ml_app.addresses_id_seq'::regclass)
;


--
-- Name: admin_action_logs id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.admin_action_logs
alter column id
set default nextval('ml_app.admin_action_logs_id_seq'::regclass)
;


--
-- Name: admin_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.admin_history
alter column id
set default nextval('ml_app.admin_history_id_seq'::regclass)
;


--
-- Name: admins id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.admins
alter column id
set default nextval('ml_app.admins_id_seq'::regclass)
;


--
-- Name: app_configurations id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.app_configurations
alter column id
set default nextval('ml_app.app_configurations_id_seq'::regclass)
;


--
-- Name: app_types id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.app_types
alter column id
set default nextval('ml_app.app_types_id_seq'::regclass)
;


--
-- Name: college_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.college_history
alter column id
set default nextval('ml_app.college_history_id_seq'::regclass)
;


--
-- Name: colleges id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.colleges
alter column id
set default nextval('ml_app.colleges_id_seq'::regclass)
;


--
-- Name: config_libraries id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.config_libraries
alter column id
set default nextval('ml_app.config_libraries_id_seq'::regclass)
;


--
-- Name: config_library_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.config_library_history
alter column id
set default nextval('ml_app.config_library_history_id_seq'::regclass)
;


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.delayed_jobs
alter column id
set default nextval('ml_app.delayed_jobs_id_seq'::regclass)
;


--
-- Name: dynamic_model_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.dynamic_model_history
alter column id
set default nextval('ml_app.dynamic_model_history_id_seq'::regclass)
;


--
-- Name: dynamic_models id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.dynamic_models
alter column id
set default nextval('ml_app.dynamic_models_id_seq'::regclass)
;


--
-- Name: exception_logs id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.exception_logs
alter column id
set default nextval('ml_app.exception_logs_id_seq'::regclass)
;


--
-- Name: external_identifier_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_identifier_history
alter column id
set default nextval('ml_app.external_identifier_history_id_seq'::regclass)
;


--
-- Name: external_identifiers id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_identifiers
alter column id
set default nextval('ml_app.external_identifiers_id_seq'::regclass)
;


--
-- Name: external_link_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_link_history
alter column id
set default nextval('ml_app.external_link_history_id_seq'::regclass)
;


--
-- Name: external_links id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_links
alter column id
set default nextval('ml_app.external_links_id_seq'::regclass)
;


--
-- Name: general_selection_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.general_selection_history
alter column id
set default nextval('ml_app.general_selection_history_id_seq'::regclass)
;


--
-- Name: general_selections id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.general_selections
alter column id
set default nextval('ml_app.general_selections_id_seq'::regclass)
;


--
-- Name: imports id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.imports
alter column id
set default nextval('ml_app.imports_id_seq'::regclass)
;


--
-- Name: imports_model_generators id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.imports_model_generators
alter column id
set default nextval('ml_app.imports_model_generators_id_seq'::regclass)
;


--
-- Name: item_flag_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flag_history
alter column id
set default nextval('ml_app.item_flag_history_id_seq'::regclass)
;


--
-- Name: item_flag_name_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flag_name_history
alter column id
set default nextval('ml_app.item_flag_name_history_id_seq'::regclass)
;


--
-- Name: item_flag_names id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flag_names
alter column id
set default nextval('ml_app.item_flag_names_id_seq'::regclass)
;


--
-- Name: item_flags id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flags
alter column id
set default nextval('ml_app.item_flags_id_seq'::regclass)
;


--
-- Name: manage_users id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.manage_users
alter column id
set default nextval('ml_app.manage_users_id_seq'::regclass)
;


--
-- Name: masters id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.masters
alter column id
set default nextval('ml_app.masters_id_seq'::regclass)
;


--
-- Name: message_notifications id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_notifications
alter column id
set default nextval('ml_app.message_notifications_id_seq'::regclass)
;


--
-- Name: message_template_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_template_history
alter column id
set default nextval('ml_app.message_template_history_id_seq'::regclass)
;


--
-- Name: message_templates id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_templates
alter column id
set default nextval('ml_app.message_templates_id_seq'::regclass)
;


--
-- Name: model_references id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.model_references
alter column id
set default nextval('ml_app.model_references_id_seq'::regclass)
;


--
-- Name: nfs_store_archived_file_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_archived_file_history
alter column id
set default nextval('ml_app.nfs_store_archived_file_history_id_seq'::regclass)
;


--
-- Name: nfs_store_archived_files id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_archived_files
alter column id
set default nextval('ml_app.nfs_store_archived_files_id_seq'::regclass)
;


--
-- Name: nfs_store_container_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_container_history
alter column id
set default nextval('ml_app.nfs_store_container_history_id_seq'::regclass)
;


--
-- Name: nfs_store_containers id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_containers
alter column id
set default nextval('ml_app.nfs_store_containers_id_seq'::regclass)
;


--
-- Name: nfs_store_downloads id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_downloads
alter column id
set default nextval('ml_app.nfs_store_downloads_id_seq'::regclass)
;


--
-- Name: nfs_store_filters id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_filters
alter column id
set default nextval('ml_app.nfs_store_filters_id_seq'::regclass)
;


--
-- Name: nfs_store_move_actions id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_move_actions
alter column id
set default nextval('ml_app.nfs_store_move_actions_id_seq'::regclass)
;


--
-- Name: nfs_store_stored_file_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_stored_file_history
alter column id
set default nextval('ml_app.nfs_store_stored_file_history_id_seq'::regclass)
;


--
-- Name: nfs_store_stored_files id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_stored_files
alter column id
set default nextval('ml_app.nfs_store_stored_files_id_seq'::regclass)
;


--
-- Name: nfs_store_uploads id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_uploads
alter column id
set default nextval('ml_app.nfs_store_uploads_id_seq'::regclass)
;


--
-- Name: nfs_store_user_file_actions id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_user_file_actions
alter column id
set default nextval('ml_app.nfs_store_user_file_actions_id_seq'::regclass)
;


--
-- Name: page_layout_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.page_layout_history
alter column id
set default nextval('ml_app.page_layout_history_id_seq'::regclass)
;


--
-- Name: page_layouts id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.page_layouts
alter column id
set default nextval('ml_app.page_layouts_id_seq'::regclass)
;


--
-- Name: player_contact_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_contact_history
alter column id
set default nextval('ml_app.player_contact_history_id_seq'::regclass)
;


--
-- Name: player_contacts id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_contacts
alter column id
set default nextval('ml_app.player_contacts_id_seq'::regclass)
;


--
-- Name: player_info_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_info_history
alter column id
set default nextval('ml_app.player_info_history_id_seq'::regclass)
;


--
-- Name: player_infos id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_infos
alter column id
set default nextval('ml_app.player_infos_id_seq'::regclass)
;


--
-- Name: pro_infos id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.pro_infos
alter column id
set default nextval('ml_app.pro_infos_id_seq'::regclass)
;


--
-- Name: protocol_event_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocol_event_history
alter column id
set default nextval('ml_app.protocol_event_history_id_seq'::regclass)
;


--
-- Name: protocol_events id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocol_events
alter column id
set default nextval('ml_app.protocol_events_id_seq'::regclass)
;


--
-- Name: protocol_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocol_history
alter column id
set default nextval('ml_app.protocol_history_id_seq'::regclass)
;


--
-- Name: protocols id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocols
alter column id
set default nextval('ml_app.protocols_id_seq'::regclass)
;


--
-- Name: rc_cis id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.rc_cis
alter column id
set default nextval('ml_app.rc_cis_id_seq'::regclass)
;


--
-- Name: rc_stage_cif_copy id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.rc_stage_cif_copy
alter column id
set default nextval('ml_app.rc_stage_cif_copy_id_seq'::regclass)
;


--
-- Name: report_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.report_history
alter column id
set default nextval('ml_app.report_history_id_seq'::regclass)
;


--
-- Name: reports id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.reports
alter column id
set default nextval('ml_app.reports_id_seq'::regclass)
;


--
-- Name: role_description_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.role_description_history
alter column id
set default nextval('ml_app.role_description_history_id_seq'::regclass)
;


--
-- Name: role_descriptions id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.role_descriptions
alter column id
set default nextval('ml_app.role_descriptions_id_seq'::regclass)
;


--
-- Name: sage_assignments id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.sage_assignments
alter column id
set default nextval('ml_app.sage_assignments_id_seq'::regclass)
;


--
-- Name: scantron_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantron_history
alter column id
set default nextval('ml_app.scantron_history_id_seq'::regclass)
;


--
-- Name: scantron_series_two_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantron_series_two_history
alter column id
set default nextval('ml_app.scantron_series_two_history_id_seq'::regclass)
;


--
-- Name: scantron_series_twos id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantron_series_twos
alter column id
set default nextval('ml_app.scantron_series_twos_id_seq'::regclass)
;


--
-- Name: scantrons id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantrons
alter column id
set default nextval('ml_app.scantrons_id_seq'::regclass)
;


--
-- Name: sessions id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.sessions
alter column id
set default nextval('ml_app.sessions_id_seq'::regclass)
;


--
-- Name: sub_process_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.sub_process_history
alter column id
set default nextval('ml_app.sub_process_history_id_seq'::regclass)
;


--
-- Name: sub_processes id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.sub_processes
alter column id
set default nextval('ml_app.sub_processes_id_seq'::regclass)
;


--
-- Name: tracker_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.tracker_history
alter column id
set default nextval('ml_app.tracker_history_id_seq'::regclass)
;


--
-- Name: trackers id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.trackers
alter column id
set default nextval('ml_app.trackers_id_seq'::regclass)
;


--
-- Name: user_access_controls id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_access_controls
alter column id
set default nextval('ml_app.user_access_controls_id_seq'::regclass)
;


--
-- Name: user_action_logs id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_action_logs
alter column id
set default nextval('ml_app.user_action_logs_id_seq'::regclass)
;


--
-- Name: user_authorization_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_authorization_history
alter column id
set default nextval('ml_app.user_authorization_history_id_seq'::regclass)
;


--
-- Name: user_authorizations id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_authorizations
alter column id
set default nextval('ml_app.user_authorizations_id_seq'::regclass)
;


--
-- Name: user_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_history
alter column id
set default nextval('ml_app.user_history_id_seq'::regclass)
;


--
-- Name: user_preferences id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_preferences
alter column id
set default nextval('ml_app.user_preferences_id_seq'::regclass)
;


--
-- Name: user_role_history id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_role_history
alter column id
set default nextval('ml_app.user_role_history_id_seq'::regclass)
;


--
-- Name: user_roles id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_roles
alter column id
set default nextval('ml_app.user_roles_id_seq'::regclass)
;


--
-- Name: users id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.users
alter column id
set default nextval('ml_app.users_id_seq'::regclass)
;


--
-- Name: users_contact_infos id; Type: DEFAULT; Schema: ml_app; Owner: -
--
alter table only ml_app.users_contact_infos
alter column id
set default nextval('ml_app.users_contact_infos_id_seq'::regclass)
;


--
-- Name: datadic_choice_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_choice_history
alter column id
set default nextval('ref_data.datadic_choice_history_id_seq'::regclass)
;


--
-- Name: datadic_choices id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_choices
alter column id
set default nextval('ref_data.datadic_choices_id_seq'::regclass)
;


--
-- Name: datadic_variable_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variable_history
alter column id
set default nextval('ref_data.datadic_variable_history_id_seq'::regclass)
;


--
-- Name: datadic_variables id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variables
alter column id
set default nextval('ref_data.datadic_variables_id_seq'::regclass)
;


--
-- Name: domain_mapping_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.domain_mapping_history
alter column id
set default nextval('ref_data.domain_mapping_history_id_seq'::regclass)
;


--
-- Name: domain_mappings id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.domain_mappings
alter column id
set default nextval('ref_data.domain_mappings_id_seq'::regclass)
;


--
-- Name: ipa_datadic id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.ipa_datadic
alter column id
set default nextval('ref_data.ipa_datadic_id_seq'::regclass)
;


--
-- Name: ipa_datadic_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.ipa_datadic_history
alter column id
set default nextval('ref_data.ipa_datadic_history_id_seq'::regclass)
;


--
-- Name: q1_datadic id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.q1_datadic
alter column id
set default nextval('ref_data.q1_datadic_id_seq'::regclass)
;


--
-- Name: q1_datadic_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.q1_datadic_history
alter column id
set default nextval('ref_data.q1_datadic_history_id_seq'::regclass)
;


--
-- Name: redcap_client_requests id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_client_requests
alter column id
set default nextval('ref_data.redcap_client_requests_id_seq'::regclass)
;


--
-- Name: redcap_data_collection_instrument_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_collection_instrument_history
alter column id
set default nextval('ref_data.redcap_data_collection_instrument_history_id_seq'::regclass)
;


--
-- Name: redcap_data_collection_instruments id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_collection_instruments
alter column id
set default nextval('ref_data.redcap_data_collection_instruments_id_seq'::regclass)
;


--
-- Name: redcap_data_dictionaries id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_dictionaries
alter column id
set default nextval('ref_data.redcap_data_dictionaries_id_seq'::regclass)
;


--
-- Name: redcap_data_dictionary_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_dictionary_history
alter column id
set default nextval('ref_data.redcap_data_dictionary_history_id_seq'::regclass)
;


--
-- Name: redcap_project_admin_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_admin_history
alter column id
set default nextval('ref_data.redcap_project_admin_history_id_seq'::regclass)
;


--
-- Name: redcap_project_admins id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_admins
alter column id
set default nextval('ref_data.redcap_project_admins_id_seq'::regclass)
;


--
-- Name: redcap_project_user_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_user_history
alter column id
set default nextval('ref_data.redcap_project_user_history_id_seq'::regclass)
;


--
-- Name: redcap_project_users id; Type: DEFAULT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_users
alter column id
set default nextval('ref_data.redcap_project_users_id_seq'::regclass)
;


--
-- Name: accuracy_score_history accuracy_score_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.accuracy_score_history
add constraint accuracy_score_history_pkey primary key (id)
;


--
-- Name: accuracy_scores accuracy_scores_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.accuracy_scores
add constraint accuracy_scores_pkey primary key (id)
;


--
-- Name: activity_log_history activity_log_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_history
add constraint activity_log_history_pkey primary key (id)
;


--
-- Name: activity_log_new_test_history activity_log_new_test_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_new_test_history
add constraint activity_log_new_test_history_pkey primary key (id)
;


--
-- Name: activity_log_new_tests activity_log_new_tests_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_new_tests
add constraint activity_log_new_tests_pkey primary key (id)
;


--
-- Name: activity_log_player_contact_emails activity_log_player_contact_emails_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_emails
add constraint activity_log_player_contact_emails_pkey primary key (id)
;


--
-- Name: activity_log_player_contact_phone_history activity_log_player_contact_phone_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phone_history
add constraint activity_log_player_contact_phone_history_pkey primary key (id)
;


--
-- Name: activity_log_player_contact_phones activity_log_player_contact_phones_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phones
add constraint activity_log_player_contact_phones_pkey primary key (id)
;


--
-- Name: activity_log_player_info_history activity_log_player_info_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phones
add constraint activity_log_player_contact_phones_pkey primary key (id)
;


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_logs
add constraint activity_logs_pkey primary key (id)
;


--
-- Name: address_history address_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.address_history
add constraint address_history_pkey primary key (id)
;


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.addresses
add constraint addresses_pkey primary key (id)
;


--
-- Name: admin_action_logs admin_action_logs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.admin_action_logs
add constraint admin_action_logs_pkey primary key (id)
;


--
-- Name: admin_history admin_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.admin_history
add constraint admin_history_pkey primary key (id)
;


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.admins
add constraint admins_pkey primary key (id)
;


--
-- Name: app_configurations app_configurations_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.app_configurations
add constraint app_configurations_pkey primary key (id)
;


--
-- Name: app_types app_types_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.app_types
add constraint app_types_pkey primary key (id)
;


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.ar_internal_metadata
add constraint ar_internal_metadata_pkey primary key (key)
;


--
-- Name: college_history college_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.college_history
add constraint college_history_pkey primary key (id)
;


--
-- Name: colleges colleges_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.colleges
add constraint colleges_pkey primary key (id)
;


--
-- Name: config_libraries config_libraries_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.config_libraries
add constraint config_libraries_pkey primary key (id)
;


--
-- Name: config_library_history config_library_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.config_library_history
add constraint config_library_history_pkey primary key (id)
;


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.delayed_jobs
add constraint delayed_jobs_pkey primary key (id)
;


--
-- Name: dynamic_model_history dynamic_model_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.dynamic_model_history
add constraint dynamic_model_history_pkey primary key (id)
;


--
-- Name: dynamic_models dynamic_models_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.dynamic_models
add constraint dynamic_models_pkey primary key (id)
;


--
-- Name: exception_logs exception_logs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.exception_logs
add constraint exception_logs_pkey primary key (id)
;


--
-- Name: external_identifier_history external_identifier_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_identifier_history
add constraint external_identifier_history_pkey primary key (id)
;


--
-- Name: external_identifiers external_identifiers_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_identifiers
add constraint external_identifiers_pkey primary key (id)
;


--
-- Name: external_link_history external_link_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_link_history
add constraint external_link_history_pkey primary key (id)
;


--
-- Name: external_links external_links_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_links
add constraint external_links_pkey primary key (id)
;


--
-- Name: general_selection_history general_selection_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.general_selection_history
add constraint general_selection_history_pkey primary key (id)
;


--
-- Name: general_selections general_selections_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.general_selections
add constraint general_selections_pkey primary key (id)
;


--
-- Name: imports_model_generators imports_model_generators_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.imports_model_generators
add constraint imports_model_generators_pkey primary key (id)
;


--
-- Name: imports imports_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.imports
add constraint imports_pkey primary key (id)
;


--
-- Name: item_flag_history item_flag_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flag_history
add constraint item_flag_history_pkey primary key (id)
;


--
-- Name: item_flag_name_history item_flag_name_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flag_name_history
add constraint item_flag_name_history_pkey primary key (id)
;


--
-- Name: item_flag_names item_flag_names_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flag_names
add constraint item_flag_names_pkey primary key (id)
;


--
-- Name: item_flags item_flags_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flags
add constraint item_flags_pkey primary key (id)
;


--
-- Name: manage_users manage_users_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.manage_users
add constraint manage_users_pkey primary key (id)
;


--
-- Name: masters masters_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.masters
add constraint masters_pkey primary key (id)
;


--
-- Name: message_notifications message_notifications_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_notifications
add constraint message_notifications_pkey primary key (id)
;


--
-- Name: message_template_history message_template_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_template_history
add constraint message_template_history_pkey primary key (id)
;


--
-- Name: message_templates message_templates_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_templates
add constraint message_templates_pkey primary key (id)
;


--
-- Name: model_references model_references_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.model_references
add constraint model_references_pkey primary key (id)
;


--
-- Name: nfs_store_archived_file_history nfs_store_archived_file_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_archived_file_history
add constraint nfs_store_archived_file_history_pkey primary key (id)
;


--
-- Name: nfs_store_archived_files nfs_store_archived_files_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_archived_files
add constraint nfs_store_archived_files_pkey primary key (id)
;


--
-- Name: nfs_store_container_history nfs_store_container_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_container_history
add constraint nfs_store_container_history_pkey primary key (id)
;


--
-- Name: nfs_store_containers nfs_store_containers_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_containers
add constraint nfs_store_containers_pkey primary key (id)
;


--
-- Name: nfs_store_downloads nfs_store_downloads_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_downloads
add constraint nfs_store_downloads_pkey primary key (id)
;


--
-- Name: nfs_store_filters nfs_store_filters_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_filters
add constraint nfs_store_filters_pkey primary key (id)
;


--
-- Name: nfs_store_move_actions nfs_store_move_actions_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_move_actions
add constraint nfs_store_move_actions_pkey primary key (id)
;


--
-- Name: nfs_store_stored_file_history nfs_store_stored_file_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_stored_file_history
add constraint nfs_store_stored_file_history_pkey primary key (id)
;


--
-- Name: nfs_store_stored_files nfs_store_stored_files_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_stored_files
add constraint nfs_store_stored_files_pkey primary key (id)
;


--
-- Name: nfs_store_uploads nfs_store_uploads_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_uploads
add constraint nfs_store_uploads_pkey primary key (id)
;


--
-- Name: nfs_store_user_file_actions nfs_store_user_file_actions_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_user_file_actions
add constraint nfs_store_user_file_actions_pkey primary key (id)
;


--
-- Name: page_layout_history page_layout_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.page_layout_history
add constraint page_layout_history_pkey primary key (id)
;


--
-- Name: page_layouts page_layouts_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.page_layouts
add constraint page_layouts_pkey primary key (id)
;


--
-- Name: player_contact_history player_contact_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_contact_history
add constraint player_contact_history_pkey primary key (id)
;


--
-- Name: player_contacts player_contacts_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_contacts
add constraint player_contacts_pkey primary key (id)
;


--
-- Name: player_info_history player_info_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_info_history
add constraint player_info_history_pkey primary key (id)
;


--
-- Name: player_infos player_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_infos
add constraint player_infos_pkey primary key (id)
;


--
-- Name: pro_infos pro_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.pro_infos
add constraint pro_infos_pkey primary key (id)
;


--
-- Name: protocol_event_history protocol_event_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocol_event_history
add constraint protocol_event_history_pkey primary key (id)
;


--
-- Name: protocol_events protocol_events_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocol_events
add constraint protocol_events_pkey primary key (id)
;


--
-- Name: protocol_history protocol_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocol_history
add constraint protocol_history_pkey primary key (id)
;


--
-- Name: protocols protocols_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocols
add constraint protocols_pkey primary key (id)
;


--
-- Name: rc_cis rc_cis_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.rc_cis
add constraint rc_cis_pkey primary key (id)
;


--
-- Name: rc_stage_cif_copy rc_stage_cif_copy_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.rc_stage_cif_copy
add constraint rc_stage_cif_copy_pkey primary key (id)
;


--
-- Name: report_history report_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.report_history
add constraint report_history_pkey primary key (id)
;


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.reports
add constraint reports_pkey primary key (id)
;


--
-- Name: role_description_history role_description_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.role_description_history
add constraint role_description_history_pkey primary key (id)
;


--
-- Name: role_descriptions role_descriptions_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.role_descriptions
add constraint role_descriptions_pkey primary key (id)
;


--
-- Name: sage_assignments sage_assignments_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.sage_assignments
add constraint sage_assignments_pkey primary key (id)
;


--
-- Name: scantron_history scantron_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantron_history
add constraint scantron_history_pkey primary key (id)
;


--
-- Name: scantron_series_two_history scantron_series_two_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantron_series_two_history
add constraint scantron_series_two_history_pkey primary key (id)
;


--
-- Name: scantron_series_twos scantron_series_twos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantron_series_twos
add constraint scantron_series_twos_pkey primary key (id)
;


--
-- Name: scantrons scantrons_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantrons
add constraint scantrons_pkey primary key (id)
;


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.sessions
add constraint sessions_pkey primary key (id)
;


--
-- Name: sub_process_history sub_process_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.sub_process_history
add constraint sub_process_history_pkey primary key (id)
;


--
-- Name: sub_processes sub_processes_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.sub_processes
add constraint sub_processes_pkey primary key (id)
;


--
-- Name: tracker_history tracker_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.tracker_history
add constraint tracker_history_pkey primary key (id)
;


--
-- Name: trackers trackers_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.trackers
add constraint trackers_pkey primary key (id)
;


--
-- Name: user_access_controls user_access_controls_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_access_controls
add constraint user_access_controls_pkey primary key (id)
;


--
-- Name: user_action_logs user_action_logs_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_action_logs
add constraint user_action_logs_pkey primary key (id)
;


--
-- Name: user_authorization_history user_authorization_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_authorization_history
add constraint user_authorization_history_pkey primary key (id)
;


--
-- Name: user_authorizations user_authorizations_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_authorizations
add constraint user_authorizations_pkey primary key (id)
;


--
-- Name: user_history user_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_history
add constraint user_history_pkey primary key (id)
;


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_preferences
add constraint user_preferences_pkey primary key (id)
;


--
-- Name: user_role_history user_role_history_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_role_history
add constraint user_role_history_pkey primary key (id)
;


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_roles
add constraint user_roles_pkey primary key (id)
;


--
-- Name: users_contact_infos users_contact_infos_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.users_contact_infos
add constraint users_contact_infos_pkey primary key (id)
;


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.users
add constraint users_pkey primary key (id)
;


--
-- Name: datadic_choice_history datadic_choice_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_choice_history
add constraint datadic_choice_history_pkey primary key (id)
;


--
-- Name: datadic_choices datadic_choices_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_choices
add constraint datadic_choices_pkey primary key (id)
;


--
-- Name: datadic_variable_history datadic_variable_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variable_history
add constraint datadic_variable_history_pkey primary key (id)
;


--
-- Name: datadic_variables datadic_variables_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variables
add constraint datadic_variables_pkey primary key (id)
;


--
-- Name: domain_mapping_history domain_mapping_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.domain_mapping_history
add constraint domain_mapping_history_pkey primary key (id)
;


--
-- Name: domain_mappings domain_mappings_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.domain_mappings
add constraint domain_mappings_pkey primary key (id)
;


--
-- Name: ipa_datadic_history ipa_datadic_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.ipa_datadic_history
add constraint ipa_datadic_history_pkey primary key (id)
;


--
-- Name: ipa_datadic ipa_datadic_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.ipa_datadic
add constraint ipa_datadic_pkey primary key (id)
;


--
-- Name: q1_datadic_history q1_datadic_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.q1_datadic_history
add constraint q1_datadic_history_pkey primary key (id)
;


--
-- Name: q1_datadic q1_datadic_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.q1_datadic
add constraint q1_datadic_pkey primary key (id)
;


--
-- Name: redcap_client_requests redcap_client_requests_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_client_requests
add constraint redcap_client_requests_pkey primary key (id)
;


--
-- Name: redcap_data_collection_instrument_history redcap_data_collection_instrument_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_collection_instrument_history
add constraint redcap_data_collection_instrument_history_pkey primary key (id)
;


--
-- Name: redcap_data_collection_instruments redcap_data_collection_instruments_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_collection_instruments
add constraint redcap_data_collection_instruments_pkey primary key (id)
;


--
-- Name: redcap_data_dictionaries redcap_data_dictionaries_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_dictionaries
add constraint redcap_data_dictionaries_pkey primary key (id)
;


--
-- Name: redcap_data_dictionary_history redcap_data_dictionary_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_dictionary_history
add constraint redcap_data_dictionary_history_pkey primary key (id)
;


--
-- Name: redcap_project_admin_history redcap_project_admin_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_admin_history
add constraint redcap_project_admin_history_pkey primary key (id)
;


--
-- Name: redcap_project_admins redcap_project_admins_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_admins
add constraint redcap_project_admins_pkey primary key (id)
;


--
-- Name: redcap_project_user_history redcap_project_user_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_user_history
add constraint redcap_project_user_history_pkey primary key (id)
;


--
-- Name: redcap_project_users redcap_project_users_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_users
add constraint redcap_project_users_pkey primary key (id)
;


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: ml_app; Owner: -
--
create index delayed_jobs_priority on ml_app.delayed_jobs using btree (priority, run_at)
;


--
-- Name: idx_h_on_role_descriptions_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index idx_h_on_role_descriptions_id on ml_app.role_description_history using btree (role_description_id)
;


--
-- Name: index_accuracy_score_history_on_accuracy_score_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_accuracy_score_history_on_accuracy_score_id on ml_app.accuracy_score_history using btree (accuracy_score_id)
;


--
-- Name: index_accuracy_scores_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_accuracy_scores_on_admin_id on ml_app.accuracy_scores using btree (admin_id)
;


--
-- Name: index_activity_log_bhs_assignment_history_on_activity_log_bhs_a; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_bhs_assignment_history_on_activity_log_bhs_a on ml_app.activity_log_bhs_assignment_history using btree (activity_log_bhs_assignment_id)
;


--
-- Name: index_activity_log_bhs_assignment_history_on_bhs_assignment_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_bhs_assignment_history_on_bhs_assignment_id on ml_app.activity_log_bhs_assignment_history using btree (bhs_assignment_id)
;


--
-- Name: index_activity_log_bhs_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_bhs_assignment_history_on_master_id on ml_app.activity_log_bhs_assignment_history using btree (master_id)
;


--
-- Name: index_activity_log_bhs_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_bhs_assignment_history_on_user_id on ml_app.activity_log_bhs_assignment_history using btree (user_id)
;


--
-- Name: index_activity_log_bhs_assignments_on_bhs_assignment_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_bhs_assignments_on_bhs_assignment_id on ml_app.activity_log_bhs_assignments using btree (bhs_assignment_id)
;


--
-- Name: index_activity_log_bhs_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_bhs_assignments_on_master_id on ml_app.activity_log_bhs_assignments using btree (master_id)
;


--
-- Name: index_activity_log_bhs_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_bhs_assignments_on_user_id on ml_app.activity_log_bhs_assignments using btree (user_id)
;


--
-- Name: index_activity_log_ext_assignment_history_on_activity_log_ext_a; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_ext_assignment_history_on_activity_log_ext_a on ml_app.activity_log_ext_assignment_history using btree (activity_log_ext_assignment_id)
;


--
-- Name: index_activity_log_ext_assignment_history_on_ext_assignment_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_ext_assignment_history_on_ext_assignment_id on ml_app.activity_log_ext_assignment_history using btree (ext_assignment_id)
;


--
-- Name: index_activity_log_ext_assignment_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_ext_assignment_history_on_master_id on ml_app.activity_log_ext_assignment_history using btree (master_id)
;


--
-- Name: index_activity_log_ext_assignment_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_ext_assignment_history_on_user_id on ml_app.activity_log_ext_assignment_history using btree (user_id)
;


--
-- Name: index_activity_log_ext_assignments_on_ext_assignment_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_ext_assignments_on_ext_assignment_id on ml_app.activity_log_ext_assignments using btree (ext_assignment_id)
;


--
-- Name: index_activity_log_ext_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_ext_assignments_on_master_id on ml_app.activity_log_ext_assignments using btree (master_id)
;


--
-- Name: index_activity_log_ext_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_ext_assignments_on_user_id on ml_app.activity_log_ext_assignments using btree (user_id)
;


--
-- Name: index_activity_log_history_on_activity_log_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_history_on_activity_log_id on ml_app.activity_log_history using btree (activity_log_id)
;


--
-- Name: index_activity_log_new_test_history_on_activity_log_new_test_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_new_test_history_on_activity_log_new_test_id on ml_app.activity_log_new_test_history using btree (activity_log_new_test_id)
;


--
-- Name: index_activity_log_new_test_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_new_test_history_on_master_id on ml_app.activity_log_new_test_history using btree (master_id)
;


--
-- Name: index_activity_log_new_test_history_on_new_test_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_new_test_history_on_new_test_id on ml_app.activity_log_new_test_history using btree (new_test_id)
;


--
-- Name: index_activity_log_new_test_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_new_test_history_on_user_id on ml_app.activity_log_new_test_history using btree (user_id)
;


--
-- Name: index_activity_log_new_tests_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_new_tests_on_master_id on ml_app.activity_log_new_tests using btree (master_id)
;


--
-- Name: index_activity_log_new_tests_on_new_test_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_new_tests_on_new_test_id on ml_app.activity_log_new_tests using btree (new_test_id)
;


--
-- Name: index_activity_log_new_tests_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_new_tests_on_user_id on ml_app.activity_log_new_tests using btree (user_id)
;


--
-- Name: index_activity_log_player_contact_emails_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_emails_on_master_id on ml_app.activity_log_player_contact_emails using btree (master_id)
;


--
-- Name: index_activity_log_player_contact_emails_on_player_contact_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_emails_on_player_contact_id on ml_app.activity_log_player_contact_emails using btree (player_contact_id)
;


--
-- Name: index_activity_log_player_contact_emails_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_emails_on_protocol_id on ml_app.activity_log_player_contact_emails using btree (protocol_id)
;


--
-- Name: index_activity_log_player_contact_emails_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_emails_on_user_id on ml_app.activity_log_player_contact_emails using btree (user_id)
;


--
-- Name: index_activity_log_player_contact_phone_history_on_activity_log; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phone_history_on_activity_log on ml_app.activity_log_player_contact_phone_history using btree (activity_log_player_contact_phone_id)
;


--
-- Name: index_activity_log_player_contact_phone_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phone_history_on_master_id on ml_app.activity_log_player_contact_phone_history using btree (master_id)
;


--
-- Name: index_activity_log_player_contact_phone_history_on_player_conta; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phone_history_on_player_conta on ml_app.activity_log_player_contact_phone_history using btree (player_contact_id)
;


--
-- Name: index_activity_log_player_contact_phone_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phone_history_on_user_id on ml_app.activity_log_player_contact_phone_history using btree (user_id)
;


--
-- Name: index_activity_log_player_contact_phones_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phones_on_master_id on ml_app.activity_log_player_contact_phones using btree (master_id)
;


--
-- Name: index_activity_log_player_contact_phones_on_player_contact_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phones_on_player_contact_id on ml_app.activity_log_player_contact_phones using btree (player_contact_id)
;


--
-- Name: index_activity_log_player_contact_phones_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phones_on_protocol_id on ml_app.activity_log_player_contact_phones using btree (protocol_id)
;


--
-- Name: index_activity_log_player_contact_phones_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phones_on_user_id on ml_app.activity_log_player_contact_phones using btree (user_id)
;


--
-- Name: index_activity_log_player_info_history_on_activity_log_player_i; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phones_on_master_id on ml_app.activity_log_player_contact_phones using btree (master_id)
;


--
-- Name: index_activity_log_player_contact_phones_on_player_contact_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phones_on_player_contact_id on ml_app.activity_log_player_contact_phones using btree (player_contact_id)
;


--
-- Name: index_activity_log_player_contact_phones_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phones_on_protocol_id on ml_app.activity_log_player_contact_phones using btree (protocol_id)
;


--
-- Name: index_activity_log_player_contact_phones_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_activity_log_player_contact_phones_on_user_id on ml_app.activity_log_player_contact_phones using btree (user_id)
;


--
-- Name: index_address_history_on_address_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_address_history_on_address_id on ml_app.address_history using btree (address_id)
;


--
-- Name: index_address_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_address_history_on_master_id on ml_app.address_history using btree (master_id)
;


--
-- Name: index_address_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_address_history_on_user_id on ml_app.address_history using btree (user_id)
;


--
-- Name: index_addresses_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_addresses_on_master_id on ml_app.addresses using btree (master_id)
;


--
-- Name: index_addresses_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_addresses_on_user_id on ml_app.addresses using btree (user_id)
;


--
-- Name: index_admin_action_logs_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_admin_action_logs_on_admin_id on ml_app.admin_action_logs using btree (admin_id)
;


--
-- Name: index_admin_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_admin_history_on_admin_id on ml_app.admin_history using btree (admin_id)
;


--
-- Name: index_admin_history_on_upd_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_admin_history_on_upd_admin_id on ml_app.admin_history using btree (updated_by_admin_id)
;


--
-- Name: index_admins_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_admins_on_admin_id on ml_app.admins using btree (admin_id)
;


--
-- Name: index_app_configurations_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_app_configurations_on_admin_id on ml_app.app_configurations using btree (admin_id)
;


--
-- Name: index_app_configurations_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_app_configurations_on_app_type_id on ml_app.app_configurations using btree (app_type_id)
;


--
-- Name: index_app_configurations_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_app_configurations_on_user_id on ml_app.app_configurations using btree (user_id)
;


--
-- Name: index_app_types_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_app_types_on_admin_id on ml_app.app_types using btree (admin_id)
;


--
-- Name: index_college_history_on_college_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_college_history_on_college_id on ml_app.college_history using btree (college_id)
;


--
-- Name: index_colleges_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_colleges_on_admin_id on ml_app.colleges using btree (admin_id)
;


--
-- Name: index_colleges_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_colleges_on_user_id on ml_app.colleges using btree (user_id)
;


--
-- Name: index_config_libraries_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_config_libraries_on_admin_id on ml_app.config_libraries using btree (admin_id)
;


--
-- Name: index_config_library_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_config_library_history_on_admin_id on ml_app.config_library_history using btree (admin_id)
;


--
-- Name: index_config_library_history_on_config_library_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_config_library_history_on_config_library_id on ml_app.config_library_history using btree (config_library_id)
;


--
-- Name: index_dynamic_model_history_on_dynamic_model_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_dynamic_model_history_on_dynamic_model_id on ml_app.dynamic_model_history using btree (dynamic_model_id)
;


--
-- Name: index_dynamic_models_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_dynamic_models_on_admin_id on ml_app.dynamic_models using btree (admin_id)
;


--
-- Name: index_exception_logs_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_exception_logs_on_admin_id on ml_app.exception_logs using btree (admin_id)
;


--
-- Name: index_exception_logs_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_exception_logs_on_user_id on ml_app.exception_logs using btree (user_id)
;


--
-- Name: index_external_identifier_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_external_identifier_history_on_admin_id on ml_app.external_identifier_history using btree (admin_id)
;


--
-- Name: index_external_identifier_history_on_external_identifier_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_external_identifier_history_on_external_identifier_id on ml_app.external_identifier_history using btree (external_identifier_id)
;


--
-- Name: index_external_identifiers_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_external_identifiers_on_admin_id on ml_app.external_identifiers using btree (admin_id)
;


--
-- Name: index_external_link_history_on_external_link_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_external_link_history_on_external_link_id on ml_app.external_link_history using btree (external_link_id)
;


--
-- Name: index_external_links_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_external_links_on_admin_id on ml_app.external_links using btree (admin_id)
;


--
-- Name: index_general_selection_history_on_general_selection_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_general_selection_history_on_general_selection_id on ml_app.general_selection_history using btree (general_selection_id)
;


--
-- Name: index_general_selections_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_general_selections_on_admin_id on ml_app.general_selections using btree (admin_id)
;


--
-- Name: index_imports_model_generators_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_imports_model_generators_on_admin_id on ml_app.imports_model_generators using btree (admin_id)
;


--
-- Name: index_imports_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_imports_on_user_id on ml_app.imports using btree (user_id)
;


--
-- Name: index_item_flag_history_on_item_flag_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_item_flag_history_on_item_flag_id on ml_app.item_flag_history using btree (item_flag_id)
;


--
-- Name: index_item_flag_name_history_on_item_flag_name_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_item_flag_name_history_on_item_flag_name_id on ml_app.item_flag_name_history using btree (item_flag_name_id)
;


--
-- Name: index_item_flag_names_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_item_flag_names_on_admin_id on ml_app.item_flag_names using btree (admin_id)
;


--
-- Name: index_item_flags_on_item_flag_name_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_item_flags_on_item_flag_name_id on ml_app.item_flags using btree (item_flag_name_id)
;


--
-- Name: index_item_flags_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_item_flags_on_user_id on ml_app.item_flags using btree (user_id)
;


--
-- Name: index_masters_on_created_by_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_masters_on_created_by_user_id on ml_app.masters using btree (created_by_user_id)
;


--
-- Name: index_masters_on_msid; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_masters_on_msid on ml_app.masters using btree (msid)
;


--
-- Name: index_masters_on_pro_info_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_masters_on_pro_info_id on ml_app.masters using btree (pro_info_id)
;


--
-- Name: index_masters_on_proid; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_masters_on_proid on ml_app.masters using btree (pro_id)
;


--
-- Name: index_masters_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_masters_on_user_id on ml_app.masters using btree (user_id)
;


--
-- Name: index_message_notifications_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_message_notifications_on_app_type_id on ml_app.message_notifications using btree (app_type_id)
;


--
-- Name: index_message_notifications_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_message_notifications_on_master_id on ml_app.message_notifications using btree (master_id)
;


--
-- Name: index_message_notifications_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_message_notifications_on_user_id on ml_app.message_notifications using btree (user_id)
;


--
-- Name: index_message_notifications_status; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_message_notifications_status on ml_app.message_notifications using btree (status)
;


--
-- Name: index_message_template_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_message_template_history_on_admin_id on ml_app.message_template_history using btree (admin_id)
;


--
-- Name: index_message_template_history_on_message_template_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_message_template_history_on_message_template_id on ml_app.message_template_history using btree (message_template_id)
;


--
-- Name: index_message_templates_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_message_templates_on_admin_id on ml_app.message_templates using btree (admin_id)
;


--
-- Name: index_model_references_on_from_record_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_model_references_on_from_record_master_id on ml_app.model_references using btree (from_record_master_id)
;


--
-- Name: index_model_references_on_from_record_type_and_from_record_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_model_references_on_from_record_type_and_from_record_id on ml_app.model_references using btree (from_record_type, from_record_id)
;


--
-- Name: index_model_references_on_to_record_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_model_references_on_to_record_master_id on ml_app.model_references using btree (to_record_master_id)
;


--
-- Name: index_model_references_on_to_record_type_and_to_record_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_model_references_on_to_record_type_and_to_record_id on ml_app.model_references using btree (to_record_type, to_record_id)
;


--
-- Name: index_model_references_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_model_references_on_user_id on ml_app.model_references using btree (user_id)
;


--
-- Name: index_nfs_store_archived_file_history_on_nfs_store_archived_fil; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_archived_file_history_on_nfs_store_archived_fil on ml_app.nfs_store_archived_file_history using btree (nfs_store_archived_file_id)
;


--
-- Name: index_nfs_store_archived_file_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_archived_file_history_on_user_id on ml_app.nfs_store_archived_file_history using btree (user_id)
;


--
-- Name: index_nfs_store_archived_files_on_nfs_store_container_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_archived_files_on_nfs_store_container_id on ml_app.nfs_store_archived_files using btree (nfs_store_container_id)
;


--
-- Name: index_nfs_store_archived_files_on_nfs_store_stored_file_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_archived_files_on_nfs_store_stored_file_id on ml_app.nfs_store_archived_files using btree (nfs_store_stored_file_id)
;


--
-- Name: index_nfs_store_container_history_on_created_by_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_container_history_on_created_by_user_id on ml_app.nfs_store_container_history using btree (created_by_user_id)
;


--
-- Name: index_nfs_store_container_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_container_history_on_master_id on ml_app.nfs_store_container_history using btree (master_id)
;


--
-- Name: index_nfs_store_container_history_on_nfs_store_container_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_container_history_on_nfs_store_container_id on ml_app.nfs_store_container_history using btree (nfs_store_container_id)
;


--
-- Name: index_nfs_store_container_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_container_history_on_user_id on ml_app.nfs_store_container_history using btree (user_id)
;


--
-- Name: index_nfs_store_containers_on_created_by_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_containers_on_created_by_user_id on ml_app.nfs_store_containers using btree (created_by_user_id)
;


--
-- Name: index_nfs_store_containers_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_containers_on_master_id on ml_app.nfs_store_containers using btree (master_id)
;


--
-- Name: index_nfs_store_containers_on_nfs_store_container_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_containers_on_nfs_store_container_id on ml_app.nfs_store_containers using btree (nfs_store_container_id)
;


--
-- Name: index_nfs_store_filters_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_filters_on_admin_id on ml_app.nfs_store_filters using btree (admin_id)
;


--
-- Name: index_nfs_store_filters_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_filters_on_app_type_id on ml_app.nfs_store_filters using btree (app_type_id)
;


--
-- Name: index_nfs_store_filters_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_filters_on_user_id on ml_app.nfs_store_filters using btree (user_id)
;


--
-- Name: index_nfs_store_stored_file_history_on_nfs_store_stored_file_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_stored_file_history_on_nfs_store_stored_file_id on ml_app.nfs_store_stored_file_history using btree (nfs_store_stored_file_id)
;


--
-- Name: index_nfs_store_stored_file_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_stored_file_history_on_user_id on ml_app.nfs_store_stored_file_history using btree (user_id)
;


--
-- Name: index_nfs_store_stored_files_on_nfs_store_container_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_stored_files_on_nfs_store_container_id on ml_app.nfs_store_stored_files using btree (nfs_store_container_id)
;


--
-- Name: index_nfs_store_uploads_on_nfs_store_stored_file_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_uploads_on_nfs_store_stored_file_id on ml_app.nfs_store_uploads using btree (nfs_store_stored_file_id)
;


--
-- Name: index_nfs_store_uploads_on_upload_set; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_nfs_store_uploads_on_upload_set on ml_app.nfs_store_uploads using btree (upload_set)
;


--
-- Name: index_page_layout_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_page_layout_history_on_admin_id on ml_app.page_layout_history using btree (admin_id)
;


--
-- Name: index_page_layout_history_on_page_layout_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_page_layout_history_on_page_layout_id on ml_app.page_layout_history using btree (page_layout_id)
;


--
-- Name: index_page_layouts_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_page_layouts_on_admin_id on ml_app.page_layouts using btree (admin_id)
;


--
-- Name: index_page_layouts_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_page_layouts_on_app_type_id on ml_app.page_layouts using btree (app_type_id)
;


--
-- Name: index_player_contact_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_player_contact_history_on_master_id on ml_app.player_contact_history using btree (master_id)
;


--
-- Name: index_player_contact_history_on_player_contact_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_player_contact_history_on_player_contact_id on ml_app.player_contact_history using btree (player_contact_id)
;


--
-- Name: index_player_contact_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_player_contact_history_on_user_id on ml_app.player_contact_history using btree (user_id)
;


--
-- Name: index_player_contacts_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_player_contacts_on_master_id on ml_app.player_contacts using btree (master_id)
;


--
-- Name: index_player_contacts_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_player_contacts_on_user_id on ml_app.player_contacts using btree (user_id)
;


--
-- Name: index_player_info_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_player_info_history_on_master_id on ml_app.player_info_history using btree (master_id)
;


--
-- Name: index_player_info_history_on_player_info_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_player_info_history_on_player_info_id on ml_app.player_info_history using btree (player_info_id)
;


--
-- Name: index_player_info_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_player_info_history_on_user_id on ml_app.player_info_history using btree (user_id)
;


--
-- Name: index_player_infos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_player_infos_on_master_id on ml_app.player_infos using btree (master_id)
;


--
-- Name: index_player_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_player_infos_on_user_id on ml_app.player_infos using btree (user_id)
;


--
-- Name: index_pro_infos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_pro_infos_on_master_id on ml_app.pro_infos using btree (master_id)
;


--
-- Name: index_pro_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_pro_infos_on_user_id on ml_app.pro_infos using btree (user_id)
;


--
-- Name: index_protocol_event_history_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_protocol_event_history_on_protocol_event_id on ml_app.protocol_event_history using btree (protocol_event_id)
;


--
-- Name: index_protocol_events_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_protocol_events_on_admin_id on ml_app.protocol_events using btree (admin_id)
;


--
-- Name: index_protocol_events_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_protocol_events_on_sub_process_id on ml_app.protocol_events using btree (sub_process_id)
;


--
-- Name: index_protocol_history_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_protocol_history_on_protocol_id on ml_app.protocol_history using btree (protocol_id)
;


--
-- Name: index_protocols_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_protocols_on_admin_id on ml_app.protocols using btree (admin_id)
;


--
-- Name: index_protocols_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_protocols_on_app_type_id on ml_app.protocols using btree (app_type_id)
;


--
-- Name: index_report_history_on_report_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_report_history_on_report_id on ml_app.report_history using btree (report_id)
;


--
-- Name: index_reports_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_reports_on_admin_id on ml_app.reports using btree (admin_id)
;


--
-- Name: index_role_description_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_role_description_history_on_admin_id on ml_app.role_description_history using btree (admin_id)
;


--
-- Name: index_role_description_history_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_role_description_history_on_app_type_id on ml_app.role_description_history using btree (app_type_id)
;


--
-- Name: index_role_descriptions_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_role_descriptions_on_admin_id on ml_app.role_descriptions using btree (admin_id)
;


--
-- Name: index_role_descriptions_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_role_descriptions_on_app_type_id on ml_app.role_descriptions using btree (app_type_id)
;


--
-- Name: index_sage_assignments_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_sage_assignments_on_admin_id on ml_app.sage_assignments using btree (admin_id)
;


--
-- Name: index_sage_assignments_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_sage_assignments_on_master_id on ml_app.sage_assignments using btree (master_id)
;


--
-- Name: index_sage_assignments_on_sage_id; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index index_sage_assignments_on_sage_id on ml_app.sage_assignments using btree (sage_id)
;


--
-- Name: index_sage_assignments_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_sage_assignments_on_user_id on ml_app.sage_assignments using btree (user_id)
;


--
-- Name: index_scantron_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_scantron_history_on_master_id on ml_app.scantron_history using btree (master_id)
;


--
-- Name: index_scantron_history_on_scantron_table_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_scantron_history_on_scantron_table_id on ml_app.scantron_history using btree (scantron_table_id)
;


--
-- Name: index_scantron_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_scantron_history_on_user_id on ml_app.scantron_history using btree (user_id)
;


--
-- Name: index_scantron_series_two_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_scantron_series_two_history_on_master_id on ml_app.scantron_series_two_history using btree (master_id)
;


--
-- Name: index_scantron_series_two_history_on_scantron_series_two_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_scantron_series_two_history_on_scantron_series_two_id on ml_app.scantron_series_two_history using btree (scantron_series_two_id)
;


--
-- Name: index_scantron_series_two_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_scantron_series_two_history_on_user_id on ml_app.scantron_series_two_history using btree (user_id)
;


--
-- Name: index_scantron_series_twos_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_scantron_series_twos_on_master_id on ml_app.scantron_series_twos using btree (master_id)
;


--
-- Name: index_scantron_series_twos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_scantron_series_twos_on_user_id on ml_app.scantron_series_twos using btree (user_id)
;


--
-- Name: index_scantrons_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_scantrons_on_master_id on ml_app.scantrons using btree (master_id)
;


--
-- Name: index_scantrons_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_scantrons_on_user_id on ml_app.scantrons using btree (user_id)
;


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index index_sessions_on_session_id on ml_app.sessions using btree (session_id)
;


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_sessions_on_updated_at on ml_app.sessions using btree (updated_at)
;


--
-- Name: index_sub_process_history_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_sub_process_history_on_sub_process_id on ml_app.sub_process_history using btree (sub_process_id)
;


--
-- Name: index_sub_processes_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_sub_processes_on_admin_id on ml_app.sub_processes using btree (admin_id)
;


--
-- Name: index_sub_processes_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_sub_processes_on_protocol_id on ml_app.sub_processes using btree (protocol_id)
;


--
-- Name: index_tracker_history_on_item_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_tracker_history_on_item_type_id on ml_app.tracker_history using btree (item_type, item_id)
;


--
-- Name: index_tracker_history_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_tracker_history_on_master_id on ml_app.tracker_history using btree (master_id)
;


--
-- Name: index_tracker_history_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_tracker_history_on_protocol_event_id on ml_app.tracker_history using btree (protocol_event_id)
;


--
-- Name: index_tracker_history_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_tracker_history_on_protocol_id on ml_app.tracker_history using btree (protocol_id)
;


--
-- Name: index_tracker_history_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_tracker_history_on_sub_process_id on ml_app.tracker_history using btree (sub_process_id)
;


--
-- Name: index_tracker_history_on_tracker_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_tracker_history_on_tracker_id on ml_app.tracker_history using btree (tracker_id)
;


--
-- Name: index_tracker_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_tracker_history_on_user_id on ml_app.tracker_history using btree (user_id)
;


--
-- Name: index_trackers_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_trackers_on_master_id on ml_app.trackers using btree (master_id)
;


--
-- Name: index_trackers_on_protocol_event_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_trackers_on_protocol_event_id on ml_app.trackers using btree (protocol_event_id)
;


--
-- Name: index_trackers_on_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_trackers_on_protocol_id on ml_app.trackers using btree (protocol_id)
;


--
-- Name: index_trackers_on_sub_process_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_trackers_on_sub_process_id on ml_app.trackers using btree (sub_process_id)
;


--
-- Name: index_trackers_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_trackers_on_user_id on ml_app.trackers using btree (user_id)
;


--
-- Name: index_user_access_controls_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_access_controls_on_app_type_id on ml_app.user_access_controls using btree (app_type_id)
;


--
-- Name: index_user_action_logs_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_action_logs_on_app_type_id on ml_app.user_action_logs using btree (app_type_id)
;


--
-- Name: index_user_action_logs_on_master_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_action_logs_on_master_id on ml_app.user_action_logs using btree (master_id)
;


--
-- Name: index_user_action_logs_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_action_logs_on_user_id on ml_app.user_action_logs using btree (user_id)
;


--
-- Name: index_user_authorization_history_on_user_authorization_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_authorization_history_on_user_authorization_id on ml_app.user_authorization_history using btree (user_authorization_id)
;


--
-- Name: index_user_history_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_history_on_app_type_id on ml_app.user_history using btree (app_type_id)
;


--
-- Name: index_user_history_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_history_on_user_id on ml_app.user_history using btree (user_id)
;


--
-- Name: index_user_preferences_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index index_user_preferences_on_user_id on ml_app.user_preferences using btree (user_id)
;


--
-- Name: index_user_role_history_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_role_history_on_admin_id on ml_app.user_role_history using btree (admin_id)
;


--
-- Name: index_user_role_history_on_user_role_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_role_history_on_user_role_id on ml_app.user_role_history using btree (user_role_id)
;


--
-- Name: index_user_roles_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_roles_on_admin_id on ml_app.user_roles using btree (admin_id)
;


--
-- Name: index_user_roles_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_roles_on_app_type_id on ml_app.user_roles using btree (app_type_id)
;


--
-- Name: index_user_roles_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_user_roles_on_user_id on ml_app.user_roles using btree (user_id)
;


--
-- Name: index_users_contact_infos_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_users_contact_infos_on_admin_id on ml_app.users_contact_infos using btree (admin_id)
;


--
-- Name: index_users_contact_infos_on_user_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_users_contact_infos_on_user_id on ml_app.users_contact_infos using btree (user_id)
;


--
-- Name: index_users_on_admin_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_users_on_admin_id on ml_app.users using btree (admin_id)
;


--
-- Name: index_users_on_app_type_id; Type: INDEX; Schema: ml_app; Owner: -
--
create index index_users_on_app_type_id on ml_app.users using btree (app_type_id)
;


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index index_users_on_authentication_token on ml_app.users using btree (authentication_token)
;


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index index_users_on_confirmation_token on ml_app.users using btree (confirmation_token)
;


--
-- Name: index_users_on_email; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index index_users_on_email on ml_app.users using btree (email)
;


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index index_users_on_reset_password_token on ml_app.users using btree (reset_password_token)
;


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index index_users_on_unlock_token on ml_app.users using btree (unlock_token)
;


--
-- Name: nfs_store_stored_files_unique_file; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index nfs_store_stored_files_unique_file on ml_app.nfs_store_stored_files using btree (nfs_store_container_id, file_hash, file_name, path)
;


--
-- Name: unique_master_protocol; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index unique_master_protocol on ml_app.trackers using btree (master_id, protocol_id)
;


--
-- Name: unique_master_protocol_id; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index unique_master_protocol_id on ml_app.trackers using btree (master_id, protocol_id, id)
;


--
-- Name: unique_protocol_and_id; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index unique_protocol_and_id on ml_app.sub_processes using btree (protocol_id, id)
;


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index unique_schema_migrations on ml_app.schema_migrations using btree (version)
;


--
-- Name: unique_sub_process_and_id; Type: INDEX; Schema: ml_app; Owner: -
--
create unique index unique_sub_process_and_id on ml_app.protocol_events using btree (sub_process_id, id)
;


--
-- Name: 09671129_id_idx; Type: INDEX; Schema: ref_data; Owner: -
--
create index "09671129_id_idx" on ref_data.data_variable_package_history using btree (data_variable_package_id)
;


--
-- Name: 09671129_user_idx; Type: INDEX; Schema: ref_data; Owner: -
--
create index "09671129_user_idx" on ref_data.data_variable_package_history using btree (user_id)
;


--
-- Name: 23bde473_id_idx; Type: INDEX; Schema: ref_data; Owner: -
--
create index "23bde473_id_idx" on ref_data.data_variable_package_var_history using btree (data_variable_package_var_id)
;


--
-- Name: 23bde473_user_idx; Type: INDEX; Schema: ref_data; Owner: -
--
create index "23bde473_user_idx" on ref_data.data_variable_package_var_history using btree (user_id)
;


--
-- Name: 9b09ee89_id_idx; Type: INDEX; Schema: ref_data; Owner: -
--
create index "9b09ee89_id_idx" on ref_data.ipa_datadic_history using btree (ipa_datadic_id)
;


--
-- Name: 9b09ee89_user_idx; Type: INDEX; Schema: ref_data; Owner: -
--
create index "9b09ee89_user_idx" on ref_data.ipa_datadic_history using btree (user_id)
;


--
-- Name: bb694a89_id_idx; Type: INDEX; Schema: ref_data; Owner: -
--
create index bb694a89_id_idx on ref_data.q1_datadic_history using btree (q1_datadic_id)
;


--
-- Name: bb694a89_user_idx; Type: INDEX; Schema: ref_data; Owner: -
--
create index bb694a89_user_idx on ref_data.q1_datadic_history using btree (user_id)
;


--
-- Name: f8d33562_id_idx; Type: INDEX; Schema: ref_data; Owner: -
--
create index f8d33562_id_idx on ref_data.domain_mapping_history using btree (domain_mapping_id)
;


--
-- Name: f8d33562_user_idx; Type: INDEX; Schema: ref_data; Owner: -
--
create index f8d33562_user_idx on ref_data.domain_mapping_history using btree (user_id)
;


--
-- Name: idx_dch_on_redcap_dd_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_dch_on_redcap_dd_id on ref_data.datadic_choice_history using btree (redcap_data_dictionary_id)
;


--
-- Name: idx_dv_equiv; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_dv_equiv on ref_data.datadic_variables using btree (equivalent_to_id)
;


--
-- Name: idx_dvh_equiv; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_dvh_equiv on ref_data.datadic_variable_history using btree (equivalent_to_id)
;


--
-- Name: idx_dvh_on_redcap_dd_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_dvh_on_redcap_dd_id on ref_data.datadic_variable_history using btree (redcap_data_dictionary_id)
;


--
-- Name: idx_h_on_datadic_variable_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_h_on_datadic_variable_id on ref_data.datadic_variable_history using btree (datadic_variable_id)
;


--
-- Name: idx_h_on_proj_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_h_on_proj_admin_id on ref_data.redcap_project_user_history using btree (redcap_project_admin_id)
;


--
-- Name: idx_h_on_rdci_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_h_on_rdci_id on ref_data.redcap_data_collection_instrument_history using btree (redcap_data_collection_instrument_id)
;


--
-- Name: idx_h_on_redcap_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_h_on_redcap_admin_id on ref_data.redcap_data_dictionary_history using btree (redcap_project_admin_id)
;


--
-- Name: idx_h_on_redcap_project_user_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_h_on_redcap_project_user_id on ref_data.redcap_project_user_history using btree (redcap_project_user_id)
;


--
-- Name: idx_history_on_datadic_choice_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_history_on_datadic_choice_id on ref_data.datadic_choice_history using btree (datadic_choice_id)
;


--
-- Name: idx_history_on_redcap_data_dictionary_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_history_on_redcap_data_dictionary_id on ref_data.redcap_data_dictionary_history using btree (redcap_data_dictionary_id)
;


--
-- Name: idx_history_on_redcap_project_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_history_on_redcap_project_admin_id on ref_data.redcap_project_admin_history using btree (redcap_project_admin_id)
;


--
-- Name: idx_on_redcap_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_on_redcap_admin_id on ref_data.redcap_data_dictionaries using btree (redcap_project_admin_id)
;


--
-- Name: idx_rcr_on_redcap_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_rcr_on_redcap_admin_id on ref_data.redcap_client_requests using btree (redcap_project_admin_id)
;


--
-- Name: idx_rdci_pa; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_rdci_pa on ref_data.redcap_data_collection_instruments using btree (redcap_project_admin_id)
;


--
-- Name: idx_rdcih_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_rdcih_on_admin_id on ref_data.redcap_data_collection_instrument_history using btree (admin_id)
;


--
-- Name: idx_rdcih_on_proj_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index idx_rdcih_on_proj_admin_id on ref_data.redcap_data_collection_instrument_history using btree (redcap_project_admin_id)
;


--
-- Name: index_datadic_variables_on_user_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index index_datadic_variables_on_user_id on ref_data.datadic_variables using btree (user_id)
;


--
-- Name: index_ref_data.data_variable_package_vars_on_user_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.data_variable_package_vars_on_user_id" on ref_data.data_variable_package_vars using btree (user_id)
;


--
-- Name: index_ref_data.data_variable_packages_on_user_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.data_variable_packages_on_user_id" on ref_data.data_variable_packages using btree (user_id)
;


--
-- Name: index_ref_data.datadic_choice_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.datadic_choice_history_on_admin_id" on ref_data.datadic_choice_history using btree (admin_id)
;


--
-- Name: index_ref_data.datadic_choices_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.datadic_choices_on_admin_id" on ref_data.datadic_choices using btree (admin_id)
;


--
-- Name: index_ref_data.datadic_choices_on_redcap_data_dictionary_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.datadic_choices_on_redcap_data_dictionary_id" on ref_data.datadic_choices using btree (redcap_data_dictionary_id)
;


--
-- Name: index_ref_data.datadic_variable_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.datadic_variable_history_on_admin_id" on ref_data.datadic_variable_history using btree (admin_id)
;


--
-- Name: index_ref_data.datadic_variables_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.datadic_variables_on_admin_id" on ref_data.datadic_variables using btree (admin_id)
;


--
-- Name: index_ref_data.datadic_variables_on_redcap_data_dictionary_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.datadic_variables_on_redcap_data_dictionary_id" on ref_data.datadic_variables using btree (redcap_data_dictionary_id)
;


--
-- Name: index_ref_data.domain_mappings_on_user_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.domain_mappings_on_user_id" on ref_data.domain_mappings using btree (user_id)
;


--
-- Name: index_ref_data.ipa_datadic_on_user_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.ipa_datadic_on_user_id" on ref_data.ipa_datadic using btree (user_id)
;


--
-- Name: index_ref_data.q1_datadic_on_user_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.q1_datadic_on_user_id" on ref_data.q1_datadic using btree (user_id)
;


--
-- Name: index_ref_data.redcap_client_requests_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.redcap_client_requests_on_admin_id" on ref_data.redcap_client_requests using btree (admin_id)
;


--
-- Name: index_ref_data.redcap_data_collection_instruments_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.redcap_data_collection_instruments_on_admin_id" on ref_data.redcap_data_collection_instruments using btree (admin_id)
;


--
-- Name: index_ref_data.redcap_data_dictionaries_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.redcap_data_dictionaries_on_admin_id" on ref_data.redcap_data_dictionaries using btree (admin_id)
;


--
-- Name: index_ref_data.redcap_data_dictionary_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.redcap_data_dictionary_history_on_admin_id" on ref_data.redcap_data_dictionary_history using btree (admin_id)
;


--
-- Name: index_ref_data.redcap_project_admin_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.redcap_project_admin_history_on_admin_id" on ref_data.redcap_project_admin_history using btree (admin_id)
;


--
-- Name: index_ref_data.redcap_project_admins_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.redcap_project_admins_on_admin_id" on ref_data.redcap_project_admins using btree (admin_id)
;


--
-- Name: index_ref_data.redcap_project_user_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.redcap_project_user_history_on_admin_id" on ref_data.redcap_project_user_history using btree (admin_id)
;


--
-- Name: index_ref_data.redcap_project_users_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.redcap_project_users_on_admin_id" on ref_data.redcap_project_users using btree (admin_id)
;


--
-- Name: index_ref_data.redcap_project_users_on_redcap_project_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--
create index "index_ref_data.redcap_project_users_on_redcap_project_admin_id" on ref_data.redcap_project_users using btree (redcap_project_admin_id)
;


--
-- Name: accuracy_scores accuracy_score_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger accuracy_score_history_insert
after insert on ml_app.accuracy_scores for each row
execute function ml_app.log_accuracy_score_update ()
;


--
-- Name: accuracy_scores accuracy_score_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger accuracy_score_history_update
after
update on ml_app.accuracy_scores for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_accuracy_score_update ()
;


--
-- Name: activity_logs activity_log_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger activity_log_history_insert
after insert on ml_app.activity_logs for each row
execute function ml_app.log_activity_log_update ()
;


--
-- Name: activity_logs activity_log_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger activity_log_history_update
after
update on ml_app.activity_logs for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_activity_log_update ()
;


--
-- Name: activity_log_player_contact_phones activity_log_player_contact_phone_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger activity_log_player_contact_phone_history_insert
after insert on ml_app.activity_log_player_contact_phones for each row
execute function ml_app.log_activity_log_player_contact_phone_update ()
;


--
-- Name: activity_log_player_contact_phones activity_log_player_contact_phone_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger activity_log_new_test_history_update
after
update on ml_app.activity_log_new_tests for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_activity_log_new_test_update ()
;


--
-- Name: activity_log_player_contact_phones activity_log_player_contact_phone_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger activity_log_player_contact_phone_history_insert
after insert on ml_app.activity_log_player_contact_phones for each row
execute function ml_app.log_activity_log_player_contact_phone_update ()
;


--
-- Name: activity_log_player_contact_phones activity_log_player_contact_phone_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger activity_log_player_contact_phone_history_update
after
update on ml_app.activity_log_player_contact_phones for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_activity_log_player_contact_phone_update ()
;


--
-- Name: activity_log_player_infos activity_log_player_info_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger activity_log_player_info_history_insert
after insert on ml_app.activity_log_player_infos for each row
execute function ml_app.log_activity_log_player_info_update ()
;


--
-- Name: activity_log_player_infos activity_log_player_info_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger activity_log_player_info_history_update
after
update on ml_app.activity_log_player_infos for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_activity_log_player_info_update ()
;


--
-- Name: addresses address_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger address_history_insert
after insert on ml_app.addresses for each row
execute function ml_app.log_address_update ()
;


--
-- Name: addresses address_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger address_history_update
after
update on ml_app.addresses for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_address_update ()
;


--
-- Name: addresses address_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger address_insert before insert on ml_app.addresses for each row
execute function ml_app.handle_address_update ()
;


--
-- Name: addresses address_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger address_update before
update on ml_app.addresses for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.handle_address_update ()
;


--
-- Name: admins admin_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger admin_history_insert
after insert on ml_app.admins for each row
execute function ml_app.log_admin_update ()
;


--
-- Name: admins admin_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger admin_history_update
after
update on ml_app.admins for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_admin_update ()
;


--
-- Name: bhs_assignments bhs_assignment_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger bhs_assignment_history_insert
after insert on ml_app.bhs_assignments for each row
execute function ml_app.log_bhs_assignment_update ()
;


--
-- Name: bhs_assignments bhs_assignment_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger bhs_assignment_history_update
after
update on ml_app.bhs_assignments for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_bhs_assignment_update ()
;


--
-- Name: colleges college_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger college_history_insert
after insert on ml_app.colleges for each row
execute function ml_app.log_college_update ()
;


--
-- Name: colleges college_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger college_history_update
after
update on ml_app.colleges for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_college_update ()
;


--
-- Name: config_libraries config_library_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger config_library_history_insert
after insert on ml_app.config_libraries for each row
execute function ml_app.log_config_library_update ()
;


--
-- Name: config_libraries config_library_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger config_library_history_update
after
update on ml_app.config_libraries for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_config_library_update ()
;


--
-- Name: dynamic_models dynamic_model_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger dynamic_model_history_insert
after insert on ml_app.dynamic_models for each row
execute function ml_app.log_dynamic_model_update ()
;


--
-- Name: dynamic_models dynamic_model_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger dynamic_model_history_update
after
update on ml_app.dynamic_models for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_dynamic_model_update ()
;


--
-- Name: external_identifiers external_identifier_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger external_identifier_history_insert
after insert on ml_app.external_identifiers for each row
execute function ml_app.log_external_identifier_update ()
;


--
-- Name: external_identifiers external_identifier_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger external_identifier_history_update
after
update on ml_app.external_identifiers for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_external_identifier_update ()
;


--
-- Name: external_links external_link_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger external_link_history_insert
after insert on ml_app.external_links for each row
execute function ml_app.log_external_link_update ()
;


--
-- Name: external_links external_link_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger external_link_history_update
after
update on ml_app.external_links for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_external_link_update ()
;


--
-- Name: general_selections general_selection_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger general_selection_history_insert
after insert on ml_app.general_selections for each row
execute function ml_app.log_general_selection_update ()
;


--
-- Name: general_selections general_selection_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger general_selection_history_update
after
update on ml_app.general_selections for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_general_selection_update ()
;


--
-- Name: item_flags item_flag_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger item_flag_history_insert
after insert on ml_app.item_flags for each row
execute function ml_app.log_item_flag_update ()
;


--
-- Name: item_flags item_flag_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger item_flag_history_update
after
update on ml_app.item_flags for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_item_flag_update ()
;


--
-- Name: item_flag_names item_flag_name_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger item_flag_name_history_insert
after insert on ml_app.item_flag_names for each row
execute function ml_app.log_item_flag_name_update ()
;


--
-- Name: item_flag_names item_flag_name_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger item_flag_name_history_update
after
update on ml_app.item_flag_names for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_item_flag_name_update ()
;


--
-- Name: role_descriptions log_role_description_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger log_role_description_history_insert
after insert on ml_app.role_descriptions for each row
execute function ml_app.role_description_history_upd ()
;


--
-- Name: role_descriptions log_role_description_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger log_role_description_history_update
after
update on ml_app.role_descriptions for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.role_description_history_upd ()
;


--
-- Name: new_tests new_test_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger new_test_history_insert
after insert on ml_app.new_tests for each row
execute function ml_app.log_new_test_update ()
;


--
-- Name: new_tests new_test_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger new_test_history_update
after
update on ml_app.new_tests for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_new_test_update ()
;


--
-- Name: player_contacts player_contact_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger player_contact_history_insert
after insert on ml_app.player_contacts for each row
execute function ml_app.log_player_contact_update ()
;


--
-- Name: player_contacts player_contact_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger player_contact_history_update
after
update on ml_app.player_contacts for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_player_contact_update ()
;


--
-- Name: player_contacts player_contact_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger player_contact_insert before insert on ml_app.player_contacts for each row
execute function ml_app.handle_player_contact_update ()
;


--
-- Name: player_contacts player_contact_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger player_contact_update before
update on ml_app.player_contacts for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.handle_player_contact_update ()
;


--
-- Name: player_infos player_info_before_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger player_info_before_update before
update on ml_app.player_infos for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.handle_player_info_before_update ()
;


--
-- Name: player_infos player_info_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger player_info_history_insert
after insert on ml_app.player_infos for each row
execute function ml_app.log_player_info_update ()
;


--
-- Name: player_infos player_info_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger player_info_history_update
after
update on ml_app.player_infos for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_player_info_update ()
;


--
-- Name: player_infos player_info_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger player_info_insert
after insert on ml_app.player_infos for each row
execute function ml_app.update_master_with_player_info ()
;


--
-- Name: player_infos player_info_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger player_info_update
after
update on ml_app.player_infos for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.update_master_with_player_info ()
;


--
-- Name: pro_infos pro_info_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger pro_info_insert
after insert on ml_app.pro_infos for each row
execute function ml_app.update_master_with_pro_info ()
;


--
-- Name: pro_infos pro_info_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger pro_info_update
after
update on ml_app.pro_infos for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.update_master_with_pro_info ()
;


--
-- Name: protocol_events protocol_event_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger protocol_event_history_insert
after insert on ml_app.protocol_events for each row
execute function ml_app.log_protocol_event_update ()
;


--
-- Name: protocol_events protocol_event_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger protocol_event_history_update
after
update on ml_app.protocol_events for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_protocol_event_update ()
;


--
-- Name: protocols protocol_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger protocol_history_insert
after insert on ml_app.protocols for each row
execute function ml_app.log_protocol_update ()
;


--
-- Name: protocols protocol_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger protocol_history_update
after
update on ml_app.protocols for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_protocol_update ()
;


--
-- Name: rc_stage_cif_copy rc_cis_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger rc_cis_update before
update on ml_app.rc_stage_cif_copy for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.handle_rc_cis_update ()
;


--
-- Name: reports report_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger report_history_insert
after insert on ml_app.reports for each row
execute function ml_app.log_report_update ()
;


--
-- Name: reports report_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger report_history_update
after
update on ml_app.reports for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_report_update ()
;


--
-- Name: scantrons scantron_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger scantron_history_insert
after insert on ml_app.scantrons for each row
execute function ml_app.log_scantron_update ()
;


--
-- Name: scantrons scantron_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger scantron_history_update
after
update on ml_app.scantrons for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_scantron_update ()
;


--
-- Name: sub_processes sub_process_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger sub_process_history_insert
after insert on ml_app.sub_processes for each row
execute function ml_app.log_sub_process_update ()
;


--
-- Name: sub_processes sub_process_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger sub_process_history_update
after
update on ml_app.sub_processes for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_sub_process_update ()
;


--
-- Name: trackers tracker_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger tracker_history_insert
after insert on ml_app.trackers for each row
execute function ml_app.log_tracker_update ()
;


--
-- Name: tracker_history tracker_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger tracker_history_update before
update on ml_app.tracker_history for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.handle_tracker_history_update ()
;


--
-- Name: trackers tracker_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger tracker_history_update
after
update on ml_app.trackers for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_tracker_update ()
;


--
-- Name: tracker_history tracker_record_delete; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger tracker_record_delete
after delete on ml_app.tracker_history for each row
execute function ml_app.handle_delete ()
;


--
-- Name: trackers tracker_upsert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger tracker_upsert before insert on ml_app.trackers for each row
execute function ml_app.tracker_upsert ()
;


--
-- Name: user_authorizations user_authorization_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger user_authorization_history_insert
after insert on ml_app.user_authorizations for each row
execute function ml_app.log_user_authorization_update ()
;


--
-- Name: user_authorizations user_authorization_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger user_authorization_history_update
after
update on ml_app.user_authorizations for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_user_authorization_update ()
;


--
-- Name: users user_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger user_history_insert
after insert on ml_app.users for each row
execute function ml_app.log_user_update ()
;


--
-- Name: users user_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger user_history_update
after
update on ml_app.users for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_user_update ()
;


--
-- Name: user_roles user_role_history_insert; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger user_role_history_insert
after insert on ml_app.user_roles for each row
execute function ml_app.log_user_role_update ()
;


--
-- Name: user_roles user_role_history_update; Type: TRIGGER; Schema: ml_app; Owner: -
--
create trigger user_role_history_update
after
update on ml_app.user_roles for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.log_user_role_update ()
;


--
-- Name: datadic_choices log_datadic_choice_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_datadic_choice_history_insert
after insert on ref_data.datadic_choices for each row
execute function ml_app.datadic_choice_history_upd ()
;


--
-- Name: datadic_choices log_datadic_choice_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_datadic_choice_history_update
after
update on ref_data.datadic_choices for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.datadic_choice_history_upd ()
;


--
-- Name: datadic_variables log_datadic_variable_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_datadic_variable_history_insert
after insert on ref_data.datadic_variables for each row
execute function ref_data.log_datadic_variables_update ()
;


--
-- Name: datadic_variables log_datadic_variable_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_datadic_variable_history_update
after
update on ref_data.datadic_variables for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ref_data.log_datadic_variables_update ()
;


--
-- Name: domain_mappings log_domain_mapping_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_domain_mapping_history_insert
after insert on ref_data.domain_mappings for each row
execute function ref_data.log_domain_mappings_update ()
;


--
-- Name: domain_mappings log_domain_mapping_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_domain_mapping_history_update
after
update on ref_data.domain_mappings for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ref_data.log_domain_mappings_update ()
;


--
-- Name: ipa_datadic log_ipa_datadic_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_ipa_datadic_history_insert
after insert on ref_data.ipa_datadic for each row
execute function ref_data.log_ipa_datadic_update ()
;


--
-- Name: ipa_datadic log_ipa_datadic_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_ipa_datadic_history_update
after
update on ref_data.ipa_datadic for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ref_data.log_ipa_datadic_update ()
;


--
-- Name: q1_datadic log_q1_datadic_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_q1_datadic_history_insert
after insert on ref_data.q1_datadic for each row
execute function ref_data.log_q1_datadic_update ()
;


--
-- Name: q1_datadic log_q1_datadic_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_q1_datadic_history_update
after
update on ref_data.q1_datadic for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ref_data.log_q1_datadic_update ()
;


--
-- Name: redcap_data_collection_instruments log_redcap_data_collection_instrument_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_redcap_data_collection_instrument_history_insert
after insert on ref_data.redcap_data_collection_instruments for each row
execute function ref_data.redcap_data_collection_instrument_history_upd ()
;


--
-- Name: redcap_data_collection_instruments log_redcap_data_collection_instrument_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_redcap_data_collection_instrument_history_update
after
update on ref_data.redcap_data_collection_instruments for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ref_data.redcap_data_collection_instrument_history_upd ()
;


--
-- Name: redcap_data_dictionaries log_redcap_data_dictionary_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_redcap_data_dictionary_history_insert
after insert on ref_data.redcap_data_dictionaries for each row
execute function ml_app.redcap_data_dictionary_history_upd ()
;


--
-- Name: redcap_data_dictionaries log_redcap_data_dictionary_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_redcap_data_dictionary_history_update
after
update on ref_data.redcap_data_dictionaries for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.redcap_data_dictionary_history_upd ()
;


--
-- Name: redcap_project_admins log_redcap_project_admin_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_redcap_project_admin_history_insert
after insert on ref_data.redcap_project_admins for each row
execute function ml_app.redcap_project_admin_history_upd ()
;


--
-- Name: redcap_project_admins log_redcap_project_admin_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_redcap_project_admin_history_update
after
update on ref_data.redcap_project_admins for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ml_app.redcap_project_admin_history_upd ()
;


--
-- Name: redcap_project_users log_redcap_project_user_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_redcap_project_user_history_insert
after insert on ref_data.redcap_project_users for each row
execute function ref_data.redcap_project_user_history_upd ()
;


--
-- Name: redcap_project_users log_redcap_project_user_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--
create trigger log_redcap_project_user_history_update
after
update on ref_data.redcap_project_users for each row when (
  (
    old.* is distinct
    from
      new.*
  )
)
execute function ref_data.redcap_project_user_history_upd ()
;


--
-- Name: accuracy_score_history fk_accuracy_score_history_accuracy_scores; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.accuracy_score_history
add constraint fk_accuracy_score_history_accuracy_scores foreign key (accuracy_score_id) references ml_app.accuracy_scores (id)
;


--
-- Name: activity_log_player_contact_phone_history fk_activity_log_player_contact_phone_history_activity_log_playe; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phone_history
add constraint fk_activity_log_player_contact_phone_history_activity_log_playe foreign key (activity_log_player_contact_phone_id) references ml_app.activity_log_player_contact_phones (id)
;


--
-- Name: activity_log_player_contact_phone_history fk_activity_log_player_contact_phone_history_activity_log_playe; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phone_history
add constraint fk_activity_log_player_contact_phone_history_activity_log_playe foreign key (activity_log_player_contact_phone_id) references ml_app.activity_log_player_contact_phones (id)
;


--
-- Name: activity_log_player_contact_phone_history fk_activity_log_player_contact_phone_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phone_history
add constraint fk_activity_log_player_contact_phone_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: activity_log_player_contact_phone_history fk_activity_log_player_contact_phone_history_player_contact_pho; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phone_history
add constraint fk_activity_log_player_contact_phone_history_player_contact_pho foreign key (player_contact_id) references ml_app.player_contacts (id)
;


--
-- Name: activity_log_player_contact_phone_history fk_activity_log_player_contact_phone_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phone_history
add constraint fk_activity_log_player_contact_phone_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: address_history fk_address_history_addresses; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.address_history
add constraint fk_address_history_addresses foreign key (address_id) references ml_app.addresses (id)
;


--
-- Name: address_history fk_address_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.address_history
add constraint fk_address_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: address_history fk_address_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.address_history
add constraint fk_address_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: admin_history fk_admin_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.admin_history
add constraint fk_admin_history_admins foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: admin_history fk_admin_history_upd_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.admin_history
add constraint fk_admin_history_upd_admins foreign key (updated_by_admin_id) references ml_app.admins (id)
;


--
-- Name: bhs_assignment_history fk_bhs_assignment_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.bhs_assignment_history
add constraint fk_bhs_assignment_history_admins foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: bhs_assignment_history fk_bhs_assignment_history_bhs_assignments; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.bhs_assignment_history
add constraint fk_bhs_assignment_history_bhs_assignments foreign key (bhs_assignment_table_id) references ml_app.bhs_assignments (id)
;


--
-- Name: bhs_assignment_history fk_bhs_assignment_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.bhs_assignment_history
add constraint fk_bhs_assignment_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: bhs_assignment_history fk_bhs_assignment_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.bhs_assignment_history
add constraint fk_bhs_assignment_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: college_history fk_college_history_colleges; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.college_history
add constraint fk_college_history_colleges foreign key (college_id) references ml_app.colleges (id)
;


--
-- Name: dynamic_model_history fk_dynamic_model_history_dynamic_models; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.dynamic_model_history
add constraint fk_dynamic_model_history_dynamic_models foreign key (dynamic_model_id) references ml_app.dynamic_models (id)
;


--
-- Name: external_link_history fk_external_link_history_external_links; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_link_history
add constraint fk_external_link_history_external_links foreign key (external_link_id) references ml_app.external_links (id)
;


--
-- Name: general_selection_history fk_general_selection_history_general_selections; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.general_selection_history
add constraint fk_general_selection_history_general_selections foreign key (general_selection_id) references ml_app.general_selections (id)
;


--
-- Name: item_flag_history fk_item_flag_history_item_flags; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flag_history
add constraint fk_item_flag_history_item_flags foreign key (item_flag_id) references ml_app.item_flags (id)
;


--
-- Name: item_flag_name_history fk_item_flag_name_history_item_flag_names; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flag_name_history
add constraint fk_item_flag_name_history_item_flag_names foreign key (item_flag_name_id) references ml_app.item_flag_names (id)
;


--
-- Name: message_template_history fk_message_template_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_template_history
add constraint fk_message_template_history_admins foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: message_template_history fk_message_template_history_message_templates; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_template_history
add constraint fk_message_template_history_message_templates foreign key (message_template_id) references ml_app.message_templates (id)
;


--
-- Name: nfs_store_archived_file_history fk_nfs_store_archived_file_history_nfs_store_archived_files; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_archived_file_history
add constraint fk_nfs_store_archived_file_history_nfs_store_archived_files foreign key (nfs_store_archived_file_id) references ml_app.nfs_store_archived_files (id)
;


--
-- Name: nfs_store_archived_file_history fk_nfs_store_archived_file_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_archived_file_history
add constraint fk_nfs_store_archived_file_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: nfs_store_container_history fk_nfs_store_container_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_container_history
add constraint fk_nfs_store_container_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: nfs_store_container_history fk_nfs_store_container_history_nfs_store_containers; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_container_history
add constraint fk_nfs_store_container_history_nfs_store_containers foreign key (nfs_store_container_id) references ml_app.nfs_store_containers (id)
;


--
-- Name: nfs_store_container_history fk_nfs_store_container_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_container_history
add constraint fk_nfs_store_container_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: nfs_store_stored_file_history fk_nfs_store_stored_file_history_nfs_store_stored_files; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_stored_file_history
add constraint fk_nfs_store_stored_file_history_nfs_store_stored_files foreign key (nfs_store_stored_file_id) references ml_app.nfs_store_stored_files (id)
;


--
-- Name: nfs_store_stored_file_history fk_nfs_store_stored_file_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_stored_file_history
add constraint fk_nfs_store_stored_file_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: page_layout_history fk_page_layout_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.page_layout_history
add constraint fk_page_layout_history_admins foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: page_layout_history fk_page_layout_history_page_layouts; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.page_layout_history
add constraint fk_page_layout_history_page_layouts foreign key (page_layout_id) references ml_app.page_layouts (id)
;


--
-- Name: player_contact_history fk_player_contact_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_contact_history
add constraint fk_player_contact_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: player_contact_history fk_player_contact_history_player_contacts; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_contact_history
add constraint fk_player_contact_history_player_contacts foreign key (player_contact_id) references ml_app.player_contacts (id)
;


--
-- Name: player_contact_history fk_player_contact_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_contact_history
add constraint fk_player_contact_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: player_info_history fk_player_info_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_info_history
add constraint fk_player_info_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: player_info_history fk_player_info_history_player_infos; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_info_history
add constraint fk_player_info_history_player_infos foreign key (player_info_id) references ml_app.player_infos (id)
;


--
-- Name: player_info_history fk_player_info_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_info_history
add constraint fk_player_info_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: protocol_event_history fk_protocol_event_history_protocol_events; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocol_event_history
add constraint fk_protocol_event_history_protocol_events foreign key (protocol_event_id) references ml_app.protocol_events (id)
;


--
-- Name: protocol_history fk_protocol_history_protocols; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocol_history
add constraint fk_protocol_history_protocols foreign key (protocol_id) references ml_app.protocols (id)
;


--
-- Name: masters fk_rails_00b234154d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.masters
add constraint fk_rails_00b234154d foreign key (user_id) references ml_app.users (id)
;


--
-- Name: app_configurations fk_rails_00f31a00c4; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.app_configurations
add constraint fk_rails_00f31a00c4 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: nfs_store_filters fk_rails_0208c3b54d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_filters
add constraint fk_rails_0208c3b54d foreign key (user_id) references ml_app.users (id)
;


--
-- Name: external_identifier_history fk_rails_0210618434; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_identifier_history
add constraint fk_rails_0210618434 foreign key (external_identifier_id) references ml_app.external_identifiers (id)
;


--
-- Name: player_infos fk_rails_08e7f66647; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_infos
add constraint fk_rails_08e7f66647 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: user_action_logs fk_rails_08eec3f089; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_action_logs
add constraint fk_rails_08eec3f089 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: role_description_history fk_rails_0910ca20ea; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.role_description_history
add constraint fk_rails_0910ca20ea foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: protocol_events fk_rails_0a64e1160a; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocol_events
add constraint fk_rails_0a64e1160a foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: nfs_store_containers fk_rails_0c84487284; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_containers
add constraint fk_rails_0c84487284 foreign key (nfs_store_container_id) references ml_app.nfs_store_containers (id)
;


--
-- Name: nfs_store_stored_files fk_rails_0de144234e; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_stored_files
add constraint fk_rails_0de144234e foreign key (nfs_store_container_id) references ml_app.nfs_store_containers (id)
;


--
-- Name: masters fk_rails_10869244dc; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.masters
add constraint fk_rails_10869244dc foreign key (created_by_user_id) references ml_app.users (id)
;


--
-- Name: users fk_rails_1694bfe639; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.users
add constraint fk_rails_1694bfe639 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: activity_log_history fk_rails_16d57266f7; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_history
add constraint fk_rails_16d57266f7 foreign key (activity_log_id) references ml_app.activity_logs (id)
;


--
-- Name: user_roles fk_rails_174e058eb3; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_roles
add constraint fk_rails_174e058eb3 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: scantrons fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantrons
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: test_exts fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_exts
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: test_ext2s fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_ext2s
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: ext_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.ext_assignments
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: activity_log_ext_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_ext_assignments
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: ext_gen_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.ext_gen_assignments
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: test1s fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test1s
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: test_2s fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_2s
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: test2s fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test2s
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: activity_log_player_infos fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_infos
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: new_tests fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.new_tests
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: activity_log_new_tests fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_new_tests
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: bhs_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.bhs_assignments
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: activity_log_bhs_assignments fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_bhs_assignments
add constraint fk_rails_1a7e2b01e0 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: test1s fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test1s
add constraint fk_rails_1a7e2b01e0admin foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: test_2s fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_2s
add constraint fk_rails_1a7e2b01e0admin foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: test2s fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test2s
add constraint fk_rails_1a7e2b01e0admin foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: new_tests fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.new_tests
add constraint fk_rails_1a7e2b01e0admin foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: bhs_assignments fk_rails_1a7e2b01e0admin; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.bhs_assignments
add constraint fk_rails_1a7e2b01e0admin foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: nfs_store_stored_files fk_rails_1cc4562569; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_stored_files
add constraint fk_rails_1cc4562569 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: activity_log_player_contact_phones fk_rails_1d67a3e7f2; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phones
add constraint fk_rails_1d67a3e7f2 foreign key (protocol_id) references ml_app.protocols (id)
;


--
-- Name: config_library_history fk_rails_1ec40f248c; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.config_library_history
add constraint fk_rails_1ec40f248c foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: sub_processes fk_rails_1fc7475261; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.sub_processes
add constraint fk_rails_1fc7475261 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: pro_infos fk_rails_20667815e3; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.pro_infos
add constraint fk_rails_20667815e3 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: item_flag_names fk_rails_22ccfd95e1; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flag_names
add constraint fk_rails_22ccfd95e1 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: player_infos fk_rails_23cd255bc6; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_infos
add constraint fk_rails_23cd255bc6 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: nfs_store_containers fk_rails_2708bd6a94; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_containers
add constraint fk_rails_2708bd6a94 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: nfs_store_downloads fk_rails_272f69e6af; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_downloads
add constraint fk_rails_272f69e6af foreign key (nfs_store_container_id) references ml_app.nfs_store_containers (id)
;


--
-- Name: role_descriptions fk_rails_291bbea3bc; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.role_descriptions
add constraint fk_rails_291bbea3bc foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: nfs_store_archived_files fk_rails_2b59e23148; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_archived_files
add constraint fk_rails_2b59e23148 foreign key (nfs_store_stored_file_id) references ml_app.nfs_store_stored_files (id)
;


--
-- Name: model_references fk_rails_2d8072edea; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.model_references
add constraint fk_rails_2d8072edea foreign key (to_record_master_id) references ml_app.masters (id)
;


--
-- Name: activity_log_player_contact_phones fk_rails_2de1cadfad; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phones
add constraint fk_rails_2de1cadfad foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: nfs_store_archived_files fk_rails_2eab578259; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_archived_files
add constraint fk_rails_2eab578259 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: user_roles fk_rails_318345354e; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_roles
add constraint fk_rails_318345354e foreign key (user_id) references ml_app.users (id)
;


--
-- Name: admin_action_logs fk_rails_3389f178f6; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.admin_action_logs
add constraint fk_rails_3389f178f6 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: page_layouts fk_rails_37a2f11066; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.page_layouts
add constraint fk_rails_37a2f11066 foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: message_notifications fk_rails_3a3553e146; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_notifications
add constraint fk_rails_3a3553e146 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: nfs_store_uploads fk_rails_3f5167a964; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_uploads
add constraint fk_rails_3f5167a964 foreign key (nfs_store_container_id) references ml_app.nfs_store_containers (id)
;


--
-- Name: trackers fk_rails_447d125f63; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.trackers
add constraint fk_rails_447d125f63 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: scantrons fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantrons
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: test_exts fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_exts
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: test_ext2s fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_ext2s
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: ext_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.ext_assignments
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: activity_log_ext_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_ext_assignments
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: ext_gen_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.ext_gen_assignments
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: test1s fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test1s
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: test_2s fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_2s
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: test2s fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test2s
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: activity_log_player_infos fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_infos
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: new_tests fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.new_tests
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: activity_log_new_tests fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_new_tests
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: bhs_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.bhs_assignments
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: activity_log_bhs_assignments fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_bhs_assignments
add constraint fk_rails_45205ed085 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: role_description_history fk_rails_47581bba71; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.role_description_history
add constraint fk_rails_47581bba71 foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: trackers fk_rails_47b051d356; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.trackers
add constraint fk_rails_47b051d356 foreign key (sub_process_id) references ml_app.sub_processes (id)
;


--
-- Name: addresses fk_rails_48c9e0c5a2; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.addresses
add constraint fk_rails_48c9e0c5a2 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: colleges fk_rails_49306e4f49; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.colleges
add constraint fk_rails_49306e4f49 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: model_references fk_rails_4bbf83b940; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.model_references
add constraint fk_rails_4bbf83b940 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: users_contact_infos fk_rails_4decdf690b; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.users_contact_infos
add constraint fk_rails_4decdf690b foreign key (user_id) references ml_app.users (id)
;


--
-- Name: message_templates fk_rails_4fe5122ed4; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_templates
add constraint fk_rails_4fe5122ed4 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: nfs_store_uploads fk_rails_4ff6d28f98; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_uploads
add constraint fk_rails_4ff6d28f98 foreign key (nfs_store_stored_file_id) references ml_app.nfs_store_stored_files (id)
;


--
-- Name: exception_logs fk_rails_51ae125c4f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.exception_logs
add constraint fk_rails_51ae125c4f foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: protocol_events fk_rails_564af80fb6; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocol_events
add constraint fk_rails_564af80fb6 foreign key (sub_process_id) references ml_app.sub_processes (id)
;


--
-- Name: external_identifier_history fk_rails_5b0628cf42; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_identifier_history
add constraint fk_rails_5b0628cf42 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: activity_log_player_contact_phones fk_rails_5ce1857310; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phones
add constraint fk_rails_5ce1857310 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: trackers fk_rails_623e0ca5ac; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.trackers
add constraint fk_rails_623e0ca5ac foreign key (protocol_id) references ml_app.protocols (id)
;


--
-- Name: nfs_store_user_file_actions fk_rails_639da31037; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_user_file_actions
add constraint fk_rails_639da31037 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: app_configurations fk_rails_647c63b069; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.app_configurations
add constraint fk_rails_647c63b069 foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: nfs_store_containers fk_rails_6a3d7bf39f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_containers
add constraint fk_rails_6a3d7bf39f foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: users fk_rails_6a971dc818; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.users
add constraint fk_rails_6a971dc818 foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: protocols fk_rails_6de4fd560d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocols
add constraint fk_rails_6de4fd560d foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: tracker_history fk_rails_6e050927c2; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.tracker_history
add constraint fk_rails_6e050927c2 foreign key (tracker_id) references ml_app.trackers (id)
;


--
-- Name: accuracy_scores fk_rails_70c17e88fd; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.accuracy_scores
add constraint fk_rails_70c17e88fd foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: external_identifiers fk_rails_7218113eac; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_identifiers
add constraint fk_rails_7218113eac foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: player_contacts fk_rails_72b1afe72f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_contacts
add constraint fk_rails_72b1afe72f foreign key (user_id) references ml_app.users (id)
;


--
-- Name: nfs_store_move_actions fk_rails_75138f1972; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_move_actions
add constraint fk_rails_75138f1972 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: nfs_store_filters fk_rails_776e17eafd; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_filters
add constraint fk_rails_776e17eafd foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: users_contact_infos fk_rails_7808f5fdb3; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.users_contact_infos
add constraint fk_rails_7808f5fdb3 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: activity_log_ext_assignments fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_ext_assignments
add constraint fk_rails_78888ed085 foreign key (ext_assignment_id) references ml_app.ext_assignments (id)
;


--
-- Name: activity_log_player_infos fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_infos
add constraint fk_rails_78888ed085 foreign key (player_info_id) references ml_app.player_infos (id)
;


--
-- Name: activity_log_new_tests fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_new_tests
add constraint fk_rails_78888ed085 foreign key (new_test_id) references ml_app.new_tests (id)
;


--
-- Name: activity_log_bhs_assignments fk_rails_78888ed085; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_bhs_assignments
add constraint fk_rails_78888ed085 foreign key (bhs_assignment_id) references ml_app.bhs_assignments (id)
;


--
-- Name: sub_processes fk_rails_7c10a99849; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.sub_processes
add constraint fk_rails_7c10a99849 foreign key (protocol_id) references ml_app.protocols (id)
;


--
-- Name: user_access_controls fk_rails_8108e25f83; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_access_controls
add constraint fk_rails_8108e25f83 foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: tracker_history fk_rails_83aa075398; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.tracker_history
add constraint fk_rails_83aa075398 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: pro_infos fk_rails_86cecb1e36; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.pro_infos
add constraint fk_rails_86cecb1e36 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: config_library_history fk_rails_88664b466b; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.config_library_history
add constraint fk_rails_88664b466b foreign key (config_library_id) references ml_app.config_libraries (id)
;


--
-- Name: app_types fk_rails_8be93bcf4b; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.app_types
add constraint fk_rails_8be93bcf4b foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: tracker_history fk_rails_9513fd1c35; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.tracker_history
add constraint fk_rails_9513fd1c35 foreign key (sub_process_id) references ml_app.sub_processes (id)
;


--
-- Name: sage_assignments fk_rails_971255ec2c; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.sage_assignments
add constraint fk_rails_971255ec2c foreign key (user_id) references ml_app.users (id)
;


--
-- Name: protocols fk_rails_990daa5f76; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.protocols
add constraint fk_rails_990daa5f76 foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: role_description_history fk_rails_9d88430088; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.role_description_history
add constraint fk_rails_9d88430088 foreign key (role_description_id) references ml_app.role_descriptions (id)
;


--
-- Name: tracker_history fk_rails_9e92bdfe65; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.tracker_history
add constraint fk_rails_9e92bdfe65 foreign key (protocol_event_id) references ml_app.protocol_events (id)
;


--
-- Name: tracker_history fk_rails_9f5797d684; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.tracker_history
add constraint fk_rails_9f5797d684 foreign key (protocol_id) references ml_app.protocols (id)
;


--
-- Name: addresses fk_rails_a44670b00a; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.addresses
add constraint fk_rails_a44670b00a foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: model_references fk_rails_a4eb981c4a; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.model_references
add constraint fk_rails_a4eb981c4a foreign key (from_record_master_id) references ml_app.masters (id)
;


--
-- Name: user_preferences fk_rails_a69bfcfd81; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_preferences
add constraint fk_rails_a69bfcfd81 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: user_history fk_rails_af2f6ffc55; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_history
add constraint fk_rails_af2f6ffc55 foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: activity_log_player_contact_phones fk_rails_b071294797; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.activity_log_player_contact_phones
add constraint fk_rails_b071294797 foreign key (player_contact_id) references ml_app.player_contacts (id)
;


--
-- Name: colleges fk_rails_b0a6220067; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.colleges
add constraint fk_rails_b0a6220067 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: reports fk_rails_b138baacff; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.reports
add constraint fk_rails_b138baacff foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: imports fk_rails_b1e2154c26; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.imports
add constraint fk_rails_b1e2154c26 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: user_roles fk_rails_b345649dfe; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_roles
add constraint fk_rails_b345649dfe foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: trackers fk_rails_b822840dc1; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.trackers
add constraint fk_rails_b822840dc1 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: trackers fk_rails_bb6af37155; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.trackers
add constraint fk_rails_bb6af37155 foreign key (protocol_event_id) references ml_app.protocol_events (id)
;


--
-- Name: imports_model_generators fk_rails_bd9f10d2c7; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.imports_model_generators
add constraint fk_rails_bd9f10d2c7 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: nfs_store_uploads fk_rails_bdb308087e; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_uploads
add constraint fk_rails_bdb308087e foreign key (user_id) references ml_app.users (id)
;


--
-- Name: admins fk_rails_c05d151591; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.admins
add constraint fk_rails_c05d151591 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: nfs_store_move_actions fk_rails_c1ea9a5fd9; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_move_actions
add constraint fk_rails_c1ea9a5fd9 foreign key (nfs_store_container_id) references ml_app.nfs_store_containers (id)
;


--
-- Name: item_flags fk_rails_c2d5bb8930; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flags
add constraint fk_rails_c2d5bb8930 foreign key (item_flag_name_id) references ml_app.item_flag_names (id)
;


--
-- Name: nfs_store_user_file_actions fk_rails_c423dc1802; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_user_file_actions
add constraint fk_rails_c423dc1802 foreign key (nfs_store_container_id) references ml_app.nfs_store_containers (id)
;


--
-- Name: tracker_history fk_rails_c55341c576; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.tracker_history
add constraint fk_rails_c55341c576 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: exception_logs fk_rails_c720bf523c; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.exception_logs
add constraint fk_rails_c720bf523c foreign key (user_id) references ml_app.users (id)
;


--
-- Name: user_action_logs fk_rails_c94bae872a; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_action_logs
add constraint fk_rails_c94bae872a foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: nfs_store_downloads fk_rails_cd756b42dd; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_downloads
add constraint fk_rails_cd756b42dd foreign key (user_id) references ml_app.users (id)
;


--
-- Name: user_action_logs fk_rails_cfc9dc539f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_action_logs
add constraint fk_rails_cfc9dc539f foreign key (user_id) references ml_app.users (id)
;


--
-- Name: message_notifications fk_rails_d3566ee56d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_notifications
add constraint fk_rails_d3566ee56d foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: player_contacts fk_rails_d3c0ddde90; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.player_contacts
add constraint fk_rails_d3c0ddde90 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: nfs_store_container_history fk_rails_d6593e5c9d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_container_history
add constraint fk_rails_d6593e5c9d foreign key (created_by_user_id) references ml_app.users (id)
;


--
-- Name: config_libraries fk_rails_da3ba4f850; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.config_libraries
add constraint fk_rails_da3ba4f850 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: item_flags fk_rails_dce5169cfd; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.item_flags
add constraint fk_rails_dce5169cfd foreign key (user_id) references ml_app.users (id)
;


--
-- Name: dynamic_models fk_rails_deec8fcb38; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.dynamic_models
add constraint fk_rails_deec8fcb38 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: nfs_store_containers fk_rails_e01d928507; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_containers
add constraint fk_rails_e01d928507 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: sage_assignments fk_rails_e3c559b547; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.sage_assignments
add constraint fk_rails_e3c559b547 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: page_layouts fk_rails_e410af4010; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.page_layouts
add constraint fk_rails_e410af4010 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: sage_assignments fk_rails_ebab73db27; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.sage_assignments
add constraint fk_rails_ebab73db27 foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: external_links fk_rails_ebf3863277; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.external_links
add constraint fk_rails_ebf3863277 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: nfs_store_archived_files fk_rails_ecfa3cb151; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_archived_files
add constraint fk_rails_ecfa3cb151 foreign key (nfs_store_container_id) references ml_app.nfs_store_containers (id)
;


--
-- Name: nfs_store_containers fk_rails_ee25fc60fa; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_containers
add constraint fk_rails_ee25fc60fa foreign key (created_by_user_id) references ml_app.users (id)
;


--
-- Name: app_configurations fk_rails_f0ac516fff; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.app_configurations
add constraint fk_rails_f0ac516fff foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: nfs_store_filters fk_rails_f547361daa; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.nfs_store_filters
add constraint fk_rails_f547361daa foreign key (app_type_id) references ml_app.app_types (id)
;


--
-- Name: general_selections fk_rails_f62500107f; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.general_selections
add constraint fk_rails_f62500107f foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: role_descriptions fk_rails_f646dbe30d; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.role_descriptions
add constraint fk_rails_f646dbe30d foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: message_notifications fk_rails_fa6dbd15de; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.message_notifications
add constraint fk_rails_fa6dbd15de foreign key (user_id) references ml_app.users (id)
;


--
-- Name: report_history fk_report_history_reports; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.report_history
add constraint fk_report_history_reports foreign key (report_id) references ml_app.reports (id)
;


--
-- Name: scantron_history fk_scantron_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantron_history
add constraint fk_scantron_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: scantron_history fk_scantron_history_scantrons; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantron_history
add constraint fk_scantron_history_scantrons foreign key (scantron_table_id) references ml_app.scantrons (id)
;


--
-- Name: scantron_history fk_scantron_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.scantron_history
add constraint fk_scantron_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: sub_process_history fk_sub_process_history_sub_processes; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.sub_process_history
add constraint fk_sub_process_history_sub_processes foreign key (sub_process_id) references ml_app.sub_processes (id)
;


--
-- Name: test1_history fk_test1_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test1_history
add constraint fk_test1_history_admins foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: test1_history fk_test1_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test1_history
add constraint fk_test1_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: test1_history fk_test1_history_test1s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test1_history
add constraint fk_test1_history_test1s foreign key (test1_table_id) references ml_app.test1s (id)
;


--
-- Name: test1_history fk_test1_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test1_history
add constraint fk_test1_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: test2_history fk_test2_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test2_history
add constraint fk_test2_history_admins foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: test2_history fk_test2_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test2_history
add constraint fk_test2_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: test2_history fk_test2_history_test2s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test2_history
add constraint fk_test2_history_test2s foreign key (test2_table_id) references ml_app.test2s (id)
;


--
-- Name: test2_history fk_test2_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test2_history
add constraint fk_test2_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: test_2_history fk_test_2_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_2_history
add constraint fk_test_2_history_admins foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: test_2_history fk_test_2_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_2_history
add constraint fk_test_2_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: test_2_history fk_test_2_history_test_2s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_2_history
add constraint fk_test_2_history_test_2s foreign key (test_2_table_id) references ml_app.test_2s (id)
;


--
-- Name: test_2_history fk_test_2_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_2_history
add constraint fk_test_2_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: test_ext2_history fk_test_ext2_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_ext2_history
add constraint fk_test_ext2_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: test_ext2_history fk_test_ext2_history_test_ext2s; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_ext2_history
add constraint fk_test_ext2_history_test_ext2s foreign key (test_ext2_table_id) references ml_app.test_ext2s (id)
;


--
-- Name: test_ext2_history fk_test_ext2_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_ext2_history
add constraint fk_test_ext2_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: test_ext_history fk_test_ext_history_masters; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_ext_history
add constraint fk_test_ext_history_masters foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: test_ext_history fk_test_ext_history_test_exts; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_ext_history
add constraint fk_test_ext_history_test_exts foreign key (test_ext_table_id) references ml_app.test_exts (id)
;


--
-- Name: test_ext_history fk_test_ext_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.test_ext_history
add constraint fk_test_ext_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: user_authorization_history fk_user_authorization_history_user_authorizations; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_authorization_history
add constraint fk_user_authorization_history_user_authorizations foreign key (user_authorization_id) references ml_app.user_authorizations (id)
;


--
-- Name: user_history fk_user_history_users; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_history
add constraint fk_user_history_users foreign key (user_id) references ml_app.users (id)
;


--
-- Name: user_role_history fk_user_role_history_admins; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_role_history
add constraint fk_user_role_history_admins foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: user_role_history fk_user_role_history_user_roles; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.user_role_history
add constraint fk_user_role_history_user_roles foreign key (user_role_id) references ml_app.user_roles (id)
;


--
-- Name: rc_cis rc_cis_master_id_fkey; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.rc_cis
add constraint rc_cis_master_id_fkey foreign key (master_id) references ml_app.masters (id)
;


--
-- Name: tracker_history unique_master_protocol_tracker_id; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.tracker_history
add constraint unique_master_protocol_tracker_id foreign key (master_id, protocol_id, tracker_id) references ml_app.trackers (master_id, protocol_id, id)
;


--
-- Name: trackers valid_protocol_sub_process; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.trackers
add constraint valid_protocol_sub_process foreign key (protocol_id, sub_process_id) references ml_app.sub_processes (protocol_id, id) match full
;


--
-- Name: tracker_history valid_protocol_sub_process; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.tracker_history
add constraint valid_protocol_sub_process foreign key (protocol_id, sub_process_id) references ml_app.sub_processes (protocol_id, id) match full
;


--
-- Name: trackers valid_sub_process_event; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.trackers
add constraint valid_sub_process_event foreign key (sub_process_id, protocol_event_id) references ml_app.protocol_events (sub_process_id, id)
;


--
-- Name: tracker_history valid_sub_process_event; Type: FK CONSTRAINT; Schema: ml_app; Owner: -
--
alter table only ml_app.tracker_history
add constraint valid_sub_process_event foreign key (sub_process_id, protocol_event_id) references ml_app.protocol_events (sub_process_id, id)
;


--
-- Name: datadic_variables fk_rails_029902d3e3; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variables
add constraint fk_rails_029902d3e3 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: datadic_variable_history fk_rails_143e8a7c25; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variable_history
add constraint fk_rails_143e8a7c25 foreign key (equivalent_to_id) references ref_data.datadic_variables (id)
;


--
-- Name: redcap_data_dictionaries fk_rails_16cfa46407; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_dictionaries
add constraint fk_rails_16cfa46407 foreign key (redcap_project_admin_id) references ref_data.redcap_project_admins (id)
;


--
-- Name: q1_datadic_history fk_rails_1a1d001639; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.q1_datadic_history
add constraint fk_rails_1a1d001639 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: redcap_data_dictionary_history fk_rails_25f366a78c; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_dictionary_history
add constraint fk_rails_25f366a78c foreign key (redcap_data_dictionary_id) references ref_data.redcap_data_dictionaries (id)
;


--
-- Name: redcap_data_collection_instruments fk_rails_2aa7bf926a; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_collection_instruments
add constraint fk_rails_2aa7bf926a foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: redcap_client_requests fk_rails_32285f308d; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_client_requests
add constraint fk_rails_32285f308d foreign key (redcap_project_admin_id) references ref_data.redcap_project_admins (id)
;


--
-- Name: data_variable_packages fk_rails_33f95db154; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.data_variable_packages
add constraint fk_rails_33f95db154 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: datadic_variables fk_rails_34eadb0aee; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variables
add constraint fk_rails_34eadb0aee foreign key (equivalent_to_id) references ref_data.datadic_variables (id)
;


--
-- Name: redcap_project_users fk_rails_38d0954914; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_users
add constraint fk_rails_38d0954914 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: datadic_choice_history fk_rails_42389740a0; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_choice_history
add constraint fk_rails_42389740a0 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: redcap_data_dictionaries fk_rails_4766ebe50f; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_dictionaries
add constraint fk_rails_4766ebe50f foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: ipa_datadic_history fk_rails_496cf1eae9; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.ipa_datadic_history
add constraint fk_rails_496cf1eae9 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: datadic_variable_history fk_rails_5302a77293; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variable_history
add constraint fk_rails_5302a77293 foreign key (datadic_variable_id) references ref_data.datadic_variables (id)
;


--
-- Name: datadic_variables fk_rails_5578e37430; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variables
add constraint fk_rails_5578e37430 foreign key (redcap_data_dictionary_id) references ref_data.redcap_data_dictionaries (id)
;


--
-- Name: data_variable_package_vars fk_rails_5d96e6785d; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.data_variable_package_vars
add constraint fk_rails_5d96e6785d foreign key (user_id) references ml_app.users (id)
;


--
-- Name: domain_mapping_history fk_rails_622af264e4; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.domain_mapping_history
add constraint fk_rails_622af264e4 foreign key (domain_mapping_id) references ref_data.domain_mappings (id)
;


--
-- Name: datadic_choice_history fk_rails_63103b7cf7; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_choice_history
add constraint fk_rails_63103b7cf7 foreign key (datadic_choice_id) references ref_data.datadic_choices (id)
;


--
-- Name: data_variable_package_var_history fk_rails_65774a8686; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.data_variable_package_var_history
add constraint fk_rails_65774a8686 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: datadic_choices fk_rails_67ca4d7e1f; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_choices
add constraint fk_rails_67ca4d7e1f foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: ipa_datadic fk_rails_6a7c4aa7b2; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.ipa_datadic
add constraint fk_rails_6a7c4aa7b2 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: datadic_variable_history fk_rails_6ba6ab1e1f; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variable_history
add constraint fk_rails_6ba6ab1e1f foreign key (redcap_data_dictionary_id) references ref_data.redcap_data_dictionaries (id)
;


--
-- Name: redcap_data_collection_instrument_history fk_rails_6c93846f69; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_collection_instrument_history
add constraint fk_rails_6c93846f69 foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: redcap_project_user_history fk_rails_7ba2e90d7d; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_user_history
add constraint fk_rails_7ba2e90d7d foreign key (redcap_project_user_id) references ref_data.redcap_project_users (id)
;


--
-- Name: domain_mapping_history fk_rails_7c6956e2d4; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.domain_mapping_history
add constraint fk_rails_7c6956e2d4 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: q1_datadic fk_rails_7f8ad9a7cc; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.q1_datadic
add constraint fk_rails_7f8ad9a7cc foreign key (user_id) references ml_app.users (id)
;


--
-- Name: q1_datadic_history fk_rails_80beee9de7; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.q1_datadic_history
add constraint fk_rails_80beee9de7 foreign key (q1_datadic_id) references ref_data.q1_datadic (id)
;


--
-- Name: redcap_project_user_history fk_rails_89af917107; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_user_history
add constraint fk_rails_89af917107 foreign key (redcap_project_admin_id) references ref_data.redcap_project_admins (id)
;


--
-- Name: data_variable_package_history fk_rails_8d566af214; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.data_variable_package_history
add constraint fk_rails_8d566af214 foreign key (data_variable_package_id) references ref_data.data_variable_packages (id)
;


--
-- Name: data_variable_package_var_history fk_rails_8db1ce51dd; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.data_variable_package_var_history
add constraint fk_rails_8db1ce51dd foreign key (data_variable_package_var_id) references ref_data.data_variable_package_vars (id)
;


--
-- Name: datadic_variables fk_rails_8dc5a059ee; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variables
add constraint fk_rails_8dc5a059ee foreign key (user_id) references ml_app.users (id)
;


--
-- Name: redcap_data_dictionary_history fk_rails_9a6eca0fe7; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_dictionary_history
add constraint fk_rails_9a6eca0fe7 foreign key (redcap_project_admin_id) references ref_data.redcap_project_admins (id)
;


--
-- Name: data_variable_package_history fk_rails_9faa9f28ca; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.data_variable_package_history
add constraint fk_rails_9faa9f28ca foreign key (user_id) references ml_app.users (id)
;


--
-- Name: redcap_project_user_history fk_rails_a0bf0fdddb; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_user_history
add constraint fk_rails_a0bf0fdddb foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: redcap_project_users fk_rails_a6952cc0e8; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_users
add constraint fk_rails_a6952cc0e8 foreign key (redcap_project_admin_id) references ref_data.redcap_project_admins (id)
;


--
-- Name: redcap_project_admin_history fk_rails_a7610f4fec; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_project_admin_history
add constraint fk_rails_a7610f4fec foreign key (redcap_project_admin_id) references ref_data.redcap_project_admins (id)
;


--
-- Name: redcap_data_collection_instrument_history fk_rails_cb0b57b6c1; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_collection_instrument_history
add constraint fk_rails_cb0b57b6c1 foreign key (redcap_project_admin_id) references ref_data.redcap_project_admins (id)
;


--
-- Name: redcap_data_collection_instrument_history fk_rails_ce6075441d; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_collection_instrument_history
add constraint fk_rails_ce6075441d foreign key (redcap_data_collection_instrument_id) references ref_data.redcap_data_collection_instruments (id)
;


--
-- Name: datadic_variable_history fk_rails_d7e89fcbde; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variable_history
add constraint fk_rails_d7e89fcbde foreign key (admin_id) references ml_app.admins (id)
;


--
-- Name: ipa_datadic_history fk_rails_dd3ea51304; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.ipa_datadic_history
add constraint fk_rails_dd3ea51304 foreign key (ipa_datadic_id) references ref_data.ipa_datadic (id)
;


--
-- Name: datadic_choices fk_rails_f5497a3583; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.datadic_variable_history
add constraint fk_rails_ef47f37820 foreign key (user_id) references ml_app.users (id)
;


--
-- Name: redcap_data_dictionary_history fk_rails_fffede9aa7; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--
alter table only ref_data.redcap_data_dictionary_history
add constraint fk_rails_fffede9aa7 foreign key (admin_id) references ml_app.admins (id)
;


--
-- PostgreSQL database dump complete
--
set
  search_path to ml_app,
  ref_data
;


insert into
  "schema_migrations" (version)
values
  ('20250507104435'),
  ('20250507104432'),
  ('20250507104428'),
  ('20250507103449'),
  ('20250507102149'),
  ('20250507102049'),
  ('20250507101606'),
  ('20250507101505'),
  ('20250507101234'),
  ('20250507100814'),
  ('20250507100046'),
  ('20250506183107'),
  ('20250506182844'),
  ('20250506182209'),
  ('20250506182054'),
  ('20250506182052'),
  ('20250506182048'),
  ('20250506182045'),
  ('20250506182037'),
  ('20250506181811'),
  ('20250506181704'),
  ('20250506181655'),
  ('20250506181649'),
  ('20250506181644'),
  ('20250506181639'),
  ('20250506181633'),
  ('20250506181631'),
  ('20250506181629'),
  ('20250506181627'),
  ('20250506181624'),
  ('20250506181622'),
  ('20250506181620'),
  ('20250506181618'),
  ('20250506181613'),
  ('20250506181611'),
  ('20250506181609'),
  ('20250506181606'),
  ('20250506181604'),
  ('20250506181602'),
  ('20250506181600'),
  ('20250506181558'),
  ('20250506181556'),
  ('20250506181554'),
  ('20250506181552'),
  ('20250506181550'),
  ('20250506181548'),
  ('20250506181545'),
  ('20250506181543'),
  ('20250506181541'),
  ('20250506181539'),
  ('20250506181537'),
  ('20250506181535'),
  ('20250506181533'),
  ('20250506181530'),
  ('20250506181528'),
  ('20250506181526'),
  ('20250506181524'),
  ('20250506181522'),
  ('20250506181520'),
  ('20250506181518'),
  ('20250506181516'),
  ('20250506181513'),
  ('20250506181511'),
  ('20250506181509'),
  ('20250506181507'),
  ('20250506181504'),
  ('20250506181502'),
  ('20250506181500'),
  ('20250506181458'),
  ('20250506181456'),
  ('20250506181454'),
  ('20250506181452'),
  ('20250506181450'),
  ('20250506181448'),
  ('20250506181446'),
  ('20250506181444'),
  ('20250506181442'),
  ('20250506181440'),
  ('20250506181438'),
  ('20250506181436'),
  ('20250506181434'),
  ('20250506181431'),
  ('20250506181429'),
  ('20250506181427'),
  ('20250506181425'),
  ('20250506181423'),
  ('20250506181421'),
  ('20250506181419'),
  ('20250506181417'),
  ('20250506181415'),
  ('20250506181408'),
  ('20250506181405'),
  ('20250506181403'),
  ('20250506181353'),
  ('20250506181234'),
  ('20250506181233'),
  ('20250121090708'),
  ('20250121090630'),
  ('20250106184405'),
  ('20250106184404'),
  ('20250106112044'),
  ('20250106112043'),
  ('20240506141400'),
  ('20230420125634'),
  ('20230420125603'),
  ('20230209153019'),
  ('20220809135938'),
  ('20220809135936'),
  ('20220809135932'),
  ('20220809135928'),
  ('20220809135927'),
  ('20220809135925'),
  ('20220809135923'),
  ('20220809135921'),
  ('20220809133318'),
  ('20220809133316'),
  ('20220809133315'),
  ('20220809133313'),
  ('20220809133308'),
  ('20220809133305'),
  ('20220809132858'),
  ('20220809132857'),
  ('20220809132855'),
  ('20220809132854'),
  ('20220809132852'),
  ('20220809132850'),
  ('20220809132849'),
  ('20220809132847'),
  ('20220809132846'),
  ('20220809132844'),
  ('20220809132841'),
  ('20220809132839'),
  ('202207190945002652'),
  ('20220531121546'),
  ('20220505095408'),
  ('20220307154248'),
  ('20220301201512'),
  ('20220224023446'),
  ('20220224020931'),
  ('20220222171443'),
  ('20220222171435'),
  ('20220222171432'),
  ('20220222171431'),
  ('20220222171429'),
  ('20220202175848'),
  ('20220121143719'),
  ('20211231113457'),
  ('20211126152918'),
  ('20211124120038'),
  ('20211117180701'),
  ('20211115141001'),
  ('20211103190252'),
  ('20211103190236'),
  ('20211103185223'),
  ('20211103184551'),
  ('20211103184154'),
  ('20211103184130'),
  ('20211103181356'),
  ('20211103181306'),
  ('20211103180309'),
  ('20211103180220'),
  ('20211103175715'),
  ('20211103174805'),
  ('20211103174357'),
  ('20211103142137'),
  ('20211103142056'),
  ('20211103140946'),
  ('20211103140853'),
  ('20211103135414'),
  ('20211103135213'),
  ('20211103134942'),
  ('20211103134630'),
  ('20211103134332'),
  ('20211103134158'),
  ('20211103134113'),
  ('20211103133717'),
  ('20211103133636'),
  ('20211103133556'),
  ('20211103130755'),
  ('20211103130714'),
  ('20211103130636'),
  ('20211103130527'),
  ('20211103130445'),
  ('20211103130404'),
  ('20211103125836'),
  ('20211103125748'),
  ('20211103125704'),
  ('20211103125312'),
  ('20211103111914'),
  ('20211103104656'),
  ('20211103102329'),
  ('20211102204351'),
  ('20211102191112'),
  ('20211102185020'),
  ('20211102183437'),
  ('20211102181505'),
  ('20211102175308'),
  ('20211102172224'),
  ('20211102171644'),
  ('20211102170421'),
  ('20211102165326'),
  ('20211102164701'),
  ('20211102163630'),
  ('20211102150532'),
  ('20211102135727'),
  ('20211102133942'),
  ('20211102133054'),
  ('20211102125305'),
  ('20211102124210'),
  ('20211102123621'),
  ('20211102112754'),
  ('20211102111840'),
  ('20211102111118'),
  ('20211102105543'),
  ('20211102104540'),
  ('20211102101401'),
  ('20211102094842'),
  ('20211041105001'),
  ('20211031183429'),
  ('20211031183210'),
  ('20211031152538'),
  ('20211029102622'),
  ('20211029102522'),
  ('20211029102510'),
  ('20211029100032'),
  ('20211028113352'),
  ('20211028113230'),
  ('20211028112849'),
  ('20211028112559'),
  ('20211028105932'),
  ('20211028105333'),
  ('20211028104927'),
  ('20211028104425'),
  ('20211028103940'),
  ('20211028100701'),
  ('20211028091134'),
  ('20211027000519'),
  ('20211026235746'),
  ('20211026235506'),
  ('20211026235157'),
  ('20211026234648'),
  ('20211026234258'),
  ('20211026234201'),
  ('20211026211626'),
  ('20211026210730'),
  ('20211026113956'),
  ('20211021220918'),
  ('20211021220116'),
  ('20211021215458'),
  ('20211021215425'),
  ('20211021215217'),
  ('20211021215006'),
  ('20211021124132'),
  ('20211021105749'),
  ('20211021103613'),
  ('20211021102728'),
  ('20211021094341'),
  ('20211021092201'),
  ('20211021092046'),
  ('20210909160320'),
  ('20210907145832'),
  ('20210907145830'),
  ('20210907145829'),
  ('20210907145631'),
  ('20210907145630'),
  ('20210907145526'),
  ('20210907145525'),
  ('20210907145500'),
  ('20210907145459'),
  ('20210907145422'),
  ('20210907145420'),
  ('20210907144849'),
  ('20210907144848'),
  ('20210825135801'),
  ('20210825135706'),
  ('20210825131907'),
  ('20210825131535'),
  ('20210825125531'),
  ('20210825125455'),
  ('20210825125438'),
  ('20210825125308'),
  ('20210825125234'),
  ('20210825123623'),
  ('20210825123614'),
  ('20210825123108'),
  ('20210825122523'),
  ('20210825122415'),
  ('20210825114924'),
  ('20210825114815'),
  ('20210825114447'),
  ('20210825114042'),
  ('20210825113722'),
  ('20210825112051'),
  ('20210824190909'),
  ('20210824185034'),
  ('20210824185002'),
  ('20210824184921'),
  ('20210824183656'),
  ('20210824170919'),
  ('20210824170721'),
  ('20210824170656'),
  ('20210824170226'),
  ('20210824165922'),
  ('20210824165628'),
  ('20210824165517'),
  ('20210824165313'),
  ('20210824165201'),
  ('20210824165136'),
  ('20210824165120'),
  ('20210824162749'),
  ('20210824162134'),
  ('20210824162120'),
  ('20210824160524'),
  ('20210824154942'),
  ('20210816170804'),
  ('20210809151207'),
  ('20210712152134'),
  ('20210622181021'),
  ('20210622180218'),
  ('20210622172644'),
  ('20210526183942'),
  ('20210428102016'),
  ('20210406154800'),
  ('20210330085617'),
  ('20210318150446'),
  ('20210318150132'),
  ('20210312143952'),
  ('20210308143952'),
  ('20210305113828'),
  ('20210303164632'),
  ('20210303164631'),
  ('20210219115851'),
  ('20210219110031'),
  ('20210219110030'),
  ('20210219102128'),
  ('20210216133011'),
  ('20210216132458'),
  ('20210215153201'),
  ('20210209154901'),
  ('20210209095546'),
  ('20210204205746'),
  ('20210201124324'),
  ('20210129154600'),
  ('20210129150044'),
  ('20210128180947'),
  ('20210115141433'),
  ('20210115141431'),
  ('20210115141430'),
  ('20210115141428'),
  ('20210115141427'),
  ('20210110181202'),
  ('20210110181200'),
  ('20210110181159'),
  ('20210110180353'),
  ('20210110180351'),
  ('20210110180348'),
  ('20210110180315'),
  ('20210110175857'),
  ('20210110174047'),
  ('20210110174046'),
  ('20210110174044'),
  ('20210110174043'),
  ('20210110174040'),
  ('20210110174038'),
  ('20210110173818'),
  ('20210110173817'),
  ('20210108085826'),
  ('20210107165844'),
  ('20210107165843'),
  ('20210107165842'),
  ('20210107165841'),
  ('20210107165840'),
  ('20210107165838'),
  ('20210107152911'),
  ('20210107152900'),
  ('20210107152851'),
  ('20210107151556'),
  ('20210107151553'),
  ('20201112163129'),
  ('20201111161035'),
  ('20201111160935'),
  ('20201109114833'),
  ('20201001120642'),
  ('20200924125350'),
  ('20200924125253'),
  ('20200924121742'),
  ('20200924100402'),
  ('20200821114133'),
  ('20200813162728'),
  ('20200803162444'),
  ('20200803161100'),
  ('20200731130750'),
  ('20200731124908'),
  ('20200731124515'),
  ('20200731122147'),
  ('20200731121144'),
  ('20200731121100'),
  ('20200727122117'),
  ('20200727122116'),
  ('20200727081306'),
  ('20200727081305'),
  ('20200724153400'),
  ('20200723153130'),
  ('20200611123849'),
  ('20200403172361'),
  ('20200313160640'),
  ('20191115124732'),
  ('20191115124723'),
  ('20190906172361'),
  ('20190902123518'),
  ('20190711084434'),
  ('20190711074003'),
  ('20190709174638'),
  ('20190709174613'),
  ('20190628131713'),
  ('20190624082535'),
  ('20190614162317'),
  ('20190612140618'),
  ('20190528152006'),
  ('20190523115611'),
  ('20190517135351'),
  ('20190502142561'),
  ('20190416181222'),
  ('20190312163119'),
  ('20190312160404'),
  ('20190226173917'),
  ('20190226165938'),
  ('20190226165932'),
  ('20190225094021'),
  ('20190201160606'),
  ('20190201160559'),
  ('20190131130024'),
  ('20190130152208'),
  ('20190130152053'),
  ('20181220160047'),
  ('20181220131156'),
  ('20181206123849'),
  ('20181205103333'),
  ('20181113185315'),
  ('20181113184920'),
  ('20181113184516'),
  ('20181113184022'),
  ('20181113183446'),
  ('20181113180608'),
  ('20181113175031'),
  ('20181113172429'),
  ('20181113170144'),
  ('20181113165948'),
  ('20181113154942'),
  ('20181113154920'),
  ('20181113154855'),
  ('20181113154525'),
  ('20181113152652'),
  ('20181113150713'),
  ('20181113150331'),
  ('20181113143327'),
  ('20181113143210'),
  ('20181108115216'),
  ('20181030185123'),
  ('20181008104204'),
  ('20181004113953'),
  ('20181003182428'),
  ('20181002165822'),
  ('20181002142656'),
  ('20180924153547'),
  ('20180913142103'),
  ('20180911153518'),
  ('20180831132605'),
  ('20180830144523'),
  ('20180822093147'),
  ('20180822085118'),
  ('20180821123717'),
  ('20180818133205'),
  ('20180817114157'),
  ('20180817114138'),
  ('20180815104221'),
  ('20180814180843'),
  ('20180814142924'),
  ('20180814142562'),
  ('20180814142561'),
  ('20180814142560'),
  ('20180814142559'),
  ('20180814142112'),
  ('20180725140502'),
  ('20180723165621'),
  ('20180531091440'),
  ('20180504080300'),
  ('20180502082334'),
  ('20180426091838'),
  ('20180416145033'),
  ('20180405141059'),
  ('20180404150536'),
  ('20180321095805'),
  ('20180321082612'),
  ('20180320183512'),
  ('20180320154951'),
  ('20180320113757'),
  ('20180320105954'),
  ('20180319175721'),
  ('20180319133540'),
  ('20180319133539'),
  ('20180313091440'),
  ('20180302144109'),
  ('20180301114206'),
  ('20180228145731'),
  ('20180209171641'),
  ('20180209152747'),
  ('20180209152723'),
  ('20180209145336'),
  ('20180206173516'),
  ('20180126120818'),
  ('20180123154108'),
  ('20180123111956'),
  ('20180119173411'),
  ('20171207170748'),
  ('20171207163040'),
  ('20171031145807'),
  ('20171025095942'),
  ('20171013141837'),
  ('20171013141835'),
  ('20171002120537'),
  ('20170926144234'),
  ('20170922182052'),
  ('20170908074038'),
  ('20170901152707'),
  ('20170823145313'),
  ('20160210200919'),
  ('20160210200918'),
  ('20151218203119'),
  ('20151216102328'),
  ('20151208244918'),
  ('20151208244917'),
  ('20151208244916'),
  ('20151208200920'),
  ('20151208200919'),
  ('20151208200918'),
  ('20151208144918'),
  ('20151202180745'),
  ('20151125192206'),
  ('20151124151501'),
  ('20151123203524'),
  ('20151120151912'),
  ('20151120150828'),
  ('20151109223309'),
  ('20151028155426'),
  ('20151028145802'),
  ('20151026181305'),
  ('20151023171217'),
  ('20151022191658'),
  ('20151022142507'),
  ('20151021171534'),
  ('20151021162145'),
  ('20151020145339'),
  ('20151019204910'),
  ('20151019203248'),
  ('20151016160248'),
  ('20151015183136'),
  ('20151015150733'),
  ('20151015142035'),
  ('20151013191910'),
  ('20151009191559'),
  ('20151005143945'),
  ('20150924183936'),
  ('20150924163412'),
  ('20150826145125'),
  ('20150826145029'),
  ('20150820155555'),
  ('20150820152721'),
  ('20150820151728'),
  ('20150820151214'),
  ('20150812194032'),
  ('20150811174323'),
  ('20150805200932'),
  ('20150805161302'),
  ('20150805132950'),
  ('20150804203710'),
  ('20150804160523'),
  ('20150803194551'),
  ('20150803194546'),
  ('20150803181029'),
  ('20150730202422'),
  ('20150730181206'),
  ('20150730174055'),
  ('20150729182424'),
  ('20150728213551'),
  ('20150728213254'),
  ('20150728203820'),
  ('20150728133359'),
  ('20150727164955'),
  ('20150724165441'),
  ('20150721204937'),
  ('20150720175827'),
  ('20150720173900'),
  ('20150720141845'),
  ('20150715181110'),
  ('20150710160215'),
  ('20150710160209'),
  ('20150710135959'),
  ('20150710135307'),
  ('20150707222630'),
  ('20150707153720'),
  ('20150707151129'),
  ('20150707151032'),
  ('20150707151010'),
  ('20150707151004'),
  ('20150707150921'),
  ('20150707150615'),
  ('20150707150524'),
  ('20150707143233'),
  ('20150707142702'),
  ('20150702200308'),
  ('20150630202829'),
  ('20150629210656'),
  ('20150626190344'),
  ('20150625213040'),
  ('20150623194212'),
  ('20150623191520'),
  ('20150622144725'),
  ('20150619165405'),
  ('20150618161945'),
  ('20150618161857'),
  ('20150618143506'),
  ('20150616202829'),
  ('20150616202753'),
  ('20150611202453'),
  ('20150611180303'),
  ('20150611145259'),
  ('20150611144834'),
  ('20150610220451'),
  ('20150610220320'),
  ('20150610220253'),
  ('20150610183502'),
  ('20150610160257'),
  ('20150610155810'),
  ('20150610143629'),
  ('20150610142403'),
  ('20150609190556'),
  ('20150609185749'),
  ('20150609185229'),
  ('20150609161656'),
  ('20150609160545'),
  ('20150609150931'),
  ('20150609140033'),
  ('20150604160659'),
  ('20150603170429'),
  ('20150603153758'),
  ('20150603135202'),
  ('20150602205642'),
  ('20150602181925'),
  ('20150602181400'),
  ('20150602181229'),
  ('20150602181200')
;