create schema IF NOT EXISTS sleep AUTHORIZATION fphs;

set search_path=sleep,ml_app;

-- # Access
\i db/app_specific/sleep/aws-db/access/create_sleep_access_pis.sql
\i db/app_specific/sleep/aws-db/access/create_sleep_access_bwh_staffs.sql
\i db/app_specific/sleep/aws-db/access/create_sleep_access_interventionists.sql

-- # External Identifier
\i db/app_specific/sleep/aws-db/external-id/create_ext_id_assignments.sql
\i db/app_specific/sleep/aws-db/external-id/create_bwh_sleep_id_numbers.sql

-- # Tracker
\i db/app_specific/sleep/aws-db/tracker/create_activity_log_assignments.sql
\i db/app_specific/sleep/aws-db/tracker/create_screenings_table.sql
-- \i db/app_specific/sleep/aws-db/tracker/create_emergency_contacts.sql
\i db/app_specific/sleep/aws-db/tracker/create_appointment_table.sql
\i db/app_specific/sleep/aws-db/tracker/create_consent_mailings.sql
-- \i db/app_specific/sleep/aws-db/tracker/create_hotel_table.sql
\i db/app_specific/sleep/aws-db/tracker/create_payment_table.sql
-- \i db/app_specific/sleep/aws-db/tracker/create_survey_table.sql
-- \i db/app_specific/sleep/aws-db/tracker/create_transportation_table.sql
\i db/app_specific/sleep/aws-db/tracker/create_withdrawals_table.sql
\i db/app_specific/sleep/aws-db/tracker/create_mrn_external_identifier.sql

-- # Phone Screen
\i db/app_specific/sleep/aws-db/phone-screen/create_activity_log_assignment_phone_screens_table.sql
\i db/app_specific/sleep/aws-db/phone-screen/create_ps_init_screening_table.sql

-- # Sleep Screening
\i db/app_specific/sleep/aws-db/screening/create_ps_init_screening_table.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_ese_questions.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_isi_questions.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_ps_audit_c_questions.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_ps_basic_responses.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_ps_dast2_mod_questions.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_ps_eligibles.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_ps_non_eligibles.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_ps_eligibility_followups.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_ps_possibly_eligibles.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_ps_screener_responses.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_ps_sleep_apnea_responses.sql
\i db/app_specific/sleep/aws-db/screening/create_sleep_ps_subject_contacts.sql
\i db/app_specific/sleep/aws-db/screening/trigger_ese_score_calc.sql
\i db/app_specific/sleep/aws-db/screening/trigger_isi_score_calc.sql

-- # Sleep Screening Part 2
\i db/app_specific/sleep/aws-db/screening_2/create_sleep_ps2_initial_screenings.sql
\i db/app_specific/sleep/aws-db/screening_2/create_activity_log_sleep_assignment_phone_screen2s.sql
\i db/app_specific/sleep/aws-db/screening_2/create_sleep_ps2_eligibles.sql
\i db/app_specific/sleep/aws-db/screening_2/create_sleep_ps2_non_eligibles.sql
\i db/app_specific/sleep/aws-db/screening_2/create_sleep_ps2_phq8_questions.sql

-- # InEx
\i db/app_specific/sleep/aws-db/inex/create_activity_log_inex_checklist_table.sql
\i db/app_specific/sleep/aws-db/inex/create_sleep_inex_checklists.sql


-- # Navigation
-- \i db/app_specific/sleep/aws-db/navigation/create_activity_log_navigation_table.sql
-- \i db/app_specific/sleep/aws-db/navigation/create_station_contacts_table.sql

-- # Adverse Events
\i db/app_specific/sleep/aws-db/adverse-events/create_activity_log_adverse_events_table.sql
\i db/app_specific/sleep/aws-db/adverse-events/create_adverse_events_table.sql

-- # Protocol Deviations
\i db/app_specific/sleep/aws-db/protocol-deviations/create_activity_log_protocol_deviations_table.sql
\i db/app_specific/sleep/aws-db/protocol-deviations/create_protocol_deviations_table.sql
\i db/app_specific/sleep/aws-db/protocol-deviations/create_protocol_exceptions_table.sql


-- # Unknown
-- \i db/app_specific/sleep/aws-db/create_activity_log_post_visit_table.sql
-- \i db/app_specific/sleep/aws-db/create_minor_deviations_activity_log.sql

-- # Phone Screen Backups
-- \i db/app_specific/sleep/aws-db/create_ps_football_experience_table.sql
-- \i db/app_specific/sleep/aws-db/create_ps_health_table.sql
-- \i db/app_specific/sleep/aws-db/create_ps_size_table.sql
-- \i db/app_specific/sleep/aws-db/create_ps_mris_table.sql
-- \i db/app_specific/sleep/aws-db/create_ps_sleeps_table.sql
-- \i db/app_specific/sleep/aws-db/create_ps_tms_tests_table.sql
-- \i db/app_specific/sleep/aws-db/create_ps_tmocas_table.sql
-- \i db/app_specific/sleep/aws-db/trigger_tmoca_score_calc.sql


-- # MedNav
\i db/app_specific/sleep/aws-db/mednav/create_al_med_navs.sql
\i db/app_specific/sleep/aws-db/mednav/create_sleep_pi_follow_ups.sql
\i db/app_specific/sleep/aws-db/mednav/create_incidental_findings_table.sql
\i db/app_specific/sleep/aws-db/mednav/create_mednav_provider_comms.sql
\i db/app_specific/sleep/aws-db/mednav/create_mednav_provider_reports.sql
-- \i db/app_specific/sleep/aws-db/mednav/create_exit_interviews_table.sql
-- \i db/app_specific/sleep/aws-db/mednav/create_four_wk_followups_table.sql
-- \i db/app_specific/sleep/aws-db/mednav/create_mednav_followups_table.sql
-- \i db/app_specific/sleep/aws-db/mednav/create_two_wk_followups_table.sql

-- # Discussions
\i db/app_specific/sleep/aws-db/discussions/create_activity_log_sleep_assignment_discussions.sql


set search_path=ml_app;
\i db/app_specific/sleep/aws-db/z-sync/z-ml_app-sync-create_sync_subject_data_aws_db.sql

set search_path=sleep,ml_app;
\i db/app_specific/sleep/aws-db/0-scripts/z_grant_roles.sql
