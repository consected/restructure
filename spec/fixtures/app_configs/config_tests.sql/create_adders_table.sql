set search_path=ml_app;


      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create adders 

      CREATE FUNCTION log_adder_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO adder_history
                  (
                      master_id,
                      
                      user_id,
                      created_at,
                      updated_at,
                      adder_id
                      )
                  SELECT
                      NEW.master_id,
                      
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE adder_history (
          id integer NOT NULL,
          master_id integer,
          
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          adder_id integer
      );

      CREATE SEQUENCE adder_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE adder_history_id_seq OWNED BY adder_history.id;

      CREATE TABLE adders (
          id integer NOT NULL,
          master_id integer,
          
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE adders_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE adders_id_seq OWNED BY adders.id;

      ALTER TABLE ONLY adders ALTER COLUMN id SET DEFAULT nextval('adders_id_seq'::regclass);
      ALTER TABLE ONLY adder_history ALTER COLUMN id SET DEFAULT nextval('adder_history_id_seq'::regclass);

      ALTER TABLE ONLY adder_history
          ADD CONSTRAINT adder_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY adders
          ADD CONSTRAINT adders_pkey PRIMARY KEY (id);

      CREATE INDEX index_adder_history_on_master_id ON adder_history USING btree (master_id);


      CREATE INDEX index_adder_history_on_adder_id ON adder_history USING btree (adder_id);
      CREATE INDEX index_adder_history_on_user_id ON adder_history USING btree (user_id);

      CREATE INDEX index_adders_on_master_id ON adders USING btree (master_id);

      CREATE INDEX index_adders_on_user_id ON adders USING btree (user_id);

      CREATE TRIGGER adder_history_insert AFTER INSERT ON adders FOR EACH ROW EXECUTE PROCEDURE log_adder_update();
      CREATE TRIGGER adder_history_update AFTER UPDATE ON adders FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_adder_update();


      ALTER TABLE ONLY adders
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY adders
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY adder_history
          ADD CONSTRAINT fk_adder_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY adder_history
          ADD CONSTRAINT fk_adder_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY adder_history
          ADD CONSTRAINT fk_adder_history_adders FOREIGN KEY (adder_id) REFERENCES adders(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
