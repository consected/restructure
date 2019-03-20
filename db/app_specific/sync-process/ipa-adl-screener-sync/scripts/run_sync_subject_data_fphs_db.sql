-- set search_path=ml_app, ipa_ops;
BEGIN;

CREATE TEMPORARY TABLE temp_adl_screeners AS
  SELECT adl.*, adl.redcap_survey_identifier "ipa_id", ipa.master_id "master_id", ''::varchar "status", -1::INTEGER to_master_id
  FROM adl_screener_data adl
  INNER JOIN ipa_assignments ipa
  ON adl.redcap_survey_identifier = ipa.ipa_id
  LEFT JOIN sync_statuses s
    ON from_db = 'fphs-adl-screener'
    AND to_db = 'athena-adl-screener'
    AND ipa.master_id = s.from_master_id
  WHERE (
      s.id IS NULL
      OR coalesce(s.select_status, '') NOT IN ('completed', 'already transferred') AND s.created_at < now() - interval '2 hours'
    )
  ;


select lock_transfer_records('fphs-adl-screener', 'athena-adl-screener', (select array_agg(master_id) from temp_adl_screeners));


\copy (SELECT * FROM temp_adl_screeners) TO $IPA_ADL_SCREENERS_FILE WITH (format csv, header true);

END;
