CREATE TEMPORARY TABLE temp_ipa_assignments (
    master_id integer,
    ipa_id integer,
    event varchar
);


INSERT INTO temp_ipa_assignments (SELECT * FROM ml_app.find_new_athena_ipa_records());

SELECT ml_app.lock_transfer_records_with_external_ids_and_events(
  'athena-db',
  'fphs-db',
  (select array_agg(master_id) from temp_ipa_assignments),
  (select array_agg(ipa_id) from temp_ipa_assignments),
  'ipa_assignments',
  (select array_agg(event) from temp_ipa_assignments)
);


\copy (SELECT * FROM temp_ipa_assignments) TO $IPA_ASSIGNMENTS_FILE WITH (format csv, header true);
\copy (SELECT id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, user_id, created_at, updated_at, start_year, rank, notes, college, end_year, source FROM player_infos WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO $IPA_PLAYER_INFOS_FILE WITH (format csv, header true);
\copy (SELECT * FROM player_contacts WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO $IPA_PLAYER_CONTACTS_FILE WITH (format csv, header true);
\copy (SELECT * FROM addresses WHERE master_id IN (SELECT master_id FROM temp_ipa_assignments)) TO $IPA_ADDRESSES_FILE WITH (format csv, header true);
