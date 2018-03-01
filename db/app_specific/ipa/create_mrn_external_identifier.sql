
      BEGIN;

      CREATE FUNCTION log_mrn_number_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO mrn_number_history
                  (
                      master_id,
                      mrn_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      mrn_number_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.mrn_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;
      CREATE TABLE mrn_number_history (
          id integer NOT NULL,
          master_id integer,
          mrn_id varchar,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          mrn_number_table_id integer
      );

      CREATE SEQUENCE mrn_number_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE mrn_number_history_id_seq OWNED BY mrn_number_history.id;

      CREATE TABLE mrn_numbers (
          id integer NOT NULL,
          master_id integer,
          mrn_id varchar,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE mrn_numbers_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE mrn_numbers_id_seq OWNED BY mrn_numbers.id;

      ALTER TABLE ONLY mrn_numbers ALTER COLUMN id SET DEFAULT nextval('mrn_numbers_id_seq'::regclass);
      ALTER TABLE ONLY mrn_number_history ALTER COLUMN id SET DEFAULT nextval('mrn_number_history_id_seq'::regclass);

      ALTER TABLE ONLY mrn_number_history
          ADD CONSTRAINT mrn_number_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY mrn_numbers
          ADD CONSTRAINT mrn_numbers_pkey PRIMARY KEY (id);

      CREATE INDEX index_mrn_number_history_on_master_id ON mrn_number_history USING btree (master_id);
      CREATE INDEX index_mrn_number_history_on_mrn_number_table_id ON mrn_number_history USING btree (mrn_number_table_id);
      CREATE INDEX index_mrn_number_history_on_user_id ON mrn_number_history USING btree (user_id);
      CREATE INDEX index_mrn_number_history_on_admin_id ON mrn_number_history USING btree (admin_id);

      CREATE INDEX index_mrn_numbers_on_master_id ON mrn_numbers USING btree (master_id);
      CREATE INDEX index_mrn_numbers_on_user_id ON mrn_numbers USING btree (user_id);
      CREATE INDEX index_mrn_numbers_on_admin_id ON mrn_numbers USING btree (admin_id);

      CREATE TRIGGER mrn_number_history_insert AFTER INSERT ON mrn_numbers FOR EACH ROW EXECUTE PROCEDURE log_mrn_number_update();
      CREATE TRIGGER mrn_number_history_update AFTER UPDATE ON mrn_numbers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_mrn_number_update();


      ALTER TABLE ONLY mrn_numbers
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY mrn_numbers
          ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY mrn_numbers
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


      ALTER TABLE ONLY mrn_number_history
          ADD CONSTRAINT fk_mrn_number_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY mrn_number_history
          ADD CONSTRAINT fk_mrn_number_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY mrn_number_history
          ADD CONSTRAINT fk_mrn_number_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY mrn_number_history
          ADD CONSTRAINT fk_mrn_number_history_mrn_numbers FOREIGN KEY (mrn_number_table_id) REFERENCES mrn_numbers(id);


      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
