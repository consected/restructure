\set VERBOSITY terse

-- SQL run by sync_subject_data.sh
-- Running this SQL script independently does not make sense
set search_path=ml_app, ipa_ops;



CREATE TEMPORARY TABLE temp_ipa_assignments (
    master_id integer,
    ipa_id integer,
    status varchar,
    to_master_id integer,
    event varchar,
    record_updated_at timestamp without time zone
);

CREATE TEMPORARY TABLE temp_player_infos AS ( SELECT * FROM player_infos WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_player_contacts AS ( SELECT * FROM player_contacts WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_addresses AS ( SELECT * FROM addresses WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_events (master_id integer, ipa_id integer, event varchar, created_at timestamp without time zone);

BEGIN;
\copy temp_ipa_assignments (master_id, ipa_id, event, record_updated_at) from $ASSIGNMENTS_FILE with (header true, format csv)
UPDATE temp_ipa_assignments SET status = 'failed';
COMMIT;

BEGIN;

\copy temp_player_infos (id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source) from $PLAYER_INFOS_FILE with (header true, format csv)
\copy temp_player_contacts from $PLAYER_CONTACTS_FILE with (header true, format csv)
\copy temp_addresses from $ADDRESSES_FILE with (header true, format csv)
\copy temp_events from $EVENTS_FILE with (header true, format csv)


COMMIT;

SELECT update_all_primary_ipa_records();

\copy (SELECT * FROM temp_ipa_assignments) TO $ASSIGNMENTS_RESULTS_FILE WITH (format csv, header true);
