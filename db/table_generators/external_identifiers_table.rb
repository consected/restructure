module TableGenerators

  def self.external_identifiers_table name=nil, generate_table=false, attrib=nil
    if name.nil? || name == ''
      puts "Usage:
      db/table_generators/generate.sh external_identifiers_table <pluralized_table_name> create|drop 'identifier_field_id'
      "
      return
    end

    @implementation_table_name = name
    if name.end_with? 'ies'
      singular_name = name[0..-4] + 'y'
    elsif name.end_with? 's'
      singular_name = name[0..-2]
    else
      puts "The provided table name does not appear to be pluralized"
      return
    end

    unless generate_table == :drop || generate_table == :drop_do || attrib.end_with?('_id')
      puts "The identifier field must end with '_id'"
      return
    end

    if generate_table == :drop || generate_table == :drop_do
      sql = <<EOF

      DROP TABLE if exists #{singular_name}_history CASCADE;
      DROP TABLE if exists #{name} CASCADE;
      DROP FUNCTION if exists log_#{singular_name}_update();

EOF

    else

      # variable used for spec tests
      @implementation_attr_name = attrib

      sql = <<EOF

      CREATE FUNCTION log_#{singular_name}_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO #{singular_name}_history
                  (
                      master_id,
                      #{attrib},
                      user_id,
                      created_at,
                      updated_at,
                      #{singular_name}_table_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.#{attrib},
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;
      CREATE TABLE #{singular_name}_history (
          id integer NOT NULL,
          master_id integer,
          #{attrib} integer,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          #{singular_name}_table_id integer
      );

      CREATE SEQUENCE #{singular_name}_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE #{singular_name}_history_id_seq OWNED BY #{singular_name}_history.id;

      CREATE TABLE #{name} (
          id integer NOT NULL,
          master_id integer,
          #{attrib} integer,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
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
      CREATE INDEX index_#{singular_name}_history_on_#{singular_name}_table_id ON #{singular_name}_history USING btree (#{singular_name}_table_id);
      CREATE INDEX index_#{singular_name}_history_on_user_id ON #{singular_name}_history USING btree (user_id);

      CREATE INDEX index_#{name}_on_master_id ON #{name} USING btree (master_id);
      CREATE INDEX index_#{name}_on_user_id ON #{name} USING btree (user_id);

      CREATE TRIGGER #{singular_name}_history_insert AFTER INSERT ON #{name} FOR EACH ROW EXECUTE PROCEDURE log_#{singular_name}_update();
      CREATE TRIGGER #{singular_name}_history_update AFTER UPDATE ON #{name} FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_#{singular_name}_update();


      ALTER TABLE ONLY #{name}
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY #{name}
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


      ALTER TABLE ONLY #{singular_name}_history
          ADD CONSTRAINT fk_#{singular_name}_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY #{singular_name}_history
          ADD CONSTRAINT fk_#{singular_name}_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY #{singular_name}_history
          ADD CONSTRAINT fk_#{singular_name}_history_#{name} FOREIGN KEY (#{singular_name}_table_id) REFERENCES #{name}(id);

EOF
    end

    if generate_table == true || generate_table == :drop_do
        ActiveRecord::Base.connection.execute sql
    else
      sql = "
      BEGIN;
#{sql}
      COMMIT;"
      puts sql
      return sql
    end
  end



end
