
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_protocol_deviations deviation_occurred_when deviation_discovered_when select_severity deviation_description corrective_action_description

      CREATE FUNCTION log_grit_protocol_deviation_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO grit_protocol_deviation_history
                  (
                      master_id,
                      deviation_occurred_when,
                      deviation_discovered_when,
                      select_severity,
                      deviation_description,
                      corrective_action_description,
                      user_id,
                      created_at,
                      updated_at,
                      grit_protocol_deviation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.deviation_occurred_when,
                      NEW.deviation_discovered_when,
                      NEW.select_severity,
                      NEW.deviation_description,
                      NEW.corrective_action_description,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE grit_protocol_deviation_history (
          id integer NOT NULL,
          master_id integer,
          deviation_occurred_when date,
          deviation_discovered_when date,
          select_severity varchar,
          deviation_description varchar,
          corrective_action_description varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_protocol_deviation_id integer
      );

      CREATE SEQUENCE grit_protocol_deviation_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_protocol_deviation_history_id_seq OWNED BY grit_protocol_deviation_history.id;

      CREATE TABLE grit_protocol_deviations (
          id integer NOT NULL,
          master_id integer,
          deviation_occurred_when date,
          deviation_discovered_when date,
          select_severity varchar,
          deviation_description varchar,
          corrective_action_description varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_protocol_deviations_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_protocol_deviations_id_seq OWNED BY grit_protocol_deviations.id;

      ALTER TABLE ONLY grit_protocol_deviations ALTER COLUMN id SET DEFAULT nextval('grit_protocol_deviations_id_seq'::regclass);
      ALTER TABLE ONLY grit_protocol_deviation_history ALTER COLUMN id SET DEFAULT nextval('grit_protocol_deviation_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_protocol_deviation_history
          ADD CONSTRAINT grit_protocol_deviation_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_protocol_deviations
          ADD CONSTRAINT grit_protocol_deviations_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_protocol_deviation_history_on_master_id ON grit_protocol_deviation_history USING btree (master_id);


      CREATE INDEX index_grit_protocol_deviation_history_on_grit_protocol_deviation_id ON grit_protocol_deviation_history USING btree (grit_protocol_deviation_id);
      CREATE INDEX index_grit_protocol_deviation_history_on_user_id ON grit_protocol_deviation_history USING btree (user_id);

      CREATE INDEX index_grit_protocol_deviations_on_master_id ON grit_protocol_deviations USING btree (master_id);

      CREATE INDEX index_grit_protocol_deviations_on_user_id ON grit_protocol_deviations USING btree (user_id);

      CREATE TRIGGER grit_protocol_deviation_history_insert AFTER INSERT ON grit_protocol_deviations FOR EACH ROW EXECUTE PROCEDURE log_grit_protocol_deviation_update();
      CREATE TRIGGER grit_protocol_deviation_history_update AFTER UPDATE ON grit_protocol_deviations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_protocol_deviation_update();


      ALTER TABLE ONLY grit_protocol_deviations
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_protocol_deviations
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_protocol_deviation_history
          ADD CONSTRAINT fk_grit_protocol_deviation_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_protocol_deviation_history
          ADD CONSTRAINT fk_grit_protocol_deviation_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_protocol_deviation_history
          ADD CONSTRAINT fk_grit_protocol_deviation_history_grit_protocol_deviations FOREIGN KEY (grit_protocol_deviation_id) REFERENCES grit_protocol_deviations(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
