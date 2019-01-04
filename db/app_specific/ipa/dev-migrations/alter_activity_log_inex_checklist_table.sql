set search_path=ipa_ops;
      BEGIN;

-- Command line:
-- db/table_generators/generate.sh activity_logs_table create activity_log_ipa_assignment_inex_checklists ipa_assignments prev_activity_type signed_no_yes

      ALTER TABLE activity_log_ipa_assignment_inex_checklist_history
        RENAME COLUMN ready_for_review_no_yes TO prev_activity_type 
      ;
      ALTER TABLE activity_log_ipa_assignment_inex_checklists
        RENAME COLUMN ready_for_review_no_yes TO prev_activity_type
      ;

      CREATE or REPLACE FUNCTION log_activity_log_ipa_assignment_inex_checklist_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_inex_checklist_history
                  (
                      master_id,
                      ipa_assignment_id,
                      prev_activity_type,
                      select_subject_eligibility,
                      signed_no_yes,
                      notes,
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
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      COMMIT;
