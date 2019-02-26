SET search_path=ipa_ops, ml_app;
BEGIN;

CREATE OR REPLACE FUNCTION log_ipa_ps_mri_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO ipa_ps_mri_history
            (
                master_id,
                past_mri_yes_no_dont_know,
                past_mri_details,
                electrical_implants_blank_yes_no_dont_know,
                electrical_implants_details,
                metal_implants_blank_yes_no_dont_know,
                metal_implants_details,
                metal_jewelry_blank_yes_no,
                hearing_aid_blank_yes_no,
                radiation_blank_yes_no,
                radiation_details,
                user_id,
                created_at,
                updated_at,
                ipa_ps_mri_id
                )
            SELECT
                NEW.master_id,
                NEW.past_mri_yes_no_dont_know,
                NEW.past_mri_details,
                NEW.electrical_implants_blank_yes_no_dont_know,
                NEW.electrical_implants_details,
                NEW.metal_implants_blank_yes_no_dont_know,
                NEW.metal_implants_details,
                NEW.metal_jewelry_blank_yes_no,
                NEW.hearing_aid_blank_yes_no,
                NEW.radiation_blank_yes_no,
                NEW.radiation_details,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

    ALTER TABLE ipa_ps_mri_history
    ADD COLUMN radiation_blank_yes_no varchar,
    ADD COLUMN radiation_details varchar;

    ALTER TABLE ipa_ps_mris
    ADD COLUMN radiation_blank_yes_no varchar,
    ADD COLUMN radiation_details varchar;


END;
