
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_assign_to_groups select_group

      CREATE FUNCTION log_grit_assign_to_group_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO grit_assign_to_group_history
                  (
                      master_id,
                      select_group,
                      user_id,
                      created_at,
                      updated_at,
                      grit_assign_to_group_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_group,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE grit_assign_to_group_history (
          id integer NOT NULL,
          master_id integer,
          select_group varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_assign_to_group_id integer
      );

      CREATE SEQUENCE grit_assign_to_group_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_assign_to_group_history_id_seq OWNED BY grit_assign_to_group_history.id;

      CREATE TABLE grit_assign_to_groups (
          id integer NOT NULL,
          master_id integer,
          select_group varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_assign_to_groups_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_assign_to_groups_id_seq OWNED BY grit_assign_to_groups.id;

      ALTER TABLE ONLY grit_assign_to_groups ALTER COLUMN id SET DEFAULT nextval('grit_assign_to_groups_id_seq'::regclass);
      ALTER TABLE ONLY grit_assign_to_group_history ALTER COLUMN id SET DEFAULT nextval('grit_assign_to_group_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_assign_to_group_history
          ADD CONSTRAINT grit_assign_to_group_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_assign_to_groups
          ADD CONSTRAINT grit_assign_to_groups_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_assign_to_group_history_on_master_id ON grit_assign_to_group_history USING btree (master_id);


      CREATE INDEX index_grit_assign_to_group_history_on_grit_assign_to_group_id ON grit_assign_to_group_history USING btree (grit_assign_to_group_id);
      CREATE INDEX index_grit_assign_to_group_history_on_user_id ON grit_assign_to_group_history USING btree (user_id);

      CREATE INDEX index_grit_assign_to_groups_on_master_id ON grit_assign_to_groups USING btree (master_id);

      CREATE INDEX index_grit_assign_to_groups_on_user_id ON grit_assign_to_groups USING btree (user_id);

      CREATE TRIGGER grit_assign_to_group_history_insert AFTER INSERT ON grit_assign_to_groups FOR EACH ROW EXECUTE PROCEDURE log_grit_assign_to_group_update();
      CREATE TRIGGER grit_assign_to_group_history_update AFTER UPDATE ON grit_assign_to_groups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_assign_to_group_update();


      ALTER TABLE ONLY grit_assign_to_groups
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_assign_to_groups
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_assign_to_group_history
          ADD CONSTRAINT fk_grit_assign_to_group_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_assign_to_group_history
          ADD CONSTRAINT fk_grit_assign_to_group_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_assign_to_group_history
          ADD CONSTRAINT fk_grit_assign_to_group_history_grit_assign_to_groups FOREIGN KEY (grit_assign_to_group_id) REFERENCES grit_assign_to_groups(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
