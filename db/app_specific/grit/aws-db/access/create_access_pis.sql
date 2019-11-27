set search_path=grit, ml_app;
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_access_pis assign_access_to_user_id

      CREATE FUNCTION log_grit_access_pi_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO grit_access_pi_history
                  (
                      master_id,
                      -- assign_access_to_user_id,
                      user_id,
                      created_at,
                      updated_at,
                      grit_access_pi_id
                      )
                  SELECT
                      NEW.master_id,
                      -- NEW.assign_access_to_user_id,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE grit_access_pi_history (
          id integer NOT NULL,
          master_id integer,
          -- assign_access_to_user_id bigint,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_access_pi_id integer
      );

      CREATE SEQUENCE grit_access_pi_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_access_pi_history_id_seq OWNED BY grit_access_pi_history.id;

      CREATE TABLE grit_access_pis (
          id integer NOT NULL,
          master_id integer,
          -- assign_access_to_user_id bigint,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_access_pis_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_access_pis_id_seq OWNED BY grit_access_pis.id;

      ALTER TABLE ONLY grit_access_pis ALTER COLUMN id SET DEFAULT nextval('grit_access_pis_id_seq'::regclass);
      ALTER TABLE ONLY grit_access_pi_history ALTER COLUMN id SET DEFAULT nextval('grit_access_pi_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_access_pi_history
          ADD CONSTRAINT grit_access_pi_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_access_pis
          ADD CONSTRAINT grit_access_pis_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_access_pi_history_on_master_id ON grit_access_pi_history USING btree (master_id);


      CREATE INDEX index_grit_access_pi_history_on_grit_access_pi_id ON grit_access_pi_history USING btree (grit_access_pi_id);
      CREATE INDEX index_grit_access_pi_history_on_user_id ON grit_access_pi_history USING btree (user_id);

      CREATE INDEX index_grit_access_pis_on_master_id ON grit_access_pis USING btree (master_id);

      CREATE INDEX index_grit_access_pis_on_user_id ON grit_access_pis USING btree (user_id);

      CREATE TRIGGER grit_access_pi_history_insert AFTER INSERT ON grit_access_pis FOR EACH ROW EXECUTE PROCEDURE log_grit_access_pi_update();
      CREATE TRIGGER grit_access_pi_history_update AFTER UPDATE ON grit_access_pis FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_access_pi_update();


      ALTER TABLE ONLY grit_access_pis
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_access_pis
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_access_pi_history
          ADD CONSTRAINT fk_grit_access_pi_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_access_pi_history
          ADD CONSTRAINT fk_grit_access_pi_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_access_pi_history
          ADD CONSTRAINT fk_grit_access_pi_history_grit_access_pis FOREIGN KEY (grit_access_pi_id) REFERENCES grit_access_pis(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
