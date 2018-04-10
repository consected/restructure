/*

Create a message by specifying:

  layout and content templates
  subject
  JSON data for variable substitutions into the content template
  array of recipient emails
  address the email shows as being sent from
This creates a record in message_notifications table, then schedules a background job, returning an ID.
The ID represents the job in the table delayed_jobs

Example:

    SELECT create_message_notification_email(
      'test email layout',
      'test email content',
      'Test Subject',
      '{"data_item": 1234}',
      Array['test-person@test.test'],
      'phil@test.com'
    );

*/


CREATE OR REPLACE FUNCTION create_message_notification_job(message_notification_id INTEGER) returns INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  last_id INTEGER;
BEGIN

  INSERT INTO ml_app.delayed_jobs
  (
    priority,
    attempts,
    handler,
    run_at,
    queue,
    created_at,
    updated_at
  )
  VALUES
  (
    0,
    0,
    '--- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
    job_data:
      job_class: HandleMessageNotificationJob
      job_id: ' || gen_random_uuid() || '
      queue_name: default
      arguments:
      - _aj_globalid: gid://fpa1/MessageNotification/' || message_notification_id::varchar || '
      locale: :en',
    now(),
    'default',
    now(),
    now()
  )
  RETURNING id
  INTO last_id
  ;

	RETURN last_id;
END;
$$;

CREATE OR REPLACE FUNCTION create_message_notification_email(layout_template_name VARCHAR, content_template_name VARCHAR, subject VARCHAR,
                                                              data JSON, recipient_emails VARCHAR[], from_user_email VARCHAR)
    RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  last_id INTEGER;
BEGIN

  INSERT INTO ml_app.message_notifications
  (
    message_type,
    created_at,
    updated_at,
    layout_template_name,
    content_template_name,
    subject,
    data,
    recipient_emails,
    from_user_email
  )
  VALUES
  (
    'email',
    now(),
    now(),
    layout_template_name,
    content_template_name,
    subject,
    data,
    recipient_emails,
    from_user_email
  )
  RETURNING id
  INTO last_id
  ;

  SELECT create_message_notification_job(last_id)
  INTO last_id
  ;

  RETURN last_id;
END;
$$;
