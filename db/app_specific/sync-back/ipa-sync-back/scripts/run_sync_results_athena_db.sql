\set VERBOSITY terse

set search_path=ml_app, ipa_ops;

BEGIN;

CREATE TEMPORARY TABLE temp_ipa_assignments_results (
    master_id integer,
    ipa_id bigint,
    status varchar,
    to_master_id integer,
    event varchar,
    record_updated_at timestamp without time zone
);

\copy temp_ipa_assignments_results (master_id, ipa_id, status, to_master_id, event, record_updated_at) from $ASSIGNMENTS_RESULTS_FILE with (header true, format csv)

select update_ipa_transfer_record_results('athena-db', 'fphs-db', 'ipa_assignments');

COMMIT;
