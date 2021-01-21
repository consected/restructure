
      BEGIN;

-- Command line:
-- table_generators/generate.sh activity_logs_table create activity_log_player_info_e_signs player_info e_signed_document e_signed_how e_signed_at e_signed_by e_signed_code

      CREATE TABLE IF NOT EXISTS activity_log_player_info_e_sign_history (
          id integer NOT NULL,
          master_id integer,
          player_info_id integer,
          e_signed_document varchar,
          e_signed_how varchar,
          e_signed_at varchar,
          e_signed_by varchar,
          e_signed_code varchar,
          e_signed_status varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_player_info_e_sign_id integer
      );
      CREATE TABLE IF NOT EXISTS activity_log_player_info_e_signs (
          id integer NOT NULL,
          master_id integer,
          player_info_id integer,
          e_signed_document varchar,
          e_signed_how varchar,
          e_signed_at varchar,
          e_signed_by varchar,
          e_signed_code varchar,
          e_signed_status varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE OR REPLACE FUNCTION log_activity_log_player_info_e_sign_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_player_info_e_sign_history
                  (
                      master_id,
                      player_info_id,
                      e_signed_document,
                      e_signed_how,
                      e_signed_at,
                      e_signed_by,
                      e_signed_code,
                      e_signed_status,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_player_info_e_sign_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.player_info_id,
                      NEW.e_signed_document,
                      NEW.e_signed_how,
                      NEW.e_signed_at,
                      NEW.e_signed_by,
                      NEW.e_signed_code,
                      NEW.e_signed_status,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE SEQUENCE activity_log_player_info_e_sign_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_player_info_e_sign_history_id_seq OWNED BY activity_log_player_info_e_sign_history.id;


      CREATE SEQUENCE activity_log_player_info_e_signs_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_player_info_e_signs_id_seq OWNED BY activity_log_player_info_e_signs.id;

      ALTER TABLE ONLY activity_log_player_info_e_signs ALTER COLUMN id SET DEFAULT nextval('activity_log_player_info_e_signs_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_player_info_e_sign_history ALTER COLUMN id SET DEFAULT nextval('activity_log_player_info_e_sign_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_player_info_e_sign_history
          ADD CONSTRAINT activity_log_player_info_e_sign_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_player_info_e_signs
          ADD CONSTRAINT activity_log_player_info_e_signs_pkey PRIMARY KEY (id);

      CREATE INDEX index_al_player_info_e_sign_history_on_master_id ON activity_log_player_info_e_sign_history USING btree (master_id);
      CREATE INDEX index_al_player_info_e_sign_history_on_player_info_e_sign_id ON activity_log_player_info_e_sign_history USING btree (player_info_id);

      CREATE INDEX index_al_player_info_e_sign_history_on_activity_log_player_info_e_sign_id ON activity_log_player_info_e_sign_history USING btree (activity_log_player_info_e_sign_id);
      CREATE INDEX index_al_player_info_e_sign_history_on_user_id ON activity_log_player_info_e_sign_history USING btree (user_id);

      CREATE INDEX index_activity_log_player_info_e_signs_on_master_id ON activity_log_player_info_e_signs USING btree (master_id);
      CREATE INDEX index_activity_log_player_info_e_signs_on_player_info_e_sign_id ON activity_log_player_info_e_signs USING btree (player_info_id);
      CREATE INDEX index_activity_log_player_info_e_signs_on_user_id ON activity_log_player_info_e_signs USING btree (user_id);

      CREATE TRIGGER activity_log_player_info_e_sign_history_insert AFTER INSERT ON activity_log_player_info_e_signs FOR EACH ROW EXECUTE PROCEDURE log_activity_log_player_info_e_sign_update();
      CREATE TRIGGER activity_log_player_info_e_sign_history_update AFTER UPDATE ON activity_log_player_info_e_signs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_player_info_e_sign_update();


      ALTER TABLE ONLY activity_log_player_info_e_signs
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_player_info_e_signs
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_player_info_e_signs
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (player_info_id) REFERENCES player_infos(id);

      ALTER TABLE ONLY activity_log_player_info_e_sign_history
          ADD CONSTRAINT fk_activity_log_player_info_e_sign_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_player_info_e_sign_history
          ADD CONSTRAINT fk_activity_log_player_info_e_sign_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_player_info_e_sign_history
          ADD CONSTRAINT fk_activity_log_player_info_e_sign_history_player_info_e_sign_id FOREIGN KEY (player_info_id) REFERENCES player_infos(id);

      ALTER TABLE ONLY activity_log_player_info_e_sign_history
          ADD CONSTRAINT fk_activity_log_player_info_e_sign_history_activity_log_player_info_e_signs FOREIGN KEY (activity_log_player_info_e_sign_id) REFERENCES activity_log_player_info_e_signs(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
