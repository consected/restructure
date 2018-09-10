set search_path=ml_app;

DROP FUNCTION log_activity_log_{{app_name}}_assignment_update() cascade;
DROP TABLE activity_log_{{app_name}}_assignment_history cascade;
DROP TABLE activity_log_{{app_name}}_assignments cascade;

DROP FUNCTION log_{{app_name}}_assignment_update() cascade;
DROP TABLE {{app_name}}_assignment_history cascade;
DROP TABLE {{app_name}}_assignments cascade;
