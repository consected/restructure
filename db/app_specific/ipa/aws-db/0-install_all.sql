create schema ipa_ops OWNER fphs;

set search_path=ipa_ops;
\i db/app_specific/ipa/create_activity_log_adverse_events_table.sql
\i db/app_specific/ipa/create_activity_log_inex_checklist_table.sql
\i db/app_specific/ipa/create_activity_log_ipa_assignment_phone_screens_table.sql
\i db/app_specific/ipa/create_activity_log_ipa_assignments.sql
\i db/app_specific/ipa/create_activity_log_ipa_protocol_deviations_table.sql
\i db/app_specific/ipa/create_activity_log_navigation_table.sql
\i db/app_specific/ipa/create_activity_log_post_visit_table.sql
\i db/app_specific/ipa/create_adl_screener_data_table.sql
\i db/app_specific/ipa/create_emergency_contacts.sql
\i db/app_specific/ipa/create_ipa_adl_informant_screener.sql
\i db/app_specific/ipa/create_ipa_adverse_events_table.sql
\i db/app_specific/ipa/create_ipa_appointment_table.sql
\i db/app_specific/ipa/create_ipa_assignments_table.sql
\i db/app_specific/ipa/create_ipa_consent_mailings.sql
\i db/app_specific/ipa/create_ipa_hotel_table.sql
\i db/app_specific/ipa/create_ipa_inex_checklist_table.sql
\i db/app_specific/ipa/create_ipa_init_screening_table.sql
\i db/app_specific/ipa/create_ipa_payment_table.sql
\i db/app_specific/ipa/create_ipa_protocol_deviations_table.sql
\i db/app_specific/ipa/create_ipa_ps_football_experience_table.sql
\i db/app_specific/ipa/create_ipa_ps_health_table.sql
\i db/app_specific/ipa/create_ipa_ps_informant_details_table.sql
\i db/app_specific/ipa/create_ipa_ps_init_screening_table.sql
\i db/app_specific/ipa/create_ipa_ps_size_table.sql
\i db/app_specific/ipa/create_ipa_ps_mris_table.sql
\i db/app_specific/ipa/create_ipa_ps_tmocas_table.sql
\i db/app_specific/ipa/create_ipa_screenings_table.sql
\i db/app_specific/ipa/create_ipa_sleeps_table.sql
\i db/app_specific/ipa/create_ipa_survey_table.sql
\i db/app_specific/ipa/create_ipa_tms_reviews_view.sql
\i db/app_specific/ipa/create_ipa_tms_tests_table.sql
\i db/app_specific/ipa/create_ipa_transportation_table.sql
\i db/app_specific/ipa/create_ipa_withdrawals_table.sql
\i db/app_specific/ipa/create_minor_deviations_activity_log.sql
\i db/app_specific/ipa/create_mrn_external_identifier.sql
\i db/app_specific/ipa/create_station_contacts_table.sql
\i db/app_specific/ipa/post_create_alter_activity_log_navigation_table.sql
\i db/app_specific/ipa/post_create_alter_ipa_screenings_table.sql
\i db/app_specific/ipa/post_create_alter_withdrawals_table.sql
\i db/app_specific/ipa/prep_inex_checklist_from_ps.sql
\i db/app_specific/ipa/trigger_adl_screener.sql
\i db/app_specific/ipa/trigger_new_screening_schedule.sql
\i db/app_specific/ipa/trigger_perform_screening_actions.sql
\i db/app_specific/ipa/trigger_screening_follow_up.sql

set search_path=ml_app;
\i db/app_specific/ipa/z-ml_app-sync-create_sync_subject_data_aws_db.sql


REVOKE ALL ON SCHEMA ipa_ops FROM fphs;
GRANT ALL ON SCHEMA ipa_ops TO fphs;
GRANT USAGE ON SCHEMA ipa_ops TO fphsadm;
GRANT USAGE ON SCHEMA ipa_ops TO fphsusr;
GRANT USAGE ON SCHEMA ipa_ops TO fphsetl;


GRANT ALL ON ALL TABLES IN SCHEMA ipa_ops TO fphs;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ipa_ops TO fphsusr;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ipa_ops TO fphsetl;
GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON ALL TABLES IN SCHEMA ipa_ops TO fphsadm;

GRANT ALL ON ALL SEQUENCES IN SCHEMA ipa_ops TO fphs;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ipa_ops TO fphsusr;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ipa_ops TO fphsetl;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ipa_ops TO fphsadm;


DO
$body$
BEGIN

IF EXISTS (
   SELECT *
   FROM   pg_catalog.pg_roles
   WHERE  rolname = 'fphsrailsapp') THEN

   GRANT USAGE ON SCHEMA ipa_ops TO fphsrailsapp;
   GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ipa_ops TO fphsrailsapp;
   GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA ipa_ops TO fphsrailsapp;
END IF;


END
$body$;
