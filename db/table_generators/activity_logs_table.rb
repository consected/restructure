# frozen_string_literal: true

module TableGenerators
  def self.singularize(str)
    if str.end_with? 'ies'
      str[0..-4] + 'y'
    elsif str.end_with? 'es'
      str[0..-3]
    elsif str.end_with? 's'
      str[0..-2]
    end
  end

  # Arguments:
  # desired table name (plural)
  # base parent table name (plural)
  # true to generate, false to create script text, :drop to create drop sql, :drop_do to actually drop the table
  # field names for the table
  def self.activity_logs_table(*args)
    name = args[0]
    base_name_plural = args[1]
    generate_table = args[2]
    attrib = args[3..-1]

    if name.nil?
      puts "Usage:
      db/table_generators/generate.sh activity_logs_table create <pluralized_table_name> <base_name_without_rectype>  'field1' 'field2' ...)\"
      Then edit the result to change the field-type for the two CREATE TABLE statements at the top of the results.
      "
      return
    end

    name = 'activity_log_' + name unless name.start_with? 'activity_log_'
    created_by = nil

    @implementation_table_name = name
    singular_name = singularize(name)
    short_name = singular_name.sub('activity_log_', 'al_')

    unless singular_name
      puts 'The provided table name does not appear to be pluralized'
      return
    end

    item_type_name = base_name_plural
    base_name = singularize(base_name_plural)
    unless base_name
      puts 'The provided base name does not appear to be pluralized'
      return
    end

    base_name_id = "#{base_name}_id"

    item_type_id = "#{singular_name.sub('activity_log_', '')}_id"

    if %i[drop drop_do].include?(generate_table)
      sql = <<EOF

      DROP TABLE if exists #{singular_name}_history CASCADE;
      DROP TABLE if exists #{name} CASCADE;
      DROP FUNCTION if exists log_#{singular_name}_update();


