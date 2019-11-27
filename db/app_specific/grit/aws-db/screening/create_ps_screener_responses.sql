set search_path=grit, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_ps_screener_responses comm_clearly_in_english_yes_no give_informed_consent_yes_no_dont_know give_informed_consent_notes notes

      CREATE or REPLACE FUNCTION log_grit_ps_screener_response_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO grit_ps_screener_response_history
                  (
                      master_id,
                      outcome,
                      comm_clearly_in_english_yes_no,
                      give_informed_consent_yes_no_dont_know,
                      give_informed_consent_notes,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      grit_ps_screener_response_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.outcome,
                      NEW.comm_clearly_in_english_yes_no,
                      NEW.give_informed_consent_yes_no_dont_know,
                      NEW.give_informed_consent_notes,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE grit_ps_screener_response_history (
          id integer NOT NULL,
          master_id integer,
          outcome varchar,
          comm_clearly_in_english_yes_no varchar,
          give_informed_consent_yes_no_dont_know varchar,
          give_informed_consent_notes varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_ps_screener_response_id integer
      );

      CREATE SEQUENCE grit_ps_screener_response_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_ps_screener_response_history_id_seq OWNED BY grit_ps_screener_response_history.id;

      CREATE TABLE grit_ps_screener_responses (
          id integer NOT NULL,
          master_id integer,
          outcome varchar,
          comm_clearly_in_english_yes_no varchar,
          give_informed_consent_yes_no_dont_know varchar,
          give_informed_consent_notes varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_ps_screener_responses_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_ps_screener_responses_id_seq OWNED BY grit_ps_screener_responses.id;

      ALTER TABLE ONLY grit_ps_screener_responses ALTER COLUMN id SET DEFAULT nextval('grit_ps_screener_responses_id_seq'::regclass);
      ALTER TABLE ONLY grit_ps_screener_response_history ALTER COLUMN id SET DEFAULT nextval('grit_ps_screener_response_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_ps_screener_response_history
          ADD CONSTRAINT grit_ps_screener_response_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_ps_screener_responses
          ADD CONSTRAINT grit_ps_screener_responses_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_ps_screener_response_history_on_master_id ON grit_ps_screener_response_history USING btree (master_id);


      CREATE INDEX index_grit_ps_screener_response_history_on_grit_ps_screener_response_id ON grit_ps_screener_response_history USING btree (grit_ps_screener_response_id);
      CREATE INDEX index_grit_ps_screener_response_history_on_user_id ON grit_ps_screener_response_history USING btree (user_id);

      CREATE INDEX index_grit_ps_screener_responses_on_master_id ON grit_ps_screener_responses USING btree (master_id);

      CREATE INDEX index_grit_ps_screener_responses_on_user_id ON grit_ps_screener_responses USING btree (user_id);

      CREATE TRIGGER grit_ps_screener_response_history_insert AFTER INSERT ON grit_ps_screener_responses FOR EACH ROW EXECUTE PROCEDURE log_grit_ps_screener_response_update();
      CREATE TRIGGER grit_ps_screener_response_history_update AFTER UPDATE ON grit_ps_screener_responses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_ps_screener_response_update();


      ALTER TABLE ONLY grit_ps_screener_responses
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_ps_screener_responses
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_ps_screener_response_history
          ADD CONSTRAINT fk_grit_ps_screener_response_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_ps_screener_response_history
          ADD CONSTRAINT fk_grit_ps_screener_response_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_ps_screener_response_history
          ADD CONSTRAINT fk_grit_ps_screener_response_history_grit_ps_screener_responses FOREIGN KEY (grit_ps_screener_response_id) REFERENCES grit_ps_screener_responses(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
