class AddHistoryToNfsStoreArchivedFiles < ActiveRecord::Migration
  def change
#
reversible do |dir|
  dir.up do

execute <<EOF

-- Command line:
-- table_generators/generate.sh item_history_table create nfs_store_archived_files file_hash file_name content_type archive_file path file_size file_updated_at nfs_store_container_id title description file_metadata nfs_store_stored_file_id

CREATE FUNCTION log_nfs_store_archived_file_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO nfs_store_archived_file_history
            (
                file_hash,
                file_name,
                content_type,
                archive_file,
                path,
                file_size,
                file_updated_at,
                nfs_store_container_id,
                title,
                description,
                file_metadata,
                nfs_store_stored_file_id,
                user_id,
                created_at,
                updated_at,
                nfs_store_archived_file_id
                )
            SELECT
                NEW.file_hash,
                NEW.file_name,
                NEW.content_type,
                NEW.archive_file,
                NEW.path,
                NEW.file_size,
                NEW.file_updated_at,
                NEW.nfs_store_container_id,
                NEW.title,
                NEW.description,
                NEW.file_metadata,
                NEW.nfs_store_stored_file_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE nfs_store_archived_file_history (
    id integer NOT NULL,
    file_hash varchar,
    file_name varchar,
    content_type varchar,
    archive_file varchar,
    path varchar,
    file_size varchar,
    file_updated_at varchar,
    nfs_store_container_id bigint,
    title varchar,
    description varchar,
    file_metadata varchar,
    nfs_store_stored_file_id bigint,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_archived_file_id integer
);

CREATE SEQUENCE nfs_store_archived_file_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE nfs_store_archived_file_history_id_seq OWNED BY nfs_store_archived_file_history.id;

ALTER TABLE ONLY nfs_store_archived_file_history ALTER COLUMN id SET DEFAULT nextval('nfs_store_archived_file_history_id_seq'::regclass);

ALTER TABLE ONLY nfs_store_archived_file_history
    ADD CONSTRAINT nfs_store_archived_file_history_pkey PRIMARY KEY (id);


CREATE INDEX index_nfs_store_archived_file_history_on_nfs_store_archived_file_id ON nfs_store_archived_file_history USING btree (nfs_store_archived_file_id);
CREATE INDEX index_nfs_store_archived_file_history_on_user_id ON nfs_store_archived_file_history USING btree (user_id);

CREATE TRIGGER nfs_store_archived_file_history_insert AFTER INSERT ON nfs_store_archived_files FOR EACH ROW EXECUTE PROCEDURE log_nfs_store_archived_file_update();
CREATE TRIGGER nfs_store_archived_file_history_update AFTER UPDATE ON nfs_store_archived_files FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_nfs_store_archived_file_update();

ALTER TABLE ONLY nfs_store_archived_file_history
    ADD CONSTRAINT fk_nfs_store_archived_file_history_users FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY nfs_store_archived_file_history
    ADD CONSTRAINT fk_nfs_store_archived_file_history_nfs_store_archived_files FOREIGN KEY (nfs_store_archived_file_id) REFERENCES nfs_store_archived_files(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

EOF
end
dir.down do

execute <<EOF


DROP TABLE if exists nfs_store_archived_file_history CASCADE;
DROP FUNCTION if exists log_nfs_store_archived_file_update() CASCADE;

EOF

end
end



  end
end
