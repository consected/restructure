set search_path=sleep, ml_app;

  BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_isi_questions falling_asleep staying_asleep waking_too_early satisfaction_with_pattern noticeable_to_others worried_distressed interferes_with_daily_function

      CREATE or REPLACE FUNCTION log_sleep_isi_question_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_isi_question_history
                  (
                      master_id,
                      falling_asleep,
                      staying_asleep,
                      waking_too_early,
                      satisfaction_with_pattern,
                      noticeable_to_others,
                      worried_distressed,
                      interferes_with_daily_function,
                      total_score,
                      ineligible_assist_yes_no,
                      trust_assessment_info_yes_no,
                      help_finding_pcp_yes_no,
                      possibly_eligible_yes_no,
                      possibly_eligible_reason_notes,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_isi_question_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.falling_asleep,
                      NEW.staying_asleep,
                      NEW.waking_too_early,
                      NEW.satisfaction_with_pattern,
                      NEW.noticeable_to_others,
                      NEW.worried_distressed,
                      NEW.interferes_with_daily_function,
                      NEW.total_score,
                      NEW.ineligible_assist_yes_no,
                      NEW.trust_assessment_info_yes_no,
                      NEW.help_finding_pcp_yes_no,
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

      CREATE TABLE sleep_isi_question_history (
          id integer NOT NULL,
          master_id integer,
          falling_asleep INTEGER,
          staying_asleep INTEGER,
          waking_too_early INTEGER,
          satisfaction_with_pattern INTEGER,
          noticeable_to_others INTEGER,
          worried_distressed INTEGER,
          interferes_with_daily_function INTEGER,
          total_score INTEGER,
          ineligible_assist_yes_no VARCHAR,
          trust_assessment_info_yes_no VARCHAR,
          help_finding_pcp_yes_no VARCHAR,
          possibly_eligible_yes_no VARCHAR,
          possibly_eligible_reason_notes varchar,
          notes VARCHAR,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_isi_question_id integer
      );

      CREATE SEQUENCE sleep_isi_question_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_isi_question_history_id_seq OWNED BY sleep_isi_question_history.id;

      CREATE TABLE sleep_isi_questions (
          id integer NOT NULL,
          master_id integer,
          falling_asleep INTEGER,
          staying_asleep INTEGER,
          waking_too_early INTEGER,
          satisfaction_with_pattern INTEGER,
          noticeable_to_others INTEGER,
          worried_distressed INTEGER,
          interferes_with_daily_function INTEGER,
          total_score INTEGER,
          ineligible_assist_yes_no VARCHAR,
          trust_assessment_info_yes_no VARCHAR,
          help_finding_pcp_yes_no VARCHAR,
          possibly_eligible_yes_no VARCHAR,
          possibly_eligible_reason_notes varchar,
          notes VARCHAR,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_isi_questions_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_isi_questions_id_seq OWNED BY sleep_isi_questions.id;

      ALTER TABLE ONLY sleep_isi_questions ALTER COLUMN id SET DEFAULT nextval('sleep_isi_questions_id_seq'::regclass);
      ALTER TABLE ONLY sleep_isi_question_history ALTER COLUMN id SET DEFAULT nextval('sleep_isi_question_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_isi_question_history
          ADD CONSTRAINT sleep_isi_question_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_isi_questions
          ADD CONSTRAINT sleep_isi_questions_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_isi_question_history_on_master_id ON sleep_isi_question_history USING btree (master_id);


      CREATE INDEX index_sleep_isi_question_history_on_sleep_isi_question_id ON sleep_isi_question_history USING btree (sleep_isi_question_id);
      CREATE INDEX index_sleep_isi_question_history_on_user_id ON sleep_isi_question_history USING btree (user_id);

      CREATE INDEX index_sleep_isi_questions_on_master_id ON sleep_isi_questions USING btree (master_id);

      CREATE INDEX index_sleep_isi_questions_on_user_id ON sleep_isi_questions USING btree (user_id);

      CREATE TRIGGER sleep_isi_question_history_insert AFTER INSERT ON sleep_isi_questions FOR EACH ROW EXECUTE PROCEDURE log_sleep_isi_question_update();
      CREATE TRIGGER sleep_isi_question_history_update AFTER UPDATE ON sleep_isi_questions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_isi_question_update();


      ALTER TABLE ONLY sleep_isi_questions
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_isi_questions
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_isi_question_history
          ADD CONSTRAINT fk_sleep_isi_question_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_isi_question_history
          ADD CONSTRAINT fk_sleep_isi_question_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_isi_question_history
          ADD CONSTRAINT fk_sleep_isi_question_history_sleep_isi_questions FOREIGN KEY (sleep_isi_question_id) REFERENCES sleep_isi_questions(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
