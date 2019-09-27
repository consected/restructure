set search_path=bulk_msg,ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create zeus_bulk_message_statuses res_timestamp message_id status status_reason bulk_message_recipient_id

      CREATE FUNCTION log_zeus_bulk_message_status_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO zeus_bulk_message_status_history
                  (
                      master_id,
                      res_timestamp,
                      message_id,
                      status,
                      status_reason,
                      zeus_bulk_message_recipient_id,
                      user_id,
                      created_at,
                      updated_at,
                      zeus_bulk_message_status_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.res_timestamp,
                      NEW.message_id,
                      NEW.status,
                      NEW.status_reason,
                      NEW.zeus_bulk_message_recipient_id,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE zeus_bulk_message_status_history (
          id integer NOT NULL,
          master_id integer,
          res_timestamp integer,
          message_id varchar,
          status varchar,
          status_reason varchar,
          zeus_bulk_message_recipient_id integer,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          zeus_bulk_message_status_id integer
      );

      CREATE SEQUENCE zeus_bulk_message_status_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE zeus_bulk_message_status_history_id_seq OWNED BY zeus_bulk_message_status_history.id;

      CREATE TABLE zeus_bulk_message_statuses (
          id integer NOT NULL,
          master_id integer,
          res_timestamp integer,
          message_id varchar,
          status varchar,
          status_reason varchar,
          zeus_bulk_message_recipient_id integer,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE zeus_bulk_message_statuses_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE zeus_bulk_message_statuses_id_seq OWNED BY zeus_bulk_message_statuses.id;

      ALTER TABLE ONLY zeus_bulk_message_statuses ALTER COLUMN id SET DEFAULT nextval('zeus_bulk_message_statuses_id_seq'::regclass);
      ALTER TABLE ONLY zeus_bulk_message_status_history ALTER COLUMN id SET DEFAULT nextval('zeus_bulk_message_status_history_id_seq'::regclass);

      ALTER TABLE ONLY zeus_bulk_message_status_history
          ADD CONSTRAINT zeus_bulk_message_status_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY zeus_bulk_message_statuses
          ADD CONSTRAINT zeus_bulk_message_statuses_pkey PRIMARY KEY (id);

      CREATE INDEX index_zeus_bulk_message_status_history_on_master_id ON zeus_bulk_message_status_history USING btree (master_id);


      CREATE INDEX index_zeus_bulk_message_status_history_on_zeus_bulk_message_status_id ON zeus_bulk_message_status_history USING btree (zeus_bulk_message_status_id);
      CREATE INDEX index_zeus_bulk_message_status_history_on_user_id ON zeus_bulk_message_status_history USING btree (user_id);

      CREATE INDEX index_zeus_bulk_message_statuses_on_master_id ON zeus_bulk_message_statuses USING btree (master_id);

      CREATE INDEX index_zeus_bulk_message_statuses_on_user_id ON zeus_bulk_message_statuses USING btree (user_id);

      CREATE INDEX index_zeus_bulk_message_statuses_on_ts ON zeus_bulk_message_statuses USING btree (res_timestamp);

      CREATE TRIGGER zeus_bulk_message_status_history_insert AFTER INSERT ON zeus_bulk_message_statuses FOR EACH ROW EXECUTE PROCEDURE log_zeus_bulk_message_status_update();
      CREATE TRIGGER zeus_bulk_message_status_history_update AFTER UPDATE ON zeus_bulk_message_statuses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_zeus_bulk_message_status_update();


      ALTER TABLE ONLY zeus_bulk_message_statuses
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY zeus_bulk_message_statuses
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);

      -- ALTER TABLE ONLY zeus_bulk_message_statuses
      --     ADD CONSTRAINT fk_rails_45205ed086 FOREIGN KEY (zeus_bulk_message_recipient_id) REFERENCES zeus_bulk_message_recipients(id);



      ALTER TABLE ONLY zeus_bulk_message_status_history
          ADD CONSTRAINT fk_zeus_bulk_message_status_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY zeus_bulk_message_status_history
          ADD CONSTRAINT fk_zeus_bulk_message_status_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY zeus_bulk_message_status_history
          ADD CONSTRAINT fk_zeus_bulk_message_status_history_zeus_bulk_message_statuses FOREIGN KEY (zeus_bulk_message_status_id) REFERENCES zeus_bulk_message_statuses(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
