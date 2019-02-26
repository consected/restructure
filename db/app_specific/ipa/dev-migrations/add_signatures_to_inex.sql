SET search_path=ipa_ops, ml_app;

      BEGIN;

        CREATE OR REPLACE FUNCTION ipa_ops.log_activity_log_ipa_assignment_inex_checklist_update()
         RETURNS trigger
         LANGUAGE plpgsql
        AS $function$
                    BEGIN
                        INSERT INTO activity_log_ipa_assignment_inex_checklist_history
                        (
                            master_id,
                            ipa_assignment_id,
                            prev_activity_type,
                            select_subject_eligibility,
                            signed_no_yes,
                            notes,
                            contact_role,
                            e_signed_document,
                            e_signed_how,
                            e_signed_at,
                            e_signed_by,
                            e_signed_code,
                            e_signed_status,
                            extra_log_type,
                            user_id,
                            created_at,
                            updated_at,
                            activity_log_ipa_assignment_inex_checklist_id
                            )
                        SELECT
                            NEW.master_id,
                            NEW.ipa_assignment_id,
                            NEW.prev_activity_type,
                            NEW.select_subject_eligibility,
                            NEW.signed_no_yes,
                            NEW.notes,
                            NEW.contact_role,
                            NEW.e_signed_document,
                            NEW.e_signed_how,
                            NEW.e_signed_at,
                            NEW.e_signed_by,
                            NEW.e_signed_code,
                            NEW.e_signed_status,
                            NEW.extra_log_type,
                            NEW.user_id,
                            NEW.created_at,
                            NEW.updated_at,
                            NEW.id
                        ;
                        RETURN NEW;
                    END;
                $function$;


-- Command line:
-- table_generators/generate.sh activity_logs_table create activity_log_ipa_assignment_e_signs ipa_assignment e_signed_document e_signed_how e_signed_at e_signed_by e_signed_code placeholder_get_started e_signed_status placeholder_in_progress

      ALTER TABLE activity_log_ipa_assignment_inex_checklist_history
      ADD COLUMN e_signed_document varchar,
      ADD COLUMN e_signed_how varchar,
      ADD COLUMN e_signed_at varchar,
      ADD COLUMN e_signed_by varchar,
      ADD COLUMN e_signed_code varchar,
      ADD COLUMN e_signed_status varchar
      ;
      ALTER TABLE activity_log_ipa_assignment_inex_checklists
      ADD COLUMN e_signed_document varchar,
      ADD COLUMN e_signed_how varchar,
      ADD COLUMN e_signed_at varchar,
      ADD COLUMN e_signed_by varchar,
      ADD COLUMN e_signed_code varchar,
      ADD COLUMN e_signed_status varchar
      ;


      COMMIT;
