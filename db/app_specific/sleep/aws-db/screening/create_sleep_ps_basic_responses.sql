set search_path=sleep, ml_app;


      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_ps_basic_responses chronic_pain_diagnosis_yes_no_dont_know chronic_pain_diagnosis_notes use_pain_meds_daily_yes_no use_pain_meds_daily_notes narcolepsy_diagnosis_yes_no_dont_know narcolepsy_diagnosis_notes reliable_internet_yes_no notes

      CREATE FUNCTION log_sleep_ps_basic_response_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_ps_basic_response_history
                  (
                      master_id,
                      chronic_pain_diagnosis_yes_no_dont_know,
                      chronic_pain_diagnosis_notes,
                      use_pain_meds_daily_yes_no,
                      use_pain_meds_daily_notes,
                      narcolepsy_diagnosis_yes_no_dont_know,
                      narcolepsy_diagnosis_notes,
                      reliable_internet_yes_no,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_ps_basic_response_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.chronic_pain_diagnosis_yes_no_dont_know,
                      NEW.chronic_pain_diagnosis_notes,
                      NEW.use_pain_meds_daily_yes_no,
                      NEW.use_pain_meds_daily_notes,
                      NEW.narcolepsy_diagnosis_yes_no_dont_know,
                      NEW.narcolepsy_diagnosis_notes,
                      NEW.reliable_internet_yes_no,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_ps_basic_response_history (
          id integer NOT NULL,
          master_id integer,
          chronic_pain_diagnosis_yes_no_dont_know varchar,
          chronic_pain_diagnosis_notes varchar,
          use_pain_meds_daily_yes_no varchar,
          use_pain_meds_daily_notes varchar,
          narcolepsy_diagnosis_yes_no_dont_know varchar,
          narcolepsy_diagnosis_notes varchar,
          reliable_internet_yes_no varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_ps_basic_response_id integer
      );

      CREATE SEQUENCE sleep_ps_basic_response_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_ps_basic_response_history_id_seq OWNED BY sleep_ps_basic_response_history.id;

      CREATE TABLE sleep_ps_basic_responses (
          id integer NOT NULL,
          master_id integer,
          chronic_pain_diagnosis_yes_no_dont_know varchar,
          chronic_pain_diagnosis_notes varchar,
          use_pain_meds_daily_yes_no varchar,
          use_pain_meds_daily_notes varchar,
          narcolepsy_diagnosis_yes_no_dont_know varchar,
          narcolepsy_diagnosis_notes varchar,
          reliable_internet_yes_no varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_ps_basic_responses_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_ps_basic_responses_id_seq OWNED BY sleep_ps_basic_responses.id;

      ALTER TABLE ONLY sleep_ps_basic_responses ALTER COLUMN id SET DEFAULT nextval('sleep_ps_basic_responses_id_seq'::regclass);
      ALTER TABLE ONLY sleep_ps_basic_response_history ALTER COLUMN id SET DEFAULT nextval('sleep_ps_basic_response_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_ps_basic_response_history
          ADD CONSTRAINT sleep_ps_basic_response_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_ps_basic_responses
          ADD CONSTRAINT sleep_ps_basic_responses_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_ps_basic_response_history_on_master_id ON sleep_ps_basic_response_history USING btree (master_id);


      CREATE INDEX index_sleep_ps_basic_response_history_on_sleep_ps_basic_response_id ON sleep_ps_basic_response_history USING btree (sleep_ps_basic_response_id);
      CREATE INDEX index_sleep_ps_basic_response_history_on_user_id ON sleep_ps_basic_response_history USING btree (user_id);

      CREATE INDEX index_sleep_ps_basic_responses_on_master_id ON sleep_ps_basic_responses USING btree (master_id);

      CREATE INDEX index_sleep_ps_basic_responses_on_user_id ON sleep_ps_basic_responses USING btree (user_id);

      CREATE TRIGGER sleep_ps_basic_response_history_insert AFTER INSERT ON sleep_ps_basic_responses FOR EACH ROW EXECUTE PROCEDURE log_sleep_ps_basic_response_update();
      CREATE TRIGGER sleep_ps_basic_response_history_update AFTER UPDATE ON sleep_ps_basic_responses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_ps_basic_response_update();


      ALTER TABLE ONLY sleep_ps_basic_responses
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_ps_basic_responses
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_ps_basic_response_history
          ADD CONSTRAINT fk_sleep_ps_basic_response_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_ps_basic_response_history
          ADD CONSTRAINT fk_sleep_ps_basic_response_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_ps_basic_response_history
          ADD CONSTRAINT fk_sleep_ps_basic_response_history_sleep_ps_basic_responses FOREIGN KEY (sleep_ps_basic_response_id) REFERENCES sleep_ps_basic_responses(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
