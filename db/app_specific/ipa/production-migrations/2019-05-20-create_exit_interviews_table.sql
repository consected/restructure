set search_path=ipa_ops, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_exit_interviews select_all_results_returned notes labs_returned_yes_no labs_notes dexa_returned_yes_no dexa_notes brain_mri_returned_yes_no brain_mri_notes neuro_psych_returned_yes_no neuro_psych_notes other_notes

      CREATE or REPLACE FUNCTION log_ipa_exit_interview_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_exit_interview_history
                  (
                      master_id,
                      select_all_results_returned,
                      notes,
                      labs_returned_yes_no,
                      labs_notes,
                      dexa_returned_yes_no,
                      dexa_notes,
                      brain_mri_returned_yes_no,
                      brain_mri_notes,
                      neuro_psych_returned_yes_no,
                      neuro_psych_notes,
                      assisted_finding_provider_yes_no,
                      assistance_notes,
                      other_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_exit_interview_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_all_results_returned,
                      NEW.notes,
                      NEW.labs_returned_yes_no,
                      NEW.labs_notes,
                      NEW.dexa_returned_yes_no,
                      NEW.dexa_notes,
                      NEW.brain_mri_returned_yes_no,
                      NEW.brain_mri_notes,
                      NEW.neuro_psych_returned_yes_no,
                      NEW.neuro_psych_notes,
                      NEW.assisted_finding_provider_yes_no,
                      NEW.assistance_notes,
                      NEW.other_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_exit_interview_history (
          id integer NOT NULL,
          master_id integer,
          select_all_results_returned varchar,
          notes varchar,
          labs_returned_yes_no varchar,
          labs_notes varchar,
          dexa_returned_yes_no varchar,
          dexa_notes varchar,
          brain_mri_returned_yes_no varchar,
          brain_mri_notes varchar,
          neuro_psych_returned_yes_no varchar,
          neuro_psych_notes varchar,
          assisted_finding_provider_yes_no varchar,
          assistance_notes varchar,
          other_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_exit_interview_id integer
      );

      CREATE SEQUENCE ipa_exit_interview_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_exit_interview_history_id_seq OWNED BY ipa_exit_interview_history.id;

      CREATE TABLE ipa_exit_interviews (
          id integer NOT NULL,
          master_id integer,
          select_all_results_returned varchar,
          notes varchar,
          labs_returned_yes_no varchar,
          labs_notes varchar,
          dexa_returned_yes_no varchar,
          dexa_notes varchar,
          brain_mri_returned_yes_no varchar,
          brain_mri_notes varchar,
          neuro_psych_returned_yes_no varchar,
          neuro_psych_notes varchar,
          assisted_finding_provider_yes_no varchar,
          assistance_notes varchar,
          other_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_exit_interviews_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_exit_interviews_id_seq OWNED BY ipa_exit_interviews.id;

      ALTER TABLE ONLY ipa_exit_interviews ALTER COLUMN id SET DEFAULT nextval('ipa_exit_interviews_id_seq'::regclass);
      ALTER TABLE ONLY ipa_exit_interview_history ALTER COLUMN id SET DEFAULT nextval('ipa_exit_interview_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_exit_interview_history
          ADD CONSTRAINT ipa_exit_interview_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_exit_interviews
          ADD CONSTRAINT ipa_exit_interviews_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_exit_interview_history_on_master_id ON ipa_exit_interview_history USING btree (master_id);


      CREATE INDEX index_ipa_exit_interview_history_on_ipa_exit_interview_id ON ipa_exit_interview_history USING btree (ipa_exit_interview_id);
      CREATE INDEX index_ipa_exit_interview_history_on_user_id ON ipa_exit_interview_history USING btree (user_id);

      CREATE INDEX index_ipa_exit_interviews_on_master_id ON ipa_exit_interviews USING btree (master_id);

      CREATE INDEX index_ipa_exit_interviews_on_user_id ON ipa_exit_interviews USING btree (user_id);

      CREATE TRIGGER ipa_exit_interview_history_insert AFTER INSERT ON ipa_exit_interviews FOR EACH ROW EXECUTE PROCEDURE log_ipa_exit_interview_update();
      CREATE TRIGGER ipa_exit_interview_history_update AFTER UPDATE ON ipa_exit_interviews FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_exit_interview_update();


      ALTER TABLE ONLY ipa_exit_interviews
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_exit_interviews
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_exit_interview_history
          ADD CONSTRAINT fk_ipa_exit_interview_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_exit_interview_history
          ADD CONSTRAINT fk_ipa_exit_interview_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_exit_interview_history
          ADD CONSTRAINT fk_ipa_exit_interview_history_ipa_exit_interviews FOREIGN KEY (ipa_exit_interview_id) REFERENCES ipa_exit_interviews(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
