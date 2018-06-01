-- SQL run by sync_subject_data.sh
-- Running this SQL script independently does not make sense
set search_path=ml_app;

CREATE TEMPORARY TABLE temp_ipa_assignments (
    master_id integer,
    ipa_id bigint
);

CREATE TEMPORARY TABLE temp_player_infos AS ( SELECT * FROM player_infos WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_player_contacts AS ( SELECT * FROM player_contacts WHERE ID IS NULL);

\copy temp_ipa_assignments from /tmp/zeus_ipa_assignments.csv with (header true, format csv)
\copy temp_player_infos (id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source) from /tmp/zeus_ipa_player_infos.csv with (header true, format csv)
\copy temp_player_contacts from /tmp/zeus_ipa_player_contacts.csv with (header true, format csv)
\copy temp_addresses from /tmp/zeus_ipa_addresses.csv with (header true, format csv)

SELECT create_all_remote_ipa_records();
