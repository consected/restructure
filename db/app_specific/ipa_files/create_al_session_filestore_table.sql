
      BEGIN;

-- Command line:
-- table_generators/generate.sh activity_logs_table create activity_log_ipa_assignment_session_filestores ipa_assignment select_scanner operator notes session_date session_time

      CREATE TABLE activity_log_ipa_assignment_session_filestore_history (
          id integer NOT NULL,
          master_id integer,
          ipa_assignment_id integer,
          select_scanner varchar,
          operator varchar,
          notes varchar,
          session_date date,
          session_time time,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_ipa_assignment_session_filestore_id integer
      );
      CREATE TABLE activity_log_ipa_assignment_session_filestores (
          id integer NOT NULL,
          master_id integer,
          ipa_assignment_id integer,
          select_scanner varchar,
          operator varchar,
          notes varchar,
          session_date date,
          session_time time,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE FUNCTION log_activity_log_ipa_assignment_session_filestore_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_session_filestore_history
                  (
                      master_id,
                      ipa_assignment_id,
                      select_scanner,
                      operator,
                      notes,
                      session_date,
                      session_time,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_session_filestore_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.select_scanner,
                      NEW.operator,
                      NEW.notes,
                      NEW.session_date,
                      NEW.session_time,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE SEQUENCE activity_log_ipa_assignment_session_filestore_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_assignment_session_filestore_history_id_seq OWNED BY activity_log_ipa_assignment_session_filestore_history.id;


      CREATE SEQUENCE activity_log_ipa_assignment_session_filestores_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_assignment_session_filestores_id_seq OWNED BY activity_log_ipa_assignment_session_filestores.id;

      ALTER TABLE ONLY activity_log_ipa_assignment_session_filestores ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignment_session_filestores_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_ipa_assignment_session_filestore_history ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignment_session_filestore_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_ipa_assignment_session_filestore_history
          ADD CONSTRAINT activity_log_ipa_assignment_session_filestore_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_ipa_assignment_session_filestores
          ADD CONSTRAINT activity_log_ipa_assignment_session_filestores_pkey PRIMARY KEY (id);

      CREATE INDEX index_al_ipa_assignment_session_filestore_history_on_master_id ON activity_log_ipa_assignment_session_filestore_history USING btree (master_id);
      CREATE INDEX index_al_ipa_assignment_session_filestore_history_on_ipa_assignment_session_filestore_id ON activity_log_ipa_assignment_session_filestore_history USING btree (ipa_assignment_id);

      CREATE INDEX index_al_ipa_assignment_session_filestore_history_on_activity_log_ipa_assignment_session_filestore_id ON activity_log_ipa_assignment_session_filestore_history USING btree (activity_log_ipa_assignment_session_filestore_id);
      CREATE INDEX index_al_ipa_assignment_session_filestore_history_on_user_id ON activity_log_ipa_assignment_session_filestore_history USING btree (user_id);

      CREATE INDEX index_activity_log_ipa_assignment_session_filestores_on_master_id ON activity_log_ipa_assignment_session_filestores USING btree (master_id);
      CREATE INDEX index_activity_log_ipa_assignment_session_filestores_on_ipa_assignment_session_filestore_id ON activity_log_ipa_assignment_session_filestores USING btree (ipa_assignment_id);
      CREATE INDEX index_activity_log_ipa_assignment_session_filestores_on_user_id ON activity_log_ipa_assignment_session_filestores USING btree (user_id);

      CREATE TRIGGER activity_log_ipa_assignment_session_filestore_history_insert AFTER INSERT ON activity_log_ipa_assignment_session_filestores FOR EACH ROW EXECUTE PROCEDURE log_activity_log_ipa_assignment_session_filestore_update();
      CREATE TRIGGER activity_log_ipa_assignment_session_filestore_history_update AFTER UPDATE ON activity_log_ipa_assignment_session_filestores FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_ipa_assignment_session_filestore_update();


      ALTER TABLE ONLY activity_log_ipa_assignment_session_filestores
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_ipa_assignment_session_filestores
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_ipa_assignment_session_filestores
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_session_filestore_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_session_filestore_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_session_filestore_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_session_filestore_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_session_filestore_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_session_filestore_history_ipa_assignment_session_filestore_id FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_session_filestore_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_session_filestore_history_activity_log_ipa_assignment_session_filestores FOREIGN KEY (activity_log_ipa_assignment_session_filestore_id) REFERENCES activity_log_ipa_assignment_session_filestores(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
