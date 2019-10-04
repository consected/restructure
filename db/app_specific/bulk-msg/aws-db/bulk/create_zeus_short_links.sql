set search_path=bulk_msg,ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create zeus_short_links url shortcode clicks next_check_date

      CREATE or REPLACE FUNCTION log_zeus_short_link_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO zeus_short_link_history
                  (
                      master_id,
                      domain,
                      url,
                      shortcode,
                      clicks,
                      next_check_date,
                      for_item_type,
                      for_item_id,
                      user_id,
                      created_at,
                      updated_at,
                      zeus_short_link_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.domain,
                      NEW.url,
                      NEW.shortcode,
                      NEW.clicks,
                      NEW.next_check_date,
                      NEW.for_item_type,
                      NEW.for_item_id,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE zeus_short_link_history (
          id integer NOT NULL,
          master_id integer,
          domain varchar,
          url varchar,
          shortcode varchar,
          clicks integer default 0,
          next_check_date date,
          for_item_type varchar,
          for_item_id integer,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          zeus_short_link_id integer
      );

      CREATE SEQUENCE zeus_short_link_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE zeus_short_link_history_id_seq OWNED BY zeus_short_link_history.id;

      CREATE TABLE zeus_short_links (
          id integer NOT NULL,
          master_id integer,
          domain varchar,
          url varchar,
          shortcode varchar,
          clicks integer default 0,
          next_check_date date,
          for_item_type varchar,
          for_item_id integer,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE zeus_short_links_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE zeus_short_links_id_seq OWNED BY zeus_short_links.id;

      ALTER TABLE ONLY zeus_short_links ALTER COLUMN id SET DEFAULT nextval('zeus_short_links_id_seq'::regclass);
      ALTER TABLE ONLY zeus_short_link_history ALTER COLUMN id SET DEFAULT nextval('zeus_short_link_history_id_seq'::regclass);

      ALTER TABLE ONLY zeus_short_link_history
          ADD CONSTRAINT zeus_short_link_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY zeus_short_links
          ADD CONSTRAINT zeus_short_links_pkey PRIMARY KEY (id);

      CREATE INDEX index_zeus_short_link_history_on_master_id ON zeus_short_link_history USING btree (master_id);


      CREATE INDEX index_zeus_short_link_history_on_zeus_short_link_id ON zeus_short_link_history USING btree (zeus_short_link_id);
      CREATE INDEX index_zeus_short_link_history_on_user_id ON zeus_short_link_history USING btree (user_id);

      CREATE INDEX index_zeus_short_links_on_master_id ON zeus_short_links USING btree (master_id);

      CREATE INDEX index_zeus_short_links_on_user_id ON zeus_short_links USING btree (user_id);

      CREATE TRIGGER zeus_short_link_history_insert AFTER INSERT ON zeus_short_links FOR EACH ROW EXECUTE PROCEDURE log_zeus_short_link_update();
      CREATE TRIGGER zeus_short_link_history_update AFTER UPDATE ON zeus_short_links FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_zeus_short_link_update();


      ALTER TABLE ONLY zeus_short_links
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY zeus_short_links
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY zeus_short_link_history
          ADD CONSTRAINT fk_zeus_short_link_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY zeus_short_link_history
          ADD CONSTRAINT fk_zeus_short_link_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY zeus_short_link_history
          ADD CONSTRAINT fk_zeus_short_link_history_zeus_short_links FOREIGN KEY (zeus_short_link_id) REFERENCES zeus_short_links(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
