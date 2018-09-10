SET SEARCH_PATH=persnet_schema,ml_app;

/* Simple support function to get app_type.id using a name */
CREATE OR REPLACE FUNCTION get_app_type_id_by_name(app_type_name VARCHAR) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
  DECLARE
    app_type_id INTEGER;
  BEGIN

    select id from app_types
    into app_type_id
    where name = app_type_name and (disabled is null or disabled = false)
    order by id asc
    limit 1;

    RETURN app_type_id;

  END;
$$;


/* Simple support function to get an array of users.id for a role in an app type */
CREATE OR REPLACE FUNCTION get_user_ids_for_app_type_role(for_app_type_id INTEGER, with_role_name VARCHAR) RETURNS INTEGER[]
LANGUAGE plpgsql
AS $$
  DECLARE
    user_ids INTEGER[];
  BEGIN

    select array_agg(ur.user_id)
    from user_roles ur
    inner join users u on ur.user_id = u.id
    into user_ids
    where
      role_name = with_role_name AND
      ur.app_type_id = for_app_type_id AND
      (ur.disabled is null or ur.disabled = false) AND
      (ur.disabled is null or u.disabled = false)
    ;

    RETURN user_ids;

  END;
$$;


/*

  Create a message notification and send it to the distribution list
  Run by the persnet sync scripts after a successful insert of Zeus player data into skeleton Elaine persnet subject record

*/
CREATE OR REPLACE FUNCTION activity_log_persnet_assignment_info_request_notification(activity_id INTEGER) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
    DECLARE
        dl_users INTEGER[];
        activity_record RECORD;
        message_id INTEGER;
        current_app_type_id INTEGER;
    BEGIN

        current_app_type_id := get_app_type_id_by_name('persnet');

        dl_users := get_user_ids_for_app_type_role(current_app_type_id, 'pi');

        SELECT * INTO activity_record FROM activity_log_persnet_assignments WHERE id = activity_id;

        IF activity_record.persnet_assignment_id IS NOT NULL AND activity_record.extra_log_type = 'primary'
        THEN

          SELECT
          INTO message_id
            create_message_notification_email(
              current_app_type_id,
              activity_record.master_id,
              activity_record.id,
              'ActivityLog::PersnetAssignment'::VARCHAR,
              activity_record.user_id,
              dl_users,
              'persnet notification layout'::VARCHAR,
              'persnet pi notification content'::VARCHAR,
              'New Personal Networks Info Request'::VARCHAR,
              now()::TIMESTAMP
            )
          ;

        END IF;
        RETURN message_id;
    END;
$$;


/*

  Handle immediate notifications based on new persnet activity log records being created.
  Run from a trigger on insert into activity_log_persnet_assignments table

*/
DROP FUNCTION IF EXISTS activity_log_persnet_assignment_insert_notification() cascade;

CREATE OR REPLACE FUNCTION activity_log_persnet_assignment_insert_notification() RETURNS trigger
LANGUAGE plpgsql
AS $$
    DECLARE
      message_id INTEGER;
      to_user_ids INTEGER[];
      num_primary_logs INTEGER;
      current_app_type_id INTEGER;
  BEGIN

        current_app_type_id := get_app_type_id_by_name('persnet');

        IF NEW.extra_log_type = 'contact_initiator' THEN

            -- Get the most recent info request from the activity log records for this master_id
            -- This gives us the user_id of the initiator of the request
            select array_agg(user_id)
            into to_user_ids
            from
            (select user_id
            from activity_log_persnet_assignments
            where
              master_id = NEW.master_id
              and extra_log_type = 'primary'
            order by id desc
            limit 1) t;

            -- If nobody was set, send to all users in the RA role
            IF to_user_ids IS NULL THEN
              to_user_ids := get_user_ids_for_app_type_role(current_app_type_id, 'ra');
            END IF;

            SELECT
            INTO message_id
              create_message_notification_email(
                current_app_type_id,
                NEW.master_id,
                NEW.id,
                'ActivityLog::PersnetAssignment'::VARCHAR,
                NEW.user_id,
                to_user_ids,
                'persnet notification layout'::VARCHAR,
                'persnet message notification content'::VARCHAR,
                'Personal Networks contact from PI'::VARCHAR,
                now()::TIMESTAMP
              )
            ;

            RETURN NEW;
        END IF;

        IF NEW.extra_log_type = 'respond_to_pi' THEN

            -- Get the most recent contact_initiator from the activity log records for this master_id
            -- This gives us the user_id of the PI making the Contact RA request
            select array_agg(user_id)
            into to_user_ids
            from
            (select user_id
            from activity_log_persnet_assignments
            where
              master_id = NEW.master_id
              and extra_log_type = 'contact_initiator'
            order by id desc
            limit 1) t;

            -- If nobody was set, send to all users in the PI role
            IF to_user_ids IS NULL THEN
              to_user_ids := get_user_ids_for_app_type_role(current_app_type_id, 'pi');
            END IF;


            SELECT
            INTO message_id
              create_message_notification_email(
                current_app_type_id,
                NEW.master_id,
                NEW.id,
                'ActivityLog::PersnetAssignment'::VARCHAR,
                NEW.user_id,
                to_user_ids,
                'persnet notification layout'::VARCHAR,
                'persnet message notification content'::VARCHAR,
                'Personal Networks contact from RA'::VARCHAR,
                now()::TIMESTAMP
              );

            RETURN NEW;
        END IF;

        -- If this is a primary type (info request), and there are already
        -- info request activities for this master
        -- then send another info request notification
        -- Don't do this otherwise, since the sync process is responsible for notifications
        -- related to the initial info request only when the sync has completed
        IF NEW.extra_log_type = 'primary' THEN
          SELECT count(id)
          INTO num_primary_logs
          FROM activity_log_persnet_assignments
          WHERE master_id = NEW.master_id AND id <> NEW.id AND extra_log_type = 'primary';

          IF num_primary_logs > 0 THEN
            PERFORM activity_log_persnet_assignment_info_request_notification(NEW.id);
          END IF;
        END IF;


        RETURN NEW;
    END;
$$;

CREATE TRIGGER activity_log_persnet_assignment_insert_notification AFTER INSERT ON activity_log_persnet_assignments FOR EACH ROW EXECUTE PROCEDURE activity_log_persnet_assignment_insert_notification();
