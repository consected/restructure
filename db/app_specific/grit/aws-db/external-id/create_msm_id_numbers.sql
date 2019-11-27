set search_path=grit, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh create external_identifiers_table

      CREATE FUNCTION log_msm_grit_id_number_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO msm_grit_id_number_history
                  (
                      master_id,
                      msm_grit_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      msm_grit_id_number_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.msm_grit_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;
      CREATE TABLE msm_grit_id_number_history (
          id integer NOT NULL,
          master_id integer,
          msm_grit_id varchar,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          msm_grit_id_number_table_id integer
      );

      CREATE SEQUENCE msm_grit_id_number_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE msm_grit_id_number_history_id_seq OWNED BY msm_grit_id_number_history.id;

      CREATE TABLE msm_grit_id_numbers (
          id integer NOT NULL,
          master_id integer,
          msm_grit_id varchar,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE msm_grit_id_numbers_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE msm_grit_id_numbers_id_seq OWNED BY msm_grit_id_numbers.id;

      ALTER TABLE ONLY msm_grit_id_numbers ALTER COLUMN id SET DEFAULT nextval('msm_grit_id_numbers_id_seq'::regclass);
      ALTER TABLE ONLY msm_grit_id_number_history ALTER COLUMN id SET DEFAULT nextval('msm_grit_id_number_history_id_seq'::regclass);

      ALTER TABLE ONLY msm_grit_id_number_history
          ADD CONSTRAINT msm_grit_id_number_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY msm_grit_id_numbers
          ADD CONSTRAINT msm_grit_id_numbers_pkey PRIMARY KEY (id);

      CREATE INDEX index_msm_grit_id_number_history_on_master_id ON msm_grit_id_number_history USING btree (master_id);
      CREATE INDEX index_msm_grit_id_number_history_on_msm_grit_id_number_table_id ON msm_grit_id_number_history USING btree (msm_grit_id_number_table_id);
      CREATE INDEX index_msm_grit_id_number_history_on_user_id ON msm_grit_id_number_history USING btree (user_id);
      CREATE INDEX index_msm_grit_id_number_history_on_admin_id ON msm_grit_id_number_history USING btree (admin_id);

      CREATE INDEX index_msm_grit_id_numbers_on_master_id ON msm_grit_id_numbers USING btree (master_id);
      CREATE INDEX index_msm_grit_id_numbers_on_user_id ON msm_grit_id_numbers USING btree (user_id);
      CREATE INDEX index_msm_grit_id_numbers_on_admin_id ON msm_grit_id_numbers USING btree (admin_id);

      CREATE TRIGGER msm_grit_id_number_history_insert AFTER INSERT ON msm_grit_id_numbers FOR EACH ROW EXECUTE PROCEDURE log_msm_grit_id_number_update();
      CREATE TRIGGER msm_grit_id_number_history_update AFTER UPDATE ON msm_grit_id_numbers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_msm_grit_id_number_update();


      ALTER TABLE ONLY msm_grit_id_numbers
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY msm_grit_id_numbers
          ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY msm_grit_id_numbers
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


      ALTER TABLE ONLY msm_grit_id_number_history
          ADD CONSTRAINT fk_msm_grit_id_number_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY msm_grit_id_number_history
          ADD CONSTRAINT fk_msm_grit_id_number_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY msm_grit_id_number_history
          ADD CONSTRAINT fk_msm_grit_id_number_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY msm_grit_id_number_history
          ADD CONSTRAINT fk_msm_grit_id_number_history_msm_grit_id_numbers FOREIGN KEY (msm_grit_id_number_table_id) REFERENCES msm_grit_id_numbers(id);


      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
