module TableGenerators

  def self.activity_logs_table *args
    name=args[0]
    generate_table=args[1]
    attrib = args[2..-1]
    if name.nil? || attrib.nil?
      puts "Usage:
      ruby -e \"require './db/table_generators/activity_logs_table.rb'; TableGenerators.activity_logs_table('pluralized_table_name', false, 'field1', 'field2', ...)\"
      Then edit the result to change the field-type for the two CREATE TABLE statements at the top of the results.
      "
      exit
    end

    @implementation_table_name = name
    if name.end_with? 'ies'
      singular_name = name[0..-4] + 'y'
    elsif name.end_with? 's'
      singular_name = name[0..-2]
    else
      puts "The provided table name does not appear to be pluralized"
      exit
    end

    item_type_id = "#{singular_name.sub('activity_log_','')}_id"


    @implementation_attr_name = attrib
    sql = <<EOF
    BEGIN;


    CREATE TABLE #{singular_name}_history (
        id integer NOT NULL,
        master_id integer,
        #{item_type_id} integer,
        #{attrib.join(" <field-type>,\n        ")} <field-type>,
        user_id integer,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        #{singular_name}_id integer
    );
    CREATE TABLE #{name} (
        id integer NOT NULL,
        master_id integer,
        #{item_type_id} integer,
        #{attrib.join(" <field-type>,\n        ")} <field-type>,
        user_id integer,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    );

    CREATE FUNCTION log_#{singular_name}_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO #{singular_name}_history
                (
                    master_id,
                    #{item_type_id},
                    #{attrib.join(",\n")},
                    user_id,
                    created_at,
                    updated_at,
                    #{singular_name}_id
                    )
                SELECT
                    NEW.master_id,
                    NEW.#{item_type_id},
                    NEW.#{attrib.join(",\n")},
                    NEW.user_id,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;

    CREATE SEQUENCE #{singular_name}_history_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;

    ALTER SEQUENCE #{singular_name}_history_id_seq OWNED BY #{singular_name}_history.id;


    CREATE SEQUENCE #{name}_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;

    ALTER SEQUENCE #{name}_id_seq OWNED BY #{name}.id;

    ALTER TABLE ONLY #{name} ALTER COLUMN id SET DEFAULT nextval('#{name}_id_seq'::regclass);
    ALTER TABLE ONLY #{singular_name}_history ALTER COLUMN id SET DEFAULT nextval('#{singular_name}_history_id_seq'::regclass);

    ALTER TABLE ONLY #{singular_name}_history
        ADD CONSTRAINT #{singular_name}_history_pkey PRIMARY KEY (id);

    ALTER TABLE ONLY #{name}
        ADD CONSTRAINT #{name}_pkey PRIMARY KEY (id);

    CREATE INDEX index_#{singular_name}_history_on_master_id ON #{singular_name}_history USING btree (master_id);
    CREATE INDEX index_#{singular_name}_history_on_#{item_type_id} ON #{singular_name}_history USING btree (#{item_type_id});

    CREATE INDEX index_#{singular_name}_history_on_#{singular_name}_id ON #{singular_name}_history USING btree (#{singular_name}_id);
    CREATE INDEX index_#{singular_name}_history_on_user_id ON #{singular_name}_history USING btree (user_id);

    CREATE INDEX index_#{name}_on_master_id ON #{name} USING btree (master_id);
    CREATE INDEX index_#{name}_on_#{item_type_id} ON #{name} USING btree (#{item_type_id});
    CREATE INDEX index_#{name}_on_user_id ON #{name} USING btree (user_id);

    CREATE TRIGGER #{singular_name}_history_insert AFTER INSERT ON #{name} FOR EACH ROW EXECUTE PROCEDURE log_#{singular_name}_update();
    CREATE TRIGGER #{singular_name}_history_update AFTER UPDATE ON #{name} FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_#{singular_name}_update();


    ALTER TABLE ONLY #{name}
        ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
    ALTER TABLE ONLY #{name}
        ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
    ALTER TABLE ONLY #{name}
        ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (#{item_type_id}) REFERENCES masters(id);

    ALTER TABLE ONLY #{singular_name}_history
        ADD CONSTRAINT fk_#{singular_name}_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

    ALTER TABLE ONLY #{singular_name}_history
        ADD CONSTRAINT fk_#{singular_name}_history_#{item_type_id} FOREIGN KEY (#{item_type_id}) REFERENCES masters(id);

    ALTER TABLE ONLY #{singular_name}_history
        ADD CONSTRAINT fk_#{singular_name}_history_#{name} FOREIGN KEY (#{singular_name}_id) REFERENCES #{name}(id);

    ALTER TABLE ONLY #{singular_name}_history
        ADD CONSTRAINT fk_#{singular_name}_history_users FOREIGN KEY (user_id) REFERENCES users(id);


    COMMIT;

EOF

    if generate_table
      ActiveRecord::Base.connection.execute sql
    else
      puts sql
    end
  end



end
