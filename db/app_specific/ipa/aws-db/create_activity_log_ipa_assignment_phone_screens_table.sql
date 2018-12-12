
      BEGIN;

-- Command line:
-- table_generators/generate.sh activity_logs_table create activity_log_ipa_assignment_phone_screens ipa_assignment callback_date callback_time notes

      CREATE TABLE activity_log_ipa_assignment_phone_screen_history (
          id integer NOT NULL,
          master_id integer,
          ipa_assignment_id integer,
          callback_required varchar,
          callback_date date,
          callback_time time,
          notes varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_ipa_assignment_phone_screen_id integer
      );
      CREATE TABLE activity_log_ipa_assignment_phone_screens (
          id integer NOT NULL,
          master_id integer,
          ipa_assignment_id integer,
          callback_required varchar,
          callback_date date,
          callback_time time,
          notes varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE FUNCTION log_activity_log_ipa_assignment_phone_screen_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_phone_screen_history
                  (
                      master_id,
                      ipa_assignment_id,
                      callback_required,
                      callback_date,
                      callback_time,
                      notes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_phone_screen_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.callback_required,
                      NEW.callback_date,
                      NEW.callback_time,
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

      CREATE SEQUENCE activity_log_ipa_assignment_phone_screen_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_assignment_phone_screen_history_id_seq OWNED BY activity_log_ipa_assignment_phone_screen_history.id;


      CREATE SEQUENCE activity_log_ipa_assignment_phone_screens_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_assignment_phone_screens_id_seq OWNED BY activity_log_ipa_assignment_phone_screens.id;

      ALTER TABLE ONLY activity_log_ipa_assignment_phone_screens ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignment_phone_screens_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_ipa_assignment_phone_screen_history ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignment_phone_screen_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_ipa_assignment_phone_screen_history
          ADD CONSTRAINT activity_log_ipa_assignment_phone_screen_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_ipa_assignment_phone_screens
          ADD CONSTRAINT activity_log_ipa_assignment_phone_screens_pkey PRIMARY KEY (id);

      CREATE INDEX index_activity_log_ipa_assignment_phone_screen_history_on_master_id ON activity_log_ipa_assignment_phone_screen_history USING btree (master_id);
      CREATE INDEX index_activity_log_ipa_assignment_phone_screen_history_on_ipa_assignment_phone_screen_id ON activity_log_ipa_assignment_phone_screen_history USING btree (ipa_assignment_id);

      CREATE INDEX index_activity_log_ipa_assignment_phone_screen_history_on_activity_log_ipa_assignment_phone_screen_id ON activity_log_ipa_assignment_phone_screen_history USING btree (activity_log_ipa_assignment_phone_screen_id);
      CREATE INDEX index_activity_log_ipa_assignment_phone_screen_history_on_user_id ON activity_log_ipa_assignment_phone_screen_history USING btree (user_id);

      CREATE INDEX index_activity_log_ipa_assignment_phone_screens_on_master_id ON activity_log_ipa_assignment_phone_screens USING btree (master_id);
      CREATE INDEX index_activity_log_ipa_assignment_phone_screens_on_ipa_assignment_phone_screen_id ON activity_log_ipa_assignment_phone_screens USING btree (ipa_assignment_id);
      CREATE INDEX index_activity_log_ipa_assignment_phone_screens_on_user_id ON activity_log_ipa_assignment_phone_screens USING btree (user_id);

      CREATE TRIGGER activity_log_ipa_assignment_phone_screen_history_insert AFTER INSERT ON activity_log_ipa_assignment_phone_screens FOR EACH ROW EXECUTE PROCEDURE log_activity_log_ipa_assignment_phone_screen_update();
      CREATE TRIGGER activity_log_ipa_assignment_phone_screen_history_update AFTER UPDATE ON activity_log_ipa_assignment_phone_screens FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_ipa_assignment_phone_screen_update();


      ALTER TABLE ONLY activity_log_ipa_assignment_phone_screens
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_ipa_assignment_phone_screens
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_ipa_assignment_phone_screens
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_phone_screen_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_phone_screen_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_phone_screen_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_phone_screen_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_phone_screen_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_phone_screen_history_ipa_assignment_phone_screen_id FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_phone_screen_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_phone_screen_history_activity_log_ipa_assignment_phone_screens FOREIGN KEY (activity_log_ipa_assignment_phone_screen_id) REFERENCES activity_log_ipa_assignment_phone_screens(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
