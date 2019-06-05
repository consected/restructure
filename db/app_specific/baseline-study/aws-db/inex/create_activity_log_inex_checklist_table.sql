
      BEGIN;

-- Command line:
-- db/table_generators/generate.sh activity_logs_table create activity_log_ipa_assignment_inex_checklists ipa_assignments prev_activity_type signed_no_yes

      CREATE TABLE activity_log_ipa_assignment_inex_checklist_history (
          id integer NOT NULL,
          master_id integer,
          ipa_assignment_id integer,
          prev_activity_type varchar,
          contact_role varchar,
          select_subject_eligibility varchar,
          signed_no_yes varchar,
          notes varchar,
          e_signed_document varchar,
          e_signed_how varchar,
          e_signed_at varchar,
          e_signed_by varchar,
          e_signed_code varchar,
          e_signed_status varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_ipa_assignment_inex_checklist_id integer
      );
      CREATE TABLE activity_log_ipa_assignment_inex_checklists (
          id integer NOT NULL,
          master_id integer,
          ipa_assignment_id integer,
          prev_activity_type varchar,
          contact_role varchar,
          select_subject_eligibility varchar,
          signed_no_yes varchar,
          notes varchar,
          e_signed_document varchar,
          e_signed_how varchar,
          e_signed_at varchar,
          e_signed_by varchar,
          e_signed_code varchar,
          e_signed_status varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

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
          $$;

      CREATE SEQUENCE activity_log_ipa_assignment_inex_checklist_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_assignment_inex_checklist_history_id_seq OWNED BY activity_log_ipa_assignment_inex_checklist_history.id;


      CREATE SEQUENCE activity_log_ipa_assignment_inex_checklists_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_assignment_inex_checklists_id_seq OWNED BY activity_log_ipa_assignment_inex_checklists.id;

      ALTER TABLE ONLY activity_log_ipa_assignment_inex_checklists ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignment_inex_checklists_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_ipa_assignment_inex_checklist_history ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignment_inex_checklist_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_ipa_assignment_inex_checklist_history
          ADD CONSTRAINT activity_log_ipa_assignment_inex_checklist_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_ipa_assignment_inex_checklists
          ADD CONSTRAINT activity_log_ipa_assignment_inex_checklists_pkey PRIMARY KEY (id);

      CREATE INDEX index_activity_log_ipa_assignment_inex_checklist_history_on_master_id ON activity_log_ipa_assignment_inex_checklist_history USING btree (master_id);
      CREATE INDEX index_activity_log_ipa_assignment_inex_checklist_history_on_ipa_assignment_inex_checklist_id ON activity_log_ipa_assignment_inex_checklist_history USING btree (ipa_assignment_id);

      CREATE INDEX index_activity_log_ipa_assignment_inex_checklist_history_on_activity_log_ipa_assignment_inex_checklist_id ON activity_log_ipa_assignment_inex_checklist_history USING btree (activity_log_ipa_assignment_inex_checklist_id);
      CREATE INDEX index_activity_log_ipa_assignment_inex_checklist_history_on_user_id ON activity_log_ipa_assignment_inex_checklist_history USING btree (user_id);

      CREATE INDEX index_activity_log_ipa_assignment_inex_checklists_on_master_id ON activity_log_ipa_assignment_inex_checklists USING btree (master_id);
      CREATE INDEX index_activity_log_ipa_assignment_inex_checklists_on_ipa_assignment_inex_checklist_id ON activity_log_ipa_assignment_inex_checklists USING btree (ipa_assignment_id);
      CREATE INDEX index_activity_log_ipa_assignment_inex_checklists_on_user_id ON activity_log_ipa_assignment_inex_checklists USING btree (user_id);

      CREATE TRIGGER activity_log_ipa_assignment_inex_checklist_history_insert AFTER INSERT ON activity_log_ipa_assignment_inex_checklists FOR EACH ROW EXECUTE PROCEDURE log_activity_log_ipa_assignment_inex_checklist_update();
      CREATE TRIGGER activity_log_ipa_assignment_inex_checklist_history_update AFTER UPDATE ON activity_log_ipa_assignment_inex_checklists FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_ipa_assignment_inex_checklist_update();


      ALTER TABLE ONLY activity_log_ipa_assignment_inex_checklists
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_ipa_assignment_inex_checklists
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_ipa_assignment_inex_checklists
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_inex_checklist_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_inex_checklist_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_inex_checklist_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_inex_checklist_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_inex_checklist_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_inex_checklist_history_ipa_assignment_inex_checklist_id FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_inex_checklist_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_inex_checklist_history_activity_log_ipa_assignment_inex_checklists FOREIGN KEY (activity_log_ipa_assignment_inex_checklist_id) REFERENCES activity_log_ipa_assignment_inex_checklists(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
