set search_path=ml_app;

DROP FUNCTION log_activity_log_bhs_assignment_update() cascade;
DROP TABLE activity_log_bhs_assignment_history cascade;
DROP TABLE activity_log_bhs_assignments cascade;

DROP FUNCTION log_bhs_assignment_update() cascade;
DROP TABLE bhs_assignment_history cascade;
DROP TABLE bhs_assignments cascade;
