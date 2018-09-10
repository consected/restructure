SET SEARCH_PATH=persnet_schema,ml_app;

      BEGIN;

      CREATE FUNCTION log_persnet_assignment_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO persnet_assignment_history
                  (
                      master_id,
                      persnet_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      persnet_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.persnet_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;
      CREATE TABLE persnet_assignment_history (
          id integer NOT NULL,
          master_id integer,
          persnet_id bigint,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          persnet_assignment_table_id integer
      );

      CREATE SEQUENCE persnet_assignment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE persnet_assignment_history_id_seq OWNED BY persnet_assignment_history.id;

      CREATE TABLE persnet_assignments (
          id integer NOT NULL,
          master_id integer,
          persnet_id bigint,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE persnet_assignments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE persnet_assignments_id_seq OWNED BY persnet_assignments.id;

      ALTER TABLE ONLY persnet_assignments ALTER COLUMN id SET DEFAULT nextval('persnet_assignments_id_seq'::regclass);
      ALTER TABLE ONLY persnet_assignment_history ALTER COLUMN id SET DEFAULT nextval('persnet_assignment_history_id_seq'::regclass);

      ALTER TABLE ONLY persnet_assignment_history
          ADD CONSTRAINT persnet_assignment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY persnet_assignments
          ADD CONSTRAINT persnet_assignments_pkey PRIMARY KEY (id);

      CREATE INDEX index_persnet_assignment_history_on_master_id ON persnet_assignment_history USING btree (master_id);
      CREATE INDEX index_persnet_assignment_history_on_persnet_assignment_table_id ON persnet_assignment_history USING btree (persnet_assignment_table_id);
      CREATE INDEX index_persnet_assignment_history_on_user_id ON persnet_assignment_history USING btree (user_id);
      CREATE INDEX index_persnet_assignment_history_on_admin_id ON persnet_assignment_history USING btree (admin_id);

      CREATE INDEX index_persnet_assignments_on_master_id ON persnet_assignments USING btree (master_id);
      CREATE INDEX index_persnet_assignments_on_user_id ON persnet_assignments USING btree (user_id);
      CREATE INDEX index_persnet_assignments_on_admin_id ON persnet_assignments USING btree (admin_id);

      CREATE TRIGGER persnet_assignment_history_insert AFTER INSERT ON persnet_assignments FOR EACH ROW EXECUTE PROCEDURE log_persnet_assignment_update();
      CREATE TRIGGER persnet_assignment_history_update AFTER UPDATE ON persnet_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_persnet_assignment_update();


      ALTER TABLE ONLY persnet_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY persnet_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY persnet_assignments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


      ALTER TABLE ONLY persnet_assignment_history
          ADD CONSTRAINT fk_persnet_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY persnet_assignment_history
          ADD CONSTRAINT fk_persnet_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY persnet_assignment_history
          ADD CONSTRAINT fk_persnet_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY persnet_assignment_history
          ADD CONSTRAINT fk_persnet_assignment_history_persnet_assignments FOREIGN KEY (persnet_assignment_table_id) REFERENCES persnet_assignments(id);


      COMMIT;
