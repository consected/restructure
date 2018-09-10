-- SQL run by sync_subject_data.sh
-- Running this SQL script independently does not make sense
set search_path=ml_app;

CREATE TEMPORARY TABLE temp_{{app_name}}_assignments (
    master_id integer,
    {{app_name}}_id bigint
);

CREATE TEMPORARY TABLE temp_player_infos AS ( SELECT * FROM player_infos WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_player_contacts AS ( SELECT * FROM player_contacts WHERE ID IS NULL);

\copy temp_{{app_name}}_assignments from /tmp/zeus_{{app_name}}_assignments.csv with (header true, format csv)
\copy temp_player_infos (id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source) from /tmp/zeus_{{app_name}}_player_infos.csv with (header true, format csv)
\copy temp_player_contacts from /tmp/zeus_{{app_name}}_player_contacts.csv with (header true, format csv)

SELECT create_all_remote_{{app_name}}_records();
