set search_path=grit, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_msm_screening_details screening_date select_status notes

      CREATE FUNCTION log_grit_msm_screening_detail_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO grit_msm_screening_detail_history
                  (
                      master_id,
                      screening_date,
                      select_status,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      grit_msm_screening_detail_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.screening_date,
                      NEW.select_status,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE grit_msm_screening_detail_history (
          id integer NOT NULL,
          master_id integer,
          screening_date date,
          select_status varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_msm_screening_detail_id integer
      );

      CREATE SEQUENCE grit_msm_screening_detail_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_msm_screening_detail_history_id_seq OWNED BY grit_msm_screening_detail_history.id;

      CREATE TABLE grit_msm_screening_details (
          id integer NOT NULL,
          master_id integer,
          screening_date date,
          select_status varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_msm_screening_details_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_msm_screening_details_id_seq OWNED BY grit_msm_screening_details.id;

      ALTER TABLE ONLY grit_msm_screening_details ALTER COLUMN id SET DEFAULT nextval('grit_msm_screening_details_id_seq'::regclass);
      ALTER TABLE ONLY grit_msm_screening_detail_history ALTER COLUMN id SET DEFAULT nextval('grit_msm_screening_detail_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_msm_screening_detail_history
          ADD CONSTRAINT grit_msm_screening_detail_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_msm_screening_details
          ADD CONSTRAINT grit_msm_screening_details_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_msm_screening_detail_history_on_master_id ON grit_msm_screening_detail_history USING btree (master_id);


      CREATE INDEX index_grit_msm_screening_detail_history_on_grit_msm_screening_detail_id ON grit_msm_screening_detail_history USING btree (grit_msm_screening_detail_id);
      CREATE INDEX index_grit_msm_screening_detail_history_on_user_id ON grit_msm_screening_detail_history USING btree (user_id);

      CREATE INDEX index_grit_msm_screening_details_on_master_id ON grit_msm_screening_details USING btree (master_id);

      CREATE INDEX index_grit_msm_screening_details_on_user_id ON grit_msm_screening_details USING btree (user_id);

      CREATE TRIGGER grit_msm_screening_detail_history_insert AFTER INSERT ON grit_msm_screening_details FOR EACH ROW EXECUTE PROCEDURE log_grit_msm_screening_detail_update();
      CREATE TRIGGER grit_msm_screening_detail_history_update AFTER UPDATE ON grit_msm_screening_details FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_msm_screening_detail_update();


      ALTER TABLE ONLY grit_msm_screening_details
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_msm_screening_details
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_msm_screening_detail_history
          ADD CONSTRAINT fk_grit_msm_screening_detail_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_msm_screening_detail_history
          ADD CONSTRAINT fk_grit_msm_screening_detail_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_msm_screening_detail_history
          ADD CONSTRAINT fk_grit_msm_screening_detail_history_grit_msm_screening_details FOREIGN KEY (grit_msm_screening_detail_id) REFERENCES grit_msm_screening_details(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
