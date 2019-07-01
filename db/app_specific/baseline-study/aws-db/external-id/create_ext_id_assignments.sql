
      BEGIN;

-- Command line:
-- table_generators/generate.sh create external_identifiers_table

      CREATE FUNCTION log_${target_name_us}_assignment_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ${target_name_us}_assignment_history
                  (
                      master_id,
                      ${target_name_us}_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      ${target_name_us}_assignment_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.${target_name_us}_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;
      CREATE TABLE ${target_name_us}_assignment_history (
          id integer NOT NULL,
          master_id integer,
          ${target_name_us}_id bigint,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ${target_name_us}_assignment_table_id integer
      );

      CREATE SEQUENCE ${target_name_us}_assignment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_assignment_history_id_seq OWNED BY ${target_name_us}_assignment_history.id;

      CREATE TABLE ${target_name_us}_assignments (
          id integer NOT NULL,
          master_id integer,
          ${target_name_us}_id bigint,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ${target_name_us}_assignments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_assignments_id_seq OWNED BY ${target_name_us}_assignments.id;

      ALTER TABLE ONLY ${target_name_us}_assignments ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_assignments_id_seq'::regclass);
      ALTER TABLE ONLY ${target_name_us}_assignment_history ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_assignment_history_id_seq'::regclass);

      ALTER TABLE ONLY ${target_name_us}_assignment_history
          ADD CONSTRAINT ${target_name_us}_assignment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ${target_name_us}_assignments
          ADD CONSTRAINT ${target_name_us}_assignments_pkey PRIMARY KEY (id);

      CREATE INDEX index_${target_name_us}_assignment_history_on_master_id ON ${target_name_us}_assignment_history USING btree (master_id);
      CREATE INDEX index_${target_name_us}_assignment_history_on_${target_name_us}_assignment_table_id ON ${target_name_us}_assignment_history USING btree (${target_name_us}_assignment_table_id);
      CREATE INDEX index_${target_name_us}_assignment_history_on_user_id ON ${target_name_us}_assignment_history USING btree (user_id);
      CREATE INDEX index_${target_name_us}_assignment_history_on_admin_id ON ${target_name_us}_assignment_history USING btree (admin_id);

      CREATE INDEX index_${target_name_us}_assignments_on_master_id ON ${target_name_us}_assignments USING btree (master_id);
      CREATE INDEX index_${target_name_us}_assignments_on_user_id ON ${target_name_us}_assignments USING btree (user_id);
      CREATE INDEX index_${target_name_us}_assignments_on_admin_id ON ${target_name_us}_assignments USING btree (admin_id);

      CREATE TRIGGER ${target_name_us}_assignment_history_insert AFTER INSERT ON ${target_name_us}_assignments FOR EACH ROW EXECUTE PROCEDURE log_${target_name_us}_assignment_update();
      CREATE TRIGGER ${target_name_us}_assignment_history_update AFTER UPDATE ON ${target_name_us}_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_${target_name_us}_assignment_update();


      ALTER TABLE ONLY ${target_name_us}_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY ${target_name_us}_assignments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


      ALTER TABLE ONLY ${target_name_us}_assignment_history
          ADD CONSTRAINT fk_${target_name_us}_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_assignment_history
          ADD CONSTRAINT fk_${target_name_us}_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY ${target_name_us}_assignment_history
          ADD CONSTRAINT fk_${target_name_us}_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY ${target_name_us}_assignment_history
          ADD CONSTRAINT fk_${target_name_us}_assignment_history_${target_name_us}_assignments FOREIGN KEY (${target_name_us}_assignment_table_id) REFERENCES ${target_name_us}_assignments(id);


      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
