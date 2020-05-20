SET search_path = data_requests, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create data_request_attribs data_source requested_attribs

      CREATE FUNCTION log_data_request_attrib_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO data_request_attrib_history
                  (
                      master_id,
                      data_source,
                      requested_attribs,
                      user_id,
                      created_at,
                      updated_at,
                      data_request_attrib_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.data_source,
                      NEW.requested_attribs,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE data_request_attrib_history (
          id integer NOT NULL,
          master_id integer,
          data_source varchar,
          requested_attribs varchar[],
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          data_request_attrib_id integer
      );

      CREATE SEQUENCE data_request_attrib_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE data_request_attrib_history_id_seq OWNED BY data_request_attrib_history.id;

      CREATE TABLE data_request_attribs (
          id integer NOT NULL,
          master_id integer,
          data_source varchar,
          requested_attribs varchar[],
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE data_request_attribs_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE data_request_attribs_id_seq OWNED BY data_request_attribs.id;

      ALTER TABLE ONLY data_request_attribs ALTER COLUMN id SET DEFAULT nextval('data_request_attribs_id_seq'::regclass);
      ALTER TABLE ONLY data_request_attrib_history ALTER COLUMN id SET DEFAULT nextval('data_request_attrib_history_id_seq'::regclass);

      ALTER TABLE ONLY data_request_attrib_history
          ADD CONSTRAINT data_request_attrib_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY data_request_attribs
          ADD CONSTRAINT data_request_attribs_pkey PRIMARY KEY (id);

      CREATE INDEX index_data_request_attrib_history_on_master_id ON data_request_attrib_history USING btree (master_id);


      CREATE INDEX index_data_request_attrib_history_on_data_request_attrib_id ON data_request_attrib_history USING btree (data_request_attrib_id);
      CREATE INDEX index_data_request_attrib_history_on_user_id ON data_request_attrib_history USING btree (user_id);

      CREATE INDEX index_data_request_attribs_on_master_id ON data_request_attribs USING btree (master_id);

      CREATE INDEX index_data_request_attribs_on_user_id ON data_request_attribs USING btree (user_id);

      CREATE TRIGGER data_request_attrib_history_insert AFTER INSERT ON data_request_attribs FOR EACH ROW EXECUTE PROCEDURE log_data_request_attrib_update();
      CREATE TRIGGER data_request_attrib_history_update AFTER UPDATE ON data_request_attribs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_data_request_attrib_update();


      ALTER TABLE ONLY data_request_attribs
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY data_request_attribs
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      -- ALTER TABLE ONLY data_request_attribs
      --     ADD CONSTRAINT fk_rails_982635401e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);



      ALTER TABLE ONLY data_request_attrib_history
          ADD CONSTRAINT fk_data_request_attrib_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY data_request_attrib_history
          ADD CONSTRAINT fk_data_request_attrib_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      -- ALTER TABLE ONLY data_request_attrib_history
      --     ADD CONSTRAINT fk_data_request_attrib_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);


      ALTER TABLE ONLY data_request_attrib_history
          ADD CONSTRAINT fk_data_request_attrib_history_data_request_attribs FOREIGN KEY (data_request_attrib_id) REFERENCES data_request_attribs(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA data_requests TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA data_requests TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA data_requests TO fphs;

      COMMIT;
