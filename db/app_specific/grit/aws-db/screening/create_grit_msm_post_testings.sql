set search_path=grit, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_msm_post_testings session_type session_date notes

      CREATE FUNCTION log_grit_msm_post_testing_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO grit_msm_post_testing_history
                  (
                      master_id,
                      session_type,
                      session_date,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      grit_msm_post_testing_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.session_type,
                      NEW.session_date,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE grit_msm_post_testing_history (
          id integer NOT NULL,
          master_id integer,
          session_type varchar,
          session_date date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_msm_post_testing_id integer
      );

      CREATE SEQUENCE grit_msm_post_testing_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_msm_post_testing_history_id_seq OWNED BY grit_msm_post_testing_history.id;

      CREATE TABLE grit_msm_post_testings (
          id integer NOT NULL,
          master_id integer,
          session_type varchar,
          session_date date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_msm_post_testings_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_msm_post_testings_id_seq OWNED BY grit_msm_post_testings.id;

      ALTER TABLE ONLY grit_msm_post_testings ALTER COLUMN id SET DEFAULT nextval('grit_msm_post_testings_id_seq'::regclass);
      ALTER TABLE ONLY grit_msm_post_testing_history ALTER COLUMN id SET DEFAULT nextval('grit_msm_post_testing_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_msm_post_testing_history
          ADD CONSTRAINT grit_msm_post_testing_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_msm_post_testings
          ADD CONSTRAINT grit_msm_post_testings_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_msm_post_testing_history_on_master_id ON grit_msm_post_testing_history USING btree (master_id);


      CREATE INDEX index_grit_msm_post_testing_history_on_grit_msm_post_testing_id ON grit_msm_post_testing_history USING btree (grit_msm_post_testing_id);
      CREATE INDEX index_grit_msm_post_testing_history_on_user_id ON grit_msm_post_testing_history USING btree (user_id);

      CREATE INDEX index_grit_msm_post_testings_on_master_id ON grit_msm_post_testings USING btree (master_id);

      CREATE INDEX index_grit_msm_post_testings_on_user_id ON grit_msm_post_testings USING btree (user_id);

      CREATE TRIGGER grit_msm_post_testing_history_insert AFTER INSERT ON grit_msm_post_testings FOR EACH ROW EXECUTE PROCEDURE log_grit_msm_post_testing_update();
      CREATE TRIGGER grit_msm_post_testing_history_update AFTER UPDATE ON grit_msm_post_testings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_msm_post_testing_update();


      ALTER TABLE ONLY grit_msm_post_testings
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_msm_post_testings
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_msm_post_testing_history
          ADD CONSTRAINT fk_grit_msm_post_testing_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_msm_post_testing_history
          ADD CONSTRAINT fk_grit_msm_post_testing_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_msm_post_testing_history
          ADD CONSTRAINT fk_grit_msm_post_testing_history_grit_msm_post_testings FOREIGN KEY (grit_msm_post_testing_id) REFERENCES grit_msm_post_testings(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
