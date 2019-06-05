-- SQL run by sync_subject_data.sh
-- Running this SQL script independently does not make sense
set search_path=ml_app, ipa_ops;

CREATE TEMPORARY TABLE temp_ipa_assignments (
    master_id integer,
    ipa_id bigint,
    status varchar,
    to_master_id integer
);

CREATE TEMPORARY TABLE temp_player_infos AS ( SELECT * FROM player_infos WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_player_contacts AS ( SELECT * FROM player_contacts WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_addresses AS ( SELECT * FROM addresses WHERE ID IS NULL);


\copy temp_ipa_assignments (master_id, ipa_id) from $IPA_ASSIGNMENTS_FILE with (header true, format csv)
\copy temp_player_infos (id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source) from $IPA_PLAYER_INFOS_FILE with (header true, format csv)
\copy temp_player_contacts from $IPA_PLAYER_CONTACTS_FILE with (header true, format csv)
\copy temp_addresses from $IPA_ADDRESSES_FILE with (header true, format csv)

UPDATE temp_ipa_assignments SET status = 'failed';

SELECT create_all_remote_ipa_records();

\copy (SELECT * FROM temp_ipa_assignments) TO $IPA_ASSIGNMENTS_RESULTS_FILE WITH (format csv, header true);
