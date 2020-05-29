SET search_path = data_requests, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create data_request_initial_reviews fphs_analyst_yes_no fphs_server_yes_no tag_select_data_classifications require_updates_yes_no review_complete_yes_no reviewer_notes message_notes created_by_user_id

      CREATE FUNCTION log_data_request_initial_review_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO data_request_initial_review_history
                  (
                      master_id,
                      fphs_analyst_yes_no,
                      fphs_server_yes_no,
                      tag_select_data_classifications,
                      require_updates_yes_no,
                      review_complete_yes_no,
                      reviewer_notes,
                      message_notes,
                      created_by_user_id,
                      user_id,
                      created_at,
                      updated_at,
                      data_request_initial_review_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.fphs_analyst_yes_no,
                      NEW.fphs_server_yes_no,
                      NEW.tag_select_data_classifications,
                      NEW.require_updates_yes_no,
                      NEW.review_complete_yes_no,
                      NEW.reviewer_notes,
                      NEW.message_notes,
                      NEW.created_by_user_id,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE data_request_initial_review_history (
          id integer NOT NULL,
          master_id integer,
          fphs_analyst_yes_no varchar,
          fphs_server_yes_no varchar,
          tag_select_data_classifications varchar,
          require_updates_yes_no varchar,
          review_complete_yes_no varchar,
          reviewer_notes varchar,
          message_notes varchar,
          created_by_user_id integer,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          data_request_initial_review_id integer
      );

      CREATE SEQUENCE data_request_initial_review_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE data_request_initial_review_history_id_seq OWNED BY data_request_initial_review_history.id;

      CREATE TABLE data_request_initial_reviews (
          id integer NOT NULL,
          master_id integer,
          fphs_analyst_yes_no varchar,
          fphs_server_yes_no varchar,
          tag_select_data_classifications varchar,
          require_updates_yes_no varchar,
          review_complete_yes_no varchar,
          reviewer_notes varchar,
          message_notes varchar,
          created_by_user_id integer,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE data_request_initial_reviews_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE data_request_initial_reviews_id_seq OWNED BY data_request_initial_reviews.id;

      ALTER TABLE ONLY data_request_initial_reviews ALTER COLUMN id SET DEFAULT nextval('data_request_initial_reviews_id_seq'::regclass);
      ALTER TABLE ONLY data_request_initial_review_history ALTER COLUMN id SET DEFAULT nextval('data_request_initial_review_history_id_seq'::regclass);

      ALTER TABLE ONLY data_request_initial_review_history
          ADD CONSTRAINT data_request_initial_review_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY data_request_initial_reviews
          ADD CONSTRAINT data_request_initial_reviews_pkey PRIMARY KEY (id);

      CREATE INDEX index_data_request_initial_review_history_on_master_id ON data_request_initial_review_history USING btree (master_id);


      CREATE INDEX index_data_request_initial_review_history_on_data_request_initial_review_id ON data_request_initial_review_history USING btree (data_request_initial_review_id);
      CREATE INDEX index_data_request_initial_review_history_on_user_id ON data_request_initial_review_history USING btree (user_id);

      CREATE INDEX index_data_request_initial_reviews_on_master_id ON data_request_initial_reviews USING btree (master_id);

      CREATE INDEX index_data_request_initial_reviews_on_user_id ON data_request_initial_reviews USING btree (user_id);

      CREATE TRIGGER data_request_initial_review_history_insert AFTER INSERT ON data_request_initial_reviews FOR EACH ROW EXECUTE PROCEDURE log_data_request_initial_review_update();
      CREATE TRIGGER data_request_initial_review_history_update AFTER UPDATE ON data_request_initial_reviews FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_data_request_initial_review_update();


      ALTER TABLE ONLY data_request_initial_reviews
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY data_request_initial_reviews
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
       ALTER TABLE ONLY data_request_initial_reviews
           ADD CONSTRAINT fk_rails_982635401e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);



      ALTER TABLE ONLY data_request_initial_review_history
          ADD CONSTRAINT fk_data_request_initial_review_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY data_request_initial_review_history
          ADD CONSTRAINT fk_data_request_initial_review_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

       ALTER TABLE ONLY data_request_initial_review_history
           ADD CONSTRAINT fk_data_request_initial_review_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);


      ALTER TABLE ONLY data_request_initial_review_history
          ADD CONSTRAINT fk_data_request_initial_review_history_data_request_initial_reviews FOREIGN KEY (data_request_initial_review_id) REFERENCES data_request_initial_reviews(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