EOF

    else

      @implementation_attr_name = attrib
      attrib.reject! { |a| a.start_with? 'placeholder_' }
      attrib_pair = {}
      attrib.each do |a|
        f = 'varchar'
        f = 'bigint' if a.end_with?('_id')
        if a == 'created_by_user_id'
          created_by = true
          f = 'integer'
        end
        f = 'date' if a.end_with?('_when')
        f = 'date' if a.end_with?('_date')
        f = 'time' if a.end_with?('_time')
        f = 'timestamp' if a.end_with?('_at')
        f = 'varchar' if a == 'data'
        f = 'varchar' if a.end_with?('_name')
        f = 'boolean' if a.end_with?('_check')
        f = 'varchar' if a == 'notes'
        f = 'varchar' if a.start_with?('select_')
        f = 'varchar[]' if a.start_with?('tag_select_')
        f = 'integer' if a == 'age'
        f = 'integer' if a.start_with?('number_')
        f = 'integer' if a.end_with?('_number')
        f = 'integer' if a.end_with?('_timestamp')
        f = 'jsonb' if a.end_with?('_json')
        f += ','
        attrib_pair[a] = f
      end

      sql = <<~EOF

        -- Command line:
        -- table_generators/generate.sh activity_logs_table create #{name} #{base_name} #{attrib.join(' ')}

              CREATE TABLE #{singular_name}_history (
                  id integer NOT NULL,
                  master_id integer,
                  #{base_name_id} integer,
                  #{attrib_pair.map { |a, f| "#{a} #{f}" }.join("\n          ")}
                  extra_log_type varchar,
                  user_id integer,
                  created_at timestamp without time zone NOT NULL,
                  updated_at timestamp without time zone NOT NULL,
                  disabled boolean default false,
                  #{singular_name}_id integer
              );
              CREATE TABLE #{name} (
                  id integer NOT NULL,
                  master_id integer,
                  #{base_name_id} integer,
                  #{attrib_pair.map { |a, f| "#{a} #{f}" }.join("\n          ")}
                  extra_log_type varchar,
                  user_id integer,
                  created_at timestamp without time zone NOT NULL,
                  updated_at timestamp without time zone NOT NULL,
                  disabled boolean default false
              );

              CREATE FUNCTION log_#{singular_name}_update() RETURNS trigger
                  LANGUAGE plpgsql
                  AS $$
                      BEGIN
                          INSERT INTO #{singular_name}_history
                          (
                              master_id,
                              #{base_name_id},
                              #{attrib.join(",\n                      ")}#{!attrib.empty? ? ',' : ''}
                              extra_log_type,
                              user_id,
                              created_at,
                              updated_at,
                              disabled,
                              #{singular_name}_id
                              )
                          SELECT
                              NEW.master_id,
                              NEW.#{base_name_id},
                              #{!attrib.empty? ? 'NEW.' : ''}#{attrib.join(",\n                      NEW.")}#{!attrib.empty? ? ',' : ''}
                              NEW.extra_log_type,
                              NEW.user_id,
                              NEW.created_at,
                              NEW.updated_at,
                              NEW.disabled,
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

              CREATE INDEX index_#{short_name}_history_on_master_id ON #{singular_name}_history USING btree (master_id);
              CREATE INDEX index_#{short_name}_history_on_#{item_type_id} ON #{singular_name}_history USING btree (#{base_name_id});

              CREATE INDEX index_#{short_name}_history_on_#{singular_name}_id ON #{singular_name}_history USING btree (#{singular_name}_id);
              CREATE INDEX index_#{short_name}_history_on_user_id ON #{singular_name}_history USING btree (user_id);

              CREATE INDEX index_#{name}_on_master_id ON #{name} USING btree (master_id);
              CREATE INDEX index_#{name}_on_#{item_type_id} ON #{name} USING btree (#{base_name_id});
              CREATE INDEX index_#{name}_on_user_id ON #{name} USING btree (user_id);

              CREATE TRIGGER #{singular_name}_history_insert AFTER INSERT ON #{name} FOR EACH ROW EXECUTE PROCEDURE log_#{singular_name}_update();
              CREATE TRIGGER #{singular_name}_history_update AFTER UPDATE ON #{name} FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_#{singular_name}_update();


              ALTER TABLE ONLY #{name}
                  ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
              ALTER TABLE ONLY #{name}
                  ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
              ALTER TABLE ONLY #{name}
                  ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (#{base_name_id}) REFERENCES #{item_type_name}(id);
              #{created_by ? '' : '--'} ALTER TABLE ONLY #{name}
              #{created_by ? '' : '--'}     ADD CONSTRAINT fk_rails_982635401e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);

              ALTER TABLE ONLY #{singular_name}_history
                  ADD CONSTRAINT fk_#{singular_name}_history_users FOREIGN KEY (user_id) REFERENCES users(id);

              ALTER TABLE ONLY #{singular_name}_history
                  ADD CONSTRAINT fk_#{singular_name}_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

              ALTER TABLE ONLY #{singular_name}_history
                  ADD CONSTRAINT fk_#{singular_name}_history_#{item_type_id} FOREIGN KEY (#{base_name_id}) REFERENCES #{item_type_name}(id);

              ALTER TABLE ONLY #{singular_name}_history
                  ADD CONSTRAINT fk_#{singular_name}_history_#{name} FOREIGN KEY (#{singular_name}_id) REFERENCES #{name}(id);
        #{'      '}
              #{created_by ? '' : '--'} ALTER TABLE ONLY #{singular_name}_history
              #{created_by ? '' : '--'}     ADD CONSTRAINT fk_#{singular_name}_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);


              GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
              GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
              GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      EOF
    end

    if [true, :create_do, :drop_do].include?(generate_table)
      ActivityLog.connection.execute sql
      ActiveRecord::Base.connection.schema_cache.clear!
    else
      sql = "
      BEGIN;
#{sql}
      COMMIT;"
      puts sql
      sql
    end
  end
end
