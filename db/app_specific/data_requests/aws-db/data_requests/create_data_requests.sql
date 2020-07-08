SET search_path = data_requests, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create data_requests project_title concept_sheet_approved_yes_no concept_sheet_approved_by full_name title institution others_handling_data pm_contact other_pm_contact data_use_agreement_status data_use_agreement_notes terms_of_use_yes_no data_start_date data_end_date

      CREATE or REPLACE FUNCTION log_data_request_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO data_request_history
                  (
                      master_id,
                      project_title,
                      concept_sheet_approved_yes_no,
                      concept_sheet_approved_by,
                      full_name,
                      title,
                      institution,
                      other_institution,
                      others_handling_data,
                      pm_contact,
                      other_pm_contact,
                      data_use_agreement_status,
                      data_use_agreement_notes,
                      terms_of_use_yes_no,
                      data_start_date,
                      data_end_date,
                      fphs_analyst_yes_no,
                      fphs_server_yes_no,
                      fphs_server_tools_notes,
                      off_fphs_server_reason_notes,
                      status,
                      user_id,
                      created_by_user_id,
                      created_at,
                      updated_at,
                      data_request_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.project_title,
                      NEW.concept_sheet_approved_yes_no,
                      NEW.concept_sheet_approved_by,
                      NEW.full_name,
                      NEW.title,
                      NEW.institution,
                      NEW.other_institution,
                      NEW.others_handling_data,
                      NEW.pm_contact,
                      NEW.other_pm_contact,
                      NEW.data_use_agreement_status,
                      NEW.data_use_agreement_notes,
                      NEW.terms_of_use_yes_no,
                      NEW.data_start_date,
                      NEW.data_end_date,
                      NEW.fphs_analyst_yes_no,
                      NEW.fphs_server_yes_no,
                      NEW.fphs_server_tools_notes,
                      NEW.off_fphs_server_reason_notes,
                      NEW.status,
                      NEW.user_id,
                      NEW.created_by_user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE data_request_history (
          id integer NOT NULL,
          master_id integer,
          project_title varchar,
          concept_sheet_approved_yes_no varchar,
          concept_sheet_approved_by varchar,
          full_name varchar,
          title varchar,
          institution varchar,
          other_institution varchar,
          others_handling_data varchar,
          pm_contact varchar,
          other_pm_contact varchar,
          data_use_agreement_status varchar,
          data_use_agreement_notes varchar,
          terms_of_use_yes_no varchar,
          data_start_date date,
          data_end_date date,
          fphs_analyst_yes_no varchar,
          fphs_server_yes_no varchar,
          fphs_server_tools_notes varchar,
          off_fphs_server_reason_notes varchar,
          status varchar,
          user_id integer,
          created_by_user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          data_request_id integer
      );

      CREATE SEQUENCE data_request_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE data_request_history_id_seq OWNED BY data_request_history.id;

      CREATE TABLE data_requests (
          id integer NOT NULL,
          master_id integer,
          project_title varchar,
          concept_sheet_approved_yes_no varchar,
          concept_sheet_approved_by varchar,
          full_name varchar,
          title varchar,
          institution varchar,
          other_institution varchar,
          others_handling_data varchar,
          pm_contact varchar,
          other_pm_contact varchar,
          data_use_agreement_status varchar,
          data_use_agreement_notes varchar,
          terms_of_use_yes_no varchar,
          data_start_date date,
          data_end_date date,
          fphs_analyst_yes_no varchar,
          fphs_server_yes_no varchar,
          fphs_server_tools_notes varchar,
          off_fphs_server_reason_notes varchar,
          status varchar,
          user_id integer,
          created_by_user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE data_requests_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE data_requests_id_seq OWNED BY data_requests.id;

      ALTER TABLE ONLY data_requests ALTER COLUMN id SET DEFAULT nextval('data_requests_id_seq'::regclass);
      ALTER TABLE ONLY data_request_history ALTER COLUMN id SET DEFAULT nextval('data_request_history_id_seq'::regclass);

      ALTER TABLE ONLY data_request_history
          ADD CONSTRAINT data_request_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY data_requests
          ADD CONSTRAINT data_requests_pkey PRIMARY KEY (id);

      CREATE INDEX index_data_request_history_on_master_id ON data_request_history USING btree (master_id);


      CREATE INDEX index_data_request_history_on_data_request_id ON data_request_history USING btree (data_request_id);
      CREATE INDEX index_data_request_history_on_user_id ON data_request_history USING btree (user_id);

      CREATE INDEX index_data_requests_on_master_id ON data_requests USING btree (master_id);

      CREATE INDEX index_data_requests_on_user_id ON data_requests USING btree (user_id);

      CREATE TRIGGER data_request_history_insert AFTER INSERT ON data_requests FOR EACH ROW EXECUTE PROCEDURE log_data_request_update();
      CREATE TRIGGER data_request_history_update AFTER UPDATE ON data_requests FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_data_request_update();


      ALTER TABLE ONLY data_requests
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY data_requests
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY data_requests
          ADD CONSTRAINT fk_rails_982635401e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);



      ALTER TABLE ONLY data_request_history
          ADD CONSTRAINT fk_data_request_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY data_request_history
          ADD CONSTRAINT fk_data_request_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY data_request_history
          ADD CONSTRAINT fk_data_request_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);


      ALTER TABLE ONLY data_request_history
          ADD CONSTRAINT fk_data_request_history_data_requests FOREIGN KEY (data_request_id) REFERENCES data_requests(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA data_requests TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA data_requests TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA data_requests TO fphs;

      COMMIT;
