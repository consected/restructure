# frozen_string_literal: true

module ActiveRecord
  class Migration
    module AppGenerator
      extend ActiveSupport::Concern

      included do
        attr_accessor :fields, :new_fields, :field_defs,
                      :field_opts, :schema, :owner, :table_name,
                      :belongs_to_model, :history_table_name, :trigger_fn_name,
                      :table_comment, :fields_comments, :mode
      end

      def create_schema
        sql = "CREATE SCHEMA IF NOT EXISTS #{schema}"
        sql += " AUTHORIZATION #{owner}" if owner.present?
        ActiveRecord::Base.connection.execute sql
      end

      def add_fields_to_tables
        setup_fields

        add_fields "#{schema}.#{table_name}"
        add_fields "#{schema}.#{history_table_name}"
      end

      def create_activity_log_tables
        setup_fields

        self.belongs_to_model = belongs_to_model.to_s.underscore

        create_table "#{schema}.#{table_name}", comment: table_comment do |t|
          t.belongs_to :master, index: { name: "al_#{belongs_to_model.singularize}_master_id_idx" }, foreign_key: true
          t.belongs_to belongs_to_model, index: { name: "al_#{belongs_to_model.singularize}_id_idx" }, foreign_key: true
          create_fields t
          t.string :extra_log_type
          t.references :user, index: { name: "al_#{belongs_to_model.singularize}_user_id_idx" }, foreign_key: true
          t.timestamps null: false
        end

        create_table "#{schema}.#{history_table_name}" do |t|
          t.belongs_to :master, index: { name: "al_#{belongs_to_model.singularize}_master_id_h_idx" }, foreign_key: true
          t.belongs_to belongs_to_model,
                       index: { name: "al_#{belongs_to_model.singularize}_id_h_idx" },
                       foreign_key: { to_table: "#{schema}.#{belongs_to_model.pluralize}" }
          create_fields t
          t.string :extra_log_type
          t.references :user, index: { name: "al_#{belongs_to_model.singularize}_user_id_h_idx" }, foreign_key: true
          t.timestamps null: false

          t.belongs_to table_name.singularize, index: { name: "#{table_name.singularize}_id_h_idx" }, foreign_key: { to_table: "#{schema}.#{table_name}" }
        end
      end

      def create_activity_log_trigger
        setup_fields

        reversible do |dir|
          dir.up do
            ActiveRecord::Base.connection.execute activity_log_trigger_sql
          end
          dir.down do
            ActiveRecord::Base.connection.execute reverse_activity_log_trigger_sql
          end
        end
      end

      def create_dynamic_model_tables
        setup_fields

        create_table "#{schema}.#{table_name}", comment: table_comment do |t|
          t.belongs_to :master, index: true, foreign_key: true
          create_fields t
          t.references :user, index: true, foreign_key: true
          t.timestamps null: false
        end

        create_table "#{schema}.#{history_table_name}" do |t|
          t.belongs_to :master, index: true, foreign_key: true
          create_fields t
          t.references :user, index: true, foreign_key: true
          t.timestamps null: false

          t.belongs_to table_name.singularize, index: { name: "#{table_name.singularize}_id_idx" }, foreign_key: { to_table: "#{schema}.#{table_name}" }
        end
      end

      def create_dynamic_model_trigger
        setup_fields

        reversible do |dir|
          dir.up do
            ActiveRecord::Base.connection.execute dynamic_model_trigger_sql
          end
          dir.down do
            ActiveRecord::Base.connection.execute reverse_dynamic_model_trigger_sql
          end
        end
      end

      def create_external_identifier_tables(id_field, id_field_type = :bigint)
        self.fields ||= []
        self.fields.unshift id_field
        setup_fields

        field_defs[id_field] = id_field_type

        create_table "#{schema}.#{table_name}", comment: table_comment do |t|
          t.belongs_to :master, index: true, foreign_key: true
          create_fields t
          t.references :user, index: true, foreign_key: true
          t.references :admin, index: true, foreign_key: true
          t.timestamps null: false
        end

        create_table "#{schema}.#{history_table_name}" do |t|
          t.belongs_to :master, index: true, foreign_key: true
          create_fields t
          t.references :user, index: true, foreign_key: true
          t.references :admin, index: true, foreign_key: true
          t.timestamps null: false

          t.belongs_to "#{table_name.singularize}_table_id", index: { name: "#{table_name.singularize}_id_idx" }, foreign_key: { to_table: "#{schema}.#{table_name}" }
        end
      end

      def create_external_identifier_trigger(id_field)
        self.fields ||= []
        self.fields.unshift id_field
        setup_fields

        reversible do |dir|
          dir.up do
            ActiveRecord::Base.connection.execute external_identifier_trigger_sql
          end
          dir.down do
            ActiveRecord::Base.connection.execute reverse_external_identifier_trigger_sql
          end
        end
      end

      def update_fields
        self.mode = :update
        setup_fields
        cols = ActiveRecord::Base.connection.columns("#{schema}.#{table_name}")
        old_table_comment = ActiveRecord::Base.connection.table_comment(table_name)

        old_colnames = cols.map(&:name) - standard_columns
        new_colnames = fields.map(&:to_s) - standard_columns
        added = new_colnames - old_colnames
        removed = old_colnames - new_colnames

        self.fields_comments ||= {}
        commented_colnames = fields_comments.keys.map(&:to_s)
        changed = commented_colnames - added - removed

        change_table_comment("#{schema}.#{table_name}", table_comment) if old_table_comment != table_comment

        added.each do |c|
          options = {}
          comment = fields_comments[c.to_sym]
          options[:comment] = comment if comment.present?
          add_column "#{schema}.#{table_name}", c, field_defs[c.to_sym], options
        end

        removed.each do |c|
          remove_column "#{schema}.#{table_name}", c
        end

        changed.each do |c|
          next unless fields_comments.key?(c.to_sym)

          col = cols.select { |csel| csel.name == c }.first
          new_comment = fields_comments[c.to_sym]
          next if col.comment == new_comment

          change_column_comment "#{schema}.#{table_name}", c, new_comment
        end
      end

      protected

      def standard_columns
        pset = %w[id created_at updated_at contactid user_id master_id
                  extra_log_type admin_id tracker_history_id]
        pset += ["#{table_name.singularize}_table_id", "#{table_name.singularize}_id"]
        pset
      end

      def setup_fields
        self.fields_comments ||= {}
        return if field_opts

        fields.reject! { |a| a.to_s.index(/^placeholder_|^tracker_history_id$/) }

        self.history_table_name = "#{table_name.singularize}_history"
        self.trigger_fn_name = "#{schema}.log_#{table_name}_update"
        self.new_fields = fields.map { |f| "NEW.#{f}" }
        self.field_defs = {}
        self.field_opts = {}

        fields.each do |attr_name|
          a = attr_name.to_s
          f = :string
          fopts = nil
          if a == 'created_by_user_id'
            attr_name = :created_by_user
            f = :references
            fopts = { index: true, foreign_key: { to_table: :users } }
          elsif a.index(/(?:_when|_date)$/)
            f = :date
          elsif a.index(/(?:_time)$/)
            f = :time
          elsif a.index(/(?:_at)$/)
            f = :timestamp
          elsif a.index(/^(?:select_)|^(?:notes|data)$|(?:_name)$/)
            f = :string
          elsif a.index(/(?:_check)$/)
            f = :boolean
          elsif a.index(/(?:_id)$/)
            f = :bigint
          elsif a.index(/^(?:number)|^(?:age|rank)$|(?:_number|_timestamp|score)$/)
            f = :integer
          end
          field_defs[attr_name] = f

          # Add in a field comment if one is defined
          comment = fields_comments[attr_name.to_sym]
          if comment
            fopts ||= {}
            fopts[:comment] = comment
          end

          field_opts[attr_name] = fopts
        end
      end

      def create_fields(t)
        field_defs.each do |attr_name, f|
          fopts = field_opts[attr_name]
          if fopts
            t.send(f, attr_name, fopts)
          else
            t.send(f, attr_name)
          end
        end
      end

      def add_fields(tbl)
        field_defs.each do |attr_name, f|
          fopts = field_opts[attr_name]
          if fopts
            add_column(tbl, attr_name, f, fopts)
          else
            add_column(tbl, attr_name, f)
          end
        end
      end

      def updating?
        mode == :update
      end

      def creating?
        !updating?
      end

      def activity_log_trigger_sql
        base_name_id = "#{belongs_to_model.to_s.underscore.gsub(%r{__|/}, '_')}_id"
        <<~EOF

          CREATE OR REPLACE FUNCTION #{trigger_fn_name} ()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS $$
          BEGIN
            INSERT INTO #{history_table_name} (
              master_id,
              #{base_name_id},
              #{fields.join(', ')},
              extra_log_type,
              user_id,
              created_at,
              updated_at,
              #{table_name.singularize}_id)
            SELECT
              NEW.master_id,
              NEW.#{base_name_id},
              #{new_fields.join(', ')},
              NEW.extra_log_type,
              NEW.user_id,
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

        EOF
      end

      def reverse_activity_log_trigger_sql
        if updating?
          activity_log_trigger_sql
        else
          "DROP FUNCTION #{trigger_fn_name}() CASCADE"
        end
      end

      def dynamic_model_trigger_sql
        <<~EOF

          CREATE OR REPLACE FUNCTION #{trigger_fn_name} ()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS $$
          BEGIN
            INSERT INTO #{history_table_name} (
              master_id,
              #{fields.join(', ')},
              user_id,
              created_at,
              updated_at,
              #{table_name.singularize}_id)
            SELECT
              NEW.master_id,
              #{new_fields.join(', ')},
              NEW.user_id,
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

        EOF
      end

      def reverse_dynamic_model_trigger_sql
        if updating?
          dynamic_model_trigger_sql
        else
          "DROP FUNCTION #{trigger_fn_name}() CASCADE"
        end
      end

      def external_identifier_trigger_sql
        <<~EOF

          CREATE OR REPLACE FUNCTION #{trigger_fn_name} ()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS $$
          BEGIN
            INSERT INTO #{history_table_name} (
              master_id,
              #{fields.join(', ')},
              user_id,
              admin_id,
              created_at,
              updated_at,
              #{table_name.singularize}_table_id)
            SELECT
              NEW.master_id,
              #{new_fields.join(', ')},
              NEW.user_id,
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

        EOF
      end

      def reverse_external_identifier_trigger_sql
        if updating?
          external_identifier_trigger_sql
        else
          "DROP FUNCTION #{trigger_fn_name}() CASCADE"
        end
      end
    end
  end
end
