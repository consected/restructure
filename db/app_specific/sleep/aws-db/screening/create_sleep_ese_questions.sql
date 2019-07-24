set search_path=sleep, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_ese_questions sitting_and_reading watching_tv public_place car_passenger afternoon_rest sitting_and_talking after_lunch stopped_in_traffic total_score number_hours_sleep ineligible_resource_yes_no placeholder_resource

      CREATE or REPLACE FUNCTION log_sleep_ese_question_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_ese_question_history
                  (
                      master_id,
                      sitting_and_reading,
                      watching_tv,
                      public_place,
                      car_passenger,
                      afternoon_rest,
                      sitting_and_talking,
                      after_lunch,
                      stopped_in_traffic,
                      total_score,
                      number_hours_sleep,
                      ineligible_resource_yes_no,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_ese_question_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.sitting_and_reading,
                      NEW.watching_tv,
                      NEW.public_place,
                      NEW.car_passenger,
                      NEW.afternoon_rest,
                      NEW.sitting_and_talking,
                      NEW.after_lunch,
                      NEW.stopped_in_traffic,
                      NEW.total_score,
                      NEW.number_hours_sleep,
                      NEW.ineligible_resource_yes_no,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_ese_question_history (
          id integer NOT NULL,
          master_id integer,
          sitting_and_reading INTEGER,
          watching_tv INTEGER,
          public_place INTEGER,
          car_passenger INTEGER,
          afternoon_rest INTEGER,
          sitting_and_talking INTEGER,
          after_lunch INTEGER,
          stopped_in_traffic INTEGER,
          total_score INTEGER,
          number_hours_sleep integer,
          ineligible_resource_yes_no varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_ese_question_id integer
      );

      CREATE SEQUENCE sleep_ese_question_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_ese_question_history_id_seq OWNED BY sleep_ese_question_history.id;

      CREATE TABLE sleep_ese_questions (
          id integer NOT NULL,
          master_id integer,
          sitting_and_reading INTEGER,
          watching_tv INTEGER,
          public_place INTEGER,
          car_passenger INTEGER,
          afternoon_rest INTEGER,
          sitting_and_talking INTEGER,
          after_lunch INTEGER,
          stopped_in_traffic INTEGER,
          total_score INTEGER,
          number_hours_sleep integer,
          ineligible_resource_yes_no varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_ese_questions_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_ese_questions_id_seq OWNED BY sleep_ese_questions.id;

      ALTER TABLE ONLY sleep_ese_questions ALTER COLUMN id SET DEFAULT nextval('sleep_ese_questions_id_seq'::regclass);
      ALTER TABLE ONLY sleep_ese_question_history ALTER COLUMN id SET DEFAULT nextval('sleep_ese_question_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_ese_question_history
          ADD CONSTRAINT sleep_ese_question_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_ese_questions
          ADD CONSTRAINT sleep_ese_questions_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_ese_question_history_on_master_id ON sleep_ese_question_history USING btree (master_id);


      CREATE INDEX index_sleep_ese_question_history_on_sleep_ese_question_id ON sleep_ese_question_history USING btree (sleep_ese_question_id);
      CREATE INDEX index_sleep_ese_question_history_on_user_id ON sleep_ese_question_history USING btree (user_id);

      CREATE INDEX index_sleep_ese_questions_on_master_id ON sleep_ese_questions USING btree (master_id);

      CREATE INDEX index_sleep_ese_questions_on_user_id ON sleep_ese_questions USING btree (user_id);

      CREATE TRIGGER sleep_ese_question_history_insert AFTER INSERT ON sleep_ese_questions FOR EACH ROW EXECUTE PROCEDURE log_sleep_ese_question_update();
      CREATE TRIGGER sleep_ese_question_history_update AFTER UPDATE ON sleep_ese_questions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_ese_question_update();


      ALTER TABLE ONLY sleep_ese_questions
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_ese_questions
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_ese_question_history
          ADD CONSTRAINT fk_sleep_ese_question_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_ese_question_history
          ADD CONSTRAINT fk_sleep_ese_question_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_ese_question_history
          ADD CONSTRAINT fk_sleep_ese_question_history_sleep_ese_questions FOREIGN KEY (sleep_ese_question_id) REFERENCES sleep_ese_questions(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
