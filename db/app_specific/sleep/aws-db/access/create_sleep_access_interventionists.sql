set search_path=sleep, ml_app;
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_access_interventionists assign_access_to_user_id

      CREATE FUNCTION log_sleep_access_interventionist_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_access_interventionist_history
                  (
                      master_id,
                      assign_access_to_user_id,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_access_interventionist_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.assign_access_to_user_id,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_access_interventionist_history (
          id integer NOT NULL,
          master_id integer,
          assign_access_to_user_id bigint,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_access_interventionist_id integer
      );

      CREATE SEQUENCE sleep_access_interventionist_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_access_interventionist_history_id_seq OWNED BY sleep_access_interventionist_history.id;

      CREATE TABLE sleep_access_interventionists (
          id integer NOT NULL,
          master_id integer,
          assign_access_to_user_id bigint,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_access_interventionists_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_access_interventionists_id_seq OWNED BY sleep_access_interventionists.id;

      ALTER TABLE ONLY sleep_access_interventionists ALTER COLUMN id SET DEFAULT nextval('sleep_access_interventionists_id_seq'::regclass);
      ALTER TABLE ONLY sleep_access_interventionist_history ALTER COLUMN id SET DEFAULT nextval('sleep_access_interventionist_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_access_interventionist_history
          ADD CONSTRAINT sleep_access_interventionist_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_access_interventionists
          ADD CONSTRAINT sleep_access_interventionists_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_access_interventionist_history_on_master_id ON sleep_access_interventionist_history USING btree (master_id);


      CREATE INDEX index_sleep_access_interventionist_history_on_sleep_access_interventionist_id ON sleep_access_interventionist_history USING btree (sleep_access_interventionist_id);
      CREATE INDEX index_sleep_access_interventionist_history_on_user_id ON sleep_access_interventionist_history USING btree (user_id);

      CREATE INDEX index_sleep_access_interventionists_on_master_id ON sleep_access_interventionists USING btree (master_id);

      CREATE INDEX index_sleep_access_interventionists_on_user_id ON sleep_access_interventionists USING btree (user_id);

      CREATE TRIGGER sleep_access_interventionist_history_insert AFTER INSERT ON sleep_access_interventionists FOR EACH ROW EXECUTE PROCEDURE log_sleep_access_interventionist_update();
      CREATE TRIGGER sleep_access_interventionist_history_update AFTER UPDATE ON sleep_access_interventionists FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_access_interventionist_update();


      ALTER TABLE ONLY sleep_access_interventionists
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_access_interventionists
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_access_interventionist_history
          ADD CONSTRAINT fk_sleep_access_interventionist_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_access_interventionist_history
          ADD CONSTRAINT fk_sleep_access_interventionist_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_access_interventionist_history
          ADD CONSTRAINT fk_sleep_access_interventionist_history_sleep_access_interventionists FOREIGN KEY (sleep_access_interventionist_id) REFERENCES sleep_access_interventionists(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
