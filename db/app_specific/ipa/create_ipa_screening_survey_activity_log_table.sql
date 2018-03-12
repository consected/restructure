
      BEGIN;

      CREATE TABLE activity_log_ipa_survey_history (
          id integer NOT NULL,
          master_id integer,
          ipa_survey_id integer,
          screened_by_who varchar,
          screening_date date,
          select_status varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_ipa_survey_id integer
      );
      CREATE TABLE activity_log_ipa_surveys (
          id integer NOT NULL,
          master_id integer,
          ipa_survey_id integer,
          screened_by_who varchar,
          screening_date date,
          select_status varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE FUNCTION log_activity_log_ipa_survey_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_survey_history
                  (
                      master_id,
                      ipa_survey_id,
                      screened_by_who,
                      screening_date,
                      select_status,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_survey_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_survey_id,
                      NEW.screened_by_who,
                      NEW.screening_date,
                      NEW.select_status,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE SEQUENCE activity_log_ipa_survey_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_survey_history_id_seq OWNED BY activity_log_ipa_survey_history.id;


      CREATE SEQUENCE activity_log_ipa_surveys_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_surveys_id_seq OWNED BY activity_log_ipa_surveys.id;

      ALTER TABLE ONLY activity_log_ipa_surveys ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_surveys_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_ipa_survey_history ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_survey_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_ipa_survey_history
          ADD CONSTRAINT activity_log_ipa_survey_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_ipa_surveys
          ADD CONSTRAINT activity_log_ipa_surveys_pkey PRIMARY KEY (id);

      CREATE INDEX index_activity_log_ipa_survey_history_on_master_id ON activity_log_ipa_survey_history USING btree (master_id);
      CREATE INDEX index_activity_log_ipa_survey_history_on_ipa_survey_id ON activity_log_ipa_survey_history USING btree (ipa_survey_id);

      CREATE INDEX index_activity_log_ipa_survey_history_on_activity_log_ipa_survey_id ON activity_log_ipa_survey_history USING btree (activity_log_ipa_survey_id);
      CREATE INDEX index_activity_log_ipa_survey_history_on_user_id ON activity_log_ipa_survey_history USING btree (user_id);

      CREATE INDEX index_activity_log_ipa_surveys_on_master_id ON activity_log_ipa_surveys USING btree (master_id);
      CREATE INDEX index_activity_log_ipa_surveys_on_ipa_survey_id ON activity_log_ipa_surveys USING btree (ipa_survey_id);
      CREATE INDEX index_activity_log_ipa_surveys_on_user_id ON activity_log_ipa_surveys USING btree (user_id);

      CREATE TRIGGER activity_log_ipa_survey_history_insert AFTER INSERT ON activity_log_ipa_surveys FOR EACH ROW EXECUTE PROCEDURE log_activity_log_ipa_survey_update();
      CREATE TRIGGER activity_log_ipa_survey_history_update AFTER UPDATE ON activity_log_ipa_surveys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_ipa_survey_update();


      ALTER TABLE ONLY activity_log_ipa_surveys
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_ipa_surveys
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_ipa_surveys
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_survey_id) REFERENCES ipa_surveys(id);

      ALTER TABLE ONLY activity_log_ipa_survey_history
          ADD CONSTRAINT fk_activity_log_ipa_survey_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_ipa_survey_history
          ADD CONSTRAINT fk_activity_log_ipa_survey_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_ipa_survey_history
          ADD CONSTRAINT fk_activity_log_ipa_survey_history_ipa_survey_id FOREIGN KEY (ipa_survey_id) REFERENCES ipa_surveys(id);

      ALTER TABLE ONLY activity_log_ipa_survey_history
          ADD CONSTRAINT fk_activity_log_ipa_survey_history_activity_log_ipa_surveys FOREIGN KEY (activity_log_ipa_survey_id) REFERENCES activity_log_ipa_surveys(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
