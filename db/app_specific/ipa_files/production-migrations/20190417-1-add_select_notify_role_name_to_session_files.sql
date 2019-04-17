set search_path=filestore,ml_app;

alter table activity_log_ipa_assignment_session_filestores add column select_notify_role_name varchar;
alter table activity_log_ipa_assignment_session_filestore_history add column select_notify_role_name varchar;

CREATE or REPLACE FUNCTION log_activity_log_ipa_assignment_session_filestore_update() RETURNS trigger
LANGUAGE plpgsql
AS $$
    BEGIN
        INSERT INTO activity_log_ipa_assignment_session_filestore_history
        (
            master_id,
            ipa_assignment_id,
            select_type,
            operator,
            notes,
            session_date,
            session_time,
            select_status,
            select_confirm_status,
            select_notify_role_name,
            extra_log_type,
            user_id,
            created_at,
            updated_at,
            activity_log_ipa_assignment_session_filestore_id
            )
        SELECT
            NEW.master_id,
            NEW.ipa_assignment_id,
            NEW.select_type,
            NEW.operator,
            NEW.notes,
            NEW.session_date,
            NEW.session_time,
            NEW.select_status,
            NEW.select_confirm_status,
            NEW.select_notify_role_name,
            NEW.extra_log_type,
            NEW.user_id,
            NEW.created_at,
            NEW.updated_at,
            NEW.id
        ;
        RETURN NEW;
    END;
$$;
