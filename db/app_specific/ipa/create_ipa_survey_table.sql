
      BEGIN;

      CREATE FUNCTION log_ipa_survey_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_survey_history
                  (
                      master_id,
                      select_survey_type,
                      sent_date,
                      completed_date,
                      send_next_survey_when,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_survey_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_survey_type,
                      NEW.sent_date,
                      NEW.completed_date,
                      NEW.send_next_survey_when,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_survey_history (
          id integer NOT NULL,
          master_id integer,
          select_survey_type varchar,
          sent_date date,
          completed_date date,
          send_next_survey_when date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_survey_id integer
      );

      CREATE SEQUENCE ipa_survey_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_survey_history_id_seq OWNED BY ipa_survey_history.id;

      CREATE TABLE ipa_surveys (
          id integer NOT NULL,
          master_id integer,
          select_survey_type varchar,
          sent_date date,
          completed_date date,
          send_next_survey_when date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_surveys_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_surveys_id_seq OWNED BY ipa_surveys.id;

      ALTER TABLE ONLY ipa_surveys ALTER COLUMN id SET DEFAULT nextval('ipa_surveys_id_seq'::regclass);
      ALTER TABLE ONLY ipa_survey_history ALTER COLUMN id SET DEFAULT nextval('ipa_survey_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_survey_history
          ADD CONSTRAINT ipa_survey_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_surveys
          ADD CONSTRAINT ipa_surveys_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_survey_history_on_master_id ON ipa_survey_history USING btree (master_id);


      CREATE INDEX index_ipa_survey_history_on_ipa_survey_id ON ipa_survey_history USING btree (ipa_survey_id);
      CREATE INDEX index_ipa_survey_history_on_user_id ON ipa_survey_history USING btree (user_id);

      CREATE INDEX index_ipa_surveys_on_master_id ON ipa_surveys USING btree (master_id);

      CREATE INDEX index_ipa_surveys_on_user_id ON ipa_surveys USING btree (user_id);

      CREATE TRIGGER ipa_survey_history_insert AFTER INSERT ON ipa_surveys FOR EACH ROW EXECUTE PROCEDURE log_ipa_survey_update();
      CREATE TRIGGER ipa_survey_history_update AFTER UPDATE ON ipa_surveys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_survey_update();


      ALTER TABLE ONLY ipa_surveys
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_surveys
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_survey_history
          ADD CONSTRAINT fk_ipa_survey_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_survey_history
          ADD CONSTRAINT fk_ipa_survey_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_survey_history
          ADD CONSTRAINT fk_ipa_survey_history_ipa_surveys FOREIGN KEY (ipa_survey_id) REFERENCES ipa_surveys(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
