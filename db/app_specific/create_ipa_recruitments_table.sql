
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_recruitments rank

      CREATE FUNCTION log_ipa_recruitment_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_recruitment_history
                  (
                      master_id,
                      rank,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_recruitment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.rank,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_recruitment_history (
          id integer NOT NULL,
          master_id integer,
          rank varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_recruitment_id integer
      );

      CREATE SEQUENCE ipa_recruitment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_recruitment_history_id_seq OWNED BY ipa_recruitment_history.id;

      CREATE TABLE ipa_recruitments (
          id integer NOT NULL,
          master_id integer,
          rank varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_recruitments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_recruitments_id_seq OWNED BY ipa_recruitments.id;

      ALTER TABLE ONLY ipa_recruitments ALTER COLUMN id SET DEFAULT nextval('ipa_recruitments_id_seq'::regclass);
      ALTER TABLE ONLY ipa_recruitment_history ALTER COLUMN id SET DEFAULT nextval('ipa_recruitment_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_recruitment_history
          ADD CONSTRAINT ipa_recruitment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_recruitments
          ADD CONSTRAINT ipa_recruitments_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_recruitment_history_on_master_id ON ipa_recruitment_history USING btree (master_id);


      CREATE INDEX index_ipa_recruitment_history_on_ipa_recruitment_id ON ipa_recruitment_history USING btree (ipa_recruitment_id);
      CREATE INDEX index_ipa_recruitment_history_on_user_id ON ipa_recruitment_history USING btree (user_id);

      CREATE INDEX index_ipa_recruitments_on_master_id ON ipa_recruitments USING btree (master_id);

      CREATE INDEX index_ipa_recruitments_on_user_id ON ipa_recruitments USING btree (user_id);

      CREATE TRIGGER ipa_recruitment_history_insert AFTER INSERT ON ipa_recruitments FOR EACH ROW EXECUTE PROCEDURE log_ipa_recruitment_update();
      CREATE TRIGGER ipa_recruitment_history_update AFTER UPDATE ON ipa_recruitments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_recruitment_update();


      ALTER TABLE ONLY ipa_recruitments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_recruitments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_recruitment_history
          ADD CONSTRAINT fk_ipa_recruitment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_recruitment_history
          ADD CONSTRAINT fk_ipa_recruitment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_recruitment_history
          ADD CONSTRAINT fk_ipa_recruitment_history_ipa_recruitments FOREIGN KEY (ipa_recruitment_id) REFERENCES ipa_recruitments(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
