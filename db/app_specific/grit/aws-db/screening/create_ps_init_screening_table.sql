set search_path=grit, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_ps_initial_screenings select_is_good_time_to_speak select_may_i_begin any_questions_blank_yes_no select_still_interested follow_up_date follow_up_time notes

      CREATE OR REPLACE FUNCTION log_grit_ps_initial_screening_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                INSERT INTO grit_ps_initial_screening_history
                (
                    master_id,
                    select_is_good_time_to_speak,
                    looked_at_website_yes_no,
                    select_may_i_begin,
                    any_questions_blank_yes_no,
                    question_notes,
                    --- Note we retain select_still_interested since it is used in the withdrawal logic
                    select_still_interested,
                    follow_up_date,
                    follow_up_time,
                    notes,
                    user_id,
                    created_at,
                    updated_at,
                    grit_ps_initial_screening_id
                    )
                SELECT
                    NEW.master_id,
                    NEW.select_is_good_time_to_speak,
                    NEW.looked_at_website_yes_no,
                    NEW.select_may_i_begin,
                    NEW.any_questions_blank_yes_no,
                    NEW.question_notes,
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

      CREATE TABLE grit_ps_initial_screening_history (
          id integer NOT NULL,
          master_id integer,
          select_is_good_time_to_speak varchar,
          looked_at_website_yes_no varchar,
          select_may_i_begin varchar,
          any_questions_blank_yes_no varchar,
          question_notes varchar,
          select_still_interested varchar,
          follow_up_date date,
          follow_up_time time,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_ps_initial_screening_id integer
      );

      CREATE SEQUENCE grit_ps_initial_screening_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_ps_initial_screening_history_id_seq OWNED BY grit_ps_initial_screening_history.id;

      CREATE TABLE grit_ps_initial_screenings (
          id integer NOT NULL,
          master_id integer,
          select_is_good_time_to_speak varchar,
          looked_at_website_yes_no varchar,
          select_may_i_begin varchar,
          any_questions_blank_yes_no varchar,
          question_notes varchar,
          select_still_interested varchar,
          follow_up_date date,
          follow_up_time time,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_ps_initial_screenings_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_ps_initial_screenings_id_seq OWNED BY grit_ps_initial_screenings.id;

      ALTER TABLE ONLY grit_ps_initial_screenings ALTER COLUMN id SET DEFAULT nextval('grit_ps_initial_screenings_id_seq'::regclass);
      ALTER TABLE ONLY grit_ps_initial_screening_history ALTER COLUMN id SET DEFAULT nextval('grit_ps_initial_screening_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_ps_initial_screening_history
          ADD CONSTRAINT grit_ps_initial_screening_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_ps_initial_screenings
          ADD CONSTRAINT grit_ps_initial_screenings_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_ps_initial_screening_history_on_master_id ON grit_ps_initial_screening_history USING btree (master_id);


      CREATE INDEX index_grit_ps_initial_screening_history_on_grit_ps_initial_screening_id ON grit_ps_initial_screening_history USING btree (grit_ps_initial_screening_id);
      CREATE INDEX index_grit_ps_initial_screening_history_on_user_id ON grit_ps_initial_screening_history USING btree (user_id);

      CREATE INDEX index_grit_ps_initial_screenings_on_master_id ON grit_ps_initial_screenings USING btree (master_id);

      CREATE INDEX index_grit_ps_initial_screenings_on_user_id ON grit_ps_initial_screenings USING btree (user_id);

      CREATE TRIGGER grit_ps_initial_screening_history_insert AFTER INSERT ON grit_ps_initial_screenings FOR EACH ROW EXECUTE PROCEDURE log_grit_ps_initial_screening_update();
      CREATE TRIGGER grit_ps_initial_screening_history_update AFTER UPDATE ON grit_ps_initial_screenings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_ps_initial_screening_update();


      ALTER TABLE ONLY grit_ps_initial_screenings
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_ps_initial_screenings
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_ps_initial_screening_history
          ADD CONSTRAINT fk_grit_ps_initial_screening_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_ps_initial_screening_history
          ADD CONSTRAINT fk_grit_ps_initial_screening_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_ps_initial_screening_history
          ADD CONSTRAINT fk_grit_ps_initial_screening_history_grit_ps_initial_screenings FOREIGN KEY (grit_ps_initial_screening_id) REFERENCES grit_ps_initial_screenings(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
