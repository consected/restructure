SET SEARCH_PATH={{app_schema}},ml_app;

      BEGIN;

      CREATE FUNCTION log_{{app_name}}_assignment_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO {{app_name}}_assignment_history
                  (
                      master_id,
                      {{app_name}}_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      {{app_name}}_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.{{app_name}}_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;
      CREATE TABLE {{app_name}}_assignment_history (
          id integer NOT NULL,
          master_id integer,
          {{app_name}}_id bigint,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          {{app_name}}_assignment_table_id integer
      );

      CREATE SEQUENCE {{app_name}}_assignment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE {{app_name}}_assignment_history_id_seq OWNED BY {{app_name}}_assignment_history.id;

      CREATE TABLE {{app_name}}_assignments (
          id integer NOT NULL,
          master_id integer,
          {{app_name}}_id bigint,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE {{app_name}}_assignments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE {{app_name}}_assignments_id_seq OWNED BY {{app_name}}_assignments.id;

      ALTER TABLE ONLY {{app_name}}_assignments ALTER COLUMN id SET DEFAULT nextval('{{app_name}}_assignments_id_seq'::regclass);
      ALTER TABLE ONLY {{app_name}}_assignment_history ALTER COLUMN id SET DEFAULT nextval('{{app_name}}_assignment_history_id_seq'::regclass);

      ALTER TABLE ONLY {{app_name}}_assignment_history
          ADD CONSTRAINT {{app_name}}_assignment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY {{app_name}}_assignments
          ADD CONSTRAINT {{app_name}}_assignments_pkey PRIMARY KEY (id);

      CREATE INDEX index_{{app_name}}_assignment_history_on_master_id ON {{app_name}}_assignment_history USING btree (master_id);
      CREATE INDEX index_{{app_name}}_assignment_history_on_{{app_name}}_assignment_table_id ON {{app_name}}_assignment_history USING btree ({{app_name}}_assignment_table_id);
      CREATE INDEX index_{{app_name}}_assignment_history_on_user_id ON {{app_name}}_assignment_history USING btree (user_id);
      CREATE INDEX index_{{app_name}}_assignment_history_on_admin_id ON {{app_name}}_assignment_history USING btree (admin_id);

      CREATE INDEX index_{{app_name}}_assignments_on_master_id ON {{app_name}}_assignments USING btree (master_id);
      CREATE INDEX index_{{app_name}}_assignments_on_user_id ON {{app_name}}_assignments USING btree (user_id);
      CREATE INDEX index_{{app_name}}_assignments_on_admin_id ON {{app_name}}_assignments USING btree (admin_id);

      CREATE TRIGGER {{app_name}}_assignment_history_insert AFTER INSERT ON {{app_name}}_assignments FOR EACH ROW EXECUTE PROCEDURE log_{{app_name}}_assignment_update();
      CREATE TRIGGER {{app_name}}_assignment_history_update AFTER UPDATE ON {{app_name}}_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_{{app_name}}_assignment_update();


      ALTER TABLE ONLY {{app_name}}_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY {{app_name}}_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY {{app_name}}_assignments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


      ALTER TABLE ONLY {{app_name}}_assignment_history
          ADD CONSTRAINT fk_{{app_name}}_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY {{app_name}}_assignment_history
          ADD CONSTRAINT fk_{{app_name}}_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY {{app_name}}_assignment_history
          ADD CONSTRAINT fk_{{app_name}}_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY {{app_name}}_assignment_history
          ADD CONSTRAINT fk_{{app_name}}_assignment_history_{{app_name}}_assignments FOREIGN KEY ({{app_name}}_assignment_table_id) REFERENCES {{app_name}}_assignments(id);


      COMMIT;
