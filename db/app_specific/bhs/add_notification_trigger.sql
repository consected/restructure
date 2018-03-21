INSERT INTO users (email, disabled, created_at, updated_at) values ('dl-fphs-elaine-bhs-pis@listserv.med.harvard.edu', false, now(), now());

CREATE FUNCTION activity_log_bhs_assignment_insert_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
          app_type RECORD;
          dl_user RECORD;
        BEGIN

            select id from app_types
            into app_type
            where name = 'bhs' and (disabled is null or disabled = false)
            order by id asc
            limit 1;

            select id from users
            into dl_user
            where email = 'dl-fphs-elaine-bhs-pis@listserv.med.harvard.edu'
            limit 1;

            IF NEW.bhs_assignment_id IS NOT NULL and (NEW.extra_log_type IS NULL or NEW.extra_log_type = '') THEN

              insert into ml_app.message_notifications
              (
                subject,
                app_type_id,
                user_id,
                recipient_user_ids,
                layout_template_name,
                content_template_name,
                item_type,
                item_id,
                master_id,
                message_type,
                created_at,
                updated_at
              )
              SELECT
                'New Brain Health Study Info Request',
                app_type.id,
                NEW.user_id,
                ARRAY[dl_user.id],
                'bhs pi notification layout',
                'bhs pi notification content',
                'ActivityLog::BhsAssignment',
                NEW.id,
                NEW.master_id,
                'email',
                now(),
                now()
                ;

              RETURN NEW;
            END IF;
        END;
    $$;

CREATE TRIGGER activity_log_bhs_assignment_history_insert_notification AFTER INSERT ON activity_log_bhs_assignments FOR EACH ROW EXECUTE PROCEDURE activity_log_bhs_assignment_insert_notification();
