-- SQL run by sync_subject_data.sh
-- Running this SQL script independently does not make sense

CREATE TEMPORARY TABLE temp_sleep_assignments (
    master_id integer,
    sleep_id bigint,
    status varchar,
    to_master_id integer
);

CREATE TEMPORARY TABLE temp_player_infos AS ( SELECT * FROM player_infos WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_player_contacts AS ( SELECT * FROM player_contacts WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_addresses AS ( SELECT * FROM addresses WHERE ID IS NULL);


\copy temp_sleep_assignments (master_id, sleep_id) from $SLEEP_ASSIGNMENTS_FILE with (header true, format csv)
\copy temp_player_infos (id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source) from $SLEEP_PLAYER_INFOS_FILE with (header true, format csv)
\copy temp_player_contacts from $SLEEP_PLAYER_CONTACTS_FILE with (header true, format csv)
\copy temp_addresses from $SLEEP_ADDRESSES_FILE with (header true, format csv)

UPDATE temp_sleep_assignments SET status = 'failed';

SELECT create_all_remote_sleep_records();

\copy (SELECT * FROM temp_sleep_assignments) TO $SLEEP_ASSIGNMENTS_RESULTS_FILE WITH (format csv, header true);
