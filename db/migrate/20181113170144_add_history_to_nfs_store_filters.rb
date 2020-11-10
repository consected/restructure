class AddHistoryToNfsStoreFilters < ActiveRecord::Migration
  def change

#
reversible do |dir|
  dir.up do

execute <<EOF

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create nfs_store_filters app_type_id role_name user_id resource_name filter description

CREATE OR REPLACE FUNCTION log_nfs_store_filter_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO nfs_store_filter_history
            (
                app_type_id,
                role_name,
                user_id,
                resource_name,
                filter,
                description,
                admin_id,
                disabled,
                created_at,
                updated_at,
                nfs_store_filter_id
                )
            SELECT
                NEW.app_type_id,
                NEW.role_name,
                NEW.user_id,
                NEW.resource_name,
                NEW.filter,
                NEW.description,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE nfs_store_filter_history (
    id integer NOT NULL,
    app_type_id bigint,
    role_name varchar,
    user_id bigint,
    resource_name varchar,
    filter varchar,
    description varchar,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_filter_id integer
);

CREATE SEQUENCE nfs_store_filter_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE nfs_store_filter_history_id_seq OWNED BY nfs_store_filter_history.id;


ALTER TABLE ONLY nfs_store_filter_history ALTER COLUMN id SET DEFAULT nextval('nfs_store_filter_history_id_seq'::regclass);

ALTER TABLE ONLY nfs_store_filter_history
    ADD CONSTRAINT nfs_store_filter_history_pkey PRIMARY KEY (id);

CREATE INDEX index_nfs_store_filter_history_on_nfs_store_filter_id ON nfs_store_filter_history USING btree (nfs_store_filter_id);
CREATE INDEX index_nfs_store_filter_history_on_admin_id ON nfs_store_filter_history USING btree (admin_id);

CREATE TRIGGER nfs_store_filter_history_insert AFTER INSERT ON nfs_store_filters FOR EACH ROW EXECUTE PROCEDURE log_nfs_store_filter_update();
CREATE TRIGGER nfs_store_filter_history_update AFTER UPDATE ON nfs_store_filters FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_nfs_store_filter_update();

ALTER TABLE ONLY nfs_store_filter_history
    ADD CONSTRAINT fk_nfs_store_filter_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY nfs_store_filter_history
    ADD CONSTRAINT fk_nfs_store_filter_history_nfs_store_filters FOREIGN KEY (nfs_store_filter_id) REFERENCES nfs_store_filters(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

EOF
end
dir.down do

execute <<EOF


DROP TABLE if exists nfs_store_filter_history CASCADE;
DROP FUNCTION if exists log_nfs_store_filter_update() CASCADE;

EOF

end
end

    
  end
end
