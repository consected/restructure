set search_path=ipa_ops, ml_app;
      BEGIN;

-- Command line:
-- table_generators/generate.sh create external_identifiers_table

      CREATE FUNCTION log_ipa_assignment_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_assignment_history
                  (
                      master_id,
                      ipa_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      ipa_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;
      CREATE TABLE ipa_assignment_history (
          id integer NOT NULL,
          master_id integer,
          ipa_id bigint,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_assignment_table_id integer
      );

      CREATE SEQUENCE ipa_assignment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_assignment_history_id_seq OWNED BY ipa_assignment_history.id;

      CREATE TABLE ipa_assignments (
          id integer NOT NULL,
          master_id integer,
          ipa_id bigint,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_assignments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_assignments_id_seq OWNED BY ipa_assignments.id;

      ALTER TABLE ONLY ipa_assignments ALTER COLUMN id SET DEFAULT nextval('ipa_assignments_id_seq'::regclass);
      ALTER TABLE ONLY ipa_assignment_history ALTER COLUMN id SET DEFAULT nextval('ipa_assignment_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_assignment_history
          ADD CONSTRAINT ipa_assignment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_assignments
          ADD CONSTRAINT ipa_assignments_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_assignment_history_on_master_id ON ipa_assignment_history USING btree (master_id);
      CREATE INDEX index_ipa_assignment_history_on_ipa_assignment_table_id ON ipa_assignment_history USING btree (ipa_assignment_table_id);
      CREATE INDEX index_ipa_assignment_history_on_user_id ON ipa_assignment_history USING btree (user_id);
      CREATE INDEX index_ipa_assignment_history_on_admin_id ON ipa_assignment_history USING btree (admin_id);

      CREATE INDEX index_ipa_assignments_on_master_id ON ipa_assignments USING btree (master_id);
      CREATE INDEX index_ipa_assignments_on_user_id ON ipa_assignments USING btree (user_id);
      CREATE INDEX index_ipa_assignments_on_admin_id ON ipa_assignments USING btree (admin_id);

      CREATE TRIGGER ipa_assignment_history_insert AFTER INSERT ON ipa_assignments FOR EACH ROW EXECUTE PROCEDURE log_ipa_assignment_update();
      CREATE TRIGGER ipa_assignment_history_update AFTER UPDATE ON ipa_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_assignment_update();


      ALTER TABLE ONLY ipa_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY ipa_assignments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


      ALTER TABLE ONLY ipa_assignment_history
          ADD CONSTRAINT fk_ipa_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_assignment_history
          ADD CONSTRAINT fk_ipa_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY ipa_assignment_history
          ADD CONSTRAINT fk_ipa_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY ipa_assignment_history
          ADD CONSTRAINT fk_ipa_assignment_history_ipa_assignments FOREIGN KEY (ipa_assignment_table_id) REFERENCES ipa_assignments(id);


      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
