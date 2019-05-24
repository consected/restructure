set search_path=ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create zeus_bulk_message_recipients item_id data rec_type rank zeus_bulk_message_id

      CREATE FUNCTION log_zeus_bulk_message_recipient_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO zeus_bulk_message_recipient_history
                  (
                      master_id,
                      item_id,
                      data,
                      rec_type,
                      rank,
                      zeus_bulk_message_id,
                      user_id,
                      created_at,
                      updated_at,
                      zeus_bulk_message_recipient_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.item_id,
                      NEW.data,
                      NEW.rec_type,
                      NEW.rank,
                      NEW.zeus_bulk_message_id,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE zeus_bulk_message_recipient_history (
          id integer NOT NULL,
          master_id integer,
          item_id bigint,
          data varchar,
          rec_type varchar,
          rank varchar,
          zeus_bulk_message_id bigint,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          zeus_bulk_message_recipient_id integer
      );

      CREATE SEQUENCE zeus_bulk_message_recipient_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE zeus_bulk_message_recipient_history_id_seq OWNED BY zeus_bulk_message_recipient_history.id;

      CREATE TABLE zeus_bulk_message_recipients (
          id integer NOT NULL,
          master_id integer,
          item_id bigint,
          data varchar,
          rec_type varchar,
          rank varchar,
          zeus_bulk_message_id bigint,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE zeus_bulk_message_recipients_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE zeus_bulk_message_recipients_id_seq OWNED BY zeus_bulk_message_recipients.id;

      ALTER TABLE ONLY zeus_bulk_message_recipients ALTER COLUMN id SET DEFAULT nextval('zeus_bulk_message_recipients_id_seq'::regclass);
      ALTER TABLE ONLY zeus_bulk_message_recipient_history ALTER COLUMN id SET DEFAULT nextval('zeus_bulk_message_recipient_history_id_seq'::regclass);

      ALTER TABLE ONLY zeus_bulk_message_recipient_history
          ADD CONSTRAINT zeus_bulk_message_recipient_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY zeus_bulk_message_recipients
          ADD CONSTRAINT zeus_bulk_message_recipients_pkey PRIMARY KEY (id);

      CREATE INDEX index_zeus_bulk_message_recipient_history_on_master_id ON zeus_bulk_message_recipient_history USING btree (master_id);


      CREATE INDEX index_zeus_bulk_message_recipient_history_on_zeus_bulk_message_recipient_id ON zeus_bulk_message_recipient_history USING btree (zeus_bulk_message_recipient_id);
      CREATE INDEX index_zeus_bulk_message_recipient_history_on_user_id ON zeus_bulk_message_recipient_history USING btree (user_id);

      CREATE INDEX index_zeus_bulk_message_recipients_on_master_id ON zeus_bulk_message_recipients USING btree (master_id);

      CREATE INDEX index_zeus_bulk_message_recipients_on_user_id ON zeus_bulk_message_recipients USING btree (user_id);

      CREATE TRIGGER zeus_bulk_message_recipient_history_insert AFTER INSERT ON zeus_bulk_message_recipients FOR EACH ROW EXECUTE PROCEDURE log_zeus_bulk_message_recipient_update();
      CREATE TRIGGER zeus_bulk_message_recipient_history_update AFTER UPDATE ON zeus_bulk_message_recipients FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_zeus_bulk_message_recipient_update();


      ALTER TABLE ONLY zeus_bulk_message_recipients
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY zeus_bulk_message_recipients
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY zeus_bulk_message_recipient_history
          ADD CONSTRAINT fk_zeus_bulk_message_recipient_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY zeus_bulk_message_recipient_history
          ADD CONSTRAINT fk_zeus_bulk_message_recipient_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY zeus_bulk_message_recipient_history
          ADD CONSTRAINT fk_zeus_bulk_message_recipient_history_zeus_bulk_message_recipients FOREIGN KEY (zeus_bulk_message_recipient_id) REFERENCES zeus_bulk_message_recipients(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
