
      BEGIN;

-- Command line:
-- table_generators/generate.sh create external_identifiers_table

      CREATE FUNCTION log_sleep_assignment_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_assignment_history
                  (
                      master_id,
                      sleep_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      sleep_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.sleep_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;
      CREATE TABLE sleep_assignment_history (
          id integer NOT NULL,
          master_id integer,
          sleep_id bigint,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_assignment_table_id integer
      );

      CREATE SEQUENCE sleep_assignment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_assignment_history_id_seq OWNED BY sleep_assignment_history.id;

      CREATE TABLE sleep_assignments (
          id integer NOT NULL,
          master_id integer,
          sleep_id bigint,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_assignments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_assignments_id_seq OWNED BY sleep_assignments.id;

      ALTER TABLE ONLY sleep_assignments ALTER COLUMN id SET DEFAULT nextval('sleep_assignments_id_seq'::regclass);
      ALTER TABLE ONLY sleep_assignment_history ALTER COLUMN id SET DEFAULT nextval('sleep_assignment_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_assignment_history
          ADD CONSTRAINT sleep_assignment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_assignments
          ADD CONSTRAINT sleep_assignments_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_assignment_history_on_master_id ON sleep_assignment_history USING btree (master_id);
      CREATE INDEX index_sleep_assignment_history_on_sleep_assignment_table_id ON sleep_assignment_history USING btree (sleep_assignment_table_id);
      CREATE INDEX index_sleep_assignment_history_on_user_id ON sleep_assignment_history USING btree (user_id);
      CREATE INDEX index_sleep_assignment_history_on_admin_id ON sleep_assignment_history USING btree (admin_id);

      CREATE INDEX index_sleep_assignments_on_master_id ON sleep_assignments USING btree (master_id);
      CREATE INDEX index_sleep_assignments_on_user_id ON sleep_assignments USING btree (user_id);
      CREATE INDEX index_sleep_assignments_on_admin_id ON sleep_assignments USING btree (admin_id);

      CREATE TRIGGER sleep_assignment_history_insert AFTER INSERT ON sleep_assignments FOR EACH ROW EXECUTE PROCEDURE log_sleep_assignment_update();
      CREATE TRIGGER sleep_assignment_history_update AFTER UPDATE ON sleep_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_assignment_update();


      ALTER TABLE ONLY sleep_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY sleep_assignments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


      ALTER TABLE ONLY sleep_assignment_history
          ADD CONSTRAINT fk_sleep_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_assignment_history
          ADD CONSTRAINT fk_sleep_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY sleep_assignment_history
          ADD CONSTRAINT fk_sleep_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY sleep_assignment_history
          ADD CONSTRAINT fk_sleep_assignment_history_sleep_assignments FOREIGN KEY (sleep_assignment_table_id) REFERENCES sleep_assignments(id);


      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
