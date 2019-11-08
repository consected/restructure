
      BEGIN;

-- Command line:
-- table_generators/generate.sh create external_identifiers_table

      CREATE FUNCTION log_scantron_q2_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO scantron_q2_history
                  (
                      master_id,
                      q2_scantron_id,
                      user_id,
                      admin_id,
                      created_at,
                      updated_at,
                      scantron_q2_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.q2_scantron_id,
                      NEW.user_id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;
      CREATE TABLE scantron_q2_history (
          id integer NOT NULL,
          master_id integer,
          q2_scantron_id bigint,
          user_id integer,
          admin_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          scantron_q2_table_id integer
      );

      CREATE SEQUENCE scantron_q2_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE scantron_q2_history_id_seq OWNED BY scantron_q2_history.id;


      alter table scantron_q2s add column admin_id integer;
      -- CREATE TABLE scantron_q2s (
      --     id integer NOT NULL,
      --     master_id integer,
      --     q2_scantron_id bigint,
      --     user_id integer,
      --     admin_id integer,
      --     created_at timestamp without time zone NOT NULL,
      --     updated_at timestamp without time zone NOT NULL
      -- );
      -- CREATE SEQUENCE scantron_q2s_id_seq
      --     START WITH 1
      --     INCREMENT BY 1
      --     NO MINVALUE
      --     NO MAXVALUE
      --     CACHE 1;
      --
      -- ALTER SEQUENCE scantron_q2s_id_seq OWNED BY scantron_q2s.id;

      -- ALTER TABLE ONLY scantron_q2s ALTER COLUMN id SET DEFAULT nextval('scantron_q2s_id_seq'::regclass);
      ALTER TABLE ONLY scantron_q2_history ALTER COLUMN id SET DEFAULT nextval('scantron_q2_history_id_seq'::regclass);

      ALTER TABLE ONLY scantron_q2_history
          ADD CONSTRAINT scantron_q2_history_pkey PRIMARY KEY (id);

      -- ALTER TABLE ONLY scantron_q2s
      --     ADD CONSTRAINT scantron_q2s_pkey PRIMARY KEY (id);

      CREATE INDEX index_scantron_q2_history_on_master_id ON scantron_q2_history USING btree (master_id);
      CREATE INDEX index_scantron_q2_history_on_scantron_q2_table_id ON scantron_q2_history USING btree (scantron_q2_table_id);
      CREATE INDEX index_scantron_q2_history_on_user_id ON scantron_q2_history USING btree (user_id);
      CREATE INDEX index_scantron_q2_history_on_admin_id ON scantron_q2_history USING btree (admin_id);

      CREATE INDEX index_scantron_q2s_on_master_id ON scantron_q2s USING btree (master_id);
      CREATE INDEX index_scantron_q2s_on_user_id ON scantron_q2s USING btree (user_id);
      CREATE INDEX index_scantron_q2s_on_admin_id ON scantron_q2s USING btree (admin_id);

      CREATE TRIGGER scantron_q2_history_insert AFTER INSERT ON scantron_q2s FOR EACH ROW EXECUTE PROCEDURE log_scantron_q2_update();
      CREATE TRIGGER scantron_q2_history_update AFTER UPDATE ON scantron_q2s FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_scantron_q2_update();


      ALTER TABLE ONLY scantron_q2s
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY scantron_q2s
          ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY scantron_q2s
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


      ALTER TABLE ONLY scantron_q2_history
          ADD CONSTRAINT fk_scantron_q2_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY scantron_q2_history
          ADD CONSTRAINT fk_scantron_q2_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY scantron_q2_history
          ADD CONSTRAINT fk_scantron_q2_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY scantron_q2_history
          ADD CONSTRAINT fk_scantron_q2_history_scantron_q2s FOREIGN KEY (scantron_q2_table_id) REFERENCES scantron_q2s(id);


      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
