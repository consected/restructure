-- SQL run by sync_subject_data.sh
-- Running this SQL script independently does not make sense
set search_path=persnet,ml_app;

CREATE TEMPORARY TABLE temp_persnet_assignments (
  master_id integer,
  persnet_id bigint,
  status varchar,
  to_master_id integer
);

CREATE TEMPORARY TABLE temp_player_infos AS ( SELECT * FROM player_infos WHERE ID IS NULL);
CREATE TEMPORARY TABLE temp_player_contacts AS ( SELECT * FROM player_contacts WHERE ID IS NULL);

\copy temp_persnet_assignments (master_id, persnet_id) from $PERSNET_ASSIGNMENTS_FILE with (header true, format csv)
\copy temp_player_infos (id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source) from $PERSNET_PLAYER_INFOS_FILE with (header true, format csv)
\copy temp_player_contacts from $PERSNET_PLAYER_CONTACTS_FILE with (header true, format csv)

SELECT create_all_remote_persnet_records();

\copy (SELECT * FROM temp_persnet_assignments) TO $PERSNET_ASSIGNMENTS_RESULTS_FILE WITH (format csv, header true);
