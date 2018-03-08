
      BEGIN;

      CREATE FUNCTION log_ipa_consent_mailing_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_consent_mailing_history
                  (
                      master_id,
                      copy_of_consent_docs_mailed_to_subject_no_yes,
                      mailed_when,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_consent_mailing_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.copy_of_consent_docs_mailed_to_subject_no_yes,
                      NEW.mailed_when,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_consent_mailing_history (
          id integer NOT NULL,
          master_id integer,
          copy_of_consent_docs_mailed_to_subject_no_yes varchar,
          mailed_when date,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_consent_mailing_id integer
      );

      CREATE SEQUENCE ipa_consent_mailing_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_consent_mailing_history_id_seq OWNED BY ipa_consent_mailing_history.id;

      CREATE TABLE ipa_consent_mailings (
          id integer NOT NULL,
          master_id integer,
          copy_of_consent_docs_mailed_to_subject_no_yes varchar,
          mailed_when date,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_consent_mailings_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_consent_mailings_id_seq OWNED BY ipa_consent_mailings.id;

      ALTER TABLE ONLY ipa_consent_mailings ALTER COLUMN id SET DEFAULT nextval('ipa_consent_mailings_id_seq'::regclass);
      ALTER TABLE ONLY ipa_consent_mailing_history ALTER COLUMN id SET DEFAULT nextval('ipa_consent_mailing_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_consent_mailing_history
          ADD CONSTRAINT ipa_consent_mailing_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_consent_mailings
          ADD CONSTRAINT ipa_consent_mailings_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_consent_mailing_history_on_master_id ON ipa_consent_mailing_history USING btree (master_id);


      CREATE INDEX index_ipa_consent_mailing_history_on_ipa_consent_mailing_id ON ipa_consent_mailing_history USING btree (ipa_consent_mailing_id);
      CREATE INDEX index_ipa_consent_mailing_history_on_user_id ON ipa_consent_mailing_history USING btree (user_id);

      CREATE INDEX index_ipa_consent_mailings_on_master_id ON ipa_consent_mailings USING btree (master_id);

      CREATE INDEX index_ipa_consent_mailings_on_user_id ON ipa_consent_mailings USING btree (user_id);

      CREATE TRIGGER ipa_consent_mailing_history_insert AFTER INSERT ON ipa_consent_mailings FOR EACH ROW EXECUTE PROCEDURE log_ipa_consent_mailing_update();
      CREATE TRIGGER ipa_consent_mailing_history_update AFTER UPDATE ON ipa_consent_mailings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_consent_mailing_update();


      ALTER TABLE ONLY ipa_consent_mailings
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_consent_mailings
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_consent_mailing_history
          ADD CONSTRAINT fk_ipa_consent_mailing_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_consent_mailing_history
          ADD CONSTRAINT fk_ipa_consent_mailing_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_consent_mailing_history
          ADD CONSTRAINT fk_ipa_consent_mailing_history_ipa_consent_mailings FOREIGN KEY (ipa_consent_mailing_id) REFERENCES ipa_consent_mailings(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
