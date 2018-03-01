
      BEGIN;

      CREATE FUNCTION log_social_security_number_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO social_security_number_history
                  (
                      master_id,
                      ssn_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      social_security_number_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ssn_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;
      CREATE TABLE social_security_number_history (
          id integer NOT NULL,
          master_id integer,
          ssn_id varchar,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          social_security_number_table_id integer
      );

      CREATE SEQUENCE social_security_number_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE social_security_number_history_id_seq OWNED BY social_security_number_history.id;

      CREATE TABLE social_security_numbers (
          id integer NOT NULL,
          master_id integer,
          ssn_id varchar,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE social_security_numbers_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE social_security_numbers_id_seq OWNED BY social_security_numbers.id;

      ALTER TABLE ONLY social_security_numbers ALTER COLUMN id SET DEFAULT nextval('social_security_numbers_id_seq'::regclass);
      ALTER TABLE ONLY social_security_number_history ALTER COLUMN id SET DEFAULT nextval('social_security_number_history_id_seq'::regclass);

      ALTER TABLE ONLY social_security_number_history
          ADD CONSTRAINT social_security_number_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY social_security_numbers
          ADD CONSTRAINT social_security_numbers_pkey PRIMARY KEY (id);

      CREATE INDEX index_social_security_number_history_on_master_id ON social_security_number_history USING btree (master_id);
      CREATE INDEX index_social_security_number_history_on_social_security_number_table_id ON social_security_number_history USING btree (social_security_number_table_id);
      CREATE INDEX index_social_security_number_history_on_user_id ON social_security_number_history USING btree (user_id);
      CREATE INDEX index_social_security_number_history_on_admin_id ON social_security_number_history USING btree (admin_id);

      CREATE INDEX index_social_security_numbers_on_master_id ON social_security_numbers USING btree (master_id);
      CREATE INDEX index_social_security_numbers_on_user_id ON social_security_numbers USING btree (user_id);
      CREATE INDEX index_social_security_numbers_on_admin_id ON social_security_numbers USING btree (admin_id);

      CREATE TRIGGER social_security_number_history_insert AFTER INSERT ON social_security_numbers FOR EACH ROW EXECUTE PROCEDURE log_social_security_number_update();
      CREATE TRIGGER social_security_number_history_update AFTER UPDATE ON social_security_numbers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_social_security_number_update();


      ALTER TABLE ONLY social_security_numbers
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY social_security_numbers
          ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY social_security_numbers
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


      ALTER TABLE ONLY social_security_number_history
          ADD CONSTRAINT fk_social_security_number_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY social_security_number_history
          ADD CONSTRAINT fk_social_security_number_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY social_security_number_history
          ADD CONSTRAINT fk_social_security_number_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY social_security_number_history
          ADD CONSTRAINT fk_social_security_number_history_social_security_numbers FOREIGN KEY (social_security_number_table_id) REFERENCES social_security_numbers(id);


      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
