# frozen_string_literal: true

module ActiveRecord
  class Migration
    module SqlHelpers
      def create_general_admin_history_trigger(schema, table_name, fields)
        return if reverting?

        execute general_admin_history_trigger_sql(schema, table_name, fields)
      end

      def general_admin_history_trigger_sql(schema, table_name, fields)
        history_table_name = "#{table_name.to_s.singularize}_history"
        history_table_id_attr = "#{table_name.to_s.singularize}_id"
        trigger_fn_name = "#{history_table_name}_upd"

        new_fields = fields.map { |f| "NEW.#{f}" }

        <<~DO_TEXT

          CREATE OR REPLACE FUNCTION #{schema}.#{trigger_fn_name} ()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS $$
          BEGIN
            INSERT INTO #{history_table_name} (
              #{"#{fields.join(', ')}," if fields.present?}
              disabled,
              admin_id,
              created_at,
              updated_at,
              #{history_table_id_attr})
            SELECT
              #{"#{new_fields.join(', ')}," if fields.present?}
              NEW.disabled,
              NEW.admin_id,
              NEW.created_at,
              NEW.updated_at,
              NEW.id;
            RETURN NEW;
          END;
          $$;

          DROP TRIGGER IF EXISTS log_#{history_table_name}_insert ON #{schema}.#{table_name};
          DROP TRIGGER IF EXISTS log_#{history_table_name}_update ON #{schema}.#{table_name};

          CREATE TRIGGER log_#{history_table_name}_insert
            AFTER INSERT ON #{schema}.#{table_name}
            FOR EACH ROW
            EXECUTE PROCEDURE #{trigger_fn_name} ();

          CREATE TRIGGER log_#{history_table_name}_update
            AFTER UPDATE ON #{schema}.#{table_name}
            FOR EACH ROW
            WHEN ((OLD.* IS DISTINCT FROM NEW.*))
            EXECUTE PROCEDURE #{trigger_fn_name} ();

        DO_TEXT
      end
    end
  end
end
