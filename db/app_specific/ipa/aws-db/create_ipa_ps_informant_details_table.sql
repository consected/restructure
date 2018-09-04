
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_ps_informant_details informant_name relationship_to_participant contact_information_notes

      CREATE FUNCTION log_ipa_ps_informant_detail_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_ps_informant_detail_history
                  (
                      master_id,
                      informant_name,
                      relationship_to_participant,
                      contact_information_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_informant_detail_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.informant_name,
                      NEW.relationship_to_participant,
                      NEW.contact_information_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_ps_informant_detail_history (
          id integer NOT NULL,
          master_id integer,
          informant_name varchar,
          relationship_to_participant varchar,
          contact_information_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_ps_informant_detail_id integer
      );

      CREATE SEQUENCE ipa_ps_informant_detail_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_informant_detail_history_id_seq OWNED BY ipa_ps_informant_detail_history.id;

      CREATE TABLE ipa_ps_informant_details (
          id integer NOT NULL,
          master_id integer,
          informant_name varchar,
          relationship_to_participant varchar,
          contact_information_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_ps_informant_details_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_informant_details_id_seq OWNED BY ipa_ps_informant_details.id;

      ALTER TABLE ONLY ipa_ps_informant_details ALTER COLUMN id SET DEFAULT nextval('ipa_ps_informant_details_id_seq'::regclass);
      ALTER TABLE ONLY ipa_ps_informant_detail_history ALTER COLUMN id SET DEFAULT nextval('ipa_ps_informant_detail_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_ps_informant_detail_history
          ADD CONSTRAINT ipa_ps_informant_detail_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_ps_informant_details
          ADD CONSTRAINT ipa_ps_informant_details_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_ps_informant_detail_history_on_master_id ON ipa_ps_informant_detail_history USING btree (master_id);


      CREATE INDEX index_ipa_ps_informant_detail_history_on_ipa_ps_informant_detail_id ON ipa_ps_informant_detail_history USING btree (ipa_ps_informant_detail_id);
      CREATE INDEX index_ipa_ps_informant_detail_history_on_user_id ON ipa_ps_informant_detail_history USING btree (user_id);

      CREATE INDEX index_ipa_ps_informant_details_on_master_id ON ipa_ps_informant_details USING btree (master_id);

      CREATE INDEX index_ipa_ps_informant_details_on_user_id ON ipa_ps_informant_details USING btree (user_id);

      CREATE TRIGGER ipa_ps_informant_detail_history_insert AFTER INSERT ON ipa_ps_informant_details FOR EACH ROW EXECUTE PROCEDURE log_ipa_ps_informant_detail_update();
      CREATE TRIGGER ipa_ps_informant_detail_history_update AFTER UPDATE ON ipa_ps_informant_details FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_ps_informant_detail_update();


      ALTER TABLE ONLY ipa_ps_informant_details
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_ps_informant_details
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_ps_informant_detail_history
          ADD CONSTRAINT fk_ipa_ps_informant_detail_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_ps_informant_detail_history
          ADD CONSTRAINT fk_ipa_ps_informant_detail_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_ps_informant_detail_history
          ADD CONSTRAINT fk_ipa_ps_informant_detail_history_ipa_ps_informant_details FOREIGN KEY (ipa_ps_informant_detail_id) REFERENCES ipa_ps_informant_details(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
