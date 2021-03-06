# frozen_string_literal: true

module ActiveRecord
  class Migration
    module AppGenerator
      extend ActiveSupport::Concern

      included do
        attr_accessor :fields, :new_fields, :field_defs, :prev_fields,
                      :field_opts, :owner, :history_table_id_attr,
                      :belongs_to_model, :history_table_name, :trigger_fn_name,
                      :table_comment, :fields_comments, :db_configs, :mode, :no_master_association,
                      :requested_action
      end

      def force_rollback
        ENV['FORCE_ROLLBACK'] == 'true' && reverting?
      end

      def schema=(new_schema)
        unless Admin::MigrationGenerator.current_search_paths.include?(new_schema)
          raise FphsException, "Current search_path does not include the schema (#{new_schema}) for the migration. " \
                               "#{Admin::MigrationGenerator.current_search_paths}"
        end

        @schema = new_schema
      end

      def schema
        @schema
      end

      def table_name=(tname)
        @table_name = tname
        self.history_table_name = Admin::MigrationGenerator.history_table_name_for tname
        self.history_table_id_attr = Admin::MigrationGenerator.history_table_id_attr_for tname
      end

      def table_name
        @table_name
      end

      def create_schema
        sql = "CREATE SCHEMA IF NOT EXISTS #{schema}"
        sql += " AUTHORIZATION #{owner}" if owner.present? && !Rails.env.development?
        ActiveRecord::Base.connection.execute sql
      end

      def add_fields_to_tables
        setup_fields

        add_fields "#{schema}.#{table_name}"
        add_fields "#{schema}.#{history_table_name}"
      rescue StandardError, ActiveRecord::StatementInvalid => e
        raise e unless force_rollback
      end

      def rand_id
        Digest::MD5.hexdigest("#{schema}.#{table_name}")[0..7]
      end

      def create_or_update_activity_log_tables
        self.requested_action = :create_or_update

        if table_exists
          update_fields
        else
          create_activity_log_tables
        end
      end

      def create_activity_log_tables
        setup_fields

        self.belongs_to_model = belongs_to_model.to_s.underscore

        unless table_exists
          create_table "#{schema}.#{table_name}", comment: table_comment do |t|
            t.belongs_to :master, index: { name: "#{rand_id}_master_id_idx" }, foreign_key: true
            t.belongs_to belongs_to_model,
                         index: { name: "#{rand_id}_id_idx" },
                         foreign_key: { to_table: "#{schema}.#{belongs_to_model.pluralize}" }
            create_fields t
            t.string :extra_log_type
            t.references :user, index: { name: "#{rand_id}_user_id_idx" }, foreign_key: true
            t.timestamps null: false
          end
        end

        unless history_table_exists || model_is_view
          create_table "#{schema}.#{history_table_name}" do |t|
            t.belongs_to :master, index: { name: "#{rand_id}_master_id_h_idx" }, foreign_key: true
            t.belongs_to belongs_to_model,
                         index: { name: "#{rand_id}_id_h_idx" },
                         foreign_key: { to_table: "#{schema}.#{belongs_to_model.pluralize}" }
            create_fields t, true
            t.string :extra_log_type
            t.references :user, index: { name: "#{rand_id}_user_id_h_idx" }, foreign_key: true
            t.timestamps null: false

            t.belongs_to table_name.singularize, index: { name: "#{rand_id}_b_id_h_idx" },
                                                 foreign_key: { to_table: "#{schema}.#{table_name}" }
          end
        end
      rescue StandardError, ActiveRecord::StatementInvalid => e
        raise e unless force_rollback
      end

      def create_activity_log_trigger
        setup_fields(fields & col_names(:sym))

        reversible do |dir|
          dir.up do
            puts "-- create or replace function #{trigger_fn_name}"
            ActiveRecord::Base.connection.execute activity_log_trigger_sql
          end
          dir.down do
            puts "-- drop function #{trigger_fn_name}"
            ActiveRecord::Base.connection.execute reverse_activity_log_trigger_sql
          end
        end
      rescue StandardError, ActiveRecord::StatementInvalid => e
        raise e unless force_rollback
      end

      def create_or_update_dynamic_model_tables
        self.requested_action = :create_or_update
        if table_exists
          update_fields
        else
          create_dynamic_model_tables
        end
      end

      def create_dynamic_model_tables
        setup_fields

        unless table_exists
          create_table "#{schema}.#{table_name}", comment: table_comment do |t|
            unless no_master_association
              t.belongs_to :master, index: {
                name: "dmbt_#{rand_id}_id_idx"
              }, foreign_key: true
            end
            create_fields t
            t.references :user, index: true, foreign_key: true
            t.timestamps null: false
          end

        end
        unless history_table_exists || model_is_view
          create_table "#{schema}.#{history_table_name}" do |t|
            unless no_master_association
              t.belongs_to :master, index: { name: "#{rand_id}_history_master_id" }, foreign_key: true
            end
            create_fields t, true
            t.references :user, index: { name: "#{rand_id}_user_idx" }, foreign_key: true
            t.timestamps null: false

            t.belongs_to table_name.singularize, index: { name: "#{rand_id}_id_idx" },
                                                 foreign_key: { to_table: "#{schema}.#{table_name}" }
          end
        end
      rescue StandardError, ActiveRecord::StatementInvalid => e
        raise e unless force_rollback
      end

      def create_dynamic_model_trigger
        return unless history_table_exists && !model_is_view

        setup_fields(fields & col_names(:sym))

        reversible do |dir|
          dir.up do
            puts "-- create or replace function #{trigger_fn_name}"
            ActiveRecord::Base.connection.execute dynamic_model_trigger_sql
          end
          dir.down do
            puts "-- drop function #{trigger_fn_name}"
            ActiveRecord::Base.connection.execute reverse_dynamic_model_trigger_sql
          end
        end
      rescue StandardError, ActiveRecord::StatementInvalid => e
        raise e unless force_rollback
      end

      def create_or_update_external_identifier_tables(id_field, id_field_type = :bigint)
        self.requested_action = :create_or_update
        if table_exists
          update_fields
        else
          create_external_identifier_tables(id_field, id_field_type)
        end
      end

      def create_external_identifier_tables(id_field, id_field_type = :bigint)
        self.fields ||= []
        self.fields.unshift id_field
        self.fields = fields.uniq
        setup_fields

        field_defs[id_field] = id_field_type

        unless table_exists
          create_table "#{schema}.#{table_name}", comment: table_comment do |t|
            t.belongs_to :master, index: { name: "ei#{rand_id}_id_idx" }, foreign_key: true
            create_fields t
            t.references :user, index: true, foreign_key: true
            t.references :admin, index: true, foreign_key: true
            t.timestamps null: false
          end
        end
        unless history_table_exists || model_is_view
          create_table "#{schema}.#{history_table_name}" do |t|
            t.belongs_to :master, index: { name: "eih#{rand_id}_id_idx" }, foreign_key: true
            create_fields t, true
            t.references :user, index: true, foreign_key: true
            t.references :admin, index: true, foreign_key: true
            t.timestamps null: false

            t.belongs_to "#{table_name.singularize}_table", index: { name: "#{table_name.singularize}_id_idx" },
                                                            foreign_key: { to_table: "#{schema}.#{table_name}" }
          end
        end
      rescue StandardError, ActiveRecord::StatementInvalid => e
        raise e unless force_rollback
      end

      def create_external_identifier_trigger(_id_field)
        return if history_table_exists || model_is_view

        self.fields ||= []
        # self.fields.unshift id_field
        self.fields = fields.uniq
        setup_fields(fields & col_names(:sym))

        reversible do |dir|
          dir.up do
            puts "-- create or replace function #{trigger_fn_name}"
            ActiveRecord::Base.connection.execute external_identifier_trigger_sql
          end
          dir.down do
            puts "-- drop function #{trigger_fn_name}"
            ActiveRecord::Base.connection.execute reverse_external_identifier_trigger_sql
          end
        end
      rescue StandardError, ActiveRecord::StatementInvalid => e
        raise e unless force_rollback
      end

      def update_table_name
        rename_table prev_table_name, table_name
        rename_table Admin::MigrationGenerator.history_table_name_for(prev_table_name),
                     Admin::MigrationGenerator.history_table_name_for(table_name)

        # Drop the trigger, so that it can be recreated with a new name
        reversible do |dir|
          dir.up do
            puts "-- drop function #{trigger_fn_name}"
            ActiveRecord::Base.connection.execute "DROP FUNCTION #{calc_trigger_fn_name(prev_table_name)}"
          end
          dir.down do
            puts "-- drop function #{trigger_fn_name}"
            ActiveRecord::Base.connection.execute "DROP FUNCTION #{calc_trigger_fn_name(table_name)}"
          end
        end
      rescue StandardError, ActiveRecord::StatementInvalid => e
        raise e unless force_rollback
      end

      def table_exists
        Admin::MigrationGenerator.table_or_view_exists? "#{schema}.#{table_name}"
      end

      def model_is_view
        Admin::MigrationGenerator.view_exists? "#{schema}.#{table_name}"
      end

      def history_table_exists
        ActiveRecord::Base.connection.table_exists? "#{schema}.#{history_table_name}"
      end

      def update_fields
        self.mode = :update

        old_table_comment = ActiveRecord::Base.connection.table_comment(table_name)

        belongs_to_model_field = "#{belongs_to_model}_id" if belongs_to_model

        col_names = if reverting?
                      prev_col_names
                    else
                      self.col_names
                    end
        col_names ||= []

        old_colnames = col_names - standard_columns
        old_history_colnames = if history_table_exists
                                 history_col_names - standard_columns
                               else
                                 []
                               end
        new_colnames = fields.map(&:to_s) - standard_columns
        added = (new_colnames - old_colnames - [belongs_to_model_field]).reject { |a| a.to_s.index(ignore_fields) }
        removed = (old_colnames - new_colnames - [belongs_to_model_field]).reject { |a| a.to_s.index(ignore_fields) }
        added_history = (new_colnames - old_history_colnames - [belongs_to_model_field]).reject do |a|
          a.to_s.index(ignore_fields)
        end
        removed_history = (old_history_colnames - new_colnames - [belongs_to_model_field]).reject do |a|
          a.to_s.index(ignore_fields)
        end

        idx = added.index('created_by_user_id')
        added[idx] = 'created_by_user' if idx
        idx = added_history.index('created_by_user_id')
        added_history[idx] = 'created_by_user' if idx

        idx = removed.index('created_by_user_id')
        removed[idx] = 'created_by_user' if idx
        idx = removed_history.index('created_by_user_id')
        removed_history[idx] = 'created_by_user' if idx

        if reverting?
          puts 'Rollback'
          puts "Adding: #{removed &= col_names}"
          puts "Removing: #{added -= col_names}"
          puts "Adding (history): #{removed_history &= history_col_names}" if history_table_exists
          puts "Removing (history): #{added_history -= history_col_names}" if history_table_exists
        else
          puts 'Migrate'
          puts "Adding: #{added -= col_names}"
          puts "Removing: #{removed &= col_names}"
          puts "Adding (history): #{added_history -= history_col_names}" if history_table_exists
          puts "Removing (history): #{removed_history &= history_col_names}" if history_table_exists
        end

        if Rails.env.production? && (removed.present? || removed_history.present?) && ENV['ALLOW_DROP_COLUMNS'] != 'true'
          puts 'Specify "allow drop columns" is required'
          exit
        end

        full_field_list = (old_colnames + new_colnames + col_names).uniq.map(&:to_sym)
        setup_fields(full_field_list)

        self.fields_comments ||= {}
        commented_colnames = fields_comments.keys.map(&:to_s)
        changed = commented_colnames - added - removed

        # Skip updates to missing history tables
        unless history_table_exists
          puts 'HISTORY TABLE does not exist'
          added_history = []
          removed_history = []
        end

        if old_table_comment != table_comment && table_exists && !model_is_view
          change_table_comment("#{schema}.#{table_name}", table_comment)
        end

        if belongs_to_model && !old_colnames.include?(belongs_to_model) && !col_names.include?(belongs_to_model_field)
          begin
            add_reference "#{schema}.#{table_name}", belongs_to_model, index: { name: "#{rand_id}_bt_id_idx" }
          rescue StandardError, ActiveRecord::StatementInvalid
            nil
          end
        end

        if no_master_association && !reverting? && col_names.include?('master_id')

          remove_reference "#{schema}.#{table_name}", :master
          remove_reference "#{schema}.#{history_table_name}", :master

        elsif !no_master_association && !reverting? && !col_names.include?('master_id')
          add_reference "#{schema}.#{table_name}", :master,
                        index: {
                          name: "dmbt_#{rand_id}_id_idx"
                        }, foreign_key: true

          add_reference "#{schema}.#{history_table_name}", :master,
                        index: {
                          name: "#{rand_id}_history_master_id"
                        },
                        foreign_key: true
        end

        added.each do |c|
          options = field_opts[c.to_sym] || {}
          comment = fields_comments[c.to_sym]
          options[:comment] = comment if comment.present?
          fdef = field_defs[c.to_sym]

          # If we are rolling back, skip this one unless the col name exists in the table
          # or if migrating up, skip this one unless the col name does not exist in the table
          next unless reverting? && c.in?(col_names) || !reverting? && !c.in?(col_names)

          if fdef == :references
            begin
              add_reference "#{schema}.#{table_name}", c, options
            rescue StandardError, ActiveRecord::StatementInvalid
              nil
            end
          else
            add_column "#{schema}.#{table_name}", c, fdef, options
          end
        end

        removed.each do |c|
          options = field_opts[c.to_sym] || {}
          comment = fields_comments[c.to_sym]
          options[:comment] = comment if comment.present?
          fdef = field_defs[c.to_sym] || {}

          # If we are rolling back, skip this one unless the col name does not exist in the table
          # or if migrating up, skip this one unless the col name exists in the table
          next unless reverting? && !c.in?(col_names) || !reverting? && c.in?(col_names)

          if fdef == :references
            begin
              remove_reference "#{schema}.#{table_name}", c, options
            rescue StandardError, ActiveRecord::StatementInvalid
              nil
            end
          else
            remove_column "#{schema}.#{table_name}", c, fdef
          end
        end

        added_history.each do |c|
          options = field_opts[c.to_sym] || {}
          comment = fields_comments[c.to_sym]
          options[:comment] = comment if comment.present?
          fdef = field_defs[c.to_sym]

          # If we are rolling back, skip this one unless the col name exists in the table
          # or if migrating up, skip this one unless the col name does not exist in the table
          next unless reverting? && c.in?(history_col_names) || !reverting? && !c.in?(history_col_names)

          if fdef == :references
            options[:index][:name] += '_hist'
            begin
              add_reference "#{schema}.#{history_table_name}", c, options
            rescue StandardError, ActiveRecord::StatementInvalid
              nil
            end
          else
            add_column "#{schema}.#{history_table_name}", c, fdef, options
          end
        end

        removed_history.each do |c|
          options = field_opts[c.to_sym] || {}
          comment = fields_comments[c.to_sym]
          options[:comment] = comment if comment.present?
          fdef = field_defs[c.to_sym] || {}

          # If we are rolling back, skip this one unless the col name does not exist in the table
          # or if migrating up, skip this one unless the col name exists in the table
          next unless reverting? && !c.in?(history_col_names) || !reverting? && c.in?(history_col_names)

          if fdef == :references
            options[:index][:name] += '_hist'
            begin
              remove_reference "#{schema}.#{history_table_name}", c, options if c.in? history_col_names
            rescue StandardError, ActiveRecord::StatementInvalid
              nil
            end
          elsif c.in? history_col_names
            remove_column "#{schema}.#{history_table_name}", c, fdef
          end
        end

        changed.each do |c|
          next unless fields_comments.key?(c.to_sym)

          col = cols.select { |csel| csel.name == c }.first
          new_comment = fields_comments[c.to_sym]
          next if !col || col&.comment == new_comment

          change_column_comment "#{schema}.#{table_name}", c, new_comment
          change_column_comment "#{schema}.#{history_table_name}", c, new_comment if history_table_exists
        end
      rescue StandardError, ActiveRecord::StatementInvalid => e
        raise e unless force_rollback
      end

      protected

      def ignore_fields
        /^placeholder_|^embedded_report_|^tracker_history_id$/
      end

      def standard_columns
        pset = %w[id created_at updated_at contactid user_id master_id
                  extra_log_type admin_id tracker_history_id]
        pset += ["#{table_name.singularize}_table_id", history_table_id_attr.to_s]
        pset
      end

      def cols
        ActiveRecord::Base.connection.columns("#{schema}.#{table_name}")
      end

      def history_cols
        ActiveRecord::Base.connection.columns("#{schema}.#{history_table_name}")
      end

      def history_col_names(to_type = nil)
        res = history_cols.map(&:name)
        res = res.map(&:to_sym) if to_type == :sym
        res
      end

      # The previous column names were either specified when initializing this
      # instance, or if in create_or_update mode then use the current table columns
      def prev_col_names(to_type = nil)
        res = if requested_action == :create_or_update
                Admin::MigrationGenerator.table_column_names table_name
              else
                prev_fields
              end

        if to_type == :sym
          res.map(&:to_sym)
        else
          res.map(&:to_s)
        end
      end

      def col_names(to_type = nil)
        res = cols.map(&:name)
        res = res.map(&:to_sym) if to_type == :sym
        res
      end

      def calc_trigger_fn_name(table_name)
        "#{schema}.log_#{table_name}_update"
      end

      def setup_fields(handle_fields = nil)
        self.fields_comments ||= {}
        return if field_opts && !handle_fields

        handle_fields ||= self.fields
        handle_fields.reject! { |a| a.to_s.index(ignore_fields) }
        handle_fields = handle_fields.map(&:to_sym)

        self.trigger_fn_name = calc_trigger_fn_name(table_name)
        self.new_fields = fields.map { |f| "NEW.#{f}" }
        self.field_defs = {}
        self.field_opts = {}

        handle_fields.each do |attr_name|
          a = attr_name.to_s
          f = :string
          fopts = nil
          field_config = db_configs[attr_name]
          if field_config.present?
            # Field definition overrides everything else
            f = field_config[:type]
            fopts = {}
            fopts[:default] = field_config[:default] if field_config[:default]
            fopts[:index] = field_config[:index] if field_config[:index]
          elsif a == 'created_by_user_id'
            attr_name = :created_by_user
            f = :references
            fopts = { index: { name: "#{rand_id}_ref_cb_user_idx" }, foreign_key: { to_table: :users } }
          elsif a.index(/(?:_when|_date)$/)
            f = :date
          elsif a.index(/(?:_time)$/)
            f = :time
          elsif a.index(/(?:_at)$/)
            f = :timestamp
          elsif a.index(/^(?:select_)|^(?:notes|data)$|(?:_name)$/)
            f = :string
          elsif a.index(/^(?:is_|has_)|(?:_check|_bool)$/)
            f = :boolean
          elsif a.index(/(?:_id)$/)
            f = :bigint
          elsif a.index(/^(?:number)|^(?:age|rank)$|(?:_number|_timestamp|score|_count)$/)
            f = :integer
          elsif a == 'disabled'
            f = :boolean
            fopts = { default: false }
          end
          field_defs[attr_name] = f

          # Add in a field comment if one is defined
          comment = fields_comments[attr_name.to_sym]
          if comment
            fopts ||= {}
            fopts[:comment] = comment
          end

          if a.start_with?('tag_select') || a.start_with?('multi_')
            fopts ||= {}
            fopts[:array] = true
          end

          field_opts[attr_name] = fopts
        end
      end

      def create_fields(tbl, history = false)
        field_defs.each do |attr_name, f|
          fopts = field_opts[attr_name]
          if fopts && fopts[:index]
            fopts[:index][:name] += '_hist' if history
            tbl.send(f, attr_name, fopts)
          elsif fopts
            tbl.send(f, attr_name, fopts)
          else
            tbl.send(f, attr_name)
          end
        end
      rescue StandardError, ActiveRecord::StatementInvalid => e
        raise e unless force_rollback
      end

      def add_fields(tbl)
        field_defs.each do |attr_name, f|
          fopts = field_opts[attr_name]
          if fopts
            add_column(tbl, attr_name, f, fopts)
          else
            add_column(tbl, attr_name)
          end
        end
      rescue StandardError, ActiveRecord::StatementInvalid => e
        raise e unless force_rollback
      end

      def updating?
        mode == :update
      end

      def creating?
        !updating?
      end

      def activity_log_trigger_sql
        base_name_id = "#{belongs_to_model.to_s.underscore.gsub(%r{__|/}, '_')}_id"
        <<~DO_TEXT
          CREATE OR REPLACE FUNCTION #{trigger_fn_name} ()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS $$
          BEGIN
            INSERT INTO #{history_table_name} (
              master_id,
              #{base_name_id},
              #{"#{fields.join(', ')}," if fields.present?}
              extra_log_type,
              user_id,
              created_at,
              updated_at,
              #{history_table_id_attr})
            SELECT
              NEW.master_id,
              NEW.#{base_name_id},
              #{"#{new_fields.join(', ')}," if fields.present?}
              NEW.extra_log_type,
              NEW.user_id,
              NEW.created_at,
              NEW.updated_at,
              NEW.id;
            RETURN NEW;
          END;
          $$;

          DROP FUNCTION IF EXISTS #{schema}.log_#{table_name.singularize}_update () CASCADE;
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

      def reverse_activity_log_trigger_sql
        if updating?
          activity_log_trigger_sql
        else
          "DROP FUNCTION #{trigger_fn_name}() CASCADE"
        end
      end

      def dynamic_model_trigger_sql
        <<~DO_TEXT

          CREATE OR REPLACE FUNCTION #{trigger_fn_name} ()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS $$
          BEGIN
            INSERT INTO #{history_table_name} (
              #{no_master_association ? '' : 'master_id,'}
              #{"#{fields.join(', ')}," if fields.present?}
              user_id,
              created_at,
              updated_at,
              #{history_table_id_attr})
            SELECT
              #{no_master_association ? '' : 'NEW.master_id,'}
              #{"#{new_fields.join(', ')}," if fields.present?}
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

        DO_TEXT
      end

      def reverse_dynamic_model_trigger_sql
        if updating?
          dynamic_model_trigger_sql
        else
          "DROP FUNCTION #{trigger_fn_name}() CASCADE"
        end
      end

      def external_identifier_trigger_sql
        <<~DO_TEXT

          CREATE OR REPLACE FUNCTION #{trigger_fn_name} ()
            RETURNS TRIGGER
            LANGUAGE plpgsql
            AS $$
          BEGIN
            INSERT INTO #{history_table_name} (
              master_id,
              #{"#{fields.join(', ')}," if fields.present?}
              user_id,
              admin_id,
              created_at,
              updated_at,
              #{table_name.singularize}_table_id)
            SELECT
              NEW.master_id,
              #{"#{new_fields.join(', ')}," if fields.present?}
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

        DO_TEXT
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
