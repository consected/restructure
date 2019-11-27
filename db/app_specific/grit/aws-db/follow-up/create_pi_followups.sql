set search_path=grit, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_pi_followups pre_call_notes call_notes

      CREATE FUNCTION log_grit_pi_followup_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO grit_pi_followup_history
                  (
                      master_id,
                      pre_call_notes,
                      call_notes,
                      user_id,
                      created_at,
                      updated_at,
                      grit_pi_followup_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.pre_call_notes,
                      NEW.call_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE grit_pi_followup_history (
          id integer NOT NULL,
          master_id integer,
          pre_call_notes varchar,
          call_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_pi_followup_id integer
      );

      CREATE SEQUENCE grit_pi_followup_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_pi_followup_history_id_seq OWNED BY grit_pi_followup_history.id;

      CREATE TABLE grit_pi_followups (
          id integer NOT NULL,
          master_id integer,
          pre_call_notes varchar,
          call_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_pi_followups_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_pi_followups_id_seq OWNED BY grit_pi_followups.id;

      ALTER TABLE ONLY grit_pi_followups ALTER COLUMN id SET DEFAULT nextval('grit_pi_followups_id_seq'::regclass);
      ALTER TABLE ONLY grit_pi_followup_history ALTER COLUMN id SET DEFAULT nextval('grit_pi_followup_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_pi_followup_history
          ADD CONSTRAINT grit_pi_followup_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_pi_followups
          ADD CONSTRAINT grit_pi_followups_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_pi_followup_history_on_master_id ON grit_pi_followup_history USING btree (master_id);


      CREATE INDEX index_grit_pi_followup_history_on_grit_pi_followup_id ON grit_pi_followup_history USING btree (grit_pi_followup_id);
      CREATE INDEX index_grit_pi_followup_history_on_user_id ON grit_pi_followup_history USING btree (user_id);

      CREATE INDEX index_grit_pi_followups_on_master_id ON grit_pi_followups USING btree (master_id);

      CREATE INDEX index_grit_pi_followups_on_user_id ON grit_pi_followups USING btree (user_id);

      CREATE TRIGGER grit_pi_followup_history_insert AFTER INSERT ON grit_pi_followups FOR EACH ROW EXECUTE PROCEDURE log_grit_pi_followup_update();
      CREATE TRIGGER grit_pi_followup_history_update AFTER UPDATE ON grit_pi_followups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_pi_followup_update();


      ALTER TABLE ONLY grit_pi_followups
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_pi_followups
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_pi_followup_history
          ADD CONSTRAINT fk_grit_pi_followup_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_pi_followup_history
          ADD CONSTRAINT fk_grit_pi_followup_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_pi_followup_history
          ADD CONSTRAINT fk_grit_pi_followup_history_grit_pi_followups FOREIGN KEY (grit_pi_followup_id) REFERENCES grit_pi_followups(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
