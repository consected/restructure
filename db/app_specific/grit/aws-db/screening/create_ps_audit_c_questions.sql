set search_path=grit, ml_app;

  BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_ps_audit_c_questions alcohol_frequency daily_alcohol six_or_more_frequency total_score

      CREATE or REPLACE FUNCTION log_grit_ps_audit_c_question_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO grit_ps_audit_c_question_history
                  (
                      master_id,
                      alcohol_frequency,
                      daily_alcohol,
                      six_or_more_frequency,
                      total_score,
                      possibly_eligible_yes_no,
                      possibly_eligible_reason_notes,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      grit_ps_audit_c_question_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.alcohol_frequency,
                      NEW.daily_alcohol,
                      NEW.six_or_more_frequency,
                      NEW.total_score,
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

      CREATE TABLE grit_ps_audit_c_question_history (
          id integer NOT NULL,
          master_id integer,
          alcohol_frequency varchar,
          daily_alcohol varchar,
          six_or_more_frequency varchar,
          total_score varchar,
          possibly_eligible_yes_no VARCHAR,
          possibly_eligible_reason_notes varchar,
          notes VARCHAR,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_ps_audit_c_question_id integer
      );

      CREATE SEQUENCE grit_ps_audit_c_question_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_ps_audit_c_question_history_id_seq OWNED BY grit_ps_audit_c_question_history.id;

      CREATE TABLE grit_ps_audit_c_questions (
          id integer NOT NULL,
          master_id integer,
          alcohol_frequency varchar,
          daily_alcohol varchar,
          six_or_more_frequency varchar,
          total_score varchar,
          possibly_eligible_yes_no VARCHAR,
          possibly_eligible_reason_notes varchar,
          notes VARCHAR,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_ps_audit_c_questions_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_ps_audit_c_questions_id_seq OWNED BY grit_ps_audit_c_questions.id;

      ALTER TABLE ONLY grit_ps_audit_c_questions ALTER COLUMN id SET DEFAULT nextval('grit_ps_audit_c_questions_id_seq'::regclass);
      ALTER TABLE ONLY grit_ps_audit_c_question_history ALTER COLUMN id SET DEFAULT nextval('grit_ps_audit_c_question_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_ps_audit_c_question_history
          ADD CONSTRAINT grit_ps_audit_c_question_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_ps_audit_c_questions
          ADD CONSTRAINT grit_ps_audit_c_questions_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_ps_audit_c_question_history_on_master_id ON grit_ps_audit_c_question_history USING btree (master_id);


      CREATE INDEX index_grit_ps_audit_c_question_history_on_grit_ps_audit_c_question_id ON grit_ps_audit_c_question_history USING btree (grit_ps_audit_c_question_id);
      CREATE INDEX index_grit_ps_audit_c_question_history_on_user_id ON grit_ps_audit_c_question_history USING btree (user_id);

      CREATE INDEX index_grit_ps_audit_c_questions_on_master_id ON grit_ps_audit_c_questions USING btree (master_id);

      CREATE INDEX index_grit_ps_audit_c_questions_on_user_id ON grit_ps_audit_c_questions USING btree (user_id);

      CREATE TRIGGER grit_ps_audit_c_question_history_insert AFTER INSERT ON grit_ps_audit_c_questions FOR EACH ROW EXECUTE PROCEDURE log_grit_ps_audit_c_question_update();
      CREATE TRIGGER grit_ps_audit_c_question_history_update AFTER UPDATE ON grit_ps_audit_c_questions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_ps_audit_c_question_update();


      ALTER TABLE ONLY grit_ps_audit_c_questions
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_ps_audit_c_questions
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_ps_audit_c_question_history
          ADD CONSTRAINT fk_grit_ps_audit_c_question_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_ps_audit_c_question_history
          ADD CONSTRAINT fk_grit_ps_audit_c_question_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_ps_audit_c_question_history
          ADD CONSTRAINT fk_grit_ps_audit_c_question_history_grit_ps_audit_c_questions FOREIGN KEY (grit_ps_audit_c_question_id) REFERENCES grit_ps_audit_c_questions(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
