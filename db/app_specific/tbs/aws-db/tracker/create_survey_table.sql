
      BEGIN;

      CREATE FUNCTION log_tbs_survey_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO tbs_survey_history
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
                      tbs_survey_id
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

      CREATE TABLE tbs_survey_history (
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
          tbs_survey_id integer
      );

      CREATE SEQUENCE tbs_survey_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_survey_history_id_seq OWNED BY tbs_survey_history.id;

      CREATE TABLE tbs_surveys (
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
      CREATE SEQUENCE tbs_surveys_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_surveys_id_seq OWNED BY tbs_surveys.id;

      ALTER TABLE ONLY tbs_surveys ALTER COLUMN id SET DEFAULT nextval('tbs_surveys_id_seq'::regclass);
      ALTER TABLE ONLY tbs_survey_history ALTER COLUMN id SET DEFAULT nextval('tbs_survey_history_id_seq'::regclass);

      ALTER TABLE ONLY tbs_survey_history
          ADD CONSTRAINT tbs_survey_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY tbs_surveys
          ADD CONSTRAINT tbs_surveys_pkey PRIMARY KEY (id);

      CREATE INDEX index_tbs_survey_history_on_master_id ON tbs_survey_history USING btree (master_id);


      CREATE INDEX index_tbs_survey_history_on_tbs_survey_id ON tbs_survey_history USING btree (tbs_survey_id);
      CREATE INDEX index_tbs_survey_history_on_user_id ON tbs_survey_history USING btree (user_id);

      CREATE INDEX index_tbs_surveys_on_master_id ON tbs_surveys USING btree (master_id);

      CREATE INDEX index_tbs_surveys_on_user_id ON tbs_surveys USING btree (user_id);

      CREATE TRIGGER tbs_survey_history_insert AFTER INSERT ON tbs_surveys FOR EACH ROW EXECUTE PROCEDURE log_tbs_survey_update();
      CREATE TRIGGER tbs_survey_history_update AFTER UPDATE ON tbs_surveys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_tbs_survey_update();


      ALTER TABLE ONLY tbs_surveys
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY tbs_surveys
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY tbs_survey_history
          ADD CONSTRAINT fk_tbs_survey_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY tbs_survey_history
          ADD CONSTRAINT fk_tbs_survey_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY tbs_survey_history
          ADD CONSTRAINT fk_tbs_survey_history_tbs_surveys FOREIGN KEY (tbs_survey_id) REFERENCES tbs_surveys(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
