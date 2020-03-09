SET search_path = ipa_ops, ml_app;

BEGIN;



CREATE OR REPLACE FUNCTION log_ipa_ps_initial_screening_update() RETURNS trigger
LANGUAGE plpgsql
AS $$
    BEGIN
        INSERT INTO ipa_ps_initial_screening_history
        (
            master_id,
            select_is_good_time_to_speak,
            looked_at_website_yes_no,
            select_may_i_begin,
            any_questions_blank_yes_no,
            --- Note we retain select_still_interested since it is used in the withdrawal logic
            select_still_interested,
            follow_up_date,
            follow_up_time,
            notes,
            form_version,
            same_hotel_yes_no,
            select_schedule,
            user_id,
            created_at,
            updated_at,
            ipa_ps_initial_screening_id
            )
        SELECT
            NEW.master_id,
            NEW.select_is_good_time_to_speak,
            NEW.looked_at_website_yes_no,
            NEW.select_may_i_begin,
            NEW.any_questions_blank_yes_no,
            NEW.select_still_interested,
            NEW.follow_up_date,
            NEW.follow_up_time,
            NEW.notes,
            NEW.form_version,
            NEW.same_hotel_yes_no,
            NEW.select_schedule,
            NEW.user_id,
            NEW.created_at,
            NEW.updated_at,
            NEW.id
        ;
        RETURN NEW;
    END;
$$;


ALTER TABLE ipa_ps_initial_screening_history
ADD COLUMN form_version VARCHAR,
ADD COLUMN same_hotel_yes_no VARCHAR,
ADD COLUMN select_schedule VARCHAR
;


ALTER TABLE ipa_ps_initial_screenings
ADD COLUMN form_version VARCHAR,
ADD COLUMN same_hotel_yes_no VARCHAR,
ADD COLUMN select_schedule VARCHAR
;


COMMIT;