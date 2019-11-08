set search_path=sleep, ml_app;

  BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_ps_dast2_mod_questions number_days_negative_feeling number_days_drug_usage

      CREATE or REPLACE FUNCTION log_sleep_ps_dast2_mod_question_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_ps_dast2_mod_question_history
                  (
                      master_id,
                      number_days_negative_feeling,
                      number_days_drug_usage,
                      possibly_eligible_yes_no,
                      possibly_eligible_reason_notes,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_ps_dast2_mod_question_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.number_days_negative_feeling,
                      NEW.number_days_drug_usage,
                      NEW.possibly_eligible_yes_no,
                      NEW.possibly_eligible_reason_notes,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_ps_dast2_mod_question_history (
          id integer NOT NULL,
          master_id integer,
          number_days_negative_feeling integer,
          number_days_drug_usage integer,
          possibly_eligible_yes_no VARCHAR,
          possibly_eligible_reason_notes VARCHAR,
          notes VARCHAR,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_ps_dast2_mod_question_id integer
      );

      CREATE SEQUENCE sleep_ps_dast2_mod_question_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_ps_dast2_mod_question_history_id_seq OWNED BY sleep_ps_dast2_mod_question_history.id;

      CREATE TABLE sleep_ps_dast2_mod_questions (
          id integer NOT NULL,
          master_id integer,
          number_days_negative_feeling integer,
          number_days_drug_usage integer,
          possibly_eligible_yes_no VARCHAR,
          possibly_eligible_reason_notes VARCHAR,
          notes VARCHAR,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_ps_dast2_mod_questions_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_ps_dast2_mod_questions_id_seq OWNED BY sleep_ps_dast2_mod_questions.id;

      ALTER TABLE ONLY sleep_ps_dast2_mod_questions ALTER COLUMN id SET DEFAULT nextval('sleep_ps_dast2_mod_questions_id_seq'::regclass);
      ALTER TABLE ONLY sleep_ps_dast2_mod_question_history ALTER COLUMN id SET DEFAULT nextval('sleep_ps_dast2_mod_question_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_ps_dast2_mod_question_history
          ADD CONSTRAINT sleep_ps_dast2_mod_question_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_ps_dast2_mod_questions
          ADD CONSTRAINT sleep_ps_dast2_mod_questions_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_ps_dast2_mod_question_history_on_master_id ON sleep_ps_dast2_mod_question_history USING btree (master_id);


      CREATE INDEX index_sleep_ps_dast2_mod_question_history_on_sleep_ps_dast2_mod_question_id ON sleep_ps_dast2_mod_question_history USING btree (sleep_ps_dast2_mod_question_id);
      CREATE INDEX index_sleep_ps_dast2_mod_question_history_on_user_id ON sleep_ps_dast2_mod_question_history USING btree (user_id);

      CREATE INDEX index_sleep_ps_dast2_mod_questions_on_master_id ON sleep_ps_dast2_mod_questions USING btree (master_id);

      CREATE INDEX index_sleep_ps_dast2_mod_questions_on_user_id ON sleep_ps_dast2_mod_questions USING btree (user_id);

      CREATE TRIGGER sleep_ps_dast2_mod_question_history_insert AFTER INSERT ON sleep_ps_dast2_mod_questions FOR EACH ROW EXECUTE PROCEDURE log_sleep_ps_dast2_mod_question_update();
      CREATE TRIGGER sleep_ps_dast2_mod_question_history_update AFTER UPDATE ON sleep_ps_dast2_mod_questions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_ps_dast2_mod_question_update();


      ALTER TABLE ONLY sleep_ps_dast2_mod_questions
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_ps_dast2_mod_questions
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_ps_dast2_mod_question_history
          ADD CONSTRAINT fk_sleep_ps_dast2_mod_question_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_ps_dast2_mod_question_history
          ADD CONSTRAINT fk_sleep_ps_dast2_mod_question_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_ps_dast2_mod_question_history
          ADD CONSTRAINT fk_sleep_ps_dast2_mod_question_history_sleep_ps_dast2_mod_questions FOREIGN KEY (sleep_ps_dast2_mod_question_id) REFERENCES sleep_ps_dast2_mod_questions(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
