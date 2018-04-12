INSERT INTO users (email, disabled, created_at, updated_at) values ('dl-fphs-elaine-bhs-pis@listserv.med.harvard.edu', false, now(), now());

/* Simple support function to get app_type.id using a name */
CREATE FUNCTION get_app_type_id_by_name(app_type_name VARCHAR) RETURNS INTEGER
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


/*

  Create a message notification and send it to the distribution list
  Run by the BHS sync scripts after a successful insert of Zeus player data into skeleton Elaine BHS subject record

*/
CREATE FUNCTION activity_log_bhs_assignment_info_request_notification(activity_id INTEGER) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
    DECLARE
        dl_user RECORD;
        activity_record RECORD;
        message_id INTEGER;
    BEGIN

        select id from users
        into dl_user
        where email = 'dl-fphs-elaine-bhs-pis@listserv.med.harvard.edu'
        limit 1;

        SELECT * INTO activity_record FROM activity_log_bhs_assignments WHERE id = activity_id;

        IF activity_record.bhs_assignment_id IS NOT NULL AND activity_record.extra_log_type = 'primary'
        THEN

          SELECT
          INTO message_id
            create_message_notification_email(
              get_app_type_id_by_name('bhs'),
              activity_record.master_id,
              activity_record.id,
              'ActivityLog::BhsAssignment',
              activity_record.user_id,
              ARRAY[dl_user.id],
              'bhs pi notification layout',
              'bhs pi notification content',
              'New Brain Health Study Info Request'
            )
          ;

        END IF;
        RETURN message_id;
    END;
$$;


/*

  Handle immediate notifications based on new BHS activity log records being created.
  Run from a trigger on insert into activity_log_bhs_assignments table

*/
CREATE FUNCTION activity_log_bhs_assignment_insert_notification() RETURNS trigger
LANGUAGE plpgsql
AS $$
    DECLARE
      responding_to RECORD;
      message_id INTEGER;
    BEGIN

        IF NEW.extra_log_type = 'contact_initiator' THEN

            -- Get the most recent info request from the activity log records for this master_id
            -- This gives us the user_id of the initiator of the request
            select * from activity_log_bhs_assignments
            into responding_to
            where
              master_id = NEW.master_id
              and extra_log_type = 'primary'
            order by id desc
            limit 1;

            SELECT
            INTO message_id
              create_message_notification_email(
                get_app_type_id_by_name('bhs'),
                NEW.master_id,
                NEW.id,
                'ActivityLog::BhsAssignment',
                NEW.user_id,
                ARRAY[responding_to.user_id],
                'bhs pi notification layout',
                'bhs message notification content',
                'Brain Health Study contact from PI'
              )
            ;

            RETURN NEW;
        END IF;

        IF NEW.extra_log_type = 'respond_to_pi' THEN

            -- Get the most recent contact_initiator from the activity log records for this master_id
            -- This gives us the user_id of the PI making the Contact RA request
            select * from activity_log_bhs_assignments
            into responding_to
            where
              master_id = NEW.master_id
              and extra_log_type = 'contact_initiator'
            order by id desc
            limit 1;

            SELECT
            INTO message_id
              create_message_notification_email(
                get_app_type_id_by_name('bhs'),
                NEW.master_id,
                NEW.id,
                'ActivityLog::BhsAssignment',
                NEW.user_id,
                ARRAY[responding_to.user_id],
                'bhs pi notification layout',
                'bhs message notification content',
                'Brain Health Study contact from RA'
              );

            RETURN NEW;
        END IF;

        RETURN NEW;
    END;
$$;

CREATE TRIGGER activity_log_bhs_assignment_history_insert_notification AFTER INSERT ON activity_log_bhs_assignments FOR EACH ROW EXECUTE PROCEDURE activity_log_bhs_assignment_insert_notification();
