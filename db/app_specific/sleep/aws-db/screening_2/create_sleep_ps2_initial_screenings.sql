set search_path=sleep, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_ps2_initial_screenings select_is_good_time_to_speak any_questions_blank_yes_no select_still_interested follow_up_date follow_up_time notes

      CREATE FUNCTION log_sleep_ps2_initial_screening_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_ps2_initial_screening_history
                  (
                      master_id,
                      select_is_good_time_to_speak,
                      any_questions_blank_yes_no,
                      select_still_interested,
                      follow_up_date,
                      follow_up_time,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_ps2_initial_screening_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_is_good_time_to_speak,
                      NEW.any_questions_blank_yes_no,
                      NEW.select_still_interested,
                      NEW.follow_up_date,
                      NEW.follow_up_time,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_ps2_initial_screening_history (
          id integer NOT NULL,
          master_id integer,
          select_is_good_time_to_speak varchar,
          any_questions_blank_yes_no varchar,
          select_still_interested varchar,
          follow_up_date date,
          follow_up_time varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_ps2_initial_screening_id integer
      );

      CREATE SEQUENCE sleep_ps2_initial_screening_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_ps2_initial_screening_history_id_seq OWNED BY sleep_ps2_initial_screening_history.id;

      CREATE TABLE sleep_ps2_initial_screenings (
          id integer NOT NULL,
          master_id integer,
          select_is_good_time_to_speak varchar,
          any_questions_blank_yes_no varchar,
          select_still_interested varchar,
          follow_up_date date,
          follow_up_time varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_ps2_initial_screenings_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_ps2_initial_screenings_id_seq OWNED BY sleep_ps2_initial_screenings.id;

      ALTER TABLE ONLY sleep_ps2_initial_screenings ALTER COLUMN id SET DEFAULT nextval('sleep_ps2_initial_screenings_id_seq'::regclass);
      ALTER TABLE ONLY sleep_ps2_initial_screening_history ALTER COLUMN id SET DEFAULT nextval('sleep_ps2_initial_screening_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_ps2_initial_screening_history
          ADD CONSTRAINT sleep_ps2_initial_screening_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_ps2_initial_screenings
          ADD CONSTRAINT sleep_ps2_initial_screenings_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_ps2_initial_screening_history_on_master_id ON sleep_ps2_initial_screening_history USING btree (master_id);


      CREATE INDEX index_sleep_ps2_initial_screening_history_on_sleep_ps2_initial_screening_id ON sleep_ps2_initial_screening_history USING btree (sleep_ps2_initial_screening_id);
      CREATE INDEX index_sleep_ps2_initial_screening_history_on_user_id ON sleep_ps2_initial_screening_history USING btree (user_id);

      CREATE INDEX index_sleep_ps2_initial_screenings_on_master_id ON sleep_ps2_initial_screenings USING btree (master_id);

      CREATE INDEX index_sleep_ps2_initial_screenings_on_user_id ON sleep_ps2_initial_screenings USING btree (user_id);

      CREATE TRIGGER sleep_ps2_initial_screening_history_insert AFTER INSERT ON sleep_ps2_initial_screenings FOR EACH ROW EXECUTE PROCEDURE log_sleep_ps2_initial_screening_update();
      CREATE TRIGGER sleep_ps2_initial_screening_history_update AFTER UPDATE ON sleep_ps2_initial_screenings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_ps2_initial_screening_update();


      ALTER TABLE ONLY sleep_ps2_initial_screenings
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_ps2_initial_screenings
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_ps2_initial_screening_history
          ADD CONSTRAINT fk_sleep_ps2_initial_screening_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_ps2_initial_screening_history
          ADD CONSTRAINT fk_sleep_ps2_initial_screening_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_ps2_initial_screening_history
          ADD CONSTRAINT fk_sleep_ps2_initial_screening_history_sleep_ps2_initial_screenings FOREIGN KEY (sleep_ps2_initial_screening_id) REFERENCES sleep_ps2_initial_screenings(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA sleep TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA sleep TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA sleep TO fphs;

      COMMIT;
