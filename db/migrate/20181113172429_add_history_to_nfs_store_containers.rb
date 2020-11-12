class AddHistoryToNfsStoreContainers < ActiveRecord::Migration

  def change

reversible do |dir|
  dir.up do

execute <<EOF

-- Command line:
-- table_generators/generate.sh item_history_table create nfs_store_containers name app_type_id nfs_store_container_id

CREATE FUNCTION log_nfs_store_container_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO nfs_store_container_history
            (
                master_id,
                name,
                app_type_id,
                orig_nfs_store_container_id,
                user_id,
                created_at,
                updated_at,
                nfs_store_container_id
                )
            SELECT
                NEW.master_id,
                NEW.name,
                NEW.app_type_id,
                NEW.nfs_store_container_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE nfs_store_container_history (
    id integer NOT NULL,
    master_id integer,
    name varchar,
    app_type_id bigint,
    orig_nfs_store_container_id bigint,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_container_id integer
);

CREATE SEQUENCE nfs_store_container_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE nfs_store_container_history_id_seq OWNED BY nfs_store_container_history.id;

ALTER TABLE ONLY nfs_store_container_history ALTER COLUMN id SET DEFAULT nextval('nfs_store_container_history_id_seq'::regclass);

ALTER TABLE ONLY nfs_store_container_history
    ADD CONSTRAINT nfs_store_container_history_pkey PRIMARY KEY (id);

CREATE INDEX index_nfs_store_container_history_on_master_id ON nfs_store_container_history USING btree (master_id);

CREATE INDEX index_nfs_store_container_history_on_nfs_store_container_id ON nfs_store_container_history USING btree (nfs_store_container_id);
CREATE INDEX index_nfs_store_container_history_on_user_id ON nfs_store_container_history USING btree (user_id);

CREATE TRIGGER nfs_store_container_history_insert AFTER INSERT ON nfs_store_containers FOR EACH ROW EXECUTE PROCEDURE log_nfs_store_container_update();
CREATE TRIGGER nfs_store_container_history_update AFTER UPDATE ON nfs_store_containers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_nfs_store_container_update();

ALTER TABLE ONLY nfs_store_container_history
    ADD CONSTRAINT fk_nfs_store_container_history_users FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY nfs_store_container_history
    ADD CONSTRAINT fk_nfs_store_container_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

ALTER TABLE ONLY nfs_store_container_history
    ADD CONSTRAINT fk_nfs_store_container_history_nfs_store_containers FOREIGN KEY (nfs_store_container_id) REFERENCES nfs_store_containers(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

EOF
end
dir.down do

execute <<EOF


DROP TABLE if exists nfs_store_container_history CASCADE;
DROP FUNCTION if exists log_nfs_store_container_update() CASCADE;

EOF

end
end


  end
end
