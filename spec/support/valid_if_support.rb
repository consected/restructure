# frozen_string_literal: true

# Support module for testing valid_if functionality in dynamic models
# Provides helpers to create test dynamic models with validation configurations
module ValidIfSupport
  # Create a test dynamic model with the specified options YAML
  # Expects the including spec to define: table_name, schema_name, resource_name, @admin, @user
  #
  # @param options_yaml [String] YAML configuration for the dynamic model options
  # @param field_list [String] Space-separated list of fields (default: 'email status')
  # @return [DynamicModel] The created dynamic model
  def create_test_dm(options_yaml, field_list: 'email status')
    # First generate the DB table
    generate_table(field_list:)

    # Disable any existing dynamic models with this table name and clear the constant cache
    DynamicModel.active.where(table_name:).reload.each { |dm| dm.disable!(@admin) }

    # Remove the constant to clear Rails class cache
    class_name = table_name.to_s.ns_camelize.singularize.to_sym
    DynamicModel.send(:remove_const, class_name) if DynamicModel.const_defined?(class_name)

    dm = DynamicModel.create!(
      table_name:,
      schema_name:,
      name: table_name.to_s.humanize.titleize,
      description: "Test valid_if functionality for #{table_name}",
      primary_key_name: 'id',
      foreign_key_name: 'master_id',
      category: 'test',
      table_key_name: nil,
      field_list:,
      result_order: 'id',
      current_admin: @admin,
      options: options_yaml
    )

    dm.update_tracker_events
    setup_access resource_name, user: @user
    expect(@user.has_access_to?(:create, :table, resource_name)).to be_truthy

    # Reset version cache to ensure clean state
    dm.send :reset_all_versions

    dm
  end

  # Generate a test table with the specified fields
  # Creates both the main table and history table with triggers
  # Expects the including spec to define: table_name, schema_name
  #
  # @param field_list [String] Space-separated list of fields (default: 'email status')
  def generate_table(field_list: 'email status')
    fields = field_list.split.map(&:strip)

    # Build field definitions for both tables
    field_defs = fields.map { |f| "#{f} varchar" }.join(",\n        ")
    history_field_defs = fields.map { |f| "#{f} varchar" }.join(",\n        ")
    history_field_names = fields.join(",\n              ")
    history_new_fields = fields.map { |f| "NEW.#{f}" }.join(",\n              ")

    sql = <<~SQL
      CREATE TABLE IF NOT EXISTS #{schema_name}.#{table_name} (
        id serial PRIMARY KEY,
        master_id integer,
        #{field_defs},
        user_id integer,
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        disabled boolean
      );

      CREATE TABLE IF NOT EXISTS #{schema_name}.#{table_name.singularize}_history (
        id serial PRIMARY KEY,
        master_id integer,
        #{history_field_defs},
        user_id integer,
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        disabled boolean,
        #{table_name.singularize}_id integer
      );

      CREATE OR REPLACE FUNCTION #{schema_name}.log_#{table_name.singularize}_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
          BEGIN
            INSERT INTO #{schema_name}.#{table_name.singularize}_history
            (
              master_id,
              #{history_field_names},
              user_id,
              created_at,
              updated_at,
              #{table_name.singularize}_id
            )
            SELECT
              NEW.master_id,
              #{history_new_fields},
              NEW.user_id,
              NEW.created_at,
              NEW.updated_at,
              NEW.id
            ;
            RETURN NEW;
          END;
        $$;

      DROP TRIGGER IF EXISTS #{table_name.singularize}_history_insert ON #{schema_name}.#{table_name};
      CREATE TRIGGER #{table_name.singularize}_history_insert
        AFTER INSERT OR UPDATE ON #{schema_name}.#{table_name}
        FOR EACH ROW EXECUTE PROCEDURE #{schema_name}.log_#{table_name.singularize}_update();
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end

  # Clean up test tables and dynamic models
  # Expects the including spec to define: table_name, schema_name
  def cleanup_test_dm
    if ActiveRecord::Base.connection.table_exists?(table_name)
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{schema_name}.#{table_name} CASCADE;")
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{schema_name}.#{table_name.singularize}_history CASCADE;")
      ActiveRecord::Base.connection.execute("DROP FUNCTION IF EXISTS #{schema_name}.log_#{table_name.singularize}_update() CASCADE;")
    end

    # Delete dynamic model history first, then the dynamic model
    DynamicModel.where(table_name:).each do |dm|
      ActiveRecord::Base.connection.execute("DELETE FROM dynamic_model_history WHERE dynamic_model_id = #{dm.id}")
      dm.delete
    end

    # Force reload of dynamic model classes
    DynamicModel.routes_reload
  end

  # Create a new record instance for the test dynamic model
  # Expects the including spec to define: resource_class, @master, @user
  #
  # @param attributes [Hash] Attributes to set on the record
  # @return [ActiveRecord::Base] New record instance
  def make_test_record(**attributes)
    resource_class.new(
      master: @master,
      current_user: @user,
      **attributes
    )
  end
end
