set search_path=ipa_ops, ml_app;

CREATE OR REPLACE FUNCTION log_ipa_appointment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO ipa_appointment_history
            (
                master_id,
                visit_start_date,
                visit_end_date,
                select_status,
                notes,
                user_id,
                created_at,
                updated_at,
                ipa_appointment_id
                )
            SELECT
                NEW.master_id,
                NEW.visit_start_date,
                NEW.visit_end_date,
                NEW.select_status,
                NEW.notes,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


alter table ipa_appointment_history
  add column visit_end_date date,
  add column select_status varchar,
  add column notes varchar,
  drop column select_navigator;

alter table ipa_appointments
  add column visit_end_date date,
  add column select_status varchar,
  add column notes varchar,
  drop column select_navigator;
