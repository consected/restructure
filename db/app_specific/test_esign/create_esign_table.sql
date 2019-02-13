
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create e_signatures e_signed_document e_signed_how e_signed_at e_signed_by e_signed_code

      CREATE FUNCTION log_e_signature_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO e_signature_history
                  (
                      master_id,
                      e_signed_document,
                      e_signed_how,
                      e_signed_at,
                      e_signed_by,
                      e_signed_code,
                      user_id,
                      created_at,
                      updated_at,
                      e_signature_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.e_signed_document,
                      NEW.e_signed_how,
                      NEW.e_signed_at,
                      NEW.e_signed_by,
                      NEW.e_signed_code,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE e_signature_history (
          id integer NOT NULL,
          master_id integer,
          e_signed_document varchar,
          e_signed_how varchar,
          e_signed_at timestamp,
          e_signed_by varchar,
          e_signed_code varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          e_signature_id integer
      );

      CREATE SEQUENCE e_signature_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE e_signature_history_id_seq OWNED BY e_signature_history.id;

      CREATE TABLE e_signatures (
          id integer NOT NULL,
          master_id integer,
          e_signed_document varchar,
          e_signed_how varchar,
          e_signed_at timestamp,
          e_signed_by varchar,
          e_signed_code varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE e_signatures_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE e_signatures_id_seq OWNED BY e_signatures.id;

      ALTER TABLE ONLY e_signatures ALTER COLUMN id SET DEFAULT nextval('e_signatures_id_seq'::regclass);
      ALTER TABLE ONLY e_signature_history ALTER COLUMN id SET DEFAULT nextval('e_signature_history_id_seq'::regclass);

      ALTER TABLE ONLY e_signature_history
          ADD CONSTRAINT e_signature_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY e_signatures
          ADD CONSTRAINT e_signatures_pkey PRIMARY KEY (id);

      CREATE INDEX index_e_signature_history_on_master_id ON e_signature_history USING btree (master_id);


      CREATE INDEX index_e_signature_history_on_e_signature_id ON e_signature_history USING btree (e_signature_id);
      CREATE INDEX index_e_signature_history_on_user_id ON e_signature_history USING btree (user_id);

      CREATE INDEX index_e_signatures_on_master_id ON e_signatures USING btree (master_id);

      CREATE INDEX index_e_signatures_on_user_id ON e_signatures USING btree (user_id);

      CREATE TRIGGER e_signature_history_insert AFTER INSERT ON e_signatures FOR EACH ROW EXECUTE PROCEDURE log_e_signature_update();
      CREATE TRIGGER e_signature_history_update AFTER UPDATE ON e_signatures FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_e_signature_update();


      ALTER TABLE ONLY e_signatures
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY e_signatures
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY e_signature_history
          ADD CONSTRAINT fk_e_signature_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY e_signature_history
          ADD CONSTRAINT fk_e_signature_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY e_signature_history
          ADD CONSTRAINT fk_e_signature_history_e_signatures FOREIGN KEY (e_signature_id) REFERENCES e_signatures(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
