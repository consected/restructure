\set ON_ERROR_STOP 1

create schema IF NOT EXISTS grit AUTHORIZATION fphs;

set search_path=grit,ml_app;

-- # Access
\i db/app_specific/grit/aws-db/access/create_access_pis.sql
\i db/app_specific/grit/aws-db/access/create_access_msm_staffs.sql

-- # External Identifier
\i db/app_specific/grit/aws-db/external-id/create_ext_id_assignments.sql
\i db/app_specific/grit/aws-db/external-id/create_msm_id_numbers.sql

-- # Tracker
\i db/app_specific/grit/aws-db/tracker/create_activity_log_assignments.sql
\i db/app_specific/grit/aws-db/tracker/create_screenings_table.sql
\i db/app_specific/grit/aws-db/tracker/create_appointment_table.sql
\i db/app_specific/grit/aws-db/tracker/create_consent_mailings.sql
\i db/app_specific/grit/aws-db/tracker/create_withdrawals_table.sql
\i db/app_specific/grit/aws-db/tracker/create_mrn_external_identifier.sql

-- # Phone Screen
\i db/app_specific/grit/aws-db/phone-screen/create_activity_log_assignment_phone_screens_table.sql

-- # grit Screening
\i db/app_specific/grit/aws-db/screening/create_grit_msm_screening_details.sql
\i db/app_specific/grit/aws-db/screening/create_ps_init_screening_table.sql
\i db/app_specific/grit/aws-db/screening/create_ps_audit_c_questions.sql
\i db/app_specific/grit/aws-db/screening/create_ps_pain_questions.sql
\i db/app_specific/grit/aws-db/screening/create_ps_participations.sql
\i db/app_specific/grit/aws-db/screening/create_ps_eligibles.sql
\i db/app_specific/grit/aws-db/screening/create_ps_non_eligibles.sql
\i db/app_specific/grit/aws-db/screening/create_ps_eligibility_followups.sql
\i db/app_specific/grit/aws-db/screening/create_ps_possibly_eligibles.sql
\i db/app_specific/grit/aws-db/screening/create_ps_screener_responses.sql


-- # Adverse Events
\i db/app_specific/grit/aws-db/adverse-events/create_activity_log_adverse_events_table.sql
\i db/app_specific/grit/aws-db/adverse-events/create_adverse_events_table.sql

-- # Protocol Deviations
\i db/app_specific/grit/aws-db/protocol-deviations/create_activity_log_protocol_deviations_table.sql
\i db/app_specific/grit/aws-db/protocol-deviations/create_protocol_deviations_table.sql
\i db/app_specific/grit/aws-db/protocol-deviations/create_protocol_exceptions_table.sql



-- # Phone Screen Backups
-- \i db/app_specific/grit/aws-db/create_ps_football_experience_table.sql
-- \i db/app_specific/grit/aws-db/create_ps_health_table.sql
-- \i db/app_specific/grit/aws-db/create_ps_size_table.sql
-- \i db/app_specific/grit/aws-db/create_ps_mris_table.sql
-- \i db/app_specific/grit/aws-db/create_ps_grits_table.sql
-- \i db/app_specific/grit/aws-db/create_ps_tms_tests_table.sql
-- \i db/app_specific/grit/aws-db/create_ps_tmocas_table.sql
-- \i db/app_specific/grit/aws-db/trigger_tmoca_score_calc.sql


-- # MedNav
\i db/app_specific/grit/aws-db/follow-up/create_al_followups.sql
\i db/app_specific/grit/aws-db/follow-up/create_pi_followups.sql

-- # Discussions
\i db/app_specific/grit/aws-db/discussions/create_activity_log_assignment_discussions.sql


set search_path=ml_app;
\i db/app_specific/grit/aws-db/z-sync/z-ml_app-sync-create_sync_subject_data_aws_db.sql

set search_path=grit,ml_app;
\i db/app_specific/grit/aws-db/0-scripts/z_grant_roles.sql
