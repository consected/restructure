set search_path=grit, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_ps_possibly_eligibles any_questions_yes_no consent_to_pass_info_to_msm_yes_no consent_to_pass_info_to_msm_2_yes_no contact_info_notes notes

      CREATE or REPLACE FUNCTION log_grit_ps_possibly_eligible_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO grit_ps_possibly_eligible_history
                  (
                      master_id,
                      any_questions_yes_no,
                      consent_to_pass_info_to_msm_yes_no,
                      consent_to_pass_info_to_msm_2_yes_no,
                      contact_info_notes,
                      follow_up_date,
                      follow_up_time,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      grit_ps_possibly_eligible_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.any_questions_yes_no,
                      NEW.consent_to_pass_info_to_msm_yes_no,
                      NEW.consent_to_pass_info_to_msm_2_yes_no,
                      NEW.contact_info_notes,
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

      CREATE TABLE grit_ps_possibly_eligible_history (
          id integer NOT NULL,
          master_id integer,
          any_questions_yes_no varchar,
          consent_to_pass_info_to_msm_yes_no varchar,
          consent_to_pass_info_to_msm_2_yes_no varchar,
          contact_info_notes varchar,
          follow_up_date date,
          follow_up_time time,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_ps_possibly_eligible_id integer
      );

      CREATE SEQUENCE grit_ps_possibly_eligible_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_ps_possibly_eligible_history_id_seq OWNED BY grit_ps_possibly_eligible_history.id;

      CREATE TABLE grit_ps_possibly_eligibles (
          id integer NOT NULL,
          master_id integer,
          any_questions_yes_no varchar,
          consent_to_pass_info_to_msm_yes_no varchar,
          consent_to_pass_info_to_msm_2_yes_no varchar,
          contact_info_notes varchar,
          follow_up_date date,
          follow_up_time time,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_ps_possibly_eligibles_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_ps_possibly_eligibles_id_seq OWNED BY grit_ps_possibly_eligibles.id;

      ALTER TABLE ONLY grit_ps_possibly_eligibles ALTER COLUMN id SET DEFAULT nextval('grit_ps_possibly_eligibles_id_seq'::regclass);
      ALTER TABLE ONLY grit_ps_possibly_eligible_history ALTER COLUMN id SET DEFAULT nextval('grit_ps_possibly_eligible_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_ps_possibly_eligible_history
          ADD CONSTRAINT grit_ps_possibly_eligible_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_ps_possibly_eligibles
          ADD CONSTRAINT grit_ps_possibly_eligibles_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_ps_possibly_eligible_history_on_master_id ON grit_ps_possibly_eligible_history USING btree (master_id);


      CREATE INDEX index_grit_ps_possibly_eligible_history_on_grit_ps_possibly_eligible_id ON grit_ps_possibly_eligible_history USING btree (grit_ps_possibly_eligible_id);
      CREATE INDEX index_grit_ps_possibly_eligible_history_on_user_id ON grit_ps_possibly_eligible_history USING btree (user_id);

      CREATE INDEX index_grit_ps_possibly_eligibles_on_master_id ON grit_ps_possibly_eligibles USING btree (master_id);

      CREATE INDEX index_grit_ps_possibly_eligibles_on_user_id ON grit_ps_possibly_eligibles USING btree (user_id);

      CREATE TRIGGER grit_ps_possibly_eligible_history_insert AFTER INSERT ON grit_ps_possibly_eligibles FOR EACH ROW EXECUTE PROCEDURE log_grit_ps_possibly_eligible_update();
      CREATE TRIGGER grit_ps_possibly_eligible_history_update AFTER UPDATE ON grit_ps_possibly_eligibles FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_ps_possibly_eligible_update();


      ALTER TABLE ONLY grit_ps_possibly_eligibles
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_ps_possibly_eligibles
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_ps_possibly_eligible_history
          ADD CONSTRAINT fk_grit_ps_possibly_eligible_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_ps_possibly_eligible_history
          ADD CONSTRAINT fk_grit_ps_possibly_eligible_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_ps_possibly_eligible_history
          ADD CONSTRAINT fk_grit_ps_possibly_eligible_history_grit_ps_possibly_eligibles FOREIGN KEY (grit_ps_possibly_eligible_id) REFERENCES grit_ps_possibly_eligibles(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
