set search_path=ipa_ops, ml_app;


      alter TABLE activity_log_ipa_assignment_discussion_history
          add column created_by_user_id integer;

      alter TABLE activity_log_ipa_assignment_discussions 
          add column created_by_user_id integer;
          

      CREATE OR REPLACE FUNCTION log_activity_log_ipa_assignment_discussion_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_discussion_history
                  (
                      master_id,
                      ipa_assignment_id,
                      tag_select_contact_role,
                      notes,
                      prev_activity_type,
                      extra_log_type,
                      user_id,
                      created_by_user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_discussion_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.tag_select_contact_role,
                      NEW.notes,
                      NEW.prev_activity_type,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_by_user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;


      ALTER TABLE ONLY activity_log_ipa_assignment_discussions
          ADD CONSTRAINT fk_rails_cb1a7e2b01e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_discussion_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_discussion_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);
