set search_path=sleep, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_pi_follow_ups pre_call_notes call_notes

      CREATE FUNCTION log_sleep_pi_follow_up_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_pi_follow_up_history
                  (
                      master_id,
                      pre_call_notes,
                      call_notes,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_pi_follow_up_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.pre_call_notes,
                      NEW.call_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_pi_follow_up_history (
          id integer NOT NULL,
          master_id integer,
          pre_call_notes varchar,
          call_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_pi_follow_up_id integer
      );

      CREATE SEQUENCE sleep_pi_follow_up_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_pi_follow_up_history_id_seq OWNED BY sleep_pi_follow_up_history.id;

      CREATE TABLE sleep_pi_follow_ups (
          id integer NOT NULL,
          master_id integer,
          pre_call_notes varchar,
          call_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_pi_follow_ups_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_pi_follow_ups_id_seq OWNED BY sleep_pi_follow_ups.id;

      ALTER TABLE ONLY sleep_pi_follow_ups ALTER COLUMN id SET DEFAULT nextval('sleep_pi_follow_ups_id_seq'::regclass);
      ALTER TABLE ONLY sleep_pi_follow_up_history ALTER COLUMN id SET DEFAULT nextval('sleep_pi_follow_up_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_pi_follow_up_history
          ADD CONSTRAINT sleep_pi_follow_up_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_pi_follow_ups
          ADD CONSTRAINT sleep_pi_follow_ups_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_pi_follow_up_history_on_master_id ON sleep_pi_follow_up_history USING btree (master_id);


      CREATE INDEX index_sleep_pi_follow_up_history_on_sleep_pi_follow_up_id ON sleep_pi_follow_up_history USING btree (sleep_pi_follow_up_id);
      CREATE INDEX index_sleep_pi_follow_up_history_on_user_id ON sleep_pi_follow_up_history USING btree (user_id);

      CREATE INDEX index_sleep_pi_follow_ups_on_master_id ON sleep_pi_follow_ups USING btree (master_id);

      CREATE INDEX index_sleep_pi_follow_ups_on_user_id ON sleep_pi_follow_ups USING btree (user_id);

      CREATE TRIGGER sleep_pi_follow_up_history_insert AFTER INSERT ON sleep_pi_follow_ups FOR EACH ROW EXECUTE PROCEDURE log_sleep_pi_follow_up_update();
      CREATE TRIGGER sleep_pi_follow_up_history_update AFTER UPDATE ON sleep_pi_follow_ups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_pi_follow_up_update();


      ALTER TABLE ONLY sleep_pi_follow_ups
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_pi_follow_ups
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_pi_follow_up_history
          ADD CONSTRAINT fk_sleep_pi_follow_up_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_pi_follow_up_history
          ADD CONSTRAINT fk_sleep_pi_follow_up_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_pi_follow_up_history
          ADD CONSTRAINT fk_sleep_pi_follow_up_history_sleep_pi_follow_ups FOREIGN KEY (sleep_pi_follow_up_id) REFERENCES sleep_pi_follow_ups(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
