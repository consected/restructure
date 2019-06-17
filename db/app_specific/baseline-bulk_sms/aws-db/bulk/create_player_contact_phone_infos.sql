set search_path=${app_schema},ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create player_contact_phone_infos player_contact_id carrier city cleansed_phone_number_e164 cleansed_phone_number_national country country_code_iso_2 country_code_numeric county original_country_code_iso_2 original_phone_number phone_type phone_type_code timezone zip_code

      CREATE FUNCTION log_player_contact_phone_info_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO player_contact_phone_info_history
                  (
                      master_id,
                      player_contact_id,
                      carrier,
                      city,
                      cleansed_phone_number_e164,
                      cleansed_phone_number_national,
                      country,
                      country_code_iso_2,
                      country_code_numeric,
                      county,
                      original_country_code_iso_2,
                      original_phone_number,
                      phone_type,
                      phone_type_code,
                      timezone,
                      zip_code,
                      user_id,
                      created_at,
                      updated_at,
                      player_contact_phone_info_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.player_contact_id,
                      NEW.carrier,
                      NEW.city,
                      NEW.cleansed_phone_number_e164,
                      NEW.cleansed_phone_number_national,
                      NEW.country,
                      NEW.country_code_iso_2,
                      NEW.country_code_numeric,
                      NEW.county,
                      NEW.original_country_code_iso_2,
                      NEW.original_phone_number,
                      NEW.phone_type,
                      NEW.phone_type_code,
                      NEW.timezone,
                      NEW.zip_code,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE player_contact_phone_info_history (
          id integer NOT NULL,
          master_id integer,
          player_contact_id bigint,
          carrier varchar,
          city varchar,
          cleansed_phone_number_e164 varchar,
          cleansed_phone_number_national varchar,
          country varchar,
          country_code_iso_2 varchar,
          country_code_numeric varchar,
          county varchar,
          original_country_code_iso_2 varchar,
          original_phone_number integer,
          phone_type varchar,
          phone_type_code varchar,
          timezone varchar,
          zip_code varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          player_contact_phone_info_id integer
      );

      CREATE SEQUENCE player_contact_phone_info_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE player_contact_phone_info_history_id_seq OWNED BY player_contact_phone_info_history.id;

      CREATE TABLE player_contact_phone_infos (
          id integer NOT NULL,
          master_id integer,
          player_contact_id bigint,
          carrier varchar,
          city varchar,
          cleansed_phone_number_e164 varchar,
          cleansed_phone_number_national varchar,
          country varchar,
          country_code_iso_2 varchar,
          country_code_numeric varchar,
          county varchar,
          original_country_code_iso_2 varchar,
          original_phone_number integer,
          phone_type varchar,
          phone_type_code varchar,
          timezone varchar,
          zip_code varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE player_contact_phone_infos_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE player_contact_phone_infos_id_seq OWNED BY player_contact_phone_infos.id;

      ALTER TABLE ONLY player_contact_phone_infos ALTER COLUMN id SET DEFAULT nextval('player_contact_phone_infos_id_seq'::regclass);
      ALTER TABLE ONLY player_contact_phone_info_history ALTER COLUMN id SET DEFAULT nextval('player_contact_phone_info_history_id_seq'::regclass);

      ALTER TABLE ONLY player_contact_phone_info_history
          ADD CONSTRAINT player_contact_phone_info_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY player_contact_phone_infos
          ADD CONSTRAINT player_contact_phone_infos_pkey PRIMARY KEY (id);

      CREATE INDEX index_player_contact_phone_info_history_on_master_id ON player_contact_phone_info_history USING btree (master_id);


      CREATE INDEX index_player_contact_phone_info_history_on_player_contact_phone_info_id ON player_contact_phone_info_history USING btree (player_contact_phone_info_id);
      CREATE INDEX index_player_contact_phone_info_history_on_user_id ON player_contact_phone_info_history USING btree (user_id);

      CREATE INDEX index_player_contact_phone_infos_on_master_id ON player_contact_phone_infos USING btree (master_id);

      CREATE INDEX index_player_contact_phone_infos_on_user_id ON player_contact_phone_infos USING btree (user_id);

      CREATE TRIGGER player_contact_phone_info_history_insert AFTER INSERT ON player_contact_phone_infos FOR EACH ROW EXECUTE PROCEDURE log_player_contact_phone_info_update();
      CREATE TRIGGER player_contact_phone_info_history_update AFTER UPDATE ON player_contact_phone_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_player_contact_phone_info_update();


      ALTER TABLE ONLY player_contact_phone_infos
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY player_contact_phone_infos
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY player_contact_phone_info_history
          ADD CONSTRAINT fk_player_contact_phone_info_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY player_contact_phone_info_history
          ADD CONSTRAINT fk_player_contact_phone_info_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY player_contact_phone_info_history
          ADD CONSTRAINT fk_player_contact_phone_info_history_player_contact_phone_infos FOREIGN KEY (player_contact_phone_info_id) REFERENCES player_contact_phone_infos(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
