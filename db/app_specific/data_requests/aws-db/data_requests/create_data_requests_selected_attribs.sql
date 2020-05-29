SET search_path = data_requests, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create data_requests_selected_attribs record_id data

      CREATE OR REPLACE FUNCTION log_data_requests_selected_attrib_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO data_requests_selected_attrib_history
                  (
                      master_id,
                      record_id,
                      record_type,
                      data_request_id,
                      data,
                      variable_name,
                      disabled,
                      user_id,
                      created_at,
                      updated_at,
                      data_requests_selected_attrib_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.record_id,
                      NEW.record_type,
                      NEW.data_request_id,
                      NEW.data,
                      NEW.variable_name,
                      NEW.disabled,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE data_requests_selected_attrib_history (
          id integer NOT NULL,
          master_id integer,
          record_id integer,
          record_type varchar,
          data_request_id integer,
          data varchar,
          variable_name varchar,
          disabled boolean,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          data_requests_selected_attrib_id integer
      );

      CREATE SEQUENCE data_requests_selected_attrib_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE data_requests_selected_attrib_history_id_seq OWNED BY data_requests_selected_attrib_history.id;

      CREATE TABLE data_requests_selected_attribs (
          id integer NOT NULL,
          master_id integer,
          record_id integer,
          record_type varchar,
          data_request_id integer,
          data varchar,
          variable_name varchar,
          disabled boolean,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE data_requests_selected_attribs_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE data_requests_selected_attribs_id_seq OWNED BY data_requests_selected_attribs.id;

      ALTER TABLE ONLY data_requests_selected_attribs ALTER COLUMN id SET DEFAULT nextval('data_requests_selected_attribs_id_seq'::regclass);
      ALTER TABLE ONLY data_requests_selected_attrib_history ALTER COLUMN id SET DEFAULT nextval('data_requests_selected_attrib_history_id_seq'::regclass);

      ALTER TABLE ONLY data_requests_selected_attrib_history
          ADD CONSTRAINT data_requests_selected_attrib_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY data_requests_selected_attribs
          ADD CONSTRAINT data_requests_selected_attribs_pkey PRIMARY KEY (id);

      CREATE INDEX index_data_requests_selected_attrib_history_on_master_id ON data_requests_selected_attrib_history USING btree (master_id);


      CREATE INDEX index_data_requests_selected_attrib_history_on_data_requests_selected_attrib_id ON data_requests_selected_attrib_history USING btree (data_requests_selected_attrib_id);
      CREATE INDEX index_data_requests_selected_attrib_history_on_user_id ON data_requests_selected_attrib_history USING btree (user_id);

      CREATE INDEX index_data_requests_selected_attribs_on_master_id ON data_requests_selected_attribs USING btree (master_id);

      CREATE INDEX index_data_requests_selected_attribs_on_user_id ON data_requests_selected_attribs USING btree (user_id);

      CREATE TRIGGER data_requests_selected_attrib_history_insert AFTER INSERT ON data_requests_selected_attribs FOR EACH ROW EXECUTE PROCEDURE log_data_requests_selected_attrib_update();
      CREATE TRIGGER data_requests_selected_attrib_history_update AFTER UPDATE ON data_requests_selected_attribs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_data_requests_selected_attrib_update();


      ALTER TABLE ONLY data_requests_selected_attribs
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY data_requests_selected_attribs
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      -- ALTER TABLE ONLY data_requests_selected_attribs
      --     ADD CONSTRAINT fk_rails_982635401e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);



      ALTER TABLE ONLY data_requests_selected_attrib_history
          ADD CONSTRAINT fk_data_requests_selected_attrib_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY data_requests_selected_attrib_history
          ADD CONSTRAINT fk_data_requests_selected_attrib_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      -- ALTER TABLE ONLY data_requests_selected_attrib_history
      --     ADD CONSTRAINT fk_data_requests_selected_attrib_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);


      ALTER TABLE ONLY data_requests_selected_attrib_history
          ADD CONSTRAINT fk_data_requests_selected_attrib_history_data_requests_selected_attribs FOREIGN KEY (data_requests_selected_attrib_id) REFERENCES data_requests_selected_attribs(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA data_requests TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA data_requests TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA data_requests TO fphs;

      COMMIT;
