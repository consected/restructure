set search_path=sleep, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh activity_logs_table create activity_log_sleep_assignment_phone_screen2s sleep_assignment

      CREATE TABLE activity_log_sleep_assignment_phone_screen2_history (
          id integer NOT NULL,
          master_id integer,
          sleep_assignment_id integer,

          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_sleep_assignment_phone_screen2_id integer
      );
      CREATE TABLE activity_log_sleep_assignment_phone_screen2s (
          id integer NOT NULL,
          master_id integer,
          sleep_assignment_id integer,

          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE FUNCTION log_activity_log_sleep_assignment_phone_screen2_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_sleep_assignment_phone_screen2_history
                  (
                      master_id,
                      sleep_assignment_id,

                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_sleep_assignment_phone_screen2_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.sleep_assignment_id,

                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE SEQUENCE activity_log_sleep_assignment_phone_screen2_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_sleep_assignment_phone_screen2_history_id_seq OWNED BY activity_log_sleep_assignment_phone_screen2_history.id;


      CREATE SEQUENCE activity_log_sleep_assignment_phone_screen2s_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_sleep_assignment_phone_screen2s_id_seq OWNED BY activity_log_sleep_assignment_phone_screen2s.id;

      ALTER TABLE ONLY activity_log_sleep_assignment_phone_screen2s ALTER COLUMN id SET DEFAULT nextval('activity_log_sleep_assignment_phone_screen2s_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_sleep_assignment_phone_screen2_history ALTER COLUMN id SET DEFAULT nextval('activity_log_sleep_assignment_phone_screen2_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_sleep_assignment_phone_screen2_history
          ADD CONSTRAINT activity_log_sleep_assignment_phone_screen2_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_sleep_assignment_phone_screen2s
          ADD CONSTRAINT activity_log_sleep_assignment_phone_screen2s_pkey PRIMARY KEY (id);

      CREATE INDEX index_al_sleep_assignment_phone_screen2_history_on_master_id ON activity_log_sleep_assignment_phone_screen2_history USING btree (master_id);
      CREATE INDEX index_al_sleep_assignment_phone_screen2_history_on_sleep_assignment_phone_screen2_id ON activity_log_sleep_assignment_phone_screen2_history USING btree (sleep_assignment_id);

      CREATE INDEX index_al_sleep_assignment_phone_screen2_history_on_activity_log_sleep_assignment_phone_screen2_id ON activity_log_sleep_assignment_phone_screen2_history USING btree (activity_log_sleep_assignment_phone_screen2_id);
      CREATE INDEX index_al_sleep_assignment_phone_screen2_history_on_user_id ON activity_log_sleep_assignment_phone_screen2_history USING btree (user_id);

      CREATE INDEX index_activity_log_sleep_assignment_phone_screen2s_on_master_id ON activity_log_sleep_assignment_phone_screen2s USING btree (master_id);
      CREATE INDEX index_activity_log_sleep_assignment_phone_screen2s_on_sleep_assignment_phone_screen2_id ON activity_log_sleep_assignment_phone_screen2s USING btree (sleep_assignment_id);
      CREATE INDEX index_activity_log_sleep_assignment_phone_screen2s_on_user_id ON activity_log_sleep_assignment_phone_screen2s USING btree (user_id);

      CREATE TRIGGER activity_log_sleep_assignment_phone_screen2_history_insert AFTER INSERT ON activity_log_sleep_assignment_phone_screen2s FOR EACH ROW EXECUTE PROCEDURE log_activity_log_sleep_assignment_phone_screen2_update();
      CREATE TRIGGER activity_log_sleep_assignment_phone_screen2_history_update AFTER UPDATE ON activity_log_sleep_assignment_phone_screen2s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_sleep_assignment_phone_screen2_update();


      ALTER TABLE ONLY activity_log_sleep_assignment_phone_screen2s
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_sleep_assignment_phone_screen2s
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_sleep_assignment_phone_screen2s
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (sleep_assignment_id) REFERENCES sleep_assignments(id);

      ALTER TABLE ONLY activity_log_sleep_assignment_phone_screen2_history
          ADD CONSTRAINT fk_activity_log_sleep_assignment_phone_screen2_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_sleep_assignment_phone_screen2_history
          ADD CONSTRAINT fk_activity_log_sleep_assignment_phone_screen2_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_sleep_assignment_phone_screen2_history
          ADD CONSTRAINT fk_activity_log_sleep_assignment_phone_screen2_history_sleep_assignment_phone_screen2_id FOREIGN KEY (sleep_assignment_id) REFERENCES sleep_assignments(id);

      ALTER TABLE ONLY activity_log_sleep_assignment_phone_screen2_history
          ADD CONSTRAINT fk_activity_log_sleep_assignment_phone_screen2_history_activity_log_sleep_assignment_phone_screen2s FOREIGN KEY (activity_log_sleep_assignment_phone_screen2_id) REFERENCES activity_log_sleep_assignment_phone_screen2s(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA sleep TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA sleep TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA sleep TO fphs;

      COMMIT;
