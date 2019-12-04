set search_path=grit, ml_app;


      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_ps_eligibility_followups outcome any_questions_yes_no notes interested_yes_no not_interested_notes contact_pi_yes_no additional_questions_yes_no consent_to_pass_info_to_msm_yes_no consent_to_pass_info_to_msm_2_yes_no contact_info_notes more_questions_yes_no more_questions_notes select_still_interested

      CREATE FUNCTION log_grit_ps_eligibility_followup_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO grit_ps_eligibility_followup_history
                  (
                      master_id,
                      outcome,
                      any_questions_yes_no,
                      notes,
                      interested_yes_no,
                      not_interested_notes,
                      contact_pi_yes_no,
                      additional_questions_yes_no,
                      consent_to_pass_info_to_msm_yes_no,
                      consent_to_pass_info_to_msm_2_yes_no,
                      contact_info_notes,
                      more_questions_yes_no,
                      more_questions_notes,
                      select_still_interested,
                      user_id,
                      created_at,
                      updated_at,
                      grit_ps_eligibility_followup_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.outcome,
                      NEW.any_questions_yes_no,
                      NEW.notes,
                      NEW.interested_yes_no,
                      NEW.not_interested_notes,
                      NEW.contact_pi_yes_no,
                      NEW.additional_questions_yes_no,
                      NEW.consent_to_pass_info_to_msm_yes_no,
                      NEW.consent_to_pass_info_to_msm_2_yes_no,
                      NEW.contact_info_notes,
                      NEW.more_questions_yes_no,
                      NEW.more_questions_notes,
                      NEW.select_still_interested,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE grit_ps_eligibility_followup_history (
          id integer NOT NULL,
          master_id integer,
          outcome varchar,
          any_questions_yes_no varchar,
          notes varchar,
          interested_yes_no varchar,
          not_interested_notes varchar,
          contact_pi_yes_no varchar,
          additional_questions_yes_no varchar,
          consent_to_pass_info_to_msm_yes_no varchar,
          consent_to_pass_info_to_msm_2_yes_no varchar,
          contact_info_notes varchar,
          more_questions_yes_no varchar,
          more_questions_notes varchar,
          select_still_interested varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_ps_eligibility_followup_id integer
      );

      CREATE SEQUENCE grit_ps_eligibility_followup_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_ps_eligibility_followup_history_id_seq OWNED BY grit_ps_eligibility_followup_history.id;

      CREATE TABLE grit_ps_eligibility_followups (
          id integer NOT NULL,
          master_id integer,
          outcome varchar,
          any_questions_yes_no varchar,
          notes varchar,
          interested_yes_no varchar,
          not_interested_notes varchar,
          contact_pi_yes_no varchar,
          additional_questions_yes_no varchar,
          consent_to_pass_info_to_msm_yes_no varchar,
          consent_to_pass_info_to_msm_2_yes_no varchar,
          contact_info_notes varchar,
          more_questions_yes_no varchar,
          more_questions_notes varchar,
          select_still_interested varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_ps_eligibility_followups_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_ps_eligibility_followups_id_seq OWNED BY grit_ps_eligibility_followups.id;

      ALTER TABLE ONLY grit_ps_eligibility_followups ALTER COLUMN id SET DEFAULT nextval('grit_ps_eligibility_followups_id_seq'::regclass);
      ALTER TABLE ONLY grit_ps_eligibility_followup_history ALTER COLUMN id SET DEFAULT nextval('grit_ps_eligibility_followup_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_ps_eligibility_followup_history
          ADD CONSTRAINT grit_ps_eligibility_followup_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_ps_eligibility_followups
          ADD CONSTRAINT grit_ps_eligibility_followups_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_ps_eligibility_followup_history_on_master_id ON grit_ps_eligibility_followup_history USING btree (master_id);


      CREATE INDEX index_grit_ps_eligibility_followup_history_on_grit_ps_eligibility_followup_id ON grit_ps_eligibility_followup_history USING btree (grit_ps_eligibility_followup_id);
      CREATE INDEX index_grit_ps_eligibility_followup_history_on_user_id ON grit_ps_eligibility_followup_history USING btree (user_id);

      CREATE INDEX index_grit_ps_eligibility_followups_on_master_id ON grit_ps_eligibility_followups USING btree (master_id);

      CREATE INDEX index_grit_ps_eligibility_followups_on_user_id ON grit_ps_eligibility_followups USING btree (user_id);

      CREATE TRIGGER grit_ps_eligibility_followup_history_insert AFTER INSERT ON grit_ps_eligibility_followups FOR EACH ROW EXECUTE PROCEDURE log_grit_ps_eligibility_followup_update();
      CREATE TRIGGER grit_ps_eligibility_followup_history_update AFTER UPDATE ON grit_ps_eligibility_followups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_ps_eligibility_followup_update();


      ALTER TABLE ONLY grit_ps_eligibility_followups
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_ps_eligibility_followups
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_ps_eligibility_followup_history
          ADD CONSTRAINT fk_grit_ps_eligibility_followup_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_ps_eligibility_followup_history
          ADD CONSTRAINT fk_grit_ps_eligibility_followup_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_ps_eligibility_followup_history
          ADD CONSTRAINT fk_grit_ps_eligibility_followup_history_grit_ps_eligibility_followups FOREIGN KEY (grit_ps_eligibility_followup_id) REFERENCES grit_ps_eligibility_followups(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
