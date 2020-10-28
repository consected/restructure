class CreateActivityLogPlayerContactPhoneHistory < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do
        execute <<EOF


    CREATE TABLE activity_log_player_contact_phone_history (
        id integer NOT NULL,
        master_id integer,
        player_contact_id integer,
        data varchar,
        select_call_direction varchar,
        select_who varchar,
        called_when date,
        select_result varchar,
        select_next_step varchar,
        follow_up_when date,
        notes varchar,
        protocol_id integer,
        set_related_player_contact_rank varchar,
        user_id integer,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        activity_log_player_contact_phone_id integer
    );

    CREATE FUNCTION log_activity_log_player_contact_phone_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO activity_log_player_contact_phone_history
                (
                    master_id,
                    player_contact_id,
                    data,
                    select_call_direction,
                    select_who,
                    called_when,
                    select_result,
                    select_next_step,
                    follow_up_when,
                    notes,
                    protocol_id,
                    set_related_player_contact_rank,
                    user_id,
                    created_at,
                    updated_at,
                    activity_log_player_contact_phone_id
                    )
                SELECT
                    NEW.master_id,
                    NEW.player_contact_id,
                    NEW.data,
                    NEW.select_call_direction,
                    NEW.select_who,
                    NEW.called_when,
                    NEW.select_result,
                    NEW.select_next_step,
                    NEW.follow_up_when,
                    NEW.notes,
                    NEW.protocol_id,
                    NEW.set_related_player_contact_rank,
                    NEW.user_id,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;

    CREATE SEQUENCE activity_log_player_contact_phone_history_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;

    ALTER SEQUENCE activity_log_player_contact_phone_history_id_seq OWNED BY activity_log_player_contact_phone_history.id;

    ALTER TABLE ONLY activity_log_player_contact_phone_history ALTER COLUMN id SET DEFAULT nextval('activity_log_player_contact_phone_history_id_seq'::regclass);

    ALTER TABLE ONLY activity_log_player_contact_phone_history
        ADD CONSTRAINT activity_log_player_contact_phone_history_pkey PRIMARY KEY (id);

    CREATE INDEX index_activity_log_player_contact_phone_history_on_master_id ON activity_log_player_contact_phone_history USING btree (master_id);
    CREATE INDEX index_activity_log_player_contact_phone_history_on_player_contact_phone_id ON activity_log_player_contact_phone_history USING btree (player_contact_id);

    CREATE INDEX index_activity_log_player_contact_phone_history_on_activity_log_player_contact_phone_id ON activity_log_player_contact_phone_history USING btree (activity_log_player_contact_phone_id);
    CREATE INDEX index_activity_log_player_contact_phone_history_on_user_id ON activity_log_player_contact_phone_history USING btree (user_id);

    CREATE TRIGGER activity_log_player_contact_phone_history_insert AFTER INSERT ON activity_log_player_contact_phones FOR EACH ROW EXECUTE PROCEDURE log_activity_log_player_contact_phone_update();
    CREATE TRIGGER activity_log_player_contact_phone_history_update AFTER UPDATE ON activity_log_player_contact_phones FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_player_contact_phone_update();

    ALTER TABLE ONLY activity_log_player_contact_phone_history
        ADD CONSTRAINT fk_activity_log_player_contact_phone_history_users FOREIGN KEY (user_id) REFERENCES users(id);

    ALTER TABLE ONLY activity_log_player_contact_phone_history
        ADD CONSTRAINT fk_activity_log_player_contact_phone_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

    ALTER TABLE ONLY activity_log_player_contact_phone_history
        ADD CONSTRAINT fk_activity_log_player_contact_phone_history_player_contact_phone_id FOREIGN KEY (player_contact_id) REFERENCES player_contacts(id);

    ALTER TABLE ONLY activity_log_player_contact_phone_history
        ADD CONSTRAINT fk_activity_log_player_contact_phone_history_activity_log_player_contact_phones FOREIGN KEY (activity_log_player_contact_phone_id) REFERENCES activity_log_player_contact_phones(id);

EOF

      end

      dir.down do
execute <<EOF

DROP TRIGGER IF EXISTS activity_log_player_contact_phone_history on activity_log_player_contact_phones;
DROP TRIGGER IF EXISTS activity_log_player_contact_phone_history on activity_log_player_contact_phones;
DROP FUNCTION IF EXISTS log_activity_log_player_contact_phone_update();

EOF
      end
    end
  end
end
