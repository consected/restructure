
      BEGIN;

      CREATE FUNCTION log_ipa_follow_up_survey_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_follow_up_survey_history
                  (
                      master_id,
                      exit_survey_completed_date,
                      send_follow_up_survey_when,
                      follow_up_completed_date,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_follow_up_survey_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.exit_survey_completed_date,
                      NEW.send_follow_up_survey_when,
                      NEW.follow_up_completed_date,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_follow_up_survey_history (
          id integer NOT NULL,
          master_id integer,
          exit_survey_completed_date date,
          send_follow_up_survey_when date,
          follow_up_completed_date date,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_follow_up_survey_id integer
      );

      CREATE SEQUENCE ipa_follow_up_survey_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_follow_up_survey_history_id_seq OWNED BY ipa_follow_up_survey_history.id;

      CREATE TABLE ipa_follow_up_surveys (
          id integer NOT NULL,
          master_id integer,
          exit_survey_completed_date date,
          send_follow_up_survey_when date,
          follow_up_completed_date date,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_follow_up_surveys_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_follow_up_surveys_id_seq OWNED BY ipa_follow_up_surveys.id;

      ALTER TABLE ONLY ipa_follow_up_surveys ALTER COLUMN id SET DEFAULT nextval('ipa_follow_up_surveys_id_seq'::regclass);
      ALTER TABLE ONLY ipa_follow_up_survey_history ALTER COLUMN id SET DEFAULT nextval('ipa_follow_up_survey_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_follow_up_survey_history
          ADD CONSTRAINT ipa_follow_up_survey_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_follow_up_surveys
          ADD CONSTRAINT ipa_follow_up_surveys_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_follow_up_survey_history_on_master_id ON ipa_follow_up_survey_history USING btree (master_id);


      CREATE INDEX index_ipa_follow_up_survey_history_on_ipa_follow_up_survey_id ON ipa_follow_up_survey_history USING btree (ipa_follow_up_survey_id);
      CREATE INDEX index_ipa_follow_up_survey_history_on_user_id ON ipa_follow_up_survey_history USING btree (user_id);

      CREATE INDEX index_ipa_follow_up_surveys_on_master_id ON ipa_follow_up_surveys USING btree (master_id);

      CREATE INDEX index_ipa_follow_up_surveys_on_user_id ON ipa_follow_up_surveys USING btree (user_id);

      CREATE TRIGGER ipa_follow_up_survey_history_insert AFTER INSERT ON ipa_follow_up_surveys FOR EACH ROW EXECUTE PROCEDURE log_ipa_follow_up_survey_update();
      CREATE TRIGGER ipa_follow_up_survey_history_update AFTER UPDATE ON ipa_follow_up_surveys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_follow_up_survey_update();


      ALTER TABLE ONLY ipa_follow_up_surveys
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_follow_up_surveys
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_follow_up_survey_history
          ADD CONSTRAINT fk_ipa_follow_up_survey_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_follow_up_survey_history
          ADD CONSTRAINT fk_ipa_follow_up_survey_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_follow_up_survey_history
          ADD CONSTRAINT fk_ipa_follow_up_survey_history_ipa_follow_up_surveys FOREIGN KEY (ipa_follow_up_survey_id) REFERENCES ipa_follow_up_surveys(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
