set search_path=bulk_msg,ml_app;
      BEGIN;

-- Command line:
-- table_generators/generate.sh activity_logs_table create activity_log_zeus_bulk_messages zeus_bulk_message

      CREATE TABLE activity_log_zeus_bulk_message_history (
          id integer NOT NULL,
          master_id integer,
          zeus_bulk_message_id integer,
          background_job_ref integer,
          disabled boolean not null default false,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_zeus_bulk_message_id integer
      );
      CREATE TABLE activity_log_zeus_bulk_messages (
          id integer NOT NULL,
          master_id integer,
          zeus_bulk_message_id integer,
          background_job_ref integer,
          disabled boolean not null default false,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE or REPLACE FUNCTION log_activity_log_zeus_bulk_message_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_zeus_bulk_message_history
                  (
                      master_id,
                      zeus_bulk_message_id,
                      background_job_ref,
                      disabled,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_zeus_bulk_message_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.zeus_bulk_message_id,
                      NEW.background_job_ref,
                      NEW.disabled,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE SEQUENCE activity_log_zeus_bulk_message_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_zeus_bulk_message_history_id_seq OWNED BY activity_log_zeus_bulk_message_history.id;


      CREATE SEQUENCE activity_log_zeus_bulk_messages_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_zeus_bulk_messages_id_seq OWNED BY activity_log_zeus_bulk_messages.id;

      ALTER TABLE ONLY activity_log_zeus_bulk_messages ALTER COLUMN id SET DEFAULT nextval('activity_log_zeus_bulk_messages_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_zeus_bulk_message_history ALTER COLUMN id SET DEFAULT nextval('activity_log_zeus_bulk_message_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_zeus_bulk_message_history
          ADD CONSTRAINT activity_log_zeus_bulk_message_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_zeus_bulk_messages
          ADD CONSTRAINT activity_log_zeus_bulk_messages_pkey PRIMARY KEY (id);

      CREATE INDEX index_al_zeus_bulk_message_history_on_master_id ON activity_log_zeus_bulk_message_history USING btree (master_id);
      CREATE INDEX index_al_zeus_bulk_message_history_on_zeus_bulk_message_id ON activity_log_zeus_bulk_message_history USING btree (zeus_bulk_message_id);

      CREATE INDEX index_al_zeus_bulk_message_history_on_activity_log_zeus_bulk_message_id ON activity_log_zeus_bulk_message_history USING btree (activity_log_zeus_bulk_message_id);
      CREATE INDEX index_al_zeus_bulk_message_history_on_user_id ON activity_log_zeus_bulk_message_history USING btree (user_id);

      CREATE INDEX index_activity_log_zeus_bulk_messages_on_master_id ON activity_log_zeus_bulk_messages USING btree (master_id);
      CREATE INDEX index_activity_log_zeus_bulk_messages_on_zeus_bulk_message_id ON activity_log_zeus_bulk_messages USING btree (zeus_bulk_message_id);
      CREATE INDEX index_activity_log_zeus_bulk_messages_on_user_id ON activity_log_zeus_bulk_messages USING btree (user_id);

      CREATE TRIGGER activity_log_zeus_bulk_message_history_insert AFTER INSERT ON activity_log_zeus_bulk_messages FOR EACH ROW EXECUTE PROCEDURE log_activity_log_zeus_bulk_message_update();
      CREATE TRIGGER activity_log_zeus_bulk_message_history_update AFTER UPDATE ON activity_log_zeus_bulk_messages FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_zeus_bulk_message_update();


      ALTER TABLE ONLY activity_log_zeus_bulk_messages
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_zeus_bulk_messages
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_zeus_bulk_messages
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (zeus_bulk_message_id) REFERENCES zeus_bulk_messages(id);

      ALTER TABLE ONLY activity_log_zeus_bulk_message_history
          ADD CONSTRAINT fk_activity_log_zeus_bulk_message_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_zeus_bulk_message_history
          ADD CONSTRAINT fk_activity_log_zeus_bulk_message_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_zeus_bulk_message_history
          ADD CONSTRAINT fk_activity_log_zeus_bulk_message_history_zeus_bulk_message_id FOREIGN KEY (zeus_bulk_message_id) REFERENCES zeus_bulk_messages(id);

      ALTER TABLE ONLY activity_log_zeus_bulk_message_history
          ADD CONSTRAINT fk_activity_log_zeus_bulk_message_history_activity_log_zeus_bulk_messages FOREIGN KEY (activity_log_zeus_bulk_message_id) REFERENCES activity_log_zeus_bulk_messages(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
