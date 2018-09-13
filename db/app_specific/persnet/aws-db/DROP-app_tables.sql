set search_path=ml_app;

DROP FUNCTION log_activity_log_persnet_assignment_update() cascade;
DROP TABLE activity_log_persnet_assignment_history cascade;
DROP TABLE activity_log_persnet_assignments cascade;

DROP FUNCTION log_persnet_assignment_update() cascade;
DROP TABLE persnet_assignment_history cascade;
DROP TABLE persnet_assignments cascade;
