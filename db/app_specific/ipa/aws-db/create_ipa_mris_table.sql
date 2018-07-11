
      BEGIN;

-- Command line:
-- table_generators/generate.sh create dynamic_models_table ipa_ps_mris false electrical_implants_blank_yes_no_dont_know electrical_implants_details metal_implants_blank_yes_no_dont_know metal_implants_details metal_jewelry_blank_yes_no hearing_aid_blank_yes_no

      CREATE FUNCTION log_ipa_ps_mri_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_ps_mri_history
                  (
                      master_id,
                      electrical_implants_blank_yes_no_dont_know,
                      electrical_implants_details,
                      metal_implants_blank_yes_no_dont_know,
                      metal_implants_details,
                      metal_jewelry_blank_yes_no,
                      hearing_aid_blank_yes_no,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_mri_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.electrical_implants_blank_yes_no_dont_know,
                      NEW.electrical_implants_details,
                      NEW.metal_implants_blank_yes_no_dont_know,
                      NEW.metal_implants_details,
                      NEW.metal_jewelry_blank_yes_no,
                      NEW.hearing_aid_blank_yes_no,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_ps_mri_history (
          id integer NOT NULL,
          master_id integer,
          electrical_implants_blank_yes_no_dont_know varchar,
          electrical_implants_details varchar,
          metal_implants_blank_yes_no_dont_know varchar,
          metal_implants_details varchar,
          metal_jewelry_blank_yes_no varchar,
          hearing_aid_blank_yes_no varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_ps_mri_id integer
      );

      CREATE SEQUENCE ipa_ps_mri_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_mri_history_id_seq OWNED BY ipa_ps_mri_history.id;

      CREATE TABLE ipa_ps_mris (
          id integer NOT NULL,
          master_id integer,
          electrical_implants_blank_yes_no_dont_know varchar,
          electrical_implants_details varchar,
          metal_implants_blank_yes_no_dont_know varchar,
          metal_implants_details varchar,
          metal_jewelry_blank_yes_no varchar,
          hearing_aid_blank_yes_no varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_ps_mris_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_mris_id_seq OWNED BY ipa_ps_mris.id;

      ALTER TABLE ONLY ipa_ps_mris ALTER COLUMN id SET DEFAULT nextval('ipa_ps_mris_id_seq'::regclass);
      ALTER TABLE ONLY ipa_ps_mri_history ALTER COLUMN id SET DEFAULT nextval('ipa_ps_mri_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_ps_mri_history
          ADD CONSTRAINT ipa_ps_mri_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_ps_mris
          ADD CONSTRAINT ipa_ps_mris_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_ps_mri_history_on_master_id ON ipa_ps_mri_history USING btree (master_id);


      CREATE INDEX index_ipa_ps_mri_history_on_ipa_ps_mri_id ON ipa_ps_mri_history USING btree (ipa_ps_mri_id);
      CREATE INDEX index_ipa_ps_mri_history_on_user_id ON ipa_ps_mri_history USING btree (user_id);

      CREATE INDEX index_ipa_ps_mris_on_master_id ON ipa_ps_mris USING btree (master_id);

      CREATE INDEX index_ipa_ps_mris_on_user_id ON ipa_ps_mris USING btree (user_id);

      CREATE TRIGGER ipa_ps_mri_history_insert AFTER INSERT ON ipa_ps_mris FOR EACH ROW EXECUTE PROCEDURE log_ipa_ps_mri_update();
      CREATE TRIGGER ipa_ps_mri_history_update AFTER UPDATE ON ipa_ps_mris FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_ps_mri_update();


      ALTER TABLE ONLY ipa_ps_mris
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_ps_mris
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_ps_mri_history
          ADD CONSTRAINT fk_ipa_ps_mri_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_ps_mri_history
          ADD CONSTRAINT fk_ipa_ps_mri_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_ps_mri_history
          ADD CONSTRAINT fk_ipa_ps_mri_history_ipa_ps_mris FOREIGN KEY (ipa_ps_mri_id) REFERENCES ipa_ps_mris(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
